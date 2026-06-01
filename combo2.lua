--[[
   ALT Combo Coconut Thrower (FINAL v9)
   Delta Executor, Lua 5.1
   Автопропуск хода если нет 39.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- ====================== НАСТРОЙКИ ======================
local FIREBASE_URL = "https://fuflik1-e9325-default-rtdb.europe-west1.firebasedatabase.app"
local FIREBASE_PATH = ""
local ACCOUNT_ID = 2
local TOTAL_ACCOUNTS = 2
local COMBO_DELAY = 16
local CYCLE_COUNT = 4
local CYCLE_DELAY = 10
local COCONUT_INTERVAL = 10
local START_DELAY = 10
local QUEUE_POLL_INTERVAL = 1   -- как часто проверяем очередь
local SKIP_DELAY = 1            -- задержка перед пропуском (антиспам Firebase)

local LP = Players.LocalPlayer

local Events = ReplicatedStorage:WaitForChild("Events")
local PlayerAbilityEvent = Events:WaitForChild("PlayerAbilityEvent")
local PlayerActivesCommand = Events:WaitForChild("PlayerActivesCommand")
local ItemPackageEvent = Events:WaitForChild("ItemPackageEvent")

-- ====================== СОСТОЯНИЕ ======================
local lastValue = -1
local lastValueChangeTime = os.time()
local hasCanister = false
local hasPorcelain = false
local totalThrows = 0
local cycleActive = false
local canThrow = false
local startTime = os.time()
local comboLock = false
local comboThread = nil
local fbStatus = "FB: --"
local skipping = false          -- защита от двойного пропуска

local cachedQueue = 0
local lastQueueCheck = 0
local lastEquipTime = 0

-- ====================== GUI ======================
local playerGui = LP:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("ComboThrower_" .. ACCOUNT_ID)
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboThrower_" .. ACCOUNT_ID
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 110)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * 120)
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
statusLabel.Text = "Val: - | Q: ? | #" .. ACCOUNT_ID
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
fbLabel.Position = UDim2.new(0, 5, 0, 62)
fbLabel.BackgroundTransparency = 1
fbLabel.Text = "FB: --"
fbLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fbLabel.Font = Enum.Font.Code
fbLabel.TextSize = 10
fbLabel.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -10, 0, 16)
logLabel.Position = UDim2.new(0, 5, 0, 82)
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

    local isMyQueue = (cachedQueue == ACCOUNT_ID or cachedQueue == -ACCOUNT_ID)

    if comboLock then
        indicator.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        countdownLabel.Text = "COMBO IN PROGRESS"
    elseif skipping then
        indicator.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        countdownLabel.Text = "SKIPPING (no 39)"
    elseif cycleActive then
        indicator.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        countdownLabel.Text = "CYCLE ACTIVE"
    elseif isMyQueue and lastValue == 39 then
        indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        countdownLabel.Text = "MY TURN — READY"
    elseif not canThrow then
        indicator.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        local remaining = math.max(0, START_DELAY - (os.time() - startTime))
        countdownLabel.Text = "Wait " .. math.ceil(remaining) .. "s"
    else
        indicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        if type(cachedQueue) == "number" and cachedQueue < 0 then
            countdownLabel.Text = "Busy (acct " .. tostring(math.abs(cachedQueue)) .. " combo)"
        else
            countdownLabel.Text = "Waiting (Q=" .. tostring(cachedQueue) .. ")"
        end
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
        lastQueueCheck = os.time()
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
        lastQueueCheck = os.time()
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

-- ========== CLAIM — токен для защиты от гонки ==========
local function writeClaim(token)
    local body
    if type(token) == "string" then
        body = '"' .. token .. '"'
    else
        body = tostring(token)
    end
    safeRequest(
        FIREBASE_URL .. FIREBASE_PATH .. "/comboClaim.json",
        "PUT", body)
end

local function readClaim()
    local body = safeRequest(
        FIREBASE_URL .. FIREBASE_PATH .. "/comboClaim.json", "GET")
    if body and body ~= "null" then
        return body:gsub('"', '')
    end
    return nil
end

local function tryAcquireQueue()
    local current = readQueue()
    if current ~= ACCOUNT_ID then return false end

    local token = ACCOUNT_ID .. "-" .. tostring(math.floor(tick() * 1000) % 1000000)
    writeClaim(token)
    task.wait(2)

    local verify = readClaim()
    if verify == token then
        writeQueue(-ACCOUNT_ID)
        addLog("Acquired (token OK)")
        return true
    end

    addLog("Token conflict: " .. token .. " vs " .. tostring(verify))
    return false
