--[[
   ALT Combo Coconut Thrower (Firebase v3)
   Тригер: ComboCoconut исчез из Particles → таймер → бросок.
   Ждёт исчезновения кокоса перед броском.
   Delta-совместим, Lua 5.1.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- ====================== НАСТРОЙКИ ======================
local FIREBASE_URL      = "https://fuflik1-e9325-default-rtdb.europe-west1.firebasedatabase.app"
local FIREBASE_PATH     = ""
local ACCOUNT_ID        = 1    -- менять на каждом аккаунте: 1, 2, 3, 4
local TOTAL_ACCOUNTS    = 4
local START_DELAY       = 10
local COMBO_DELAY       = 16   -- секунд после исчезновения кокоса → бросок
local CYCLE_COUNT       = 4
local CYCLE_DELAY       = 10
local COCONUT_INTERVAL  = 10
local QUEUE_POLL_INTERVAL = 1
local SKIP_DELAY        = 1
local COCONUT_SCAN      = 0.1  -- как часто сканируем Particles

local LP = Players.LocalPlayer

local Events               = ReplicatedStorage:WaitForChild("Events")
local PlayerAbilityEvent   = Events:WaitForChild("PlayerAbilityEvent")
local PlayerActivesCommand = Events:WaitForChild("PlayerActivesCommand")
local ItemPackageEvent     = Events:WaitForChild("ItemPackageEvent")

-- ====================== СОСТОЯНИЕ ======================
local lastValue           = -1
local lastValueChangeTime = tick()
local hasCanister         = false
local hasPorcelain        = false
local comboThread         = nil
local totalThrows         = 0
local cycleActive         = false
local firstUpdateReceived = false
local canThrow            = false
local startTime           = tick()
local skipping            = false
local comboLock           = false
local lastEquipTime       = 0
local comboThrownBy       = 0

local coconutPresent          = false
local coconutSeenWhileMyQueue = false

local cachedQueue    = 0
local lastQueueCheck = 0
local fbStatus       = "FB: --"

-- ====================== GUI ======================
local playerGui = LP:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("ComboThrower_" .. ACCOUNT_ID)
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboThrower_" .. ACCOUNT_ID
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 120)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * 130)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 8, 0, 8)
indicator.Position = UDim2.new(0, 225, 0, 8)
indicator.BorderSizePixel = 0
indicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
indicator.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 20)
statusLabel.Position = UDim2.new(0, 5, 0, 5)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Parent = frame

local throwLabel = Instance.new("TextLabel")
throwLabel.Size = UDim2.new(1, -10, 0, 18)
throwLabel.Position = UDim2.new(0, 5, 0, 26)
throwLabel.BackgroundTransparency = 1
throwLabel.Text = "Throws: 0"
throwLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
throwLabel.Font = Enum.Font.Gotham
throwLabel.TextSize = 11
throwLabel.Parent = frame

local countdownLabel = Instance.new("TextLabel")
countdownLabel.Size = UDim2.new(1, -10, 0, 18)
countdownLabel.Position = UDim2.new(0, 5, 0, 44)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text = "Wait " .. START_DELAY .. "s"
countdownLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
countdownLabel.Font = Enum.Font.Gotham
countdownLabel.TextSize = 11
countdownLabel.Parent = frame

local fbLabel = Instance.new("TextLabel")
fbLabel.Size = UDim2.new(1, -10, 0, 16)
fbLabel.Position = UDim2.new(0, 5, 0, 64)
fbLabel.BackgroundTransparency = 1
fbLabel.Text = "FB: --"
fbLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fbLabel.Font = Enum.Font.Code
fbLabel.TextSize = 10
fbLabel.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -10, 0, 16)
logLabel.Position = UDim2.new(0, 5, 0, 84)
logLabel.BackgroundTransparency = 1
logLabel.Text = ""
logLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 10
logLabel.Parent = frame

local function addLog(msg)
    logLabel.Text = msg
    pcall(function()
        appendfile("combo_log.txt", os.date("[%H:%M:%S] ") .. msg .. "\n")
    end)
end

