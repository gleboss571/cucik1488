--[[
   ALT Combo Coconut Thrower (Firebase v7 - Full Featured)
   Delta-совместим, Lua 5.1.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

-- ====================== НАСТРОЙКИ ======================
local FIREBASE_URL        = "https://fuflik1-e9325-default-rtdb.europe-west1.firebasedatabase.app"
local ACCOUNT_ID          = 1
local TOTAL_ACCOUNTS      = 3
local START_DELAY         = 10
local COMBO_DELAY         = 16
local CYCLE_COUNT         = 4
local CYCLE_DELAY         = 10
local COCONUT_INTERVAL    = 10
local QUEUE_POLL_INTERVAL = 1
local SKIP_DELAY          = 0.2
local COCONUT_SCAN        = 0.1
local CHAIN_TIMEOUT       = 90
local VALUE_HISTORY_SIZE  = 20   -- сколько точек хранить для предсказания
local PREDICT_MIN_POINTS  = 4    -- минимум точек для предсказания
local PREDICT_MAX_NEEDED  = 25   -- если нужно больше N сек — скипаем

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
local comboStarting           = false   -- семафор против двойного запуска
local lastEquipTime           = 0
local comboThrownBy           = 0
local comboLockTime           = 0
local cycleStartTime          = 0
local skippingTime            = 0
local ourCycleActive          = false   -- наш цикл кидает кокосы

local coconutPresent          = false
local coconutSeenWhileMyQueue = false
local waitingCoconutGone      = false

local comboTimerStart         = 0
local comboTimerDuration      = 0
local comboTimerActive        = false

local lastThrowTime           = os.time()
local chainWatchActive        = false

local guiMinimized            = false
local GUI_FULL_HEIGHT         = 230
local statusPanelOpen         = false

local cachedQueue    = 0
local lastQueueCheck = 0
local fbStatus       = "FB: --"

-- Серверное время
local serverTimeDelta = 0  -- разница между серверным и локальным временем

-- Пауза
local isPaused = false

-- Предсказание val=39
local valueHistory    = {}   -- {t=tick(), v=value}
local lastWrittenValue = -1

-- Лог 5 строк
local logLines = {"", "", "", "", ""}

-- Firebase async worker
local fbWriteQueue = {}

-- ====================== СЕРВЕРНОЕ ВРЕМЯ ======================
local function serverNow()
    return os.time() + serverTimeDelta
end

-- ====================== FIREBASE ASYNC WORKER ======================
-- Записи в Firebase НЕ блокируют основные потоки
-- Читаем синхронно но с коротким таймаутом

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
            fbStatus = "FB: OK"
            result = res.Body
            break
        end
        fbStatus = string.format("FB: ERR%d(%s)", attempt, tostring(res and res.StatusCode or "?"))
        task.wait(attempt * 1.5)
    end
    if not result then fbStatus = "FB: FAIL" end
    return result
end

-- Асинхронная запись — добавляем в очередь и не ждём
local function fbWriteAsync(url, method, body)
    table.insert(fbWriteQueue, {url = url, method = method, body = body})
end

-- Воркер обрабатывает очередь записей в фоне
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

-- ====================== FIREBASE БАТЧИНГ ======================
-- Один запрос вместо нескольких при броске
local function writeThrowBatch(nextQueue)
    local data = string.format(
        '{"comboQueue":%d,"comboThrownBy":%d,"lastThrowTime":{"sv":"timestamp"}}',
        nextQueue, ACCOUNT_ID
    )
    -- Батч — один запрос
    fbWriteAsync(FIREBASE_URL .. "/.json", "PATCH", data)
    -- Обновляем кэш локально сразу не дожидаясь ответа
    cachedQueue    = nextQueue
    lastQueueCheck = tick()
    comboThrownBy  = ACCOUNT_ID
    lastThrowTime  = serverNow()
end

-- ====================== FIREBASE ФУНКЦИИ ======================
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
    -- Кэш устарел но Firebase недоступен — используем кэш
    return cachedQueue > 0 and cachedQueue or nil
end

-- Свежее чтение очереди с инвалидацией кэша
local function readQueueFresh()
    lastQueueCheck = 0  -- принудительно инвалидируем кэш
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

-- Умная очередь — пишем своё value в Firebase
local function writeMyValue(value)
    fbWriteAsync(
        FIREBASE_URL .. "/accountValues/" .. ACCOUNT_ID .. ".json",
        "PUT",
        tostring(value)
    )
    lastWrittenValue = value
end

local function writeMyValueIfSignificant(value)
    local significant = (value == 39)
        or (lastWrittenValue == 39 and value ~= 39)
        or (math.abs(value - lastWrittenValue) >= 5)
        or (lastWrittenValue == -1)
    if significant then
        writeMyValue(value)
    end
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

-- Пауза через Firebase — все аккаунты читают этот флаг
local function writePauseFlag(paused)
    fbWriteAsync(
        FIREBASE_URL .. "/globalPause.json",
        "PUT",
        paused and "true" or "false"
    )
end

local function readPauseFlag()
    local body = safeRequest(FIREBASE_URL .. "/globalPause.json", "GET")
    if body and body ~= "null" then
        return body == "true"
    end
    return false
end

-- Статус аккаунта для панели
local function writeMyStatus(state)
    local data = string.format(
        '{"value":%d,"queue":%s,"lock":%s,"state":"%s"}',
        lastValue,
        tostring(cachedQueue == ACCOUNT_ID),
        tostring(comboLock),
        state or "idle"
    )
    fbWriteAsync(
        FIREBASE_URL .. "/status/" .. ACCOUNT_ID .. ".json",
        "PUT",
        data
    )
end

local function readAllStatuses()
    local body = safeRequest(FIREBASE_URL .. "/status.json", "GET")
    if body and body ~= "null" then
        return body
    end
    return nil
end

local function getNextQueue()
    return (ACCOUNT_ID % TOTAL_ACCOUNTS) + 1
end

-- ====================== СИНХРОНИЗАЦИЯ СЕРВЕРНОГО ВРЕМЕНИ ======================
local function syncServerTime()
    -- Пишем timestamp и читаем обратно чтобы узнать серверное время
    local body = safeRequest(
        FIREBASE_URL .. "/serverTimeSync/" .. ACCOUNT_ID .. ".json",
        "PUT",
        '{"sv":"timestamp"}'
    )
    if body and body ~= "null" then
        local serverMs = tonumber(body)
        if serverMs then
            local serverSec  = math.floor(serverMs / 1000)
            serverTimeDelta  = serverSec - os.time()
            return true
        end
    end
    return false
end

-- ====================== УМНАЯ ОЧЕРЕДЬ ======================
local function findAccountWith39()
    local values = readAllValues()
    if not values then
        -- Firebase недоступен — обычная очередь
        return getNextQueue()
    end

    -- Обходим по кругу начиная со следующего после нас
    for i = 1, TOTAL_ACCOUNTS - 1 do
        local checkId = (ACCOUNT_ID - 1 + i) % TOTAL_ACCOUNTS + 1
        if values[checkId] == 39 then
            return checkId
        end
    end

    -- Никто не имеет 39 — следующий по порядку
    return getNextQueue()
end

-- ====================== ПРЕДСКАЗАНИЕ val=39 ======================
local function addValueHistory(value)
    table.insert(valueHistory, {t = tick(), v = value})
    -- Держим только последние N точек
    while #valueHistory > VALUE_HISTORY_SIZE do
        table.remove(valueHistory, 1)
    end
end

-- Вернёт true если предположительно успеем набрать 39
-- Вернёт true если недостаточно данных (не скипаем без уверенности)
local function predictWillReach39()
    if lastValue >= 39 then return true end
    if #valueHistory < PREDICT_MIN_POINTS then return true end

    -- Считаем среднюю скорость роста по всей истории
    local oldest = valueHistory[1]
    local newest = valueHistory[#valueHistory]
    local timeDiff = newest.t - oldest.t

    if timeDiff < 1 then return true end  -- слишком мало времени — не скипаем

    local rate = (newest.v - oldest.v) / timeDiff  -- единиц в секунду

    if rate <= 0 then
        -- Value не растёт или падает — точно не успеем
        return false
    end

    local needed    = 39 - lastValue
    local timeNeeded = needed / rate

    -- Скипаем только если нужно явно больше PREDICT_MAX_NEEDED секунд
    return timeNeeded < PREDICT_MAX_NEEDED
end

-- ====================== GUI ======================
local playerGui = LP:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("ComboThrower_" .. ACCOUNT_ID)
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name        = "ComboThrower_" .. ACCOUNT_ID
screenGui.ResetOnSpawn = false
screenGui.Parent      = playerGui

-- Кнопка сворачивания
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size                  = UDim2.new(0, 24, 0, 24)
toggleBtn.Position              = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * (GUI_FULL_HEIGHT + 10))
toggleBtn.BackgroundColor3      = Color3.fromRGB(40, 40, 40)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.Text                  = "×"
toggleBtn.TextColor3            = Color3.fromRGB(255, 255, 255)
toggleBtn.Font                  = Enum.Font.GothamBold
toggleBtn.TextSize              = 12
toggleBtn.BorderSizePixel       = 0
toggleBtn.ZIndex                = 10
toggleBtn.Parent                = screenGui

local toggleIndicator = Instance.new("Frame")
toggleIndicator.Size            = UDim2.new(0, 6, 0, 6)
toggleIndicator.Position        = UDim2.new(1, -7, 0, 1)
toggleIndicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
toggleIndicator.BorderSizePixel = 0
toggleIndicator.ZIndex          = 11
toggleIndicator.Parent          = toggleBtn

-- Основная панель
local frame = Instance.new("Frame")
frame.Size                  = UDim2.new(0, 230, 0, GUI_FULL_HEIGHT)
frame.Position              = UDim2.new(0, 38, 0, 10 + (ACCOUNT_ID - 1) * (GUI_FULL_HEIGHT + 10))
frame.BackgroundColor3      = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel       = 0
frame.Active                = true
frame.Draggable             = true
frame.ClipsDescendants      = true
frame.Visible               = true
frame.Parent                = screenGui

local indicator = Instance.new("Frame")
indicator.Size            = UDim2.new(0, 8, 0, 8)
indicator.Position        = UDim2.new(1, -12, 0, 6)
indicator.BorderSizePixel = 0
indicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
indicator.Parent          = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size               = UDim2.new(1, -22, 0, 20)
statusLabel.Position           = UDim2.new(0, 5, 0, 3)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
statusLabel.Font               = Enum.Font.Gotham
statusLabel.TextSize           = 11
statusLabel.TextXAlignment     = Enum.TextXAlignment.Left
statusLabel.Parent             = frame

local throwLabel = Instance.new("TextLabel")
throwLabel.Size               = UDim2.new(1, -10, 0, 14)
throwLabel.Position           = UDim2.new(0, 5, 0, 24)
throwLabel.BackgroundTransparency = 1
throwLabel.Text               = "Throws: 0"
throwLabel.TextColor3         = Color3.fromRGB(200, 200, 200)
throwLabel.Font               = Enum.Font.Gotham
throwLabel.TextSize           = 10
throwLabel.TextXAlignment     = Enum.TextXAlignment.Left
throwLabel.Parent             = frame

local countdownLabel = Instance.new("TextLabel")
countdownLabel.Size               = UDim2.new(1, -10, 0, 14)
countdownLabel.Position           = UDim2.new(0, 5, 0, 39)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text               = "Wait " .. START_DELAY .. "s"
countdownLabel.TextColor3         = Color3.fromRGB(255, 200, 100)
countdownLabel.Font               = Enum.Font.Gotham
countdownLabel.TextSize           = 10
countdownLabel.TextXAlignment     = Enum.TextXAlignment.Left
countdownLabel.Parent             = frame

-- Прогресс val к 39
local valBarBg = Instance.new("Frame")
valBarBg.Size            = UDim2.new(1, -10, 0, 5)
valBarBg.Position        = UDim2.new(0, 5, 0, 55)
valBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
valBarBg.BorderSizePixel = 0
valBarBg.Parent          = frame

local valBarFill = Instance.new("Frame")
valBarFill.Size            = UDim2.new(0, 0, 1, 0)
valBarFill.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
valBarFill.BorderSizePixel = 0
valBarFill.Parent          = valBarBg

local valBarLabel = Instance.new("TextLabel")
valBarLabel.Size               = UDim2.new(1, -10, 0, 12)
valBarLabel.Position           = UDim2.new(0, 5, 0, 62)
valBarLabel.BackgroundTransparency = 1
valBarLabel.Text               = "val: 0/39"
valBarLabel.TextColor3         = Color3.fromRGB(180, 180, 180)
valBarLabel.Font               = Enum.Font.Code
valBarLabel.TextSize           = 9
valBarLabel.TextXAlignment     = Enum.TextXAlignment.Left
valBarLabel.Parent             = frame

-- Таймер бар
local timerBarBg = Instance.new("Frame")
timerBarBg.Size            = UDim2.new(1, -10, 0, 6)
timerBarBg.Position        = UDim2.new(0, 5, 0, 76)
timerBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
timerBarBg.BorderSizePixel = 0
timerBarBg.Visible         = false
timerBarBg.Parent          = frame

local timerBarFill = Instance.new("Frame")
timerBarFill.Size            = UDim2.new(1, 0, 1, 0)
timerBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
timerBarFill.BorderSizePixel = 0
timerBarFill.Parent          = timerBarBg

local timerLabel = Instance.new("TextLabel")
timerLabel.Size               = UDim2.new(1, -10, 0, 12)
timerLabel.Position           = UDim2.new(0, 5, 0, 84)
timerLabel.BackgroundTransparency = 1
timerLabel.Text               = ""
timerLabel.TextColor3         = Color3.fromRGB(255, 220, 100)
timerLabel.Font               = Enum.Font.Code
timerLabel.TextSize           = 9
timerLabel.TextXAlignment     = Enum.TextXAlignment.Left
timerLabel.Visible            = false
timerLabel.Parent             = frame

local fbLabel = Instance.new("TextLabel")
fbLabel.Size               = UDim2.new(1, -10, 0, 12)
fbLabel.Position           = UDim2.new(0, 5, 0, 98)
fbLabel.BackgroundTransparency = 1
fbLabel.Text               = "FB: --"
fbLabel.TextColor3         = Color3.fromRGB(150, 200, 255)
fbLabel.Font               = Enum.Font.Code
fbLabel.TextSize           = 9
fbLabel.TextXAlignment     = Enum.TextXAlignment.Left
fbLabel.Parent             = frame

local predictLabel = Instance.new("TextLabel")
predictLabel.Size               = UDim2.new(1, -10, 0, 12)
predictLabel.Position           = UDim2.new(0, 5, 0, 111)
predictLabel.BackgroundTransparency = 1
predictLabel.Text               = "Predict: --"
predictLabel.TextColor3         = Color3.fromRGB(200, 200, 100)
predictLabel.Font               = Enum.Font.Code
predictLabel.TextSize           = 9
predictLabel.TextXAlignment     = Enum.TextXAlignment.Left
predictLabel.Parent             = frame

-- Лог 5 строк
local logLabels = {}
for i = 1, 5 do
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -10, 0, 11)
    lbl.Position           = UDim2.new(0, 5, 0, 123 + (i - 1) * 11)
    lbl.BackgroundTransparency = 1
    lbl.Text               = ""
    lbl.Font               = Enum.Font.Code
    lbl.TextSize           = 9
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.TextColor3         = Color3.fromRGB(
        180 - (i - 1) * 25,
        255 - (i - 1) * 35,
        180 - (i - 1) * 25
    )
    lbl.Parent = frame
    logLabels[i] = lbl
end

-- Кнопки
local btnReset = Instance.new("TextButton")
btnReset.Size            = UDim2.new(0, 70, 0, 18)
btnReset.Position        = UDim2.new(0, 5, 0, 180)
btnReset.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
btnReset.Text            = "Reset Q→1"
btnReset.TextColor3      = Color3.fromRGB(255, 255, 255)
btnReset.Font            = Enum.Font.Gotham
btnReset.TextSize        = 9
btnReset.BorderSizePixel = 0
btnReset.Parent          = frame

local btnForce = Instance.new("TextButton")
btnForce.Size            = UDim2.new(0, 65, 0, 18)
btnForce.Position        = UDim2.new(0, 80, 0, 180)
btnForce.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
btnForce.Text            = "Force Me"
btnForce.TextColor3      = Color3.fromRGB(255, 255, 255)
btnForce.Font            = Enum.Font.Gotham
btnForce.TextSize        = 9
btnForce.BorderSizePixel = 0
btnForce.Parent          = frame

local btnPause = Instance.new("TextButton")
btnPause.Size            = UDim2.new(0, 70, 0, 18)
btnPause.Position        = UDim2.new(0, 150, 0, 180)
btnPause.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
btnPause.Text            = "Pause"
btnPause.TextColor3      = Color3.fromRGB(255, 255, 255)
btnPause.Font            = Enum.Font.Gotham
btnPause.TextSize        = 9
btnPause.BorderSizePixel = 0
btnPause.Parent          = frame

local btnStatus = Instance.new("TextButton")
btnStatus.Size            = UDim2.new(1, -10, 0, 18)
btnStatus.Position        = UDim2.new(0, 5, 0, 203)
btnStatus.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
btnStatus.Text            = "▼ All Accounts Status"
btnStatus.TextColor3      = Color3.fromRGB(200, 200, 255)
btnStatus.Font            = Enum.Font.Gotham
btnStatus.TextSize        = 9
btnStatus.BorderSizePixel = 0
btnStatus.Parent          = frame

-- ====================== ПАНЕЛЬ СТАТУСОВ ВСЕХ АККАУНТОВ ======================
local statusPanel = Instance.new("Frame")
statusPanel.Size                  = UDim2.new(0, 250, 0, 30 + TOTAL_ACCOUNTS * 28)
statusPanel.Position              = UDim2.new(0, 38, 0, 10 + TOTAL_ACCOUNTS * (GUI_FULL_HEIGHT + 10) + 10)
statusPanel.BackgroundColor3      = Color3.fromRGB(20, 20, 30)
statusPanel.BackgroundTransparency = 0.2
statusPanel.BorderSizePixel       = 0
statusPanel.Visible               = false
statusPanel.Active                = true
statusPanel.Draggable             = true
statusPanel.Parent                = screenGui

local statusPanelTitle = Instance.new("TextLabel")
statusPanelTitle.Size               = UDim2.new(1, 0, 0, 20)
statusPanelTitle.Position           = UDim2.new(0, 0, 0, 0)
statusPanelTitle.BackgroundColor3   = Color3.fromRGB(40, 40, 60)
statusPanelTitle.BackgroundTransparency = 0
statusPanelTitle.Text               = "ALL ACCOUNTS"
statusPanelTitle.TextColor3         = Color3.fromRGB(200, 200, 255)
statusPanelTitle.Font               = Enum.Font.GothamBold
statusPanelTitle.TextSize           = 10
statusPanelTitle.BorderSizePixel    = 0
statusPanelTitle.Parent             = statusPanel

-- Строки для каждого аккаунта в панели
local accountRows = {}
for i = 1, TOTAL_ACCOUNTS do
    local row = Instance.new("Frame")
    row.Size            = UDim2.new(1, -10, 0, 24)
    row.Position        = UDim2.new(0, 5, 0, 22 + (i - 1) * 26)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel = 0
    row.Parent          = statusPanel

    local dot = Instance.new("Frame")
    dot.Size            = UDim2.new(0, 8, 0, 8)
    dot.Position        = UDim2.new(0, 4, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    dot.BorderSizePixel = 0
    dot.Parent          = row

    local label = Instance.new("TextLabel")
    label.Size               = UDim2.new(0, 120, 1, 0)
    label.Position           = UDim2.new(0, 16, 0, 0)
    label.BackgroundTransparency = 1
    label.Text               = "#" .. i .. " val:-- Q:--"
    label.TextColor3         = Color3.fromRGB(200, 200, 200)
    label.Font               = Enum.Font.Code
    label.TextSize           = 9
    label.TextXAlignment     = Enum.TextXAlignment.Left
    label.Parent             = row

    local barBg = Instance.new("Frame")
    barBg.Size            = UDim2.new(0, 80, 0, 5)
    barBg.Position        = UDim2.new(0, 140, 0.5, -2)
    barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    barBg.BorderSizePixel = 0
    barBg.Parent          = row

    local barFill = Instance.new("Frame")
    barFill.Size            = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    barFill.BorderSizePixel = 0
    barFill.Parent          = barBg

    accountRows[i] = {row = row, dot = dot, label = label, barFill = barFill}
end

-- ====================== ЛОГ ======================
local function addLog(msg)
    table.insert(logLines, 1, msg)
    if #logLines > 5 then
        table.remove(logLines, 6)
    end
    for i = 1, 5 do
        logLabels[i].Text = logLines[i] or ""
    end
end

local function setIndicatorColor(color)
    indicator.BackgroundColor3      = color
    toggleIndicator.BackgroundColor3 = color
end

-- ====================== GUI ОБНОВЛЕНИЕ ======================
local function updateValBar()
    local progress = math.max(0, math.min(1, lastValue / 39))
    valBarFill.Size = UDim2.new(progress, 0, 1, 0)

    if progress < 0.5 then
        valBarFill.BackgroundColor3 = Color3.fromRGB(255, math.floor(progress * 2 * 200), 0)
    elseif progress < 0.9 then
        valBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    else
        valBarFill.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
    end

    valBarLabel.Text = string.format("val: %d/39", lastValue)
end

local function updatePredictLabel()
    if lastValue >= 39 then
        predictLabel.Text      = "Predict: READY ✓"
        predictLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
        return
    end
    if #valueHistory < PREDICT_MIN_POINTS then
        predictLabel.Text      = "Predict: collecting..."
        predictLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        return
    end

    local oldest   = valueHistory[1]
    local newest   = valueHistory[#valueHistory]
    local timeDiff = newest.t - oldest.t
    if timeDiff < 1 then
        predictLabel.Text = "Predict: --"
        return
    end

    local rate = (newest.v - oldest.v) / timeDiff
    if rate <= 0 then
        predictLabel.Text       = "Predict: NOT growing ✗"
        predictLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end

    local needed     = 39 - lastValue
    local timeNeeded = needed / rate
    if timeNeeded < PREDICT_MAX_NEEDED then
        predictLabel.Text       = string.format("Predict: ~%.0fs to 39 ✓", timeNeeded)
        predictLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        predictLabel.Text       = string.format("Predict: ~%.0fs — SKIP ✗", timeNeeded)
        predictLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
    end
end

local function updateGUI()
    statusLabel.Text = string.format(
        "Val:%d | Q:%s | #%d%s",
        lastValue, tostring(cachedQueue), ACCOUNT_ID,
        isPaused and " [PAUSED]" or ""
    )
    throwLabel.Text = "Throws: " .. totalThrows
    fbLabel.Text    = fbStatus

    updateValBar()
    updatePredictLabel()

    local isMyQueue = (cachedQueue == ACCOUNT_ID)

    if isPaused then
        setIndicatorColor(Color3.fromRGB(100, 100, 200))
        countdownLabel.Text = "⏸ PAUSED — waiting Resume"
    elseif comboLock then
        setIndicatorColor(Color3.fromRGB(255, 200, 0))
        if waitingCoconutGone then
            countdownLabel.Text = "COCONUT — WAIT GONE..."
        elseif comboTimerActive then
            local remaining = math.max(0, comboTimerDuration - (tick() - comboTimerStart))
            countdownLabel.Text = string.format("COMBO DELAY: %.0fs", remaining)
        else
            countdownLabel.Text = "COMBO IN PROGRESS"
        end
    elseif chainWatchActive then
        setIndicatorColor(Color3.fromRGB(255, 50, 50))
        countdownLabel.Text = "CHAIN DEAD — RECOVERING"
    elseif skipping then
        setIndicatorColor(Color3.fromRGB(255, 100, 0))
        countdownLabel.Text = "SKIPPING..."
    elseif cycleActive then
        setIndicatorColor(Color3.fromRGB(0, 150, 255))
        countdownLabel.Text = "CYCLE ACTIVE"
    elseif isMyQueue and coconutPresent then
        setIndicatorColor(Color3.fromRGB(255, 200, 0))
        countdownLabel.Text = "WATCHING COCONUT..."
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
        countdownLabel.Text = "Watching (Q=" .. tostring(cachedQueue) .. ")"
    end
end

-- ====================== ОБНОВЛЕНИЕ ПАНЕЛИ СТАТУСОВ ======================
task.spawn(function()
    while true do
        task.wait(2)
        if not statusPanelOpen then continue end

        local body = readAllStatuses()
        if not body then continue end

        for i = 1, TOTAL_ACCOUNTS do
            local row = accountRows[i]
            if not row then continue end

            -- Парсим JSON для аккаунта i
            local section = body:match('"' .. i .. '":%s*(%b{})')
            if section then
                local val   = tonumber(section:match('"value":(%d+)')) or 0
                local queue = section:match('"queue":"?(%w+)"?') == "true"
                local lock  = section:match('"lock":"?(%w+)"?') == "true"
                local state = section:match('"state":"([^"]+)"') or "idle"

                -- Цвет индикатора
                local dotColor
                if lock then
                    dotColor = Color3.fromRGB(255, 200, 0)
                elseif queue then
                    dotColor = Color3.fromRGB(0, 255, 0)
                else
                    dotColor = Color3.fromRGB(100, 100, 100)
                end
                row.dot.BackgroundColor3 = dotColor

                -- Текст
                local qMark = queue and " Q" or "  "
                row.label.Text = string.format("#%d val:%d%s [%s]", i, val, qMark, state)

                -- Прогресс бар
                local prog = math.max(0, math.min(1, val / 39))
                row.barFill.Size = UDim2.new(prog, 0, 1, 0)
                if prog >= 1 then
                    row.barFill.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
                elseif prog > 0.7 then
                    row.barFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                else
                    row.barFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
                end
            else
                row.label.Text               = "#" .. i .. " offline"
                row.dot.BackgroundColor3     = Color3.fromRGB(60, 60, 60)
                row.barFill.Size             = UDim2.new(0, 0, 1, 0)
            end
        end
    end
end)

-- ====================== ТАЙМЕР ======================
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
            timerLabel.Text = string.format("[%s%s] %.0fs",
                string.rep("█", bars), string.rep("░", 18 - bars), remaining)

            if not guiMinimized then updateGUI() end
        end
    end
end)

-- ====================== GUI КНОПКИ ======================
toggleBtn.MouseButton1Click:Connect(function()
    guiMinimized  = not guiMinimized
    frame.Visible = not guiMinimized
    toggleBtn.Text = guiMinimized and tostring(ACCOUNT_ID) or "×"
    if not guiMinimized then
        timerBarBg.Visible = comboTimerActive
        timerLabel.Visible = comboTimerActive
        updateGUI()
    end
end)

btnStatus.MouseButton1Click:Connect(function()
    statusPanelOpen        = not statusPanelOpen
    statusPanel.Visible    = statusPanelOpen
    btnStatus.Text         = statusPanelOpen and "▲ All Accounts Status" or "▼ All Accounts Status"
end)

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

-- ====================== СБРОС СОСТОЯНИЙ ======================
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
    addLog("RESET: " .. (reason or "manual"))
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
    addLog("THROW! #" .. totalThrows)
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
    if coconutPresent then return end
    if isPaused then return end

    skipping     = true
    skippingTime = tick()
    updateGUI()

    task.spawn(function()
        task.wait(SKIP_DELAY)

        if lastValue == 39 then
            addLog("Skip aborted — got 39")
            skipping, skippingTime = false, 0
            updateGUI()
            return
        end
        if coconutPresent then
            addLog("Skip aborted — coconut appeared")
            skipping, skippingTime = false, 0
            updateGUI()
            return
        end

        -- Свежая проверка очереди перед записью
        local current = readQueueFresh()
        if current ~= ACCOUNT_ID then
            addLog("Skip aborted — queue moved")
            skipping, skippingTime = false, 0
            updateGUI()
            return
        end

        -- Умная очередь — ищем у кого есть 39
        local targetQ = findAccountWith39()
        writeQueue(targetQ)
        coconutSeenWhileMyQueue = false
        addLog("Skip → Acc" .. targetQ .. " (smart)")
        skipping, skippingTime = false, 0
        updateGUI()
    end)
end

-- ====================== ОСНОВНОЕ КОМБО ======================
local function startCombo()
    -- Семафор — защита от двойного запуска
    if comboStarting or comboLock or not canThrow then return end
    if isPaused then return end

    -- Предсказание — если точно не успеем набрать 39 — скипаем
    if lastValue ~= 39 then
        if not predictWillReach39() then
            addLog("Predict: skip — won't reach 39")
            skipTurn()
            return
        end
        -- Если предсказание говорит что успеем — всё равно скипаем
        -- потому что сейчас нет 39 (только ждём если predict уверен)
        addLog("No 39 (val=" .. lastValue .. ") → skip")
        skipTurn()
        return
    end

    -- Атомарно устанавливаем семафор ДО любых async операций
    comboStarting = true

    -- Свежая проверка очереди
    local freshQ = readQueueFresh()
    if freshQ ~= ACCOUNT_ID then
        addLog("startCombo: queue changed → abort")
        comboStarting = false
        return
    end

    comboLock               = true
    comboStarting           = false
    comboLockTime           = tick()
    coconutSeenWhileMyQueue = false
    updateGUI()

    comboThread = task.spawn(function()
        local ok, err = pcall(function()

            local timerDone = false
            while not timerDone do

                -- Проверки перед запуском таймера
                if isPaused then
                    addLog("Abort: paused before timer")
                    return
                end
                if cachedQueue ~= ACCOUNT_ID then
                    addLog("Abort: queue changed before timer")
                    return
                end
                if lastValue ~= 39 then
                    addLog("Abort: value dropped before timer")
                    writeQueue(findAccountWith39())
                    return
                end

                -- Запускаем COMBO_DELAY
                addLog("Coconut gone → COMBO_DELAY " .. COMBO_DELAY .. "s")
                writeMyStatus("timer")
                startGuiTimer(COMBO_DELAY)

                local timerStart  = tick()
                local interrupted = false

                while (tick() - timerStart) < COMBO_DELAY do
                    task.wait(COCONUT_SCAN)

                    -- Пауза — отменяем
                    if isPaused then
                        stopGuiTimer()
                        addLog("Abort: paused during timer")
                        writeQueue(findAccountWith39())
                        return
                    end

                    -- Кокос появился — прерываем таймер
                    -- НО только если это НЕ наш цикл
                    if coconutPresent and not ourCycleActive then
                        interrupted = true
                        break
                    end

                    -- Value упало — abort
                    if lastValue ~= 39 then
                        stopGuiTimer()
                        addLog("Abort: value dropped during timer")
                        writeQueue(findAccountWith39())
                        return
                    end

                    -- Очередь ушла — abort
                    if cachedQueue ~= ACCOUNT_ID then
                        stopGuiTimer()
                        addLog("Abort: queue changed during timer")
                        return
                    end
                end

                stopGuiTimer()

                if interrupted then
                    -- Чужой кокос во время таймера — ждём пока уйдёт и перезапускаем
                    waitingCoconutGone = true
                    updateGUI()
                    addLog("Coconut mid-timer → wait then restart")
                    while coconutPresent do task.wait(COCONUT_SCAN) end
                    waitingCoconutGone = false
                    addLog("Coconut gone → RESTART COMBO_DELAY")
                else
                    timerDone = true
                end
            end

            -- Финальные проверки — свежее чтение очереди перед броском
            local freshQueue = readQueueFresh()
            if freshQueue ~= ACCOUNT_ID then
                addLog("Abort final: queue changed")
                return
            end
            if lastValue ~= 39 then
                addLog("Abort final: value changed")
                writeQueue(findAccountWith39())
                return
            end
            if isPaused then
                addLog("Abort final: paused")
                writeQueue(findAccountWith39())
                return
            end

            -- Бросок — один батч запрос вместо трёх
            local nextQ = findAccountWith39()
            SpawnCoconut()
            writeThrowBatch(nextQ)
            coconutSeenWhileMyQueue = false
            writeMyStatus("threw")
            addLog("Threw! Queue → Acc" .. nextQ)
            startCycle(CYCLE_COUNT)
        end)

        waitingCoconutGone = false
        stopGuiTimer()

        if not ok then
            addLog("Combo err: " .. tostring(err))
            local current = readQueueFresh()
            if current == ACCOUNT_ID then
                writeQueue(findAccountWith39())
                addLog("Err fallback → Acc" .. getNextQueue())
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
task.spawn(function()
    while true do
        local present   = false
        local particles = Workspace:FindFirstChild("Particles")
        if particles then
            present = particles:FindFirstChild("ComboCoconut", true) ~= nil
        end

        if present and not coconutPresent then
            coconutPresent = true
            if cachedQueue == ACCOUNT_ID then
                coconutSeenWhileMyQueue = true
            end
            addLog("Coconut appeared")
            updateGUI()

        elseif not present and coconutPresent then
            coconutPresent = false
            addLog("Coconut gone")

            if cachedQueue == ACCOUNT_ID
                and canThrow
                and not comboLock
                and not comboStarting
                and not cycleActive
                and not skipping
                and not isPaused
            then
                addLog("My turn → startCombo")
                startCombo()
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
        if canThrow and not comboLock and not comboStarting and not skipping and not cycleActive then
            readQueue()
            updateGUI()
            if cachedQueue == ACCOUNT_ID then
                if coconutPresent then
                    coconutSeenWhileMyQueue = true
                    addLog("My turn, coconut — watching...")
                elseif lastValue == 39 then
                    addLog("My turn, no coconut, val=39 → startCombo")
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

                -- Value упало ниже 39 во время комбо — отменяем
                if value < 39 and comboLock and comboThread then
                    pcall(task.cancel, comboThread)
                    waitingCoconutGone = false
                    stopGuiTimer()
                    comboThread   = nil
                    comboLock     = false
                    comboLockTime = 0
                    task.spawn(function()
                        local current = readQueueFresh()
                        if current == ACCOUNT_ID then
                            local target = findAccountWith39()
                            writeQueue(target)
                            addLog("Val<39 cancelled → Acc" .. target)
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
        btnPause.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        btnPause.Text             = "Resume"

        -- Отменяем всё активное
        if comboThread then pcall(task.cancel, comboThread); comboThread = nil end
        stopGuiTimer()
        comboLock      = false
        comboStarting  = false
        comboLockTime  = 0
        cycleActive    = false
        ourCycleActive = false
        skipping       = false
        waitingCoconutGone = false

        -- Если наша очередь — передаём следующему
        task.spawn(function()
            local current = readQueueFresh()
            if current == ACCOUNT_ID then
                writeQueue(getNextQueue())
                addLog("Paused → queue released to Acc" .. getNextQueue())
            end
            writeMyStatus("paused")
            updateGUI()
        end)

        addLog("⏸ PAUSED — all throws stopped")
    else
        btnPause.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        btnPause.Text             = "Pause"
        addLog("▶ RESUMED")
        writeMyStatus("idle")
        updateGUI()
    end
end)

-- ====================== ПОЛЛИНГ ГЛОБАЛЬНОЙ ПАУЗЫ ======================
-- Все аккаунты читают флаг паузы с Firebase
task.spawn(function()
    while not canThrow do task.wait(1) end
    while true do
        task.wait(3)
        local serverPaused = readPauseFlag()
        if serverPaused ~= isPaused then
            isPaused = serverPaused
            if isPaused then
                -- Другой аккаунт нажал паузу
                if comboThread then pcall(task.cancel, comboThread); comboThread = nil end
                stopGuiTimer()
                comboLock      = false
                comboStarting  = false
                cycleActive    = false
                ourCycleActive = false
                skipping       = false
                btnPause.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
                btnPause.Text             = "Resume"
                addLog("⏸ Remote pause received")
            else
                btnPause.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
                btnPause.Text             = "Pause"
                addLog("▶ Remote resume received")
            end
            updateGUI()
        end
    end
end)

-- ====================== CHARACTERADDED — МГНОВЕННЫЙ СБРОС ======================
local function onCharacterAdded(char)
    addLog("Respawn detected — resetting states")
    resetAllStates("respawn")

    -- Ждём загрузки персонажа
    task.wait(2)

    -- Переэкипируем аксессуар
    hasCanister  = false
    hasPorcelain = false
    if lastValue <= 34 then
        equipCanister()
    else
        equipPorcelain()
    end

    -- Если очередь была наша — передаём
    task.spawn(function()
        local current = readQueueFresh()
        if current == ACCOUNT_ID then
            writeQueue(getNextQueue())
            addLog("Respawn: queue released → Acc" .. getNextQueue())
        end
        updateGUI()
    end)
end

LP.CharacterAdded:Connect(onCharacterAdded)
if LP.Character then
    -- Персонаж уже есть при запуске
    task.spawn(function()
        task.wait(1)
        if lastValue <= 34 then equipCanister() else equipPorcelain() end
    end)
end

-- ====================== ЗАДЕРЖКА СТАРТА ======================
task.spawn(function()
    local startJitter = (ACCOUNT_ID - 1) * 3
    task.wait(startJitter)

    -- Синхронизация серверного времени
    addLog("Syncing server time...")
    if syncServerTime() then
        addLog("Time delta: " .. serverTimeDelta .. "s")
    else
        addLog("Time sync failed — using local time")
    end

    while tick() - startTime < START_DELAY do
        if tick() - lastQueueCheck > 3 then readQueue() end
        updateGUI()
        task.wait(0.5)
    end

    task.wait((ACCOUNT_ID - 1) * 1.5)
    readQueue()

    local lastUpdate = readLastUpdateTime()
    if lastUpdate and (serverNow() - lastUpdate) > 300 then
        if ACCOUNT_ID == 1 then
            writeQueue(1)
            addLog("Queue idle >5min — reset to 1")
        end
    end

    local fbLastThrow = readLastThrowTime()
    if fbLastThrow and fbLastThrow > 0 then
        lastThrowTime = math.max(lastThrowTime, fbLastThrow)
    end

    -- Проверяем глобальную паузу при старте
    isPaused = readPauseFlag()
    if isPaused then
        btnPause.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        btnPause.Text             = "Resume"
        addLog("Started in PAUSED state")
    end

    writeMyValue(lastValue)
    writeMyStatus("idle")

    canThrow = true
    addLog("START — jitter=" .. startJitter .. "s | delta=" .. serverTimeDelta .. "s")
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
                addLog("WD: queue dead → reset to 1")
            else
                addLog("WD: queue dead → wait #1")
            end
        end

        if comboLock and comboLockTime > 0 and (tick() - comboLockTime) > 300 then
            addLog("WD: comboLock stuck → reset")
            resetAllStates("WD comboLock")
            task.spawn(function()
                local current = readQueueFresh()
                if current == ACCOUNT_ID then
                    writeQueue(findAccountWith39())
                    addLog("WD: queue released")
                end
                updateGUI()
            end)
        end

        local maxCycleTime = CYCLE_DELAY + (CYCLE_COUNT * COCONUT_INTERVAL) * 2
        if cycleActive and cycleStartTime > 0 and (tick() - cycleStartTime) > maxCycleTime then
            addLog("WD: cycleActive stuck → reset")
            cycleActive    = false
            ourCycleActive = false
            cycleStartTime = 0
            updateGUI()
        end

        if skipping and skippingTime > 0 and (tick() - skippingTime) > 30 then
            addLog("WD: skipping stuck → reset")
            skipping, skippingTime = false, 0
            updateGUI()
        end

        -- Переписываем статус и своё value периодически
        writeMyValue(lastValue)
        writeMyStatus(comboLock and "lock" or cycleActive and "cycle" or "idle")

        local char = LP.Character
        if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            addLog("WD: char dead/missing")
            resetAllStates("WD char dead")
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
        if not canThrow or isPaused then continue end

        local fbLastThrow = readLastThrowTime()
        if fbLastThrow and fbLastThrow > 0 then
            lastThrowTime = math.max(lastThrowTime, fbLastThrow)
        end

        local timeSinceThrow = serverNow() - lastThrowTime

        if timeSinceThrow > CHAIN_TIMEOUT
            and not comboLock
            and not comboStarting
            and not cycleActive
            and not skipping
            and not chainWatchActive
            and not isPaused
            and cachedQueue == ACCOUNT_ID
            and lastValue == 39
        then
            chainWatchActive = true
            updateGUI()
            addLog("Chain dead " .. timeSinceThrow .. "s → recovering")

            task.spawn(function()
                if coconutPresent then
                    addLog("Chain: waiting coconut gone...")
                    while coconutPresent do task.wait(COCONUT_SCAN) end
                end

                chainWatchActive = false

                if canThrow and not comboLock and not cycleActive
                    and cachedQueue == ACCOUNT_ID and lastValue == 39 and not isPaused
                then
                    coconutSeenWhileMyQueue = false
                    addLog("Chain: → startCombo")
                    startCombo()
                else
                    addLog("Chain: conditions changed — abort")
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
        local before = gcinfo()
        collectgarbage("collect")
        local after = gcinfo()
        addLog(string.format("GC: freed %d KB", before - after))
    end
end)

-- ====================== КНОПКИ ======================
btnReset.MouseButton1Click:Connect(function()
    resetAllStates("manual reset")
    writeQueue(1)
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
addLog("Wait " .. START_DELAY .. "s | #" .. ACCOUNT_ID)
