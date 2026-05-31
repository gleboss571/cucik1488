--[[
   Account 2/3: Объединённый помощник (Jelly Beans + Gumdrops)
   Jelly Beans – по флагу Coconut Canister у мейна, с чередующимися кулдаунами.
   Gumdrops – через Firebase при boostActive=true.
   Delta-совместимый.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- ====================== НАСТРОЙКИ ======================
local MY_ID = 3                      -- 2 или 3
local TARGET_NAME = "Kukurudza_dontreal"  -- имя мейна
local WEB_APP_URL = "https://fuflik1-e9325-default-rtdb.europe-west1.firebasedatabase.app"

-- Jelly Beans
local JB_COOLDOWNS = { 3 * 60, 4 * 60 }  -- кулдауны в секундах (меняйте числа)

-- Gumdrops
local GUMMY_THRESHOLD = 20
local GUMMY_MAX = 30
local MORPH_DURATION = 10

local CHECK_INTERVAL = 1  -- общий интервал опроса
-- =====================================================

local Events = ReplicatedStorage:WaitForChild("Events")
local PlayerAbilityEvent = Events:WaitForChild("PlayerAbilityEvent")
local PlayerActivesCommand = Events:WaitForChild("PlayerActivesCommand")

-- =============== JELLY BEANS ===============
local lastJBThrow = 0
local jbCooldownIndex = 1
local jbTotalThrows = 0

local function throwJellyBeans()
    PlayerActivesCommand:FireServer({ Name = "Jelly Beans" })
end

local function checkFlag()
    local main = Players:FindFirstChild(TARGET_NAME)
    if not main then return false end
    local char = main.Character
    if not char then return false end
    return char:FindFirstChild("Coconut Canister") ~= nil
end

-- =============== GUMMY MORPH ===============
local gummyValue = 0
PlayerAbilityEvent.OnClientEvent:Connect(function(data)
    for tag, info in pairs(data) do
        if tag == "Gummy Morph" and info.Action == "Update" then
            gummyValue = info.Values and info.Values[1] or 0
        end
    end
end)

local function readState()
    local ok, result = pcall(function()
        return request({
            Url = WEB_APP_URL .. "/state.json",
            Method = "GET"
        })
    end)
    if ok and result and result.Body then
        return HttpService:JSONDecode(result.Body)
    end
    return nil
end

local function writeKey(key, value)
    request({
        Url = WEB_APP_URL .. "/state/" .. key .. ".json",
        Method = "PUT",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(value)
    })
end

local function useGumdrops()
    PlayerActivesCommand:FireServer({ Name = "Gumdrops" })
end

local gummyTurn = false
local morphEndTime = 0

-- =============== GUI ===============
local playerGui = LP:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Helper" .. MY_ID
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 110)
frame.Position = UDim2.new(0, 10, 0, 10 + (MY_ID-1)*120)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,18)
title.Position = UDim2.new(0,0,0,2)
title.BackgroundTransparency = 1
title.Text = "Acc " .. MY_ID
title.TextColor3 = Color3.fromRGB(255,200,100)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.Parent = frame

-- Статус Jelly Beans
local jbStatus = Instance.new("TextLabel")
jbStatus.Size = UDim2.new(1,-10,0,16)
jbStatus.Position = UDim2.new(0,5,0,22)
jbStatus.BackgroundTransparency = 1
jbStatus.Text = "JB: ожидание"
jbStatus.TextColor3 = Color3.fromRGB(200,200,200)
jbStatus.Font = Enum.Font.Code
jbStatus.TextSize = 11
jbStatus.Parent = frame

-- Статус Gumdrops
local gdStatus = Instance.new("TextLabel")
gdStatus.Size = UDim2.new(1,-10,0,16)
gdStatus.Position = UDim2.new(0,5,0,40)
gdStatus.BackgroundTransparency = 1
gdStatus.Text = "GD: ожидание"
gdStatus.TextColor3 = Color3.fromRGB(200,200,200)
gdStatus.Font = Enum.Font.Code
gdStatus.TextSize = 11
gdStatus.Parent = frame

-- Лог
local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1,-10,0,32)
logLabel.Position = UDim2.new(0,5,0,58)
logLabel.BackgroundTransparency = 1
logLabel.Text = ""
logLabel.TextColor3 = Color3.fromRGB(180,255,180)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 10
logLabel.TextWrapped = true
logLabel.Parent = frame

local function addLog(msg)
    logLabel.Text = msg
end

-- =============== ГЛАВНЫЙ ЦИКЛ ===============
task.spawn(function()
    while true do
        -- Jelly Beans
        local flag = checkFlag()
        local jbOk = false
        if flag and tick() - lastJBThrow >= JB_COOLDOWNS[jbCooldownIndex] then
            throwJellyBeans()
            jbTotalThrows = jbTotalThrows + 1
            lastJBThrow = tick()
            jbOk = true
            addLog("JB бросок! След. кд: " .. JB_COOLDOWNS[jbCooldownIndex == 1 and 2 or 1]/60 .. " мин")
            jbCooldownIndex = jbCooldownIndex == 1 and 2 or 1
        end

        -- Обновление статуса JB
        local jbRemaining = 0
        if lastJBThrow > 0 then
            jbRemaining = JB_COOLDOWNS[jbCooldownIndex] - (tick() - lastJBThrow)
            if jbRemaining < 0 then jbRemaining = 0 end
        end
        jbStatus.Text = string.format("JB: %s | кд %d:%02d | бросков %d",
            flag and "актив" or "нет флага",
            math.floor(jbRemaining/60), math.floor(jbRemaining%60), jbTotalThrows)

        -- Gumdrops
        local state = readState()
        local gdOk = false
        if state then
            local boostActive = state.boostActive
            local currentFarmer = state.farmer

            if gummyTurn then
                if tick() >= morphEndTime then
                    gummyTurn = false
                    writeKey("farmer", 0)
                else
                    if gummyValue < GUMMY_MAX then
                        useGumdrops()
                        gdOk = true
                        task.wait(2)
                    else
                        task.wait(1)
                    end
                end
            elseif (currentFarmer == 0 or currentFarmer == nil) and boostActive then
                if gummyValue >= GUMMY_THRESHOLD then
                    writeKey("farmer", MY_ID)
                    task.wait(0.5)
                    local check = readState()
                    if check and check.farmer == MY_ID then
                        gummyTurn = true
                        morphEndTime = tick() + MORPH_DURATION
                        useGumdrops()
                        gdOk = true
                        addLog("GD захват роли")
                        task.wait(2)
                    end
                end
            end

            gdStatus.Text = string.format("GD: %s | стеки %d | роль %d",
                gummyTurn and "моя" or (boostActive and "жду" or "нет буста"),
                gummyValue,
                currentFarmer or 0)
        else
            gdStatus.Text = "GD: нет связи с Firebase"
        end

        if not gummyTurn then
            task.wait(CHECK_INTERVAL)
        end
    end
end)
