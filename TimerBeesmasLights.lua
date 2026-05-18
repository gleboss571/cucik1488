local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local COOLDOWN_TIME = 20
local TARGET_AMOUNT = 25
local LIFESPAN_MULTIPLIER = 1.24
local COLLECT_THRESHOLD_FACTOR = 0.9
local CD_CHECK_INTERVAL = 3
local LOGS = false

local tokenBaseLifetimes = {
    [65867881]=4,[1629649299]=4,[1442700745]=24,[1629547638]=4,
    [2499514197]=8,[2499540966]=8,[1472256444]=8,[253828517]=8,
    [1442764904]=4,[1442725244]=4,[1442859163]=4,[3877732821]=4,
    [1442863423]=4,[4519523935]=4,[4528379338]=4,[4519549299]=4,
    [4528208186]=8,[4528414666]=8,[8083436978]=4,[8083943936]=24,
    [8173559749]=8,[1671281844]=12,[1104415222]=4,[1753904608]=16,
    [2319100769]=8,[2305425690]=8,[1472532912]=15,[1472491940]=15,
    [1472425802]=15,[2032949183]=15,[1472580249]=15,[1489734171]=15,
    [1874564120]=12,[1874704640]=24,[1874692303]=24,[177997841]=4,
    [1839454544]=4,[3582501342]=24,[3582519526]=24,[5877939956]=12,
    [5877998606]=16,[2000457501]=8,[6077288982]=16,
}

local IGNORE_IDS = {
    [6087969886]=true,[1472135114]=true,[1952682401]=true,
    [2028574353]=true,[1952796032]=true,[2028453802]=true,
    [1952740625]=true,[1838129169]=true,
}

local currentCount = 0
local timerActive = false
local endTime = 0
local tokenSpawnTimes = {}
local lastCooldownState = nil

-- CD Checker
local function findBeesmasLights(data, visited, depth)
    visited = visited or {}
    depth = depth or 0
    if depth > 20 then return nil end
    if type(data) ~= "table" then return nil end
    if visited[data] then return nil end
    visited[data] = true
    local direct = rawget(data, "Beesmas Lights")
    if type(direct) == "table" then return direct end
    for k, v in pairs(data) do
        if k == "Beesmas Lights" and type(v) == "table" then return v end
        if type(v) == "table" then
            local found = findBeesmasLights(v, visited, depth + 1)
            if found then return found end
        end
    end
    return nil
end

local function getBeesmasLightsCD()
    local ev = ReplicatedStorage:FindFirstChild("Events")
    local fn = ev and ev:FindFirstChild("RetrievePlayerStats")
    if not fn then return nil end
    local ok, stats = pcall(function() return fn:InvokeServer() end)
    if not ok or type(stats) ~= "table" then return nil end
    local bl = findBeesmasLights(stats)
    if type(bl) ~= "table" then return nil end
    return bl.OnCooldown
end

local function getTextureId(texture)
    local id = texture:match("id=(%d+)") or texture:match("rbxassetid://(%d+)")
    return id and tonumber(id)
end

-- GUI (компактная)
local sg = Instance.new("ScreenGui")
sg.Name = "BeesmasLightTracker"
sg.Parent = PlayerGui
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 180, 0, 100)
main.Position = UDim2.new(0.5, -90, 0.92, -50)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
main.BackgroundTransparency = 0.15
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = sg
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 6)

