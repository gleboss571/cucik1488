--[[
   Account 2/3: Gumdrops Farmer (Firebase, исправленный)
   Использует Gumdrops при boostActive = true, координация через Firebase.
   MY_ID = 2 или 3.
--]]

local MY_ID = 3  -- замените на 3 для второго помощника
local WEB_APP_URL = "https://fuflik1-e9325-default-rtdb.europe-west1.firebasedatabase.app"
local CHECK_INTERVAL = 1       -- опрос Firebase каждую секунду
local GUMMY_THRESHOLD = 20
local GUMMY_MAX = 30
local MORPH_DURATION = 10

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Прямой доступ к событиям (Delta-совместимый)
local Events = ReplicatedStorage:WaitForChild("Events")
local PlayerAbilityEvent = Events:WaitForChild("PlayerAbilityEvent")
local PlayerActivesCommand = Events:WaitForChild("PlayerActivesCommand")

-- Текущие стеки Gummy Morph
local gummyValue = 0
PlayerAbilityEvent.OnClientEvent:Connect(function(data)
    for tag, info in pairs(data) do
        if tag == "Gummy Morph" and info.Action == "Update" then
            gummyValue = info.Values and info.Values[1] or 0
        end
    end
end)

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

-- Запись одного ключа в Firebase
local function writeKey(key, value)
    request({
        Url = WEB_APP_URL .. "/state/" .. key .. ".json",
        Method = "PUT",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(value)
    })
end

-- Использование Gumdrops (рабочий формат)
local function useGumdrops()
    PlayerActivesCommand:FireServer({ Name = "Gumdrops" })
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

        -- Если сейчас моя очередь
        if myTurn then
            if tick() >= morphEndTime then
                myTurn = false
                writeKey("farmer", 0)
                task.wait(CHECK_INTERVAL)
                continue
            end

            if gummyValue < GUMMY_MAX then
                useGumdrops()
                task.wait(2)  -- каждые 2 секунды
            else
                task.wait(1)
            end
            continue
        end

        -- Если роль свободна и буст активен
        if (currentFarmer == 0 or currentFarmer == nil) and boostActive then
            if gummyValue >= GUMMY_THRESHOLD then
                -- Пытаемся захватить роль
                writeKey("farmer", MY_ID)
                task.wait(0.5)
                local check = readState()
                if check and check.farmer == MY_ID then
                    myTurn = true
                    morphEndTime = tick() + MORPH_DURATION
                    useGumdrops()
                end
            end
        end

        task.wait(CHECK_INTERVAL)
    end
end)
