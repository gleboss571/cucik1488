--[[
   ALT Combo Coconut Thrower (Firebase v7 - Compact GUI)
   Delta-совместим, Lua 5.1.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

-- ====================== НАСТРОЙКИ ======================
local FIREBASE_URL        = "https://fuflik1-e9325-default-rtdb.europe-west1.firebasedatabase.app"
local ACCOUNT_ID          = 2
local TOTAL_ACCOUNTS      = 2
local START_DELAY         = 10
local COMBO_DELAY         = 18
local CYCLE_COUNT         = 4
local CYCLE_DELAY         = 10
local COCONUT_INTERVAL    = 10
local QUEUE_POLL_INTERVAL = 1
local SKIP_DELAY          = 0.2
local COCONUT_SCAN        = 0.1
local CHAIN_TIMEOUT       = 120
local VALUE_HISTORY_SIZE  = 20
local PREDICT_MIN_POINTS  = 4
local PREDICT_MAX_NEEDED  = 25

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
local comboStarting           = false
local lastEquipTime           = 0
local comboThrownBy           = 0
local comboLockTime           = 0
local cycleStartTime          = 0
local skippingTime            = 0
local ourCycleActive          = false

local coconutPresent          = false
local coconutSeenWhileMyQueue = false
local waitingCoconutGone      = false

local comboTimerStart         = 0
local comboTimerDuration      = 0
local comboTimerActive        = false

local lastThrowTime           = os.time()
local chainWatchActive        = false

local guiMinimized            = false

local ACC_ROW_H  = 13
local GUI_W      = 195
local GUI_H      = 155 + TOTAL_ACCOUNTS * ACC_ROW_H

local cachedQueue    = 0
local lastQueueCheck = 0
local fbStatus       = "FB: --"

local serverTimeDelta = 0
local isPaused        = false

local valueHistory     = {}
local lastWrittenValue = -1

local logLines = {"", "", ""}

local fbWriteQueue = {}

-- ====================== СЕРВЕРНОЕ ВРЕМЯ ======================
local function serverNow()
    return os.time() + serverTimeDelta
end

-- ====================== FIREBASE WORKER ======================
local function safeRequest(url, method, body)
    local result = nil
    for attempt = 1, 3 do
        local ok, res = pcall(function()
            return request({
                Url     = url,
                Method  = method,
                Headers = method ~= "GET" and {["Content-Type"] = "application/json"} or nil,
                Body    = body
            })
        end)
        if ok and res and res.StatusCode == 200 and res.Body then
            fbStatus = "OK"
            result   = res.Body
            break
        end
        fbStatus = "ERR" .. attempt
        task.wait(attempt * 1.5)
    end
    if not result then fbStatus = "FAIL" end
    return result
end

local function fbWriteAsync(url, method, body)
    table.insert(fbWriteQueue, {url = url, method = method, body = body})
end

task.spawn(function()
    while true do
        if #fbWriteQueue > 0 then
            local item = table.remove(fbWriteQueue, 1)
            safeRequest(item.url, item.method, item.body)
        else
            task.wait(0.05)
        end
    end
end)

-- ====================== FIREBASE ФУНКЦИИ ======================
local function writeThrowBatch(nextQueue)
    local data = string.format(
        '{"comboQueue":%d,"comboThrownBy":%d,"lastThrowTime":{"sv":"timestamp"}}',
        nextQueue, ACCOUNT_ID
    )
    fbWriteAsync(FIREBASE_URL .. "/.json", "PATCH", data)
    -- ✅ Обновляем кэш СРАЗУ локально не дожидаясь Firebase
    cachedQueue    = nextQueue
    lastQueueCheck = tick()
    comboThrownBy  = ACCOUNT_ID
    lastThrowTime  = serverNow()
end

local function readQueue()
    local body = safeRequest(FIREBASE_URL .. "/comboQueue.json", "GET")
    if body and body ~= "null" then
        local val = tonumber(body)
        if val then
            cachedQueue    = val
            lastQueueCheck = tick()
            return cachedQueue
        end
    end
    return cachedQueue > 0 and cachedQueue or nil
end

local function readQueueFresh()
    lastQueueCheck = 0
    return readQueue()
end

local function writeQueue(value)
    fbWriteAsync(FIREBASE_URL .. "/comboQueue.json", "PUT", tostring(value))
    fbWriteAsync(FIREBASE_URL .. "/comboQueueLastUpdate.json", "PUT", '{"sv":"timestamp"}')
    cachedQueue    = value
    lastQueueCheck = tick()
end

local function readLastUpdateTime()
    local body = safeRequest(FIREBASE_URL .. "/comboQueueLastUpdate.json", "GET")
    if body and body ~= "null" then
        local ms = tonumber(body)
        return ms and math.floor(ms / 1000) or nil
    end
    return nil
end

local function readLastThrowTime()
    local body = safeRequest(FIREBASE_URL .. "/lastThrowTime.json", "GET")
    if body and body ~= "null" then
        local ms = tonumber(body)
        return ms and math.floor(ms / 1000) or 0
    end
    return 0
end

local function writeMyValue(value)
    fbWriteAsync(
        FIREBASE_URL .. "/accountValues/" .. ACCOUNT_ID .. ".json",
        "PUT", tostring(value)
    )
    lastWrittenValue = value
end

local function writeMyValueIfSignificant(value)
    local sig = (value == 39)
        or (lastWrittenValue == 39 and value ~= 39)
        or (math.abs(value - lastWrittenValue) >= 5)
        or (lastWrittenValue == -1)
    if sig then writeMyValue(value) end
end

local function readAllValues()
    local body = safeRequest(FIREBASE_URL .. "/accountValues.json", "GET")
    if body and body ~= "null" then
        local values = {}
        for id, val in body:gmatch('"(%d+)":(%d+)') do
            values[tonumber(id)] = tonumber(val)
        end
        return values
    end
    return nil
end

local function writePauseFlag(paused)
    fbWriteAsync(FIREBASE_URL .. "/globalPause.json", "PUT", paused and "true" or "false")
end

local function readPauseFlag()
    local body = safeRequest(FIREBASE_URL .. "/globalPause.json", "GET")
    return body == "true"
end

local function writeMyStatus(state)
    local safeVal = (lastValue >= 0) and lastValue or 0
    local data = string.format(
        '{"value":%d,"queue":%s,"lock":%s,"state":"%s"}',
        safeVal,
        tostring(cachedQueue == ACCOUNT_ID),
        tostring(comboLock),
        state or "idle"
    )
    fbWriteAsync(FIREBASE_URL .. "/status/" .. ACCOUNT_ID .. ".json", "PUT", data)
end

local function readAllStatuses()
    local body = safeRequest(FIREBASE_URL .. "/status.json", "GET")
    return (body and body ~= "null") and body or nil
end

local function getNextQueue()
    return (ACCOUNT_ID % TOTAL_ACCOUNTS) + 1
end

-- ====================== СИНХРОНИЗАЦИЯ ВРЕМЕНИ ======================
local function syncServerTime()
    local body = safeRequest(
        FIREBASE_URL .. "/serverTimeSync/" .. ACCOUNT_ID .. ".json",
        "PUT", '{"sv":"timestamp"}'
    )
    if body and body ~= "null" then
        local ms = tonumber(body)
        if ms then
            serverTimeDelta = math.floor(ms / 1000) - os.time()
            return true
        end
    end
    return false
end

-- ====================== УМНАЯ ОЧЕРЕДЬ ======================
local function findAccountWith39()
    local values = readAllValues()
    if not values then return getNextQueue() end
    for i = 1, TOTAL_ACCOUNTS - 1 do
        local checkId = (ACCOUNT_ID - 1 + i) % TOTAL_ACCOUNTS + 1
        if values[checkId] == 39 then return checkId end
    end
    return getNextQueue()
end

-- ====================== ПРЕДСКАЗАНИЕ ======================
local function addValueHistory(value)
    table.insert(valueHistory, {t = tick(), v = value})
    while #valueHistory > VALUE_HISTORY_SIZE do
        table.remove(valueHistory, 1)
    end
end

local function predictWillReach39()
    if lastValue >= 39 then return true end
    if #valueHistory < PREDICT_MIN_POINTS then return true end
    local oldest   = valueHistory[1]
    local newest   = valueHistory[#valueHistory]
    local timeDiff = newest.t - oldest.t
    if timeDiff < 1 then return true end
    local rate = (newest.v - oldest.v) / timeDiff
    if rate <= 0 then return false end
    return ((39 - lastValue) / rate) < PREDICT_MAX_NEEDED
end

-- ====================== GUI ======================
local playerGui = LP:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("ComboThrower_" .. ACCOUNT_ID)
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "ComboThrower_" .. ACCOUNT_ID
screenGui.ResetOnSpawn = false
screenGui.Parent       = playerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size                   = UDim2.new(0, 18, 0, 18)
toggleBtn.Position               = UDim2.new(0, 4, 0, 4 + (ACCOUNT_ID - 1) * (GUI_H + 6))
toggleBtn.BackgroundColor3       = Color3.fromRGB(40, 40, 40)
toggleBtn.BackgroundTransparency = 0.3
toggleBtn.Text                   = "×"
toggleBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
toggleBtn.Font                   = Enum.Font.GothamBold
toggleBtn.TextSize               = 10
toggleBtn.BorderSizePixel        = 0
toggleBtn.ZIndex                 = 10
toggleBtn.Parent                 = screenGui

local toggleDot = Instance.new("Frame")
toggleDot.Size             = UDim2.new(0, 5, 0, 5)
toggleDot.Position         = UDim2.new(1, -6, 0, 1)
toggleDot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
toggleDot.BorderSizePixel  = 0
toggleDot.ZIndex           = 11
toggleDot.Parent           = toggleBtn

local frame = Instance.new("Frame")
frame.Size                   = UDim2.new(0, GUI_W, 0, GUI_H)
frame.Position               = UDim2.new(0, 26, 0, 4 + (ACCOUNT_ID - 1) * (GUI_H + 6))
frame.BackgroundColor3       = Color3.fromRGB(22, 22, 28)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel        = 0
frame.Active                 = true
frame.Draggable              = true
frame.ClipsDescendants       = true
frame.Visible                = true
frame.Parent                 = screenGui

local topBar = Instance.new("Frame")
topBar.Size             = UDim2.new(1, 0, 0, 2)
topBar.Position         = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
topBar.BorderSizePixel  = 0
topBar.Parent           = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size               = UDim2.new(1, -6, 0, 13)
statusLabel.Position           = UDim2.new(0, 4, 0, 3)
statusLabel.BackgroundTransparency = 1
statusLabel.Text               = "Val:-- | Q:-- | #" .. ACCOUNT_ID
statusLabel.TextColor3         = Color3.fromRGB(220, 220, 220)
statusLabel.Font               = Enum.Font.GothamBold
statusLabel.TextSize           = 10
statusLabel.TextXAlignment     = Enum.TextXAlignment.Left
statusLabel.Parent             = frame

local countdownLabel = Instance.new("TextLabel")
countdownLabel.Size               = UDim2.new(1, -6, 0, 12)
countdownLabel.Position           = UDim2.new(0, 4, 0, 17)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text               = "Initializing..."
countdownLabel.TextColor3         = Color3.fromRGB(255, 200, 80)
countdownLabel.Font               = Enum.Font.Gotham
countdownLabel.TextSize           = 9
countdownLabel.TextXAlignment     = Enum.TextXAlignment.Left
countdownLabel.Parent             = frame

local valBarBg = Instance.new("Frame")
valBarBg.Size             = UDim2.new(1, -8, 0, 4)
valBarBg.Position         = UDim2.new(0, 4, 0, 31)
valBarBg.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
valBarBg.BorderSizePixel  = 0
valBarBg.Parent           = frame

local valBarFill = Instance.new("Frame")
valBarFill.Size             = UDim2.new(0, 0, 1, 0)
valBarFill.BackgroundColor3 = Color3.fromRGB(255, 120, 0)
valBarFill.BorderSizePixel  = 0
valBarFill.Parent           = valBarBg

local timerBarBg = Instance.new("Frame")
timerBarBg.Size             = UDim2.new(1, -8, 0, 4)
timerBarBg.Position         = UDim2.new(0, 4, 0, 37)
timerBarBg.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
timerBarBg.BorderSizePixel  = 0
timerBarBg.Visible          = false
timerBarBg.Parent           = frame

local timerBarFill = Instance.new("Frame")
timerBarFill.Size             = UDim2.new(1, 0, 1, 0)
timerBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
timerBarFill.BorderSizePixel  = 0
timerBarFill.Parent           = timerBarBg

local infoLabel = Instance.new("TextLabel")
infoLabel.Size               = UDim2.new(1, -6, 0, 11)
infoLabel.Position           = UDim2.new(0, 4, 0, 43)
infoLabel.BackgroundTransparency = 1
infoLabel.Text               = "FB:-- | T:0 | dt:0s"
infoLabel.TextColor3         = Color3.fromRGB(130, 160, 200)
infoLabel.Font               = Enum.Font.Code
infoLabel.TextSize           = 8
infoLabel.TextXAlignment     = Enum.TextXAlignment.Left
infoLabel.Parent             = frame

local predictLabel = Instance.new("TextLabel")
predictLabel.Size               = UDim2.new(1, -6, 0, 11)
predictLabel.Position           = UDim2.new(0, 4, 0, 55)
predictLabel.BackgroundTransparency = 1
predictLabel.Text               = "Pred: --"
predictLabel.TextColor3         = Color3.fromRGB(180, 180, 100)
predictLabel.Font               = Enum.Font.Code
predictLabel.TextSize           = 8
predictLabel.TextXAlignment     = Enum.TextXAlignment.Left
predictLabel.Parent             = frame

local logLabels = {}
for i = 1, 3 do
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -6, 0, 10)
    lbl.Position           = UDim2.new(0, 4, 0, 67 + (i - 1) * 10)
    lbl.BackgroundTransparency = 1
    lbl.Text               = ""
    lbl.Font               = Enum.Font.Code
    lbl.TextSize           = 8
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.TextColor3         = Color3.fromRGB(
        160 - (i - 1) * 30,
        220 - (i - 1) * 40,
        160 - (i - 1) * 30
    )
    lbl.Parent  = frame
    logLabels[i] = lbl
end

local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, -8, 0, 1)
divider.Position         = UDim2.new(0, 4, 0, 98)
divider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
divider.BorderSizePixel  = 0
divider.Parent           = frame

-- Строки аккаунтов
local accountRows = {}
for i = 1, TOTAL_ACCOUNTS do
    local y = 101 + (i - 1) * ACC_ROW_H

    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 5, 0, 5)
    dot.Position         = UDim2.new(0, 4, 0, y + 4)
    dot.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    dot.BorderSizePixel  = 0
    dot.Parent           = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0, 100, 0, ACC_ROW_H)
    lbl.Position           = UDim2.new(0, 13, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text               = "#" .. i .. " val:--"
    lbl.TextColor3         = Color3.fromRGB(170, 170, 170)
    lbl.Font               = Enum.Font.Code
    lbl.TextSize           = 8
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = frame

    local barBg = Instance.new("Frame")
    barBg.Size             = UDim2.new(0, 72, 0, 4)
    barBg.Position         = UDim2.new(0, 118, 0, y + 4)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    barBg.BorderSizePixel  = 0
    barBg.Parent           = frame

    local barFill = Instance.new("Frame")
    barFill.Size             = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
    barFill.BorderSizePixel  = 0
    barFill.Parent           = barBg

    accountRows[i] = {dot = dot, lbl = lbl, barFill = barFill}
end

local btnY = 101 + TOTAL_ACCOUNTS * ACC_ROW_H + 3

local btnReset = Instance.new("TextButton")
btnReset.Size             = UDim2.new(0, 58, 0, 14)
btnReset.Position         = UDim2.new(0, 4, 0, btnY)
btnReset.BackgroundColor3 = Color3.fromRGB(160, 45, 45)
btnReset.Text             = "Reset Q→1"
btnReset.TextColor3       = Color3.fromRGB(255, 255, 255)
btnReset.Font             = Enum.Font.Gotham
btnReset.TextSize         = 8
btnReset.BorderSizePixel  = 0
btnReset.Parent           = frame

local btnForce = Instance.new("TextButton")
btnForce.Size             = UDim2.new(0, 52, 0, 14)
btnForce.Position         = UDim2.new(0, 66, 0, btnY)
btnForce.BackgroundColor3 = Color3.fromRGB(40, 130, 40)
btnForce.Text             = "Force Me"
btnForce.TextColor3       = Color3.fromRGB(255, 255, 255)
btnForce.Font             = Enum.Font.Gotham
btnForce.TextSize         = 8
btnForce.BorderSizePixel  = 0
btnForce.Parent           = frame

local btnPause = Instance.new("TextButton")
btnPause.Size             = UDim2.new(0, 62, 0, 14)
btnPause.Position         = UDim2.new(0, 122, 0, btnY)
btnPause.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
btnPause.Text             = "⏸ Pause"
btnPause.TextColor3       = Color3.fromRGB(255, 255, 255)
btnPause.Font             = Enum.Font.Gotham
btnPause.TextSize         = 8
btnPause.BorderSizePixel  = 0
btnPause.Parent           = frame

-- ====================== ЛОГ ======================
local function addLog(msg)
    table.insert(logLines, 1, msg)
    if #logLines > 3 then table.remove(logLines, 4) end
    for i = 1, 3 do
        logLabels[i].Text = logLines[i] or ""
    end
end

local function setBarColor(color)
    topBar.BackgroundColor3  = color
    toggleDot.BackgroundColor3 = color
end

-- ====================== GUI ОБНОВЛЕНИЕ ======================
local function updateValBar()
    local p = math.max(0, math.min(1, (lastValue >= 0 and lastValue or 0) / 39))
    valBarFill.Size = UDim2.new(p, 0, 1, 0)
    if p >= 1 then
        valBarFill.BackgroundColor3 = Color3.fromRGB(50, 230, 50)
    elseif p > 0.7 then
        valBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    else
        valBarFill.BackgroundColor3 = Color3.fromRGB(255, 120, 0)
    end
end

local function updatePredictLabel()
    if lastValue >= 39 then
        predictLabel.Text       = "Pred: READY ✓"
        predictLabel.TextColor3 = Color3.fromRGB(50, 220, 50)
        return
    end
    if #valueHistory < PREDICT_MIN_POINTS then
        predictLabel.Text       = "Pred: collecting..."
        predictLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
        return
    end
    local oldest   = valueHistory[1]
    local newest   = valueHistory[#valueHistory]
    local timeDiff = newest.t - oldest.t
    if timeDiff < 1 then predictLabel.Text = "Pred: --"; return end
    local rate = (newest.v - oldest.v) / timeDiff
    if rate <= 0 then
        predictLabel.Text       = "Pred: not growing ✗"
        predictLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
        return
    end
    local secs = (39 - lastValue) / rate
    if secs < PREDICT_MAX_NEEDED then
        predictLabel.Text       = string.format("Pred: ~%.0fs to 39 ✓", secs)
        predictLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
    else
        predictLabel.Text       = string.format("Pred: ~%.0fs SKIP ✗", secs)
        predictLabel.TextColor3 = Color3.fromRGB(255, 140, 40)
    end
end

local function updateInfoLine()
    local timerStr = ""
    if comboTimerActive then
        local rem = math.max(0, comboTimerDuration - (tick() - comboTimerStart))
        timerStr = string.format("T:%.0fs | ", rem)
    end
    infoLabel.Text = string.format("%sFB:%s | #%d: %dt | dt:%ds",
        timerStr, fbStatus, ACCOUNT_ID, totalThrows, serverTimeDelta)
end

local function updateGUI()
    statusLabel.Text = string.format("Val:%d | Q:%s | #%d%s",
        lastValue >= 0 and lastValue or 0,
        tostring(cachedQueue), ACCOUNT_ID,
        isPaused and " ⏸" or "")

    updateValBar()
    updatePredictLabel()
    updateInfoLine()

    local isMyQ = (cachedQueue == ACCOUNT_ID)

    if isPaused then
        setBarColor(Color3.fromRGB(80, 80, 200))
        countdownLabel.Text       = "⏸ PAUSED"
        countdownLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
    elseif comboLock then
        setBarColor(Color3.fromRGB(255, 190, 0))
        countdownLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
        if waitingCoconutGone then
            countdownLabel.Text = "Coconut — waiting gone..."
        elseif comboTimerActive then
            local rem = math.max(0, comboTimerDuration - (tick() - comboTimerStart))
            countdownLabel.Text = string.format("Combo delay: %.0fs", rem)
        else
            countdownLabel.Text = "Combo in progress"
        end
    elseif chainWatchActive then
        setBarColor(Color3.fromRGB(220, 40, 40))
        countdownLabel.Text       = "Chain dead — recovering"
        countdownLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    elseif skipping then
        setBarColor(Color3.fromRGB(255, 100, 0))
        countdownLabel.Text       = "Skipping..."
        countdownLabel.TextColor3 = Color3.fromRGB(255, 160, 60)
    elseif cycleActive then
        setBarColor(Color3.fromRGB(0, 130, 255))
        countdownLabel.Text       = "Cycle active"
        countdownLabel.TextColor3 = Color3.fromRGB(80, 180, 255)
    elseif isMyQ and coconutPresent then
        setBarColor(Color3.fromRGB(255, 190, 0))
        countdownLabel.Text       = "Watching coconut..."
        countdownLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
    elseif isMyQ and lastValue == 39 then
        setBarColor(Color3.fromRGB(0, 220, 0))
        countdownLabel.Text       = "My turn — ready!"
        countdownLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
    elseif isMyQ then
        setBarColor(Color3.fromRGB(255, 140, 0))
        countdownLabel.Text       = "My turn (no 39)"
        countdownLabel.TextColor3 = Color3.fromRGB(255, 170, 60)
    elseif not canThrow then
        setBarColor(Color3.fromRGB(100, 100, 100))
        local rem = math.max(0, START_DELAY - (tick() - startTime))
        countdownLabel.Text       = "Wait " .. math.ceil(rem) .. "s"
        countdownLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    else
        setBarColor(Color3.fromRGB(70, 70, 80))
        countdownLabel.Text       = "Watching Q=" .. tostring(cachedQueue)
        countdownLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
    end
end

-- ====================== ОБНОВЛЕНИЕ СТРОК АККАУНТОВ ======================
-- ✅ Фикс 2: правильный парсинг + хартбит каждые 3 сек
task.spawn(function()
    while true do
        task.wait(2)
        if guiMinimized then continue end

        local body = readAllStatuses()
        if not body then continue end

        for i = 1, TOTAL_ACCOUNTS do
            local row = accountRows[i]
            if not row then continue end

            local section = body:match('"' .. tostring(i) .. '":%s*(%b{})')

            if section and #section > 2 then
                -- ✅ Парсим корректно — Firebase пишет true/false без кавычек
                local val = tonumber(section:match('"value":%s*(%d+)')) or 0

                local queueRaw = section:match('"queue":%s*([%w"]+)')
                local queue    = (queueRaw == "true" or queueRaw == '"true"')

                local lockRaw  = section:match('"lock":%s*([%w"]+)')
                local lock     = (lockRaw == "true" or lockRaw == '"true"')

                local state = section:match('"state":%s*"([^"]*)"') or "idle"

                if lock then
                    row.dot.BackgroundColor3 = Color3.fromRGB(255, 190, 0)
                elseif queue then
                    row.dot.BackgroundColor3 = Color3.fromRGB(0, 220, 0)
                else
                    row.dot.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
                end

                local qStr = queue and " Q" or "  "
                local sStr = ""
                if lock or state == "lock" then
                    sStr = "[lock]"
                elseif state == "timer" then
                    sStr = "[tmr]"
                elseif state == "threw" then
                    sStr = "[thr]"
                elseif state == "cycle" then
                    sStr = "[cyc]"
                elseif state == "paused" then
                    sStr = "[pau]"
                end

                row.lbl.Text = string.format("#%d v:%d%s %s", i, val, qStr, sStr)

                local prog = math.max(0, math.min(1, val / 39))
                row.barFill.Size = UDim2.new(prog, 0, 1, 0)
                if prog >= 1 then
                    row.barFill.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
                elseif prog > 0.7 then
                    row.barFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                else
                    row.barFill.BackgroundColor3 = Color3.fromRGB(80, 120, 220)
                end
            else
                row.dot.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
                row.lbl.Text             = "#" .. i .. " offline"
                row.barFill.Size         = UDim2.new(0, 0, 1, 0)
            end
        end
    end
end)

-- ✅ Фикс 2: хартбит — пишем статус каждые 3 сек чтобы не показывало offline
task.spawn(function()
    while true do
        task.wait(3)
        local state
        if isPaused then
            state = "paused"
        elseif comboLock then
            state = comboTimerActive and "timer" or "lock"
        elseif cycleActive then
            state = "cycle"
        else
            state = "idle"
        end
        writeMyStatus(state)
        writeMyValueIfSignificant(lastValue >= 0 and lastValue or 0)
    end
end)

-- ====================== ТАЙМЕР ======================
local function startGuiTimer(duration)
    comboTimerStart    = tick()
    comboTimerDuration = duration
    comboTimerActive   = true
    timerBarBg.Visible = true
end

local function stopGuiTimer()
    comboTimerActive   = false
    timerBarBg.Visible = false
    timerBarFill.Size  = UDim2.new(1, 0, 1, 0)
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if comboTimerActive and comboTimerDuration > 0 then
            local elapsed  = tick() - comboTimerStart
            local progress = math.max(0, math.min(1, 1 - elapsed / comboTimerDuration))
            timerBarFill.Size = UDim2.new(progress, 0, 1, 0)
            if progress > 0.5 then
                timerBarFill.BackgroundColor3 = Color3.fromRGB(
                    math.floor((1 - progress) * 2 * 255), 200, 0)
            else
                timerBarFill.BackgroundColor3 = Color3.fromRGB(
                    255, math.floor(progress * 2 * 200), 0)
            end
            if not guiMinimized then updateGUI() end
        end
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    guiMinimized  = not guiMinimized
    frame.Visible = not guiMinimized
    toggleBtn.Text = guiMinimized and tostring(ACCOUNT_ID) or "×"
    if not guiMinimized then updateGUI() end
end)

-- ====================== ЭКИПИРОВКА ======================
local function isAccessoryEquipped(name)
    local char = LP.Character
    if not char then return false end
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Accessory") and c.Name == name then return true end
    end
    return false
end

local function equipAccessory(itemType)
    local ok = pcall(function()
        ItemPackageEvent:InvokeServer("Equip", {Category = "Accessory", Type = itemType})
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

-- ====================== СБРОС ======================
local function resetAllStates(reason)
    if comboThread then pcall(task.cancel, comboThread); comboThread = nil end
    comboLock               = false
    comboStarting           = false
    comboLockTime           = 0
    cycleActive             = false
    cycleStartTime          = 0
    ourCycleActive          = false
    skipping                = false
    skippingTime            = 0
    chainWatchActive        = false
    waitingCoconutGone      = false
    coconutSeenWhileMyQueue = false
    stopGuiTimer()
    addLog("Reset: " .. (reason or "?"))
    updateGUI()
end

-- ====================== БРОСОК ======================
local function SpawnCoconut()
    pcall(function()
        PlayerActivesCommand:FireServer({Name = "Coconut"})
    end)
    totalThrows   = totalThrows + 1
    lastThrowTime = serverNow()
    updateGUI()
    addLog("Throw! #" .. totalThrows)
end

-- ====================== ЦИКЛ ======================
local function startCycle(count)
    if cycleActive then return end
    cycleActive    = true
    ourCycleActive = true
    cycleStartTime = tick()
    updateGUI()
    task.spawn(function()
        local ok, err = pcall(function()
            task.wait(CYCLE_DELAY)
            for i = 1, count do
                if isPaused then break end
                SpawnCoconut()
                if i < count then task.wait(COCONUT_INTERVAL) end
            end
        end)
        if not ok then addLog("Cycle err: " .. tostring(err)) end
        cycleActive    = false
        ourCycleActive = false
        cycleStartTime = 0
        updateGUI()
    end)
end

-- ====================== ПРОПУСК ХОДА ======================
local function skipTurn()
    if skipping or comboLock or not canThrow then return end
    if cachedQueue ~= ACCOUNT_ID then return end
    if coconutPresent or isPaused then return end

    skipping     = true
    skippingTime = tick()
    updateGUI()

    task.spawn(function()
        task.wait(SKIP_DELAY)
        if lastValue == 39 or coconutPresent then
            addLog("Skip abort — got 39")
            skipping, skippingTime = false, 0
            updateGUI()
            return
        end
        local current = readQueueFresh()
        if current ~= ACCOUNT_ID then
            addLog("Skip abort — Q moved")
            skipping, skippingTime = false, 0
            updateGUI()
            return
        end
        local targetQ = findAccountWith39()
        writeQueue(targetQ)
        coconutSeenWhileMyQueue = false
        addLog("Skip → Acc" .. targetQ)
        skipping, skippingTime = false, 0
        updateGUI()
    end)
end

-- ====================== ОСНОВНОЕ КОМБО ======================
local function startCombo()
    if comboStarting or comboLock or not canThrow or isPaused then return end

    if lastValue ~= 39 then
        if not predictWillReach39() then
            addLog("Pred: skip (won't reach 39)")
        else
            addLog("No 39 (val=" .. lastValue .. ") → skip")
        end
        skipTurn()
        return
    end

    comboStarting = true

    local freshQ = readQueueFresh()
    if freshQ ~= ACCOUNT_ID then
        addLog("Combo abort: Q=" .. tostring(freshQ))
        comboStarting = false
        return
    end

    comboLock               = true
    comboStarting           = false
    comboLockTime           = tick()
    coconutSeenWhileMyQueue = false
    writeMyStatus("lock")
    updateGUI()

    comboThread = task.spawn(function()
        local ok, err = pcall(function()
            local timerDone = false
            while not timerDone do
                if isPaused then
                    addLog("Abort: paused")
                    return
                end
                if cachedQueue ~= ACCOUNT_ID then
                    addLog("Abort: Q changed")
                    return
                end
                if lastValue ~= 39 then
                    addLog("Abort: val dropped")
                    writeQueue(findAccountWith39())
                    return
                end

                addLog("Combo delay " .. COMBO_DELAY .. "s")
                writeMyStatus("timer")
                startGuiTimer(COMBO_DELAY)

                local tStart      = tick()
                local interrupted = false

                while (tick() - tStart) < COMBO_DELAY do
                    task.wait(COCONUT_SCAN)

                    if isPaused then
                        stopGuiTimer()
                        addLog("Abort: paused in timer")
                        writeQueue(findAccountWith39())
                        return
                    end

                    if coconutPresent and not ourCycleActive then
                        interrupted = true
                        break
                    end

                    if lastValue ~= 39 then
                        stopGuiTimer()
                        addLog("Abort: val dropped in timer")
                        writeQueue(findAccountWith39())
                        return
                    end

                    if cachedQueue ~= ACCOUNT_ID then
                        stopGuiTimer()
                        addLog("Abort: Q changed in timer")
                        return
                    end
                end

                stopGuiTimer()

                if interrupted then
                    waitingCoconutGone = true
                    updateGUI()
                    addLog("Coconut mid-timer → restart")
                    while coconutPresent do task.wait(COCONUT_SCAN) end
                    waitingCoconutGone = false
                    addLog("Gone → restart delay")
                else
                    timerDone = true
                end
            end

            local freshQueue = readQueueFresh()
            if freshQueue ~= ACCOUNT_ID then
                addLog("Abort final: Q changed")
                return
            end
            if lastValue ~= 39 then
                addLog("Abort final: val changed")
                writeQueue(findAccountWith39())
                return
            end
            if isPaused then
                addLog("Abort final: paused")
                writeQueue(findAccountWith39())
                return
            end

            local nextQ = findAccountWith39()
            SpawnCoconut()
            writeThrowBatch(nextQ)
            coconutSeenWhileMyQueue = false
            writeMyStatus("threw")
            addLog("Threw! → Acc" .. nextQ)
            startCycle(CYCLE_COUNT)
        end)

        waitingCoconutGone = false
        stopGuiTimer()

        if not ok then
            addLog("Err: " .. tostring(err):sub(1, 22))
            local cur = readQueueFresh()
            if cur == ACCOUNT_ID then
                writeQueue(findAccountWith39())
            end
        end

        comboLock     = false
        comboLockTime = 0
        comboThread   = nil
        writeMyStatus("idle")
        updateGUI()
    end)
end

-- ====================== ДЕТЕКТОР ComboCoconut ======================
-- ✅ Фикс 3: используем кэш сначала, потом fresh если нужно
task.spawn(function()
    while true do
        local present   = false
        local particles = Workspace:FindFirstChild("Particles")
        if particles then
            present = particles:FindFirstChild("ComboCoconut", true) ~= nil
        end

        if present and not coconutPresent then
            coconutPresent = true
            addLog("Coconut appeared")
            updateGUI()

        elseif not present and coconutPresent then
            coconutPresent = false
            addLog("Coconut gone")

            -- ШАГ 1: Проверяем локальный кэш сначала
            -- writeThrowBatch уже обновил cachedQueue локально
            local queueToUse = cachedQueue

            -- ШАГ 2: Если кэш говорит что НЕ моя очередь —
            -- ждём 0.5 сек (fbWriteWorker успеет записать)
            -- и делаем свежий запрос
            if queueToUse ~= ACCOUNT_ID then
                task.wait(0.5)
                queueToUse = readQueueFresh()
            end

            -- ШАГ 3: Запускаем комбо если условия выполнены
            if queueToUse == ACCOUNT_ID
                and canThrow
                and not comboLock
                and not comboStarting
                and not cycleActive
                and not skipping
                and not isPaused
            then
                addLog("My turn Q=" .. queueToUse .. " → combo")
                startCombo()
            else
                -- Лог причины почему не запустили
                if queueToUse ~= ACCOUNT_ID then
                    addLog("Not my turn Q=" .. tostring(queueToUse))
                elseif comboLock then
                    addLog("Skip: comboLock")
                elseif cycleActive then
                    addLog("Skip: cycleActive")
                elseif not canThrow then
                    addLog("Skip: canThrow=false")
                elseif isPaused then
                    addLog("Skip: paused")
                end
            end

            coconutSeenWhileMyQueue = false
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
        if isPaused then continue end
        if canThrow and not comboLock and not comboStarting
            and not skipping and not cycleActive then
            readQueue()
            updateGUI()
            if cachedQueue == ACCOUNT_ID then
                if coconutPresent then
                    coconutSeenWhileMyQueue = true
                    addLog("My turn, coconut — watch")
                elseif lastValue == 39 then
                    addLog("My turn val=39 → combo")
                    startCombo()
                else
                    skipTurn()
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
            and info.Action == "Update"
        then
            local value = info.Values and info.Values[1] or 0
            if not firstUpdateReceived then
                firstUpdateReceived = true
                lastValue           = value
                lastValueChangeTime = tick()
                addValueHistory(value)
                writeMyValueIfSignificant(value)
                if value <= 34 then equipCanister() else equipPorcelain() end
                updateGUI()
                addLog("Init val=" .. value)
                return
            end
            if value ~= lastValue then
                lastValue           = value
                lastValueChangeTime = tick()
                addValueHistory(value)
                writeMyValueIfSignificant(value)
                updateGUI()
                if value <= 34 then equipCanister() else equipPorcelain() end
                if value < 39 and comboLock and comboThread then
                    pcall(task.cancel, comboThread)
                    waitingCoconutGone = false
                    stopGuiTimer()
                    comboThread   = nil
                    comboLock     = false
                    comboLockTime = 0
                    task.spawn(function()
                        local cur = readQueueFresh()
                        if cur == ACCOUNT_ID then
                            local t = findAccountWith39()
                            writeQueue(t)
                            addLog("Val<39 → Acc" .. t)
                        end
                        coconutSeenWhileMyQueue = false
                        updateGUI()
                    end)
                end
            end
        end
    end
end)

-- ====================== КНОПКА ПАУЗЫ ======================
btnPause.MouseButton1Click:Connect(function()
    isPaused = not isPaused
    writePauseFlag(isPaused)

    if isPaused then
        btnPause.BackgroundColor3 = Color3.fromRGB(180, 130, 0)
        btnPause.Text             = "▶ Resume"
        if comboThread then pcall(task.cancel, comboThread); comboThread = nil end
        stopGuiTimer()
        comboLock      = false
        comboStarting  = false
        comboLockTime  = 0
        cycleActive    = false
        ourCycleActive = false
        skipping       = false
        waitingCoconutGone = false
        task.spawn(function()
            local cur = readQueueFresh()
            if cur == ACCOUNT_ID then
                writeQueue(getNextQueue())
                addLog("Paused → Acc" .. getNextQueue())
            end
            writeMyStatus("paused")
            updateGUI()
        end)
        addLog("Paused — all stopped")
    else
        btnPause.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
        btnPause.Text             = "⏸ Pause"
        addLog("Resumed")
        writeMyStatus("idle")
        updateGUI()
    end
end)

task.spawn(function()
    while not canThrow do task.wait(1) end
    while true do
        task.wait(3)
        local serverPaused = readPauseFlag()
        if serverPaused ~= isPaused then
            isPaused = serverPaused
            if isPaused then
                if comboThread then pcall(task.cancel, comboThread); comboThread = nil end
                stopGuiTimer()
                comboLock      = false
                comboStarting  = false
                cycleActive    = false
                ourCycleActive = false
                skipping       = false
                btnPause.BackgroundColor3 = Color3.fromRGB(180, 130, 0)
                btnPause.Text             = "▶ Resume"
                addLog("Remote pause")
            else
                btnPause.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
                btnPause.Text             = "⏸ Pause"
                addLog("Remote resume")
            end
            updateGUI()
        end
    end
end)

-- ====================== CHARACTERADDED ======================
local function onCharacterAdded()
    addLog("Respawn — reset")
    resetAllStates("respawn")
    task.wait(2)
    hasCanister  = false
    hasPorcelain = false
    if lastValue <= 34 then equipCanister() else equipPorcelain() end
    task.spawn(function()
        local cur = readQueueFresh()
        if cur == ACCOUNT_ID then
            writeQueue(getNextQueue())
            addLog("Respawn: Q → Acc" .. getNextQueue())
        end
        updateGUI()
    end)
end

LP.CharacterAdded:Connect(onCharacterAdded)
if LP.Character then
    task.spawn(function()
        task.wait(1)
        if lastValue <= 34 then equipCanister() else equipPorcelain() end
    end)
end

-- ====================== ЗАДЕРЖКА СТАРТА ======================
-- ✅ Фикс 1: startTime сбрасывается ПОСЛЕ jitter
task.spawn(function()
    local jitter = (ACCOUNT_ID - 1) * 3
    task.wait(jitter)

    -- ✅ Сбрасываем startTime ПОСЛЕ jitter чтобы START_DELAY был честным
    startTime = tick()

    addLog("Syncing time...")
    if syncServerTime() then
        addLog("dt=" .. serverTimeDelta .. "s")
    else
        addLog("Time sync fail")
    end

    -- Честный обратный отсчёт START_DELAY
    while tick() - startTime < START_DELAY do
        if tick() - lastQueueCheck > 3 then readQueue() end
        local rem = math.max(0, START_DELAY - (tick() - startTime))
        countdownLabel.Text       = "Wait " .. math.ceil(rem) .. "s"
        countdownLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        task.wait(0.5)
    end

    task.wait((ACCOUNT_ID - 1) * 1.5)
    readQueue()

    local lastUpdate = readLastUpdateTime()
    if lastUpdate and (serverNow() - lastUpdate) > 300 then
        if ACCOUNT_ID == 1 then
            writeQueue(1)
            addLog("Queue idle >5m → reset")
        end
    end

    local fbLast = readLastThrowTime()
    if fbLast and fbLast > 0 then
        lastThrowTime = math.max(lastThrowTime, fbLast)
    end

    isPaused = readPauseFlag()
    if isPaused then
        btnPause.BackgroundColor3 = Color3.fromRGB(180, 130, 0)
        btnPause.Text             = "▶ Resume"
        addLog("Started paused")
    end

    writeMyValue(lastValue >= 0 and lastValue or 0)
    writeMyStatus("idle")

    canThrow = true
    addLog("Start #" .. ACCOUNT_ID .. " dt=" .. serverTimeDelta .. "s")
    updateGUI()
end)

-- ====================== ВОТЧДОГ ======================
task.spawn(function()
    task.wait(math.random(5, 15))
    while true do
        task.wait(30)
        if isPaused then continue end

        local lastUpdate = readLastUpdateTime()
        if lastUpdate and (serverNow() - lastUpdate) > 180 then
            if ACCOUNT_ID == 1 then
                writeQueue(1)
                addLog("WD: Q dead → reset")
            end
        end

        if comboLock and comboLockTime > 0 and (tick() - comboLockTime) > 300 then
            addLog("WD: lock stuck")
            resetAllStates("WD lock")
            task.spawn(function()
                local cur = readQueueFresh()
                if cur == ACCOUNT_ID then
                    writeQueue(findAccountWith39())
                end
                updateGUI()
            end)
        end

        local maxCycle = CYCLE_DELAY + (CYCLE_COUNT * COCONUT_INTERVAL) * 2
        if cycleActive and cycleStartTime > 0 and (tick() - cycleStartTime) > maxCycle then
            addLog("WD: cycle stuck")
            cycleActive    = false
            ourCycleActive = false
            cycleStartTime = 0
            updateGUI()
        end

        if skipping and skippingTime > 0 and (tick() - skippingTime) > 30 then
            addLog("WD: skip stuck")
            skipping, skippingTime = false, 0
            updateGUI()
        end

        local char = LP.Character
        if not char or not char:FindFirstChild("Humanoid")
            or char.Humanoid.Health <= 0 then
            addLog("WD: char dead")
            resetAllStates("WD dead")
        end
        updateGUI()
    end
end)

-- ====================== ДЕТЕКТОР ЦЕПОЧКИ ======================
task.spawn(function()
    while not canThrow do task.wait(1) end
    task.wait(15)
    while true do
        task.wait(10)
        if not canThrow or isPaused then continue end

        local fbLast = readLastThrowTime()
        if fbLast and fbLast > 0 then
            lastThrowTime = math.max(lastThrowTime, fbLast)
        end

        local since = serverNow() - lastThrowTime

        if since > CHAIN_TIMEOUT
            and not comboLock and not comboStarting
            and not cycleActive and not skipping
            and not chainWatchActive and not isPaused
            and cachedQueue == ACCOUNT_ID and lastValue == 39
        then
            chainWatchActive = true
            updateGUI()
            addLog("Chain dead " .. since .. "s")

            task.spawn(function()
                if coconutPresent then
                    while coconutPresent do task.wait(COCONUT_SCAN) end
                end
                chainWatchActive = false
                if canThrow and not comboLock and not cycleActive
                    and cachedQueue == ACCOUNT_ID and lastValue == 39 and not isPaused
                then
                    coconutSeenWhileMyQueue = false
                    addLog("Chain recover → combo")
                    startCombo()
                else
                    addLog("Chain: abort")
                    updateGUI()
                end
            end)
        end
    end
end)

-- ====================== GC ======================
task.spawn(function()
    while true do
        task.wait(600)
        local b = gcinfo()
        collectgarbage("collect")
        addLog(string.format("GC: -%dKB", b - gcinfo()))
    end
end)

-- ====================== КНОПКИ ======================
btnReset.MouseButton1Click:Connect(function()
    resetAllStates("manual")
    writeQueue(1)
    addLog("Reset Q=1")
    updateGUI()
end)

btnForce.MouseButton1Click:Connect(function()
    writeQueue(ACCOUNT_ID)
    addLog("Force Q=" .. ACCOUNT_ID)
    updateGUI()
end)

-- ====================== СТАРТ ======================
equipCanister()
readQueue()
updateGUI()
addLog("Init #" .. ACCOUNT_ID)
