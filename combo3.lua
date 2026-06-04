--[[
   ALT Combo Coconut Thrower (Firebase v6 - No Logs & Sync Time)
   Delta-совместим, Lua 5.1.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- ====================== НАСТРОЙКИ ======================
local FIREBASE_URL       = "https://fuflik1-e9325-default-rtdb.europe-west1.firebasedatabase.app"
local ACCOUNT_ID         = 3
local TOTAL_ACCOUNTS     = 3
local START_DELAY        = 10
local COMBO_DELAY        = 16
local CYCLE_COUNT        = 4
local CYCLE_DELAY        = 10
local COCONUT_INTERVAL   = 10
local QUEUE_POLL_INTERVAL = 1
local SKIP_DELAY         = 1
local COCONUT_SCAN       = 0.1
local CHAIN_TIMEOUT      = 60

local LP = Players.LocalPlayer

local Events               = ReplicatedStorage:WaitForChild("Events")
local PlayerAbilityEvent   = Events:WaitForChild("PlayerAbilityEvent")
local PlayerActivesCommand = Events:WaitForChild("PlayerActivesCommand")
local ItemPackageEvent     = Events:WaitForChild("ItemPackageEvent")

-- ====================== СОСТОЯНИЕ ======================
local lastValue               = -1
local lastValueChangeTime     = tick()
local hasCanister             = false
local hasPorcelain            = false
local comboThread             = nil
local totalThrows             = 0
local cycleActive             = false
local firstUpdateReceived     = false
local canThrow                = false
local startTime               = tick()
local skipping                = false
local comboLock               = false
local lastEquipTime           = 0
local comboThrownBy           = 0
local comboLockTime           = 0
local cycleStartTime          = 0
local skippingTime            = 0

local coconutPresent          = false
local coconutSeenWhileMyQueue = false

local comboTimerStart         = 0
local comboTimerDuration      = 0
local comboTimerActive        = false

local lastThrowTime           = os.time()
local chainWatchActive        = false

local guiMinimized            = false
local GUI_FULL_HEIGHT         = 165
local GUI_MINI_HEIGHT         = 20

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

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 24, 0, 24)
toggleBtn.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * (GUI_FULL_HEIGHT + 10))
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.Text = tostring(ACCOUNT_ID)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 12
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 10
toggleBtn.Parent = screenGui

local toggleIndicator = Instance.new("Frame")
toggleIndicator.Size = UDim2.new(0, 6, 0, 6)
toggleIndicator.Position = UDim2.new(1, -7, 0, 1)
toggleIndicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
toggleIndicator.BorderSizePixel = 0
toggleIndicator.ZIndex = 11
toggleIndicator.Parent = toggleBtn

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 230, 0, GUI_FULL_HEIGHT)
frame.Position = UDim2.new(0, 38, 0, 10 + (ACCOUNT_ID - 1) * (GUI_FULL_HEIGHT + 10))
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Visible = true
frame.Parent = screenGui

local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 8, 0, 8)
indicator.Position = UDim2.new(1, -12, 0, 6)
indicator.BorderSizePixel = 0
indicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
indicator.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -22, 0, 20)
statusLabel.Position = UDim2.new(0, 5, 0, 3)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local throwLabel = Instance.new("TextLabel")
throwLabel.Size = UDim2.new(1, -10, 0, 16)
throwLabel.Position = UDim2.new(0, 5, 0, 24)
throwLabel.BackgroundTransparency = 1
throwLabel.Text = "Throws: 0"
throwLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
throwLabel.Font = Enum.Font.Gotham
throwLabel.TextSize = 10
throwLabel.TextXAlignment = Enum.TextXAlignment.Left
throwLabel.Parent = frame

local countdownLabel = Instance.new("TextLabel")
countdownLabel.Size = UDim2.new(1, -10, 0, 16)
countdownLabel.Position = UDim2.new(0, 5, 0, 41)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text = "Wait " .. START_DELAY .. "s"
countdownLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
countdownLabel.Font = Enum.Font.Gotham
countdownLabel.TextSize = 10
countdownLabel.TextXAlignment = Enum.TextXAlignment.Left
countdownLabel.Parent = frame

