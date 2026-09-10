local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ABILITY_TOKEN_MULTIPLIER = 1.22
local DIGITAL_BEE_LEVEL = 22
local DUPED_HEIGHT_THRESHOLD = 5
local LOGS = false

local function getPlayerRoot()
    if LocalPlayer and LocalPlayer.Character then
        return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local tokens = {
    [1472532912] = { name = "Polar Bear", base = 15, normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), prefix = "MO " },
    [1472491940] = { name = "Black Bear", base = 15, normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), prefix = "MO " },
    [1472425802] = { name = "Brown Bear", base = 15, normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), prefix = "MO " },
    [2032949183] = { name = "Mother Bear", base = 15, normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), prefix = "MO " },
    [1472580249] = { name = "Panda", base = 15, normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), prefix = "MO " },
    [1489734171] = { name = "Science Bear", base = 15, normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), prefix = "MO " },
    [2000457501] = { name = "Inspire", base = 8, normalColor = Color3.new(1, 1, 0), dupedColor = Color3.new(1, 0.84, 0), bgColor = Color3.new(0,0,0), prefix = "IN " },
    [1629547638] = { name = "Token Link", base = 4, normalColor = Color3.new(0,0,0), dupedColor = nil, bgColor = Color3.new(1,1,1), prefix = "TL " },
    [5877939956] = { name = "Glitch", base = 4, normalColor = Color3.new(1,1,1), dupedColor = Color3.new(1,1,1), bgColor = Color3.new(0,0,0), prefix = "SM " },
    [8173559749] = { name = "TP", base = 8, normalColor = Color3.new(0.7, 0.2, 0.9), dupedColor = Color3.new(0.5, 0.1, 0.7), bgColor = Color3.new(0,0,0), prefix = "TP " },
}

local activeTokens = {}

local function getTextureId(texture)
    local id = texture:match("id=(%d+)") or texture:match("rbxassetid://(%d+)")
    return id and tonumber(id)
end

local function isTargetToken(obj)
    if obj.Name ~= "C" or not obj:IsA("BasePart") then return false, nil end
    local front = obj:FindFirstChild("FrontDecal")
    if not front or not front:IsA("Decal") then return false, nil end
    local id = getTextureId(front.Texture)
    if id and tokens[id] then return true, id end
    return false, nil
end

local function isDuped(part)
    local root = getPlayerRoot()
    if not root then return false end
    return (part.Position.Y - root.Position.Y) > DUPED_HEIGHT_THRESHOLD
end

local function calculateLifetime(base, duped)
    local normal = base * ABILITY_TOKEN_MULTIPLIER
    if not duped then return normal end
    local dupedMultiplier = 2 + 0.05 * (DIGITAL_BEE_LEVEL - 1)
    return normal * dupedMultiplier
end

local function createTimer(part, id)
    if activeTokens[part] then return end
    local data = tokens[id]
    local duped = isDuped(part)

    if duped and id == 1629547638 then return end

    local totalLifetime = calculateLifetime(data.base, duped)

    local gui = Instance.new("BillboardGui")
    gui.Adornee = part
    gui.Size = UDim2.new(0, 80, 0, 24)
    gui.StudsOffset = Vector3.new(0, 2, 0)
    gui.AlwaysOnTop = true
    gui.Parent = part

    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 0.2
    label.BackgroundColor3 = data.bgColor
    label.TextColor3 = duped and (data.dupedColor or data.normalColor) or data.normalColor
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold

    local prefix = data.prefix or ""
    label.Text = prefix .. string.format("%.1f", totalLifetime)

    activeTokens[part] = {
        gui = gui,
        label = label,
        startTime = tick(),
        totalLifetime = totalLifetime,
        prefix = prefix,
        duped = duped,
        id = id
    }

    if LOGS then
        print("➕", data.name, duped and "(DUPED)" or "")
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    local ok, id = isTargetToken(obj)
    if ok then createTimer(obj, id) end
end)

game.DescendantRemoving:Connect(function(obj)
    if activeTokens[obj] then
        activeTokens[obj].gui:Destroy()
        activeTokens[obj] = nil
    end
end)

RunService.Heartbeat:Connect(function()
    local now = tick()
    for part, data in pairs(activeTokens) do
        if part and part.Parent then
            local remaining = data.totalLifetime - (now - data.startTime)
            if remaining > 0 then
                data.label.Text = data.prefix .. string.format("%.1f", remaining)
            else
                data.label.Text = data.prefix .. "0.0"
            end
        else
            if data.gui then data.gui:Destroy() end
            activeTokens[part] = nil
        end
    end
end)

if LOGS then
    print("✅ Token Timer loaded | Digital Bee Lvl:", DIGITAL_BEE_LEVEL)
end
