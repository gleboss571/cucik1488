-- PetalPart Gatherer (микро-телепорт с повторами и мгновенной реакцией)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ========== НАСТРОЙКИ ==========
local UPDATE_INTERVAL = 2.0               -- проверка каждые 2 сек (если не было события)
local PETAL_PART_NAME = "PetalPart"
local TELEPORT_OFFSET = 3                 -- высота над лепестком
local RETURN_DELAY = 0.2                  -- время касания (увеличено для надёжности)
local MAX_RETRIES = 3                     -- макс. повторов, если лепесток не собран
local RETRY_DELAY = 0.3                   -- задержка перед повтором

-- Цвета лепестков
local PETAL_COLORS = {
    ["Blue Petal"]    = Color3.fromRGB(33, 66, 249),
    ["Black Petal"]   = Color3.fromRGB(11, 11, 11),
    ["White Petal"]   = Color3.fromRGB(249, 249, 249),
    ["Green Petal"]   = Color3.fromRGB(35, 232, 5),
    ["Cyan Petal"]    = Color3.fromRGB(29, 196, 222),
    ["Violet Petal"]  = Color3.fromRGB(94, 38, 177),
    ["Yellow Petal"]  = Color3.fromRGB(238, 204, 79),
    ["Scarlet Petal"] = Color3.fromRGB(171, 19, 19),
    ["Merigold Petal"]= Color3.fromRGB(218, 168, 28),
    ["Red Petal"]     = Color3.fromRGB(249, 34, 34),
    ["Grey Petal"]    = Color3.fromRGB(127, 127, 127),
    ["Pink Petal"]    = Color3.fromRGB(255, 130, 201),
    ["Periwinkle Petal"] = Color3.fromRGB(150, 156, 236),
}

-- Пороги
local THRESHOLDS = { ["Red Petal"] = 5 }
local DEFAULT_THRESHOLD = 2

-- Приоритет цветов (число – место, меньше = выше)
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

local enabled = true
local isTeleporting = false

-- ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
local function colorEquals(c1, c2)
    return math.abs(c1.R - c2.R) < 0.01 and
           math.abs(c1.G - c2.G) < 0.01 and
           math.abs(c1.B - c2.B) < 0.01
end

local function getColorName(color)
    for name, col in pairs(PETAL_COLORS) do
        if colorEquals(col, color) then return name end
    end
    return "Unknown"
end

-- Получение всех уникальных лепестков (один на цвет, ближайший)
local function getAllUniquePetals()
    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return {} end
    local character = LocalPlayer.Character
    if not character then return {} end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end

    local colorToPart = {}
    for _, obj in ipairs(particles:GetChildren()) do
        if obj.Name == PETAL_PART_NAME and obj:IsA("BasePart") then
            local color = obj.Color
            local dist = (obj.Position - hrp.Position).Magnitude
            local foundKey = nil
            for c, data in pairs(colorToPart) do
                if colorEquals(c, color) then
                    foundKey = c
                    break
                end
            end
            if foundKey then
                if dist < colorToPart[foundKey].dist then
                    colorToPart[foundKey] = {part = obj, dist = dist}
                end
            else
                colorToPart[color] = {part = obj, dist = dist}
            end
        end
    end

    local result = {}
    for color, data in pairs(colorToPart) do
        table.insert(result, {
            name = getColorName(color),
            part = data.part,
            dist = data.dist
        })
    end
    return result
end

-- Получение активных баффов с оставшимся временем
local function fetchPlayerStats()
    local event = ReplicatedStorage:FindFirstChild("Events")
    if not event then return nil end
    local func = event:FindFirstChild("RetrievePlayerStats")
    if not func then return nil end
    local success, result = pcall(function() return func:InvokeServer() end)
    return success and result or nil
end

local function collectBuffs(data, results)
    if type(data) ~= "table" then return end
    if data.Src and data.Start and data.Dur then
        if PETAL_COLORS[data.Src] then
            table.insert(results, data)
        end
    end
    for _, v in pairs(data) do
        if type(v) == "table" then
            collectBuffs(v, results)
        end
    end
end

local function getActiveBuffRemaining()
    local stats = fetchPlayerStats()
    if not stats then return {} end
    local buffs = {}
    collectBuffs(stats, buffs)
    local active = {}
    for _, buff in ipairs(buffs) do
        local remaining = (buff.Start + buff.Dur) - os.time()
        if remaining > 0 then
            active[buff.Src] = remaining
        end
    end
    return active
end

-- Сортировка кандидатов по приоритету
local function sortByPriority(candidates)
    table.sort(candidates, function(a, b)
        local pa = COLOR_PRIORITY[a.name] or 999
        local pb = COLOR_PRIORITY[b.name] or 999
        if pa ~= pb then return pa < pb end
        return math.random() < 0.5
    end)
    return candidates
