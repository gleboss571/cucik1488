--[[
    Inspire Auto Refresh v2.0
    CHANGES from original:
    - Normal Inspire TP hold = 0.1s (was 1.1s for all)
    - Duped Inspire TP hold = 1.1s with FULL FREEZE at player height
    - Duped TP targets player Y, not token Y
    - Character frozen (Anchored + velocity zero) during duped hold
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local ServerBuffEvent = Events:WaitForChild("ServerBuffEvent")

-- ============================================================
-- SETTINGS
-- ============================================================

local ABILITY_TOKEN_MULTIPLIER = 1.21
local DIGITAL_BEE_LEVEL = 23

local INSPIRE_BASE_LIFETIME = 8
local TOKEN_LINK_BASE_LIFETIME = 4

local DUPED_HEIGHT_THRESHOLD = 5

local INSPIRE_BUFF_REFRESH_THRESHOLD = 0.5
local INSPIRE_TOKEN_URGENT_THRESHOLD = 0.5

local DUPED_BUFF_REFRESH_THRESHOLD = 1.6

-- ★ РАЗНЫЕ HOLD ДЛЯ NORMAL И DUPED
local NORMAL_INSPIRE_HOLD = 0.1    -- ★ обычные токены: 0.1с
local DUPED_INSPIRE_HOLD = 1.1     -- ★ duped токены: 1.1с с заморозкой

local TELEPORT_COOLDOWN = 0.1

local PROTECTED_RADIUS = 6
local WALL_SEGMENTS = 16
local WALL_HEIGHT = 20
local WALL_THICKNESS = 0.8
local WALL_ARC_SCALE = 1.10
local walls = {}
local activeTokens = {}

local DECISION_INTERVAL = 0.05

local LOGS = true

-- ============================================================
-- TOKEN IDS
-- ============================================================

local INSPIRE_ID = 2000457501
local TOKEN_LINK_ID = 1629547638

-- ============================================================
-- STATE
-- ============================================================

local inspireBuffEnd = 0
local inspireBuffActive = false

local lastTeleport = 0
local teleportBusy = false

local multiInspireHoldUntil = 0
local multiInspireTargetPart = nil
local multiInspireMode = false

-- ★ Duped freeze state
local dupedInspireHoldUntil = 0
local dupedInspireHoldPart = nil
local dupedFreezeActive = false

local inspireLifetimeQueueMode = false
local inspireLifetimeLastPart = nil
local inspireLifetimeHoldUntil = 0

local lastDecision = ""

-- ============================================================
-- HELPERS
-- ============================================================

local function log(...)
    if LOGS then print("[InspireRefresh]", ...) end
end

local function getRoot()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

local function getServerNow()
    local ok, value = pcall(function() return Workspace:GetServerTimeNow() end)
    if ok and type(value) == "number" then return value end
    return os.time()
end

local function getTextureId(texture)
    if type(texture) ~= "string" then return nil end
    local id = texture:match("id=(%d+)") or texture:match("rbxassetid://(%d+)")
    return id and tonumber(id)
end

local function getTokenId(obj)
    if not obj or obj.Name ~= "C" or not obj:IsA("BasePart") then return nil end
    local front = obj:FindFirstChild("FrontDecal")
    if not front or not front:IsA("Decal") then return nil end
    local id = getTextureId(front.Texture)
    if id == INSPIRE_ID or id == TOKEN_LINK_ID then return id end
    return nil
end

local function isDuped(part)
    local root = getRoot()
    if not root then return false end
    return (part.Position.Y - root.Position.Y) > DUPED_HEIGHT_THRESHOLD
end

local function calculateLifetime(id, duped)
    local base
    if id == INSPIRE_ID then base = INSPIRE_BASE_LIFETIME
    elseif id == TOKEN_LINK_ID then base = TOKEN_LINK_BASE_LIFETIME
    else return 0 end
    local normal = base * ABILITY_TOKEN_MULTIPLIER
    if not duped then return normal end
    local dupedMultiplier = 2 + 0.05 * (DIGITAL_BEE_LEVEL - 1)
    return normal * dupedMultiplier
end

local function getRemaining(data)
    return math.max(0, data.expiresAt - tick())
end

local function tokenKind(id)
    if id == INSPIRE_ID then return "Inspire"
    elseif id == TOKEN_LINK_ID then return "Token Link"
    end
    return "Unknown"
end

-- ============================================================
-- ★ CHARACTER FREEZE / UNFREEZE
-- ============================================================

local function freezeCharacter()
    if dupedFreezeActive then return end
    local root = getRoot()
    local hum = getHumanoid()
    if not root then return end
    
    dupedFreezeActive = true
    
    -- Anchored = true → персонаж не может двигаться
    root.Anchored = true
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    
    if hum then
        hum.AutoRotate = false
    end
    
    log("FREEZE ON")
end

local function unfreezeCharacter()
    if not dupedFreezeActive then return end
    local root = getRoot()
    local hum = getHumanoid()
    
    dupedFreezeActive = false
    
    if root then
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    
    if hum then
        hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    log("FREEZE OFF")
end

-- ============================================================
-- INVISIBLE WALLS (unchanged)
-- ============================================================

local function destroyWall(part)
    local group = walls[part]
    if not group then return end
    for _, wallPart in ipairs(group) do
        if wallPart and wallPart.Parent then wallPart:Destroy() end
    end
    walls[part] = nil
end

local function destroyAllWalls()
    for part in pairs(walls) do destroyWall(part) end
end

local function createWall(part)
    if not part or not part.Parent or walls[part] then return end
    local group = {}
    local circumference = 2 * math.pi * PROTECTED_RADIUS
    local segmentLength = (circumference / WALL_SEGMENTS) * WALL_ARC_SCALE
    for i = 1, WALL_SEGMENTS do
        local angle = ((i - 1) / WALL_SEGMENTS) * (2 * math.pi)
        local x = math.cos(angle) * PROTECTED_RADIUS
        local z = math.sin(angle) * PROTECTED_RADIUS
        local wallPart = Instance.new("Part")
        wallPart.Name = "InspireRefreshWall"
        wallPart.Anchored = true
        wallPart.CanCollide = true
        wallPart.CanTouch = false
        wallPart.CanQuery = false
        wallPart.CastShadow = false
        wallPart.Transparency = 1
        wallPart.Size = Vector3.new(segmentLength, WALL_HEIGHT, WALL_THICKNESS)
        wallPart.CFrame = CFrame.new(part.Position.X + x, part.Position.Y, part.Position.Z + z)
            * CFrame.Angles(0, angle + math.pi / 2, 0)
        wallPart.Parent = Workspace
        group[#group + 1] = wallPart
    end
    walls[part] = group
end

local function updateWallPositions()
    for tokenPart, group in pairs(walls) do
        if not tokenPart or not tokenPart.Parent then
            destroyWall(tokenPart)
        elseif activeTokens[tokenPart] and not activeTokens[tokenPart].teleported then
            local tokenPos = tokenPart.Position
            for i, wallPart in ipairs(group) do
                if not wallPart or not wallPart.Parent then
                    destroyWall(tokenPart); createWall(tokenPart); break
                end
                local angle = ((i - 1) / WALL_SEGMENTS) * (2 * math.pi)
                local x = math.cos(angle) * PROTECTED_RADIUS
                local z = math.sin(angle) * PROTECTED_RADIUS
                wallPart.CFrame = CFrame.new(tokenPos.X + x, tokenPos.Y, tokenPos.Z + z)
                    * CFrame.Angles(0, angle + math.pi / 2, 0)
            end
        else
            destroyWall(tokenPart)
        end
    end
end

local function hasActiveInspireToken()
    for part, data in pairs(activeTokens) do
        if data and data.kind == "Inspire" and part and part.Parent and getRemaining(data) > 0 then
            return true
        end
    end
    return false
end

local function syncWalls(buffRemaining)
    local inspireExists = hasActiveInspireToken()
    for part, data in pairs(activeTokens) do
        if not data or data.teleported or not part or not part.Parent then
            destroyWall(part)
        else
            local shouldWall = false
            if data.kind == "Inspire" then
                shouldWall = buffRemaining > INSPIRE_BUFF_REFRESH_THRESHOLD
            elseif data.kind == "Token Link" then
                shouldWall = inspireExists or buffRemaining > INSPIRE_BUFF_REFRESH_THRESHOLD
            end
            if shouldWall then
                if not walls[part] then createWall(part) end
            else
                destroyWall(part)
            end
        end
    end
    updateWallPositions()
end

-- ============================================================
-- TOKEN STATE
-- ============================================================

local function unregisterToken(part)
    activeTokens[part] = nil
    destroyWall(part)
end

local function registerToken(part)
    if activeTokens[part] then return end
    local id = getTokenId(part)
    if not id then return end
    local duped = isDuped(part)
    if duped and id == TOKEN_LINK_ID then return end
    local lifetime = calculateLifetime(id, duped)
    if lifetime <= 0 then return end
    local now = tick()
    activeTokens[part] = {
        part = part, id = id, kind = tokenKind(id),
        startTime = now, totalLifetime = lifetime,
        expiresAt = now + lifetime, duped = duped, teleported = false,
    }
    log(string.format("TOKEN + %s | lifetime=%.2fs | %s", tokenKind(id), lifetime, duped and "DUPED" or "NORMAL"))
end

local function inspectAddedObject(obj)
    if not obj then return end
    if obj:IsA("BasePart") and obj.Name == "C" then registerToken(obj); return end
    if obj:IsA("Decal") and obj.Name == "FrontDecal" then
        local parent = obj.Parent
        if parent and parent:IsA("BasePart") and parent.Name == "C" then registerToken(parent) end
        return
    end
    local parent = obj.Parent
    if parent and parent:IsA("BasePart") and parent.Name == "C" then registerToken(parent) end
end

Workspace.DescendantAdded:Connect(inspectAddedObject)
Workspace.DescendantRemoving:Connect(function(obj)
    if activeTokens[obj] then unregisterToken(obj) end
    if obj:IsA("Decal") and obj.Name == "FrontDecal" then
        local parent = obj.Parent
        if parent and activeTokens[parent] then unregisterToken(parent) end
    end
end)

for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("BasePart") and obj.Name == "C" then registerToken(obj) end
end

-- ============================================================
-- INSPIRE BUFF
-- ============================================================

ServerBuffEvent.OnClientEvent:Connect(function(action, buffName, arg3, arg4, ...)
    if buffName ~= "Inspire" then return end
    if action == "Apply" then
        local startTime = tonumber(arg3)
        local duration = tonumber(arg4)
        if not startTime or not duration then
            local args = {...}
            for _, value in ipairs(args) do
                if type(value) == "table" then
                    if not startTime then startTime = tonumber(value.Start) end
                    if not duration then duration = tonumber(value.Dur) end
                end
            end
        end
        if startTime and duration then
            inspireBuffEnd = startTime + duration
            inspireBuffActive = true
            log(string.format("INSPIRE APPLY | dur=%.2fs | rem=%.2fs", duration, math.max(0, inspireBuffEnd - getServerNow())))
        end
    elseif action == "Remove" then
        inspireBuffEnd = 0; inspireBuffActive = false
        log("INSPIRE REMOVE")
    end
end)

local function getBuffRemaining()
    if not inspireBuffActive then return 0 end
    local remaining = inspireBuffEnd - getServerNow()
    if remaining <= 0 then inspireBuffActive = false; inspireBuffEnd = 0; return 0 end
    return remaining
end

-- ============================================================
-- CLEANUP
-- ============================================================

local function cleanupExpiredTokens()
    local now = tick()
    for part, data in pairs(activeTokens) do
        if not part or not part.Parent then activeTokens[part] = nil
        elseif now >= data.expiresAt then activeTokens[part] = nil end
    end
end

-- ============================================================
-- TARGET SELECTION (unchanged)
-- ============================================================

local function getNormalInspireCount()
    local count = 0
    for part, data in pairs(activeTokens) do
        if data and data.kind == "Inspire" and not data.duped and part and part.Parent and getRemaining(data) > 0 then
            count += 1
        end
    end
    return count
end

local function getNextNormalInspire(excludePart)
    local best, bestRemaining = nil, math.huge
    for part, data in pairs(activeTokens) do
        if data and data.kind == "Inspire" and not data.duped and not data.teleported
            and part and part.Parent and part ~= excludePart then
            local remaining = getRemaining(data)
            if remaining > 0 and remaining < bestRemaining then best = data; bestRemaining = remaining end
        end
    end
    return best
end

local function getLowestLifetimeToken(kind)
    local best, bestRemaining = nil, math.huge
    for part, data in pairs(activeTokens) do
        if data.kind == kind and not data.teleported and part.Parent then
            local remaining = getRemaining(data)
            if remaining > 0 and remaining < bestRemaining then best = data; bestRemaining = remaining end
        end
    end
    return best
end

local function getMostExpiringInspire(excludePart)
    local best, bestRemaining = nil, math.huge
    for part, data in pairs(activeTokens) do
        if data.kind == "Inspire" and not data.teleported and part and part.Parent then
            local remaining = getRemaining(data)
            if part ~= excludePart and remaining > 0 and remaining < bestRemaining then
                best = data; bestRemaining = remaining
            end
        end
    end
    return best
end

-- ============================================================
-- ★ TELEPORT (FIXED: different hold for normal/duped + freeze)
-- ============================================================

local function teleportToToken(data, reason)
    if teleportBusy then return false end
    if not data or not data.part or not data.part.Parent then return false end
    local now = tick()
    if now - lastTeleport < TELEPORT_COOLDOWN then return false end
    local root = getRoot()
    if not root then return false end

    teleportBusy = true
    data.teleported = true
    destroyWall(data.part)

    -- ★ DUPED: TP на высоте ПЕРСОНАЖА, не токена
    if data.duped and data.kind == "Inspire" then
        local playerY = root.Position.Y
        pcall(function()
            root.CFrame = CFrame.new(data.part.Position.X, playerY, data.part.Position.Z)
        end)
        
        -- ★ ЗАМОРОЗКА на DUPED_INSPIRE_HOLD (1.1с)
        freezeCharacter()
        dupedInspireHoldPart = data.part
        dupedInspireHoldUntil = tick() + DUPED_INSPIRE_HOLD
        
        log(string.format("TP -> %s DUPED | reason=%s | FREEZE %.1fs | playerY=%.1f",
            data.kind, tostring(reason), DUPED_INSPIRE_HOLD, playerY))
    else
        -- ★ NORMAL: обычный TP на позицию токена
        pcall(function()
            root.CFrame = CFrame.new(data.part.Position)
        end)
        
        -- ★ NORMAL hold = 0.1с, БЕЗ заморозки
        dupedInspireHoldPart = nil
        dupedInspireHoldUntil = tick() + NORMAL_INSPIRE_HOLD
        
        log(string.format("TP -> %s NORMAL | reason=%s | hold=%.1fs",
            data.kind, tostring(reason), NORMAL_INSPIRE_HOLD))
    end

    lastTeleport = now

    -- Multi-inspire queue logic (unchanged)
    if data.kind == "Inspire" and not data.duped then
        local remainingNormalAfter = 0
        for part, other in pairs(activeTokens) do
            if other and other.kind == "Inspire" and not other.duped and not other.teleported
                and part and part.Parent and part ~= data.part and getRemaining(other) > 0 then
                remainingNormalAfter += 1
            end
        end
        if remainingNormalAfter >= 1 then
            multiInspireMode = true
            multiInspireTargetPart = data.part
            local buffRemainingNow = getBuffRemaining()
            local nextInspire = getNextNormalInspire(data.part)
            local nextUrgentAt = math.huge
            if nextInspire then
                nextUrgentAt = math.max(0, nextInspire.expiresAt - INSPIRE_TOKEN_URGENT_THRESHOLD - tick())
            end
            local buffWait = buffRemainingNow > 0 and buffRemainingNow or math.huge
            multiInspireHoldUntil = tick() + math.min(buffWait, nextUrgentAt)
        else
            multiInspireMode = false; multiInspireTargetPart = nil; multiInspireHoldUntil = 0
        end
    end

    task.delay(NORMAL_INSPIRE_HOLD, function() teleportBusy = false end)
    return true
end

-- ============================================================
-- DECISION (unchanged logic)
-- ============================================================

local function makeDecision()
    cleanupExpiredTokens()
    local buffRemaining = getBuffRemaining()

    if buffRemaining <= 0 then
        multiInspireMode = false; multiInspireTargetPart = nil; multiInspireHoldUntil = 0
        -- ★ Разморозка если buff кончился
        if dupedFreezeActive then unfreezeCharacter() end
        dupedInspireHoldUntil = 0; dupedInspireHoldPart = nil
        inspireLifetimeQueueMode = false; inspireLifetimeLastPart = nil; inspireLifetimeHoldUntil = 0
        return nil, "NO_ACTIVE_INSPIRE_BUFF"
    end

    -- ★ Hold после TP
    if dupedInspireHoldUntil > 0 then
        if tick() < dupedInspireHoldUntil then
            return nil, dupedFreezeActive and "DUPED_FREEZE_HOLD" or "NORMAL_HOLD"
        end
        -- ★ Hold закончился → разморозка
        if dupedFreezeActive then unfreezeCharacter() end
        dupedInspireHoldUntil = 0; dupedInspireHoldPart = nil
    end

    -- Lifetime queue
    if buffRemaining <= DUPED_BUFF_REFRESH_THRESHOLD then
        local nextInspire
        if inspireLifetimeQueueMode then
            nextInspire = getMostExpiringInspire(inspireLifetimeLastPart)
            if not nextInspire then
                inspireLifetimeQueueMode = false; inspireLifetimeLastPart = nil; inspireLifetimeHoldUntil = 0
            else
                inspireLifetimeLastPart = nextInspire.part
                inspireLifetimeHoldUntil = tick() + 1.1
                return nextInspire, "INSPIRE_LIFETIME_QUEUE_NEXT"
            end
        else
            nextInspire = getMostExpiringInspire(nil)
            if nextInspire then
                inspireLifetimeQueueMode = true; inspireLifetimeLastPart = nextInspire.part
                return nextInspire, "INSPIRE_LIFETIME_QUEUE_FIRST"
            end
        end
    end

    if buffRemaining <= INSPIRE_BUFF_REFRESH_THRESHOLD then
        local inspire = getMostExpiringInspire(nil)
        if inspire then return inspire, "BUFF_<=0.5_INSPIRE" end
        local link = getLowestLifetimeToken("Token Link")
        if link then return link, "BUFF_<=0.5_TOKEN_LINK" end
        return nil, "BUFF_<=0.5_NO_TOKEN"
    end

    return nil, "INSPIRE_BUFF_ACTIVE_WAIT"
end

-- ============================================================
-- MAIN LOOP
-- ============================================================

local accumulator = 0

RunService.Heartbeat:Connect(function(dt)
    accumulator += dt
    if accumulator < DECISION_INTERVAL then return end
    accumulator = 0

    syncWalls(getBuffRemaining())

    -- ★ Не принимаем решения во время заморозки
    if teleportBusy or dupedFreezeActive then return end

    local target, reason = makeDecision()
    if target then
        if reason ~= lastDecision then
            lastDecision = reason
            log(string.format("DECISION -> %s | target=%s | token=%.2fs | buff=%.2fs",
                reason, target.kind, getRemaining(target), getBuffRemaining()))
        end
        teleportToToken(target, reason)
    elseif reason ~= lastDecision then
        lastDecision = reason
        log(string.format("DECISION -> %s | buff=%.2fs", reason, getBuffRemaining()))
    end
end)

-- ============================================================
-- RESPAWN
-- ============================================================

LocalPlayer.CharacterAdded:Connect(function()
    teleportBusy = false; lastTeleport = 0
    multiInspireHoldUntil = 0; multiInspireTargetPart = nil; multiInspireMode = false
    -- ★ Разморозка при респавне
    unfreezeCharacter()
    dupedInspireHoldUntil = 0; dupedInspireHoldPart = nil
    inspireLifetimeQueueMode = false; inspireLifetimeLastPart = nil; inspireLifetimeHoldUntil = 0
    destroyAllWalls()
end)

print("========================================")
print("[InspireRefresh] v2.0 ACTIVE")
print("[InspireRefresh] Normal hold=0.1s | Duped hold=1.1s+FREEZE")
print("[InspireRefresh] Duped TP at player height")
print("[InspireRefresh] Character anchored during duped hold")
print("========================================")
