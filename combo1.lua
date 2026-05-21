-- ================================================
-- Combo Coconut Script v3
-- Поменяй ACCOUNT_ID на 1, 2, 3 или 4
-- ================================================

local ACCOUNT_ID = 1  -- <== ПОМЕНЯЙ ЗДЕСЬ (1, 2, 3 или 4)
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

-- Стоп-значения: кидаем кокосы пока не достигнем одного из них
local STOP_VALUES = {4, 9, 14, 19, 24, 29, 34}

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
frame.Size = UDim2.new(0, 140, 0, 90)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * 100)
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

-- Кнопка SKIP (только для ACC 1)
local skipBtn = Instance.new("TextButton")
skipBtn.Size = UDim2.new(1, -16, 0, 26)
skipBtn.Position = UDim2.new(0, 8, 0, 58)
skipBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
skipBtn.BorderSizePixel = 0
skipBtn.Text = "⏭️ SKIP & COMBO"
skipBtn.TextColor3 = Color3.fromRGB(150, 150, 170)
skipBtn.TextSize = 10
skipBtn.Font = Enum.Font.GothamBold
skipBtn.AutoButtonColor = true
skipBtn.Visible = (ACCOUNT_ID == 1)  -- Только для ACC 1
skipBtn.Parent = frame

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 6)
skipCorner.Parent = skipBtn

local function updateSkipButton()
    if ACCOUNT_ID ~= 1 then return end
    if lastValue == 39 then
        skipBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
        skipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        skipBtn.Text = "⏭️ SKIP & COMBO"
    else
        skipBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        skipBtn.TextColor3 = Color3.fromRGB(80, 80, 90)
        skipBtn.Text = "ждём 39..."
    end
end

local function updateCounterDisplay()
    label.Text = tostring(comboCounter)
    valueLabel.Text = "value: " .. tostring(lastValue)
    if comboCounter == ACCOUNT_ID then
        frame.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        label.TextColor3 = Color3.fromRGB(100, 255, 100)
        idLabel.Text = ">>> МОЯ ОЧЕРЕДЬ <<<"
    else
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        label.TextColor3 = Color3.fromRGB(255, 200, 100)
        idLabel.Text = "ACC #" .. ACCOUNT_ID .. " (ждём " .. comboCounter .. ")"
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
        {
            Category = "Accessory",
            Type = "Coconut Canister"
        }
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
        {
            Category = "Accessory",
            Type = "Porcelain Port-O-Hive"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    currentAccessory = "porcelain"
    hasPorcelain = true
    hasCanister = false
end

function SpawnCoconut(isCombo)
    local args = {
        {
            Name = "Coconut"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args))
    if isCombo then
        print("✅ [ACC " .. ACCOUNT_ID .. "] КОМБО КОКОС!")
        task.spawn(function()
            task.wait(11)
            SpawnCoconut(false)
        end)
    else
        print("🥥 [ACC " .. ACCOUNT_ID .. "] обычный кокос")
    end
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
            print("🌟 [ACC " .. ACCOUNT_ID .. "] Комбо появилось")
            
        elseif not present and coconutActive then
            coconutActive = false
            comboCounter = comboCounter + 1
            if comboCounter > TOTAL_ACCOUNTS then 
                comboCounter = 1 
            end
            updateCounterDisplay()
            print("📊 [ACC " .. ACCOUNT_ID .. "] Счётчик: " .. comboCounter)
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
        task.wait(12)  -- 12 секунд
        if lastValue == 39 and comboCounter == ACCOUNT_ID then
            print("🎯 [ACC " .. ACCOUNT_ID .. "] Кидаю КОМБО по таймеру!")
            SpawnCoconut(true)
        end
        spawnTimer = nil
    end)
end

-- ================================================
-- Кнопка SKIP (ACC 1): пропустить очередь и кинуть комбо
-- ================================================
skipBtn.MouseButton1Click:Connect(function()
    if ACCOUNT_ID ~= 1 then return end
    if lastValue ~= 39 then
        print("⚠️ [ACC 1] Нельзя — value не 39!")
        return
    end
    
    -- Отменяем текущий таймер если есть
    if spawnTimer then
        task.cancel(spawnTimer)
        spawnTimer = nil
    end
    
    print("⏭️ [ACC 1] SKIP! Кидаю комбо вне очереди")
    SpawnCoconut(true)
    
    -- Очередь сдвигается когда комбо соберут (comboCounter увеличится)
    -- Так что после сбора комбо очередь перейдёт к следующему
end)

-- ================================================
-- Слушатель событий
-- ================================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                
                -- Отменяем таймер если value упал
                if value < 39 and spawnTimer then
                    task.cancel(spawnTimer)
                    spawnTimer = nil
                end

                -- ====== ЭКИПИРОВКА ======
                -- 0-34: канистра
                if value >= 0 and value <= 34 then
                    EquipCanister()
                end
                
                -- 35-39: фарфор
                if value >= 35 and value <= 39 then
                    EquipPorcelain()
                end

                -- ====== ОБЫЧНЫЕ КОКОСЫ ======
                -- Кидаем пока не достигнем стоп-значения (4,9,14,19,24,29,34)
                if value >= 0 and value <= 34 and not isStopValue(value) then
                    SpawnCoconut(false)
                end

                -- ====== КОМБО ТАЙМЕР ======
                if value == 39 and comboCounter == ACCOUNT_ID and not spawnTimer then
                    print("⏳ [ACC " .. ACCOUNT_ID .. "] Моя очередь! Таймер 12 сек...")
                    startSpawnTimer()
                end

                lastValue = value
                updateCounterDisplay()
            end
        end
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
        print("🔧 [ACC " .. ACCOUNT_ID .. "] Счётчик: " .. n)
    end,
    
    Reset = function()
        comboCounter = 0
        updateCounterDisplay()
        print("🔧 [ACC " .. ACCOUNT_ID .. "] Сброс на 0")
    end,
    
    Status = function()
        print("========================================")
        print("🔧 [ACC " .. ACCOUNT_ID .. "] Статус:")
        print("   Счётчик: " .. comboCounter)
        print("   Моя очередь: " .. tostring(comboCounter == ACCOUNT_ID))
        print("   Value: " .. lastValue)
        print("   Комбо: " .. tostring(coconutActive))
        print("   Таймер: " .. tostring(spawnTimer ~= nil))
        print("========================================")
    end,
    
    Skip = function()
        if lastValue == 39 then
            print("⏭️ [ACC " .. ACCOUNT_ID .. "] Ручной SKIP!")
            if spawnTimer then task.cancel(spawnTimer) spawnTimer = nil end
            SpawnCoconut(true)
        else
            print("⚠️ Value не 39!")
        end
    end,
}

-- ================================================
-- Старт
-- ================================================
updateCounterDisplay()
print("========================================")
print("✅ [ACC " .. ACCOUNT_ID .. "] Combo Coconut v3")
print("")
print("📋 Логика:")
print("   • 0-34: канистра + кокосы до 4/9/14/19/24/29/34")
print("   • 35-39: фарфор")
print("   • 39 + очередь: таймер 12 сек → комбо")
print("")
if ACCOUNT_ID == 1 then
    print("🔴 Кнопка SKIP: кинуть комбо вне очереди (при 39)")
end
print("")
print("📊 CC.Set(N) — установить счётчик")
print("📊 CC.Status() — статус")
print("📊 CC.Skip() — ручной комбо")
print("========================================")
