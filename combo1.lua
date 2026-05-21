-- ================================================
-- Combo Coconut Script
-- ================================================
local ACCOUNT_ID = 1
local TOTAL_ACCOUNTS = 3
local LOGS = false

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

local function log(...)
    if LOGS then print(...) end
end

-- ================================================
-- Файловая синхронизация очереди между аккаунтами
-- ACC 1 пишет сигналы, ACC 2/3 их читают.
-- Работает на большинстве executors через writefile/readfile.
-- ================================================
local SYNC_FILE = "combo_coconut_queue.txt"
local hasFileAPI = (typeof(writefile) == "function") and (typeof(readfile) == "function") and (typeof(isfile) == "function")

local function writeSync(counter)
    if not hasFileAPI then return end
    pcall(function()
        -- формат: counter|timestamp
        writefile(SYNC_FILE, tostring(counter) .. "|" .. tostring(tick()))
    end)
end

local function readSync()
    if not hasFileAPI then return nil, 0 end
    if not isfile(SYNC_FILE) then return nil, 0 end
    local ok, content = pcall(readfile, SYNC_FILE)
    if not ok or not content then return nil, 0 end
    local c, t = string.match(content, "^(%d+)|([%d%.]+)$")
    if not c then return nil, 0 end
    return tonumber(c), tonumber(t) or 0
end

local lastValue = -1
local coconutActive = false
local currentAccessory = "none"
local hasCanister = false
local hasPorcelain = false
local spawnTimer = nil
local comboCounter = 0
local skipUsed = false
local lastCoconutThrow = 0
local COCONUT_COOLDOWN = 1.0

-- Анти-дубль
local lastQueueAdvanceAt = 0
local QUEUE_ADVANCE_DEBOUNCE = 3.0
local lastAdvanceReason = "-"

-- Стоп-значения
local STOP_VALUES = {4, 9, 14, 19, 24, 29, 34}
local reachedStopValue = false

local function isStopValue(v)
    for _, sv in ipairs(STOP_VALUES) do
        if v == sv then return true end
    end
    return false
end

local function advanceQueue(reason)
    local now = tick()
    if now - lastQueueAdvanceAt < QUEUE_ADVANCE_DEBOUNCE then
        return
    end
    lastQueueAdvanceAt = now
    lastAdvanceReason = tostring(reason)

    if skipUsed then
        skipUsed = false
        log("[ACC " .. ACCOUNT_ID .. "] SKIP collected")
        return
    end

    comboCounter = comboCounter + 1
    if comboCounter > TOTAL_ACCOUNTS then
        comboCounter = 1
    end
    log("[ACC " .. ACCOUNT_ID .. "] Queue -> " .. comboCounter .. " (" .. tostring(reason) .. ")")

    -- ACC 1 публикует новое значение для остальных
    if ACCOUNT_ID == 1 then
        writeSync(comboCounter)
    end
end

-- ================================================
-- Интерфейс
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboCounter_" .. ACCOUNT_ID
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 170, 0, 160)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * 170)
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
label.Size = UDim2.new(1, 0, 0, 30)
label.Position = UDim2.new(0, 0, 0, 0)
label.BackgroundTransparency = 1
label.Text = "0"
label.TextColor3 = Color3.fromRGB(255, 200, 100)
label.Font = Enum.Font.GothamBold
label.TextSize = 22
label.Parent = frame

local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(1, 0, 0, 16)
idLabel.Position = UDim2.new(0, 0, 0, 28)
idLabel.BackgroundTransparency = 1
idLabel.Text = "ACC #" .. ACCOUNT_ID
idLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
idLabel.Font = Enum.Font.Gotham
idLabel.TextSize = 10
idLabel.Parent = frame

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, 0, 0, 14)
valueLabel.Position = UDim2.new(0, 0, 0, 44)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "value: -"
valueLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
valueLabel.Font = Enum.Font.Gotham
valueLabel.TextSize = 10
valueLabel.Parent = frame

local stopLabel = Instance.new("TextLabel")
stopLabel.Size = UDim2.new(1, 0, 0, 14)
stopLabel.Position = UDim2.new(0, 0, 0, 58)
stopLabel.BackgroundTransparency = 1
stopLabel.Text = ""
stopLabel.TextColor3 = Color3.fromRGB(80, 180, 80)
stopLabel.Font = Enum.Font.Gotham
stopLabel.TextSize = 9
stopLabel.Parent = frame

-- Отладочные строки (видны на экране, консоль не нужна)
local dbg1 = Instance.new("TextLabel")
dbg1.Size = UDim2.new(1, -4, 0, 12)
dbg1.Position = UDim2.new(0, 2, 0, 74)
dbg1.BackgroundTransparency = 1
dbg1.Text = ""
dbg1.TextColor3 = Color3.fromRGB(120, 160, 200)
dbg1.Font = Enum.Font.Gotham
dbg1.TextSize = 9
dbg1.TextXAlignment = Enum.TextXAlignment.Left
dbg1.Parent = frame

