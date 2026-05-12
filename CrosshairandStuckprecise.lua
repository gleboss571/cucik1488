--================================================================
-- BSS Precise Bee + Crosshair Collector
--
-- Y = toggle прецайсы на цветках (вкл/выкл)
-- V (зажать) = собирать Crosshair с возвратом
-- Запоминает собранные метки — повторно не лутает
--================================================================

local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Flowers     = Workspace:FindFirstChild("Flowers")
local Bees        = Workspace:FindFirstChild("Bees")
local Particles   = Workspace:FindFirstChild("Particles")

--================================================================
-- НАСТРОЙКИ
--================================================================
local BEE_HEIGHT     = 8
local COLLECT_DELAY  = 0.12

local FLOWER_NAMES = {
    "FP18-14-4",
    "FP18-10-4",
    "FP18-6-4",
    "FP18-6-22",
    "FP18-10-22",
    "FP18-14-22",
    "FP18-18-13",
    "FP18-2-13",
}

--================================================================
-- СОСТОЯНИЕ
--================================================================
local beeControlEnabled = false
local isCollecting      = false
local startPosition     = nil
local collectedSet      = {}  -- запоминаем собранные метки

--================================================================
-- GC SCAN
--================================================================
local targetFunc
for _,v in pairs(getgc(true)) do
    if typeof(v) == "function" then
        local ok,c = pcall(debug.getconstants, v)
        if ok and c and table.find(c,"FlyingEntityMoveToPart") and table.find(c,"FlyingEntityCreate") then
            targetFunc = v
            break
        end
    end
end
if not targetFunc then return print("no targetFunc") end

local controller = debug.getupvalues(targetFunc)[6]
local entities   = debug.getupvalues(targetFunc)[5]
if not entities or not controller then return print("no entities/controller") end

--================================================================
-- ПОЗИЦИИ ЦВЕТКОВ
--================================================================
local flowerPositions = {}
if Flowers then
    for i, name in ipairs(FLOWER_NAMES) do
        local f = Flowers:FindFirstChild(name)
        if f and f:IsA("BasePart") then
            flowerPositions[i] = f.Position + Vector3.new(0, BEE_HEIGHT, 0)
        end
    end
end

--================================================================
-- FIND PRECISE BEES
--================================================================
local preciseData = {}

