-- Star Aura Timer + Token TP + Gumdrops Counter v2.3
-- FIX: При подборе токена (взлёт вверх) → мгновенный переход к следующему
-- FIX: Удаление из очереди по Y-движению, не по Parent=nil
-- FLOW: AURA(45s) → TP chain (0.1s hold) → next token immediately

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Events = ReplicatedStorage:FindFirstChild("Events")

-- ===============================
-- НАСТРОЙКИ
-- ===============================
local AURA_DURATION    = 45
local COOLDOWN         = 15
local TARGET_TOKEN_ID  = 1472135114
local TOKEN_HOLD       = 0.1    -- ★ 0.1 секунды на токене
local SCAN_RATE        = 0.05
local TOKEN_GAP        = 0.0    -- ★ НУЛЕВАЯ пауза между токенами — сразу следующий
local TP_EMPTY_GRACE   = 1.0
local TP_ARM_TIMEOUT   = 30
local TOGGLE_KEY       = Enum.KeyCode.H
local COLLECT_Y_THRESHOLD = 2.0 -- ★ если токен поднялся на N стадов → считаем подобранным

local TOKEN_ZONE = {
    minX = -537.67,
    maxX = -444.33,
    minZ = 476.75,
    maxZ = 590.94,
}

-- ===============================
-- СОСТОЯНИЕ
-- ===============================
local gummyRemaining     = 0
local scorchRemaining    = 0
local gummyVisible       = false
local scorchVisible      = false
local tpEnabled          = true
local tpActive           = false
local tokenQueue         = {}
local activeTokenParts   = {}

local gumdropsCount     = 0
local counting          = false
local cooldownEnd       = 0
local phase             = "IDLE"

local gummyApplied  = false
local scorchApplied = false
local gummyEndTime  = 0
local scorchEndTime = 0

local lastGumdropsResult = 0

-- ★ Отслеживание Y-позиции токенов для детекта подбора
local tokenBaseY = {}  -- part -> Y при регистрации

-- ===============================
-- HOOK: Gumdrops
-- ===============================
local function argsMentionGumdrop(args)
    for i = 1, #args do
        local a = args[i]
        if type(a) == "string" then
            if a:find("Gumdrop") then return true end
        elseif type(a) == "table" then
            for _, v in pairs(a) do
                if type(v) == "string" and v:find("Gumdrop") then return true end
            end
        end
    end
    return false
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    if getnamecallmethod() == "FireServer" and counting then
        local args = {...}
        if argsMentionGumdrop(args) then
            gumdropsCount = gumdropsCount + 1
        end
    end
    return oldNamecall(self, ...)
end)

