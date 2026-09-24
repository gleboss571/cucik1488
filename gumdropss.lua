-- Star Aura Auto-Equip v3.7
-- CORRECTED LOGIC:
-- Ball detected → SCYTHE (набивка)
-- Gummy ending (<5s) → always GUMMY MASK
-- Gummy ended → DEMON MASK
-- Solo Gummy (no Scorch) → BALLER
-- Gummy+Scorch, no Ball → BALLER

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Events = ReplicatedStorage:WaitForChild("Events")
local ItemPackageEvent = Events:WaitForChild("ItemPackageEvent")

-- ===============================
-- НАСТРОЙКИ
-- ===============================
local AURA_DURATION       = 45
local COOLDOWN            = 15
local GUMMY_END_THRESHOLD = 5   -- служебный порог окончания ауры
local BALL_SWITCH_THRESHOLD = 15 -- Ball переключает на косу только при Gummy < 15с
local BALL_SWITCH_DELAY = 0.1   -- задержка после детекта Ball перед фиксацией косы
local AUTO_TOGGLE_KEY = Enum.KeyCode.H

-- ===============================
-- ПРЕДМЕТЫ
-- ===============================
local EQUIP = {
    DemonMask   = { Category = "Accessory", Type = "Demon Mask" },
    GummyMask   = { Category = "Accessory", Type = "Gummy Mask" },
    DarkScythe  = { Category = "Collector", Type = "Dark Scythe", Amount = 1 },
    Gummyballer = { Category = "Collector", Type = "Gummyballer" },
}

-- ===============================
-- МАТРИЦА РЕШЕНИЙ [Scorch_bucket][Gummy_bucket]
-- Используется как БАЗОВОЕ решение когда нет Ball и не конец ауры
-- ===============================
local DECISION_MATRIX = {
    {"KD","KD","GM_K","GM_K","GM_B","GM_B","GM_B","GM_B","GM_B","GM_B"},
    {"KD","KD","GM_K","GM_K","GM_B","GM_B","GM_B","GM_B","GM_B","GM_B"},
    {"KD","KD","GM_K","GM_K","GM_B","GM_B","GM_B","GM_B","GM_B","GM_B"},
    {"KD","KD","GM_K","GM_K","GM_B","GM_B","GM_B","GM_B","GM_B","GM_B"},
    {"KD","KD","GM_K","GM_K","GM_B","GM_B","GM_B","GM_B","GM_B","GM_B"},
    {"KD","KD","GM_K","GM_K","GM_B","GM_B","GM_B","PREP","PREP","PREP"},
    {"KD","KD","GM_K","GM_K","GM_B","GM_B","GM_B","PREP","PREP","PREP"},
    {"KD","KD","GM_K","GM_K","GM_B","GM_B","GM_B","PREP","PREP","PREP"},
    {"KD","KD","GM_K","GM_K","GM_B","GM_B","GM_B","PREP","PREP","PREP"},
    {"KD","KD","GM_K","GM_K","GM_B","GM_B","GM_B","PREP","PREP","PREP"},
}

local function getPrepDuration(gummyRem)
    if gummyRem >= 43 then return 10
    elseif gummyRem >= 38 then return 12
    else return 15 end
end

-- ===============================
-- СОСТОЯНИЕ
-- ===============================
local gummyRemaining  = 0
local scorchRemaining = 0
local gummyVisible    = false
local scorchVisible   = false
local gummyApplied    = false
local scorchApplied   = false
local gummyEndTime    = 0
local scorchEndTime   = 0

local autoMode         = true
local currentLoadout   = ""
local prepStartTime    = 0
local inPrepPhase      = false
local currentPrepDur   = 12
local prepUsedThisAura = false
local ballPresent      = false
local ballDetectedAt    = 0
local ballTriggeredThisAura = false

-- Gumdrops
local gumdropsCount      = 0
local counting           = false
local cooldownEnd        = 0
local phase              = "IDLE"
local lastGumdropsResult = 0

-- Manual
-- ===============================
-- HOOK: GUMDROPS
-- ===============================
local function argsMentionGumdrop(args)
    for i = 1, #args do
        local a = args[i]
        if type(a) == "string" and a:find("Gumdrop") then return true end
        if type(a) == "table" then
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
        if argsMentionGumdrop(args) then gumdropsCount = gumdropsCount + 1 end
    end
    return oldNamecall(self, ...)
