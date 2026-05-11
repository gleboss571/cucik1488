-- Sprinkler на FP18-10-13: один раз при запуске

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local char        = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp         = char:WaitForChild("HumanoidRootPart")
local hum         = char:WaitForChild("Humanoid")
local flower      = Workspace.Flowers:FindFirstChild("FP18-10-13")
local PAC         = ReplicatedStorage.Events.PlayerActivesCommand

local savedCF = hrp.CFrame
local camType = Camera.CameraType
local camCF   = Camera.CFrame

Camera.CameraType = Enum.CameraType.Scriptable
Camera.CFrame = camCF
hum.AutoRotate = false

local target = CFrame.new(flower.Position + Vector3.new(0, 3, 0))

local t = tick()
while tick() - t < 0.3 do
    hrp.CFrame = target
    hrp.AssemblyLinearVelocity = Vector3.zero
    RunService.Heartbeat:Wait()
end

PAC:FireServer({Name = "Sprinkler Builder"})

for i = 1, 3 do
    hrp.CFrame = target
    hrp.AssemblyLinearVelocity = Vector3.zero
    RunService.Heartbeat:Wait()
end

hrp.CFrame = savedCF
hrp.AssemblyLinearVelocity = Vector3.zero
task.wait(0.05)
hrp.CFrame = savedCF
hrp.AssemblyLinearVelocity = Vector3.zero

hum.AutoRotate = true
hum:ChangeState(Enum.HumanoidStateType.Running)
Camera.CameraType = camType

print("✅ Sprinkler → FP18-10-13")
