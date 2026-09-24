--[[
   Script Hub GUI v2.0
   - Чекбоксы перед каждым скриптом
   - Кнопка "▶ Run Checked" запускает выбранные с интервалом 1с
   - Кнопка X закрывает окно
   - Выполненный скрипт зеленеет
--]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ====================== СКРИПТЫ ======================
local SCRIPTS = {
    { Name = "Timer Beesmas Lights", Url = "https://raw.githubusercontent.com/gleboss571/cucik1488/refs/heads/main/TimerBeesmasLights.lua" },
    { Name = "ATL", Url = "https://raw.githubusercontent.com/gleboss571/cucik1488/refs/heads/main/atl.lua" },
    { Name = "Auto Splinker", Url = "https://raw.githubusercontent.com/gleboss571/cucik1488/refs/heads/main/autosplinker.lua" },
    { Name = "Blooms", Url = "https://raw.githubusercontent.com/gleboss571/cucik1488/refs/heads/main/blooms.lua" },
    { Name = "Gumdrops", Url = "https://github.com/gleboss571/cucik1488/raw/refs/heads/main/gumdropss.lua" },
    { Name = "Inspire", Url = "https://github.com/gleboss571/cucik1488/raw/refs/heads/main/inspire.lua" },
}
-- =====================================================

local BUTTON_H = 32
local BUTTON_GAP = 6
local HEADER_H = 40
local BATCH_BTN_H = 36
local PADDING = 10

local buttonCount = #SCRIPTS
local frameHeight = HEADER_H + (buttonCount * (BUTTON_H + BUTTON_GAP)) + BATCH_BTN_H + PADDING * 2

-- Удаляем старый GUI если есть
local oldGui = playerGui:FindFirstChild("ScriptHub")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScriptHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, frameHeight)
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
title.Size = UDim2.new(1, -30, 0, 30)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "🐝 Script Hub"
title.TextColor3 = Color3.fromRGB(255, 200, 100)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- Кнопка закрытия
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -28, 0, 6)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
closeButton.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.BorderSizePixel = 0
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeButton

closeButton.Activated:Connect(function()
    screenGui:Destroy()
end)

-- Состояние
local checked = {}
local executed = {}
local batchRunning = false

for i = 1, #SCRIPTS do
    checked[i] = false
    executed[i] = false
end

-- ====================== СОЗДАНИЕ КНОПОК ======================
for i, scriptData in ipairs(SCRIPTS) do
    local yPos = HEADER_H + (i - 1) * (BUTTON_H + BUTTON_GAP) + PADDING

    -- Чекбокс
    local checkbox = Instance.new("TextButton")
    checkbox.Size = UDim2.new(0, BUTTON_H, 0, BUTTON_H)
    checkbox.Position = UDim2.new(0, PADDING, 0, yPos)
    checkbox.Text = ""
    checkbox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    checkbox.BorderSizePixel = 0
    checkbox.Font = Enum.Font.GothamBold
    checkbox.TextSize = 16
    checkbox.TextColor3 = Color3.fromRGB(100, 255, 100)
    checkbox.Parent = mainFrame

    local cbCorner = Instance.new("UICorner")
    cbCorner.CornerRadius = UDim.new(0, 4)
    cbCorner.Parent = checkbox

    -- Кнопка скрипта
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -(PADDING * 2 + BUTTON_H + 6), 0, BUTTON_H)
    button.Position = UDim2.new(0, PADDING + BUTTON_H + 6, 0, yPos)
    button.Text = scriptData.Name
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 13
    button.BorderSizePixel = 0
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = mainFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = button

    -- Отступ текста внутри кнопки
    local textPad = Instance.new("UIPadding")
    textPad.PaddingLeft = UDim.new(0, 8)
    textPad.Parent = button

    -- Обновление вида чекбокса
    local function updateCheckbox()
        if checked[i] then
            checkbox.Text = "✓"
            checkbox.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        else
            checkbox.Text = ""
            checkbox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
    end

    -- Клик по чекбоксу
    checkbox.Activated:Connect(function()
        checked[i] = not checked[i]
        updateCheckbox()
    end)

    -- Клик по кнопке скрипта (одиночный запуск)
    button.Activated:Connect(function()
        if executed[i] then return end
        executed[i] = true
        button.TextColor3 = Color3.fromRGB(100, 255, 100)
        button.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptData.Url))()
        end)
        if not success then
            warn("[ScriptHub] Ошибка " .. scriptData.Name .. ": " .. tostring(err))
            button.Text = scriptData.Name .. " ✗"
            button.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end

