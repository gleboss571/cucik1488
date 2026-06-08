-- Petal TP v9 (CFrame + Camera Lock)
-- R = toggle

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Events = ReplicatedStorage:FindFirstChild("Events")

local HEIGHT_ZONES = {
    {min = 20, max = 30, tpMin = 30, minX = -254.52, maxX = -166.23, minZ = 105.47, maxZ = 244.76},
    {min = 36, max = 47, tpMin = 46, minX = -403, maxX = -258, minZ = 83, maxZ = 175},
    {min = 87, max = 100, tpMin = 96},
    {min = 119, max = 150, interval = 1.5, spawnDelay = 0.3},
}

local TP_INTERVAL       = 4
local SCAN_INTERVAL     = 0.01
local PETAL_WAIT        = 0.1
local RED_URGENT        = 4
local REFRESH_THRESHOLD = 1
local LOGS              = false
local DEBUG_LOGS        = false

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
    ["Red Petal"]        = 1,
    ["Pink Petal"]       = 2,
    ["Merigold Petal"]   = 3,
    ["Periwinkle Petal"] = 4,
    ["Violet Petal"]     = 5,
    ["Scarlet Petal"]    = 6,
    ["Green Petal"]      = 7,
    ["Yellow Petal"]     = 8,
    ["Black Petal"]      = 9,
    ["Grey Petal"]       = 10,
    ["Blue Petal"]       = 11,
    ["Cyan Petal"]       = 12,
    ["White Petal"]      = 13,
}

local FESTIVE_PETALS = {
    ["Red Petal"]        = true,
    ["Pink Petal"]       = true,
    ["Periwinkle Petal"] = true,
    ["Violet Petal"]     = true,
    ["Scarlet Petal"]    = true,
}

local enabled          = false
local busy             = false
local cachedPetals     = {}
local hasFestiveBlessing = false
local lastTPTime       = 0
local lastZoneInterval = TP_INTERVAL
local petalFirstSeen   = {}

-- ===============================
-- BUFF TRACKING
-- ===============================
local liveBuffs = {}

local function recordBuff(name, remaining)
    if remaining > 0 then
        liveBuffs[name] = tick() + remaining
    end
end

local function getBuffRemaining(name)
    local exp = liveBuffs[name]
    if exp and tick() < exp then
        return exp - tick()
    end
    return 0
end

local SBE = Events and Events:FindFirstChild("ServerBuffEvent")
if SBE then
    SBE.OnClientEvent:Connect(function(action, buffName, arg3, arg4)
        if action == "Apply" and PETAL_COLORS[buffName] then
            local dur = 8
            if type(arg4) == "number" then
                dur = arg4
            elseif type(arg3) == "number" and arg3 < 1000 then
                dur = arg3
            end
            recordBuff(buffName, dur)
            if DEBUG_LOGS then
                print("[SBE] Apply " .. buffName .. " dur=" .. dur)
            end
        end
        if action == "Apply" and buffName == "Festive Blessing" then
            hasFestiveBlessing = true
        end
        if action == "Remove" and buffName == "Festive Blessing" then
            hasFestiveBlessing = false
        end
    end)
end

task.spawn(function()
    while true do
        local fn = Events and Events:FindFirstChild("RetrievePlayerStats")
        if fn then
            local ok, stats = pcall(fn.InvokeServer, fn)
            if ok and type(stats) == "table" then
                local festive = false
                local function scan(data, visited)
                    if type(data) ~= "table" or visited[data] then return end
                    visited[data] = true
                    if data.Src and data.Start and data.Dur then
                        if PETAL_COLORS[data.Src] then
                            local rem = (data.Start + data.Dur) - os.time()
                            if rem > 0 and rem > getBuffRemaining(data.Src) then
                                recordBuff(data.Src, rem)
                            end
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
                hasFestiveBlessing = festive
            end
        end
        task.wait(10)
    end
end)

-- ===============================
-- HELPERS
-- ===============================
local function getHRP()
    local c = LP.Character
    if not c then return nil, nil end
    return c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