local function updateGUI()
    statusLabel.Text = string.format(
        "Val: %d | Q: %s | #%d", lastValue, tostring(cachedQueue), ACCOUNT_ID)
    throwLabel.Text = "Throws: " .. totalThrows

    if comboLock then
        indicator.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        if coconutPresent then
            countdownLabel.Text = "WAITING COCONUT..."
        else
            countdownLabel.Text = "COMBO IN PROGRESS"
        end
    elseif skipping then
        indicator.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        countdownLabel.Text = "SKIPPING (no 39)"
    elseif cycleActive then
        indicator.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        countdownLabel.Text = "CYCLE ACTIVE"
    elseif cachedQueue == ACCOUNT_ID and coconutPresent then
        indicator.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        countdownLabel.Text = "WAITING COCONUT..."
    elseif cachedQueue == ACCOUNT_ID and lastValue == 39 then
        indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        countdownLabel.Text = "MY TURN — READY"
    elseif cachedQueue == ACCOUNT_ID then
        indicator.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
        countdownLabel.Text = "MY TURN (no 39)"
    elseif not canThrow then
        indicator.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        local remaining = math.max(0, START_DELAY - (tick() - startTime))
        countdownLabel.Text = "Wait " .. math.ceil(remaining) .. "s"
    else
        indicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        countdownLabel.Text = "Waiting (Q=" .. tostring(cachedQueue) .. ")"
    end

    fbLabel.Text = fbStatus
end

-- ====================== FIREBASE ======================
local function safeRequest(url, method, body)
    for attempt = 1, 3 do
        local ok, result = pcall(function()
            return request({
                Url = url,
                Method = method,
                Headers = method ~= "GET"
                    and {["Content-Type"] = "application/json"} or nil,
                Body = body
            })
        end)
        if ok and result and result.StatusCode == 200 and result.Body then
            fbStatus = "FB: OK"
            return result.Body
        end
        fbStatus = string.format("FB: ERR%d (code %s)",
            attempt, tostring(result and result.StatusCode or "?"))
        task.wait(attempt * 2)
    end
    fbStatus = "FB: FAIL"
    return nil
end

local function readQueue()
    local body = safeRequest(
        FIREBASE_URL .. FIREBASE_PATH .. "/comboQueue.json", "GET")
    if body and body ~= "null" then
        cachedQueue = tonumber(body) or 0
        lastQueueCheck = tick()
        return cachedQueue
    end
    return nil
end

local function writeQueue(value)
    local ok1 = safeRequest(
        FIREBASE_URL .. FIREBASE_PATH .. "/comboQueue.json",
        "PUT", tostring(value))
    safeRequest(
        FIREBASE_URL .. FIREBASE_PATH .. "/comboQueueLastUpdate.json",
        "PUT", tostring(os.time()))
    if ok1 then
        cachedQueue = value
        lastQueueCheck = tick()
    end
end

local function readLastUpdateTime()
    local body = safeRequest(
        FIREBASE_URL .. FIREBASE_PATH .. "/comboQueueLastUpdate.json", "GET")
    if body and body ~= "null" then
        return tonumber(body)
    end
    return nil
end

local function writeThrownBy(accountId)
    safeRequest(
        FIREBASE_URL .. FIREBASE_PATH .. "/comboThrownBy.json",
        "PUT", tostring(accountId))
    comboThrownBy = accountId
end

local function readThrownBy()
    local body = safeRequest(
        FIREBASE_URL .. FIREBASE_PATH .. "/comboThrownBy.json", "GET")
    if body and body ~= "null" then
        comboThrownBy = tonumber(body) or 0
        return comboThrownBy
    end
    return nil
end

local function getNextQueue()
    return (ACCOUNT_ID % TOTAL_ACCOUNTS) + 1
end

local function getPrevAccount()
    return (ACCOUNT_ID - 2 + TOTAL_ACCOUNTS) % TOTAL_ACCOUNTS + 1
end

-- ====================== ЭКИПИРОВКА ======================
local function isAccessoryEquipped(exactName)
    local char = LP.Character
    if not char then return false end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") and child.Name == exactName then
            return true
        end
    end
    return false
end

local function equipAccessory(itemType)
    local ok = pcall(function()
        ItemPackageEvent:InvokeServer("Equip", {
            Category = "Accessory",
            Type = itemType,
        })
    end)
    if ok then task.wait(0.5) end
    return ok
end

local function equipCanister()
    if isAccessoryEquipped("Coconut Canister") then hasCanister = true; return end
    if hasCanister then return end
    if tick() - lastEquipTime < 3 then return end
    lastEquipTime = tick()
    if equipAccessory("Coconut Canister") then
        hasCanister = isAccessoryEquipped("Coconut Canister")
        hasPorcelain = false
    end
end

local function equipPorcelain()
    if isAccessoryEquipped("Porcelain Port-O-Hive") then hasPorcelain = true; return end
    if hasPorcelain then return end
    if tick() - lastEquipTime < 3 then return end
    lastEquipTime = tick()
    if equipAccessory("Porcelain Port-O-Hive") then
        hasPorcelain = isAccessoryEquipped("Porcelain Port-O-Hive")
        hasCanister = false
    end