end)

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
                gummyApplied = true; gummyVisible = true
                gummyEndTime = tick() + dur; gummyRemaining = dur
            end
            if buffName == "Scorching Star Aura" and not scorchVisible then
                scorchApplied = true; scorchVisible = true
                scorchEndTime = tick() + dur; scorchRemaining = dur
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
-- BALL DETECTION + DELAYED SWITCH (Heartbeat)
-- ===============================
RunService.Heartbeat:Connect(function()
    local cam = Workspace.CurrentCamera
    local found = false
    if cam then
        for _, child in ipairs(cam:GetChildren()) do
            if child.Name == "Ball" then
                found = true
                break
            end
        end
    end

    if found and not ballPresent then
        ballPresent = true
        ballDetectedAt = os.clock()
        print(string.format("[Ball] SPAWNED | waiting %.2fs before switch", BALL_SWITCH_DELAY))
    elseif not found and ballPresent then
        ballPresent = false
        ballDetectedAt = 0
        print("[Ball] GONE")
    end

    -- Переключение происходит не в момент появления Ball, а после небольшой задержки.
    -- Условие Gummy < 15с проверяется непосредственно здесь, в Heartbeat.
    if ballPresent and not ballTriggeredThisAura and ballDetectedAt > 0 and (os.clock() - ballDetectedAt) >= BALL_SWITCH_DELAY then
        local gRemNow = gummyVisible and math.max(0, gummyEndTime - tick()) or 0
        if autoMode and gRemNow < BALL_SWITCH_THRESHOLD and gummyVisible then
            ballTriggeredThisAura = true
            currentLoadout = "" -- разрешаем следующему проходу авто-цикла переодеться
            print(string.format("[Ball] SWITCH TRIGGERED | Gummy=%.2fs < %.2fs", gRemNow, BALL_SWITCH_THRESHOLD))
        elseif gummyVisible and gRemNow >= BALL_SWITCH_THRESHOLD then
            -- Ball появился слишком рано: этот Ball не активирует переключение.
            print(string.format("[Ball] IGNORED | Gummy=%.2fs >= %.2fs", gRemNow, BALL_SWITCH_THRESHOLD))
            ballDetectedAt = -1
        end
    end
end)

-- ===============================
-- ★ DECIDE LOADOUT (ИСПРАВЛЕННАЯ ЛОГИКА v3.7)
--
-- Приоритет правил (сверху вниз):
-- 1. Аура кончилась          → KD (Демон + Коса)
-- 2. Ball + Gummy <15с      → GM_K и зафиксировать до конца Gummy
-- 3. Уже выбран Gummyballer   → держать его до Ball
-- 4. Prep фаза                → PREP (Демон + Коса)
-- 5. Матрица                  → базовое решение
-- ===============================
local function bucket(val)
    local clamped = math.max(0, math.min(45, val))
    local idx = math.floor(clamped / 5) + 1
    return math.min(idx, 10)
end

local function decideLoadout(gRem, sRem, auraActive)
    -- ★ 1. Аура закончилась → всегда Демон + Коса
    if not auraActive then
        inPrepPhase = false
        return "KD"
    end

    -- ★ 2. Ball — единственный триггер перехода Baller → Scythe
    -- Срабатывает только в последние 15с Gummy.
    -- Само переключение предварительно подтверждается Heartbeat с небольшой задержкой.
    -- После срабатывания фиксируем GM_K до конца Gummy-ауры,
    -- даже если сам Ball исчез из Camera.
        if ballTriggeredThisAura then
        inPrepPhase = false
        return "GM_K"
    end

    -- ★ 3. Пока Ball не был задетекчен, не сбрасываем Baller
    -- из-за последних секунд Gummy или из-за матрицы.
    -- Если уже стоял Gummyballer, держим его до фактического Ball.
    if currentLoadout == "GM_B" then
        inPrepPhase = false
        return "GM_B"
    end

    -- ★ 4. Prep фаза
    if inPrepPhase then
        local elapsed = tick() - prepStartTime
        if elapsed < currentPrepDur then
            return "PREP"
        else
            inPrepPhase = false
            -- Prep закончилась → падаем в матрицу
        end
    end

    -- ★ 5. Матричное решение
    local sIdx = bucket(sRem)
    local gIdx = bucket(gRem)
    local decision = DECISION_MATRIX[sIdx][gIdx]

    -- ★ До фактического Ball матрица не имеет права переводить
    -- активный Gummy-сеанс на косу из-за таймера.
    -- KD/GM_K заменяем на Gummyballer; PREP оставляем без изменений.
    if not ballTriggeredThisAura and (decision == "KD" or decision == "GM_K") then
        decision = "GM_B"
    end

    -- Запуск prep (только один раз за ауру)
    if decision == "PREP" and not inPrepPhase and not prepUsedThisAura then
        inPrepPhase = true
        prepStartTime = tick()
        currentPrepDur = getPrepDuration(gRem)
        prepUsedThisAura = true
        return "PREP"
    end

    -- Если матрица хочет PREP но prep уже была → GM_B
    if decision == "PREP" and prepUsedThisAura then
        return "GM_B"
    end

    return decision
end

