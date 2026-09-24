--[[
    Inspire Auto Refresh - optimized
    ------------------------------------------------------------
    Оптимизации:
    - Убраны все GUI.
    - Убран периодический Workspace:GetDescendants().
    - Новые токены ловятся через Workspace.DescendantAdded.
    - Удаление токенов ловится через Workspace.DescendantRemoving.
    - Inspire buff отслеживается через ServerBuffEvent.
    - Urgent Inspire token = <= 0.5s.
    - Inspire buff refresh threshold = <= 0.5s.

    Логика:
    1) Пока Inspire buff > 0.5s:
       - Token Link / Inspire не являются обычными целями.
       - Исключение: Inspire token с lifetime <= 0.5s -> TP к нему.

    2) Inspire buff <= 0.5s:
       - Token Link имеет приоритет.
       - Если его нет -> Inspire.

    3) Бафф закончился:
       - Token Link имеет приоритет.
       - Если его нет -> Inspire.

    Lifetime:
    Inspire = 8 * 1.21 = 9.68s
    Token Link = 4 * 1.21 = 4.84s
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

-- Оба порога специально 0.5s.
local INSPIRE_BUFF_REFRESH_THRESHOLD = 0.5
local INSPIRE_TOKEN_URGENT_THRESHOLD = 0.5

-- Минимальный интервал между TP.
local TELEPORT_COOLDOWN = 0.1

-- Невидимая круглая стена вокруг Inspire / Token Link
-- при активном Inspire buff.
local PROTECTED_RADIUS = 6
local WALL_SEGMENTS = 16
local WALL_HEIGHT = 20
local WALL_THICKNESS = 0.8
local WALL_ARC_SCALE = 1.10
local walls = {}
local activeTokens = {}

-- Частота принятия решения.
-- Нет полного сканирования Workspace.
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

local activeTokens = {}

local inspireBuffEnd = 0
local inspireBuffActive = false

local lastTeleport = 0
local teleportBusy = false

local lastDecision = ""

-- ============================================================
-- HELPERS
-- ============================================================

local function log(...)
    if LOGS then
        print("[InspireRefresh]", ...)
    end
end

local function getRoot()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function getServerNow()
    local ok, value = pcall(function()
        return Workspace:GetServerTimeNow()
    end)

    if ok and type(value) == "number" then
        return value
    end

    return os.time()
end

local function getTextureId(texture)
    if type(texture) ~= "string" then
        return nil
    end

    local id = texture:match("id=(%d+)")
        or texture:match("rbxassetid://(%d+)")

    return id and tonumber(id)
end

local function getTokenId(obj)
    if not obj or obj.Name ~= "C" or not obj:IsA("BasePart") then
        return nil
    end

    local front = obj:FindFirstChild("FrontDecal")
    if not front or not front:IsA("Decal") then
        return nil
    end

    local id = getTextureId(front.Texture)

    if id == INSPIRE_ID or id == TOKEN_LINK_ID then
        return id
    end

    return nil
end

local function isDuped(part)
    local root = getRoot()
    if not root then
        return false
    end

    return (part.Position.Y - root.Position.Y) > DUPED_HEIGHT_THRESHOLD
end

local function calculateLifetime(id, duped)
    local base

    if id == INSPIRE_ID then
        base = INSPIRE_BASE_LIFETIME
    elseif id == TOKEN_LINK_ID then
        base = TOKEN_LINK_BASE_LIFETIME
    else
        return 0
    end

    local normal = base * ABILITY_TOKEN_MULTIPLIER

    if not duped then
        return normal
    end

    local dupedMultiplier = 2 + 0.05 * (DIGITAL_BEE_LEVEL - 1)
    return normal * dupedMultiplier
end

local function getRemaining(data)
    return math.max(0, data.expiresAt - tick())
end

local function tokenKind(id)
    if id == INSPIRE_ID then
        return "Inspire"
    elseif id == TOKEN_LINK_ID then
        return "Token Link"
    end

    return "Unknown"
end