local timerBarBg = Instance.new("Frame")
timerBarBg.Size = UDim2.new(1, -10, 0, 7)
timerBarBg.Position = UDim2.new(0, 5, 0, 59)
timerBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
timerBarBg.BorderSizePixel = 0
timerBarBg.Visible = false
timerBarBg.Parent = frame

local timerBarFill = Instance.new("Frame")
timerBarFill.Size = UDim2.new(1, 0, 1, 0)
timerBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
timerBarFill.BorderSizePixel = 0
timerBarFill.Parent = timerBarBg

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, -10, 0, 14)
timerLabel.Position = UDim2.new(0, 5, 0, 68)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = ""
timerLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
timerLabel.Font = Enum.Font.Code
timerLabel.TextSize = 9
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.Visible = false
timerLabel.Parent = frame

local fbLabel = Instance.new("TextLabel")
fbLabel.Size = UDim2.new(1, -10, 0, 14)
fbLabel.Position = UDim2.new(0, 5, 0, 84)
fbLabel.BackgroundTransparency = 1
fbLabel.Text = "FB: --"
fbLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fbLabel.Font = Enum.Font.Code
fbLabel.TextSize = 9
fbLabel.TextXAlignment = Enum.TextXAlignment.Left
fbLabel.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -10, 0, 14)
logLabel.Position = UDim2.new(0, 5, 0, 100)
logLabel.BackgroundTransparency = 1
logLabel.Text = ""
logLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 9
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.Parent = frame

local btnReset = Instance.new("TextButton")
btnReset.Size = UDim2.new(0, 100, 0, 20)
btnReset.Position = UDim2.new(0, 5, 0, 120)
btnReset.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
btnReset.Text = "Reset Q→1"
btnReset.TextColor3 = Color3.fromRGB(255, 255, 255)
btnReset.Font = Enum.Font.Gotham
btnReset.TextSize = 10
btnReset.BorderSizePixel = 0
btnReset.Parent = frame

local btnForce = Instance.new("TextButton")
btnForce.Size = UDim2.new(0, 100, 0, 20)
btnForce.Position = UDim2.new(0, 120, 0, 120)
btnForce.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
btnForce.Text = "Force Me"
btnForce.TextColor3 = Color3.fromRGB(255, 255, 255)
btnForce.Font = Enum.Font.Gotham
btnForce.TextSize = 10
btnForce.BorderSizePixel = 0
btnForce.Parent = frame

-- ====================== ЛОГИРОВАНИЕ (БЕЗ ФАЙЛОВ) ======================
local function addLog(msg)
    logLabel.Text = msg
end

local function setIndicatorColor(color)
    indicator.BackgroundColor3 = color
    toggleIndicator.BackgroundColor3 = color
end

local function updateGUI()
    statusLabel.Text = string.format(
        "Val:%d | Q:%s | #%d",
        lastValue, tostring(cachedQueue), ACCOUNT_ID)
    throwLabel.Text = "Throws: " .. totalThrows
    fbLabel.Text = fbStatus

    local isMyQueue = (cachedQueue == ACCOUNT_ID)

    if comboLock then
        setIndicatorColor(Color3.fromRGB(255, 200, 0))
        if coconutPresent then
            countdownLabel.Text = "WAITING COCONUT..."
        elseif comboTimerActive then
            local remaining = math.max(0, comboTimerDuration - (tick() - comboTimerStart))
            countdownLabel.Text = string.format("COMBO: %.0fs", remaining)
        else
            countdownLabel.Text = "COMBO IN PROGRESS"
        end
    elseif chainWatchActive then
        setIndicatorColor(Color3.fromRGB(255, 50, 50))
        countdownLabel.Text = "CHAIN DEAD — RECOVERING"
    elseif skipping then
        setIndicatorColor(Color3.fromRGB(255, 100, 0))
        countdownLabel.Text = "SKIPPING (no 39)"
    elseif cycleActive then
        setIndicatorColor(Color3.fromRGB(0, 150, 255))
        countdownLabel.Text = "CYCLE ACTIVE"
    elseif isMyQueue and coconutPresent then
        setIndicatorColor(Color3.fromRGB(255, 200, 0))
        countdownLabel.Text = "WAITING COCONUT..."
    elseif isMyQueue and lastValue == 39 then
        setIndicatorColor(Color3.fromRGB(0, 255, 0))
        countdownLabel.Text = "MY TURN — READY"
    elseif isMyQueue then
        setIndicatorColor(Color3.fromRGB(255, 150, 0))
        countdownLabel.Text = "MY TURN (no 39)"
    elseif not canThrow then
        setIndicatorColor(Color3.fromRGB(150, 150, 150))
        local remaining = math.max(0, START_DELAY - (tick() - startTime))
        countdownLabel.Text = "Wait " .. math.ceil(remaining) .. "s"
    else
        setIndicatorColor(Color3.fromRGB(100, 100, 100))
        countdownLabel.Text = "Waiting (Q=" .. tostring(cachedQueue) .. ")"
    end