local cdLabel = Instance.new("TextLabel")
cdLabel.Size = UDim2.new(1, -24, 0, 16)
cdLabel.Position = UDim2.new(0, 6, 0, 4)
cdLabel.BackgroundTransparency = 1
cdLabel.Text = "⏳ ..."
cdLabel.TextColor3 = Color3.new(1, 1, 1)
cdLabel.Font = Enum.Font.GothamBold
cdLabel.TextSize = 11
cdLabel.TextXAlignment = Enum.TextXAlignment.Left
cdLabel.Parent = main

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 16, 0, 16)
closeBtn.Position = UDim2.new(1, -20, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 10
closeBtn.Parent = main
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
closeBtn.MouseButton1Click:Connect(function() sg.Enabled = false end)

local counterLabel = Instance.new("TextLabel")
counterLabel.Size = UDim2.new(1, 0, 0, 22)
counterLabel.Position = UDim2.new(0, 0, 0, 22)
counterLabel.BackgroundTransparency = 1
counterLabel.Text = "0/" .. TARGET_AMOUNT
counterLabel.TextColor3 = Color3.new(1, 1, 1)
counterLabel.Font = Enum.Font.GothamBold
counterLabel.TextSize = 18
counterLabel.Parent = main

local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(0.88, 0, 0, 8)
progressBg.Position = UDim2.new(0.06, 0, 0, 48)
progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
progressBg.BorderSizePixel = 0
progressBg.Parent = main
Instance.new("UICorner", progressBg).CornerRadius = UDim.new(0, 4)

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg
Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 4)

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, 0, 0, 28)
timerLabel.Position = UDim2.new(0, 0, 0, 60)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = ""
timerLabel.TextColor3 = Color3.fromRGB(255, 200, 60)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 20
timerLabel.Parent = main

local function updateDisplay()
    counterLabel.Text = currentCount .. "/" .. TARGET_AMOUNT
    progressBar.Size = UDim2.new(math.clamp(currentCount / TARGET_AMOUNT, 0, 1), 0, 1, 0)
    if timerActive then
        local rem = endTime - tick()
        if rem <= 0 then
            timerLabel.Text = ""
            timerActive = false
        else
            timerLabel.Text = string.format("%.1fs", rem)
        end
    else
        timerLabel.Text = ""
    end
end

-- Токены
Workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "C" and obj:IsA("BasePart") then
        local front = obj:FindFirstChild("FrontDecal")
        if front and front:IsA("Decal") then
            local id = getTextureId(front.Texture)
            if id and not IGNORE_IDS[id] and tokenBaseLifetimes[id] then
                tokenSpawnTimes[obj] = tick()
            end
        end
    end
end)

game.DescendantRemoving:Connect(function(obj)
    if timerActive then return end
    local spawnTime = tokenSpawnTimes[obj]
    if spawnTime then
        local front = obj:FindFirstChild("FrontDecal")
        local id = front and getTextureId(front.Texture) or 0
        local base = tokenBaseLifetimes[id]
        if base then
            local full = base * LIFESPAN_MULTIPLIER
            local life = tick() - spawnTime
            if life < full * COLLECT_THRESHOLD_FACTOR then
                currentCount = currentCount + 1
                if currentCount >= TARGET_AMOUNT then
                    currentCount = 0
                    tokenSpawnTimes = {}
                end
            end
        end
        tokenSpawnTimes[obj] = nil
        updateDisplay()
    end
end)

-- CD Loop
task.spawn(function()
    while true do
        local onCooldown = getBeesmasLightsCD()
        if onCooldown == true then
            cdLabel.Text = "🔴 КД"
            cdLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            if lastCooldownState ~= true then
                if LOGS then print("⚠️ Beesmas Lights КД! Таймер " .. COOLDOWN_TIME .. "с") end
                timerActive = true
                endTime = tick() + COOLDOWN_TIME
                currentCount = 0
                tokenSpawnTimes = {}
                updateDisplay()
            end
        elseif onCooldown == false then
            cdLabel.Text = "🟢 ГОТОВ"
            cdLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
        else
            cdLabel.Text = "❌ ?"
            cdLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
        end
        lastCooldownState = onCooldown
        task.wait(CD_CHECK_INTERVAL)
    end
end)

RunService.Heartbeat:Connect(updateDisplay)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F9 then
        sg.Enabled = not sg.Enabled
    end
end)

updateDisplay()
if LOGS then print("✅ Beesmas Light Tracker | F9 = toggle") end