end

-- Выбор лучшей цели для телепорта (с учётом порогов)
local function selectTarget()
    local petals = getAllUniquePetals()
    if #petals == 0 then return nil end
    local buffs = getActiveBuffRemaining()
    local candidates = {}
    for _, p in ipairs(petals) do
        local remaining = buffs[p.name]
        local threshold = THRESHOLDS[p.name] or DEFAULT_THRESHOLD
        if remaining then
            if remaining < threshold then
                table.insert(candidates, p)
            end
        else
            table.insert(candidates, p)
        end
    end
    if #candidates == 0 then return nil end
    local sorted = sortByPriority(candidates)
    return sorted[1].part
end

-- Проверка, подходит ли конкретный лепесток для сбора (для события ChildAdded)
local function isPetalEligible(petal)
    if not petal or not petal:IsA("BasePart") then return false end
    local name = getColorName(petal.Color)
    if name == "Unknown" then return false end
    local buffs = getActiveBuffRemaining()
    local remaining = buffs[name]
    local threshold = THRESHOLDS[name] or DEFAULT_THRESHOLD
    if remaining then
        return remaining < threshold
    else
        return true
    end
end

-- ========== МИКРО-ТЕЛЕПОРТ С ПОВТОРАМИ ==========
local function teleportToPetal(petal, reason, retryCount)
    retryCount = retryCount or 0
    if not petal or not petal.Parent or isTeleporting then return false end
    isTeleporting = true

    local character = LocalPlayer.Character
    if not character then isTeleporting = false; return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not hrp or not humanoid then isTeleporting = false; return false end

    local originalPos = hrp.CFrame
    local colorName = getColorName(petal.Color)

    -- Фиксация камеры
    local oldCamType = Camera.CameraType
    local oldCamCF = Camera.CFrame
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = oldCamCF

    -- Отключение физики
    humanoid.AutoRotate = false
    humanoid.PlatformStand = true
    hrp.Velocity = Vector3.new(0,0,0)
    hrp.RotVelocity = Vector3.new(0,0,0)

    -- Телепорт к лепестку
    hrp.CFrame = petal.CFrame + Vector3.new(0, TELEPORT_OFFSET, 0)
    task.wait(RETURN_DELAY)

    -- Возврат
    hrp.CFrame = originalPos
    task.wait(0.05)
    hrp.CFrame = originalPos   -- фиксация

    hrp.Velocity = Vector3.new(0,0,0)
    hrp.RotVelocity = Vector3.new(0,0,0)

    -- Восстановление
    humanoid.PlatformStand = false
    humanoid.AutoRotate = true
    Camera.CameraType = oldCamType

    hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.5, 0)
    task.wait(0.05)

    isTeleporting = false

    -- Проверяем, собран ли лепесток (исчез ли)
    if petal.Parent then
        -- Не исчез – повторяем, если не превышен лимит
        if retryCount < MAX_RETRIES then
            print(string.format("⚠️ Лепесток %s не собран, повтор %d...", colorName, retryCount+1))
            task.wait(RETRY_DELAY)
            return teleportToPetal(petal, reason, retryCount+1)
        else
            print(string.format("❌ Лепесток %s не собран после %d попыток", colorName, MAX_RETRIES))
            return false
        end
    else
        print(string.format("✅ Собран лепесток %s (%s) — %s", petal.Name, colorName, reason))
        return true
    end
end

-- ========== ОСНОВНОЙ ПЕРИОДИЧЕСКИЙ ЦИКЛ ==========
task.spawn(function()
    while true do
        if enabled and not isTeleporting then
            local target = selectTarget()
            if target then
                teleportToPetal(target, "периодический сбор", 0)
            end
        end
        task.wait(UPDATE_INTERVAL)
    end
end)

-- ========== МГНОВЕННАЯ РЕАКЦИЯ НА ПОЯВЛЕНИЕ ЛЕПЕСТКА ==========
local particles = Workspace:FindFirstChild("Particles")
if particles then
    particles.ChildAdded:Connect(function(child)
        if enabled and not isTeleporting and child.Name == PETAL_PART_NAME and child:IsA("BasePart") then
            if isPetalEligible(child) then
                -- Небольшая задержка, чтобы игра успела зарегистрировать лепесток
                task.wait(0.1)
                teleportToPetal(child, "мгновенная реакция", 0)
            end
        end
    end)
end

-- ========== ВКЛ/ВЫКЛ ПО R ==========
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.R then
        enabled = not enabled
        print(enabled and "🟢 Сбор включён" or "🔴 Сбор выключен")
    end
end)

print("✅ PetalPart Gatherer (микро-телепорт + повторы + мгновенная реакция) загружен")
print("Нажмите R для вкл/выкл | Пороги: Red<5с, остальные<2с | Время касания: 0.2с")