end

local function getNextQueue()
    return (ACCOUNT_ID % TOTAL_ACCOUNTS) + 1
end

-- ====================== ПРОПУСК ХОДА ======================
local function skipTurn()
    if skipping then return end
    if comboLock then return end

    skipping = true
    updateGUI()

    task.spawn(function()
        task.wait(SKIP_DELAY)

        -- Перепроверяем — может за секунду значение стало 39
        if lastValue == 39 then
            addLog("Skip aborted — got 39!")
            skipping = false
            updateGUI()
            return
        end

        -- Перечитываем очередь — вдруг кто-то уже передал
        local current = readQueue()
        if current ~= ACCOUNT_ID then
            addLog("Skip aborted — not my turn anymore")
            skipping = false
            updateGUI()
            return
        end

        local nextQ = getNextQueue()
        writeQueue(nextQ)
        addLog("No 39, skip → " .. nextQ)
        skipping = false
        updateGUI()
    end)
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
        local args = {"Equip", {Category = "Accessory", Type = itemType}}
        if ItemPackageEvent:IsA("RemoteFunction") then
            ItemPackageEvent:InvokeServer(unpack(args))
        else
            ItemPackageEvent:FireServer(unpack(args))
        end
    end)
    if ok then task.wait(0.5) end
    return ok
end

local function equipCanister()
    if isAccessoryEquipped("Coconut Canister") then
        hasCanister = true
        return
    end
    if hasCanister then return end
    if os.time() - lastEquipTime < 3 then return end
    lastEquipTime = os.time()
    if equipAccessory("Coconut Canister") then
        hasCanister = isAccessoryEquipped("Coconut Canister")
        hasPorcelain = false
    end
end

local function equipPorcelain()
    if isAccessoryEquipped("Porcelain Port-O-Hive") then
        hasPorcelain = true
        return
    end
    if hasPorcelain then return end
    if os.time() - lastEquipTime < 3 then return end
    lastEquipTime = os.time()
    if equipAccessory("Porcelain Port-O-Hive") then
        hasPorcelain = isAccessoryEquipped("Porcelain Port-O-Hive")
        hasCanister = false
    end
end

-- ====================== ПРОВЕРКА КОКОСА ======================
local function hasComboCoconut()
    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return false end
    return particles:FindFirstChild("ComboCoconut", true) ~= nil
end

-- ====================== БРОСОК ======================
local function SpawnCoconut()
    local formats = {
        {fn = function() PlayerActivesCommand:FireServer({Name = "Coconut"}) end,                  waitTime = 5},
        {fn = function() PlayerActivesCommand:FireServer("Coconut") end,                           waitTime = 3},
        {fn = function() PlayerActivesCommand:FireServer({Name = "Coconut", Type = "Active"}) end, waitTime = 3},
    }

    for attempt, fmt in ipairs(formats) do
        pcall(fmt.fn)
        local start = tick()
        while tick() - start < fmt.waitTime do
            if hasComboCoconut() then
                totalThrows = totalThrows + 1
                updateGUI()
                addLog("THROW OK (fmt " .. attempt .. ")")
                return true
            end
            task.wait(0.15)
        end
        addLog("Fmt " .. attempt .. " no coconut, next")
    end

    addLog("ALL FORMATS FAILED")
    return false
end

-- ====================== ЦИКЛ БРОСКОВ ======================
local function startCycle(count)
    if cycleActive then return end
    cycleActive = true
    task.spawn(function()
        local ok, err = pcall(function()
            task.wait(CYCLE_DELAY)
            for i = 1, count do
                SpawnCoconut()
                if i < count then task.wait(COCONUT_INTERVAL) end
            end
        end)
        if not ok then addLog("Cycle error: " .. tostring(err)) end
        cycleActive = false
    end)
end

