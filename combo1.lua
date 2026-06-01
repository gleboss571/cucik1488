--[[
   ALT Combo Coconut Thrower (v5 + настройки цикла и таймера)
   Переменные: CYCLE_COUNT (кокосов в цикле), COMBO_DELAY (секунд перед комбо)
   Delta-совместим, задержка старта 10 сек.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local MAIN_ACCOUNT_NAME = "Kukurudza_dontreal"  -- ИМЯ МЕЙНА
local ACCOUNT_ID = 1                              -- ваш ID (1,2,3)
local TOTAL_ACCOUNTS = 2
local START_DELAY = 10                            -- секунд на запуск скриптов
local SCAN_INTERVAL = 0.5
local COCONUT_INTERVAL = 10                       -- пауза между кокосами в цикле
local CYCLE_DELAY = 10                            -- задержка перед циклом
local CYCLE_COUNT = 4                             -- количество кокосов в цикле (по умолчанию 4)
local COMBO_DELAY = 18                            -- задержка перед комбо-броском (сек)

local LP = Players.LocalPlayer

-- Прямой доступ
local Events = ReplicatedStorage:WaitForChild("Events")
local PlayerAbilityEvent = Events:WaitForChild("PlayerAbilityEvent")
local PlayerActivesCommand = Events:WaitForChild("PlayerActivesCommand")
local ItemPackageEvent = Events:WaitForChild("ItemPackageEvent")

-- Переменные состояния
local lastValue = -1
local lastValueChangeTime = tick()
local coconutActive = false
local hasCanister = false
local hasPorcelain = false
local spawnTimer = nil
local comboCounter = 0
local totalThrows = 0
local cycleActive = false
local thrownThisCycle = 0
local cycleSize = 0
local firstUpdateReceived = false
local scorchingActive = false
local canThrow = false
local startTime = tick()

-- =============== GUI ===============
local playerGui = LP:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboThrower_" .. ACCOUNT_ID
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 110)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID-1)*120)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-10,0,20)
statusLabel.Position = UDim2.new(0,5,0,5)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Val: - | Flag: false"
statusLabel.TextColor3 = Color3.fromRGB(255,255,255)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Parent = frame

local throwLabel = Instance.new("TextLabel")
throwLabel.Size = UDim2.new(1,-10,0,18)
throwLabel.Position = UDim2.new(0,5,0,26)
throwLabel.BackgroundTransparency = 1
throwLabel.Text = "Throws: 0"
throwLabel.TextColor3 = Color3.fromRGB(200,200,200)
throwLabel.Font = Enum.Font.Gotham
throwLabel.TextSize = 11
throwLabel.Parent = frame

local countdownLabel = Instance.new("TextLabel")
countdownLabel.Size = UDim2.new(1,-10,0,18)
countdownLabel.Position = UDim2.new(0,5,0,44)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text = "Wait " .. START_DELAY .. "s"
countdownLabel.TextColor3 = Color3.fromRGB(255,200,100)
countdownLabel.Font = Enum.Font.Gotham
countdownLabel.TextSize = 11
countdownLabel.Parent = frame

-- Лог
local logLabel1 = Instance.new("TextLabel")
logLabel1.Size = UDim2.new(1,-10,0,16)
logLabel1.Position = UDim2.new(0,5,0,64)
logLabel1.BackgroundTransparency = 1
logLabel1.Text = ""
logLabel1.TextColor3 = Color3.fromRGB(180,255,180)
logLabel1.Font = Enum.Font.Code
logLabel1.TextSize = 10
logLabel1.Parent = frame

local logLabel2 = Instance.new("TextLabel")
logLabel2.Size = UDim2.new(1,-10,0,16)
logLabel2.Position = UDim2.new(0,5,0,80)
logLabel2.BackgroundTransparency = 1
logLabel2.Text = ""
logLabel2.TextColor3 = Color3.fromRGB(180,255,180)
logLabel2.Font = Enum.Font.Code
logLabel2.TextSize = 10
logLabel2.Parent = frame

local function addLog(msg)
    logLabel2.Text = logLabel1.Text
    logLabel1.Text = msg
end

local function updateGUI()
    statusLabel.Text = string.format("Val: %d | Flag: %s", lastValue, tostring(scorchingActive))
    throwLabel.Text = "Throws: " .. totalThrows
    if not canThrow then
        local remaining = math.max(0, START_DELAY - (tick() - startTime))
        countdownLabel.Text = "Wait " .. math.ceil(remaining) .. "s"
    else
        countdownLabel.Text = ""
    end
end

-- =============== ЭКИПИРОВКА (как в v5) ===============
local function equipAccessory(itemType)
    pcall(function()
        ItemPackageEvent:InvokeServer("Equip", {
            Category = "Accessory",
            Type = itemType,
        })
    end)
end

local function equipCanister()
    if hasCanister then return end
    equipAccessory("Coconut Canister")
    hasCanister = true
    hasPorcelain = false
end

local function equipPorcelain()
    if hasPorcelain then return end
    equipAccessory("Porcelain Port-O-Hive")
    hasPorcelain = true
    hasCanister = false
end