end

-- ====================== ТАЙМЕР В GUI ======================
local function startGuiTimer(duration)
    comboTimerStart    = tick()
    comboTimerDuration = duration
    comboTimerActive   = true
    if not guiMinimized then
        timerBarBg.Visible = true
        timerLabel.Visible = true
    end
end

local function stopGuiTimer()
    comboTimerActive   = false
    timerBarBg.Visible = false
    timerLabel.Visible = false
    timerBarFill.Size  = UDim2.new(1, 0, 1, 0)
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if comboTimerActive and comboTimerDuration > 0 then
            local elapsed   = tick() - comboTimerStart
            local remaining = math.max(0, comboTimerDuration - elapsed)
            local progress  = math.max(0, math.min(1, 1 - elapsed / comboTimerDuration))

            timerBarFill.Size = UDim2.new(progress, 0, 1, 0)

            if progress > 0.5 then
                timerBarFill.BackgroundColor3 = Color3.fromRGB(math.floor((1 - progress) * 2 * 255), 200, 0)
            else
                timerBarFill.BackgroundColor3 = Color3.fromRGB(255, math.floor(progress * 2 * 200), 0)
            end

            local bars = math.floor(progress * 18)
            timerLabel.Text = string.format("[%s%s] %.0fs", string.rep("█", bars), string.rep("░", 18 - bars), remaining)

            if not guiMinimized then updateGUI() end
        end
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    guiMinimized = not guiMinimized
    frame.Visible = not guiMinimized
    if guiMinimized then
        toggleBtn.Text = tostring(ACCOUNT_ID)
    else
        toggleBtn.Text = "×"
        timerBarBg.Visible = comboTimerActive
        timerLabel.Visible = comboTimerActive
        updateGUI()
    end
end)
toggleBtn.Text = "×"

-- ====================== FIREBASE (С СЕРВЕРНЫМ ВРЕМЕНЕМ) ======================
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
        if ok and result and result.StatusCode == 200 and result.Body then
            fbStatus = "FB: OK"
            return result.Body
        end
        fbStatus = string.format("FB: ERR%d (code %s)", attempt, tostring(result and result.StatusCode or "?"))
        task.wait(attempt * 2)
    end
    fbStatus = "FB: FAIL"
    return nil
end

local function readQueue()
    local body = safeRequest(FIREBASE_URL .. "/comboQueue.json", "GET")
    if body and body ~= "null" then
        cachedQueue    = tonumber(body) or 0
        lastQueueCheck = tick()
        return cachedQueue
    end
    return nil
end

local function writeQueue(value)
    local ok1 = safeRequest(FIREBASE_URL .. "/comboQueue.json", "PUT", tostring(value))
    -- Используем серверное время Firebase
    safeRequest(FIREBASE_URL .. "/comboQueueLastUpdate.json", "PUT", '{"sv": "timestamp"}')
    if ok1 then
        cachedQueue    = value
        lastQueueCheck = tick()
    end
end

local function readLastUpdateTime()
    local body = safeRequest(FIREBASE_URL .. "/comboQueueLastUpdate.json", "GET")
    if body and body ~= "null" then 
        local ms = tonumber(body)
        return ms and math.floor(ms / 1000) or nil -- Конвертируем миллисекунды в секунды
    end
    return nil