-- ===============================
-- EQUIP SET
-- ===============================
local function equipSet(mask, collector, loadoutKey)
    if currentLoadout == loadoutKey then return end
    ItemPackageEvent:InvokeServer("Equip", mask)
    ItemPackageEvent:InvokeServer("Equip", collector)
    currentLoadout = loadoutKey
    print(string.format("[AutoEquip] %s + %s [%s]", mask.Type, collector.Type, loadoutKey))
end

local function applyLoadout(key)
    if key == "KD" then
        equipSet(EQUIP.DemonMask, EQUIP.DarkScythe, "KD")
    elseif key == "GM_K" then
        equipSet(EQUIP.GummyMask, EQUIP.DarkScythe, "GM_K")
    elseif key == "GM_B" then
        equipSet(EQUIP.GummyMask, EQUIP.Gummyballer, "GM_B")
    elseif key == "PREP" then
        equipSet(EQUIP.DemonMask, EQUIP.DarkScythe, "PREP")
    end
end

-- ===============================
-- AUTO-EQUIP LOOP
-- ===============================
task.spawn(function()
    while true do
        if autoMode then
            local g = gummyVisible and math.max(0, gummyEndTime - tick()) or 0
            local s = scorchVisible and math.max(0, scorchEndTime - tick()) or 0
            local auraActive = gummyVisible and gummyRemaining > 0
            local decision = decideLoadout(g, s, auraActive)
            applyLoadout(decision)
            if ballPresent and g < BALL_SWITCH_THRESHOLD then
                print(string.format("[Ball DEBUG] Gummy=%.1fs | Scorch=%.1fs | Ball=true | Latched=%s | Loadout=%s", g, s, tostring(ballTriggeredThisAura), decision))
            end
        end
        task.wait(0.3)
    end
end)

-- ===============================
-- GUI
-- ===============================
local playerGui = LP:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("StarAuraGUI")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StarAuraGUI"; screenGui.ResetOnSpawn = false; screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 130)
frame.Position = UDim2.new(1, -250, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true
frame.Parent = screenGui

local gummyLabel = Instance.new("TextLabel")
gummyLabel.Size = UDim2.new(1, -10, 0, 16); gummyLabel.Position = UDim2.new(0, 5, 0, 4)
gummyLabel.BackgroundTransparency = 1; gummyLabel.Text = ""
gummyLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
gummyLabel.Font = Enum.Font.GothamBold; gummyLabel.TextSize = 12
gummyLabel.TextXAlignment = Enum.TextXAlignment.Left; gummyLabel.Visible = false
gummyLabel.Parent = frame

local gummyBarBg = Instance.new("Frame")
gummyBarBg.Size = UDim2.new(1, -10, 0, 5); gummyBarBg.Position = UDim2.new(0, 5, 0, 21)
gummyBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45); gummyBarBg.BorderSizePixel = 0
gummyBarBg.Visible = false; gummyBarBg.Parent = frame

local gummyBarFill = Instance.new("Frame")
gummyBarFill.Size = UDim2.new(0, 0, 1, 0)
gummyBarFill.BackgroundColor3 = Color3.fromRGB(100, 220, 100); gummyBarFill.BorderSizePixel = 0
gummyBarFill.Parent = gummyBarBg

local scorchLabel = Instance.new("TextLabel")
scorchLabel.Size = UDim2.new(1, -10, 0, 16); scorchLabel.Position = UDim2.new(0, 5, 0, 29)
scorchLabel.BackgroundTransparency = 1; scorchLabel.Text = ""
scorchLabel.TextColor3 = Color3.fromRGB(255, 140, 40)
scorchLabel.Font = Enum.Font.GothamBold; scorchLabel.TextSize = 12
scorchLabel.TextXAlignment = Enum.TextXAlignment.Left; scorchLabel.Visible = false
scorchLabel.Parent = frame

local scorchBarBg = Instance.new("Frame")
scorchBarBg.Size = UDim2.new(1, -10, 0, 5); scorchBarBg.Position = UDim2.new(0, 5, 0, 46)
scorchBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45); scorchBarBg.BorderSizePixel = 0
scorchBarBg.Visible = false; scorchBarBg.Parent = frame

local scorchBarFill = Instance.new("Frame")
scorchBarFill.Size = UDim2.new(0, 0, 1, 0)
scorchBarFill.BackgroundColor3 = Color3.fromRGB(255, 140, 40); scorchBarFill.BorderSizePixel = 0
scorchBarFill.Parent = scorchBarBg

local loadoutLabel = Instance.new("TextLabel")
loadoutLabel.Size = UDim2.new(1, -10, 0, 14); loadoutLabel.Position = UDim2.new(0, 5, 0, 54)
loadoutLabel.BackgroundTransparency = 1; loadoutLabel.Text = "Loadout: --"
loadoutLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
loadoutLabel.Font = Enum.Font.GothamBold; loadoutLabel.TextSize = 11
loadoutLabel.TextXAlignment = Enum.TextXAlignment.Left
loadoutLabel.Parent = frame

