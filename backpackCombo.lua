--[[
   MAIN Backpack Switcher (стабильный, с pcall и задержкой)
   Условие: стаки 19-30 ИЛИ бафф активен → Coconut.
   Без спама, без GUI, только консоль.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Events = require(ReplicatedStorage.Events)

local SCORCHING_MIN = 19
local SCORCHING_MAX = 30
local STATS_INTERVAL = 1                -- проверка баффа раз в 2 сек
local LOGS = true

local coconutEquipped = false
local scorchingActive = false
local lastStacks = 0
local lastBuffActive = false
local equipLock = false                 -- блокировка от частых переодеваний

-- =============== БЕЗОПАСНАЯ ЭКИПИРОВКА ===============
local function equipAccessory(itemType)
    pcall(function()
        ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Equip", {
            Category = "Accessory",
            Type = itemType,
        })
    end)
end

local function switchToCoconut()
    if coconutEquipped or equipLock then return end
    equipLock = true
    equipAccessory("Coconut Canister")
    coconutEquipped = true
    if LOGS then print("[Backpack] → Coconut Canister (активен)") end
    task.delay(2, function() equipLock = false end)
end

local function switchToRedPort()
    if not coconutEquipped or equipLock then return end
    equipLock = true
    equipAccessory("Red Port-O-Hive")
    coconutEquipped = false
    if LOGS then print("[Backpack] → Red Port-O-Hive (неактивен)") end
    task.delay(2, function() equipLock = false end)
end

-- =============== ОЦЕНКА СОСТОЯНИЯ ===============
local function evaluateState()
    local stackActive = (lastStacks >= SCORCHING_MIN and lastStacks <= SCORCHING_MAX)
    return stackActive or lastBuffActive
end

local function applyState(newState)
    if newState ~= scorchingActive then
        scorchingActive = newState
        if scorchingActive then
            switchToCoconut()
        else
            switchToRedPort()
        end
    end
end

-- =============== СЛУШАТЕЛЬ СТАКОВ ===============
Events.ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag:lower():find("scorching") and info.Action == "Update" then
            local stacks = info.Values and info.Values[1] or 0
            if stacks ~= lastStacks then
                lastStacks = stacks
                applyState(evaluateState())
            end
        end
    end
end)

-- =============== ПЕРИОДИЧЕСКАЯ ПРОВЕРКА БАФФА ===============
task.spawn(function()
    while true do
        local ok, stats = pcall(function()
            return ReplicatedStorage.Events.RetrievePlayerStats:InvokeServer()
        end)
        if ok and stats then
            local function findBuff(tbl)
                if type(tbl) ~= "table" then return nil end
                if rawget(tbl, "Src") == "Scorching Star Aura" then return tbl end
                for _, v in pairs(tbl) do
                    local found = findBuff(v)
                    if found then return found end
                end
                return nil
            end
            local buff = findBuff(stats)
            local active = buff and (buff.Removed ~= true)
            if active ~= lastBuffActive then
                lastBuffActive = active
                applyState(evaluateState())
            end
        end
        task.wait(STATS_INTERVAL)
    end
end)