-- ====================== КНОПКА BATCH RUN ======================
local batchYPos = HEADER_H + buttonCount * (BUTTON_H + BUTTON_GAP) + PADDING

local batchButton = Instance.new("TextButton")
batchButton.Size = UDim2.new(1, -(PADDING * 2), 0, BATCH_BTN_H)
batchButton.Position = UDim2.new(0, PADDING, 0, batchYPos)
batchButton.Text = "▶ Run Checked"
batchButton.BackgroundColor3 = Color3.fromRGB(40, 80, 160)
batchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
batchButton.Font = Enum.Font.GothamBold
batchButton.TextSize = 14
batchButton.BorderSizePixel = 0
batchButton.Parent = mainFrame

local batchCorner = Instance.new("UICorner")
batchCorner.CornerRadius = UDim.new(0, 6)
batchCorner.Parent = batchButton

batchButton.Activated:Connect(function()
    if batchRunning then return end

    -- Собираем индексы выбранных и невыполненных
    local toRun = {}
    for i = 1, #SCRIPTS do
        if checked[i] and not executed[i] then
            toRun[#toRun + 1] = i
        end
    end

    if #toRun == 0 then
        print("[ScriptHub] Ничего не выбрано или всё уже выполнено")
        return
    end

    batchRunning = true
    batchButton.Text = string.format("▶ Running %d...", #toRun)
    batchButton.BackgroundColor3 = Color3.fromRGB(80, 60, 20)

    task.spawn(function()
        for idx, scriptIndex in ipairs(toRun) do
            local data = SCRIPTS[scriptIndex]

            -- Находим кнопку скрипта для обновления цвета
            -- Кнопки создаются в порядке SCRIPTS, позиция известна
            local btnY = HEADER_H + (scriptIndex - 1) * (BUTTON_H + BUTTON_GAP) + PADDING
            -- Ищем кнопку по позиции (надёжнее чем по имени)
            local targetBtn = nil
            for _, child in ipairs(mainFrame:GetChildren()) do
                if child:IsA("TextButton") and child ~= closeButton and child ~= batchButton
                    and math.abs(child.Position.Y.Offset - btnY) < 2
                    and child.Size.X.Scale > 0.3 then
                    targetBtn = child
                    break
                end
            end

            executed[scriptIndex] = true
            if targetBtn then
                targetBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
                targetBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
            end

            local success, err = pcall(function()
                loadstring(game:HttpGet(data.Url))()
            end)

            if not success then
                warn("[ScriptHub] Ошибка " .. data.Name .. ": " .. tostring(err))
                if targetBtn then
                    targetBtn.Text = data.Name .. " ✗"
                    targetBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
                end
            else
                print("[ScriptHub] ✓ " .. data.Name)
            end

            batchButton.Text = string.format("▶ %d/%d", idx, #toRun)

            -- Интервал 1с между скриптами (кроме последнего)
            if idx < #toRun then
                task.wait(1)
            end
        end

        batchRunning = false
        batchButton.Text = "▶ Run Checked"
        batchButton.BackgroundColor3 = Color3.fromRGB(40, 80, 160)
        print("[ScriptHub] Batch complete")
    end)
end)

print("=== Script Hub v2.0 ===")
print("  ☑ Check scripts → ▶ Run Checked")
print("  Click script name = instant run")
print("========================")