end

local function writeThrownBy(accountId)
    safeRequest(FIREBASE_URL .. "/comboThrownBy.json", "PUT", tostring(accountId))
    comboThrownBy = accountId
end

local function readThrownBy()
    local body = safeRequest(FIREBASE_URL .. "/comboThrownBy.json", "GET")
    if body and body ~= "null" then
        comboThrownBy = tonumber(body) or 0
        return comboThrownBy
    end
    return nil
end

local function writeLastThrowTime()
    -- Используем серверное время Firebase
    safeRequest(FIREBASE_URL .. "/lastThrowTime.json", "PUT", '{"sv": "timestamp"}')
    lastThrowTime = os.time() -- Локальный фоллбек до следующего чтения
end

local function readLastThrowTime()
    local body = safeRequest(FIREBASE_URL .. "/lastThrowTime.json", "GET")
    if body and body ~= "null" then 
        local ms = tonumber(body)
        return ms and math.floor(ms / 1000) or 0 -- Конвертируем миллисекунды в секунды
    end
    return 0
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
        if child:IsA("Accessory") and child.Name == exactName then return true end
    end
    return false
end

local function equipAccessory(itemType)
    local ok = pcall(function()
        ItemPackageEvent:InvokeServer("Equip", { Category = "Accessory", Type = itemType })
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
        hasCanister  = isAccessoryEquipped("Coconut Canister")
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
        hasCanister  = false
    end
end

-- ====================== БРОСОК ======================
local function SpawnCoconut()
    pcall(function()
        PlayerActivesCommand:FireServer({Name = "Coconut"})
    end)
    totalThrows = totalThrows + 1
    lastThrowTime = os.time()
    writeLastThrowTime()
    updateGUI()
    addLog("THROW!")
end

-- ====================== ЦИКЛ ======================
local function startCycle(count)
    if cycleActive then return end
    cycleActive    = true
    cycleStartTime = tick()
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
        cycleActive    = false
        cycleStartTime = 0
        updateGUI()
    end)
end

-- ====================== ПРОПУСК ХОДА ======================
local function skipTurn()
    if skipping or comboLock or not canThrow or cachedQueue ~= ACCOUNT_ID or coconutPresent then return end

    skipping     = true
    skippingTime = tick()
    updateGUI()
    addLog("No 39, skip in " .. SKIP_DELAY .. "s")

    task.spawn(function()
        task.wait(SKIP_DELAY)
        if lastValue == 39 or coconutPresent then
            addLog("Skip aborted")
            skipping, skippingTime = false, 0
            updateGUI()
            return
        end

        local current = readQueue()
        if current ~= ACCOUNT_ID then
            addLog("Skip aborted — queue moved")
            skipping, skippingTime = false, 0
            updateGUI()
            return
        end

        local nextQ = getNextQueue()
        writeQueue(nextQ)
        coconutSeenWhileMyQueue = false
        addLog("No 39, skip → " .. nextQ)
        skipping, skippingTime = false, 0
        updateGUI()
    end)
end

