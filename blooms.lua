-- Petal TP v10.3 (Configurable Toggle Key)
-- Нажми TOGGLE_KEY для вкл/выкл

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Events = ReplicatedStorage:FindFirstChild("Events")

-- ===============================
-- НАСТРОЙКИ (МЕНЯЙ ЗДЕСЬ)
-- ===============================
local TOGGLE_KEY        = Enum.KeyCode.G       -- Кнопка вкл/выкл (G, R, F, X и т.д.)
local TP_INTERVAL       = 3.5
local SCAN_INTERVAL     = 0.01
local PETAL_WAIT        = 0.11
local RED_URGENT        = 3
local REFRESH_THRESHOLD = 2
local BUFF_CAP          = 4
local LOGS              = false
local DEBUG_LOGS        = false

local HEIGHT_ZONES = {
    {min = 20, max = 30, tpMin = 27, minX = -254.52, maxX = -166.23, minZ = 105.47, maxZ = 244.76},
    {min = 36, max = 47, tpMin = 43, minX = -403, maxX = -258, minZ = 83, maxZ = 175},
    {min = 87, max = 100, tpMin = 94},
    {min = 115, max = 150, interval = 1.5},
}

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

local VIP_PETALS = {
    ["Red Petal"]        = true,
    ["Pink Petal"]       = true,
    ["Periwinkle Petal"] = true,
    ["Scarlet Petal"]    = true,
    ["Violet Petal"]     = true,
}