local function getZoneForPos(pos)
    local y, x, z = pos.Y, pos.X, pos.Z
    for _, zone in ipairs(HEIGHT_ZONES) do
        if y >= zone.min and y <= zone.max then
            if zone.minX then
                if x >= zone.minX and x <= zone.maxX
                    and z >= zone.minZ and z <= zone.maxZ then
                    return zone
                end
            else
                return zone
            end
        end
    end
    return nil
end

local function isInZone(pos)
    return getZoneForPos(pos) ~= nil
end

local function getZoneInterval(pos)
    local zone = getZoneForPos(pos)
    return zone and (zone.interval or TP_INTERVAL) or TP_INTERVAL
end

local function getTPHeight(pos)
    local zone = getZoneForPos(pos)
    return zone and (zone.tpMin or zone.min) or (pos.Y + 3)
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

local function isPetalReady(obj)
    local zone = getZoneForPos(obj.Position)
    if not zone or not zone.spawnDelay then return true end

    local firstSeen = petalFirstSeen[obj]
    if not firstSeen then
        petalFirstSeen[obj] = tick()
        return false
    end

    local age   = tick() - firstSeen
    local ready = age >= zone.spawnDelay

    if DEBUG_LOGS and not ready then
        print(string.format("[D] PetalReady: age=%.2fs < delay=%.2fs — NOT READY",
            age, zone.spawnDelay))
    end

    return ready
end

