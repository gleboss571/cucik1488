--[[
   ALT Combo Coconut Thrower (Firebase-очередь, улучшенный)
   Попытки броска: 1) unpack, 2) unpack, 3) без unpack.
   + индикатор FB, повторные запросы, восстановление очереди.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

-- ====================== НАСТРОЙКИ ======================
local FIREBASE_URL = "https://fuflik1-e9325-default-rtdb.europe-west1.firebasedatabase.app"
local ACCOUNT_ID = 1                  -- 1,2,3,4
local TOTAL_ACCOUNTS = 4
local COMBO_DELAY = 18                -- задержка перед броском
local CYCLE_COUNT = 4                 -- кокосов после комбо
local CYCLE_DELAY = 10                -- задержка перед циклом
local COCONUT_INTERVAL = 10           -- между обычными кокосами
local START_DELAY = 10                -- пауза при запуске
local CHECK_INTERVAL = 0.5            -- интервал проверки очереди

local LP = Players.LocalPlayer

-- Прямой доступ к событиям
local Events = ReplicatedStorage:WaitForChild("Events")
local PlayerAbilityEvent = Events:WaitForChild("PlayerAbilityEvent")
local PlayerActivesCommand = Events:WaitForChild("PlayerActivesCommand")
local ItemPackageEvent = Events:WaitForChild("ItemPackageEvent")

-- Переменные
local lastValue = -1
local lastValueChangeTime = tick()
local hasCanister = false
local hasPorcelain = false
local totalThrows = 0
local cycleActive = false
local canThrow = false
local startTime = tick()
local spawnTimer = nil
local fbStatus = "FB: --"

-- =============== GUI ===============
local playerGui = LP:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboThrower_" .. ACCOUNT_ID
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 100)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID-1)*110)
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
statusLabel.Text = "Val: - | Queue: ?"
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

local fbLabel = Instance.new("TextLabel")
fbLabel.Size = UDim2.new(1,-10,0,16)
fbLabel.Position = UDim2.new(0,5,0,62)
fbLabel.BackgroundTransparency = 1
fbLabel.Text = "FB: --"
fbLabel.TextColor3 = Color3.fromRGB(255,255,255)
fbLabel.Font = Enum.Font.Code
fbLabel.TextSize = 10
fbLabel.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1,-10,0,16)
logLabel.Position = UDim2.new(0,5,0,78)
logLabel.BackgroundTransparency = 1
logLabel.Text = ""
logLabel.TextColor3 = Color3.fromRGB(180,255,180)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 10
logLabel.Parent = frame

local function addLog(msg)
    logLabel.Text = msg
    pcall(function() appendfile("combo_log.txt", os.date("[%H:%M:%S] ") .. msg .. "\n") end)
end

local function updateGUI(queue)
    statusLabel.Text = string.format("Val: %d | Queue: %s", lastValue, tostring(queue))
    throwLabel.Text = "Throws: " .. totalThrows
    if not canThrow then
        local remaining = math.max(0, START_DELAY - (tick() - startTime))
        countdownLabel.Text = "Wait " .. math.ceil(remaining) .. "s"
    else
        countdownLabel.Text = ""
    end
    fbLabel.Text = fbStatus
end

-- =============== Firebase: надёжные запросы ===============
local function safeRequest(url, method, body)
    for attempt = 1, 3 do
        local ok, result = pcall(function()
            return request({
                Url = url,
                Method = method,
                Headers = method ~= "GET" and {["Content-Type"] = "application/json"} or nil,
                Body = body
            })
        end)
        if ok and result and result.Body then
            fbStatus = "FB: OK"
            return result.Body
        end
        fbStatus = "FB: ERR" .. attempt
        task.wait(1)
    end
    fbStatus = "FB: FAIL"
    return nil
end

local function readQueue()
    local body = safeRequest(FIREBASE_URL .. "/comboQueue.json", "GET")
    if body then
        return tonumber(body)
    end
    return nil
end

local function writeQueue(value)
    safeRequest(FIREBASE_URL .. "/comboQueue.json", "PUT", tostring(value))
    safeRequest(FIREBASE_URL .. "/comboQueueLastUpdate.json", "PUT", tostring(tick()))
end

local function readLastUpdateTime()
    local body = safeRequest(FIREBASE_URL .. "/comboQueueLastUpdate.json", "GET")
    if body then
        return tonumber(body)
    end
    return nil
end

-- =============== Проверка ComboCoconut ===============
local function hasComboCoconut()
    local particles = Workspace:FindFirstChild("Particles")
    if particles then
        for _, obj in ipairs(particles:GetChildren()) do
            if obj.Name == "ComboCoconut" then return true end
        end
    end
    return false
end

