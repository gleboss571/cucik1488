-- Crosshair Collector
-- V (зажать) = лутать → отпустить = вернуться
-- Запоминает собранные, повторно не лутает

local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Particles   = Workspace:FindFirstChild("Particles")

local COLLECT_DELAY = 0.12
local LOGS = false

local isCollecting = false
local startPosition = nil
local collectedSet = {}

local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- Индикаторы
local function createIndicator(part, wasCollected)
    if not part:IsA("BasePart") then return end
    local old = part:FindFirstChild("CrosshairIndicator")
    if old then old:Destroy() end

    local gui = Instance.new("BillboardGui")
    gui.Name = "CrosshairIndicator"
    gui.Adornee = part
    gui.Size = UDim2.new(0, 30, 0, 30)
    gui.StudsOffset = Vector3.new(0, 4, 0)
    gui.AlwaysOnTop = true
    gui.Parent = part

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = wasCollected and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
end

if Particles then
    Particles.DescendantAdded:Connect(function(obj)
        if obj.Name == "Crosshair" and obj:IsA("BasePart") then
            createIndicator(obj, false)
        end
    end)
    for _, obj in ipairs(Particles:GetDescendants()) do
        if obj.Name == "Crosshair" and obj:IsA("BasePart") then
            createIndicator(obj, false)
        end
    end
end

-- Сбор
local function collectCrosshairs()
    isCollecting = true
    local root = getRoot()
    if not root then isCollecting = false return end

    startPosition = root.CFrame

    local camType = Camera.CameraType
    local camCF = Camera.CFrame
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = camCF

    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = false end

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

    root = getRoot()
    if root and startPosition then
        root.CFrame = startPosition
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    if hum then
        hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end

    Camera.CameraType = camType
    isCollecting = false
end

-- V зажать/отпустить
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.V and not isCollecting then
        task.spawn(collectCrosshairs)
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.V then
        isCollecting = false
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    collectedSet = {}
end)

if LOGS then
    print("🎯 Crosshair Collector | V = collect")
end