end

-- ====================== БРОСОК ======================
local function SpawnCoconut()
    PlayerActivesCommand:FireServer({Name = "Coconut"})
    totalThrows = totalThrows + 1
    updateGUI()
    addLog("THROW!")
end

-- ====================== ЦИКЛ ======================
local function startCycle(count)
    if cycleActive then return end
    cycleActive = true
    updateGUI()
    task.spawn(function()
        local ok, err = pcall(function()
            task.wait(CYCLE_DELAY)
            for i = 1, count do
                SpawnCoconut()
                if i < count then task.wait(COCONUT_INTERVAL) end
            end
        end)
        if not ok then addLog("Cycle err: " .. tostring(err)) end
        cycleActive = false
        updateGUI()
    end)
end

-- ====================== ПРОПУСК ХОДА ======================
local function skipTurn()
    if skipping then return end
    if comboLock then return end
    if not canThrow then return end
    if cachedQueue ~= ACCOUNT_ID then return end
    if coconutPresent then return end

    skipping = true
    updateGUI()
    addLog("No 39, skip in " .. SKIP_DELAY .. "s")

    task.spawn(function()
        task.wait(SKIP_DELAY)

        if lastValue == 39 then
            addLog("Skip aborted — got 39!")
            skipping = false
            updateGUI()
            return
        end

        if coconutPresent then
            addLog("Skip aborted — coconut appeared")
            skipping = false
            updateGUI()
            return
        end

        local current = readQueue()
        if current ~= ACCOUNT_ID then
            addLog("Skip aborted — queue moved")
            skipping = false
            updateGUI()
            return
        end

        local nextQ = getNextQueue()
        writeQueue(nextQ)
        coconutSeenWhileMyQueue = false
        addLog("No 39, skip → " .. nextQ)
        skipping = false
        updateGUI()
    end)
end

-- ====================== ОСНОВНОЕ КОМБО ======================
local function startCombo()
    if comboLock then return end
    if not canThrow then return end
    if lastValue ~= 39 then
        skipTurn()
        return
    end

    comboLock = true
    coconutSeenWhileMyQueue = false
    updateGUI()

    comboThread = task.spawn(function()
        local ok, err = pcall(function()

            -- Шаг 1: если сейчас в Particles есть кокос — ждём пока исчезнет
            if coconutPresent then
                addLog("Waiting coconut to disappear...")
                while coconutPresent do
                    task.wait(COCONUT_SCAN)
                end
                addLog("Coconut gone, starting timer")
            end

            -- Шаг 2: ждём COMBO_DELAY
            addLog("Timer " .. COMBO_DELAY .. "s")
            task.wait(COMBO_DELAY)

            -- Шаг 3: если во время таймера появился новый кокос — ждём пока исчезнет
            if coconutPresent then
                addLog("New coconut during timer, waiting...")
                while coconutPresent do
                    task.wait(COCONUT_SCAN)
                end
                addLog("Coconut gone, throwing now")
            end

            -- Шаг 4: перепроверяем value
            if lastValue ~= 39 then
                addLog("Abort: value changed → skip")
                writeQueue(getNextQueue())
                return
            end

            if cachedQueue ~= ACCOUNT_ID then
                addLog("Abort: queue changed")
                return
            end

            -- Шаг 5: бросаем
            local nextQ = getNextQueue()
            SpawnCoconut()
            writeThrownBy(ACCOUNT_ID)
            coconutSeenWhileMyQueue = false

            -- Передаём очередь сразу после броска
            writeQueue(nextQ)
            addLog("Queue → " .. nextQ)

            -- Цикл запускается параллельно
            startCycle(CYCLE_COUNT)
        end)

        if not ok then
            addLog("Combo err: " .. tostring(err))
            local current = readQueue()
            if current == ACCOUNT_ID then
                writeQueue(getNextQueue())
                addLog("Err fallback → " .. getNextQueue())
            end
        end

        comboLock = false
        comboThread = nil
        updateGUI()
    end)
end

