local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Particles = Workspace:FindFirstChild("Particles")

if not Particles then return warn("Particles not found") end

local LOGS = false

local activeDisks = 0
local coconutEquipped = false

local function isTargetWarningDisk(obj)
    if obj.Name ~= "WarningDisk" or not obj:IsA("BasePart") then return false end
    local r, g, b = obj.Color.R, obj.Color.G, obj.Color.B
    if math.abs(r - 0.988) > 0.01 or math.abs(g) > 0.01 or math.abs(b - 0.0235) > 0.01 then return false end
    local sx, sy, sz = obj.Size.X, obj.Size.Y, obj.Size.Z
    if math.abs(sx - 8) > 0.1 or math.abs(sy - 0.4) > 0.05 or math.abs(sz - 8) > 0.1 then return false end
    local mesh = obj:FindFirstChildOfClass("CylinderMesh")
    if not mesh then return false end
    local mx, my, mz = mesh.Scale.X, mesh.Scale.Y, mesh.Scale.Z
    if math.abs(mx - 0.9) > 0.05 or math.abs(my - 0.4) > 0.05 or math.abs(mz - 0.9) > 0.05 then return false end
    return true
end

local function equipItem(itemType)
    local event = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent")
    local ok, err = pcall(function()
        return event:InvokeServer("Equip", {
            Category = "Accessory",
            Type = itemType,
        })
    end)
    if LOGS then
        if ok then
            print(itemType .. " equipped")
        else
            warn("Equip failed:", itemType, err)
        end
    end
end

local function onDiskAdded(obj)
    activeDisks = activeDisks + 1
    if LOGS then print("🔴 WarningDisk появился | Всего: " .. activeDisks) end
    if not coconutEquipped then
        if LOGS then print("🎒 Надеваю Coconut Canister") end
        equipItem("Coconut Canister")
        coconutEquipped = true
    end
end

local function onDiskRemoved(obj)
    activeDisks = activeDisks - 1
    if activeDisks <= 0 then activeDisks = 0 end
    if LOGS then print("⬛ WarningDisk исчез | Осталось: " .. activeDisks) end
    if activeDisks <= 0 and coconutEquipped then
        if LOGS then print("🎒 Надеваю Red Port-O-Hive") end
        equipItem("Red Port-O-Hive")
        coconutEquipped = false
    end
end

local trackedDisks = {}

local function trackDisk(obj)
    if trackedDisks[obj] then return end
    trackedDisks[obj] = true
    onDiskAdded(obj)

    obj.AncestryChanged:Connect(function()
        if not obj:IsDescendantOf(Workspace) and trackedDisks[obj] then
            trackedDisks[obj] = nil
            onDiskRemoved(obj)
        end
    end)
end

Particles.DescendantAdded:Connect(function(obj)
    if isTargetWarningDisk(obj) then
        trackDisk(obj)
    end
end)

for _, obj in ipairs(Particles:GetDescendants()) do
    if isTargetWarningDisk(obj) then
        trackDisk(obj)
    end
end

if LOGS then print("WarningDisk Equip Switcher loaded") end
