-- Petal TP v9 (Heartbeat/PostSim + Camera Lock)
-- R = toggle

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Events = ReplicatedStorage:FindFirstChild("Events")

-- min/max = высота ДЕТЕКТА петалей (где они спавнятся)
-- tpMin = высота ТЕЛЕПОРТА персонажа (куда ТП над петалью)
local HEIGHT_ZONES = {
    {min = 20, max = 30, tpMin = 27, minX = -254.52, maxX = -166.23, minZ = 105.47, maxZ = 244.76},  -- sunflower
    {min = 36, max = 47, tpMin = 43, minX = -403, maxX = -258, minZ = 83, maxZ = 175},               -- rose
    {min = 87, max = 100, tpMin = 94},                                                                -- coconut
    {min = 115, max = 150, interval = 1.5},                                                           -- pepper
}

local TP_INTERVAL       = 3.5
local SCAN_INTERVAL     = 0.01
local PETAL_WAIT        = 0.11
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
    ["Red Petal"] = 1,
    ["Pink Petal"] = 2,
    ["Merigold Petal"] = 3,
    ["Periwinkle Petal"] = 4,
    ["Violet Petal"] = 5,
    ["Scarlet Petal"] = 6,
    ["Green Petal"] = 7,
    ["Yellow Petal"] = 8,
    ["Black Petal"] = 9,
    ["Grey Petal"] = 10,
    ["Blue Petal"] = 11,
    ["Cyan Petal"] = 12,
    ["White Petal"] = 13,
}

local FESTIVE_PETALS = {
    ["Red Petal"] = true, ["Pink Petal"] = true,
    ["Periwinkle Petal"] = true, ["Violet Petal"] = true,
    ["Scarlet Petal"] = true,
}

local enabled = false
local busy = false
local cachedPetals = {}
local hasFestiveBlessing = false
local lastTPTime = 0
local lastZoneInterval = TP_INTERVAL

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

-- InvokeServer backup
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

local function getHRP()
    local c = LP.Character
    if not c then return nil, nil end
    return c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

-- Ищет зону по позиции петали (использует min/max для детекта)
local function getZoneForPos(pos)
    local y, x, z = pos.Y, pos.X, pos.Z
    for _, zone in ipairs(HEIGHT_ZONES) do
        if y >= zone.min and y <= zone.max then
            if zone.minX then
                if x >= zone.minX and x <= zone.maxX and z >= zone.minZ and z <= zone.maxZ then
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
    if zone then
        return zone.interval or TP_INTERVAL
    end
    return TP_INTERVAL
end

-- Высота ТП: если есть tpMin — используем его, иначе min
local function getTPHeight(pos)
    local zone = getZoneForPos(pos)
    if zone then
        return zone.tpMin or zone.min
    end
    return pos.Y + 3
end

local function getColorName(color)
    for name, col in pairs(PETAL_COLORS) do
        if math.abs(col.R - color.R) < 0.02 and math.abs(col.G - color.G) < 0.02 and math.abs(col.B - color.B) < 0.02 then
            return name
        end
    end
    return nil
end