local FESTIVE_PETALS = {
    ["Red Petal"]        = true,
    ["Pink Petal"]       = true,
    ["Periwinkle Petal"] = true,
    ["Violet Petal"]     = true,
    ["Scarlet Petal"]    = true,
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
    if remaining > 0 then liveBuffs[name] = tick() + remaining end
end

local function getBuffRemaining(name)
    local exp = liveBuffs[name]
    if exp and tick() < exp then return exp - tick() end
    return 0
end

local function countActiveBuffs()
    local count = 0
    for name in pairs(PETAL_COLORS) do
        if getBuffRemaining(name) > 0 then count = count + 1 end
    end
    return count
end

local SBE = Events and Events:FindFirstChild("ServerBuffEvent")
if SBE then
    SBE.OnClientEvent:Connect(function(action, buffName, arg3, arg4)
        if action == "Apply" and PETAL_COLORS[buffName] then
            local dur = 8
            if type(arg4) == "number" then dur = arg4
            elseif type(arg3) == "number" and arg3 < 1000 then dur = arg3 end
            recordBuff(buffName, dur)
            if DEBUG_LOGS then print("[SBE] Apply " .. buffName .. " dur=" .. dur) end
        end
        if action == "Apply" and buffName == "Festive Blessing" then hasFestiveBlessing = true end
        if action == "Remove" and buffName == "Festive Blessing" then hasFestiveBlessing = false end
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
                            if rem > 0 and rem > getBuffRemaining(data.Src) then recordBuff(data.Src, rem) end
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

local function getZoneForPos(pos)
    local y, x, z = pos.Y, pos.X, pos.Z
    for _, zone in ipairs(HEIGHT_ZONES) do
        if y >= zone.min and y <= zone.max then
            if zone.minX then
                if x >= zone.minX and x <= zone.maxX and z >= zone.minZ and z <= zone.maxZ then return zone end
            else return zone end
        end
    end
    return nil
end

local function isInZone(pos) return getZoneForPos(pos) ~= nil end

local function getZoneInterval(pos)
    local zone = getZoneForPos(pos)
    if zone then return zone.interval or TP_INTERVAL end
    return TP_INTERVAL
end

local function getTPHeight(pos)
    local zone = getZoneForPos(pos)
    if zone then return zone.tpMin or zone.min end
    return pos.Y + 3
end

local function getColorName(color)
    for name, col in pairs(PETAL_COLORS) do
        if math.abs(col.R - color.R) < 0.02 and math.abs(col.G - color.G) < 0.02 and math.abs(col.B - color.B) < 0.02 then return name end
    end
    return nil
end

task.spawn(function()
    while true do
        local particles = Workspace:FindFirstChild("Particles")
        local found = {}
        if particles then
            for _, obj in ipairs(particles:GetChildren()) do
                if obj.Name == "PetalPart" and obj:IsA("BasePart") and isInZone(obj.Position) then found[#found + 1] = obj end
            end
        end
        cachedPetals = found
        task.wait(SCAN_INTERVAL)
    end
end)

local function tpCollect(petal, colorName)
    if busy then return end
    if not petal or not petal.Parent then return end
    local hrp, hum = getHRP()
    if not hrp or not hum then return end

    busy = true
    local savedCF = hrp.CFrame
    local camCF = Camera.CFrame
    local camType = Camera.CameraType

    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = camCF
    if hum then hum.AutoRotate = false end

    local tpY = getTPHeight(petal.Position)
    local petalCF = CFrame.new(petal.Position.X, tpY, petal.Position.Z)

    local hbConn = RunService.Heartbeat:Connect(function()
        if hrp.Parent then
            hrp.CFrame = petalCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)

    local psConn = RunService.PostSimulation:Connect(function()
        if hrp.Parent then
            hrp.CFrame = savedCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)

    local camBindName = "TPv10_CamLock"
    RunService:BindToRenderStep(camBindName, 0, function() Camera.CFrame = camCF end)

    task.wait(PETAL_WAIT)

    hbConn:Disconnect()
    psConn:Disconnect()
    RunService:UnbindFromRenderStep(camBindName)

    hrp.CFrame = savedCF
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

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
        print("[Petal] " .. colorName .. fb .. zi .. " Y=" .. string.format("%.0f", tpY) .. " buffs=" .. countActiveBuffs() .. "/" .. BUFF_CAP)
    end
    busy = false
end

-- ===============================
-- ВЫБОР ЦЕЛИ v10.2
-- ===============================
local function selectTarget()
    local hrp = getHRP()
    if not hrp or #cachedPetals == 0 then return nil end

    local activeCount = countActiveBuffs()
    local overCap = activeCount >= BUFF_CAP

    if DEBUG_LOGS then
        print("[D] --- selectTarget --- buffs=" .. activeCount .. "/" .. BUFF_CAP .. (overCap and " OVER" or " UNDER"))
    end

    local byColor = {}
    for _, obj in ipairs(cachedPetals) do
        if obj and obj.Parent then
            local name = getColorName(obj.Color)
            if name and COLOR_PRIORITY[name] then
                local dist = (obj.Position - hrp.Position).Magnitude
                if not byColor[name] or dist < byColor[name].dist then
                    byColor[name] = {part = obj, dist = dist, name = name}
                end
            end
        end
    end

    -- RED URGENT (абсолютный приоритет)
    local redRem = getBuffRemaining("Red Petal")
    if redRem > 0 and redRem < RED_URGENT and byColor["Red Petal"] then
        if DEBUG_LOGS then print("[D] !!! RED URGENT rem=" .. string.format("%.1f", redRem) .. "s !!!") end
        return byColor["Red Petal"].part, "Red Petal"
    end

    -- OVER CAP → только VIP
    if overCap then
        local vipCandidates = {}
        for colorName, data in pairs(byColor) do
            if VIP_PETALS[colorName] then
                local rem = getBuffRemaining(colorName)
                if rem == 0 or rem < REFRESH_THRESHOLD then
                    vipCandidates[#vipCandidates + 1] = data
                    if DEBUG_LOGS then print("[D] + [VIP/CAP] " .. colorName .. " d=" .. math.floor(data.dist)) end
                end
            else
                if DEBUG_LOGS then print("[D] BLOCKED " .. colorName .. " (over cap)") end
            end
        end
        if #vipCandidates > 0 then
            table.sort(vipCandidates, function(a, b)
                local pa = COLOR_PRIORITY[a.name] or 999
                local pb = COLOR_PRIORITY[b.name] or 999
                if pa ~= pb then return pa < pb end
                return a.dist < b.dist
            end)
            return vipCandidates[1].part, vipCandidates[1].name
        end
        return nil
    end

    -- UNDER CAP → новые > продление
    local newCandidates = {}
    local refreshCandidates = {}

    for colorName, data in pairs(byColor) do
        local rem = getBuffRemaining(colorName)
        if rem == 0 then
            newCandidates[#newCandidates + 1] = data
        elseif rem < REFRESH_THRESHOLD then
            refreshCandidates[#refreshCandidates + 1] = data
        end
    end

    local candidates
    if #newCandidates > 0 then
        candidates = newCandidates
    else
        candidates = refreshCandidates
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

-- ОСНОВНОЙ ЦИКЛ
task.spawn(function()
    while true do
        if enabled and not busy then
            local elapsed = tick() - lastTPTime
            if elapsed >= lastZoneInterval then
                local petal, colorName = selectTarget()
                if petal then tpCollect(petal, colorName) end
            end
        end
        task.wait(0.2)
    end
end)

-- УПРАВЛЕНИЕ (использует TOGGLE_KEY)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == TOGGLE_KEY then
        enabled = not enabled
        if enabled then lastTPTime = 0 end
        print(enabled and "[Petal] ON" or "[Petal] OFF")
    end
end)

LP.CharacterAdded:Connect(function()
    busy = false; lastTPTime = 0; liveBuffs = {}; lastZoneInterval = TP_INTERVAL
end)

local function printStatus()
    print("=== Petal v10.3 ===")
    print("  Toggle: " .. tostring(TOGGLE_KEY))
    print("  Cap: " .. BUFF_CAP .. " | Red urgent: <" .. RED_URGENT .. "s")
    print("  Active: " .. countActiveBuffs() .. "/" .. BUFF_CAP)
    local sorted = {}
    for name, prio in pairs(COLOR_PRIORITY) do sorted[#sorted + 1] = {name, prio} end
    table.sort(sorted, function(a, b) return a[2] < b[2] end)
    for _, e in ipairs(sorted) do
        local vip = VIP_PETALS[e[1]] and " [VIP]" or ""
        local rem = getBuffRemaining(e[1])
        local rs = rem > 0 and (" =" .. string.format("%.1f", rem) .. "s") or ""
        print("    #" .. e[2] .. " " .. e[1] .. vip .. rs)
    end
    print("================")
end

getgenv().PT = {
    Add = function(min, max) HEIGHT_ZONES[#HEIGHT_ZONES + 1] = {min = min, max = max} printStatus() end,
    Set = function(...) HEIGHT_ZONES = {} local a = {...} for i = 1, #a, 2 do HEIGHT_ZONES[#HEIGHT_ZONES + 1] = {min = a[i], max = a[i+1]} end printStatus() end,
    List = printStatus, Speed = function(t) TP_INTERVAL = t printStatus() end,
    Wait = function(t) PETAL_WAIT = t printStatus() end,
    Urgent = function(t) RED_URGENT = t printStatus() end,
    Refresh = function(t) REFRESH_THRESHOLD = t printStatus() end,
    Cap = function(t) BUFF_CAP = t printStatus() end,
    Key = function(k) TOGGLE_KEY = Enum.KeyCode[k:upper()] or TOGGLE_KEY printStatus() end,
    ZoneSpeed = function(i, t) if HEIGHT_ZONES[i] then HEIGHT_ZONES[i].interval = t end printStatus() end,
    Log = function(on) LOGS = on == nil and not LOGS or on end,
    Debug = function(on) DEBUG_LOGS = on == nil and not DEBUG_LOGS or on print("Debug: " .. tostring(DEBUG_LOGS)) end,
    Buffs = printStatus,
}

printStatus()
print(tostring(TOGGLE_KEY):match("%w+$") .. " = toggle | PT.Key(\"R\") | PT.Debug() | PT.Buffs()")