-- ===============================
-- СКАНЕР
-- ===============================
task.spawn(function()
    while true do
        local particles  = Workspace:FindFirstChild("Particles")
        local found      = {}
        local currentSet = {}

        if particles then
            for _, obj in ipairs(particles:GetChildren()) do
                if obj.Name == "PetalPart"
                    and obj:IsA("BasePart")
                    and isInZone(obj.Position) then

                    found[#found + 1] = obj
                    currentSet[obj]   = true

                    if not petalFirstSeen[obj] then
                        petalFirstSeen[obj] = tick()
                        local zone = getZoneForPos(obj.Position)
                        if zone and zone.spawnDelay and DEBUG_LOGS then
                            print(string.format(
                                "[D] New petal in zone Y=%.0f — wait %.2fs",
                                obj.Position.Y, zone.spawnDelay))
                        end
                    end
                end
            end
        end

        -- Чистим словарь от исчезнувших петалов
        for obj in pairs(petalFirstSeen) do
            if not currentSet[obj] then
                petalFirstSeen[obj] = nil
            end
        end

        cachedPetals = found
        task.wait(SCAN_INTERVAL)
    end
end)

-- ===============================
-- ТП — чистый CFrame
-- ===============================
local function tpCollect(petal, colorName)
    if busy then return end
    if not petal or not petal.Parent then return end

    local hrp, hum = getHRP()
    if not hrp or not hum then return end

    busy = true

    local savedCF = hrp.CFrame
    local camCF   = Camera.CFrame
    local camType = Camera.CameraType

    -- Фиксируем камеру
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame     = camCF
    if hum then hum.AutoRotate = false end

    -- Фиксация камеры каждый кадр
    local camBindName = "TPv9_CamLock"
    RunService:BindToRenderStep(
        camBindName,
        Enum.RenderPriority.Camera.Value + 1,
        function()
            Camera.CFrame = camCF
        end
    )

    local tpY     = getTPHeight(petal.Position)
    local petalCF = CFrame.new(petal.Position.X, tpY, petal.Position.Z)

    -- ✅ Чистый CFrame — телепортируемся к петалу и стоим там
    -- Сервер видит нас у петала всё время PETAL_WAIT
    -- Нет осцилляции Heartbeat/PostSim которая давала 1/120 сек касания
    hrp.CFrame                  = petalCF
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    -- Ждём пока сервер зарегистрирует касание
    local buffBefore = getBuffRemaining(colorName)
    task.wait(PETAL_WAIT)

    -- ✅ Проверка: если бафф не обновился — пробуем ещё раз
    -- Это страховка на случай лага сервера
    if getBuffRemaining(colorName) <= buffBefore and petal.Parent then
        if DEBUG_LOGS then
            print("[D] Buff not updated — retry touch " .. colorName)
        end
        hrp.CFrame                  = petalCF
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        task.wait(PETAL_WAIT)
    end

    -- Возвращаемся домой
    hrp.CFrame                  = savedCF
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    -- Убираем фиксацию камеры
    RunService:UnbindFromRenderStep(camBindName)

    Camera.CameraType = camType
    if hum then
        hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end

    lastTPTime       = tick()
    lastZoneInterval = getZoneInterval(petal.Position)

    if LOGS then
        local fb       = hasFestiveBlessing and " [FB]" or ""
        local zi       = lastZoneInterval ~= TP_INTERVAL
            and (" [zone=" .. lastZoneInterval .. "s]") or ""
        local zone     = getZoneForPos(petal.Position)
        local delayStr = (zone and zone.spawnDelay)
            and (" [delay=" .. zone.spawnDelay .. "s]") or ""
        print("[Petal] " .. colorName .. fb .. zi .. delayStr
            .. " Y=" .. string.format("%.0f", tpY))
    end

    busy = false
end

-- ===============================
-- ВЫБОР ЦЕЛИ
-- ===============================
local function selectTarget()
    local hrp = getHRP()
    if not hrp or #cachedPetals == 0 then return nil end

    local byColor = {}
    for _, obj in ipairs(cachedPetals) do
        if obj and obj.Parent then
            local name = getColorName(obj.Color)
            if name and COLOR_PRIORITY[name] then
                if hasFestiveBlessing and not FESTIVE_PETALS[name] then
                    -- skip non-festive when festive blessing active
                elseif not isPetalReady(obj) then
                    if DEBUG_LOGS then
                        local firstSeen = petalFirstSeen[obj]
                        local age = firstSeen and (tick() - firstSeen) or 0
                        print(string.format("[D] Skip %s — spawn delay (age=%.2fs)",
                            name, age))
                    end
                else
                    local dist = (obj.Position - hrp.Position).Magnitude
                    if not byColor[name] or dist < byColor[name].dist then
                        byColor[name] = {part = obj, dist = dist, name = name}
                    end
                end
            end
        end
    end

    if DEBUG_LOGS then print("[D] --- selectTarget ---") end

    local candidates = {}
    for colorName, data in pairs(byColor) do
        local rem = getBuffRemaining(colorName)
        if rem < REFRESH_THRESHOLD then
            candidates[#candidates + 1] = data
            if DEBUG_LOGS then
                local tpY = getTPHeight(data.part.Position)
                print(string.format("[D] + %s d=%d buff=%.1fs petalY=%.0f tpY=%.0f",
                    colorName, math.floor(data.dist), rem,
                    data.part.Position.Y, tpY))
            end
        else
            if DEBUG_LOGS then
                print(string.format("[D] - %s buff=%.1fs SKIP", colorName, rem))
            end
        end
    end

    if #candidates == 0 then
        if DEBUG_LOGS then print("[D] No candidates") end
        return nil
    end

    table.sort(candidates, function(a, b)
        local pa = COLOR_PRIORITY[a.name] or 999
        local pb = COLOR_PRIORITY[b.name] or 999
        if pa ~= pb then return pa < pb end
        return a.dist < b.dist
    end)

    if DEBUG_LOGS then
        local tpY = getTPHeight(candidates[1].part.Position)
        print(string.format("[D] -> %s petalY=%.0f tpY=%.0f",
            candidates[1].name,
            candidates[1].part.Position.Y,
            tpY))
    end

    return candidates[1].part, candidates[1].name
end

-- ===============================
-- ОСНОВНОЙ ЦИКЛ
-- ===============================
task.spawn(function()
    while true do
        if enabled and not busy then
            -- Red urgent
            local redRem = getBuffRemaining("Red Petal")
            if redRem > 0 and redRem < RED_URGENT then
                local hrp = getHRP()
                if hrp then
                    local best, bestD = nil, math.huge
                    for _, obj in ipairs(cachedPetals) do
                        if obj and obj.Parent
                            and getColorName(obj.Color) == "Red Petal"
                            and isPetalReady(obj) then
                            local d = (obj.Position - hrp.Position).Magnitude
                            if d < bestD then
                                bestD = d
                                best  = obj
                            end
                        end
                    end
                    if best then
                        if DEBUG_LOGS then
                            print(string.format("[D] RED URGENT rem=%.1f petalY=%.0f tpY=%.0f",
                                redRem, best.Position.Y, getTPHeight(best.Position)))
                        end
                        tpCollect(best, "Red Petal")
                        task.wait(0.3)
                        continue
                    end
                end
            end

            local elapsed = tick() - lastTPTime
            if elapsed >= lastZoneInterval then
                local petal, colorName = selectTarget()
                if petal then
                    tpCollect(petal, colorName)
                end
            end
        end
        task.wait(0.2)
    end
end)

-- ===============================
-- УПРАВЛЕНИЕ
-- ===============================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.R then
        enabled = not enabled
        if enabled then lastTPTime = 0 end
        print(enabled and "[Petal] ON" or "[Petal] OFF")
    end
end)

LP.CharacterAdded:Connect(function()
    busy             = false
    lastTPTime       = 0
    liveBuffs        = {}
    lastZoneInterval = TP_INTERVAL
    petalFirstSeen   = {}
end)

-- ===============================
-- СТАТУС
-- ===============================
local function printStatus()
    print("=== Petal v9 (CFrame) ===")
    print("  Wait: " .. PETAL_WAIT .. "s")
    print("  Interval: " .. TP_INTERVAL .. "s (default)")
    print("  Zones:")
    for i, z in ipairs(HEIGHT_ZONES) do
        local zi      = z.interval or TP_INTERVAL
        local tpH     = z.tpMin or z.min
        local bounds  = ""
        if z.minX then
            bounds = string.format(" X=%.0f..%.0f Z=%.0f..%.0f",
                z.minX, z.maxX, z.minZ, z.maxZ)
        end
        local dStr = z.spawnDelay and (" delay=" .. z.spawnDelay .. "s") or ""
        print(string.format("    [%d] Y=%d-%d -> tpY=%d%s int=%.1fs%s",
            i, z.min, z.max, tpH, bounds, zi, dStr))
    end
    print("  Red urgent:  <" .. RED_URGENT .. "s")
    print("  Refresh:     <" .. REFRESH_THRESHOLD .. "s")
    print("  Festive:     " .. tostring(hasFestiveBlessing))
    print("  Buffs:")
    for name in pairs(COLOR_PRIORITY) do
        local rem = getBuffRemaining(name)
        if rem > 0 then
            print(string.format("    %s = %.1fs", name, rem))
        end
    end
    print("=========================")
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
    List      = printStatus,
    Speed     = function(t) TP_INTERVAL = t; printStatus() end,
    Wait      = function(t) PETAL_WAIT = t; printStatus() end,
    Urgent    = function(t) RED_URGENT = t; printStatus() end,
    Refresh   = function(t) REFRESH_THRESHOLD = t; printStatus() end,
    ZoneSpeed = function(i, t)
        if HEIGHT_ZONES[i] then HEIGHT_ZONES[i].interval = t end
        printStatus()
    end,
    SpawnDelay = function(i, t)
        if HEIGHT_ZONES[i] then HEIGHT_ZONES[i].spawnDelay = t end
        print("SpawnDelay zone[" .. i .. "] = " .. tostring(t) .. "s")
        printStatus()
    end,
    Log   = function(on) LOGS = (on == nil) and not LOGS or on end,
    Debug = function(on)
        DEBUG_LOGS = (on == nil) and not DEBUG_LOGS or on
        print("Debug: " .. tostring(DEBUG_LOGS))
    end,
    Buffs = printStatus,
}

printStatus()
print("R = toggle | PT.Debug() | PT.Buffs() | PT.SpawnDelay(4, 0.3) | PT.Wait(0.15)")