-- ====================== ОСНОВНАЯ ЛОГИКА ======================
local function tryCombo()
    if not canThrow then return end
    if lastValue ~= 39 then return end
    if comboLock or cycleActive or skipping then return end

    comboLock = true
    updateGUI()

    comboThread = task.spawn(function()
        local ok, err = pcall(function()
            if not tryAcquireQueue() then
                addLog("Queue conflict, skipping")
                return
            end

            if cachedQueue ~= -ACCOUNT_ID then
                addLog("Queue stolen after acquire")
                return
            end

            updateGUI()
            task.wait(COMBO_DELAY)

            if lastValue ~= 39 then
                addLog("Abort: value changed during delay")
                writeQueue(getNextQueue())
                return
            end

            local finalQueue = readQueue()
            if finalQueue ~= -ACCOUNT_ID then
                addLog("Abort: queue stolen during delay")
                return
            end

            local nextQueue = getNextQueue()
            local success = SpawnCoconut()
            if success then
                startCycle(CYCLE_COUNT)
            end
            writeQueue(nextQueue)
            addLog((success and "Queue → " or "Fail, queue → ") .. nextQueue)
        end)

        if not ok then addLog("ComboErr: " .. tostring(err)) end

        comboLock = false
        comboThread = nil
        updateGUI()
    end)
end

-- ====================== СЛУШАТЕЛЬ ======================
PlayerAbilityEvent.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    for tag, info in pairs(data) do
        if type(info) == "table"
            and (tag == "Combo Coconuts" or tag == "ComboCoconuts")
            and info.Action == "Update" then

            local value = info.Values and info.Values[1] or 0
            if value ~= lastValue then
                lastValue = value
                lastValueChangeTime = os.time()
                if os.time() - lastQueueCheck > 3 then readQueue() end
                updateGUI()
                addLog(value .. (value <= 34 and " Can" or " Porc"))

                if value <= 34 then
                    equipCanister()
                else
                    equipPorcelain()
                end

                if value == 39 then
                    -- Получили 39 — если наш ход, запускаем комбо
                    if cachedQueue == ACCOUNT_ID then
                        tryCombo()
                    end
                elseif value < 39 and comboLock then
                    -- Значение упало — отменяем комбо
                    if comboThread then
                        pcall(task.cancel, comboThread)
                        comboThread = nil
                    end
                    comboLock = false

                    task.spawn(function()
                        local current = readQueue()
                        if current == -ACCOUNT_ID then
                            writeQueue(ACCOUNT_ID)
                            addLog("Combo canceled, queue restored → " .. ACCOUNT_ID)
                        else
                            addLog("Combo canceled (queue clean)")
                        end
                        updateGUI()
                    end)
                end
            end
        end
    end
end)

-- ====================== ПОЛЛИНГ ОЧЕРЕДИ ======================
-- Главный цикл: проверяем очередь и решаем — комбо или пропуск
task.spawn(function()
    -- Ждём окончания START_DELAY
    while not canThrow do
        task.wait(0.5)
    end

    while true do
        task.wait(QUEUE_POLL_INTERVAL)

        if not comboLock and not cycleActive and not skipping and canThrow then
            readQueue()
            updateGUI()

            if cachedQueue == ACCOUNT_ID then
                if lastValue == 39 then
                    -- Наш ход + есть 39 → комбо
                    tryCombo()
                else
                    -- Наш ход + нет 39 → пропускаем
                    skipTurn()
                end
            end
        end
    end
end)

-- ====================== ЗАДЕРЖКА СТАРТА ======================
task.spawn(function()
    while os.time() - startTime < START_DELAY do
        if os.time() - lastQueueCheck > 3 then readQueue() end
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

        -- Мёртвая очередь — только аккаунт 1 ресетит
        local lastUpdate = readLastUpdateTime()
        if lastUpdate and (os.time() - lastUpdate) > 180 then
            if ACCOUNT_ID == 1 then
                writeQueue(1)
                addLog("WD: queue dead >3min, reset to 1")
            else
                addLog("WD: queue dead, waiting for #1 reset")
            end
        end

        -- Застрявший отрицательный ID
        if cachedQueue == -ACCOUNT_ID
            and not comboLock
            and not cycleActive then
            writeQueue(ACCOUNT_ID)
            addLog("WD: restored stuck -ID → " .. ACCOUNT_ID)
        end

        -- Проверка персонажа
        local char = LP.Character
        if not char
            or not char:FindFirstChild("Humanoid")
            or char.Humanoid.Health <= 0 then
            addLog("WD: character dead/missing")
        end

        updateGUI()
    end
end)

-- ====================== СТАРТ ======================
equipCanister()
readQueue()
updateGUI()
addLog("Wait " .. START_DELAY .. "s")
