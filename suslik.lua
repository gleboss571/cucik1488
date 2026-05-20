-- Petal TP — возврат когда петаль собрана
-- R = toggle

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════════════════════════════
-- НАСТРОЙКИ
-- ═══════════════════════════════

local HEIGHT_ZONES = {
    {min = 36, max = 40},
    {min = 85, max = 90},
    {min = 115, max = 150, interval = 1.2},
}

local TP_INTERVAL       = 2
local SCAN_INTERVAL     = 0.1
local MAX_WAIT          = 0.7   -- максимум ждать на петале (если не исчезла)
local RED_THRESHOLD     = 5
local DEFAULT_THRESHOLD = 3
local LOGS              = true

local PETAL_COLORS = {
    ["Blue Petal"]       = Color3.fromRGB(33, 66, 249),
    ["Black Petal"]      = Color3.fromRGB(11, 11, 11),
    ["White Petal"]      = Color3.fromRGB(249, 249, 249),
    ["Green Petal"]      = Color3.fromRGB(35, 232, 5),
    ["Cyan Petal"]       = Color3.fromRGB(29, 196, 222),
    ["Violet Petal"]     = Color3.fromRGB(94, 38, 177),
    ["Yellow Petal"]     = Color3.fromRGB(238, 204, 79),
    ["Scarlet Petal"]    = Color3.fromRGB(171, 19, 19),
    ["Merigold Petal"]   = Color3.fromRGB(218, 168, 28),
    ["Red Petal"]        = Color3.fromRGB(249, 34, 34),
    ["Grey Petal"]       = Color3.fromRGB(127, 127, 127),
    ["Pink Petal"]       = Color3.fromRGB(255, 130, 201),
    ["Periwinkle Petal"] = Color3.fromRGB(150, 156, 236),
}

local COLOR_PRIORITY = {
    ["Red Petal"] = 1,
    ["Pink Petal"] = 2,
    ["Periwinkle Petal"] = 3,
    ["Violet Petal"] = 4,
    ["Scarlet Petal"] = 5,
    ["Merigold Petal"] = 6,
    ["Green Petal"] = 7,
    ["Yellow Petal"] = 8,
}

local FESTIVE_PETALS = {
    ["Red Petal"] = true,
    ["Pink Petal"] = true,
    ["Periwinkle Petal"] = true,
    ["Violet Petal"] = true,
    ["Scarlet Petal"] = true,
}

-- ═══════════════════════════════

local enabled = false
local busy = false
local cachedPetals = {}
local redUrgentDone = false
local redNoBuffUsed = false
local hasFestiveBlessing = false

local function getHRP()
    local c = LP.Character
    if not c then return nil, nil end
    return c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

local function isInZone(y)
    for _, z in ipairs(HEIGHT_ZONES) do
        if y >= z.min and y <= z.max then return true end
    end
    return false
end

local function getZoneInterval(y)
    for _, z in ipairs(HEIGHT_ZONES) do
        if y >= z.min and y <= z.max then
            return z.interval or TP_INTERVAL
        end
    end
    return TP_INTERVAL
end

local function getColorName(color)
    for name, col in pairs(PETAL_COLORS) do
        if math.abs(col.R - color.R) < 0.02
            and math.abs(col.G - color.G) < 0.02
            and math.abs(col.B - color.B) < 0.02 then
            return name
        end
    end
    return nil
end