-- ============================================================
-- INVISIBLE 6-STUD TOKEN WALLS
-- ============================================================

local function destroyWall(part)
    local group = walls[part]
    if not group then
        return
    end

    for _, wallPart in ipairs(group) do
        if wallPart and wallPart.Parent then
            wallPart:Destroy()
        end
    end

    walls[part] = nil
end

local function destroyAllWalls()
    for part in pairs(walls) do
        destroyWall(part)
    end
end

local function createWall(part)
    if not part or not part.Parent or walls[part] then
        return
    end

    local group = {}

    -- Polygonal circular ring. The interior remains empty, so the
    -- player cannot cross the 6-stud boundary from outside.
    local circumference = 2 * math.pi * PROTECTED_RADIUS
    local segmentLength =
        (circumference / WALL_SEGMENTS) * WALL_ARC_SCALE

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
        wallPart.Size = Vector3.new(
            segmentLength,
            WALL_HEIGHT,
            WALL_THICKNESS
        )

        -- X axis of the part follows the circle tangent.
        wallPart.CFrame =
            CFrame.new(
                part.Position.X + x,
                part.Position.Y,
                part.Position.Z + z
            )
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
                    -- Rebuild if a wall segment was unexpectedly removed.
                    destroyWall(tokenPart)
                    createWall(tokenPart)
                    break
                end

                local angle = ((i - 1) / WALL_SEGMENTS) * (2 * math.pi)

                local x = math.cos(angle) * PROTECTED_RADIUS
                local z = math.sin(angle) * PROTECTED_RADIUS

                wallPart.CFrame =
                    CFrame.new(
                        tokenPos.X + x,
                        tokenPos.Y,
                        tokenPos.Z + z
                    )
                    * CFrame.Angles(0, angle + math.pi / 2, 0)
            end
        else
            destroyWall(tokenPart)
        end
    end
end

local function syncWalls(buffRemaining)
    if buffRemaining > INSPIRE_BUFF_REFRESH_THRESHOLD then
        for part, data in pairs(activeTokens) do
            if data
                and not data.teleported
                and part
                and part.Parent
            then
                if not walls[part] then
                    createWall(part)
                end
            else
                destroyWall(part)
            end
        end

        updateWallPositions()
    else
        -- Refresh window: remove every barrier before TP.
        destroyAllWalls()
    end
end

-- ============================================================
-- TOKEN STATE
-- ============================================================

local function unregisterToken(part)
    activeTokens[part] = nil
    destroyWall(part)
end

local function registerToken(part)
    if activeTokens[part] then
        return
    end

    local id = getTokenId(part)
    if not id then
        return
    end

    local duped = isDuped(part)

    -- Сохраняем поведение исходного Token Timer:
    -- duped Token Link не отслеживается.
    if duped and id == TOKEN_LINK_ID then
        return
    end

    local lifetime = calculateLifetime(id, duped)
    if lifetime <= 0 then
        return
    end

    local now = tick()

    activeTokens[part] = {
        part = part,
        id = id,
        kind = tokenKind(id),
        startTime = now,
        totalLifetime = lifetime,
        expiresAt = now + lifetime,
        duped = duped,
        teleported = false,
    }

    log(
        string.format(
            "TOKEN + %s | lifetime=%.2fs | %s",
            tokenKind(id),
            lifetime,
            duped and "DUPED" or "NORMAL"
        )
    )
end

local function inspectAddedObject(obj)
    if not obj then
        return
    end

    -- C появился уже с FrontDecal.
    if obj:IsA("BasePart") and obj.Name == "C" then
        registerToken(obj)
        return
    end

    -- C появился раньше, FrontDecal добавился позже.
    if obj:IsA("Decal") and obj.Name == "FrontDecal" then
        local parent = obj.Parent

        if parent and parent:IsA("BasePart") and parent.Name == "C" then
            registerToken(parent)
        end

        return
    end

    -- Дополнительная лёгкая проверка ближайшего родителя.
    local parent = obj.Parent

    if parent and parent:IsA("BasePart") and parent.Name == "C" then
        registerToken(parent)
    end
