--[[
   MAIN Backpack Switcher (стаки 19-30 ИЛИ бафф активен → Coconut, + таймер 45с)
   При активации баффа Scorching Star Aura запускается таймер 45с.
   По истечении таймера принудительно надевается Red Port-O-Hive.
   Delta-совместимый, без GUI.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Events = require(ReplicatedStorage.Events)

local SCORCHING_MIN = 19
local SCORCHING_MAX = 30
local STATS_INTERVAL = 2                -- проверка баффа раз в 2 сек
local SCORCHING_DURATION = 45           -- длительность способности (сек)
local LOGS = true

local coconutEquipped = false
local scorchingActive = false           -- текущее состояние (держим канистру?)
local lastStacks = 0
local lastBuffActive = false
local equipLock = false
local timer = nil                       -- таймер для принудительного переключения

-- =============== ФУНКЦИИ ЭКИПИРОВКИ ===============
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
    return stackActive or lastBuffActive      -- ИЛИ
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

-- =============== ЗАПУСК ТАЙМЕРА ПРИ АКТИВАЦИИ БАФФА ===============
local function startTimerIfNeeded()
    -- Отменяем старый таймер, если есть
    if timer then
        task.cancel(timer)
        timer = nil
    end
    -- Запускаем новый только если бафф активен
    if lastBuffActive then
        if LOGS then print(string.format("[Backpack] Запуск таймера на %d сек", SCORCHING_DURATION)) end
        timer = task.delay(SCORCHING_DURATION, function()
            if LOGS then print("[Backpack] Таймер истёк → принудительное переключение на Red") end
            switchToRedPort()
            scorchingActive = false   -- сбрасываем состояние, чтобы не пытаться снова надеть канистру
            timer = nil
        end)
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

            -- Если бафф только что активировался, запускаем таймер
            if active and not lastBuffActive then
                startTimerIfNeeded()
            end
            -- Если бафф деактивировался, таймер не отменяем, он дотикает сам
            lastBuffActive = active

            applyState(evaluateState())
        end
        task.wait(STATS_INTERVAL)
    end
end)