-- ===============================
-- GUI
-- ===============================
local playerGui = LP:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("StarAuraGUI")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StarAuraGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 100)
frame.Position = UDim2.new(1, -230, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local gummyLabel = Instance.new("TextLabel")
gummyLabel.Size = UDim2.new(1, -10, 0, 18)
gummyLabel.Position = UDim2.new(0, 5, 0, 5)
gummyLabel.BackgroundTransparency = 1
gummyLabel.Text = ""
gummyLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
gummyLabel.Font = Enum.Font.GothamBold
gummyLabel.TextSize = 13
gummyLabel.TextXAlignment = Enum.TextXAlignment.Left
gummyLabel.Visible = false
gummyLabel.Parent = frame

local gummyBarBg = Instance.new("Frame")
gummyBarBg.Size = UDim2.new(1, -10, 0, 6)
gummyBarBg.Position = UDim2.new(0, 5, 0, 24)
gummyBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
gummyBarBg.BorderSizePixel = 0
gummyBarBg.Visible = false
gummyBarBg.Parent = frame

local gummyBarFill = Instance.new("Frame")
gummyBarFill.Size = UDim2.new(0, 0, 1, 0)
gummyBarFill.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
gummyBarFill.BorderSizePixel = 0
gummyBarFill.Parent = gummyBarBg

local scorchLabel = Instance.new("TextLabel")
scorchLabel.Size = UDim2.new(1, -10, 0, 18)
scorchLabel.Position = UDim2.new(0, 5, 0, 34)
scorchLabel.BackgroundTransparency = 1
scorchLabel.Text = ""
scorchLabel.TextColor3 = Color3.fromRGB(255, 140, 40)
scorchLabel.Font = Enum.Font.GothamBold
scorchLabel.TextSize = 13
scorchLabel.TextXAlignment = Enum.TextXAlignment.Left
scorchLabel.Visible = false
scorchLabel.Parent = frame

local scorchBarBg = Instance.new("Frame")
scorchBarBg.Size = UDim2.new(1, -10, 0, 6)
scorchBarBg.Position = UDim2.new(0, 5, 0, 53)
scorchBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
scorchBarBg.BorderSizePixel = 0
scorchBarBg.Visible = false
scorchBarBg.Parent = frame

local scorchBarFill = Instance.new("Frame")
scorchBarFill.Size = UDim2.new(0, 0, 1, 0)
scorchBarFill.BackgroundColor3 = Color3.fromRGB(255, 140, 40)
scorchBarFill.BorderSizePixel = 0
scorchBarFill.Parent = scorchBarBg

local gumdropsLabel = Instance.new("TextLabel")
gumdropsLabel.Size = UDim2.new(1, -10, 0, 16)
gumdropsLabel.Position = UDim2.new(0, 5, 0, 63)
gumdropsLabel.BackgroundTransparency = 1
gumdropsLabel.Text = ""
gumdropsLabel.TextColor3 = Color3.fromRGB(220, 100, 220)
gumdropsLabel.Font = Enum.Font.GothamBold
gumdropsLabel.TextSize = 12
gumdropsLabel.TextXAlignment = Enum.TextXAlignment.Left
gumdropsLabel.Visible = false
gumdropsLabel.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 14)
statusLabel.Position = UDim2.new(0, 5, 0, 82)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "TP: ON | Tokens: 0"
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- ===============================
-- SERVER BUFF EVENT
-- ===============================
local SBE = Events and Events:FindFirstChild("ServerBuffEvent")
if SBE then
    SBE.OnClientEvent:Connect(function(action, buffName, arg3, arg4)
        if action == "Apply" then
            local dur = AURA_DURATION
            if type(arg4) == "number" and arg4 > 0 then dur = arg4
            elseif type(arg3) == "number" and arg3 > 0 and arg3 < 1000 then dur = arg3 end

            if buffName == "Gummy Star Aura" and not gummyVisible then
                gummyApplied = true
                gummyVisible = true
                gummyEndTime = tick() + dur
                gummyRemaining = dur
            end

            if buffName == "Scorching Star Aura" and not scorchVisible then
                scorchApplied = true
                scorchVisible = true
                scorchEndTime = tick() + dur
                scorchRemaining = dur
            end
        end

        if action == "Remove" then
            if buffName == "Gummy Star Aura" then
                gummyApplied = false; gummyEndTime = 0; gummyRemaining = 0; gummyVisible = false
            end
            if buffName == "Scorching Star Aura" then
                scorchApplied = false; scorchEndTime = 0; scorchRemaining = 0; scorchVisible = false
            end
        end
    end)
end

