
-- ================================================
-- Combo Coconut Script v2 (СИНХРОНИЗИРОВАННЫЙ)
-- Поменяй ACCOUNT_ID на 1, 2, 3 или 4
-- ================================================

local ACCOUNT_ID = 1  -- <== ПОМЕНЯЙ ЗДЕСЬ (1, 2, 3 или 4)
local TOTAL_ACCOUNTS = 3  -- Сколько всего аккаунтов в очереди

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

-- ГЛАВНОЕ ИЗМЕНЕНИЕ: comboCounter у всех должен быть ОДИНАКОВЫМ
-- Это "чья сейчас очередь", а не личный счётчик
-- При старте = 0, первый кто кинет комбо после запуска = аккаунт 1
local comboCounter = 0
local isFirstEvent = true  -- Флаг для синхронизации

-- ================================================
-- Интерфейс
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboCounter_" .. ACCOUNT_ID
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 120, 0, 50)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * 60)  -- Сдвиг по Y для разных аккаунтов
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
label.Size = UDim2.new(1, 0, 0.6, 0)
label.Position = UDim2.new(0, 0, 0, 0)
label.BackgroundTransparency = 1
label.Text = "0"
label.TextColor3 = Color3.fromRGB(255, 200, 100)
label.Font = Enum.Font.GothamBold
label.TextSize = 22
label.Parent = frame

local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(1, 0, 0.4, 0)
idLabel.Position = UDim2.new(0, 0, 0.6, 0)
idLabel.BackgroundTransparency = 1
idLabel.Text = "ACC #" .. ACCOUNT_ID
idLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
idLabel.Font = Enum.Font.Gotham
idLabel.TextSize = 10
idLabel.Parent = frame

local function updateCounterDisplay()
    label.Text = tostring(comboCounter)
    if comboCounter == ACCOUNT_ID then
        frame.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        label.TextColor3 = Color3.fromRGB(100, 255, 100)
        idLabel.Text = ">>> МОЯ ОЧЕРЕДЬ <<<"
    else
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        label.TextColor3 = Color3.fromRGB(255, 200, 100)
        idLabel.Text = "ACC #" .. ACCOUNT_ID .. " (ждём " .. comboCounter .. ")"
    end
end

-- ================================================
-- Функции экипировки
-- ================================================
function EquipCanister()
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
        print("✅ [ACC " .. ACCOUNT_ID .. "] КОМБО КОКОС! (очередь была " .. comboCounter .. ")")
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
-- Мониторинг комбо (СИНХРОНИЗИРОВАННЫЙ)
-- ================================================
spawn(function()
    while true do
        local present = IsComboCoconutPresent()
        
        if present and not coconutActive then
            -- Комбо появилось
            coconutActive = true
            print("🌟 [ACC " .. ACCOUNT_ID .. "] Комбо появилось")
            
        elseif not present and coconutActive then
            -- Комбо исчезло = кто-то собрал
            coconutActive = false
            
            -- Увеличиваем счётчик (у ВСЕХ клиентов одинаково)
            comboCounter = comboCounter + 1
            if comboCounter > TOTAL_ACCOUNTS then 
                comboCounter = 1 
            end
            
            updateCounterDisplay()
            print("📊 [ACC " .. ACCOUNT_ID .. "] Счётчик очереди: " .. comboCounter)
        end
        
        task.wait(0.5)
    end
end)

-- ================================================
-- Таймер спавна комбо
-- ================================================
local function startSpawnTimer()
    if spawnTimer then
        task.cancel(spawnTimer)
        spawnTimer = nil
    end
    spawnTimer = task.spawn(function()
        task.wait(15)
        if lastValue == 39 and comboCounter == ACCOUNT_ID then
            print("🎯 [ACC " .. ACCOUNT_ID .. "] Кидаю КОМБО по таймеру!")
            SpawnCoconut(true)
        end
        spawnTimer = nil
    end)
end

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

                -- Экипировка
                if value == 39 and not hasPorcelain then
                    EquipPorcelain()
                end

                if value < 39 and not hasCanister then
                    EquipCanister()
                end

                -- Обычные кокосы
                if value == 11 or value == 17 or value == 23 then
                    SpawnCoconut(false)
                end

                -- Запуск таймера ТОЛЬКО если моя очередь
                if value == 39 and comboCounter == ACCOUNT_ID and not spawnTimer then
                    print("⏳ [ACC " .. ACCOUNT_ID .. "] Моя очередь! Запускаю таймер 15 сек...")
                    startSpawnTimer()
                end

                lastValue = value
            end
        end
    end
end)

-- Авто-экипировка канистры
spawn(function()
    while true do
        if lastValue ~= 39 and currentAccessory ~= "canister" then
            EquipCanister()
        end
        task.wait(5)
    end
end)

-- ================================================
-- КОМАНДЫ ДЛЯ СИНХРОНИЗАЦИИ (ВАЖНО!)
-- ================================================
getgenv().CC = {
    -- Установить счётчик вручную (на ВСЕХ аккаунтах ввести одинаковое число!)
    Set = function(n)
        comboCounter = n
        updateCounterDisplay()
        print("🔧 [ACC " .. ACCOUNT_ID .. "] Счётчик установлен: " .. n)
    end,
    
    -- Сбросить на 0
    Reset = function()
        comboCounter = 0
        updateCounterDisplay()
        print("🔧 [ACC " .. ACCOUNT_ID .. "] Счётчик сброшен на 0")
    end,
    
    -- Показать статус
    Status = function()
        print("========================================")
        print("🔧 [ACC " .. ACCOUNT_ID .. "] Статус:")
        print("   Счётчик очереди: " .. comboCounter)
        print("   Моя очередь: " .. tostring(comboCounter == ACCOUNT_ID))
        print("   Комбо активен: " .. tostring(coconutActive))
        print("   lastValue: " .. lastValue)
        print("   Таймер: " .. tostring(spawnTimer ~= nil))
        print("========================================")
    end,
}

-- ================================================
-- Старт
-- ================================================
updateCounterDisplay()
print("========================================")
print("✅ [ACC " .. ACCOUNT_ID .. "] Скрипт запущен!")
print("")
print("⚠️ ВАЖНО: Для синхронизации на ВСЕХ аккаунтах введи:")
print("   CC.Set(0)  — чтобы следующий комбо кинул ACC 1")
print("   CC.Set(1)  — чтобы следующий комбо кинул ACC 2")
print("   CC.Set(2)  — чтобы следующий комбо кинул ACC 3")
print("   и т.д.")
print("")
print("📊 CC.Status() — посмотреть состояние")
print("🔄 CC.Reset()  — сбросить на 0")
print("========================================")
