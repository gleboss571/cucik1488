--[[
   Account 2/3: Gumdrops Farmer (Firebase)
   Использует Gumdrops при boostActive = true, координация через Firebase.
   MY_ID должен быть 2 или 3.
--]]

local MY_ID = 2  -- замените на 3 для второго помощника
local WEB_APP_URL = "https://fuflik1-e9325-default-rtdb.firebaseio.com" -- замените на ваш URL
local CHECK_INTERVAL = 3
local GUMMY_THRESHOLD = 20     -- начинаем использовать Gumdrops, если стеков > 20
local GUMMY_MAX = 30           -- значение, при котором активируется Gummy Morph
local MORPH_DURATION = 10      -- длительность Gummy Morph

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Текущее значение стеков Gummy Morph (из PlayerAbilityEvent)
local gummyValue = 0
local Events = require(ReplicatedStorage.Events)
if Events and Events.ClientListen then
    Events.ClientListen("PlayerAbilityEvent", function(data)
        local info = data["Gummy Morph"]
        if info and info.Action == "Update" then
            gummyValue = info.Values and info.Values[1] or 0
        end
    end)
end

-- Чтение состояния из Firebase
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

-- Запись одного поля в Firebase
local function writeState(key, value)
    request({
        Url = WEB_APP_URL .. "/state/" .. key .. ".json",
        Method = "PUT",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(value)
    })
end

-- Использование Gumdrops
local function useGumdrops()
    ReplicatedStorage.Events.PlayerActivesCommand:FireServer({ Name = "Gumdrops" })
end

-- Основной цикл
local myTurn = false
local morphEndTime = 0

task.spawn(function()
    while true do
        local state = readState()
        if not state then
            task.wait(CHECK_INTERVAL)
            continue
        end

        local boostActive = state.boostActive
        local currentFarmer = state.farmer

        -- Если сейчас моя очередь (я уже захватил роль)
        if myTurn then
            -- Проверяем, не истекло ли время морфа
            if tick() >= morphEndTime then
                myTurn = false
                writeState("farmer", 0)
                task.wait(CHECK_INTERVAL)
                continue
            end

            -- Продолжаем использовать Gumdrops, пока стеки < GUMMY_MAX,
            -- ДАЖЕ ЕСЛИ boostActive стал false
            if gummyValue < GUMMY_MAX then
                useGumdrops()
                task.wait(2)  -- каждые 2 секунды
            else
                -- Gummy Morph активирован, просто ждём
                task.wait(1)
            end
            continue
        end

        -- Если роль свободна (0) и буст активен, пытаемся захватить
        if currentFarmer == 0 or currentFarmer == nil then
            if boostActive and gummyValue >= GUMMY_THRESHOLD then
                -- Пытаемся захватить роль
                writeState("farmer", MY_ID)
                task.wait(0.5)
                -- Проверяем, что роль действительно наша (нет гонки)
                local check = readState()
                if check and check.farmer == MY_ID then
                    myTurn = true
                    morphEndTime = tick() + MORPH_DURATION
                    useGumdrops() -- сразу используем
                end
            end
        end

        task.wait(CHECK_INTERVAL)
    end
end)
