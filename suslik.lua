-- ╔══════════════════════════════════════╗
-- ║     Petal Collector — BSS (авто)     ║
-- ╚══════════════════════════════════════╝

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PETAL_NAME  = "PetalPart"

-- ┌─────────────────────────────────────┐
-- │  Приоритеты (меньше = выше)         │
-- └─────────────────────────────────────┘
local COLOR_PRIORITY = {
    ["Red Petal"]        = 1,
    ["Periwinkle Petal"] = 2,
    ["Pink Petal"]       = 3,
    ["Scarlet Petal"]    = 4,
    ["Violet Petal"]     = 5,
    ["Merigold Petal"]   = 6,
    ["Green Petal"]      = 7,
    ["Yellow Petal"]     = 8,
}
local DEFAULT_PRIORITY = 99

local TELEPORT_WAIT  = 0.08
local CHECK_INTERVAL = 0.15
local COLLECT_DELAY  = 1.2

-- ══════════════════════════════════════
local seen  = {}
local queue = {}

local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hrp      = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return nil, nil end
    return hrp, humanoid
end

local function cleanSeen()
    for obj in pairs(seen) do
        if not obj.Parent then
            seen[obj] = nil
        end
    end
end

-- Определяем приоритет лепестка по атрибутам или имени
local function getPriority(petal)
    -- Сначала пробуем атрибут
    local colorAttr = petal:GetAttribute("Color")
                   or petal:GetAttribute("PetalColor")

    if colorAttr then
        return COLOR_PRIORITY[colorAttr] or DEFAULT_PRIORITY, colorAttr
    end

    -- Fallback: ищем совпадение по именам из таблицы
    for colorName, priority in pairs(COLOR_PRIORITY) do
        if petal.Name:find(colorName, 1, true) then
            return priority, colorName
        end
    end

    return DEFAULT_PRIORITY, "Unknown"
end

local function scanPetals()
    cleanSeen()
    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return end

    local added = false
    for _, obj in ipairs(particles:GetChildren()) do
        if obj.Name == PETAL_NAME
        and obj:IsA("BasePart")
        and not seen[obj]
        then
            seen[obj] = true
            local priority, color = getPriority(obj)
            table.insert(queue, {
                part     = obj,
                priority = priority,
                color    = color,
            })
            added = true
        end
    end

    if added then
        table.sort(queue, function(a, b)
            return a.priority < b.priority
        end)
    end
end

local function teleportTo(petal)
    local hrp, humanoid = getChar()
    if not hrp or not humanoid then return false end
    if not petal or not petal.Parent then return false end

    local camera     = Workspace.CurrentCamera
    local oldCamType = camera.CameraType
    local oldCF      = hrp.CFrame

    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    humanoid.AutoRotate = false
    camera.CameraType   = Enum.CameraType.Scriptable

    hrp.CFrame = CFrame.new(petal.Position + Vector3.new(0, 2, 0))
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    task.wait(TELEPORT_WAIT)

    hrp.CFrame = oldCF
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    task.wait(0.05)

    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    humanoid.AutoRotate = true
    pcall(function() camera.CameraType = oldCamType end)

    return true
end

-- ══════════════════════════════════════
task.spawn(function()
    print("✅ Petal Collector запущен (авто)")

    while true do
        scanPetals()

        while #queue > 0 do
            local entry = table.remove(queue, 1)

            if entry.part.Parent then
                local ok = teleportTo(entry.part)
                if ok then
                    print(string.format(
                        "✅ [%s] приоритет %d",
                        entry.color, entry.priority
                    ))
                end
                task.wait(COLLECT_DELAY)
            end
        end

        task.wait(CHECK_INTERVAL)
    end
end)
