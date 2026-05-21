-- ================================================
-- Combo Coconut Script v7
-- ACCOUNT_ID = 1
-- ================================================
local ACCOUNT_ID = 2
local TOTAL_ACCOUNTS = 3
local LOGS = false   -- <== true чтобы включить принты

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

local function log(...)
    if LOGS then print(...) end
end

local lastValue = -1
local coconutActive = false
local currentAccessory = "none"
local hasCanister = false
local hasPorcelain = false
local spawnTimer = nil
local comboCounter = 0
local skipUsed = false
local lastCoconutThrow = 0
local COCONUT_COOLDOWN = 1.0

-- Анти-дубль сдвига очереди
local lastQueueAdvanceAt = 0
local QUEUE_ADVANCE_DEBOUNCE = 3.0
local lastAdvanceReason = "-"

-- Стоп-значения
local STOP_VALUES = {4, 9, 14, 19, 24, 29, 34}
local reachedStopValue = false

local function isStopValue(v)
    for _, sv in ipairs(STOP_VALUES) do
        if v == sv then return true end
    end
    return false
end

local function advanceQueue(reason)
    local now = tick()
    if now - lastQueueAdvanceAt < QUEUE_ADVANCE_DEBOUNCE then
        log("[ACC " .. ACCOUNT_ID .. "] advanceQueue IGNORED (debounce " .. string.format("%.2f", now - lastQueueAdvanceAt) .. "s) reason=" .. tostring(reason))
        return
    end
    lastQueueAdvanceAt = now
    lastAdvanceReason = tostring(reason)

    if skipUsed then
        skipUsed = false
        log("[ACC " .. ACCOUNT_ID .. "] Combo collected (SKIP, counter=" .. comboCounter .. ") reason=" .. tostring(reason))
        return
    end

    comboCounter = comboCounter + 1
    if comboCounter > TOTAL_ACCOUNTS then
        comboCounter = 1
    end
    log("[ACC " .. ACCOUNT_ID .. "] >>> Queue -> " .. comboCounter .. " (reason=" .. tostring(reason) .. ")")
end

-- ================================================
-- Интерфейс
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboCounter_" .. ACCOUNT_ID
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 140, 0, 105)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * 115)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0, 30)
label.Position = UDim2.new(0, 0, 0, 0)
label.BackgroundTransparency = 1
label.Text = "0"
label.TextColor3 = Color3.fromRGB(255, 200, 100)
label.Font = Enum.Font.GothamBold
label.TextSize = 22
label.Parent = frame

local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(1, 0, 0, 16)
idLabel.Position = UDim2.new(0, 0, 0, 28)
idLabel.BackgroundTransparency = 1
idLabel.Text = "ACC #" .. ACCOUNT_ID
idLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
idLabel.Font = Enum.Font.Gotham
idLabel.TextSize = 10
idLabel.Parent = frame

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, 0, 0, 14)
valueLabel.Position = UDim2.new(0, 0, 0, 44)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "value: -"
valueLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
valueLabel.Font = Enum.Font.Gotham
valueLabel.TextSize = 10
valueLabel.Parent = frame

local stopLabel = Instance.new("TextLabel")
stopLabel.Size = UDim2.new(1, 0, 0, 14)
stopLabel.Position = UDim2.new(0, 0, 0, 58)
stopLabel.BackgroundTransparency = 1
stopLabel.Text = ""
stopLabel.TextColor3 = Color3.fromRGB(80, 180, 80)
stopLabel.Font = Enum.Font.Gotham
stopLabel.TextSize = 9
stopLabel.Parent = frame

local skipBtn = Instance.new("TextButton")
skipBtn.Size = UDim2.new(1, -16, 0, 26)
skipBtn.Position = UDim2.new(0, 8, 0, 74)
skipBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
skipBtn.BorderSizePixel = 0
skipBtn.Text = "SKIP & COMBO"
skipBtn.TextColor3 = Color3.fromRGB(150, 150, 170)
skipBtn.TextSize = 10
skipBtn.Font = Enum.Font.GothamBold
skipBtn.AutoButtonColor = true
skipBtn.Visible = (ACCOUNT_ID == 1)
skipBtn.Parent = frame

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 6)
skipCorner.Parent = skipBtn

local function updateSkipButton()
    if ACCOUNT_ID ~= 1 then return end
    if lastValue == 39 then
        skipBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
        skipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        skipBtn.Text = "SKIP -> NEXT"
    else
        skipBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        skipBtn.TextColor3 = Color3.fromRGB(80, 80, 90)
        skipBtn.Text = "wait 39..."
    end
end