-- =============== ПРОВЕРКА ФЛАГА ===============
local function checkMainCoconut()
    local mainPlayer = Players:FindFirstChild(MAIN_ACCOUNT_NAME)
    if not mainPlayer then return false end
    local char = mainPlayer.Character
    if not char then return false end
    for _, child in ipairs(char:GetChildren()) do
        if child.Name == "Coconut Canister" then return true end
    end
    return false
end

task.spawn(function()
    while true do
        local newFlag = checkMainCoconut()
        if newFlag ~= scorchingActive then
            scorchingActive = newFlag
            updateGUI()
            addLog("Flag " .. (scorchingActive and "ON" or "OFF"))
            if scorchingActive and lastValue == 39 and comboCounter == ACCOUNT_ID and not spawnTimer and canThrow then
                startSpawnTimer()
            end
        end
        task.wait(SCAN_INTERVAL)
    end
end)

-- =============== БРОСОК КОКОСА ===============
local function SpawnCoconut()
    PlayerActivesCommand:FireServer({ Name = "Coconut" })
    totalThrows = totalThrows + 1
    updateGUI()
    addLog("THROW!")
end

-- =============== ЦИКЛ БРОСКОВ (настраиваемый CYCLE_COUNT) ===============
local function startCycle(count)
    if cycleActive then return end
    cycleActive = true
    cycleSize = count
    thrownThisCycle = 0
    updateGUI()
    task.spawn(function()
        task.wait(CYCLE_DELAY)
        for i = 1, count do
            SpawnCoconut()
            thrownThisCycle = i
            updateGUI()
            if i < count then
                task.wait(COCONUT_INTERVAL)
            end
        end
        cycleActive = false
        updateGUI()
    end)
end

-- =============== ДЕТЕКТОР ComboCoconut (очередь) ===============
task.spawn(function()
    while true do
        local present = false
        local particles = Workspace:FindFirstChild("Particles")
        if particles then
            for _, obj in ipairs(particles:GetChildren()) do
                if obj.Name == "ComboCoconut" then present = true; break end
            end
        end
        if present and not coconutActive then
            coconutActive = true
        elseif not present and coconutActive then
            coconutActive = false
            comboCounter = comboCounter + 1
            if comboCounter > TOTAL_ACCOUNTS then comboCounter = 1 end
            lastValue = 0
            lastValueChangeTime = tick()
            updateGUI()
        end
        task.wait(0.5)
    end
end)

-- =============== ФОЛЛБЭК СТАРТА (value == 0) ===============
task.spawn(function()
    while true do
        if firstUpdateReceived and lastValue == 0 and not cycleActive and not coconutActive and canThrow then
            task.wait(3)
            if lastValue == 0 and not cycleActive and not coconutActive and canThrow then
                startCycle(CYCLE_COUNT)
            end
        end
        task.wait(1)
    end
end)

-- =============== ТАЙМЕР КОМБО (настраиваемый COMBO_DELAY) ===============
local function startSpawnTimer()
    if spawnTimer then task.cancel(spawnTimer) spawnTimer = nil end
    spawnTimer = task.spawn(function()
        task.wait(COMBO_DELAY)
        if lastValue == 39 and comboCounter == ACCOUNT_ID and scorchingActive then
            SpawnCoconut()
            startCycle(CYCLE_COUNT)
        end
        spawnTimer = nil
    end)
end

-- =============== СЛУШАТЕЛЬ PlayerAbilityEvent ===============
PlayerAbilityEvent.OnClientEvent:Connect(function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                if not firstUpdateReceived then
                    firstUpdateReceived = true
                    lastValue = value
                    if value <= 34 then equipCanister() else equipPorcelain() end
                    updateGUI()
                    addLog("Init " .. value)
                    if value == 39 and comboCounter == ACCOUNT_ID and scorchingActive and canThrow then
                        startSpawnTimer()
                    end
                    return
                end
                if value ~= lastValue then
                    lastValue = value
                    lastValueChangeTime = tick()
                    updateGUI()
                    addLog(value .. (value <= 34 and " Can" or " Porc"))
                    if value <= 34 then equipCanister() else equipPorcelain() end
                    if value == 39 and comboCounter == ACCOUNT_ID and scorchingActive and canThrow and not spawnTimer then
                        startSpawnTimer()
                    elseif value < 39 and spawnTimer then
                        task.cancel(spawnTimer)
                        spawnTimer = nil
                    end
                end
            end
        end
    end
end)

-- =============== ВОТЧДОГ (value == 39 зависло) ===============
task.spawn(function()
    while true do
        task.wait(5)
        if lastValue == 39 and (tick() - lastValueChangeTime) > 30 then
            lastValue = 0
            lastValueChangeTime = tick()
        end
    end
end)

-- =============== ЗАДЕРЖКА СТАРТА ===============
task.spawn(function()
    while tick() - startTime < START_DELAY do
        updateGUI()
        task.wait(0.5)
    end
    canThrow = true
    addLog("START")
    if lastValue == 39 and comboCounter == ACCOUNT_ID and scorchingActive and not spawnTimer then
        startSpawnTimer()
    end
end)

-- Первичная экипировка
equipCanister()
updateGUI()
addLog("Wait " .. START_DELAY .. "s")