local function initPrecise()
    if #preciseData > 0 then return end
    if not Bees then return end

    local models = {}
    for _,b in ipairs(Bees:GetChildren()) do
        if b.Name == "Precise" then models[#models+1] = b end
    end

    local used = {}
    for _,model in ipairs(models) do
        local mPos = model.Position
        local best, bestD, bestI = nil, 10, nil
        for idx,ent in pairs(entities) do
            if type(ent)=="table" and ent.TypeName=="Bee" and ent.Pos and not used[idx] then
                local d = (ent.Pos - mPos).Magnitude
                if d < bestD then best,bestD,bestI = ent,d,idx end
            end
        end
        if best and bestI then
            used[bestI] = true
            local flowerIdx = #preciseData + 1
            preciseData[flowerIdx] = {
                entity    = best,
                targetPos = flowerPositions[flowerIdx],
            }
        end
    end
    print("Precise: " .. #preciseData .. " | Flowers: " .. #flowerPositions)
end

initPrecise()

--================================================================
-- UPDATE BEES — без принудительного Facing
--================================================================
local function updateBees()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _,d in ipairs(preciseData) do
        local bee = d.entity
        local pos = d.targetPos or (root.Position + Vector3.new(0, 6, 0))

        bee.Pos = pos
        bee.PosNext = pos
        bee.PosLast = pos
        bee.DestPosLast = pos
        bee.Moving = false
        pcall(function() controller.CancelMovement(bee) end)
    end
end

--================================================================
-- BEE CONTROL LOOP
--================================================================
task.spawn(function()
    while true do
        if beeControlEnabled then
            if #preciseData == 0 then initPrecise() end
            updateBees()
        end
        task.wait(0.05)
    end
end)

--================================================================
-- CROSSHAIR INDICATORS
--================================================================
local function createIndicator(part, wasCollected)
    if not part:IsA("BasePart") then return end
    local old = part:FindFirstChild("CrosshairIndicator")
    if old then old:Destroy() end

    local color = wasCollected and Color3.new(0,1,0) or Color3.new(1,0,0)
    local gui = Instance.new("BillboardGui")
    gui.Name = "CrosshairIndicator"
    gui.Adornee = part
    gui.Size = UDim2.new(0, 30, 0, 30)
    gui.StudsOffset = Vector3.new(0, 4, 0)
    gui.AlwaysOnTop = true
    gui.Parent = part

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = color
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
end

-- Новые Crosshair — ставим индикатор
if Particles then
    Particles.DescendantAdded:Connect(function(obj)
        if obj.Name == "Crosshair" and obj:IsA("BasePart") then
            createIndicator(obj, false)
        end
    end)
end

-- Существующие
if Particles then
    for _, obj in ipairs(Particles:GetDescendants()) do
        if obj.Name == "Crosshair" and obj:IsA("BasePart") then
            createIndicator(obj, false)
        end
    end
end

--================================================================
-- CROSSHAIR COLLECTION (V зажать)
--================================================================
local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function collectCrosshairs()
    isCollecting = true
    local root = getRoot()
    if not root then isCollecting = false return end

    startPosition = root.CFrame

    -- Замораживаем камеру
    local savedCamType = Camera.CameraType
    local savedCamCF   = Camera.CFrame
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = savedCamCF

    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.AutoRotate = false end

    while isCollecting do
        if not Particles then break end

        local target = nil
        for _, obj in ipairs(Particles:GetDescendants()) do
            if obj.Name == "Crosshair" and obj:IsA("BasePart") and not collectedSet[obj] then
                target = obj
                break
            end
        end

        if target then
            root = getRoot()
            if not root then break end

            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))

            collectedSet[target] = true
            createIndicator(target, true)

            task.wait(COLLECT_DELAY)
        else
            task.wait(0.15)
        end
    end

    -- Возврат
    root = getRoot()
    if root and startPosition then
        root.CFrame = startPosition
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    if humanoid then
        humanoid.AutoRotate = true
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end

    Camera.CameraType = savedCamType

    -- Обновляем позиции пчёл после возврата
    if beeControlEnabled then updateBees() end

    isCollecting = false
end

--================================================================
-- KEYBINDS
--================================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- Y = toggle прецайсы
    if input.KeyCode == Enum.KeyCode.Y then
        beeControlEnabled = not beeControlEnabled
        if beeControlEnabled and #preciseData == 0 then initPrecise() end
        print(beeControlEnabled and "🟢 Precise ON" or "🔴 Precise OFF")
    end

    -- V = собирать Crosshair (зажать)
    if input.KeyCode == Enum.KeyCode.V and not isCollecting then
        task.spawn(collectCrosshairs)
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end

    -- V отпущен = стоп + возврат
    if input.KeyCode == Enum.KeyCode.V then
        isCollecting = false
    end
end)

--================================================================
-- РЕСПАВН
--================================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(2)
    -- Сохраняем цветки
    local savedFlowers = {}
    for i,d in ipairs(preciseData) do
        savedFlowers[i] = d.targetPos
    end
    preciseData = {}
    initPrecise()
    for i,pos in pairs(savedFlowers) do
        if preciseData[i] then
            preciseData[i].targetPos = pos
        end
    end
    -- Сбрасываем собранные метки (новая жизнь)
    collectedSet = {}
end)

--================================================================
-- READY
--================================================================
print("🎯 Precise + Crosshair Collector")
print("  Y = toggle прецайсы на цветках")
print("  V (зажать) = лутать Crosshair → отпустить = вернуться")
print("  Precise: " .. #preciseData)
print("  Flowers: " .. #flowerPositions)
