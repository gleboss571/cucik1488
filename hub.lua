--[[
   Simple Script Hub GUI
   Кнопка X закрывает окно. После выполнения скрипта кнопка зеленеет.
--]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ====================== ДОБАВЛЯЙТЕ СВОИ СКРИПТЫ СЮДА ======================
local SCRIPTS = {
    { Name = "Suslik", Url = "https://raw.githubusercontent.com/gleboss571/cucik1488/refs/heads/main/suslik.lua" },
    { Name = "Timer Beesmas Lights", Url = "https://raw.githubusercontent.com/gleboss571/cucik1488/refs/heads/main/TimerBeesmasLights.lua" },
    { Name = "ATL", Url = "https://raw.githubusercontent.com/gleboss571/cucik1488/refs/heads/main/atl.lua" },
    { Name = "Auto Splinker", Url = "https://raw.githubusercontent.com/gleboss571/cucik1488/refs/heads/main/autosplinker.lua" },
    { Name = "Backpack Combo", Url = "https://raw.githubusercontent.com/gleboss571/cucik1488/refs/heads/main/backpackCombo.lua" },
    { Name = "Blooms", Url = "https://raw.githubusercontent.com/gleboss571/cucik1488/refs/heads/main/blooms.lua" },
    -- { Name = "Новый скрипт", Url = "https://..." },
}
-- ========================================================================

-- Создаём GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScriptHub"
screenGui.Parent = playerGui

-- Высота фрейма: 30 (заголовок) + 10 отступ + кол-во кнопок * 38
local buttonCount = #SCRIPTS
local frameHeight = 40 + buttonCount * 40
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, frameHeight)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 30)   -- оставляем место для крестика справа
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "🐝 Script Hub"
title.TextColor3 = Color3.fromRGB(255, 200, 100)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = mainFrame

-- Кнопка закрытия (X)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -28, 0, 6)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
closeButton.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Parent = mainFrame

closeButton.Activated:Connect(function()
    screenGui:Destroy()
end)

-- Храним состояние кнопок (выполнена или нет)
local executed = {}

for i, scriptData in ipairs(SCRIPTS) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 32)
    button.Position = UDim2.new(0, 10, 0, 35 + (i - 1) * 40)
    button.Text = scriptData.Name
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.Parent = mainFrame

    -- Обработчик нажатия
    button.Activated:Connect(function()
        if executed[i] then return end
        executed[i] = true
        button.TextColor3 = Color3.fromRGB(100, 255, 100)
        button.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptData.Url))()
        end)
        if not success then
            warn("Ошибка выполнения " .. scriptData.Name .. ": " .. tostring(err))
            button.Text = scriptData.Name .. " (ошибка)"
            button.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end
