local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- SETTINGS

local ENABLED = true

local PETAL_NAME = "PetalPart"

local TELEPORT_INTERVAL = 0.4

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

-- FIND NEAREST PETAL

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

    if busy then return end
    if not petal then return end
    if not petal.Parent then return end

    local char = getCharacter()
    local hrp = getHRP()

    if not char or not hrp then
        return
    end

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

    -- stabilize
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    -- ULTRA FAST TP
    pcall(function()

        hrp.CFrame = petal.CFrame

        firetouchinterest(hrp, petal, 0)
        firetouchinterest(hrp, petal, 1)

        RunService.RenderStepped:Wait()

        hrp.CFrame = oldCF

        RunService.RenderStepped:Wait()

        hrp.CFrame = oldCF
    end)

    -- stabilize again
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

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

print("✅ Ultra Fast Hidden Petal Collector Loaded")
print("R = Toggle")
