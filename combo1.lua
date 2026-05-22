-- ================================================
-- Combo Coconut Script (v3 — упрощённый)
-- ================================================
local ACCOUNT_ID = 1     -- поменяй на 2 или 3
local TOTAL_ACCOUNTS = 3

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local lastValue = -1
local lastValueChangeTime = tick()
local coconutActive = false
local hasCanister = false
local hasPorcelain = false
local spawnTimer = nil
local comboCounter = 0
local totalThrows = 0

local COCONUTS_PER_CYCLE = 4
local COCONUT_INTERVAL = 10

-- Состояние цикла
local cycleActive = false
local thrownThisCycle = 0
local firstUpdateReceived = false

-- ================================================
-- Интерфейс
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboCounter_" .. ACCOUNT_ID
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 160, 0, 68)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID - 1) * 78)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local bigLabel = Instance.new("TextLabel")
bigLabel.Size = UDim2.new(1, 0, 0, 26)
bigLabel.Position = UDim2.new(0, 0, 0, 2)
bigLabel.BackgroundTransparency = 1
bigLabel.Text = "0"
bigLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
bigLabel.Font = Enum.Font.GothamBold
bigLabel.TextSize = 22
bigLabel.Parent = frame

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
infoLabel.Position = UDim2.new(0, 3, 0, 42)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(140, 200, 255)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 10
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.Parent = frame

local cycleStatusLabel = Instance.new("TextLabel")
cycleStatusLabel.Size = UDim2.new(1, -6, 0, 14)
cycleStatusLabel.Position = UDim2.new(0, 3, 0, 54)
cycleStatusLabel.BackgroundTransparency = 1
cycleStatusLabel.TextColor3 = Color3.fromRGB(200, 180, 100)
cycleStatusLabel.Font = Enum.Font.Gotham
cycleStatusLabel.TextSize = 10
cycleStatusLabel.TextXAlignment = Enum.TextXAlignment.Center
cycleStatusLabel.Parent = frame

local function updateCounterDisplay()
    bigLabel.Text = tostring(comboCounter)

    if comboCounter == ACCOUNT_ID then
        frame.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        bigLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        idLabel.Text = ">>> MY TURN <<<"
    else
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        bigLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        idLabel.Text = "ACC #" .. ACCOUNT_ID .. " (wait " .. comboCounter .. ")"
    end

    local age = math.floor(tick() - lastValueChangeTime)
    infoLabel.Text = "v: " .. tostring(lastValue) .. " (" .. age .. "s)  t:" .. totalThrows
    cycleStatusLabel.Text = "cycle: " .. thrownThisCycle .. "/" .. COCONUTS_PER_CYCLE
        .. (cycleActive and " RUN" or "")
end

-- ================================================
-- Экипировка
-- ================================================
function EquipCanister()
    if hasCanister then return end
    local args = {"Equip", { Category = "Accessory", Type = "Coconut Canister" }}
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    hasCanister = true
    hasPorcelain = false
end

function EquipPorcelain()
    if hasPorcelain then return end
    local args = {"Equip", { Category = "Accessory", Type = "Porcelain Port-O-Hive" }}
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    hasPorcelain = true
    hasCanister = false
end

-- ================================================
-- Бросок кокоса
-- ================================================
function SpawnCoconut()
    local args = { { Name = "Coconut" } }
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args))
    totalThrows = totalThrows + 1
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
-- ГЛАВНЫЙ ЦИКЛ (упрощённый)
-- Каждую секунду проверяет value.
-- Когда value == 0 — кидает 4 кокоса с интервалом 10 сек.
-- ================================================
task.spawn(function()
    while true do
        -- Ждём первый апдейт от сервера, потом ждём value == 0
        if firstUpdateReceived and lastValue == 0 and not cycleActive then
            cycleActive = true
            thrownThisCycle = 0

            for i = 1, COCONUTS_PER_CYCLE do
                -- Перед каждым броском проверяем — value всё ещё 0?
                -- Если value ушло выше — значит другие кинули, пропускаем
                if lastValue > 0 then break end

                SpawnCoconut()
                thrownThisCycle = i
                updateCounterDisplay()

                if i < COCONUTS_PER_CYCLE then
                    task.wait(COCONUT_INTERVAL)
                end
            end

            cycleActive = false
        end

        task.wait(1)
    end
end)

-- ================================================
-- Детектор ComboCoconut — очередь аккаунтов
-- ================================================
task.spawn(function()
    while true do
        local present = IsComboCoconutPresent()
        if present and not coconutActive then
            coconutActive = true
        elseif not present and coconutActive then
            coconutActive = false

            comboCounter = comboCounter + 1
            if comboCounter > TOTAL_ACCOUNTS then comboCounter = 1 end

            -- НЕ ставим lastValue = 0 вручную!
            -- Пусть listener получит реальное значение от сервера.
            lastValueChangeTime = tick()
            updateCounterDisplay()
        end
        task.wait(0.5)
    end
end)

-- ================================================
-- Таймер комбо 13 сек (value == 39, мой ход)
-- ================================================
local function startSpawnTimer()
    if spawnTimer then task.cancel(spawnTimer) spawnTimer = nil end
    spawnTimer = task.spawn(function()
        task.wait(13)
        if lastValue == 39 and comboCounter == ACCOUNT_ID then
            SpawnCoconut()
        end
        spawnTimer = nil
    end)
end

-- ================================================
-- Слушатель обновлений value
-- ================================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0

                if value ~= lastValue then
                    lastValueChangeTime = tick()
                end

                firstUpdateReceived = true

                if value < 39 and spawnTimer then
                    task.cancel(spawnTimer)
                    spawnTimer = nil
                end

                if value <= 34 then
                    EquipCanister()
                else
                    EquipPorcelain()
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

-- Фоллбэк канистры
task.spawn(function()
    EquipCanister()
    while true do
        if (lastValue == -1) or (lastValue >= 0 and lastValue <= 34) then
            if not hasCanister then
                EquipCanister()
            end
        end
        task.wait(1)
    end
end)

-- Обновление дисплея
task.spawn(function()
    while true do
        updateCounterDisplay()
        task.wait(1)
    end
end)

-- ВОТЧДОГ: если value застряло на 39 больше 30 сек
task.spawn(function()
    while true do
        task.wait(5)
        if lastValue == 39 and (tick() - lastValueChangeTime) > 30 then
            lastValue = 0
            lastValueChangeTime = tick()
        end
    end
end)

updateCounterDisplay()