-- ====================== ДЕТЕКТОР ComboCoconut ======================
task.spawn(function()
    while true do
        local present = false
        local particles = Workspace:FindFirstChild("Particles")
        if particles then
            present = particles:FindFirstChild("ComboCoconut", true) ~= nil
        end

        if present and not coconutPresent then
            -- Кокос появился
            coconutPresent = true
            if cachedQueue == ACCOUNT_ID then
                coconutSeenWhileMyQueue = true
                addLog("Coconut appeared — watching...")
            end
            updateGUI()

        elseif not present and coconutPresent then
            -- Кокос исчез
            coconutPresent = false
            addLog("Coconut gone")

            -- Запускаем комбо только если:
            -- 1. Наша очередь
            -- 2. Видели кокос пока была наша очередь
            -- 3. Нет активного комбо и цикла
            -- 4. Кокос был от предыдущего скрипт-аккаунта
            if cachedQueue == ACCOUNT_ID
                and coconutSeenWhileMyQueue
                and canThrow
                and not comboLock
                and not cycleActive
                and not skipping then

                local prevAcc = getPrevAccount()
                local thrownBy = readThrownBy()

                if thrownBy == prevAcc then
                    addLog("Trigger: script coconut gone → startCombo")
                    startCombo()
                else
                    addLog("Ignore: not script coconut (by=" .. tostring(thrownBy) .. ")")
                    coconutSeenWhileMyQueue = false
                end
            end

            updateGUI()
        end

        task.wait(COCONUT_SCAN)
    end
end)

-- ====================== ПОЛЛИНГ ОЧЕРЕДИ ======================
task.spawn(function()
    while not canThrow do
        task.wait(0.5)
    end

    while true do
        task.wait(QUEUE_POLL_INTERVAL)

        if canThrow and not comboLock and not skipping then
            readQueue()
            updateGUI()

            if cachedQueue == ACCOUNT_ID then
                if coconutPresent then
                    -- Кокос в воздухе — ждём, детектор сработает сам
                    coconutSeenWhileMyQueue = true
                    addLog("My turn, waiting coconut...")

                elseif coconutSeenWhileMyQueue then
                    -- Уже видели кокос и он исчез — детектор уже запустил комбо
                    -- Ничего не делаем

                else
                    -- Кокоса не было — прямой запуск
                    if lastValue == 39 then
                        addLog("No prev coconut, direct combo")
                        startCombo()
                    else
                        skipTurn()
                    end
                end
            end
        end
    end
end)

-- ====================== СЛУШАТЕЛЬ ======================
PlayerAbilityEvent.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    for tag, info in pairs(data) do
        if type(info) == "table"
            and (tag == "Combo Coconuts" or tag == "ComboCoconuts")
            and info.Action == "Update" then

            local value = info.Values and info.Values[1] or 0

            if not firstUpdateReceived then
                firstUpdateReceived = true
                lastValue = value
                lastValueChangeTime = tick()
                if value <= 34 then equipCanister() else equipPorcelain() end
                updateGUI()
                addLog("Init " .. value)
                return
            end

            if value ~= lastValue then
                lastValue = value
                lastValueChangeTime = tick()
                updateGUI()
                addLog(value .. (value <= 34 and " Can" or " Porc"))

                if value <= 34 then
                    equipCanister()
                else
                    equipPorcelain()
                end

                -- Если value упало во время таймера — отменяем
                if value < 39 and comboLock and comboThread then
                    pcall(task.cancel, comboThread)
                    comboThread = nil
                    comboLock = false
                    task.spawn(function()
                        local current = readQueue()
                        if current == ACCOUNT_ID then
                            writeQueue(getNextQueue())
                            addLog("Cancelled, queue → " .. getNextQueue())
                        end
                        coconutSeenWhileMyQueue = false
                        updateGUI()
                    end)
                end
            end
        end
    end
end)

-- ====================== ЗАДЕРЖКА СТАРТА ======================
task.spawn(function()
    while tick() - startTime < START_DELAY do
        if tick() - lastQueueCheck > 3 then readQueue() end
        updateGUI()
        task.wait(0.5)
    end

    local lastUpdate = readLastUpdateTime()
    if lastUpdate and (os.time() - lastUpdate) > 300 then
        writeQueue(1)
        addLog("Queue idle >5min, reset to 1")
    end

    readQueue()
    updateGUI()

    canThrow = true
    addLog("START")
end)

-- ====================== ВОТЧДОГ ======================
task.spawn(function()
    task.wait(math.random(0, 10))
    while true do
        task.wait(30)

        local lastUpdate = readLastUpdateTime()
        if lastUpdate and (os.time() - lastUpdate) > 180 then
            if ACCOUNT_ID == 1 then
                writeQueue(1)
                addLog("WD: queue dead, reset to 1")
            else
                addLog("WD: queue dead, wait #1")
            end
        end

        local char = LP.Character
        if not char
            or not char:FindFirstChild("Humanoid")
            or char.Humanoid.Health <= 0 then
            addLog("WD: char dead/missing")
        end

        updateGUI()
    end
end)

-- ====================== СТАРТ ======================
equipCanister()
readQueue()
updateGUI()
addLog("Wait " .. START_DELAY .. "s")