-- Сканер — ищет петали по min/max (старая высота)
task.spawn(function()
    while true do
        local particles = Workspace:FindFirstChild("Particles")
        local found = {}
        if particles then
            for _, obj in ipairs(particles:GetChildren()) do
                if obj.Name == "PetalPart" and obj:IsA("BasePart") and isInZone(obj.Position) then
                    found[#found + 1] = obj
                end
            end
        end
        cachedPetals = found
        task.wait(SCAN_INTERVAL)
    end
end)

-- ТП — Heartbeat / PostSimulation + Camera Lock
local function tpCollect(petal, colorName)
    if busy then return end
    if not petal or not petal.Parent then return end
    local hrp, hum = getHRP()
    if not hrp or not hum then return end

    busy = true
    local savedCF = hrp.CFrame
    local camCF = Camera.CFrame
    local camType = Camera.CameraType

    -- Фиксация камеры
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = camCF
    if hum then hum.AutoRotate = false end

    local tpY = getTPHeight(petal.Position)
    local petalCF = CFrame.new(petal.Position.X, tpY, petal.Position.Z)

    -- Heartbeat: телепорт к петали
    local hbConn = RunService.Heartbeat:Connect(function()
        if hrp.Parent then
            hrp.CFrame = petalCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)

    -- PostSimulation: возврат домой
    local psConn = RunService.PostSimulation:Connect(function()
        if hrp.Parent then
            hrp.CFrame = savedCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)

    -- Дополнительная страховка камеры каждый кадр
    local camBindName = "TPv9_CamLock"
    RunService:BindToRenderStep(camBindName, 0, function()
        Camera.CFrame = camCF
    end)

    -- Удержание (PETAL_WAIT)
    task.wait(PETAL_WAIT)

    -- Очистка
    hbConn:Disconnect()
    psConn:Disconnect()
    RunService:UnbindFromRenderStep(camBindName)

    -- Гарантированное возвращение HRP на место
    hrp.CFrame = savedCF
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    -- Восстановление камеры и хуманоида
    Camera.CameraType = camType
    if hum then
        hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end

    lastTPTime = tick()
    lastZoneInterval = getZoneInterval(petal.Position)

    if LOGS then
        local fb = hasFestiveBlessing and " [FB]" or ""
        local zi = lastZoneInterval ~= TP_INTERVAL and (" [zone=" .. lastZoneInterval .. "s]") or ""
        print("[Petal] " .. colorName .. fb .. zi .. " Y=" .. string.format("%.0f", tpY) .. " (ghost)")
    end
    busy = false
end

-- ВЫБОР ЦЕЛИ
local function selectTarget()
    local hrp = getHRP()
    if not hrp or #cachedPetals == 0 then return nil end

    local byColor = {}
    for _, obj in ipairs(cachedPetals) do
        if obj and obj.Parent then
            local name = getColorName(obj.Color)
            if name and COLOR_PRIORITY[name] then
                if hasFestiveBlessing and not FESTIVE_PETALS[name] then
                    -- skip
                else
                    local dist = (obj.Position - hrp.Position).Magnitude
                    if not byColor[name] or dist < byColor[name].dist then
                        byColor[name] = {part = obj, dist = dist, name = name}
                    end
                end
            end
        end
    end

    if DEBUG_LOGS then
        print("[D] --- selectTarget ---")
    end

    local candidates = {}
    for colorName, data in pairs(byColor) do
        local rem = getBuffRemaining(colorName)
        if rem < REFRESH_THRESHOLD then
            candidates[#candidates + 1] = data
            if DEBUG_LOGS then
                local tpY = getTPHeight(data.part.Position)
                print("[D] + " .. colorName .. " d=" .. math.floor(data.dist) .. " buff=" .. string.format("%.1f", rem) .. "s petalY=" .. string.format("%.0f", data.part.Position.Y) .. " tpY=" .. string.format("%.0f", tpY))
            end
        else
            if DEBUG_LOGS then
                print("[D] - " .. colorName .. " buff=" .. string.format("%.1f", rem) .. "s SKIP")
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
        print("[D] -> " .. candidates[1].name .. " petalY=" .. string.format("%.0f", candidates[1].part.Position.Y) .. " tpY=" .. string.format("%.0f", tpY))
    end
    return candidates[1].part, candidates[1].name
end

-- ОДИН ЦИКЛ
task.spawn(function()
    while true do
        if enabled and not busy then
            local redRem = getBuffRemaining("Red Petal")
            if redRem > 0 and redRem < RED_URGENT then
                local hrp = getHRP()
                if hrp then
                    local best, bestD = nil, math.huge
                    for _, obj in ipairs(cachedPetals) do
                        if obj and obj.Parent and getColorName(obj.Color) == "Red Petal" then
                            local d = (obj.Position - hrp.Position).Magnitude
                            if d < bestD then bestD = d best = obj end
                        end
                    end
                    if best then
                        if DEBUG_LOGS then
                            local tpY = getTPHeight(best.Position)
                            print("[D] RED URGENT rem=" .. string.format("%.1f", redRem) .. " petalY=" .. string.format("%.0f", best.Position.Y) .. " tpY=" .. string.format("%.0f", tpY))
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

-- УПРАВЛЕНИЕ
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.R then
        enabled = not enabled
        if enabled then lastTPTime = 0 end
        print(enabled and "[Petal] ON" or "[Petal] OFF")
    end
end)

LP.CharacterAdded:Connect(function()
    busy = false
    lastTPTime = 0
    liveBuffs = {}
    lastZoneInterval = TP_INTERVAL
end)

local function printStatus()
    print("=== Petal v9 (Heartbeat/PostSim + CamLock) ===")
    print("  Wait: " .. PETAL_WAIT .. "s")
    print("  Interval: " .. TP_INTERVAL .. "s (default)")
    print("  Zones (detect -> tp):")
    for i, z in ipairs(HEIGHT_ZONES) do
        local zi = z.interval or TP_INTERVAL
        local tpH = z.tpMin or z.min
        local bounds = ""
        if z.minX then
            bounds = " X=" .. z.minX .. ".." .. z.maxX .. " Z=" .. z.minZ .. ".." .. z.maxZ
        end
        print("    [" .. i .. "] detect Y=" .. z.min .. "-" .. z.max .. " -> tp Y=" .. tpH .. bounds .. " int=" .. zi .. "s")
    end
    print("  Red urgent: <" .. RED_URGENT .. "s")
    print("  Refresh: <" .. REFRESH_THRESHOLD .. "s")
    print("  Festive: " .. tostring(hasFestiveBlessing))
    print("  Buffs:")
    for name, _ in pairs(COLOR_PRIORITY) do
        local rem = getBuffRemaining(name)
        if rem > 0 then print("    " .. name .. " = " .. string.format("%.1f", rem) .. "s") end
    end
    print("================")
end

getgenv().PT = {
    Add = function(min, max) HEIGHT_ZONES[#HEIGHT_ZONES + 1] = {min = min, max = max} printStatus() end,
    Set = function(...) HEIGHT_ZONES = {} local a = {...} for i = 1, #a, 2 do HEIGHT_ZONES[#HEIGHT_ZONES + 1] = {min = a[i], max = a[i+1]} end printStatus() end,
    List = printStatus,
    Speed = function(t) TP_INTERVAL = t printStatus() end,
    Wait = function(t) PETAL_WAIT = t printStatus() end,
    Urgent = function(t) RED_URGENT = t printStatus() end,
    Refresh = function(t) REFRESH_THRESHOLD = t printStatus() end,
    ZoneSpeed = function(i, t) if HEIGHT_ZONES[i] then HEIGHT_ZONES[i].interval = t end printStatus() end,
    Log = function(on) LOGS = on == nil and not LOGS or on end,
    Debug = function(on) DEBUG_LOGS = on == nil and not DEBUG_LOGS or on print("Debug: " .. tostring(DEBUG_LOGS)) end,
    Buffs = printStatus,
}

printStatus()
print("R = toggle | PT.Debug() | PT.Buffs()")