local function updateCounterDisplay()
    label.Text = tostring(comboCounter)
    valueLabel.Text = "value: " .. tostring(lastValue)

    if reachedStopValue then
        stopLabel.Text = "STOP (wait 0)"
        stopLabel.TextColor3 = Color3.fromRGB(200, 150, 50)
    else
        stopLabel.Text = "throwing coconuts"
        stopLabel.TextColor3 = Color3.fromRGB(80, 180, 80)
    end

    if comboCounter == ACCOUNT_ID then
        frame.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        label.TextColor3 = Color3.fromRGB(100, 255, 100)
        idLabel.Text = ">>> MY TURN <<<"
    else
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        label.TextColor3 = Color3.fromRGB(255, 200, 100)
        idLabel.Text = "ACC #" .. ACCOUNT_ID .. " (wait " .. comboCounter .. ")"
    end
    updateSkipButton()
end

-- ================================================
-- Функции экипировки
-- ================================================
function EquipCanister()
    if hasCanister then return end
    local args = {
        "Equip",
        { Category = "Accessory", Type = "Coconut Canister" }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    currentAccessory = "canister"
    hasCanister = true
    hasPorcelain = false
end

function EquipPorcelain()
    if hasPorcelain then return end
    local args = {
        "Equip",
        { Category = "Accessory", Type = "Porcelain Port-O-Hive" }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    currentAccessory = "porcelain"
    hasPorcelain = true
    hasCanister = false
end

function SpawnCoconut(isCombo)
    local args = { { Name = "Coconut" } }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args))
    if isCombo then
        log("[ACC " .. ACCOUNT_ID .. "] COMBO COCONUT!")
        task.spawn(function()
            task.wait(11)
            SpawnCoconut(false)
        end)
    else
        lastCoconutThrow = tick()
        log("[ACC " .. ACCOUNT_ID .. "] coconut (value=" .. lastValue .. ")")
    end
end

function TryThrowCoconut()
    if tick() - lastCoconutThrow < COCONUT_COOLDOWN then return false end
    SpawnCoconut(false)
    return true
end

function IsComboCoconutPresent()
    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return false end
    for _, obj in pairs(particles:GetChildren()) do
        if obj.Name == "ComboCoconut" and obj.ClassName == "UnionOperation" then
            return true
        end
    end
    return false
end

-- ================================================
-- ДЕТЕКТОР ЧАСТИЦЫ — главный триггер сдвига очереди
-- Опрос 0.1 сек. Сдвигаем по ПОЯВЛЕНИЮ (это надёжнее
-- чем по исчезновению, т.к. частица существует дольше).
-- ================================================
spawn(function()
    while true do
        local present = IsComboCoconutPresent()

        if present and not coconutActive then
            coconutActive = true
            log("[ACC " .. ACCOUNT_ID .. "] Combo particle APPEARED")
            advanceQueue("particle-appeared")
            updateCounterDisplay()
        elseif not present and coconutActive then
            coconutActive = false
            log("[ACC " .. ACCOUNT_ID .. "] Combo particle gone")
        end

        task.wait(0.1)
    end
end)

-- ================================================
-- ДОПОЛНИТЕЛЬНЫЙ ДЕТЕКТОР: ChildAdded на Particles
-- Срабатывает мгновенно, не зависит от опроса
-- ================================================
spawn(function()
    local particles = Workspace:WaitForChild("Particles", 30)
    if not particles then return end
    particles.ChildAdded:Connect(function(obj)
        if obj.Name == "ComboCoconut" then
            log("[ACC " .. ACCOUNT_ID .. "] ChildAdded: ComboCoconut")
            advanceQueue("child-added")
            coconutActive = true
            updateCounterDisplay()
        end
    end)
end)

-- ================================================
-- Таймер комбо (12 сек)
-- ================================================
local function startSpawnTimer()
    if spawnTimer then
        task.cancel(spawnTimer)
        spawnTimer = nil
    end
    spawnTimer = task.spawn(function()
        task.wait(12)
        if lastValue == 39 and comboCounter == ACCOUNT_ID then
            log("[ACC " .. ACCOUNT_ID .. "] Throwing COMBO by timer!")
            SpawnCoconut(true)
        end
        spawnTimer = nil
    end)
end

-- ================================================
-- Кнопка SKIP (только ACC 1)
-- ================================================
skipBtn.MouseButton1Click:Connect(function()
    if ACCOUNT_ID ~= 1 then return end
    if lastValue ~= 39 then
        log("[ACC 1] Cannot skip - value is not 39!")
        return
    end

    if spawnTimer then
        task.cancel(spawnTimer)
        spawnTimer = nil
    end

    -- Локально сдвигаем счётчик и блокируем автотриггеры
    comboCounter = comboCounter + 1
    if comboCounter > TOTAL_ACCOUNTS then
        comboCounter = 1
    end
    skipUsed = false  -- НЕ ставим true, потому что мы УЖЕ сдвинули и хотим заблокировать второй сдвиг через debounce
    lastQueueAdvanceAt = tick()
    lastAdvanceReason = "skip-button"
    coconutActive = true

    updateCounterDisplay()

    log("[ACC 1] SKIP! Combo now, queue -> ACC " .. comboCounter)
    SpawnCoconut(true)
end)

