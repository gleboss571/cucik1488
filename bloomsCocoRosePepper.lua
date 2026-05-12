-- Petal TP — Red Petal threshold + urgent
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
    {min = 115, max = 150},
}

local TP_INTERVAL   = 4
local SCAN_INTERVAL = 0.25
local PETAL_DELAY   = 0.7

local RED_THRESHOLD = 4  -- Red Petal: собирать когда баффа нет ИЛИ <3с

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

-- Приоритет (меньше = важнее)
local COLOR_PRIORITY = {
    ["Red Petal"] = 1,
    ["Periwinkle Petal"] = 2,
    ["Pink Petal"] = 3,
    ["Scarlet Petal"] = 4,
    ["Violet Petal"] = 5,
    ["Merigold Petal"] = 6,
    ["Green Petal"] = 7,
    ["Yellow Petal"] = 8,
}

-- ═══════════════════════════════

local enabled = false
local busy = false
local cachedPetals = {}
local redUrgentDone = false

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
-- БАФФЫ
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
    local function scan(data)
        if type(data) ~= "table" then return end
        if data.Src and data.Start and data.Dur then
            if PETAL_COLORS[data.Src] then
                local rem = (data.Start + data.Dur) - os.time()
                if rem > 0 then found[data.Src] = rem end
            end
        end
        for _, v in pairs(data) do
            if type(v) == "table" then scan(v) end
        end
    end
    scan(stats)
    buffCache = found
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
        if colorName == "Red Petal" then
            -- Red Petal: собирать ВСЕГДА
            candidates[#candidates + 1] = data
        elseif colorName ~= "Red Petal" then
            -- Все остальные: собирать ВСЕГДА (без порога)
            candidates[#candidates + 1] = data
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
-- ТЕЛЕПОРТ
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

    hrp.CFrame = petal.CFrame + Vector3.new(0, 3, 0)
    task.wait(PETAL_DELAY)

    hrp.CFrame = savedCF
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    if hum then
        hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end

    Camera.CameraType = camType

    print("🌸 " .. (colorName or "Petal"))
    busy = false
end

-- ═══════════════════════════════
-- ОДИН ОСНОВНОЙ ЦИКЛ
-- ═══════════════════════════════

task.spawn(function()
    while true do
        if enabled and not busy then
            local petal, colorName = selectTarget()
            if petal then
                tpCollect(petal, colorName)
            end
        end
        task.wait(TP_INTERVAL)
    end
end)

-- Urgent Red Petal — бафф ЕСТЬ и <3с → один раз, без ожидания TP_INTERVAL
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

            -- Сброс когда бафф обновился
            if redRem and redRem >= RED_THRESHOLD then
                redUrgentDone = false
            end
            if not redRem then
                redUrgentDone = false
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
        print(enabled and "🟢 Petal ON" or "🔴 Petal OFF")
    end
end)

LP.CharacterAdded:Connect(function()
    busy = false
    redUrgentDone = false
end)

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
    List = function()
        printStatus()
    end,
    Speed = function(t) TP_INTERVAL = t printStatus() end,
    Delay = function(t) PETAL_DELAY = t printStatus() end,
    Red = function(t) RED_THRESHOLD = t printStatus() end,
    Scan = function(t) SCAN_INTERVAL = t printStatus() end,
}

local function printStatus()
    print("═══════════════════════════")
    print("🌸 Petal Collector")
    print("  Enabled: " .. tostring(enabled))
    print("  TP interval: " .. TP_INTERVAL .. "s")
    print("  Petal delay: " .. PETAL_DELAY .. "s")
    print("  Red urgent: <" .. RED_THRESHOLD .. "s")
    print("  Scan: " .. SCAN_INTERVAL .. "s")
    print("  Zones:")
    for i, z in ipairs(HEIGHT_ZONES) do
        print("    [" .. i .. "] Y=" .. z.min .. "-" .. z.max)
    end
    print("═══════════════════════════")
end
printStatus()
print("  R = toggle | PT.Delay() | PT.Speed() | PT.Red()")