local ballLabel = Instance.new("TextLabel")
ballLabel.Size = UDim2.new(1, -10, 0, 14); ballLabel.Position = UDim2.new(0, 5, 0, 70)
ballLabel.BackgroundTransparency = 1; ballLabel.Text = "Ball: --"
ballLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
ballLabel.Font = Enum.Font.GothamBold; ballLabel.TextSize = 11
ballLabel.TextXAlignment = Enum.TextXAlignment.Left
ballLabel.Parent = frame

local gumdropsLabel = Instance.new("TextLabel")
gumdropsLabel.Size = UDim2.new(1, -10, 0, 14); gumdropsLabel.Position = UDim2.new(0, 5, 0, 86)
gumdropsLabel.BackgroundTransparency = 1; gumdropsLabel.Text = ""
gumdropsLabel.TextColor3 = Color3.fromRGB(220, 100, 220)
gumdropsLabel.Font = Enum.Font.GothamBold; gumdropsLabel.TextSize = 11
gumdropsLabel.TextXAlignment = Enum.TextXAlignment.Left; gumdropsLabel.Visible = false
gumdropsLabel.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 14); statusLabel.Position = UDim2.new(0, 5, 0, 102)
statusLabel.BackgroundTransparency = 1; statusLabel.Text = "AUTO ON"
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.Font = Enum.Font.Gotham; statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, -10, 0, 12); hintLabel.Position = UDim2.new(0, 5, 0, 117)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "H=auto"
hintLabel.TextColor3 = Color3.fromRGB(100, 100, 110)
hintLabel.Font = Enum.Font.Gotham; hintLabel.TextSize = 9
hintLabel.TextXAlignment = Enum.TextXAlignment.Left
hintLabel.Parent = frame

-- ===============================
-- GUI UPDATE
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

        if ballPresent then
            ballLabel.Text = "Ball: ● SCYTHE"
            ballLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        else
            ballLabel.Text = "Ball: ○ none"
            ballLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
        end

        local loadoutNames = {
            KD = "Demon + Scythe",
            GM_K = "GummyMask + Scythe",
            GM_B = "GummyMask + Baller",
            PREP = "Prep: Demon+Scythe (" .. math.max(0, math.ceil(currentPrepDur - (tick() - prepStartTime))) .. "s)",
        }
        loadoutLabel.Text = "Loadout: " .. (loadoutNames[currentLoadout] or "--")

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
        if phase == "AURA" then phaseText = "AURA"
        elseif phase == "COOLDOWN" then phaseText = "CD"
        elseif phase == "COUNTING" then phaseText = "COUNT"
        else phaseText = "WAIT" end

        statusLabel.Text = string.format("%s | %s", phaseText, autoMode and "AUTO" or "MANUAL")
        task.wait(0.1)
    end
end)

-- ===============================
-- STATE MACHINE (Gumdrops)
-- ===============================
task.spawn(function()
    local wasGummyActive = false
    while true do
        local gummyNow = gummyApplied and gummyVisible and gummyRemaining > 0
        if not wasGummyActive and gummyNow then
            if counting then lastGumdropsResult = gumdropsCount end
            counting = false; gumdropsCount = 0; cooldownEnd = 0
            prepUsedThisAura = false; inPrepPhase = false
            ballTriggeredThisAura = false
            phase = "AURA"
        end
        if wasGummyActive and not gummyNow then
            lastGumdropsResult = -1; counting = false
            cooldownEnd = tick() + COOLDOWN; phase = "COOLDOWN"
        end
        if phase == "COOLDOWN" and tick() >= cooldownEnd then
            counting = true; gumdropsCount = 0; phase = "COUNTING"
        end
        wasGummyActive = gummyNow
        task.wait(0.2)
    end
end)

-- ===============================
-- INPUT
-- ===============================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == AUTO_TOGGLE_KEY then
        autoMode = not autoMode
        if autoMode then currentLoadout = "" end
        print("[H] Auto " .. (autoMode and "ON" or "OFF"))
    end
end)

LP.CharacterAdded:Connect(function()
    gumdropsCount = 0; counting = false; cooldownEnd = 0; lastGumdropsResult = 0
    phase = "IDLE"; gummyVisible = false; scorchVisible = false
    gummyApplied = false; scorchApplied = false; gummyEndTime = 0; scorchEndTime = 0
    currentLoadout = ""; inPrepPhase = false; prepUsedThisAura = false
    autoMode = true; ballPresent = false; ballDetectedAt = 0; ballTriggeredThisAura = false
end)

print("=== Star Aura Auto-Equip v3.7 ===")
print("  Priority: aura-end>KD | Ball(<15s)+delay>GM_K(latched) | Baller holds until Ball | matrix")
print("==================================")