-- ================================================
-- Слушатель PlayerAbilityEvent (value, экипировка, обычные кокосы)
-- ================================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                local prevValue = lastValue

                -- Резервный триггер: value было 39 и упало (на своём аккаунте)
                if prevValue == 39 and value < 39 then
                    advanceQueue("value-drop-from-39")
                end

                if value == 0 then
                    reachedStopValue = false
                end

                if value < 39 and spawnTimer then
                    task.cancel(spawnTimer)
                    spawnTimer = nil
                end

                if value >= 0 and value <= 34 then
                    EquipCanister()
                end
                if value >= 35 and value <= 39 then
                    EquipPorcelain()
                end

                if value >= 0 and value <= 34 then
                    if isStopValue(value) then
                        if not reachedStopValue then
                            reachedStopValue = true
                            log("[ACC " .. ACCOUNT_ID .. "] Reached stop: " .. value)
                        end
                    elseif not reachedStopValue then
                        TryThrowCoconut()
                    end
                end

                if value == 39 and comboCounter == ACCOUNT_ID and not spawnTimer then
                    log("[ACC " .. ACCOUNT_ID .. "] My turn! Timer 12 sec...")
                    startSpawnTimer()
                end

                lastValue = value
                updateCounterDisplay()
            end
        end
    end
end)

-- Фоновый кокосо-кидатель (1 раз/сек)
spawn(function()
    while true do
        if lastValue >= 0 and lastValue <= 34
           and not isStopValue(lastValue)
           and not reachedStopValue then
            TryThrowCoconut()
        end
        task.wait(1)
    end
end)

-- Фоллбэк экипировки канистры
spawn(function()
    while true do
        if lastValue >= 0 and lastValue <= 34 and not hasCanister then
            EquipCanister()
        end
        task.wait(5)
    end
end)

-- ================================================
-- Команды
-- ================================================
getgenv().CC = {
    Set = function(n)
        comboCounter = n
        updateCounterDisplay()
        log("[ACC " .. ACCOUNT_ID .. "] Counter: " .. n)
    end,

    Reset = function()
        comboCounter = 0
        reachedStopValue = false
        skipUsed = false
        coconutActive = false
        lastQueueAdvanceAt = 0
        updateCounterDisplay()
        log("[ACC " .. ACCOUNT_ID .. "] Full reset")
    end,

    Status = function()
        print("========================================")
        print("[ACC " .. ACCOUNT_ID .. "] Status:")
        print("   Counter: " .. comboCounter)
        print("   My turn: " .. tostring(comboCounter == ACCOUNT_ID))
        print("   Value: " .. lastValue)
        print("   ReachedStop: " .. tostring(reachedStopValue))
        print("   ComboActive: " .. tostring(coconutActive))
        print("   SkipUsed: " .. tostring(skipUsed))
        print("   Timer: " .. tostring(spawnTimer ~= nil))
        print("   LastAdvanceReason: " .. lastAdvanceReason)
        print("   ParticlesFolder: " .. tostring(Workspace:FindFirstChild("Particles") ~= nil))
        print("   Logs: " .. tostring(LOGS))
        print("========================================")
    end,

    Skip = function()
        if lastValue == 39 then
            if spawnTimer then task.cancel(spawnTimer) spawnTimer = nil end
            comboCounter = comboCounter + 1
            if comboCounter > TOTAL_ACCOUNTS then comboCounter = 1 end
            skipUsed = false
            lastQueueAdvanceAt = tick()
            lastAdvanceReason = "skip-cmd"
            coconutActive = true
            updateCounterDisplay()
            log("[ACC " .. ACCOUNT_ID .. "] SKIP! Queue -> " .. comboCounter)
            SpawnCoconut(true)
        else
            log("Value is not 39!")
        end
    end,

    ResetStop = function()
        reachedStopValue = false
        updateCounterDisplay()
        log("[ACC " .. ACCOUNT_ID .. "] Stop flag reset")
    end,

    SetLogs = function(v)
        LOGS = v and true or false
        print("[ACC " .. ACCOUNT_ID .. "] Logs = " .. tostring(LOGS))
    end,

    -- Ручной сдвиг очереди (для отладки)
    Advance = function()
        lastQueueAdvanceAt = 0
        advanceQueue("manual")
        updateCounterDisplay()
    end,
}

-- ================================================
-- Старт
-- ================================================
updateCounterDisplay()
if LOGS then
    print("========================================")
    print("[ACC " .. ACCOUNT_ID .. "] Combo Coconut v7")
    print("Queue advance via particle ChildAdded + 0.1s poll")
    print("========================================")
end
