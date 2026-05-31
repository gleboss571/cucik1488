--[[
   ALT Combo Coconut Thrower (по флагу Coconut Canister на мейне)
   Бросает комбо-кокос при value == 39, если флаг активен.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local MAIN_ACCOUNT_NAME = "Kukurudza_dontreal"   -- точное имя мейн-аккаунта
local ACCOUNT_ID = 2                    -- ID этого альта (1, 2, 3...)
local SCAN_INTERVAL = 1                 -- проверка флага каждую секунду

local LP = Players.LocalPlayer
local Events = require(ReplicatedStorage.Events)

local scorchingActive = false
local lastComboValue = -1
local totalThrows = 0

-- =============== GUI ===============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboThrower_" .. ACCOUNT_ID
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 42)
frame.Position = UDim2.new(0, 10, 0, 10 + (ACCOUNT_ID-1)*60)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,0,0,24)
statusLabel.Position = UDim2.new(0,0,0,4)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Val: - | Flag: false"
statusLabel.TextColor3 = Color3.fromRGB(255,255,255)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.Parent = frame

local throwLabel = Instance.new("TextLabel")
throwLabel.Size = UDim2.new(1,0,0,14)
throwLabel.Position = UDim2.new(0,0,0,28)
throwLabel.BackgroundTransparency = 1
throwLabel.Text = "Throws: 0"
throwLabel.TextColor3 = Color3.fromRGB(200,200,200)
throwLabel.Font = Enum.Font.Gotham
throwLabel.TextSize = 10
throwLabel.Parent = frame

local function updateGUI()
    statusLabel.Text = string.format("Val: %d | Flag: %s", lastComboValue, tostring(scorchingActive))
    throwLabel.Text = "Throws: " .. totalThrows
end

-- =============== ПРОВЕРКА ФЛАГА ===============
local function checkMainCoconut()
    local mainPlayer = Players:FindFirstChild(MAIN_ACCOUNT_NAME)
    if not mainPlayer then return false end
    local char = mainPlayer.Character
    if not char then return false end
    for _, child in ipairs(char:GetChildren()) do
        if child.Name == "Coconut Canister" then
            return true
        end
    end
    return false
end

task.spawn(function()
    while true do
        local newFlag = checkMainCoconut()
        if newFlag ~= scorchingActive then
            scorchingActive = newFlag
            updateGUI()
        end
        task.wait(SCAN_INTERVAL)
    end
end)

-- =============== СЛУШАТЕЛЬ COMBO COCONUTS ===============
Events.ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                if value ~= lastComboValue then
                    lastComboValue = value
                    updateGUI()
                    if value == 39 and scorchingActive then
                        local delay = ACCOUNT_ID * 0.5
                        task.spawn(function()
                            task.wait(delay)
                            if lastComboValue == 39 and scorchingActive then
                                -- проверяем, не появился ли уже комбо-кокос
                                local found = false
                                local particles = Workspace:FindFirstChild("Particles")
                                if particles then
                                    for _, obj in ipairs(particles:GetChildren()) do
                                        if obj.Name == "ComboCoconut" then found = true; break end
                                    end
                                end
                                if not found then
                                    ReplicatedStorage.Events.PlayerActivesCommand:FireServer({ Name = "Coconut" })
                                    totalThrows = totalThrows + 1
                                    updateGUI()
                                end
                            end
                        end)
                    end
                end
            end
        end
    end
end)

updateGUI()
