-- Mask & Collector Toggle v1.3
-- R = маски | F = коллекторы
-- Автодетект через Workspace.<PlayerName> при старте

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LP = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local ItemPackageEvent = Events:WaitForChild("ItemPackageEvent")

-- ===============================
-- БИНДЫ
-- ===============================
local MASK_TOGGLE_KEY      = Enum.KeyCode.R
local COLLECTOR_TOGGLE_KEY = Enum.KeyCode.F

-- ===============================
-- ПРЕДМЕТЫ
-- ===============================
local MASKS = {
    [1] = { Category = "Accessory", Type = "Demon Mask" },
    [2] = { Category = "Accessory", Type = "Gummy Mask" },
}

local COLLECTORS = {
    [1] = { Category = "Collector", Type = "Dark Scythe", Amount = 1 },
    [2] = { Category = "Collector", Type = "Gummyballer" },
}

-- ===============================
-- СОСТОЯНИЕ
-- ===============================
local maskIndex = 1
local collectorIndex = 1

-- ===============================
-- АВТОДЕТЕКТ ЧЕРЕЗ WORKSPACE
-- Ищет <PlayerName>.<ItemName> напрямую
-- ===============================
local function autoDetect()
    local folder = Workspace:FindFirstChild(LP.Name)
    if not folder then
        print("[AutoDetect] Folder " .. LP.Name .. " not found, using defaults")
        return
    end

    -- Детект маски
    for i, item in ipairs(MASKS) do
        if folder:FindFirstChild(item.Type) then
            maskIndex = i
            print("[AutoDetect] Mask: " .. item.Type .. " (index " .. i .. ")")
            break
        end
    end

    -- Детект коллектора
    for i, item in ipairs(COLLECTORS) do
        if folder:FindFirstChild(item.Type) then
            collectorIndex = i
            print("[AutoDetect] Collector: " .. item.Type .. " (index " .. i .. ")")
            break
        end
    end
end

-- Запуск при старте
task.spawn(function()
    task.wait(0.5)
    autoDetect()
    print(string.format("[Ready] Mask=%s | Collector=%s",
        MASKS[maskIndex].Type, COLLECTORS[collectorIndex].Type))
end)

-- Пересканирование при респавне
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    autoDetect()
end)

-- ===============================
-- INPUT (мгновенно)
-- ===============================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode == MASK_TOGGLE_KEY then
        maskIndex = maskIndex % #MASKS + 1
        ItemPackageEvent:InvokeServer("Equip", MASKS[maskIndex])
        print("[R] → " .. MASKS[maskIndex].Type)
    end

    if input.KeyCode == COLLECTOR_TOGGLE_KEY then
        collectorIndex = collectorIndex % #COLLECTORS + 1
        ItemPackageEvent:InvokeServer("Equip", COLLECTORS[collectorIndex])
        print("[F] → " .. COLLECTORS[collectorIndex].Type)
    end
end)

print("=== Toggle v1.3 ===")
print("  Detecting via Workspace." .. LP.Name .. "...")
print("  R=mask  F=collector")
print("===================")