local dbg2 = Instance.new("TextLabel")
dbg2.Size = UDim2.new(1, -4, 0, 12)
dbg2.Position = UDim2.new(0, 2, 0, 86)
dbg2.BackgroundTransparency = 1
dbg2.Text = ""
dbg2.TextColor3 = Color3.fromRGB(120, 160, 200)
dbg2.Font = Enum.Font.Gotham
dbg2.TextSize = 9
dbg2.TextXAlignment = Enum.TextXAlignment.Left
dbg2.Parent = frame

local dbg3 = Instance.new("TextLabel")
dbg3.Size = UDim2.new(1, -4, 0, 12)
dbg3.Position = UDim2.new(0, 2, 0, 98)
dbg3.BackgroundTransparency = 1
dbg3.Text = ""
dbg3.TextColor3 = Color3.fromRGB(120, 160, 200)
dbg3.Font = Enum.Font.Gotham
dbg3.TextSize = 9
dbg3.TextXAlignment = Enum.TextXAlignment.Left
dbg3.Parent = frame

local skipBtn = Instance.new("TextButton")
skipBtn.Size = UDim2.new(1, -16, 0, 26)
skipBtn.Position = UDim2.new(0, 8, 0, 116)
skipBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
skipBtn.BorderSizePixel = 0
skipBtn.Text = "SKIP & COMBO"
skipBtn.TextColor3 = Color3.fromRGB(150, 150, 170)
skipBtn.TextSize = 10
skipBtn.Font = Enum.Font.GothamBold
skipBtn.AutoButtonColor = true
skipBtn.Visible = (ACCOUNT_ID == 1)
skipBtn.Parent = frame

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 6)
skipCorner.Parent = skipBtn

local function updateSkipButton()
    if ACCOUNT_ID ~= 1 then return end
    if lastValue == 39 then
        skipBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
        skipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        skipBtn.Text = "SKIP -> NEXT"
    else
        skipBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        skipBtn.TextColor3 = Color3.fromRGB(80, 80, 90)
        skipBtn.Text = "wait 39..."
    end
end

local function updateCounterDisplay()
    label.Text = tostring(comboCounter)
    valueLabel.Text = "value: " .. tostring(lastValue)

    if reachedStopValue then
        stopLabel.Text = "STOP (wait 0)"
        stopLabel.TextColor3 = Color3.fromRGB(200, 150, 50)
    else
        stopLabel.Text = "throwing coconuts"
        stopLabel.TextColor3 = Color3.fromRGB(80, 180, 80)
    end

    if comboCounter == ACCOUNT_ID then
        frame.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        label.TextColor3 = Color3.fromRGB(100, 255, 100)
        idLabel.Text = ">>> MY TURN <<<"
    else
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        label.TextColor3 = Color3.fromRGB(255, 200, 100)
        idLabel.Text = "ACC #" .. ACCOUNT_ID .. " (wait " .. comboCounter .. ")"
    end

    -- Отладка прямо в GUI
    dbg1.Text = "reason: " .. lastAdvanceReason
    dbg2.Text = "fileAPI: " .. tostring(hasFileAPI)
        .. " | parts: " .. tostring(Workspace:FindFirstChild("Particles") ~= nil)
    local fc, ft = readSync()
    if fc then
        dbg3.Text = "sync: " .. fc .. " (" .. string.format("%.0f", tick() - ft) .. "s ago)"
    else
        dbg3.Text = "sync: -"
    end

    updateSkipButton()
end

-- ================================================
-- Функции экипировки
-- ================================================
function EquipCanister()
    if hasCanister then return end
    local args = {
        "Equip",
        { Category = "Accessory", Type = "Coconut Canister" }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    currentAccessory = "canister"
    hasCanister = true
    hasPorcelain = false
end

function EquipPorcelain()
    if hasPorcelain then return end
    local args = {
        "Equip",
        { Category = "Accessory", Type = "Porcelain Port-O-Hive" }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    currentAccessory = "porcelain"
    hasPorcelain = true
    hasCanister = false
end

function SpawnCoconut(isCombo)
    local args = { { Name = "Coconut" } }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args))
    if isCombo then
        task.spawn(function()
            task.wait(11)
            SpawnCoconut(false)
        end)
    else
        lastCoconutThrow = tick()
    end
end

function TryThrowCoconut()
    if tick() - lastCoconutThrow < COCONUT_COOLDOWN then return false end
    SpawnCoconut(false)
    return true
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
-- Детектор частицы (опрос 0.1 сек)
-- ================================================
spawn(function()
    while true do
        local present = IsComboCoconutPresent()
        if present and not coconutActive then
            coconutActive = true
            advanceQueue("particle-appeared")
            updateCounterDisplay()
        elseif not present and coconutActive then
            coconutActive = false
        end
        task.wait(0.1)
    end
end)