-- =============== ЭКИПИРОВКА ===============
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

-- =============== БРОСОК: 1) unpack, 2) unpack, 3) без unpack ===============
local function SpawnCoconut()
    -- Попытка 1: unpack
    PlayerActivesCommand:FireServer(unpack({ { Name = "Coconut" } }))
    task.wait(1)
    if hasComboCoconut() then
        totalThrows = totalThrows + 1
        updateGUI(readQueue() or 0)
        addLog("THROW! (unpack 1)")
        return true
    end

    -- Попытка 2: unpack (повтор)
    addLog("Retry unpack 2...")
    PlayerActivesCommand:FireServer(unpack({ { Name = "Coconut" } }))
    task.wait(1)
    if hasComboCoconut() then
        totalThrows = totalThrows + 1
        updateGUI(readQueue() or 0)
        addLog("THROW! (unpack 2)")
        return true
    end

    -- Попытка 3: без unpack
    addLog("Retry without unpack...")
    PlayerActivesCommand:FireServer({ Name = "Coconut" })
    task.wait(1)
    if hasComboCoconut() then
        totalThrows = totalThrows + 1
        updateGUI(readQueue() or 0)
        addLog("THROW! (no unpack)")
        return true
    end

    addLog("FAILED to spawn ComboCoconut")
    return false
end

-- =============== ЦИКЛ БРОСКОВ ===============
local function startCycle(count)
    if cycleActive then return end
    cycleActive = true
    task.spawn(function()
        task.wait(CYCLE_DELAY)
        for i = 1, count do
            SpawnCoconut()
            if i < count then
                task.wait(COCONUT_INTERVAL)
            end
        end
        cycleActive = false
    end)
end

-- =============== ОСНОВНАЯ ЛОГИКА ===============
local function tryCombo()
    if not canThrow then return end
    if lastValue ~= 39 then return end
    local currentQueue = readQueue()
    if not currentQueue then return end
    updateGUI(currentQueue)

    if currentQueue ~= ACCOUNT_ID then return end
    if spawnTimer then return end

    spawnTimer = task.spawn(function()
        task.wait(COMBO_DELAY)
        spawnTimer = nil
        local finalQueue = readQueue()
        if lastValue == 39 and finalQueue == ACCOUNT_ID then
            local success = SpawnCoconut()
            if success then
                startCycle(CYCLE_COUNT)
                local nextQueue = ACCOUNT_ID + 1
                if nextQueue > TOTAL_ACCOUNTS then nextQueue = 1 end
                writeQueue(nextQueue)
                addLog("Queue → " .. nextQueue)
            else
                local nextQueue = ACCOUNT_ID + 1
                if nextQueue > TOTAL_ACCOUNTS then nextQueue = 1 end
                writeQueue(nextQueue)
                addLog("Fail, force queue → " .. nextQueue)
            end
        else
            addLog("Abort: val=" .. lastValue .. " queue=" .. tostring(finalQueue))
        end
    end)
end

-- =============== СЛУШАТЕЛЬ ===============
PlayerAbilityEvent.OnClientEvent:Connect(function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                if value ~= lastValue then
                    lastValue = value
                    lastValueChangeTime = tick()
                    updateGUI(readQueue() or 0)
                    addLog(value .. (value <= 34 and " Can" or " Porc"))
                    if value <= 34 then equipCanister() else equipPorcelain() end
                    if value == 39 then
                        tryCombo()
                    elseif value < 39 and spawnTimer then
                        task.cancel(spawnTimer)
                        spawnTimer = nil
                    end
                end
            end
        end
    end
end)

-- =============== ЗАДЕРЖКА СТАРТА + ВОССТАНОВЛЕНИЕ ===============
task.spawn(function()
    while tick() - startTime < START_DELAY do
        updateGUI(readQueue() or 0)
        task.wait(0.5)
    end

    local lastUpdate = readLastUpdateTime()
    if lastUpdate and (tick() - lastUpdate) > 300 then
        writeQueue(1)
        addLog("Queue idle >5min, reset to 1")
    end

    local currentQueue = readQueue()
    if currentQueue then
        updateGUI(currentQueue)
        if currentQueue == ACCOUNT_ID and lastValue == 39 then
            tryCombo()
        end
    end

    canThrow = true
    addLog("START")
end)

-- =============== ВОТЧДОГ ===============
task.spawn(function()
    while true do
        task.wait(30)
        if lastValue == 39 and (tick() - lastValueChangeTime) > 30 then
            lastValue = 0
            lastValueChangeTime = tick()
            if spawnTimer then
                task.cancel(spawnTimer)
                spawnTimer = nil
            end
        end
    end
end)

equipCanister()
updateGUI(0)
addLog("Wait " .. START_DELAY .. "s")
