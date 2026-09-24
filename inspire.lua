--[[
    Inspire Auto Refresh + Token Timer
    ------------------------------------------------------------
    Логика:

    1) Inspire token:
       Name = "C"
       Class = BasePart
       Child "FrontDecal" = Decal
       Texture ID = 2000457501

    2) Token Link:
       Name = "C"
       Class = BasePart
       Child "FrontDecal" = Decal
       Texture ID = 1629547638

    3) Inspire buff:
       ServerBuffEvent -> Apply, "Inspire"
       Arg3 = Start timestamp
       Arg4 = Duration
       Extra table содержит те же данные.

    4) Пока Inspire buff > 0.5s:
       - НЕ трогаем Inspire / Token Link обычным приоритетом.
       - ИСКЛЮЧЕНИЕ: если Inspire token сам доживает до <= 0.6s,
         телепортируемся к нему независимо от текущего баффа.

    5) Inspire buff <= 0.5s:
       - Token Link имеет приоритет.
       - Если Token Link нет -> Inspire.
       - Если подходящего токена нет -> продолжаем ждать.

    6) Inspire buff закончился:
       - Token Link имеет приоритет.
       - Если Token Link нет -> Inspire.

    7) Inspire lifetime:
       BASE = 8s
       * ABILITY_TOKEN_MULTIPLIER (1.21 из исходного Token Timer)
       = 9.68s для обычного Inspire.

    8) Token Link lifetime:
       BASE = 4s
       * ABILITY_TOKEN_MULTIPLIER
       = 4.84s.

    9) DUPED:
       Сохраняется логика исходного Token Timer:
       если token выше игрока более чем на DUPED_HEIGHT_THRESHOLD,
       применяется Digital Bee multiplier.
       Для duped Token Link оригинальный таймер его игнорировал,
       поэтому здесь тоже игнорируем.

    ВАЖНО:
    Этот скрипт управляет только своей логикой TP к Inspire/Token Link.
    Он не может физически запретить другой скрипт собирать эти токены.
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

-- При каком остатке баффа начинаем обновление Inspire.
local INSPIRE_BUFF_REFRESH_THRESHOLD = 0.5

-- Если сам Inspire token уже почти исчезает,
-- собираем его независимо от текущего баффа.
local INSPIRE_TOKEN_URGENT_THRESHOLD = 0.6

-- Небольшая задержка после TP, чтобы не делать пачку TP подряд.
local TELEPORT_COOLDOWN = 0.1

-- Период служебного поиска.
local SCAN_INTERVAL = 0.1

-- Расстояние вертикального смещения при TP.
-- 0 = прямо в token.
local TELEPORT_Y_OFFSET = 0

local SHOW_TOKEN_GUI = true
local SHOW_BUFF_GUI = true
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
local tokenGuis = {}

local inspireBuffEnd = 0
local inspireBuffActive = false

local lastTeleport = 0
local teleportBusy = false

local lastDecision = ""
local lastDecisionTime = 0

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
    -- ServerBuffEvent Arg3 выглядит как Unix/server timestamp.
    -- GetServerTimeNow() даёт согласованный server-time.
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

local function getPlayerY()
    local root = getRoot()
    return root and root.Position.Y or 0
end

local function isDuped(part)
    local root = getRoot()
    if not root then
        return false
    end

    return (part.Position.Y - root.Position.Y) > DUPED_HEIGHT_THRESHOLD
end

local function getBaseLifetime(id)
    if id == INSPIRE_ID then
        return INSPIRE_BASE_LIFETIME
    elseif id == TOKEN_LINK_ID then
        return TOKEN_LINK_BASE_LIFETIME
    end

    return 0
end

local function calculateLifetime(id, duped)
    local base = getBaseLifetime(id)

    if base <= 0 then
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
-- GUI
-- ============================================================

local function destroyTokenGui(part)
    local gui = tokenGuis[part]

    if gui then
        pcall(function()
            gui:Destroy()
        end)
    end

    tokenGuis[part] = nil
end

