-- Bee Swarm - Petal Collector + Bee Return DEBUG

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Events = ReplicatedStorage:WaitForChild("Events")
local BeeMoveRemote = Events:WaitForChild("FlyingEntityMoveToPart")

local ENABLED = false
local busy = false

local TELEPORT_DELAY = 1.2

print("✅ Bee Return Collector Loaded")

-- HELPERS

local function getCharacter()
    return LocalPlayer.Character
end

local function getHRP()

    local char = getCharacter()

    if not char then
        return nil
    end

    return char:FindFirstChild("HumanoidRootPart")
end

-- FIND PETAL

local function getNearestPetal()

    local particles = Workspace:FindFirstChild("Particles")
    local hrp = getHRP()

    if not particles or not hrp then
        return nil
    end

    local nearest = nil
    local shortest = math.huge

    for _,v in ipairs(particles:GetChildren()) do

        if v:IsA("BasePart") and v.Name == "PetalPart" then

            local dist = (v.Position - hrp.Position).Magnitude

            if dist < shortest then
                shortest = dist
                nearest = v
            end
        end
    end

    return nearest
end

-- RETURN BEES

local function forceBeesBack()

    local hrp = getHRP()

    if not hrp then
        return
    end

    print("🐝 Attempting to return bees...")

    local success, err = pcall(function()

        firesignal(
            BeeMoveRemote.OnClientEvent,

            999999,

            "Workspace.GhostPlayerParts.HumanoidRootPart",

            hrp.Position.X,
            hrp.Position.Y,
            hrp.Position.Z,

            1
        )
    end)

    if success then
        print("✅ Bee return signal fired")
    else
        warn("❌ Bee return failed:", err)
    end
end

-- COLLECT

local function collectPetal(petal)

    if busy then
        return
    end

    if not petal or not petal.Parent then
        return
    end

    local char = getCharacter()
    local hrp = getHRP()

    if not char or not hrp then
        return
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return
    end

    busy = true

    local oldCF = hrp.CFrame

    local oldCamType = Camera.CameraType
    local oldCamCF = Camera.CFrame

    -- freeze camera
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = oldCamCF

    -- stop physics
    humanoid.AutoRotate = false

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    -- TP
    hrp.CFrame = petal.CFrame + Vector3.new(0, 2, 0)

    pcall(function()

        firetouchinterest(hrp, petal, 0)
        firetouchinterest(hrp, petal, 1)
    end)

    RunService.RenderStepped:Wait()

    -- return
    hrp.CFrame = oldCF

    -- stabilize
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    -- FIX FALLING
    humanoid:ChangeState(Enum.HumanoidStateType.Running)

    task.wait(0.03)

    humanoid.AutoRotate = true

    -- return bees
    forceBeesBack()

    -- restore camera
    Camera.CameraType = oldCamType
    Camera.CFrame = oldCamCF

    busy = false
end

-- LOOP

task.spawn(function()

    while true do

        if ENABLED and not busy then

            local petal = getNearestPetal()

            if petal then
                collectPetal(petal)
            end
        end

        task.wait(TELEPORT_DELAY)
    end
end)

-- TOGGLE

UserInputService.InputBegan:Connect(function(input,gp)

    if gp then
        return
    end

    if input.KeyCode == Enum.KeyCode.R then

        ENABLED = not ENABLED

        print(ENABLED and "🟢 ENABLED" or "🔴 DISABLED")
    end
end)

print("Press R to toggle")