-- ChildAdded на Particles
spawn(function()
    local particles = Workspace:WaitForChild("Particles", 30)
    if not particles then return end
    particles.ChildAdded:Connect(function(obj)
        if obj.Name == "ComboCoconut" then
            advanceQueue("child-added")
            coconutActive = true
            updateCounterDisplay()
        end
    end)
end)

-- ================================================
-- Слушатель файла синхронизации (только не-ACC1)
-- ACC 2/3 берут counter напрямую из файла, который пишет ACC 1
-- ================================================
if ACCOUNT_ID ~= 1 and hasFileAPI then
    spawn(function()
        local lastSeenCounter = nil
        while true do
            local c, _ = readSync()
            if c and c ~= lastSeenCounter then
                lastSeenCounter = c
                if c ~= comboCounter then
                    comboCounter = c
                    lastAdvanceReason = "file-sync"
                    lastQueueAdvanceAt = tick()  -- блокируем повторный сдвиг от других триггеров
                    updateCounterDisplay()
                end
            end
            task.wait(0.2)
        end
    end)
end

-- ================================================
-- Таймер комбо (12 сек)
-- ================================================
local function startSpawnTimer()
    if spawnTimer then
        task.cancel(spawnTimer)
        spawnTimer = nil
    end
    spawnTimer = task.spawn(function()
        task.wait(12)
        if lastValue == 39 and comboCounter == ACCOUNT_ID then
            SpawnCoconut(true)
        end
        spawnTimer = nil
    end)
end

-- ================================================
-- Кнопка SKIP (только ACC 1)
-- ================================================
skipBtn.MouseButton1Click:Connect(function()
    if ACCOUNT_ID ~= 1 then return end
    if lastValue ~= 39 then return end

    if spawnTimer then
        task.cancel(spawnTimer)
        spawnTimer = nil
    end

    comboCounter = comboCounter + 1
    if comboCounter > TOTAL_ACCOUNTS then
        comboCounter = 1
    end
    skipUsed = false
    lastQueueAdvanceAt = tick()
    lastAdvanceReason = "skip-button"
    coconutActive = true

    -- Публикуем для остальных аккаунтов
    writeSync(comboCounter)

    updateCounterDisplay()
    SpawnCoconut(true)
end)

-- ================================================
-- Слушатель PlayerAbilityEvent
-- ================================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                local prevValue = lastValue

                if prevValue == 39 and value < 39 then
                    advanceQueue("value-drop-from-39")
                end

                if value == 0 then
                    reachedStopValue = false
                end

                if value < 39 and spawnTimer then
                    task.cancel(spawnTimer)
                    spawnTimer = nil
                end

                if value >= 0 and value <= 34 then
                    EquipCanister()
                end
                if value >= 35 and value <= 39 then
                    EquipPorcelain()
                end

                if value >= 0 and value <= 34 then
                    if isStopValue(value) then
                        if not reachedStopValue then
                            reachedStopValue = true
                        end
                    elseif not reachedStopValue then
                        TryThrowCoconut()
                    end
                end

                if value == 39 and comboCounter == ACCOUNT_ID and not spawnTimer then
                    startSpawnTimer()
                end

                lastValue = value
                updateCounterDisplay()
            end
        end
    end
end)

-- Фоновый кокосо-кидатель
spawn(function()
    while true do
        if lastValue >= 0 and lastValue <= 34
           and not isStopValue(lastValue)
           and not reachedStopValue then
            TryThrowCoconut()
        end
        task.wait(1)
    end
end)

-- Фоллбэк экипировки канистры
spawn(function()
    while true do
        if lastValue >= 0 and lastValue <= 34 and not hasCanister then
            EquipCanister()
        end
        task.wait(5)
    end
end)

-- Обновление отладочных строк раз в секунду
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
    Set = function(n)
        comboCounter = n
        if ACCOUNT_ID == 1 then writeSync(n) end
        updateCounterDisplay()
    end,

    Reset = function()
        comboCounter = 0
        reachedStopValue = false
        skipUsed = false
        coconutActive = false
        lastQueueAdvanceAt = 0
        if ACCOUNT_ID == 1 then writeSync(0) end
        updateCounterDisplay()
    end,

    Skip = function()
        if lastValue == 39 then
            if spawnTimer then task.cancel(spawnTimer) spawnTimer = nil end
            comboCounter = comboCounter + 1
            if comboCounter > TOTAL_ACCOUNTS then comboCounter = 1 end
            skipUsed = false
            lastQueueAdvanceAt = tick()
            lastAdvanceReason = "skip-cmd"
            coconutActive = true
            if ACCOUNT_ID == 1 then writeSync(comboCounter) end
            updateCounterDisplay()
            SpawnCoconut(true)
        end
    end,

    Advance = function()
        lastQueueAdvanceAt = 0
        advanceQueue("manual")
        updateCounterDisplay()
    end,
}

updateCounterDisplay()