local function createTokenGui(part, id)
    if not SHOW_TOKEN_GUI then
        return
    end

    destroyTokenGui(part)

    local gui = Instance.new("BillboardGui")
    gui.Name = "AutoRefreshTimer"
    gui.Adornee = part
    gui.Size = UDim2.new(0, 145, 0, 26)
    gui.StudsOffset = Vector3.new(0, 2.5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 1000
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.Name = "Timer"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 0.18
    label.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    label.TextColor3 =
        id == INSPIRE_ID
        and Color3.fromRGB(255, 225, 80)
        or Color3.fromRGB(120, 220, 255)
    label.TextStrokeTransparency = 0.25
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = tokenKind(id) .. ": --"
    label.Parent = gui

    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 5)

    tokenGuis[part] = gui
end

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("InspireRefreshGUI")
if oldGui then
    oldGui:Destroy()
end

local mainGui = Instance.new("ScreenGui")
mainGui.Name = "InspireRefreshGUI"
mainGui.ResetOnSpawn = false
mainGui.Parent = playerGui

local buffLabel

if SHOW_BUFF_GUI then
    buffLabel = Instance.new("TextLabel")
    buffLabel.Name = "InspireBuff"
    buffLabel.Size = UDim2.new(0, 300, 0, 30)
    buffLabel.Position = UDim2.new(0, 10, 0, 10)
    buffLabel.BackgroundTransparency = 0.15
    buffLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    buffLabel.TextColor3 = Color3.fromRGB(255, 210, 70)
    buffLabel.TextStrokeTransparency = 0.25
    buffLabel.Font = Enum.Font.GothamBold
    buffLabel.TextSize = 14
    buffLabel.TextXAlignment = Enum.TextXAlignment.Left
    buffLabel.Text = "Inspire buff: 0.00s"
    buffLabel.Parent = mainGui

    Instance.new("UICorner", buffLabel).CornerRadius = UDim.new(0, 6)
end

-- ============================================================
-- TOKEN REGISTRATION
-- ============================================================

local function unregisterToken(part)
    activeTokens[part] = nil
    destroyTokenGui(part)
end

local function registerToken(part)
    local id = getTokenId(part)

    if not id then
        return
    end

    if activeTokens[part] then
        return
    end

    local duped = isDuped(part)

    -- Как в исходном Token Timer:
    -- duped Token Link не отслеживаем.
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
        createdAt = now,
    }

    createTokenGui(part, id)

    log(
        "TOKEN +",
        tokenKind(id),
        string.format("lifetime=%.2fs", lifetime),
        duped and "DUPED" or "NORMAL"
    )
end

-- Если FrontDecal появляется немного позже C,
-- перепроверяем самого родителя.
local function inspectAddedObject(obj)
    if not obj then
        return
    end

    if obj:IsA("BasePart") and obj.Name == "C" then
        registerToken(obj)
        return
    end

    if obj:IsA("Decal") and obj.Name == "FrontDecal" then
        local parent = obj.Parent

        if parent and parent:IsA("BasePart") and parent.Name == "C" then
            registerToken(parent)
        end

        return
    end

    -- Иногда структура может достраиваться несколькими шагами.
    -- Проверяем ближайшего BasePart-родителя.
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

    -- Если удалился FrontDecal, токен теряет идентификацию.
    if obj:IsA("Decal") and obj.Name == "FrontDecal" then
        local parent = obj.Parent

        if parent and activeTokens[parent] then
            unregisterToken(parent)
        end
    end
end)

-- Первичный scan
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("BasePart") and obj.Name == "C" then
        registerToken(obj)
    end
end

-- ============================================================
-- INSPIRE BUFF DETECTION
-- ============================================================

ServerBuffEvent.OnClientEvent:Connect(function(action, buffName, arg3, arg4, ...)
    if buffName ~= "Inspire" then
        return
    end

    if action == "Apply" then
        local startTime = tonumber(arg3)
        local duration = tonumber(arg4)

        if not startTime or not duration then
            -- Фоллбек: ищем Dur/Start во всех дополнительных таблицах.
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
                    "INSPIRE APPLY | duration=%.2fs | endIn=%.2fs",
                    duration,
                    math.max(0, inspireBuffEnd - getServerNow())
                )
            )
        else
            log("INSPIRE APPLY detected, but Start/Dur was not readable")
        end

    elseif action == "Remove" then
        inspireBuffEnd = 0
        inspireBuffActive = false

        log("INSPIRE REMOVE")
    end