-- ====================== ОСНОВНОЕ КОМБО ======================
local function startCombo()
    if comboLock or not canThrow then return end
    if lastValue ~= 39 then skipTurn(); return end

    comboLock     = true
    comboLockTime = tick()
    coconutSeenWhileMyQueue = false
    updateGUI()

    comboThread = task.spawn(function()
        local ok, err = pcall(function()
            if coconutPresent then
                addLog("Waiting coconut to disappear...")
                while coconutPresent do task.wait(COCONUT_SCAN) end
                addLog("Coconut gone, starting timer")
            end

            startGuiTimer(COMBO_DELAY)
            addLog("Timer " .. COMBO_DELAY .. "s")
            task.wait(COMBO_DELAY)
            stopGuiTimer()

            if coconutPresent then
                addLog("New coconut during timer, waiting...")
                while coconutPresent do task.wait(COCONUT_SCAN) end
                addLog("Coconut gone, throwing now")
            end

            if lastValue ~= 39 then
                addLog("Abort: value changed → pass queue")
                writeQueue(getNextQueue())
                return
            end

            if cachedQueue ~= ACCOUNT_ID then
                addLog("Abort: queue changed")
                return
            end

            local nextQ = getNextQueue()
            SpawnCoconut()
            writeThrownBy(ACCOUNT_ID)
            coconutSeenWhileMyQueue = false
            writeQueue(nextQ)
            addLog("Queue → " .. nextQ)
            startCycle(CYCLE_COUNT)
        end)

        stopGuiTimer()

        if not ok then
            addLog("Combo err: " .. tostring(err))
            local current = readQueue()
            if current == ACCOUNT_ID then
                writeQueue(getNextQueue())
                addLog("Err fallback → " .. getNextQueue())
            end
        end

        comboLock     = false
        comboLockTime = 0
        comboThread   = nil
        updateGUI()
    end)
end

-- ====================== ДЕТЕКТОР ComboCoconut ======================
task.spawn(function()
    while true do
        local present = false
        local particles = Workspace:FindFirstChild("Particles")
        if particles then present = particles:FindFirstChild("ComboCoconut", true) ~= nil end

        if present and not coconutPresent then
            coconutPresent = true
            if cachedQueue == ACCOUNT_ID then
                coconutSeenWhileMyQueue = true
                addLog("Coconut appeared — watching...")
            end
            updateGUI()
        elseif not present and coconutPresent then
            coconutPresent = false
            addLog("Coconut gone")

            if cachedQueue == ACCOUNT_ID and coconutSeenWhileMyQueue and canThrow and not comboLock and not cycleActive and not skipping then
                local prevAcc  = getPrevAccount()
                local thrownBy = readThrownBy()

                if thrownBy == prevAcc then
                    addLog("Trigger: script coconut → startCombo")
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
    while not canThrow do task.wait(0.5) end
    while true do
        task.wait(QUEUE_POLL_INTERVAL)
        if canThrow and not comboLock and not skipping then
            readQueue()
            updateGUI()
            if cachedQueue == ACCOUNT_ID then
                if coconutPresent then
                    coconutSeenWhileMyQueue = true
                    addLog("My turn, waiting coconut...")
                elseif coconutSeenWhileMyQueue then
                    -- детектор уже запустит комбо
                else
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
        if type(info) == "table" and (tag == "Combo Coconuts" or tag == "ComboCoconuts") and info.Action == "Update" then
            local value = info.Values and info.Values[1] or 0

            if not firstUpdateReceived then
                firstUpdateReceived = true
                lastValue           = value
                lastValueChangeTime = tick()
                if value <= 34 then equipCanister() else equipPorcelain() end
                updateGUI()
                addLog("Init " .. value)
                return
            end

            if value ~= lastValue then
                lastValue           = value
                lastValueChangeTime = tick()
                updateGUI()
                addLog(value .. (value <= 34 and " Can" or " Porc"))

                if value <= 34 then equipCanister() else equipPorcelain() end

                if value < 39 and comboLock and comboThread then
                    pcall(task.cancel, comboThread)
                    stopGuiTimer()
                    comboThread   = nil
                    comboLock     = false
                    comboLockTime = 0
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
    local startJitter = (ACCOUNT_ID - 1) * 3
    task.wait(startJitter)

    while tick() - startTime < START_DELAY do
        if tick() - lastQueueCheck > 3 then readQueue() end
        updateGUI()
        task.wait(0.5)
    end

    task.wait((ACCOUNT_ID - 1) * 1.5)
    readQueue()

    local lastUpdate = readLastUpdateTime()
    if lastUpdate and (os.time() - lastUpdate) > 300 then
        if ACCOUNT_ID == 1 then
            writeQueue(1)
            addLog("Queue idle >5min, reset to 1")
        end
    end

    local fbLastThrow = readLastThrowTime()
    if fbLastThrow and fbLastThrow > 0 then lastThrowTime = fbLastThrow end

    canThrow = true
    addLog("START (jitter=" .. startJitter .. "s)")
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

        if comboLock and comboLockTime > 0 and (tick() - comboLockTime) > 300 then
            addLog("WD: comboLock stuck, reset")
            if comboThread then pcall(task.cancel, comboThread); comboThread = nil end
            stopGuiTimer()
            comboLock, comboLockTime = false, 0
            task.spawn(function()
                local current = readQueue()
                if current == ACCOUNT_ID then writeQueue(getNextQueue()); addLog("WD: queue released → " .. getNextQueue()) end
                updateGUI()
            end)
        end

        local maxCycleTime = CYCLE_DELAY + (CYCLE_COUNT * COCONUT_INTERVAL) * 2
        if cycleActive and cycleStartTime > 0 and (tick() - cycleStartTime) > maxCycleTime then
            addLog("WD: cycleActive stuck, reset")
            cycleActive, cycleStartTime = false, 0
            updateGUI()
        end

        if skipping and skippingTime > 0 and (tick() - skippingTime) > 30 then
            addLog("WD: skipping stuck, reset")
            skipping, skippingTime = false, 0
            updateGUI()
        end

        local char = LP.Character
        if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            addLog("WD: char dead/missing")
            comboLock, cycleActive, skipping = false, false, false
            stopGuiTimer()
            updateGUI()
        end
        updateGUI()
    end
end)

