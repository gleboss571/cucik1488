-- ╔══════════════════════════════════════╗
-- ║     Petal Collector — BSS            ║
-- ║  R — вкл/выкл  |  автосбор лепестков ║
-- ╚══════════════════════════════════════╝

local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PETAL_NAME  = "PetalPart"

-- ┌─────────────────────────────────────┐
-- │  Приоритеты (1 = важнее всего)      │
-- │  Порог = минимальный стак для сбора  │
-- └─────────────────────────────────────┘
local PETAL_CONFIG = {
    -- цвет         приоритет  порог стаков
    Merigold    = { priority = 1, threshold = 0  },
    Green       = { priority = 2, threshold = 0  },
    Periwinkle  = { priority = 3, threshold = 0  },
    Pink        = { priority = 4, threshold = 0  },
    Cyan        = { priority = 5, threshold = 0  },
    Blue        = { priority = 6, threshold = 0  },
    Gray        = { priority = 7, threshold = 0  },
    Black       = { priority = 8, threshold = 0  },
    Scarlet     = { priority = 9, threshold = 0  },
    Violet      = { priority = 10, threshold = 0 },
    -- остальные — низкий приоритет
    DEFAULT     = { priority = 99, threshold = 0 },
}

local TELEPORT_WAIT  = 0.08   -- сек удержания у лепестка
local CHECK_INTERVAL = 0.15   -- сек между сканированием
local COLLECT_DELAY  = 1.2   -- сек между сборами в очереди

-- ══════════════════════════════════════
local enabled      = false
local collecting   = false
local seen         = {}       -- [BasePart] = true, слабая очистка по Parent
local queue        = {}       -- отсортированная очередь на сбор

-- ──────────────────────────────────────
local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hrp      = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return nil, nil, nil end
    return char, hrp, humanoid
end

-- Очистка мёртвых ссылок из seen
local function cleanSeen()
    for obj in pairs(seen) do
        if not obj.Parent then
            seen[obj] = nil
        end
    end
end

-- Получить приоритет по цвету (имя объекта или атрибут Color)
local function getPriority(petal)
    -- Пробуем атрибут "Color" или "PetalColor", затем имя
    local color = petal:GetAttribute("Color")
              or  petal:GetAttribute("PetalColor")
    if not color then
        -- fallback: ищем цвет в имени дочерних объектов / самого Part
        for name in pairs(PETAL_CONFIG) do
            if petal.Name:find(name) then
                color = name
                break
            end
        end
    end
    local cfg = PETAL_CONFIG[color] or PETAL_CONFIG.DEFAULT
    return cfg.priority, cfg.threshold, color
end

-- Собрать новые лепестки и добавить в очередь
local function scanPetals()
    cleanSeen()

    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return end

    local newOnes = {}
    for _, obj in ipairs(particles:GetChildren()) do
        if obj.Name == PETAL_NAME
        and obj:IsA("BasePart")
        and not seen[obj]
        then
            seen[obj] = true
            local priority, threshold, color = getPriority(obj)
            table.insert(newOnes, {
                part      = obj,
                priority  = priority,
                threshold = threshold,
                color     = color or "?",
            })
        end
    end

    if #newOnes == 0 then return end

    -- Добавляем и сортируем всю очередь по приоритету
    for _, entry in ipairs(newOnes) do
        table.insert(queue, entry)
    end
    table.sort(queue, function(a, b) return a.priority < b.priority end)
end

-- Телепорт к лепестку и обратно
local function teleportTo(petal)
    local _, hrp, humanoid = getChar()
    if not hrp or not humanoid then return false end
    if not petal or not petal.Parent then return false end

    local camera    = Workspace.CurrentCamera
    local oldCamType = camera.CameraType
    local oldCF     = hrp.CFrame
    local target    = petal.Position + Vector3.new(0, 2, 0)

    -- Замораживаем персонажа
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    humanoid.AutoRotate = false
    camera.CameraType   = Enum.CameraType.Scriptable

    hrp.CFrame = CFrame.new(target)
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    task.wait(TELEPORT_WAIT)

    -- Возврат
    hrp.CFrame = oldCF
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    task.wait(0.05)

    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    humanoid.AutoRotate = true
    pcall(function() camera.CameraType = oldCamType end)

    return true
end

-- Главный цикл сбора из очереди
local function startCollectLoop()
    if collecting then return end
    collecting = true

    task.spawn(function()
        while enabled do
            scanPetals()

            while #queue > 0 and enabled do
                local entry = table.remove(queue, 1)
                local petal = entry.part

                -- Лепесток уже исчез?
                if not petal.Parent then
                    task.wait()
                    continue
                end

                local ok = teleportTo(petal)
                if ok then
                    print(string.format(
                        "✅ [%s] приоритет %d",
                        entry.color, entry.priority
                    ))
                end

                task.wait(COLLECT_DELAY)
            end

            task.wait(CHECK_INTERVAL)
        end

        collecting = false
    end)
end

-- ══════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode ~= Enum.KeyCode.R then return end

    enabled = not enabled

    if enabled then
        seen  = {}
        queue = {}
        print("🟢 Petal Collector ON")
        startCollectLoop()
    else
        print("🔴 Petal Collector OFF")
    end
end)

print("✅ Petal Collector загружен. R — вкл/выкл")