end)

-- ============================================================
-- TARGET SELECTION
-- ============================================================

local function cleanupExpiredTokens()
    local now = tick()

    for part, data in pairs(activeTokens) do
        if not part or not part.Parent then
            unregisterToken(part)
        elseif now >= data.expiresAt then
            unregisterToken(part)
        end
    end
end

local function getBestToken(kind)
    local best = nil
    local bestRemaining = math.huge
    local root = getRoot()

    for part, data in pairs(activeTokens) do
        if data.kind == kind and part.Parent then
            local remaining = getRemaining(data)

            if remaining > 0 then
                if kind == "Inspire" then
                    -- Для Inspire приоритет у самого быстро исчезающего.
                    if remaining < bestRemaining then
                        best = data
                        bestRemaining = remaining
                    end
                else
                    -- Для Token Link тоже выбираем наиболее срочный.
                    if remaining < bestRemaining then
                        best = data
                        bestRemaining = remaining
                    end
                end
            end
        end
    end

    return best
end

local function getNearestToken(kind)
    local root = getRoot()
    if not root then
        return nil
    end

    local best = nil
    local bestDistance = math.huge

    for _, data in pairs(activeTokens) do
        if data.kind == kind and data.part.Parent then
            local remaining = getRemaining(data)

            if remaining > 0 then
                local distance = (data.part.Position - root.Position).Magnitude

                if distance < bestDistance then
                    best = data
                    bestDistance = distance
                end
            end
        end
    end

    return best
end

local function getUrgentInspire()
    local best = nil
    local bestRemaining = math.huge

    for _, data in pairs(activeTokens) do
        if data.kind == "Inspire" and data.part.Parent then
            local remaining = getRemaining(data)

            if remaining > 0 and remaining <= INSPIRE_TOKEN_URGENT_THRESHOLD then
                if remaining < bestRemaining then
                    best = data
                    bestRemaining = remaining
                end
            end
        end
    end

    return best
end

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

    local targetPos =
        data.part.Position
        + Vector3.new(0, TELEPORT_Y_OFFSET, 0)

    pcall(function()
        root.CFrame = CFrame.new(targetPos)
    end)

    lastTeleport = now

    log(
        string.format(
            "TP -> %s | reason=%s | tokenRemaining=%.2fs | buffRemaining=%.2fs",
            data.kind,
            tostring(reason),
            getRemaining(data),
            getBuffRemaining()
        )
    )

    task.delay(0.08, function()
        teleportBusy = false
    end)

    return true
end

-- ============================================================
-- DECISION ENGINE
-- ============================================================

local function makeDecision()
    cleanupExpiredTokens()

    local buffRemaining = getBuffRemaining()

    -- ========================================================
    -- PRIORITY 1:
    -- Сам Inspire token вот-вот исчезает.
    -- Это ИСКЛЮЧЕНИЕ, работает при ЛЮБОМ Inspire buff.
    -- ========================================================

    local urgentInspire = getUrgentInspire()

    if urgentInspire then
        return urgentInspire, "INSPIRE_TOKEN_URGENT"
    end

    -- ========================================================
    -- PRIORITY 2:
    -- Inspire buff <= 0.5s -> обновление.
    --
    -- Token Link > Inspire
    -- ========================================================

    if buffRemaining <= INSPIRE_BUFF_REFRESH_THRESHOLD then
        local link = getBestToken("Token Link")

        if link then
            return link, "BUFF_REFRESH_TOKEN_LINK"
        end

        local inspire = getBestToken("Inspire")

        if inspire then
            return inspire, "BUFF_REFRESH_INSPIRE"
        end

        return nil, "WAITING_FOR_REFRESH_TOKEN"
    end

    -- ========================================================
    -- PRIORITY 3:
    -- Inspire buff активен > 0.5s.
    --
    -- Нельзя целиться в Inspire / Token Link.
    -- Идем дальше без TP к этим токенам.
    -- ========================================================

    if buffRemaining > 0.5 then
        return nil, "INSPIRE_BUFF_ACTIVE_BLOCK"
    end

    -- ========================================================
    -- PRIORITY 4:
    -- Бафф закончился.
    --
    -- Token Link > Inspire
    -- ========================================================

    local link = getBestToken("Token Link")

    if link then
        return link, "NO_BUFF_TOKEN_LINK"
    end

    local inspire = getBestToken("Inspire")

    if inspire then
        return inspire, "NO_BUFF_INSPIRE"
    end

    return nil, "NO_TARGET"