-- ====================== ДЕТЕКТОР ЗАВИСАНИЯ ЦЕПОЧКИ ======================
task.spawn(function()
    while not canThrow do task.wait(1) end
    task.wait(15)

    while true do
        task.wait(10)
        if not canThrow then break end

        local fbLastThrow = readLastThrowTime()
        if fbLastThrow and fbLastThrow > 0 then lastThrowTime = math.max(lastThrowTime, fbLastThrow) end

        local timeSinceThrow = os.time() - lastThrowTime

        if timeSinceThrow > CHAIN_TIMEOUT and not comboLock and not cycleActive and not skipping and not chainWatchActive and cachedQueue == ACCOUNT_ID and lastValue == 39 then
            chainWatchActive = true
            updateGUI()
            addLog("Chain dead " .. timeSinceThrow .. "s — recovering")

            task.spawn(function()
                if not coconutPresent then
                    addLog("Chain: waiting for coconut (30s max)...")
                    local waitStart = tick()
                    while not coconutPresent and tick() - waitStart < 30 do task.wait(COCONUT_SCAN) end
                end

                if coconutPresent then
                    addLog("Chain: waiting coconut to disappear...")
                    while coconutPresent do task.wait(COCONUT_SCAN) end
                    addLog("Chain: coconut gone → startCombo")
                else
                    addLog("Chain: no coconut → direct combo")
                end

                chainWatchActive = false

                if canThrow and not comboLock and not cycleActive and cachedQueue == ACCOUNT_ID and lastValue == 39 then
                    coconutSeenWhileMyQueue = false
                    startCombo()
                else
                    addLog("Chain: conditions changed, abort")
                    updateGUI()
                end
            end)
        end
    end
end)

-- ====================== ОЧИСТКА ПАМЯТИ (GC) ======================
task.spawn(function()
    while true do
        task.wait(600) -- Каждые 10 минут
        local before = gcinfo()
        collectgarbage("collect")
        local after = gcinfo()
        addLog(string.format("GC: Freed %d KB", before - after))
    end
end)

-- ====================== КНОПКИ ======================
btnReset.MouseButton1Click:Connect(function()
    writeQueue(1)
    comboLock, cycleActive, skipping, chainWatchActive, coconutSeenWhileMyQueue = false, false, false, false, false
    if comboThread then pcall(task.cancel, comboThread); comboThread = nil end
    stopGuiTimer()
    addLog("Manual: reset Q=1")
    updateGUI()
end)

btnForce.MouseButton1Click:Connect(function()
    writeQueue(ACCOUNT_ID)
    addLog("Manual: force Q=" .. ACCOUNT_ID)
    updateGUI()
end)

-- ====================== СТАРТ ======================
equipCanister()
readQueue()
updateGUI()
addLog("Wait " .. START_DELAY .. "s")
