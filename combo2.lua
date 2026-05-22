-- ================================================
-- Combo Coconut Script (debug GUI)
-- ================================================
local ACCOUNT_ID = 2     -- поменяй на 2 или 3
local TOTAL_ACCOUNTS = 3

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local lastValue = -1
local coconutActive = false
local hasCanister = false
local hasPorcelain = false
local spawnTimer = nil
local comboCounter = 0
local thrownAtValue = {}

local updateCount = 0
local throwCount = 0
local comboThrowCount = 0
local lastEvent = "-"

local THROW_VALUES = {8, 20, 33}

-- ================================================
-- Интерфейс
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboCounter_" .. ACCOUNT_ID
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 130)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * 140)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local function makeLabel(y, h, size, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -6, 0, h)
    l.Position = UDim2.new(0, 3, 0, y)
    l.BackgroundTransparency = 1
    l.TextColor3 = color
    l.Font = Enum.Font.Gotham
    l.TextSize = size
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = ""
    l.Parent = frame
    return l
end

local bigLabel = makeLabel(2, 28, 22, Color3.fromRGB(255, 200, 100))
bigLabel.Font = Enum.Font.GothamBold
bigLabel.TextXAlignment = Enum.TextXAlignment.Center

local idLabel    = makeLabel(30, 14, 11, Color3.fromRGB(180, 180, 180))
local valueLabel = makeLabel(46, 14, 11, Color3.fromRGB(140, 200, 255))
local throwLabel = makeLabel(60, 14, 11, Color3.fromRGB(140, 200, 255))
local equipLabel = makeLabel(74, 14, 11, Color3.fromRGB(140, 200, 255))
local timerLabel = makeLabel(88, 14, 11, Color3.fromRGB(140, 200, 255))
local eventLabel = makeLabel(102, 14, 11, Color3.fromRGB(200, 180, 100))
local flagsLabel = makeLabel(116, 14, 11, Color3.fromRGB(160, 160, 160))

local function flagsString()
    local parts = {}
    for _, tv in ipairs(THROW_VALUES) do
        if thrownAtValue[tv] then
            table.insert(parts, tostring(tv) .. "*")
        else
            table.insert(parts, tostring(tv))
        end
    end
    return table.concat(parts, ",")
end

local function updateCounterDisplay()
    bigLabel.Text = tostring(comboCounter)

    if comboCounter == ACCOUNT_ID then
        frame.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        bigLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        idLabel.Text = ">>> MY TURN <<<  ACC#" .. ACCOUNT_ID
    else
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        bigLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        idLabel.Text = "ACC #" .. ACCOUNT_ID .. " (wait " .. comboCounter .. ")"
    end

    valueLabel.Text = "value: " .. tostring(lastValue) .. "  upd: " .. updateCount
    throwLabel.Text = "throws: " .. throwCount .. "   combos: " .. comboThrowCount
    equipLabel.Text = "equip: " .. (hasPorcelain and "PORCELAIN" or (hasCanister and "canister" or "-"))
    timerLabel.Text = "timer: " .. (spawnTimer ~= nil and "RUNNING" or "-")
    eventLabel.Text = "last: " .. lastEvent
    flagsLabel.Text = "flags: " .. flagsString()
end

-- ================================================
-- Экипировка
-- ================================================
function EquipCanister()
    if hasCanister then return end
    local args = {"Equip", { Category = "Accessory", Type = "Coconut Canister" }}
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    hasCanister = true
    hasPorcelain = false
    lastEvent = "equipped canister"
end

function EquipPorcelain()
    if hasPorcelain then return end
    local args = {"Equip", { Category = "Accessory", Type = "Porcelain Port-O-Hive" }}
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    hasPorcelain = true
    hasCanister = false
    lastEvent = "equipped porcelain"
end

-- ================================================
-- Бросок кокоса
-- ================================================
function SpawnCoconut(isCombo)
    local args = { { Name = "Coconut" } }
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args))
    if isCombo then
        comboThrowCount = comboThrowCount + 1
        lastEvent = "COMBO thrown!"
    else
        throwCount = throwCount + 1
        lastEvent = "coconut at v=" .. lastValue
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
-- Очередь по детекту частицы
-- ================================================
spawn(function()
    while true do
        local present = IsComboCoconutPresent()
        if present and not coconutActive then
            coconutActive = true
            lastEvent = "combo appeared"
        elseif not present and coconutActive then
            coconutActive = false
            comboCounter = comboCounter + 1
            if comboCounter > TOTAL_ACCOUNTS then comboCounter = 1 end
            lastEvent = "queue -> " .. comboCounter
            updateCounterDisplay()
        end
        task.wait(0.5)
    end
end)

-- ================================================
-- Таймер комбо 13 сек
-- ================================================
local function startSpawnTimer()
    if spawnTimer then task.cancel(spawnTimer) spawnTimer = nil end
    spawnTimer = task.spawn(function()
        task.wait(13)
        if lastValue == 39 and comboCounter == ACCOUNT_ID then
            SpawnCoconut(true)
        end
        spawnTimer = nil
    end)
end

-- ================================================
-- Главный слушатель
-- ================================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                updateCount = updateCount + 1
                local value = info.Values and info.Values[1] or 0

                if value == 0 then
                    thrownAtValue = {}
                end

                if value < 39 and spawnTimer then
                    task.cancel(spawnTimer)
                    spawnTimer = nil
                end

                -- Экипировка: канистра 0-34, фарфор от 35
                if value <= 34 then
                    EquipCanister()
                else
                    EquipPorcelain()
                end

                -- Бросок кокоса (строго на триггерное value)
                if value <= 34 then
                    for _, tv in ipairs(THROW_VALUES) do
                        if value == tv and not thrownAtValue[tv] then
                            thrownAtValue[tv] = true
                            SpawnCoconut(false)
                            break
                        end
                    end
                end

                if value == 39 and comboCounter == ACCOUNT_ID and not spawnTimer then
                    startSpawnTimer()
                    lastEvent = "timer started"
                end

                lastValue = value
                updateCounterDisplay()
            end
        end
    end
end)

-- ================================================
-- АГРЕССИВНЫЙ ФОЛЛБЭК КАНИСТРЫ
-- Раз в 1 секунду проверяет: если value в зоне 0-34 и канистры нет — одевает.
-- Также при самом старте (lastValue == -1) пытается одеть, чтобы быть готовым.
-- ================================================
spawn(function()
    -- При запуске сразу пробуем надеть канистру
    EquipCanister()

    while true do
        if (lastValue == -1) or (lastValue >= 0 and lastValue <= 34) then
            if not hasCanister then
                EquipCanister()
            end
        end
        task.wait(1)
    end
end)

-- Регулярное обновление дисплея
spawn(function()
    while true do
        updateCounterDisplay()
        task.wait(1)
    end
end)

-- ================================================
-- Команды
-- ================================================
getgenv().CC = {
    Set = function(n) comboCounter = n; updateCounterDisplay() end,
    Reset = function()
        comboCounter = 0
        coconutActive = false
        thrownAtValue = {}
        throwCount = 0
        comboThrowCount = 0
        updateCount = 0
        lastEvent = "reset"
        if spawnTimer then task.cancel(spawnTimer) spawnTimer = nil end
        updateCounterDisplay()
    end,
    Throw = function() SpawnCoconut(false) end,
}

updateCounterDisplay()
lastEvent = "script loaded"