end

Workspace.DescendantAdded:Connect(inspectAddedObject)

Workspace.DescendantRemoving:Connect(function(obj)
    if activeTokens[obj] then
        unregisterToken(obj)
    end

    if obj:IsA("Decal") and obj.Name == "FrontDecal" then
        local parent = obj.Parent

        if parent and activeTokens[parent] then
            unregisterToken(parent)
        end
    end
end)

-- ============================================================
-- ONE-TIME INITIAL SCAN
-- ============================================================

-- Только один раз при запуске.
-- После этого полного GetDescendants больше нет.
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("BasePart") and obj.Name == "C" then
        registerToken(obj)
    end
end

-- ============================================================
-- INSPIRE BUFF
-- ============================================================

ServerBuffEvent.OnClientEvent:Connect(function(action, buffName, arg3, arg4, ...)
    if buffName ~= "Inspire" then
        return
    end

    if action == "Apply" then
        local startTime = tonumber(arg3)
        local duration = tonumber(arg4)

        -- Fallback для формата с дополнительной таблицей.
        if not startTime or not duration then
            local args = {...}

            for _, value in ipairs(args) do
                if type(value) == "table" then
                    if not startTime then
                        startTime = tonumber(value.Start)
                    end

                    if not duration then
                        duration = tonumber(value.Dur)
                    end
                end
            end
        end

        if startTime and duration then
            inspireBuffEnd = startTime + duration
            inspireBuffActive = true

            log(
                string.format(
                    "INSPIRE APPLY | duration=%.2fs | remaining=%.2fs",
                    duration,
                    math.max(0, inspireBuffEnd - getServerNow())
                )
            )
        else
            log("INSPIRE APPLY: Start/Dur not found")
        end

    elseif action == "Remove" then
        inspireBuffEnd = 0
        inspireBuffActive = false

        log("INSPIRE REMOVE")
    end
end)

local function getBuffRemaining()
    if not inspireBuffActive then
        return 0
    end

    local remaining = inspireBuffEnd - getServerNow()

    if remaining <= 0 then
        inspireBuffActive = false
        inspireBuffEnd = 0
        return 0
    end

    return remaining
end

-- ============================================================
-- TOKEN CLEANUP
-- ============================================================

local function cleanupExpiredTokens()
    local now = tick()

    for part, data in pairs(activeTokens) do
        if not part or not part.Parent then
            activeTokens[part] = nil
        elseif now >= data.expiresAt then
            activeTokens[part] = nil
        end
    end
end

-- ============================================================
-- TARGET SELECTION
-- ============================================================

local function getLowestLifetimeToken(kind)
    local best = nil
    local bestRemaining = math.huge

    for part, data in pairs(activeTokens) do
        if data.kind == kind and not data.teleported and part.Parent then
            local remaining = getRemaining(data)

            if remaining > 0 and remaining < bestRemaining then
                best = data
                bestRemaining = remaining
            end
        end
    end

    return best
end

local function getUrgentInspire()
    local best = nil
    local bestRemaining = math.huge

    for part, data in pairs(activeTokens) do
        if data.kind == "Inspire" and not data.teleported and part.Parent then
            local remaining = getRemaining(data)

            if remaining > 0
                and remaining <= INSPIRE_TOKEN_URGENT_THRESHOLD
                and remaining < bestRemaining
            then
                best = data
                bestRemaining = remaining
            end
        end
    end

    return best
end

-- ============================================================
-- TELEPORT
-- ============================================================

local function teleportToToken(data, reason)
    if teleportBusy then
        return false
    end

    if not data or not data.part or not data.part.Parent then
        return false
    end

    local now = tick()

    if now - lastTeleport < TELEPORT_COOLDOWN then
        return false
    end

    local root = getRoot()

    if not root then
        return false
    end

    teleportBusy = true

    -- Один конкретный токен = максимум один TP.
    -- Токен может ещё физически существовать после подбора,
    -- поэтому помечаем его consumed сразу.
    data.teleported = true

    -- Перед TP убираем защитное кольцо именно этого токена.
    destroyWall(data.part)

    pcall(function()
        root.CFrame = CFrame.new(data.part.Position)
    end)

    lastTeleport = now

    log(
        string.format(
            "TP -> %s | reason=%s | token=%.2fs | buff=%.2fs",
            data.kind,
            tostring(reason),
            getRemaining(data),
            getBuffRemaining()
        )
    )

    task.delay(0.05, function()
        teleportBusy = false
    end)

    return true
