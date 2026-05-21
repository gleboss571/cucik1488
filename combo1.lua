-- ================================================
-- Combo Coconut Script v5
-- ACCOUNT_ID = 1
-- ================================================
local ACCOUNT_ID = 1
local TOTAL_ACCOUNTS = 3

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

local lastValue = -1
local coconutActive = false
local currentAccessory = "none"
local hasCanister = false
local hasPorcelain = false
local spawnTimer = nil
local comboCounter = 0
local skipUsed = false
local lastCoconutThrow = 0   -- время последнего обычного кокоса (throttle 1 сек)
local COCONUT_COOLDOWN = 1.0 -- кокос не чаще 1 раза в секунду

-- Стоп-значения
local STOP_VALUES = {4, 9, 14, 19, 24, 29, 34}
local reachedStopValue = false

local function isStopValue(v)
    for _, sv in ipairs(STOP_VALUES) do
        if v == sv then return true end
    end
    return false
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

-- Кнопка SKIP (только для ACC 1)
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
        skipBtn.Text = "SKIP -> ACC 2"
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
        print("[ACC " .. ACCOUNT_ID .. "] COMBO COCONUT!")
        task.spawn(function()
            task.wait(11)
            SpawnCoconut(false)
        end)
    else
        lastCoconutThrow = tick()
        print("[ACC " .. ACCOUNT_ID .. "] coconut (value=" .. lastValue .. ")")
    end
end

-- Обычный кокос с throttle 1 сек
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
-- Мониторинг комбо
-- ================================================
spawn(function()
    while true do
        local present = IsComboCoconutPresent()

        if present and not coconutActive then
            coconutActive = true
            print("[ACC " .. ACCOUNT_ID .. "] Combo appeared")

        elseif not present and coconutActive then
            coconutActive = false

            if skipUsed then
                skipUsed = false
                print("[ACC " .. ACCOUNT_ID .. "] Combo collected (SKIP, counter=" .. comboCounter .. ")")
            else
                comboCounter = comboCounter + 1
                if comboCounter > TOTAL_ACCOUNTS then
                    comboCounter = 1
                end
                print("[ACC " .. ACCOUNT_ID .. "] Queue: " .. comboCounter)
            end
            updateCounterDisplay()
        end

        task.wait(0.5)
    end
end)

-- ================================================
-- Таймер комбо (12 секунд)
-- ================================================
local function startSpawnTimer()
    if spawnTimer then
        task.cancel(spawnTimer)
        spawnTimer = nil
    end
    spawnTimer = task.spawn(function()
        task.wait(12)
        if lastValue == 39 and comboCounter == ACCOUNT_ID then
            print("[ACC " .. ACCOUNT_ID .. "] Throwing COMBO by timer!")
            SpawnCoconut(true)
        end
        spawnTimer = nil
    end)
end

-- ================================================
-- Кнопка SKIP (ACC 1): кинуть комбо, очередь -> ACC 2
-- ================================================
skipBtn.MouseButton1Click:Connect(function()
    if ACCOUNT_ID ~= 1 then return end
    if lastValue ~= 39 then
        print("[ACC 1] Cannot skip - value is not 39!")
        return
    end

    if spawnTimer then
        task.cancel(spawnTimer)
        spawnTimer = nil
    end

    -- Сдвигаем счётчик ВПЕРЁД
    comboCounter = comboCounter + 1
    if comboCounter > TOTAL_ACCOUNTS then
        comboCounter = 1
    end
    skipUsed = true

    -- ВАЖНО: принудительно ставим coconutActive = true,
    -- чтобы при следующем тике детектора (когда частица исчезнет)
    -- сработала ветка "комбо собрано" и сбросила skipUsed.
    -- Иначе детектор с интервалом 0.5 сек может НЕ УВИДЕТЬ
    -- кратковременное появление частицы, skipUsed зависнет true,
    -- и следующее реальное комбо не сдвинет счётчик.
    coconutActive = true

    updateCounterDisplay()

    print("[ACC 1] SKIP! Combo now, queue -> ACC " .. comboCounter)
    SpawnCoconut(true)
end)

-- ================================================
-- Слушатель событий
-- ================================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0

                -- ====== СБРОС ЦИКЛА при value = 0 ======
                if value == 0 then
                    reachedStopValue = false
                end

                -- Отменяем таймер если value упал
                if value < 39 and spawnTimer then
                    task.cancel(spawnTimer)
                    spawnTimer = nil
                end

                -- ====== ЭКИПИРОВКА ======
                if value >= 0 and value <= 34 then
                    EquipCanister()
                end

                if value >= 35 and value <= 39 then
                    EquipPorcelain()
                end

                -- ====== ОБЫЧНЫЕ КОКОСЫ ======
                -- Кидаем максимум раз в 1 секунду (throttle)
                if value >= 0 and value <= 34 then
                    if isStopValue(value) then
                        if not reachedStopValue then
                            reachedStopValue = true
                            print("[ACC " .. ACCOUNT_ID .. "] Reached stop: " .. value)
                        end
                    elseif not reachedStopValue then
                        TryThrowCoconut()  -- throttle внутри
                    end
                end

                -- ====== КОМБО ТАЙМЕР ======
                if value == 39 and comboCounter == ACCOUNT_ID and not spawnTimer then
                    print("[ACC " .. ACCOUNT_ID .. "] My turn! Timer 12 sec...")
                    startSpawnTimer()
                end

                lastValue = value
                updateCounterDisplay()
            end
        end
    end
end)

-- ================================================
-- Фоновый кокосо-кидатель (каждую 1 секунду)
-- Дублирует листенер, но гарантирует ритм даже
-- если апдейтов value не приходит долго.
-- ================================================
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

-- Авто-экипировка канистры (фоллбэк)
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
        print("[ACC " .. ACCOUNT_ID .. "] Counter: " .. n)
    end,

    Reset = function()
        comboCounter = 0
        reachedStopValue = false
        skipUsed = false
        coconutActive = false
        updateCounterDisplay()
        print("[ACC " .. ACCOUNT_ID .. "] Full reset")
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
        print("========================================")
    end,

    Skip = function()
        if lastValue == 39 then
            if spawnTimer then task.cancel(spawnTimer) spawnTimer = nil end
            comboCounter = comboCounter + 1
            if comboCounter > TOTAL_ACCOUNTS then comboCounter = 1 end
            skipUsed = true
            coconutActive = true   -- см. комментарий в обработчике кнопки
            updateCounterDisplay()
            print("[ACC " .. ACCOUNT_ID .. "] SKIP! Queue -> " .. comboCounter)
            SpawnCoconut(true)
        else
            print("Value is not 39!")
        end
    end,

    ResetStop = function()
        reachedStopValue = false
        updateCounterDisplay()
        print("[ACC " .. ACCOUNT_ID .. "] Stop flag reset")
    end,
}

-- ================================================
-- Старт
-- ================================================
updateCounterDisplay()
print("========================================")
print("[ACC " .. ACCOUNT_ID .. "] Combo Coconut v5")
print("Coconuts thrown max 1/sec, SKIP fixed")
print("========================================")
