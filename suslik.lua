--// Bee Swarm Simulator - Smart Petal Collector
--// Улучшенная версия:
--// • Умный выбор лепестков
--// • Анти-дубликаты
--// • Стабильный телепорт
--// • Кэш баффов
--// • Быстрый поиск ближайших petals
--// • Приоритет + пороги
--// • Минимум лагов

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// ================= SETTINGS =================

local ENABLED = true

local TELEPORT_INTERVAL = 1.2
local PETAL_NAME = "PetalPart"

local DEFAULT_THRESHOLD = 2

local BUFF_THRESHOLDS = {
    ["Red Petal"] = 5,
}

local COLOR_PRIORITY = {
    ["Red Petal"] = 1,
    ["Periwinkle Petal"] = 2,
    ["Pink Petal"] = 3,
    ["Scarlet Petal"] = 4,
    ["Violet Petal"] = 5,
    ["Merigold Petal"] = 6,
    ["Green Petal"] = 7,
    ["Yellow Petal"] = 8,
    ["Blue Petal"] = 9,
    ["Cyan Petal"] = 10,
    ["White Petal"] = 11,
    ["Grey Petal"] = 12,
    ["Black Petal"] = 13,
}

local PETAL_COLORS = {
    ["Blue Petal"] = Color3.fromRGB(33,66,249),
    ["Black Petal"] = Color3.fromRGB(11,11,11),
    ["White Petal"] = Color3.fromRGB(249,249,249),
    ["Green Petal"] = Color3.fromRGB(35,232,5),
    ["Cyan Petal"] = Color3.fromRGB(29,196,222),
    ["Violet Petal"] = Color3.fromRGB(94,38,177),
    ["Yellow Petal"] = Color3.fromRGB(238,204,79),
    ["Scarlet Petal"] = Color3.fromRGB(171,19,19),
    ["Merigold Petal"] = Color3.fromRGB(218,168,28),
    ["Red Petal"] = Color3.fromRGB(249,34,34),
    ["Grey Petal"] = Color3.fromRGB(127,127,127),
    ["Pink Petal"] = Color3.fromRGB(255,130,201),
    ["Periwinkle Petal"] = Color3.fromRGB(150,156,236),
}

--// ================= VARIABLES =================

local isTeleporting = false
local lastTeleport = 0

local cachedBuffs = {}
local lastBuffUpdate = 0

--// ================= HELPERS =================

local function getCharacter()
    return LocalPlayer.Character
end

local function getHRP()
    local char = getCharacter()
    if not char then return end
    return char:FindFirstChild("HumanoidRootPart")
end

local function colorMatch(a,b)
    return math.abs(a.R-b.R) < 0.01
        and math.abs(a.G-b.G) < 0.01
        and math.abs(a.B-b.B) < 0.01
end

local function getColorName(color)
    for name, c in pairs(PETAL_COLORS) do
        if colorMatch(color,c) then
            return name
        end
    end
    return "Unknown"
end

--// ================= BUFF SYSTEM =================

local function fetchStats()
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then return end

    local remote = events:FindFirstChild("RetrievePlayerStats")
    if not remote then return end

    local ok, data = pcall(function()
        return remote:InvokeServer()
    end)

    if ok then
        return data
    end
end

local function scanBuffs(tbl, result)
    if type(tbl) ~= "table" then
        return
    end

    if tbl.Src and tbl.Start and tbl.Dur then
        if PETAL_COLORS[tbl.Src] then
            local remain = (tbl.Start + tbl.Dur) - os.time()

            if remain > 0 then
                result[tbl.Src] = remain
            end
        end
    end

    for _,v in pairs(tbl) do
        if type(v) == "table" then
            scanBuffs(v, result)
        end
    end
end

local function getBuffs()
    if tick() - lastBuffUpdate < 1 then
        return cachedBuffs
    end

    lastBuffUpdate = tick()

    local stats = fetchStats()
    if not stats then
        return cachedBuffs
    end

    local found = {}
    scanBuffs(stats, found)

    cachedBuffs = found
    return cachedBuffs
end

--// ================= PETAL SEARCH =================

local function getBestPetal()
    local particles = Workspace:FindFirstChild("Particles")
    local hrp = getHRP()

    if not particles or not hrp then
        return
    end

    local buffs = getBuffs()

    local bestPetal = nil
    local bestScore = math.huge

    local usedColors = {}

    for _,obj in ipairs(particles:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name == PETAL_NAME then

            local colorName = getColorName(obj.Color)

            if not usedColors[colorName] then

                local remaining = buffs[colorName]
                local threshold = BUFF_THRESHOLDS[colorName] or DEFAULT_THRESHOLD

                local allowed = false

                if not remaining then
                    allowed = true
                elseif remaining < threshold then
                    allowed = true
                end

                if allowed then

                    local dist = (obj.Position - hrp.Position).Magnitude
                    local priority = COLOR_PRIORITY[colorName] or 999

                    local score = priority * 10000 + dist

                    if score < bestScore then
                        bestScore = score
                        bestPetal = obj
                    end
                end

                usedColors[colorName] = true
            end
        end
    end

    return bestPetal
end

--// ================= TELEPORT =================

local function collectPetal(part)
    if not part then return end
    if isTeleporting then return end

    local char = getCharacter()
    local hrp = getHRP()

    if not char or not hrp then
        return
    end

    isTeleporting = true

    local oldCF = hrp.CFrame

    local humanoid = char:FindFirstChildOfClass("Humanoid")

    local oldCamType = Camera.CameraType
    Camera.CameraType = Enum.CameraType.Scriptable

    if humanoid then
        humanoid.AutoRotate = false
        humanoid.PlatformStand = true
    end

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    hrp.CFrame = part.CFrame + Vector3.new(0,3,0)

    task.wait(0.12)

    hrp.CFrame = oldCF

    task.wait(0.05)

    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
    end

    Camera.CameraType = oldCamType

    print("✅ Collected:", getColorName(part.Color))

    isTeleporting = false
end

--// ================= MAIN LOOP =================

task.spawn(function()
    while true do
        if ENABLED then

            if tick() - lastTeleport >= TELEPORT_INTERVAL then
                lastTeleport = tick()

                local petal = getBestPetal()

                if petal then
                    collectPetal(petal)
                end
            end
        end

        task.wait(0.1)
    end
end)

--// ================= TOGGLE =================

UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.R then
        ENABLED = not ENABLED

        print(ENABLED and "🟢 ENABLED" or "🔴 DISABLED")
    end
end)

print("✅ Smart Petal Collector Loaded")
print("R = Toggle")
