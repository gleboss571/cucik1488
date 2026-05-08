local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- SETTINGS
local ENABLED = true

local PETAL_NAME = "PetalPart"

local TELEPORT_INTERVAL = 1
local HOLD_TIME = 0.2

local busy = false

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

local function getNearestPetal()

    local particles = Workspace:FindFirstChild("Particles")
    local hrp = getHRP()

    if not particles or not hrp then
        return nil
    end

    local nearest = nil
    local shortest = math.huge

    for _,v in ipairs(particles:GetChildren()) do

        if v:IsA("BasePart") and v.Name == PETAL_NAME then

            local dist = (v.Position - hrp.Position).Magnitude

            if dist < shortest then
                shortest = dist
                nearest = v
            end
        end
    end

    return nearest
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

    busy = true

    local oldCF = hrp.CFrame

    local oldCamType = Camera.CameraType
    local oldCamCF = Camera.CFrame

    -- freeze camera
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = oldCamCF

    -- hide character locally
    local hidden = {}

    for _,v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            hidden[v] = v.LocalTransparencyModifier
            v.LocalTransparencyModifier = 1
        end
    end

    -- physics protection
    if humanoid then
        humanoid.AutoRotate = false
        humanoid.PlatformStand = true
    end

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    -- REAL TP
    pcall(function()

        hrp.CFrame = petal.CFrame + Vector3.new(0,2.5,0)

        firetouchinterest(hrp, petal, 0)
        firetouchinterest(hrp, petal, 1)
    end)

    local start = tick()

    while tick() - start < HOLD_TIME do
        Camera.CFrame = oldCamCF
        RunService.RenderStepped:Wait()
    end

    -- return
    hrp.CFrame = oldCF

    -- stabilize
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    task.wait(0.05)

    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
    end

    -- restore visibility
    for part,trans in pairs(hidden) do
        if part then
            part.LocalTransparencyModifier = trans
        end
    end

    Camera.CameraType = oldCamType
    Camera.CFrame = oldCamCF

    busy = false
end

-- MAIN LOOP

task.spawn(function()

    while true do

        if ENABLED and not busy then

            local petal = getNearestPetal()

            if petal and petal.Parent then
                collectPetal(petal)
            end
        end

        task.wait(TELEPORT_INTERVAL)
    end
end)

-- TOGGLE

UserInputService.InputBegan:Connect(function(input,gpe)

    if gpe then
        return
    end

    if input.KeyCode == Enum.KeyCode.R then

        ENABLED = not ENABLED

        print(ENABLED and "🟢 ENABLED" or "🔴 DISABLED")
    end
end)

print("✅ Hidden Petal Collector Loaded")
print("Press R to toggle")
