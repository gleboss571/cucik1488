-- ================================================
-- Combo Coconut Script
-- ================================================
local ACCOUNT_ID = 3
local TOTAL_ACCOUNTS = 3
local LOGS = false

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
local lastCoconutThrow = 0
local COCONUT_COOLDOWN = 1.0

-- Стоп-значения
local STOP_VALUES = {4, 9, 14, 19, 24, 29, 34}
local reachedStopValue = false

-- Триггер-значения для обычных кокосов
local THROW_VALUES = {16, 22, 28}
local thrownAtValue = {}

local function isStopValue(v)
    for _, sv in ipairs(STOP_VALUES) do
        if v == sv then return true end
    end
    return false
end

local function isThrowValue(v)
    for _, tv in ipairs(THROW_VALUES) do
        if v == tv then return true end
    end
    return false
end

-- ================================================
-- Интерфейс (компактный)
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboCounter_" .. ACCOUNT_ID
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 160, 0, 80)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * 90)
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
label.Size = UDim2.new(1, 0, 0, 28)
label.Position = UDim2.new(0, 0, 0, 2)
label.BackgroundTransparency = 1
label.Text = "0"
label.TextColor3 = Color3.fromRGB(255, 200, 100)
label.Font = Enum.Font.GothamBold
label.TextSize = 22
label.Parent = frame

local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(1, -6, 0, 16)
idLabel.Position = UDim2.new(0, 3, 0, 30)
idLabel.BackgroundTransparency = 1
idLabel.Text = "ACC #" .. ACCOUNT_ID
idLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
idLabel.Font = Enum.Font.Gotham
idLabel.TextSize = 12
idLabel.Parent = frame

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, -6, 0, 14)
valueLabel.Position = UDim2.new(0, 3, 0, 46)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "value: -"
valueLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
valueLabel.Font = Enum.Font.Gotham
valueLabel.TextSize = 11
valueLabel.Parent = frame

local stopLabel = Instance.new("TextLabel")
stopLabel.Size = UDim2.new(1, -6, 0, 14)
stopLabel.Position = UDim2.new(0, 3, 0, 60)
stopLabel.BackgroundTransparency = 1
stopLabel.Text = ""
stopLabel.TextColor3 = Color3.fromRGB(80, 180, 80)
stopLabel.Font = Enum.Font.Gotham
stopLabel.TextSize = 11
stopLabel.Parent = frame

local function updateCounterDisplay()
    label.Text = tostring(comboCounter)
    valueLabel.Text = "value: " .. tostring(lastValue)

    if reachedStopValue then
        stopLabel.Text = "STOP (wait 0)"
        stopLabel.TextColor3 = Color3.fromRGB(200, 150, 50)
    else
        stopLabel.Text = "throwing"
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
-- Мониторинг комбо (оригинальная логика: исчезновение частицы)
-- ================================================
spawn(function()
    while true do
        local present = IsComboCoconutPresent()

        if present and not coconutActive then
            coconutActive = true
            log("[ACC " .. ACCOUNT_ID .. "] Combo appeared")

        elseif not present and coconutActive then
            coconutActive = false
            comboCounter = comboCounter + 1
            if comboCounter > TOTAL_ACCOUNTS then
                comboCounter = 1
            end
            log("[ACC " .. ACCOUNT_ID .. "] Queue: " .. comboCounter)
            updateCounterDisplay()
        end

        task.wait(0.5)
    end
end)

-- ================================================
-- Таймер комбо (13 сек)
-- ================================================
local function startSpawnTimer()
    if spawnTimer then
        task.cancel(spawnTimer)
        spawnTimer = nil
    end
    spawnTimer = task.spawn(function()
        task.wait(13)
        if lastValue == 39 and comboCounter == ACCOUNT_ID then
            log("[ACC " .. ACCOUNT_ID .. "] Throwing COMBO by timer!")
            SpawnCoconut(true)
        end
        spawnTimer = nil
    end)
end

-- ================================================
-- Слушатель PlayerAbilityEvent
-- ================================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0

                if value == 0 then
                    reachedStopValue = false
                    thrownAtValue = {}
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

                -- Стоп-флаг (для отображения и фоллбэк-логики)
                if value >= 0 and value <= 34 then
                    if isStopValue(value) then
                        if not reachedStopValue then
                            reachedStopValue = true
                            log("[ACC " .. ACCOUNT_ID .. "] Reached stop: " .. value)
                        end
                    end
                end

                -- ====== ОБЫЧНЫЕ КОКОСЫ: только на 16, 22, 28 ======
                if isThrowValue(value) and not thrownAtValue[value] then
                    thrownAtValue[value] = true
                    TryThrowCoconut()
                end

                if value == 39 and comboCounter == ACCOUNT_ID and not spawnTimer then
                    log("[ACC " .. ACCOUNT_ID .. "] My turn! Timer 13 sec...")
                    startSpawnTimer()
                end

                lastValue = value
                updateCounterDisplay()
            end
        end
    end
end)

-- Фоновый кокосо-кидатель: добивает 16/22/28 если апдейт пропустился
spawn(function()
    while true do
        if isThrowValue(lastValue) and not thrownAtValue[lastValue] then
            thrownAtValue[lastValue] = true
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
        coconutActive = false
        thrownAtValue = {}
        if spawnTimer then task.cancel(spawnTimer) spawnTimer = nil end
        updateCounterDisplay()
        log("[ACC " .. ACCOUNT_ID .. "] Full reset")
    end,

    ResetStop = function()
        reachedStopValue = false
        updateCounterDisplay()
        log("[ACC " .. ACCOUNT_ID .. "] Stop flag reset")
    end,

    SetLogs = function(v)
        LOGS = v and true or false
    end,
}

updateCounterDisplay()
