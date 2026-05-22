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
local cycleId = 0  -- увеличивается с каждым новым циклом, защита от старых отложенных вызовов

-- Интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboCounter_" .. ACCOUNT_ID
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 130, 0, 64)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * 74)
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
label.Size = UDim2.new(1, 0, 0, 26)
label.Position = UDim2.new(0, 0, 0, 2)
label.BackgroundTransparency = 1
label.Text = "0"
label.TextColor3 = Color3.fromRGB(255, 200, 100)
label.Font = Enum.Font.GothamBold
label.TextSize = 22
label.Parent = frame

local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(1, -6, 0, 14)
idLabel.Position = UDim2.new(0, 3, 0, 28)
idLabel.BackgroundTransparency = 1
idLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
idLabel.Font = Enum.Font.Gotham
idLabel.TextSize = 11
idLabel.TextXAlignment = Enum.TextXAlignment.Center
idLabel.Parent = frame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -6, 0, 14)
infoLabel.Position = UDim2.new(0, 3, 0, 44)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(140, 200, 255)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 10
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.Parent = frame

local totalThrows = 0

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
    infoLabel.Text = "v:" .. lastValue .. " t:" .. totalThrows .. " c:" .. cycleId
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
    if not isCombo then
        totalThrows = totalThrows + 1
    end
    if isCombo then
        task.delay(11, function() SpawnCoconut(false) end)
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
-- Цикл бросков через task.delay (не корутина)
-- 4 отложенных вызова, каждый со своим временем
-- ================================================
local function runThrowCycle()
    cycleId = cycleId + 1
    local myCycleId = cycleId

    -- 4 отложенных вызова: t+10, t+20, t+30, t+40
    -- Каждый проверяет что cycleId не сменился (если ещё один цикл стартанул — отменяем себя)
    for i = 1, 4 do
        task.delay(10 * i, function()
            if cycleId ~= myCycleId then return end  -- старый цикл, игнорим
            SpawnCoconut(false)
        end)
    end
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
    if spawnTimer then task.cancel(spawnTimer); spawnTimer = nil end
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

                if value < 39 and spawnTimer then
                    task.cancel(spawnTimer); spawnTimer = nil
                end

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

-- ВОТЧДОГ: запускает цикл когда value=0 и предыдущий цикл уже не активен
-- Защита: чтобы не запускать снова и снова пока value=0,
-- запоминаем что цикл стартанул и ждём пока value не станет не-0 (значит цикл реально начался)
local lastCycleStartValue = nil

spawn(function()
    while true do
        if lastValue == 0 then
            -- Если предыдущий цикл стартовали не на текущем "нуле" — стартуем
            if lastCycleStartValue ~= 0 then
                lastCycleStartValue = 0
                runThrowCycle()
            end
        else
            -- Value не 0 — разрешаем следующий запуск когда снова станет 0
            lastCycleStartValue = nil
        end
        task.wait(1)
    end
end)

-- Фоллбэк экипировки раз в 1 сек
spawn(function()
    while true do
        if lastValue == 39 then
            if not hasPorcelain then EquipPorcelain() end
        elseif lastValue >= 0 and lastValue <= 38 then
            if not hasCanister then EquipCanister() end
        end
        task.wait(1)
    end
end)

-- Обновление дисплея
spawn(function()
    while true do
        updateCounterDisplay()
        task.wait(1)
    end
end)

updateCounterDisplay()
