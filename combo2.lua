--[[
   ALT Combo Coconut Thrower (исправлен GUI + FireServer)
   Совместим с Delta, задержка старта 10 сек.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local MAIN_ACCOUNT_NAME = "Kukurudza_dontreal"  -- ИМЯ МЕЙНА
local ACCOUNT_ID = 2   -- измените на 1, 2 или 3
local START_DELAY = 10
local SCAN_INTERVAL = 0.5

local LP = Players.LocalPlayer

-- Прямой доступ к событиям
local Events = ReplicatedStorage:WaitForChild("Events")
local PlayerAbilityEvent = Events:WaitForChild("PlayerAbilityEvent")
local PlayerActivesCommand = Events:WaitForChild("PlayerActivesCommand")
local ItemPackageEvent = Events:WaitForChild("ItemPackageEvent")

local scorchingActive = false
local lastComboValue = -1
local totalThrows = 0
local currentBackpack = nil
local throwScheduled = false
local canThrow = false
local startTime = tick()   -- ВАЖНО: ранее отсутствовало

-- =============== ПРОСТОЙ GUI (PlayerGui) ===============
local playerGui = LP:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboThrower_" .. ACCOUNT_ID
screenGui.Parent = playerGui   -- ИСПОЛЬЗУЕМ PlayerGui

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

-- Лог (одна строка)
local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1,-10,0,18)
logLabel.Position = UDim2.new(0,5,0,64)
logLabel.BackgroundTransparency = 1
logLabel.Text = ""
logLabel.TextColor3 = Color3.fromRGB(180,255,180)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 10
logLabel.Parent = frame

local function addLog(msg)
    logLabel.Text = msg   -- только последнее сообщение
end

local function updateGUI()
    statusLabel.Text = string.format("Val: %d | Flag: %s", lastComboValue, tostring(scorchingActive))
    throwLabel.Text = "Throws: " .. totalThrows
    if not canThrow then
        local remaining = math.max(0, START_DELAY - (tick() - startTime))
        countdownLabel.Text = "Wait " .. math.ceil(remaining) .. "s"
    else
        countdownLabel.Text = ""
    end
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
    if currentBackpack == "canister" then return end
    equipAccessory("Coconut Canister")
    currentBackpack = "canister"
    addLog("Canister")
end

local function equipPorcelain()
    if currentBackpack == "porcelain" then return end
    equipAccessory("Porcelain Port-O-Hive")
    currentBackpack = "porcelain"
    addLog("Porcelain")
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
            if scorchingActive and lastComboValue == 39 and canThrow then
                tryThrow()
            end
        end
        task.wait(SCAN_INTERVAL)
    end
end)

-- =============== БРОСОК ===============
local function tryThrow()
    if not scorchingActive or lastComboValue ~= 39 or throwScheduled or not canThrow then return end
    throwScheduled = true
    local delay = ACCOUNT_ID * 0.5
    addLog("Planned " .. delay .. "s")
    task.spawn(function()
        task.wait(delay)
        throwScheduled = false
        if lastComboValue == 39 and scorchingActive and canThrow then
            local found = false
            local particles = Workspace:FindFirstChild("Particles")
            if particles then
                for _, obj in ipairs(particles:GetChildren()) do
                    if obj.Name == "ComboCoconut" then found = true; break end
                end
            end
            if not found then
                addLog("THROW!")
                PlayerActivesCommand:FireServer({ { Name = "Coconut" } })   -- ИСПРАВЛЕН ФОРМАТ
                totalThrows = totalThrows + 1
                updateGUI()
            else
                addLog("Already exists")
            end
        else
            addLog("Cancel: val=" .. lastComboValue .. " f=" .. tostring(scorchingActive))
        end
    end)
end

-- =============== СЛУШАТЕЛЬ ===============
PlayerAbilityEvent.OnClientEvent:Connect(function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                if lastComboValue == -1 then
                    lastComboValue = value
                    if value <= 34 then equipCanister() else equipPorcelain() end
                    updateGUI()
                    addLog("Init " .. value)
                    if value == 39 and scorchingActive and canThrow then tryThrow() end
                    return
                end
                if value ~= lastComboValue then
                    lastComboValue = value
                    updateGUI()
                    addLog(value .. (value <= 34 and " Can" or " Porc"))
                    if value <= 34 then equipCanister() else equipPorcelain() end
                    if value ~= 39 then throwScheduled = false end
                    if value == 39 and scorchingActive and canThrow then tryThrow() end
                end
            end
        end
    end
end)

-- Задержка старта
task.spawn(function()
    while tick() - startTime < START_DELAY do
        updateGUI()
        task.wait(0.5)
    end
    canThrow = true
    addLog("START")
    if lastComboValue == 39 and scorchingActive then
        tryThrow()
    end
end)

updateGUI()
addLog("Wait " .. START_DELAY .. "s")
