local ACCOUNT_ID = 1     -- поменяй на 2 или 3
local TOTAL_ACCOUNTS = 3

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local lastValue = -1
local coconutActive = false
local hasCanister = false
local hasPorcelain = false
local comboCounter = 0
local spawnTimer = nil
local throwLoop = nil
local firstUpdateReceived = false

-- Интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboCounter_" .. ACCOUNT_ID
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 120, 0, 50)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * 60)
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
idLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
idLabel.Font = Enum.Font.Gotham
idLabel.TextSize = 11
idLabel.TextXAlignment = Enum.TextXAlignment.Center
idLabel.Parent = frame

local function updateCounterDisplay()
    label.Text = tostring(comboCounter)
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

function EquipCanister()
    local args = {"Equip", { Category = "Accessory", Type = "Coconut Canister" }}
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    hasCanister = true
    hasPorcelain = false
end

function EquipPorcelain()
    local args = {"Equip", { Category = "Accessory", Type = "Porcelain Port-O-Hive" }}
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    hasPorcelain = true
    hasCanister = false
end

function SpawnCoconut(isCombo)
    local args = { { Name = "Coconut" } }
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args))
    if isCombo then
        task.spawn(function()
            task.wait(11)
            SpawnCoconut(false)
        end)
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

-- Цикл: ждём 10 сек, потом 4 кокоса каждые 10 сек
local function startThrowCycle()
    if throwLoop then
        task.cancel(throwLoop)
        throwLoop = nil
    end
    throwLoop = task.spawn(function()
        task.wait(10)
        for i = 1, 4 do
            SpawnCoconut(false)
            if i < 4 then
                task.wait(10)
            end
        end
        throwLoop = nil
    end)
end

-- Очередь
spawn(function()
    while true do
        local present = IsComboCoconutPresent()
        if present and not coconutActive then
            coconutActive = true
        elseif not present and coconutActive then
            coconutActive = false
            comboCounter = comboCounter + 1
            if comboCounter > TOTAL_ACCOUNTS then comboCounter = 1 end
            updateCounterDisplay()
        end
        task.wait(0.5)
    end
end)

-- Таймер комбо 13 сек
local function startSpawnTimer()
    if spawnTimer then
        task.cancel(spawnTimer)
        spawnTimer = nil
    end
    spawnTimer = task.spawn(function()
        task.wait(13)
        if lastValue == 39 and comboCounter == ACCOUNT_ID then
            SpawnCoconut(true)
        end
        spawnTimer = nil
    end)
end

-- Главный слушатель
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                local prevValue = lastValue

                -- Запуск цикла при value = 0
                -- Срабатывает и при первом апдейте если value=0, и при сбросе после комбо
                if value == 0 and prevValue ~= 0 then
                    startThrowCycle()
                end

                firstUpdateReceived = true

                if value < 39 and spawnTimer then
                    task.cancel(spawnTimer)
                    spawnTimer = nil
                end

                -- Экипировка строго по value
                if value == 39 then
                    EquipPorcelain()
                else
                    EquipCanister()
                end

                if value == 39 and comboCounter == ACCOUNT_ID and not spawnTimer then
                    startSpawnTimer()
                end

                lastValue = value
            end
        end
    end
end)

-- Подстраховка: если апдейт за 3 сек не пришёл — значит value уже давно 0,
-- запускаем серию вручную
spawn(function()
    task.wait(3)
    if not firstUpdateReceived then
        startThrowCycle()
    end
end)

-- Фоллбэк экипировки раз в 1 сек
-- Жёстко по lastValue: если value=39 — фарфор, иначе канистра
spawn(function()
    while true do
        if lastValue == 39 then
            if not hasPorcelain then
                EquipPorcelain()
            end
        elseif lastValue >= 0 and lastValue <= 38 then
            if not hasCanister then
                EquipCanister()
            end
        end
        task.wait(1)
    end
end)

updateCounterDisplay()