end

-- ============================================================
-- DECISION
-- ============================================================

local function makeDecision()
    cleanupExpiredTokens()

    local buffRemaining = getBuffRemaining()

    -- 1. Inspire token <= 0.5s:
    -- emergency, работает при любом баффе.
    -- Аварийный Inspire тоже разрешён только при активном buff.
    if buffRemaining > 0 then
        local urgentInspire = getUrgentInspire()

        if urgentInspire then
            return urgentInspire, "INSPIRE_URGENT_<=0.5"
        end
    end

    -- Без активного Inspire вообще не TP к Inspire / Token Link.
    if buffRemaining <= 0 then
        return nil, "NO_ACTIVE_INSPIRE_BUFF"
    end

    -- 3. Inspire buff <= 0.5s:
    -- Token Link > Inspire.
    if buffRemaining <= INSPIRE_BUFF_REFRESH_THRESHOLD then
        local link = getLowestLifetimeToken("Token Link")

        if link then
            return link, "BUFF_<=0.5_TOKEN_LINK"
        end

        local inspire = getLowestLifetimeToken("Inspire")

        if inspire then
            return inspire, "BUFF_<=0.5_INSPIRE"
        end

        return nil, "BUFF_<=0.5_NO_TOKEN"
    end

    -- 4. Бафф ещё активен, но до обновления > 0.5s:
    -- обычных TP к Inspire / Token Link пока нет.
    return nil, "INSPIRE_BUFF_ACTIVE"
end

-- ============================================================
-- LIGHTWEIGHT LOOP
-- ============================================================

local accumulator = 0

RunService.Heartbeat:Connect(function(dt)
    accumulator += dt

    if accumulator < DECISION_INTERVAL then
        return
    end

    accumulator = 0

    -- При активном buff > 0.5s строим 6-stud barriers.
    -- В окне обновления barriers удаляются ДО выбора цели/TP.
    syncWalls(getBuffRemaining())

    if teleportBusy then
        return
    end

    local target, reason = makeDecision()

    if target then
        if reason ~= lastDecision then
            lastDecision = reason
            log(
                string.format(
                    "DECISION -> %s | target=%s | token=%.2fs | buff=%.2fs",
                    reason,
                    target.kind,
                    getRemaining(target),
                    getBuffRemaining()
                )
            )
        end

        teleportToToken(target, reason)
    elseif reason ~= lastDecision then
        lastDecision = reason
        log(
            string.format(
                "DECISION -> %s | buff=%.2fs",
                reason,
                getBuffRemaining()
            )
        )
    end
end)

-- ============================================================
-- RESPAWN
-- ============================================================

LocalPlayer.CharacterAdded:Connect(function()
    teleportBusy = false
    lastTeleport = 0
    destroyAllWalls()
end)

print("========================================")
print("[InspireRefresh] OPTIMIZED ACTIVE")
print("[InspireRefresh] No token GUI")
print("[InspireRefresh] No buff GUI")
print("[InspireRefresh] No periodic Workspace:GetDescendants() scan")
print("[InspireRefresh] Inspire urgent <= 0.5s (only with active buff)")
print("[InspireRefresh] Inspire buff refresh <= 0.5s")
print("[InspireRefresh] No TP to Inspire/Token Link without active Inspire buff")
print("[InspireRefresh] One TP per token object")
print("[InspireRefresh] Invisible 6-stud collision ring while buff > 0.5s")
print("[InspireRefresh] Walls removed before refresh TP")
print("[InspireRefresh] Token priority: Token Link > Inspire")
print("========================================")