-- Сканер
task.spawn(function()
    while true do
        local particles = Workspace:FindFirstChild("Particles")
        local found = {}
        if particles then
            for _, obj in ipairs(particles:GetChildren()) do
                if obj.Name == "PetalPart" and obj:IsA("BasePart") and isInZone(obj.Position.Y) then
                    found[#found + 1] = obj
                end
            end
        end
        cachedPetals = found
        task.wait(SCAN_INTERVAL)
    end
end)

-- ═══════════════════════════════
-- БАФФЫ + FESTIVE BLESSING
-- ═══════════════════════════════

local buffCache = {}
local lastBuffTime = 0

local function getBuffs()
    if tick() - lastBuffTime < 3 then return buffCache end
    local ev = ReplicatedStorage:FindFirstChild("Events")
    local fn = ev and ev:FindFirstChild("RetrievePlayerStats")
    if not fn then return buffCache end
    local ok, stats = pcall(fn.InvokeServer, fn)
    if not ok or type(stats) ~= "table" then return buffCache end

    local found = {}
    local festive = false

    local function scan(data, visited)
        if type(data) ~= "table" or visited[data] then return end
        visited[data] = true
        if data.Src and data.Start and data.Dur then
            if PETAL_COLORS[data.Src] then
                local rem = (data.Start + data.Dur) - os.time()
                if rem > 0 then found[data.Src] = rem end
            end
            if data.Src == "Festive Blessing" then
                local rem = (data.Start + data.Dur) - os.time()
                if rem > 0 then festive = true end
            end
        end
        for _, v in pairs(data) do
            if type(v) == "table" then scan(v, visited) end
        end
    end
    scan(stats, {})

    buffCache = found
    hasFestiveBlessing = festive
    lastBuffTime = tick()
    return found
end

-- ═══════════════════════════════
-- ВЫБОР ЦЕЛИ
-- ═══════════════════════════════

local function selectTarget()
    local hrp = getHRP()
    if not hrp then return nil end
    if #cachedPetals == 0 then return nil end

    local buffs = getBuffs()

    local byColor = {}
    for _, obj in ipairs(cachedPetals) do
        if obj and obj.Parent then
            local name = getColorName(obj.Color)
            if name then
                local dist = (obj.Position - hrp.Position).Magnitude
                if not byColor[name] or dist < byColor[name].dist then
                    byColor[name] = {part = obj, dist = dist, name = name}
                end
            end
        end
    end

    local candidates = {}
    for colorName, data in pairs(byColor) do
        if hasFestiveBlessing and not FESTIVE_PETALS[colorName] then
        elseif colorName == "Red Petal" then
            local rem = buffs["Red Petal"]
            if not rem then
                if not redNoBuffUsed then
                    candidates[#candidates + 1] = data
                end
            elseif rem < RED_THRESHOLD then
                candidates[#candidates + 1] = data
            end
        else
            local rem = buffs[colorName]
            if not rem or rem < DEFAULT_THRESHOLD then
                candidates[#candidates + 1] = data
            end
        end
    end

    if #candidates == 0 then return nil end

    table.sort(candidates, function(a, b)
        local pa = COLOR_PRIORITY[a.name] or 999
        local pb = COLOR_PRIORITY[b.name] or 999
        if pa ~= pb then return pa < pb end
        return a.dist < b.dist
    end)

    return candidates[1].part, candidates[1].name
end

-- ═══════════════════════════════
-- НАЙТИ RED PETAL
-- ═══════════════════════════════

local function findRedPetal()
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestD = nil, math.huge
    for _, obj in ipairs(cachedPetals) do
        if obj and obj.Parent then
            if getColorName(obj.Color) == "Red Petal" then
                local d = (obj.Position - hrp.Position).Magnitude
                if d < bestD then bestD = d best = obj end
            end
        end
    end
    return best
end

-- ═══════════════════════════════
-- ТЕЛЕПОРТ — возврат когда петаль собрана
-- ═══════════════════════════════

local function tpCollect(petal, colorName)
    if busy then return end
    if not petal or not petal.Parent then return end
    local hrp, hum = getHRP()
    if not hrp or not hum then return end

    busy = true

    local savedCF = hrp.CFrame
    local camType = Camera.CameraType
    local camCF = Camera.CFrame

    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = camCF

    if hum then hum.AutoRotate = false end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    -- Сохраняем позицию петали ДО телепорта
    local petalCF = petal.CFrame + Vector3.new(0, 3, 0)

    -- Проверяем что петаль ещё существует
    if not petal or not petal.Parent then
        busy = false
        return
    end

    -- Слушаем PetalCollected — сервер шлёт когда бафф засчитан
    local collected = false
    local Events = ReplicatedStorage:FindFirstChild("Events")
    local PC = Events and Events:FindFirstChild("PetalCollected")
    local conn
    if PC then
        conn = PC.OnClientEvent:Connect(function()
            collected = true
        end)
    end

    -- TP к петале
    hrp.CFrame = petalCF
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    -- Ждём PetalCollected event или MAX_WAIT
    local start = tick()
    while tick() - start < MAX_WAIT do
        if collected then break end
        hrp.CFrame = petalCF
        hrp.AssemblyLinearVelocity = Vector3.zero
        RunService.Heartbeat:Wait()
    end

    if conn then conn:Disconnect() end

    -- Сразу возврат
    hrp.CFrame = savedCF
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    RunService.Heartbeat:Wait()
    hrp.CFrame = savedCF
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    if hum then
        hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end

    Camera.CameraType = camType

    if LOGS then
        local festiveTag = hasFestiveBlessing and " [FB]" or ""
        print("🌸 " .. (colorName or "Petal") .. festiveTag)
    end
    busy = false
end

-- ═══════════════════════════════
-- ОСНОВНОЙ ЦИКЛ
-- ═══════════════════════════════

task.spawn(function()
    while true do
        local waitTime = TP_INTERVAL
        if enabled and not busy then
            local petal, colorName = selectTarget()
            if petal then
                waitTime = getZoneInterval(petal.Position.Y)
                if colorName == "Red Petal" then
                    local buffs = getBuffs()
                    if not buffs["Red Petal"] then
                        redNoBuffUsed = true
                    end
                end
                tpCollect(petal, colorName)
            end
        end
        task.wait(waitTime)
    end
end)

-- Urgent Red Petal
task.spawn(function()
    while true do
        if enabled and not busy then
            local buffs = getBuffs()
            local redRem = buffs["Red Petal"]

            if redRem and redRem < RED_THRESHOLD and not redUrgentDone then
                local redPetal = findRedPetal()
                if redPetal then
                    redUrgentDone = true
                    tpCollect(redPetal, "Red Petal (URGENT)")
                end
            end

            if not redRem then
                redUrgentDone = false
            end

            if redRem and redRem >= RED_THRESHOLD then
                redUrgentDone = false
                redNoBuffUsed = false
            end
        end
        task.wait(0.3)
    end
end)

-- ═══════════════════════════════
-- УПРАВЛЕНИЕ
-- ═══════════════════════════════

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.R then
        enabled = not enabled
        if LOGS then print(enabled and "🟢 Petal ON" or "🔴 Petal OFF") end
    end
end)

LP.CharacterAdded:Connect(function()
    busy = false
    redUrgentDone = false
    redNoBuffUsed = false
end)

local function printStatus()
    print("═══════════════════════════")
    print("🌸 Petal Collector")
    print("  Enabled: " .. tostring(enabled))
    print("  Festive Blessing: " .. tostring(hasFestiveBlessing))
    print("  TP interval: " .. TP_INTERVAL .. "s")
    print("  Max wait: " .. MAX_WAIT .. "s")
    print("  Red threshold: <" .. RED_THRESHOLD .. "s")
    print("  Default threshold: <" .. DEFAULT_THRESHOLD .. "s")
    print("  Scan: " .. SCAN_INTERVAL .. "s")
    print("  Logs: " .. tostring(LOGS))
    if hasFestiveBlessing then
        print("  FB mode: Red, Pink, Periwinkle, Violet, Scarlet ONLY")
    end
    print("  Zones:")
    for i, z in ipairs(HEIGHT_ZONES) do
        print("    [" .. i .. "] Y=" .. z.min .. "-" .. z.max .. " | interval=" .. (z.interval or TP_INTERVAL) .. "s")
    end
    print("═══════════════════════════")
end

getgenv().PT = {
    Add = function(min, max)
        HEIGHT_ZONES[#HEIGHT_ZONES + 1] = {min = min, max = max}
        printStatus()
    end,
    Set = function(...)
        HEIGHT_ZONES = {}
        local a = {...}
        for i = 1, #a, 2 do
            HEIGHT_ZONES[#HEIGHT_ZONES + 1] = {min = a[i], max = a[i+1]}
        end
        printStatus()
    end,
    List = function() printStatus() end,
    Speed = function(t) TP_INTERVAL = t printStatus() end,
    Wait = function(t) MAX_WAIT = t printStatus() end,
    Red = function(t) RED_THRESHOLD = t printStatus() end,
    Default = function(t) DEFAULT_THRESHOLD = t printStatus() end,
    Scan = function(t) SCAN_INTERVAL = t printStatus() end,
    ZoneSpeed = function(index, t)
        if HEIGHT_ZONES[index] then
            HEIGHT_ZONES[index].interval = t
            printStatus()
        end
    end,
    Log = function(on)
        if on == nil then LOGS = not LOGS else LOGS = on end
        print("Logs: " .. tostring(LOGS))
    end,
}

printStatus()
print("  R = toggle | PT.Wait(0.5) | PT.Speed(1.5)")