end

-- ============================================================
-- MAIN HEARTBEAT
-- ============================================================

local scanAccumulator = 0

RunService.Heartbeat:Connect(function(dt)
    scanAccumulator += dt

    -- ========================================================
    -- GUI / Token timers
    -- ========================================================

    local buffRemaining = getBuffRemaining()

    if buffLabel then
        if buffRemaining > 0 then
            buffLabel.Text = string.format(
                "Inspire buff: %.2fs",
                buffRemaining
            )

            if buffRemaining <= INSPIRE_BUFF_REFRESH_THRESHOLD then
                buffLabel.TextColor3 = Color3.fromRGB(255, 100, 80)
            else
                buffLabel.TextColor3 = Color3.fromRGB(255, 210, 70)
            end
        else
            buffLabel.Text = "Inspire buff: 0.00s"
            buffLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end

    for part, data in pairs(activeTokens) do
        if not part or not part.Parent then
            unregisterToken(part)
        else
            local remaining = getRemaining(data)

            local gui = tokenGuis[part]

            if gui then
                local label = gui:FindFirstChild("Timer")

                if label then
                    label.Text = string.format(
                        "%s: %.2fs",
                        data.kind,
                        remaining
                    )

                    if data.kind == "Inspire"
                        and remaining <= INSPIRE_TOKEN_URGENT_THRESHOLD
                    then
                        label.TextColor3 = Color3.fromRGB(255, 80, 80)
                    end
                end
            end

            if remaining <= 0 then
                unregisterToken(part)
            end
        end
    end

    -- ========================================================
    -- Periodic rescan
    -- Нужно на случай, если C и FrontDecal создаются в разные кадры.
    -- ========================================================

    if scanAccumulator >= SCAN_INTERVAL then
        scanAccumulator = 0

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name == "C" then
                registerToken(obj)
            end
        end
    end

    -- ========================================================
    -- DECISION / TP
    -- ========================================================

    if teleportBusy then
        return
    end

    local target, reason = makeDecision()

    if target then
        if reason ~= lastDecision then
            lastDecision = reason
            lastDecisionTime = tick()

            log(
                string.format(
                    "DECISION -> %s | target=%s | buff=%.2fs | token=%.2fs",
                    reason,
                    target.kind,
                    buffRemaining,
                    getRemaining(target)
                )
            )
        end

        teleportToToken(target, reason)
    elseif reason ~= lastDecision then
        lastDecision = reason
        lastDecisionTime = tick()

        if LOGS then
            log(
                string.format(
                    "DECISION -> %s | buff=%.2fs",
                    reason,
                    buffRemaining
                )
            )
        end
    end
end)

-- ============================================================
-- RESPAWN
-- ============================================================

LocalPlayer.CharacterAdded:Connect(function()
    teleportBusy = false
    lastTeleport = 0

    -- Buff state не сбрасываем искусственно:
    -- ServerBuffEvent сам пришлёт актуальный Remove/Apply.
end)

print("========================================")
print("[InspireRefresh] ACTIVE")
print(string.format(
    "[InspireRefresh] Inspire lifetime = %.2fs (8 * %.2f)",
    INSPIRE_BASE_LIFETIME * ABILITY_TOKEN_MULTIPLIER,
    ABILITY_TOKEN_MULTIPLIER
))
print(string.format(
    "[InspireRefresh] Token Link lifetime = %.2fs",
    TOKEN_LINK_BASE_LIFETIME * ABILITY_TOKEN_MULTIPLIER
))
print(string.format(
    "[InspireRefresh] Buff refresh <= %.2fs",
    INSPIRE_BUFF_REFRESH_THRESHOLD
))
print(string.format(
    "[InspireRefresh] Inspire urgent <= %.2fs",
    INSPIRE_TOKEN_URGENT_THRESHOLD
))
print("[InspireRefresh] Priority: urgent Inspire -> Token Link -> Inspire")
print("========================================")