-- ===============================
-- GUI UPDATE LOOP
-- ===============================
task.spawn(function()
    while true do
        if gummyVisible then
            gummyRemaining = math.max(0, gummyEndTime - tick())
            if gummyRemaining <= 0 then gummyVisible = false; gummyApplied = false end
        end
        if scorchVisible then
            scorchRemaining = math.max(0, scorchEndTime - tick())
            if scorchRemaining <= 0 then scorchVisible = false; scorchApplied = false end
        end

        gummyLabel.Visible = gummyVisible; gummyBarBg.Visible = gummyVisible
        if gummyVisible then
            gummyLabel.Text = string.format("Gummy: %.1fs", gummyRemaining)
            gummyBarFill.Size = UDim2.new(math.min(1, gummyRemaining / AURA_DURATION), 0, 1, 0)
        end

        scorchLabel.Visible = scorchVisible; scorchBarBg.Visible = scorchVisible
        if scorchVisible then
            scorchLabel.Text = string.format("Scorch: %.1fs", scorchRemaining)
            scorchBarFill.Size = UDim2.new(math.min(1, scorchRemaining / AURA_DURATION), 0, 1, 0)
        end

        if phase == "COUNTING" then
            gumdropsLabel.Visible = true
            gumdropsLabel.Text = string.format("Gumdrops: %d", gumdropsCount)
            gumdropsLabel.TextColor3 = Color3.fromRGB(220, 100, 220)
        elseif lastGumdropsResult >= 0 then
            gumdropsLabel.Visible = true
            gumdropsLabel.Text = string.format("Last: %d Gumdrops", lastGumdropsResult)
            gumdropsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        else
            gumdropsLabel.Visible = false
        end

        local phaseText
        if phase == "AURA" then phaseText = "AURA ACTIVE"
        elseif phase == "COOLDOWN" then phaseText = "COOLDOWN"
        elseif phase == "COUNTING" then phaseText = "COUNTING"
        else phaseText = "WAIT" end

        statusLabel.Text = string.format("%s | %s | T:%d",
            phaseText, tpActive and "TP" or (tpEnabled and "idle" or "OFF"), #tokenQueue)

        task.wait(0.1)
    end
end)

-- ===============================
-- TOKEN SCANNER
-- ===============================
local function getTextureId(texture)
    local id = texture:match("id=(%d+)") or texture:match("rbxassetid://(%d+)")
    return id and tonumber(id)
end

local function isInTokenZone(pos)
    return pos.X >= TOKEN_ZONE.minX and pos.X <= TOKEN_ZONE.maxX
        and pos.Z >= TOKEN_ZONE.minZ and pos.Z <= TOKEN_ZONE.maxZ
end

local function tryRegister(obj)
    if not obj or not obj.Parent then return end
    local part
    if obj:IsA("BasePart") then part = obj
    elseif obj:IsA("Decal") and obj.Parent and obj.Parent:IsA("BasePart") then part = obj.Parent
    else return end

    if part.Name ~= "C" then return end
    if activeTokenParts[part] then return end

    local front = part:FindFirstChild("FrontDecal")
    if not (front and front:IsA("Decal")) then return end

    local id = getTextureId(front.Texture)
    if id ~= TARGET_TOKEN_ID then return end
    if not isInTokenZone(part.Position) then return end

    activeTokenParts[part] = true
    tokenBaseY[part] = part.Position.Y  -- ★ запоминаем стартовую Y
    tokenQueue[#tokenQueue + 1] = {part = part, addedAt = tick()}
end

Workspace.DescendantAdded:Connect(tryRegister)
for _, obj in ipairs(Workspace:GetDescendants()) do tryRegister(obj) end

-- ★ Чистка + детект подбора через Y-движение
task.spawn(function()
    while true do
        local filtered = {}
        for _, entry in ipairs(tokenQueue) do
            local p = entry.part
            if p and p.Parent and activeTokenParts[p] then
                -- ★ Детект подбора: токен взлетел вверх
                local baseY = tokenBaseY[p] or p.Position.Y
                if p.Position.Y - baseY > COLLECT_Y_THRESHOLD then
                    -- Токен подобран → убираем из очереди
                    activeTokenParts[p] = nil
                    tokenBaseY[p] = nil
                else
                    filtered[#filtered + 1] = entry
                end
            elseif p then
                activeTokenParts[p] = nil
                tokenBaseY[p] = nil
            end
        end
        tokenQueue = filtered
        task.wait(SCAN_RATE)
    end
end)

-- ===============================
-- TP LOGIC
-- ===============================
local function getHRP()
    local c = LP.Character
    if not c then return nil, nil end
    return c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

local camLocked = false
local camSavedCF, camSavedType

local function lockCamera()
    if camLocked then return end
    camSavedCF = Camera.CFrame
    camSavedType = Camera.CameraType
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = camSavedCF
    RunService:BindToRenderStep("StarTP_CamLock", 0, function() Camera.CFrame = camSavedCF end)
    camLocked = true
end

local function endCollection()
    if camLocked then
        RunService:UnbindFromRenderStep("StarTP_CamLock")
        Camera.CameraType = camSavedType
        camLocked = false
    end
    local _, hum = getHRP()
    if hum then hum.AutoRotate = true; hum:ChangeState(Enum.HumanoidStateType.Running) end
end

-- ★ ТП: стоим 0.1с, потом СРАЗУ следующий (TOKEN_GAP = 0)
-- ★ Если токен улетел вверх во время hold → прерываем и берём следующий
local function tpToToken(part)
    if not part or not part.Parent then return false end
    local hrp, hum = getHRP()
    if not hrp or not hum then return false end

    lockCamera()
    hum.AutoRotate = false

    local targetCF = CFrame.new(part.Position.X, part.Position.Y, part.Position.Z)
    local baseY = tokenBaseY[part] or part.Position.Y

    local hbConn = RunService.Heartbeat:Connect(function()
        if hrp.Parent then
            hrp.CFrame = targetCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)

    -- ★ Ждём TOKEN_HOLD, но прерываем если токен улетел вверх
    local startTime = tick()
    while tick() - startTime < TOKEN_HOLD do
        -- Проверяем: токен ещё на месте?
        if not part.Parent or part.Position.Y - baseY > COLLECT_Y_THRESHOLD then
            break  -- ★ Токен подобран → выходим немедленно
        end
        task.wait(0.01)
    end

    hbConn:Disconnect()
    return true
end

-- ===============================
-- MAIN STATE MACHINE
-- ===============================
task.spawn(function()
    local wasGummyActive = false
    local emptySince = nil
    local sawToken = false
    local armedAt = 0

    while true do
        local gummyNow = gummyApplied and gummyVisible and gummyRemaining > 0

        if not wasGummyActive and gummyNow then
            if counting then lastGumdropsResult = gumdropsCount end
            counting = false; gumdropsCount = 0
            if tpActive then endCollection() end
            tpActive = false; emptySince = nil; sawToken = false; cooldownEnd = 0
            phase = "AURA"
        end

        if wasGummyActive and not gummyNow then
            lastGumdropsResult = -1
            counting = false
            tpActive = tpEnabled
            emptySince = nil; sawToken = false; armedAt = tick()
            cooldownEnd = tick() + COOLDOWN
            phase = "COOLDOWN"
        end

        if phase == "COOLDOWN" and tick() >= cooldownEnd then
            counting = true; gumdropsCount = 0; phase = "COUNTING"
        end

        if tpActive and tpEnabled then
            if #tokenQueue > 0 then
                sawToken = true; emptySince = nil
                local entry = tokenQueue[1]
                if entry and entry.part and entry.part.Parent then
                    tpToToken(entry.part)
                    -- ★ После hold: убираем токен из очереди (он либо подобран, либо мы уходим)
                    table.remove(tokenQueue, 1)
                    activeTokenParts[entry.part] = nil
                    tokenBaseY[entry.part] = nil
                else
                    table.remove(tokenQueue, 1)
                end
                -- ★ TOKEN_GAP = 0 → никакого ожидания, сразу следующий
            else
                emptySince = emptySince or tick()
                local waited = tick() - emptySince
                local noTokensEver = (not sawToken) and (tick() - armedAt >= TP_ARM_TIMEOUT)
                if sawToken and waited >= TP_EMPTY_GRACE then
                    tpActive = false; emptySince = nil; endCollection()
                elseif noTokensEver then
                    tpActive = false; emptySince = nil; endCollection()
                end
            end
        end

        wasGummyActive = gummyNow
        task.wait(0.05)
    end
end)

-- ===============================
-- TOGGLE
-- ===============================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == TOGGLE_KEY then
        tpEnabled = not tpEnabled
        if not tpEnabled then tpActive = false; endCollection() end
        print("[StarTP] TP " .. (tpEnabled and "ON" or "OFF"))
    end
end)

LP.CharacterAdded:Connect(function()
    if tpActive then endCollection() end
    tpActive = false; tokenQueue = {}; activeTokenParts = {}; tokenBaseY = {}
    gumdropsCount = 0; counting = false; cooldownEnd = 0; lastGumdropsResult = 0
    phase = "IDLE"; gummyVisible = false; scorchVisible = false
    gummyApplied = false; scorchApplied = false; gummyEndTime = 0; scorchEndTime = 0
end)

print("=== Star Aura + Token TP + Gumdrops v2.3 ===")
print("  Hold=0.1s | Gap=0 | Instant next on collect")
print("=============================================")
