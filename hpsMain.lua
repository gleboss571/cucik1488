--[[
   Account 1: Main HPS Monitor + Firebase (2T порог)
   Центрированный GUI, Delta-совместим.
--]]

local WEB_APP_URL = "https://fuflik1-e9325-default-rtdb.europe-west1.firebasedatabase.app"
local CHECK_INTERVAL = 1
local HPS_THRESHOLD = 2e12  -- 2 триллиона

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- =============== GUI (центрирован) ===============
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = playerGui

local label = Instance.new("TextLabel")
label.Parent = screenGui
label.Size = UDim2.new(0, 200, 0, 30)
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.new(0.5, 0, 0.5, 0)
label.BackgroundTransparency = 0.3
label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.Code
label.TextSize = 14

-- =============== Функции ===============
local function sendState(hps, boostActive)
    local payload = HttpService:JSONEncode({
        boostActive = boostActive,
        farmer = 0,
        hps = math.floor(hps)
    })
    request({
        Url = WEB_APP_URL .. "/state.json",
        Method = "PUT",
        Headers = { ["Content-Type"] = "application/json" },
        Body = payload
    })
end

local function getHPS()
    local label = player.PlayerGui:FindFirstChild("ScreenGui", true)
    if label then
        label = label:FindFirstChild("MeterHUD", true)
        if label then
            label = label:FindFirstChild("HoneyMeter", true)
            if label then
                label = label:FindFirstChild("Bar", true)
                if label then
                    label = label:FindFirstChild("PerSecLabel")
                    if label then
                        local text = label.Text
                        local num, suffix = string.match(text, "([%d%.]+)%s*(%a?)")
                        num = tonumber(num) or 0
                        local mult = { K=1e3, M=1e6, B=1e9, T=1e12, Qd=1e15 }
                        return num * (mult[suffix] or 1)
                    end
                end
            end
        end
    end
    return 0
end

-- =============== Главный цикл ===============
task.spawn(function()
    while true do
        local hps = getHPS()
        local boostActive = (hps >= HPS_THRESHOLD)
        sendState(hps, boostActive)
        label.Text = string.format("HPS: %.1fT | Boost: %s", hps/1e12, boostActive and "ON" or "OFF")
        task.wait(CHECK_INTERVAL)
    end
end)
