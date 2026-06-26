-- BSS AI v12.9 safe + Heartbeat-оптимизация, кольцо каждый кадр, Scorch roam 4s от флеймов
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")

local Q_VERSION = "12.9"
local ENABLED = true

-- ===================== GUI ОШИБОК (ПЕРВЫМ) =====================
local errorLog = {}
local errorGui = nil
local errorLabel = nil
local errorCopyBtn = nil
local errorCount = 0

local function createErrorGUI()
    pcall(function()
        if errorGui then return end
        errorGui = Instance.new("ScreenGui")
        errorGui.Name = "BSSAI_ErrorGUI"
        errorGui.ResetOnSpawn = false
        errorGui.Parent = PGui
        local bg = Instance.new("Frame")
        bg.Name = "ErrorPanel"
        bg.Size = UDim2.new(0, 360, 0, 220)
        bg.Position = UDim2.new(0.5, -180, 0.5, -110)
        bg.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        bg.BackgroundTransparency = 0.08
        bg.BorderSizePixel = 0
        bg.Active = true
        bg.Draggable = true
        bg.Parent = errorGui
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -16, 0, 24)
        title.Position = UDim2.new(0, 8, 0, 8)
        title.BackgroundTransparency = 1
        title.Text = "⚠️ BSS AI v12.9 — Статус"
        title.TextColor3 = Color3.fromRGB(255, 180, 60)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = bg
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, -16, 0, 1)
        line.Position = UDim2.new(0, 8, 0, 36)
        line.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
        line.BorderSizePixel = 0
        line.Parent = bg
        errorLabel = Instance.new("TextLabel")
        errorLabel.Size = UDim2.new(1, -16, 0, 120)
        errorLabel.Position = UDim2.new(0, 8, 0, 42)
        errorLabel.BackgroundTransparency = 1
        errorLabel.Text = "⏳ Инициализация..."
        errorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        errorLabel.Font = Enum.Font.Code
        errorLabel.TextSize = 11
        errorLabel.TextXAlignment = Enum.TextXAlignment.Left
        errorLabel.TextYAlignment = Enum.TextYAlignment.Top
        errorLabel.TextWrapped = true
        errorLabel.RichText = true
        errorLabel.Parent = bg
        errorCopyBtn = Instance.new("TextButton")
        errorCopyBtn.Size = UDim2.new(0, 100, 0, 28)
        errorCopyBtn.Position = UDim2.new(0, 8, 0, 170)
        errorCopyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        errorCopyBtn.BorderSizePixel = 0
        errorCopyBtn.Text = "📋 Копировать"
        errorCopyBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
        errorCopyBtn.Font = Enum.Font.Gotham
        errorCopyBtn.TextSize = 11
        errorCopyBtn.Parent = bg
        Instance.new("UICorner", errorCopyBtn).CornerRadius = UDim.new(0, 4)
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 80, 0, 28)
        closeBtn.Position = UDim2.new(0, 116, 0, 170)
        closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "✕ Закрыть"
        closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
        closeBtn.Font = Enum.Font.Gotham
        closeBtn.TextSize = 11
        closeBtn.Parent = bg
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
        closeBtn.MouseButton1Click:Connect(function()
            errorGui.Enabled = false
            errorGui:Destroy()
            errorGui = nil
        end)
        errorCopyBtn.MouseButton1Click:Connect(function()
            local txt = table.concat(errorLog, "\n")
            if #txt == 0 then txt = "Нет ошибок" end
            pcall(setclipboard, txt)
            errorCopyBtn.Text = "✅ Скопировано"
            task.wait(1.5)
            errorCopyBtn.Text = "📋 Копировать"
        end)
        task.spawn(function()
            task.wait(4)
            if errorGui and errorCount == 0 then
                errorGui.Enabled = false
                errorGui:Destroy()
                errorGui = nil
            end
        end)
    end)
end

local function logError(msg)
    errorCount = errorCount + 1
    local ts = string.format("[%02d] %s", errorCount, msg)
    table.insert(errorLog, ts)
    while #errorLog > 20 do table.remove(errorLog, 1) end
    if errorLabel then
        local lines = {}
        for i = math.max(1, #errorLog - 12), #errorLog do
            table.insert(lines, errorLog[i])
        end
        errorLabel.Text = table.concat(lines, "\n")
        if errorCount == 1 then
            errorLabel.TextColor3 = Color3.fromRGB(255, 140, 100)
        end
    end
    warn("BSSAI:", msg)
end

local function logInfo(msg)
    if errorLabel then
        errorLabel.Text = "✅ " .. msg
        errorLabel.TextColor3 = Color3.fromRGB(140, 255, 160)
    end
end

createErrorGUI()
logInfo("GUI ошибок запущен")

-- ===================== КОНФИГУРАЦИЯ =====================
local SPEED_BASE = {["НАБОР"] = 70, ["X10"] = 90, ["REFRESH"] = 75}
local SPEED_JITTER = 3
local ABILITY_MULT = 1.2
local DIG_BEE_LVL = 22
local FIELD_MARGIN = 3
local ARRIVE_DIST = 5
local MOVE_TIMEOUT = 6
local PREC_BUFF_ID = 2574507284
local PREC_PER_STACK = 0.02
local PREC_MAX = 10
local PREC_REFRESH_AT = 15
local PURPLE = Color3.fromRGB(119, 85, 255)
local PURPLE_TOL = 12
local PURPLE_STAND = 1
local SMILE_TOKEN_ID = 5877939956
local SMILE_REACT_TIME = 15
local TOKEN_STAND_DUR = 1.1
local CH_AVOID_RADIUS = 28
local CH_AVOID_STEER = 20
local CH_AVOID_DOT_MIN = 0.1
local AREA_RING_RADIUS = 20
local TL_INTERRUPT_DIST = 20
local PETAL_COLLECT_DIST = 8
local PETAL_FIELD_MARGIN = 20
local FLAME_HIT_AFTER = 5
local FLAME_HIT_DIST = 14
local TARGET_PRACTICE_ID = 8173559749
local TOKEN_LINK_COOLDOWN = 2
local PATROL_TIMEOUT = 8
local XFLAME_CENTER_RADIUS = 12
local SCORCH_ROAM_DIST = 4

local ALPHA = 0.5
local GAMMA = 0.95
local EPSILON = 0.3
local EPSILON_DECAY = 0.9995
local POLLEN_MARK_BUFF_ID = 2499540966

local TOKENS = {
    [1629547638] = {name = "Token Link", base = 4, prio = 99},
    [2000457501] = {name = "Inspire", base = 8, prio = 25},
    [1472256444] = {name = "Baby Love", base = 8, prio = 22},
    [1629649299] = {name = "Focus", base = 4, prio = 15},
    [65867881] = {name = "Haste", base = 4, prio = 15},
    [1442863423] = {name = "Blue Boost", base = 4, prio = 12},
    [1442859163] = {name = "Red Boost", base = 4, prio = 12},
    [3877732821] = {name = "White Boost", base = 4, prio = 12},
    [1442700745] = {name = "Rage", base = 8, prio = 10},
    [253828517] = {name = "Melody", base = 8, prio = 10},
    [1472532912] = {name = "Polar Bear", base = 15, prio = 8, mo = true},
    [1472491940] = {name = "Black Bear", base = 15, prio = 8, mo = true},
    [1472425802] = {name = "Brown Bear", base = 15, prio = 8, mo = true},
    [2032949183] = {name = "Mother Bear", base = 15, prio = 8, mo = true},
    [1472580249] = {name = "Panda", base = 15, prio = 8, mo = true},
    [1489734171] = {name = "Science Bear", base = 15, prio = 8, mo = true},
    [1874564120] = {name = "Pulse", base = 12, prio = 7},
    [2499514197] = {name = "Honey Mark", base = 8, prio = 7},
    [2499540966] = {name = "Pollen Mark", base = 8, prio = 7},
    [4528379338] = {name = "Mark Surge", base = 4, prio = 7},
    [3582501342] = {name = "Rain Call", base = 24, prio = 6},
    [3582519526] = {name = "Tornado", base = 24, prio = 6},
    [5877998606] = {name = "Mind Hack", base = 16, prio = 6},
    [8083943936] = {name = "Surprise Party", base = 24, prio = 6},
    [177997841] = {name = "Glob", base = 4, prio = 6},
    [1839454544] = {name = "Gummy Storm", base = 4, prio = 6},
    [1442725244] = {name = "Bomb", base = 4, prio = 5},
    [5877939956] = {name = "Smile Token", base = 4, prio = 5},
    [4519549299] = {name = "Inferno", base = 4, prio = 5},
    [4519523935] = {name = "Triangulate", base = 4, prio = 5},
    [4528414666] = {name = "Summon Frog", base = 8, prio = 5},
    [4528208186] = {name = "Flame Fuel", base = 8, prio = 5},
    [1671281844] = {name = "Beamstorm", base = 12, prio = 4},
    [1442764904] = {name = "Red Bomb Plus", base = 4, prio = 12},
    [8083436978] = {name = "Blue Balloon", base = 4, prio = 4},
    [1104415222] = {name = "BondToken", base = 4, prio = 4},
    [2319100769] = {name = "Fetch", base = 8, prio = 4},
    [4889322534] = {name = "Fuzz Bombs", base = 4, prio = 4},
    [2319083910] = {name = "Impale", base = 24, prio = 4},
    [3080529618] = {name = "Jelly Bean", base = 4, prio = 4},
    [4889470194] = {name = "Pollen Haze", base = 4, prio = 4},
    [8173559749] = {name = "Target Practice", base = 8, prio = 3},
    [107187190] = {name = "Honey Gift", base = 4, prio = 2},
    [183390139] = {name = "Cog", base = 4, prio = 2},
}

local AVOID = {
    [1674871631] = true, [1471882621] = true, [1952740625] = true, [8055428094] = true,
    [2319943273] = true, [3030569073] = true, [3036899811] = true, [3080740120] = true,
    [3012679515] = true, [1838129169] = true, [2584584968] = true, [1471849394] = true,
    [1952682401] = true, [6087969886] = true, [2028574353] = true, [2028453802] = true,
}

local PETAL_COLORS = {
    ["Red"] = Color3.fromRGB(249, 34, 34), ["Pink"] = Color3.fromRGB(255, 130, 201),
    ["Merigold"] = Color3.fromRGB(218, 168, 28), ["Periwinkle"] = Color3.fromRGB(150, 156, 236),
    ["Violet"] = Color3.fromRGB(94, 38, 177), ["Scarlet"] = Color3.fromRGB(171, 19, 19),
    ["Green"] = Color3.fromRGB(35, 232, 5), ["Yellow"] = Color3.fromRGB(238, 204, 79),
    ["Black"] = Color3.fromRGB(11, 11, 11), ["Grey"] = Color3.fromRGB(127, 127, 127),
    ["Blue"] = Color3.fromRGB(33, 66, 249), ["Cyan"] = Color3.fromRGB(29, 196, 222),
    ["White"] = Color3.fromRGB(249, 249, 249),
}

local PETAL_PRIORITY = {
    Red = 1, Pink = 2, Merigold = 3, Periwinkle = 4, Violet = 5,
    Scarlet = 6, Green = 7, Yellow = 8, Black = 9, Grey = 10,
    Blue = 11, Cyan = 12, White = 13,
}

-- ===================== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ =====================
local activeTokens = {}
local chQueue = {}
local lastPurple = nil
local curField = nil
local taskLabel = "старт"

local prec = {stacks = 0, value = 0, isX10 = false, localStart = 0, serverDur = 60, serverStart = 0, timeLeft = 0, needRefresh = false}
local cycle = {chCollectedCount = 0}
local stats = {tok = 0, ch = 0, purple = 0, x10 = 0, ref = 0, totalReward = 0, decisions = 0, smileCollected = 0, chAvoided = 0, petalsCollected = 0, flamesHit = 0}
local INTERRUPT = false
local trackedFlames = {}
local fieldPetals = {}
local areaRing = nil
local areaRingRadius = AREA_RING_RADIUS
local isCollectingSmile = false
local smileTarget = nil
local smileTargetRem = 0
local ignoreNewTokensUntil = 0
local activeBuffs = {ScorchingStar = {stacks = 0}, XFlame = {stacks = 0}, PreciseMark = {active = false}, PollenMark = {active = false, pos = nil}}
local stuckPetals = {}

local refreshCHCounter = 0
local refreshStartTime = 0

local hpsBuffer = {}
local actionBuffer = {}
local patternsHistory = {}
local bestAvgHPS = 0
local lastAnalyzeTime = 0
local hpsMeterLabel = nil
local patternFile = "bss_ai_pattern_v12.json"

local QTable = {}
local lastMoveTime = tick()
local stuckWarning = false
local xflameEmergency = false
local xflameCircle = nil
local scytheCircle = nil
local lastPenaltyTime = 0
local lastSpeedJitter = 0
local currentSpeed = SPEED_BASE["НАБОР"]
local lastScorchMove = 0

-- ===================== HEARTBEAT-СЧЁТЧИКИ =====================
local hbFrame = 0
local lastFieldScan = 0
local lastAreaRingScan = 0
local lastBuffScan = 0
local lastPrecScan = 0
local lastFlameScan = 0
local lastPetalScan = 0
local lastHPSRead = 0
local lastHPSSave = 0
local lastSpeedUpdate = 0
local lastSmileScan = 0
local lastQSave = 0

-- ===================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====================
local function getHRP()
    local c = LP.Character
    if c then return c:FindFirstChild("HumanoidRootPart") end
end

local function getHumanoid()
    local c = LP.Character
    if c then return c:FindFirstChildOfClass("Humanoid") end
end

local function texId(t)
    if not t then return nil end
    return tonumber(t:match("rbxassetid://(%d+)") or t:match("id=(%d+)"))
end

local function dist3(a, b)
    return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
end

local function dist3D(a, b)
    return (a - b).Magnitude
end

local function getPhase()
    if not prec.isX10 then return "НАБОР"
    elseif prec.needRefresh then return "REFRESH"
    else return "X10" end
end

-- ===================== ДЕТЕКТОР ПОЛЯ =====================
local function findCurrentField()
    local r = getHRP()
    if not r then return curField end
    local myPos = r.Position
    local zones = Workspace:FindFirstChild("FlowerZones")
    if zones then
        local best = nil; local bestDist = math.huge
        for _, zone in ipairs(zones:GetChildren()) do
            if zone:IsA("BasePart") then
                local d = dist3(myPos, zone.Position); local s = zone.Size
                if math.abs(myPos.X - zone.Position.X) <= s.X/2 + 20 and
                   math.abs(myPos.Z - zone.Position.Z) <= s.Z/2 + 20 then
                    if d < bestDist then bestDist = d; best = zone end
                end
            end
        end
        if best then curField = {part = best}; return curField end
    end
    local flowers = Workspace:FindFirstChild("Flowers")
    if flowers then
        local fParts = {}
        for _, f in ipairs(flowers:GetChildren()) do
            if f:IsA("BasePart") then table.insert(fParts, f.Position) end
        end
        if #fParts > 0 then
            local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
            for _, p in ipairs(fParts) do
                if p.X < minX then minX = p.X end; if p.X > maxX then maxX = p.X end
                if p.Z < minZ then minZ = p.Z end; if p.Z > maxZ then maxZ = p.Z end
            end
            curField = {part = {Position = Vector3.new((minX+maxX)/2, myPos.Y, (minZ+maxZ)/2), Size = Vector3.new(math.abs(maxX-minX)+10, 1, math.abs(maxZ-minZ)+10)}}
            return curField
        end
    end
    if areaRing then
        curField = {part = {Position = areaRing.Position, Size = Vector3.new(areaRingRadius*3, 1, areaRingRadius*3)}}
        return curField
    end
    return curField
end

-- ===================== АДАПТИВНЫЙ СПИДХАК =====================
local function getAdaptiveSpeed()
    local phase = getPhase()
    local base = SPEED_BASE[phase] or SPEED_BASE["НАБОР"]
    if hbFrame % 30 == 0 then -- каждые ~0.5 сек (60 fps * 0.5 = 30 кадров)
        currentSpeed = base + (math.random() * 2 - 1) * SPEED_JITTER
    end
    return currentSpeed
end

local function getFieldCenter()
    if curField and curField.part then return curField.part.Position end
    local r = getHRP(); return r and r.Position or Vector3.zero
end

local function clampPos(pos, skipClamp)
    if skipClamp then return pos end
    if not curField then return pos end
    local c = curField.part.Position; local s = curField.part.Size
    local mx = math.max(s.X/2 - FIELD_MARGIN, 1); local mz = math.max(s.Z/2 - FIELD_MARGIN, 1)
    local cl = Vector3.new(math.clamp(pos.X, c.X-mx, c.X+mx), pos.Y, math.clamp(pos.Z, c.Z-mz, c.Z+mz))
    if activeBuffs.XFlame.stacks >= 20 then
        local dx = cl.X - c.X; local dz = cl.Z - c.Z
        local dist = math.sqrt(dx*dx + dz*dz)
        if dist > XFLAME_CENTER_RADIUS then
            cl = Vector3.new(c.X + dx*(XFLAME_CENTER_RADIUS/dist), cl.Y, c.Z + dz*(XFLAME_CENTER_RADIUS/dist))
        end
    end
    return cl
end

local function isInField(pos)
    if not curField then return false end
    local c = curField.part.Position; local s = curField.part.Size
    return math.abs(pos.X - c.X) <= s.X/2 + PETAL_FIELD_MARGIN and
           math.abs(pos.Z - c.Z) <= s.Z/2 + PETAL_FIELD_MARGIN
end

-- ===================== AREA RING — поиск через Heartbeat =====================
local function findAreaRing()
    local particles = Workspace:FindFirstChild("Particles")
    if particles then
        for _, obj in ipairs(particles:GetChildren()) do
            if obj.Name == "AreaRing" and obj:IsA("BasePart") then
                areaRing = obj
                areaRingRadius = (obj.Size.X + obj.Size.Z) / 4
                if areaRingRadius < 5 then areaRingRadius = AREA_RING_RADIUS end
                return
            end
        end
    end
    areaRing = Workspace:FindFirstChild("AreaRing")
    if areaRing and areaRing:IsA("BasePart") then
        areaRingRadius = (areaRing.Size.X + areaRing.Size.Z) / 4
        if areaRingRadius < 5 then areaRingRadius = AREA_RING_RADIUS end
    else
        areaRing = nil; areaRingRadius = AREA_RING_RADIUS
    end
end

-- ===================== КРОСХЕИРЫ =====================
local Parts = Workspace:FindFirstChild("Particles") or workspace:WaitForChild("Particles", 10)
local function isClose(a, b, tol)
    tol = tol or PURPLE_TOL
    return math.abs(a.R*255 - b.R*255) <= tol and
           math.abs(a.G*255 - b.G*255) <= tol and
           math.abs(a.B*255 - b.B*255) <= tol
end

local function isPurple(part)
    local ok, c = pcall(function() return part.Color end)
    if ok and c and isClose(c, PURPLE) then return true end
    local ok2, bc = pcall(function() return part.BrickColor.Color end)
    return ok2 and bc and isClose(bc, PURPLE)
end

local function addCH(obj)
    if obj.Name ~= "Crosshair" or not obj:IsA("BasePart") then return end
    for _, ch in ipairs(chQueue) do if ch.part == obj then return end end
    if not obj.Parent then return end
    table.insert(chQueue, {part = obj, spawnTime = tick(), collected = false, isPurple = isPurple(obj)})
end

if Parts then
    Parts.DescendantAdded:Connect(addCH)
    Parts.DescendantRemoving:Connect(function(obj)
        for i = #chQueue, 1, -1 do
            if chQueue[i].part == obj then table.remove(chQueue, i) break end
        end
        if lastPurple == obj then lastPurple = nil end
    end)
    for _, o in ipairs(Parts:GetDescendants()) do addCH(o) end
end

local function getCH(onlyP, onlyR)
    local list = {}
    for _, ch in ipairs(chQueue) do
        if not ch.collected and ch.part.Parent then
            if (onlyP and ch.isPurple) or (onlyR and not ch.isPurple) or (not onlyP and not onlyR) then
                table.insert(list, ch)
            end
        end
    end
    table.sort(list, function(a, b) return a.spawnTime < b.spawnTime end)
    return list
end

-- ===================== TARGET PRACTICE ГРУППЫ =====================
local function getTargetPracticeGroups()
    if not prec.isX10 or prec.needRefresh then return nil end
    local all = getCH(false, false)
    if #all < 3 then return nil end
    local groups = {}
    local i = 1
    while i <= #all - 2 do
        local a, b, c = all[i], all[i+1], all[i+2]
        if not a.isPurple and not b.isPurple and c.isPurple then
            if c.spawnTime - a.spawnTime <= 2 then
                table.insert(groups, {regular1 = a, regular2 = b, purple = c})
                i = i + 3
            else i = i + 1 end
        else i = i + 1 end
    end
    return #groups > 0 and groups or nil
end

-- ===================== ИЗБЕГАНИЕ CH =====================
local function getRegCHThreats(myPos, destPos)
    if not prec.isX10 or prec.needRefresh then return {} end
    local mf = Vector3.new(myPos.X, 0, myPos.Z)
    local df = Vector3.new(destPos.X, 0, destPos.Z)
    local tt = df - mf
    if tt.Magnitude < 1 then return {} end
    local tD = tt.Unit
    local th = {}
    for _, ch in ipairs(chQueue) do
        if not ch.collected and ch.part.Parent and not ch.isPurple then
            local cf = Vector3.new(ch.part.Position.X, 0, ch.part.Position.Z)
            local toCh = cf - mf; local d = toCh.Magnitude
            if d < CH_AVOID_RADIUS and d > 1 then
                local dot = toCh.Unit:Dot(tD)
                if dot > CH_AVOID_DOT_MIN then
                    local cross = math.abs(toCh.X*tD.Z - toCh.Z*tD.X)
                    if cross < CH_AVOID_RADIUS then
                        table.insert(th, {ch = ch, pos = cf, dist = d, cross = cross})
                    end
                end
            end
        end
    end
    return th
end

local function calcAvoidTarget(myPos, destPos)
    local th = getRegCHThreats(myPos, destPos)
    if #th == 0 then return nil end
    table.sort(th, function(a, b) return a.dist < b.dist end)
    local t = th[1]
    local mf = Vector3.new(myPos.X, 0, myPos.Z)
    local df = Vector3.new(destPos.X, 0, destPos.Z)
    local tD = (df - mf).Unit; local toCh = t.pos - mf
    local p1 = Vector3.new(-toCh.Unit.Z, 0, toCh.Unit.X)
    local p2 = Vector3.new(toCh.Unit.Z, 0, -toCh.Unit.X)
    local bp = (p2:Dot(tD) >= p1:Dot(tD)) and p2 or p1
    local ap = t.pos + bp * CH_AVOID_STEER
    stats.chAvoided = stats.chAvoided + 1
    return clampPos(Vector3.new(ap.X, myPos.Y, ap.Z))
end

local function getDupedTokenCount()
    local c = 0
    local r = getHRP(); if not r then return 0 end
    for part, t in pairs(activeTokens) do
        if not t.collected and t.duped and part.Parent then
            if dist3(r.Position, part.Position) < 80 then c = c + 1 end
        end
    end
    return c
end

-- ===================== GO TO =====================
local function goTo(targetPos, radius, timeout, skipClamp)
    radius = radius or ARRIVE_DIST; timeout = timeout or MOVE_TIMEOUT
    if targetPos == Vector3.zero then return false end
    local r = getHRP(); local h = getHumanoid()
    if not r or not h then return false end
    targetPos = clampPos(targetPos, skipClamp)
    if targetPos == Vector3.zero then
        local center = getFieldCenter()
        if center == Vector3.zero then return false end
        targetPos = center
    end
    local origTarget = Vector3.new(targetPos.X, r.Position.Y, targetPos.Z)
    local curMove = origTarget
    local avoid = calcAvoidTarget(r.Position, origTarget)
    if avoid then curMove = Vector3.new(avoid.X, r.Position.Y, avoid.Z) end
    h:MoveTo(curMove)
    local t0 = tick(); local lastMove = tick(); local lastAvoid = tick()
    while tick() - t0 < timeout do
        task.wait(0.05)
        if not ENABLED then return false end
        if INTERRUPT then return false end
        r = getHRP(); if not r then return false end
        if dist3(r.Position, origTarget) <= radius then return true end
        if tick() - lastAvoid >= 0.15 then
            lastAvoid = tick()
            local newAvoid = calcAvoidTarget(r.Position, origTarget)
            if newAvoid then curMove = Vector3.new(newAvoid.X, r.Position.Y, newAvoid.Z)
            else curMove = origTarget end
        end
        if curMove ~= origTarget and dist3(r.Position, curMove) <= 4 then
            local na = calcAvoidTarget(r.Position, origTarget)
            curMove = na and Vector3.new(na.X, r.Position.Y, na.Z) or origTarget
        end
        if tick() - lastMove >= 0.3 then
            h = getHumanoid(); if h then h:MoveTo(curMove) end
            lastMove = tick()
        end
    end
    return false
end

-- ===================== SMILE TOKEN — проверка через Heartbeat =====================
local function scanSmile()
    local n = tick()
    smileTarget = nil; smileTargetRem = 0
    local bp, bd, br = nil, math.huge, 0
    local r = getHRP(); if not r then return end
    local hp = activeBuffs.PollenMark.active
    local rp = areaRing and areaRing.Position
    for part, t in pairs(activeTokens) do
        if not t.collected and part.Parent and t.id == SMILE_TOKEN_ID then
            local rem = t.life - (n - t.spawn)
            if rem <= SMILE_REACT_TIME and rem > 0 then
                local take = false
                if hp and rp then
                    if dist3(part.Position, rp) <= areaRingRadius * 1.5 then take = true end
                else take = true end
                if take then
                    local d = dist3(r.Position, part.Position)
                    if d < bd then bp = part; bd = d; br = rem end
                end
            end
        end
    end
    if bp then
        smileTarget = bp; smileTargetRem = br
        if not isCollectingSmile then INTERRUPT = true end
    end
end

-- ===================== ФЛЕЙМЫ — проверка через Heartbeat =====================
local function isFlmDark(flm)
    local pf = flm:FindFirstChild("PF")
    if pf then
        local color = nil
        if pf:IsA("ColorSequenceValue") then
            local seq = pf.Value
            if seq and seq.Keypoints and #seq.Keypoints > 0 then
                local key = seq.Keypoints[1]
                if key and type(key) == "table" and key.Value then color = key.Value
                elseif key and type(key) == "userdata" and key.Value then color = key.Value end
            end
        elseif pf:IsA("Color3Value") then color = pf.Value
        elseif pf:IsA("BasePart") then
            local ok, c = pcall(function() return pf.Color end)
            if ok then color = c end
        end
        if color then return color.G < 0.3 and color.B > 0.5 end
    end
    local ok, c = pcall(function() return flm.Color end)
    if ok and c then return c.G < 0.3 and c.B > 0.5 end
    return false
end

local function scanFlames()
    local now = tick()
    local flames = Workspace:FindFirstChild("PlayerFlames")
    if flames then
        local seen = {}
        for _, flm in ipairs(flames:GetChildren()) do
            if flm.Name:sub(1, 3) == "Flm" then
                seen[flm] = true
                if not trackedFlames[flm] then
                    trackedFlames[flm] = {spawnTime = now, isDark = isFlmDark(flm), hit = false}
                else
                    trackedFlames[flm].isDark = isFlmDark(flm)
                end
            end
        end
        for flm in pairs(trackedFlames) do
            if not seen[flm] then trackedFlames[flm] = nil end
        end
    end
end

local function swingScythe()
    local toolCollectEvent = nil
    local e = ReplicatedStorage:FindFirstChild("Events")
    if e then toolCollectEvent = e:FindFirstChild("ToolCollect") end
    if toolCollectEvent then
        pcall(toolCollectEvent.FireServer, toolCollectEvent)
        task.wait(0.1)
    else
        pcall(function()
            local cam = workspace.CurrentCamera
            local vp = cam.ViewportSize
            VirtualInputManager:SendMouseButtonEvent(vp.X/2, vp.Y/2, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(vp.X/2, vp.Y/2, 0, false, game, 1)
        end)
    end
end

local function tryHitFlame()
    if not ENABLED then return end
    local r = getHRP(); if not r then return end
    local n = tick()
    for flm, data in pairs(trackedFlames) do
        if not data.hit and not data.isDark and flm.Parent then
            if n - data.spawnTime >= FLAME_HIT_AFTER and dist3(r.Position, flm.Position) <= FLAME_HIT_DIST then
                INTERRUPT = true
                local bg = r:FindFirstChild("AI_BG")
                if not bg then
                    bg = Instance.new("BodyGyro"); bg.Name = "AI_BG"
                    bg.MaxTorque = Vector3.new(0, 40000, 0); bg.P = 10000; bg.D = 500
                    bg.Parent = r
                end
                local dir = (flm.Position - r.Position)
                dir = Vector3.new(dir.X, 0, dir.Z)
                if dir.Magnitude > 0.1 then bg.CFrame = CFrame.lookAt(r.Position, r.Position + dir) end
                task.wait(0.1); swingScythe(); task.wait(0.15)
                if bg then bg:Destroy() end
                data.hit = true; stats.flamesHit = stats.flamesHit + 1
                task.wait(0.2); INTERRUPT = false; return true
            end
        end
    end
    return false
end

-- ===================== SCORCHING STAR: roam в 4 studs от СКОПЛЕНИЯ флеймов =====================
-- getFlameClusterCenter — центр ВСЕХ флеймов (чёрные + обычные)
local function getFlameClusterCenter()
    local positions = {}
    for flm, data in pairs(trackedFlames) do
        if flm.Parent then table.insert(positions, flm.Position) end
    end
    if #positions == 0 then return nil end
    local sum = Vector3.new(0, 0, 0)
    for _, p in ipairs(positions) do sum = sum + p end
    return clampPos(sum / #positions)
end

-- getScorchRoamTarget — точка в 4 studs от ближайшего флейма в кластере
local function getScorchRoamTarget()
    local r = getHRP(); if not r then return nil end
    -- Находим ближайший флейм (любой)
    local closestFlm = nil; local closestDist = SCORCH_ROAM_DIST + 1
    for flm in pairs(trackedFlames) do
        if flm.Parent then
            local d = dist3(r.Position, flm.Position)
            if d < closestDist then closestDist = d; closestFlm = flm end
        end
    end
    if not closestFlm then
        -- Если нет флеймов в радиусе — идём к центру кластера
        local center = getFlameClusterCenter()
        if center then return clampPos(center) end
        return nil
    end
    -- Случайная точка в радиусе SCORCH_ROAM_DIST от ближайшего флейма
    local angle = math.random() * 2 * math.pi
    local dist = math.random() * SCORCH_ROAM_DIST
    return clampPos(Vector3.new(closestFlm.Position.X + math.cos(angle)*dist, 0, closestFlm.Position.Z + math.sin(angle)*dist))
end

-- ===================== ТОКЕНЫ =====================
local function regToken(obj)
    if obj.Name ~= "C" or not obj:IsA("BasePart") or activeTokens[obj] or tick() < ignoreNewTokensUntil then return end
    local front = obj:FindFirstChild("FrontDecal")
    if not front or not front:IsA("Decal") then return end
    local id = texId(front.Texture)
    if not id or AVOID[id] then return end
    local def = TOKENS[id]; if not def then return end
    local r = getHRP()
    local duped = r and (obj.Position.Y - r.Position.Y) > 5
    local life = def.base * ABILITY_MULT
    if duped then life = life * (2 + 0.05 * (DIG_BEE_LVL - 1)) end
    activeTokens[obj] = {id = id, name = def.name, prio = def.prio, mo = def.mo or false, spawn = tick(), life = life, duped = duped, collected = false}
end

Workspace.DescendantAdded:Connect(function(o) task.wait(0.05) pcall(regToken, o) end)
for _, o in ipairs(Workspace:GetDescendants()) do pcall(regToken, o) end
game.DescendantRemoving:Connect(function(obj)
    if activeTokens[obj] then
        if activeTokens[obj].collected then stats.tok = stats.tok + 1 end
        activeTokens[obj] = nil
    end
end)

-- ===================== BUFFS — проверка через Heartbeat =====================
local rps = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RetrievePlayerStats")
local function scanBuffs()
    if not rps then return end
    local ok, result = pcall(rps.InvokeServer, rps)
    if not ok or type(result) ~= "table" then return end
    local function findBuff(tbl, src)
        if type(tbl) ~= "table" then return nil end
        if rawget(tbl, "Src") == src then return {stacks = tonumber(rawget(tbl, "Combo") or 0)} end
        for _, v in pairs(tbl) do local f = findBuff(v, src); if f then return f end end
        return nil
    end
    local ss = findBuff(result, "Scorching Star Aura")
    activeBuffs.ScorchingStar.stacks = ss and ss.stacks or 0
    local xf = findBuff(result, "X-Flame Aura")
    activeBuffs.XFlame.stacks = xf and xf.stacks or 0
    local function findPreciseMark(tbl)
        if type(tbl) ~= "table" then return false end
        if rawget(tbl, "BuffID") == 2575093099 and rawget(tbl, "Removed") ~= true then return true end
        for _, v in pairs(tbl) do if findPreciseMark(v) then return true end end
        return false
    end
    activeBuffs.PreciseMark.active = findPreciseMark(result)
    local function findPollenMark(tbl)
        if type(tbl) ~= "table" then return nil end
        if rawget(tbl, "BuffID") == POLLEN_MARK_BUFF_ID and rawget(tbl, "Removed") ~= true then return rawget(tbl, "Value") or 1 end
        for _, v in pairs(tbl) do local f = findPollenMark(v); if f then return f end end
        return nil
    end
    local pm = findPollenMark(result)
    if pm and pm > 0 then
        activeBuffs.PollenMark.active = true; activeBuffs.PollenMark.multiplier = pm
        if areaRing then activeBuffs.PollenMark.pos = areaRing.Position end
    else activeBuffs.PollenMark.active = false end
end

-- ===================== PRECISION — проверка через Heartbeat =====================
local rps_event = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RetrievePlayerStats")
local function scanPrecision()
    if not rps_event then return end
    local ok, pd = pcall(rps_event.InvokeServer, rps_event)
    if not ok or type(pd) ~= "table" then return end
    local function fp(t)
        if type(t) ~= "table" then return nil end
        if rawget(t, "BuffID") == PREC_BUFF_ID and rawget(t, "Removed") ~= true then return t end
        if rawget(t, "Src") == "Precision" then return t end
        for _, v in pairs(t) do local f = fp(v); if f then return f end end
        return nil
    end
    local b = fp(pd)
    if b then
        local val = tonumber(b.Value) or 0
        if tonumber(b.Start) ~= prec.serverStart then
            prec.serverStart = tonumber(b.Start) or 0
            prec.serverDur = tonumber(b.Dur) or 60; prec.localStart = os.clock()
        end
        prec.stacks = math.min(PREC_MAX, math.round(val / PREC_PER_STACK))
        prec.value = val; prec.isX10 = (prec.stacks >= PREC_MAX)
    else prec.stacks = 0; prec.value = 0; prec.isX10 = false end
    if prec.localStart > 0 then
        prec.timeLeft = math.max(0, prec.serverDur - (os.clock() - prec.localStart))
        prec.needRefresh = prec.isX10 and (prec.timeLeft <= PREC_REFRESH_AT)
        if prec.needRefresh and refreshCHCounter == 0 then refreshStartTime = tick(); refreshCHCounter = 0 end
    end
end

-- ===================== ПЕТАЛЫ — проверка через Heartbeat =====================
local function getPetalColor(part)
    for name, col in pairs(PETAL_COLORS) do
        if (col.R - part.Color.R)^2 + (col.G - part.Color.G)^2 + (col.B - part.Color.B)^2 < 0.002 then return name end
    end
    return nil
end

local function scanPetals()
    fieldPetals = {}
    if not ENABLED or not curField then return end
    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return end
    local r = getHRP(); if not r then return end
    for _, obj in ipairs(particles:GetChildren()) do
        if obj.Name == "PetalPart" and obj:IsA("BasePart") and isInField(obj.Position) then
            local cName = getPetalColor(obj)
            if cName and PETAL_PRIORITY[cName] then
                table.insert(fieldPetals, {part = obj, colorName = cName, priority = PETAL_PRIORITY[cName], dist = dist3D(r.Position, obj.Position)})
            end
        end
    end
    table.sort(fieldPetals, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        return a.dist < b.dist
    end)
end

-- ===================== HPS =====================
local function findHPSLabel()
    local sgui = LP.PlayerGui:FindFirstChild("ScreenGui"); if not sgui then return nil end
    local mh = sgui:FindFirstChild("MeterHUD"); if not mh then return nil end
    local hm = mh:FindFirstChild("HoneyMeter"); if not hm then return nil end
    local bar = hm:FindFirstChild("Bar"); if not bar then return nil end
    return bar:FindFirstChild("PerSecLabel")
end

local function parseHPS(text)
    if type(text) ~= "string" then return 0 end
    text = text:gsub(",", ""):gsub(" ", ""):upper()
    local num, suffix = text:match("([%d.]+)([KM]?)")
    if not num then return 0 end
    local val = tonumber(num) or 0
    if suffix == "K" then val = val * 1000 elseif suffix == "M" then val = val * 1000000 end
    return val
end

local function getHoneyPerSecond()
    if not hpsMeterLabel or not hpsMeterLabel.Parent then hpsMeterLabel = findHPSLabel() end
    if hpsMeterLabel and hpsMeterLabel:IsA("TextLabel") then return parseHPS(hpsMeterLabel.Text) end
    return 0
end

local function savePatterns()
    local ok, j = pcall(HttpService.JSONEncode, HttpService, patternsHistory)
    if ok then pcall(writefile, patternFile, j) end
end

local function loadPatterns()
    local ok, raw = pcall(readfile, patternFile)
    if ok and raw then
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if ok2 and type(data) == "table" then
            patternsHistory = data
            for _, p in ipairs(patternsHistory) do if p.hps and p.hps > bestAvgHPS then bestAvgHPS = p.hps end end
        end
    end
end

local function updateHPSBuffers()
    local now = tick(); local hps = getHoneyPerSecond()
    if hps > 0 then table.insert(hpsBuffer, {time = now, hps = hps}) end
    local cutoff = now - 120
    while #hpsBuffer > 0 and hpsBuffer[1].time < cutoff do table.remove(hpsBuffer, 1) end
    if taskLabel and taskLabel ~= "старт" then
        local r = getHRP()
        table.insert(actionBuffer, {time = now, action = taskLabel, pos = r and r.Position or Vector3.zero, phase = getPhase(), isScorch = activeBuffs.ScorchingStar.stacks > 0})
    end
    while #actionBuffer > 0 and actionBuffer[1].time < cutoff do table.remove(actionBuffer, 1) end
    if now - lastAnalyzeTime >= 10 then
        lastAnalyzeTime = now
        local sum, count = 0, 0
        for _, e in ipairs(hpsBuffer) do sum = sum + e.hps; count = count + 1 end
        local avg = count > 0 and (sum / count) or 0
        if avg > 0 then
            local acts = {}
            for _, e in ipairs(actionBuffer) do
                table.insert(acts, {action = e.action, pos = e.pos, timeOffset = e.time - (now - 120), phase = e.phase, isScorch = e.isScorch})
            end
            table.insert(patternsHistory, {hps = avg, actions = acts, timestamp = now})
            table.sort(patternsHistory, function(a, b) return a.hps > b.hps end)
            while #patternsHistory > 30 do table.remove(patternsHistory) end
            if avg > bestAvgHPS then bestAvgHPS = avg end
            savePatterns()
        end
    end
end

local function getPatternBonus(action, pos)
    if #patternsHistory == 0 then return 0 end
    local phase = getPhase(); local isScorch = activeBuffs.ScorchingStar.stacks > 0
    local best = 0
    for _, p in ipairs(patternsHistory) do
        for _, pa in ipairs(p.actions) do
            if pa.action == action then
                if (pos - pa.pos).Magnitude < 10 then
                    local ms = ((pa.phase == phase) and (pa.isScorch == isScorch)) and 2 or (((pa.phase == phase) or (pa.isScorch == isScorch)) and 1.5 or 1)
                    if ms > best then best = ms end
                end
            end
        end
    end
    return 15 * best
end

-- ===================== Q-LEARNING =====================
local function getQ(s, a) return (QTable[s] and QTable[s][a]) or 0 end
local function setQ(s, a, v) if not QTable[s] then QTable[s] = {} end; QTable[s][a] = v end

local function hasTokenLink()
    for _, t in pairs(activeTokens) do
        if not t.collected and t.prio >= 90 then return true end
    end
    return false
end

local function getDupTargetPractice()
    local n = tick()
    for part, t in pairs(activeTokens) do
        if not t.collected and part.Parent and t.id == TARGET_PRACTICE_ID and t.duped then
            if t.life - (n - t.spawn) > 1 then return part, t end
        end
    end
    return nil, nil
end

local function getSmileOrDupInArea()
    local r = getHRP(); if not r then return nil end
    local rp = areaRing and areaRing.Position; if not rp then return nil end
    local bp, bd = nil, math.huge
    for part, t in pairs(activeTokens) do
        if not t.collected and part.Parent then
            if (t.id == SMILE_TOKEN_ID) or (t.id == TARGET_PRACTICE_ID and t.duped) then
                if dist3(part.Position, rp) <= areaRingRadius * 1.5 then
                    local d = dist3(r.Position, part.Position)
                    if d < bd then bd = d; bp = part end
                end
            end
        end
    end
    return bp
end

local function encodeState()
    local r = getHRP(); if not r then return "dead" end
    local ph = getPhase()
    local tlDist = "none"
    for part, t in pairs(activeTokens) do
        if not t.collected and part.Parent and t.prio >= 90 then
            local d = dist3(r.Position, part.Position)
            if d < 20 then tlDist = "close" elseif d < 60 then tlDist = "far" end
        end
    end
    local purN = math.min(3, #getCH(true, false)); local regN = math.min(3, #getCH(false, true))
    local smUrgent = (smileTarget ~= nil); local hasPetal = (#fieldPetals > 0)
    local nearTok = false; local n = tick()
    for part, t in pairs(activeTokens) do
        if not t.collected and part.Parent and (t.life - (n - t.spawn)) > 1 and dist3(r.Position, part.Position) < 30 then
            nearTok = true; break
        end
    end
    local zone = "mid"
    if curField and curField.part and curField.part.Parent then
        local c = curField.part.Position; local s = curField.part.Size
        if s.X > 0 and s.Z > 0 then
            local rx = math.abs(r.Position.X - c.X) / (s.X/2)
            local rz = math.abs(r.Position.Z - c.Z) / (s.Z/2)
            if rx > 0.7 or rz > 0.7 then zone = "edge"
            elseif rx < 0.3 and rz < 0.3 then zone = "center" end
        end
    end
    local chT = "none"
    if prec.isX10 and not prec.needRefresh then
        local ct = 0
        for _, ch in ipairs(chQueue) do
            if not ch.collected and ch.part.Parent and not ch.isPurple and dist3(r.Position, ch.part.Position) < 20 then ct = ct + 1 end
        end
        if ct > 2 then chT = "many" elseif ct > 0 then chT = "some" end
    end
    local sc = activeBuffs.ScorchingStar.stacks > 0 and "1" or "0"
    return string.format("PH:%s|TL:%s|CH:%d|PR:%d|SM:%s|NT:%s|Z:%s|CT:%s|PT:%s|SC:%s", ph, tlDist, regN, purN, tostring(smUrgent), tostring(nearTok), zone, chT, tostring(hasPetal), sc)
end

-- ===================== ДЕЙСТВИЯ =====================
local function getActionsWithBuffs()
    local baseActions = {}
    local phase = getPhase()
    local now = tick()

    if hasTokenLink() then return {"go_tokenlink"} end

    if phase ~= "НАБОР" then
        for part, t in pairs(activeTokens) do
            if not t.collected and part.Parent and (t.life - (now - t.spawn)) < 0.3 and (t.life - (now - t.spawn)) > 0 then
                return {"go_urgent_token"}
            end
        end
    end

    if activeBuffs.ScorchingStar.stacks > 0 and next(trackedFlames) then
        local center = getFlameClusterCenter()
        if center then
            table.insert(baseActions, "go_scorching_roam")
        end
    end

    if smileTarget and getDupedTokenCount() > 6 then return {"go_smile"} end

    if activeBuffs.PollenMark.active and areaRing then
        local target = getSmileOrDupInArea()
        if target then
            local t = activeTokens[target]
            if t and t.id == SMILE_TOKEN_ID then table.insert(baseActions, 1, "go_smile_area")
            elseif t and t.id == TARGET_PRACTICE_ID and t.duped then table.insert(baseActions, 1, "go_dup_area") end
        end
    end

    if xflameEmergency then
        local center = getFieldCenter()
        local closestCH, closestDist = nil, XFLAME_CENTER_RADIUS + 1
        if center ~= Vector3.zero then
            for _, ch in ipairs(chQueue) do
                if not ch.collected and ch.part.Parent then
                    local d = dist3(ch.part.Position, center)
                    if d <= XFLAME_CENTER_RADIUS and d < closestDist then closestDist = d; closestCH = ch end
                end
            end
        end
        if closestCH then return {"go_xflame_ch"} else return {"go_xflame_center"} end
    end

    if phase == "REFRESH" then
        local all = getCH(false, false)
        if #all > 0 then table.insert(baseActions, "go_crosshair_refresh_all")
        else table.insert(baseActions, "patrol_ring") end
        return baseActions
    end

    if phase == "X10" then
        local tpGroups = getTargetPracticeGroups()
        if tpGroups then table.insert(baseActions, "go_target_practice_purple")
        else
            local purps = getCH(true, false)
            if #purps > 0 then table.insert(baseActions, "go_purple") end
        end
    end

    if phase == "X10" or phase == "НАБОР" then
        if #fieldPetals > 0 then table.insert(baseActions, "go_petal") end
        local all = getCH(false, false)
        if #all > 0 then table.insert(baseActions, "go_crosshair") end
        local hasAny = false; for _ in pairs(activeTokens) do hasAny = true; break end
        if hasAny then table.insert(baseActions, "go_token_near"); table.insert(baseActions, "go_token_best") end
        local dtp = getDupTargetPractice()
        if dtp then table.insert(baseActions, "go_dup_tp") end
        table.insert(baseActions, "patrol_ring")
        if phase == "НАБОР" then table.insert(baseActions, "patrol_random") end
        return baseActions
    end

    return {"patrol_ring"}
end

local function chooseActionWithBuffs(state)
    local valid = getActionsWithBuffs()
    if #valid == 0 then return "patrol_ring" end
    if math.random() < EPSILON then return valid[math.random(1, #valid)] end
    local bestA, bestQ = valid[1], getQ(state, valid[1])
    for i = 2, #valid do
        local q = getQ(state, valid[i])
        if q > bestQ then bestA = valid[i]; bestQ = q end
    end
    return bestA
end

local function doUpdateQ(state, action, reward, nextState)
    local r = getHRP()
    local totalReward = reward + getPatternBonus(action, r and r.Position or Vector3.zero)
    local valid = getActionsWithBuffs()
    local maxNext = 0
    for _, a in ipairs(valid) do local q = getQ(nextState, a); if q > maxNext then maxNext = q end end
    local new = getQ(state, action) + ALPHA * (totalReward + GAMMA * maxNext - getQ(state, action))
    setQ(state, action, new)
    stats.totalReward = stats.totalReward + totalReward; stats.decisions = stats.decisions + 1
    EPSILON = math.max(0.02, EPSILON * EPSILON_DECAY)
end

-- ===================== ВИЗУАЛИЗАЦИЯ =====================
local function updateXFlameCircle()
    if xflameEmergency then
        local center = getFieldCenter()
        if center == Vector3.zero then local r = getHRP(); if r then center = r.Position end end
        if not xflameCircle then
            xflameCircle = Instance.new("Part"); xflameCircle.Name = "XFlameCircle"
            xflameCircle.Shape = Enum.PartType.Cylinder; xflameCircle.Anchored = true
            xflameCircle.CanCollide = false; xflameCircle.Transparency = 0.6
            xflameCircle.BrickColor = BrickColor.Red()
            xflameCircle.Size = Vector3.new(XFLAME_CENTER_RADIUS*2, 0.2, XFLAME_CENTER_RADIUS*2)
            xflameCircle.Parent = Workspace
        end
        xflameCircle.Position = Vector3.new(center.X, center.Y + 0.2, center.Z)
    else if xflameCircle then xflameCircle:Destroy(); xflameCircle = nil end end
end

local function updateScytheCircle()
    if ENABLED then
        local r = getHRP()
        if r then
            if not scytheCircle then
                scytheCircle = Instance.new("Part"); scytheCircle.Name = "ScytheRadius"
                scytheCircle.Shape = Enum.PartType.Cylinder; scytheCircle.Anchored = true
                scytheCircle.CanCollide = false; scytheCircle.Transparency = 0.6
                scytheCircle.BrickColor = BrickColor.new("Bright orange")
                scytheCircle.Size = Vector3.new(FLAME_HIT_DIST*2, 0.2, FLAME_HIT_DIST*2)
                scytheCircle.Parent = Workspace
            end
            scytheCircle.Position = Vector3.new(r.Position.X, r.Position.Y + 0.2, r.Position.Z)
        end
    else if scytheCircle then scytheCircle:Destroy(); scytheCircle = nil end end
end

local function getEdgePoint(targetPos)
    if not areaRing or not areaRing.Parent then return targetPos end
    local dir = (targetPos - areaRing.Position).Unit
    return clampPos(Vector3.new(areaRing.Position.X + dir.X*areaRingRadius, 0, areaRing.Position.Z + dir.Z*areaRingRadius))
end

-- ===================== Crosshair Hit =====================
local CROSSHAIR_HIT_COLOR = Color3.fromRGB(17, 134, 19)
local function isCrosshairHit(part)
    if not part or part.Name ~= "Crosshair" then return false end
    local ok, col = pcall(function() return part.Color end)
    if not ok then return false end
    return math.abs(col.R - CROSSHAIR_HIT_COLOR.R) < 0.05 and
           math.abs(col.G - CROSSHAIR_HIT_COLOR.G) < 0.05 and
           math.abs(col.B - CROSSHAIR_HIT_COLOR.B) < 0.05
end

-- ===================== ИСПОЛНЕНИЕ ДЕЙСТВИЙ =====================
local function executeAction(action)
    local r = getHRP()
    if not r then return -1 end

    if action == "go_scorching_roam" then
        local target = getScorchRoamTarget()
        if not target then return -1 end
        taskLabel = "🔥 Scorch roam"
        INTERRUPT = false
        goTo(target, 2, 2)
        task.wait(0.15)
        return 2
    elseif action == "go_crosshair_refresh_all" then
        local all = getCH(false, false)
        if #all == 0 then return -1 end
        local collected = 0; INTERRUPT = false
        for _, ch in ipairs(all) do
            if ch.part.Parent and not ch.collected then
                if collected >= 3 then break end
                taskLabel = "🔄 REFRESH (" .. (collected+1) .. "/3)"
                local ok = goTo(ch.part.Position, 4, 4, true)
                if ok and ch.part.Parent then
                    ch.collected = true; refreshCHCounter = refreshCHCounter + 1
                    if ch.isPurple then stats.purple = stats.purple + 1; lastPurple = ch.part
                    else stats.ch = stats.ch + 1 end
                    collected = collected + 1; task.wait(0.1)
                end
            end
        end
        if areaRing and areaRing.Parent then
            taskLabel = "🏠 возврат в кольцо"
            goTo(areaRing.Position, 6, 4)
        else
            goTo(clampPos(r.Position), 5, 2)
        end
        if refreshCHCounter >= 3 then
            prec.needRefresh = false; cycle.chCollectedCount = 0
            stats.ref = stats.ref + 1; refreshCHCounter = 0
            taskLabel = "✅ REFRESH ОК"
            return 40
        end
        return collected > 0 and (collected * 12) or -2
    elseif action == "go_target_practice_purple" then
        local tpGroups = getTargetPracticeGroups()
        if not tpGroups then return -1 end
        local reward = 0; INTERRUPT = false
        for _, group in ipairs(tpGroups) do
            if group.purple.part.Parent and not group.purple.collected then
                taskLabel = "🎯 TP фиолетовый"
                local ok = goTo(group.purple.part.Position, 4, 5)
                if ok and group.purple.part.Parent then
                    group.purple.collected = true; group.regular1.collected = true; group.regular2.collected = true
                    lastPurple = group.purple.part; stats.purple = stats.purple + 1
                    taskLabel = "🟣 TP Precise Mark"
                    local t0 = tick()
                    while tick() - t0 < PURPLE_STAND do task.wait(0.05); if smileTarget or prec.needRefresh or not ENABLED then break end end
                    reward = reward + 40
                end
            end
        end
        return reward > 0 and reward or -2
    elseif action == "go_smile_area" then
        local target = getSmileOrDupInArea()
        if not target then return -1 end
        local t = activeTokens[target]
        if not t or t.collected or t.id ~= SMILE_TOKEN_ID then return -1 end
        taskLabel = "😊 Smile (AreaRing)"; INTERRUPT = false
        local edge = getEdgePoint(target.Position)
        local ok = goTo(edge, 4, 4)
        if ok and target.Parent then
            local start = tick()
            while tick() - start < TOKEN_STAND_DUR do
                task.wait(0.1); if not target.Parent or INTERRUPT then break end
                local hrp = getHRP()
                if hrp then hrp.CFrame = CFrame.new(target.Position.X, hrp.Position.Y, target.Position.Z) end
            end
            t.collected = true; stats.smileCollected = stats.smileCollected + 1; return 45
        end
        return -10
    elseif action == "go_dup_area" then
        local target = getSmileOrDupInArea()
        if not target then return -1 end
        local t = activeTokens[target]
        if not t or t.collected or t.id ~= TARGET_PRACTICE_ID or not t.duped then return -1 end
        taskLabel = "🎯 Dup (AreaRing)"; INTERRUPT = false
        local edge = getEdgePoint(target.Position)
        local ok = goTo(edge, 4, 4)
        if ok and target.Parent then
            local start = tick()
            while tick() - start < TOKEN_STAND_DUR do
                task.wait(0.1); if not target.Parent or INTERRUPT then break end
                local hrp = getHRP()
                if hrp then hrp.CFrame = CFrame.new(target.Position.X, hrp.Position.Y, target.Position.Z) end
            end
            t.collected = true; stats.tok = stats.tok + 1; return 15
        end
        return -2
    elseif action == "go_smile" then
        local target = smileTarget
        if not target or not target.Parent then smileTarget = nil; return -1 end
        local t = activeTokens[target]
        if not t or t.collected then smileTarget = nil; return -1 end
        isCollectingSmile = true; taskLabel = "😊 Smile"; INTERRUPT = false
        local ok = goTo(target.Position, 4, math.min(2.5, smileTargetRem - 0.2))
        if ok and target.Parent then
            local start = tick()
            while tick() - start < TOKEN_STAND_DUR do
                task.wait(0.1); if not target.Parent or INTERRUPT then break end
                local hrp = getHRP()
                if hrp then hrp.CFrame = CFrame.new(target.Position.X, hrp.Position.Y, target.Position.Z) end
            end
            t.collected = true; smileTarget = nil; stats.smileCollected = stats.smileCollected + 1
            isCollectingSmile = false; return 45
        end
        isCollectingSmile = false; smileTarget = nil; return -10
    elseif action == "go_urgent_token" then
        local now = tick(); local best, bestLife = nil, 0.3
        for part, t in pairs(activeTokens) do
            if not t.collected and part.Parent then
                local rem = t.life - (now - t.spawn)
                if rem < bestLife and rem > 0 then bestLife = rem; best = part end
            end
        end
        if best then
            taskLabel = "⚡Срочный токен"; INTERRUPT = false
            local ok = goTo(best.Position, 4, 2)
            if ok and best.Parent then activeTokens[best].collected = true; stats.tok = stats.tok + 1; return 25 end
            return -2
        end
        return -1
    elseif action == "go_purple" then
        local purps = getCH(true, false)
        if #purps == 0 then return -1 end
        local reward = 0; INTERRUPT = false
        for _, ch in ipairs(purps) do
            if ch.part.Parent and not ch.collected and not smileTarget and not prec.needRefresh then
                local ok = goTo(ch.part.Position, 4, 5)
                if ok and ch.part.Parent then
                    ch.collected = true; lastPurple = ch.part; stats.purple = stats.purple + 1
                    taskLabel = "🟣 1с"
                    local t0 = tick()
                    while tick() - t0 < PURPLE_STAND do task.wait(0.05); if smileTarget or prec.needRefresh or not ENABLED then break end end
                    reward = reward + 30
                end
            end
        end
        return reward > 0 and reward or -2
    elseif action == "go_tokenlink" then
        for part, t in pairs(activeTokens) do
            if not t.collected and part.Parent and t.prio >= 90 then
                taskLabel = "💎🔴 Link"; INTERRUPT = false
                local ok = goTo(part.Position, 5, 5)
                if ok and part.Parent then t.collected = true; ignoreNewTokensUntil = tick() + TOKEN_LINK_COOLDOWN; return 50 end
                return -5
            end
        end
        return -2
    elseif action == "go_crosshair" then
        local all = getCH(false, false)
        if #all == 0 then return -1 end
        local target = all[1]; local reward = 0; INTERRUPT = false
        if target.part.Parent and not target.collected and not smileTarget and not prec.needRefresh then
            local shouldSkip = false; local r2 = getHRP()
            if r2 then
                for part2, t2 in pairs(activeTokens) do
                    if not t2.collected and part2.Parent and t2.prio >= 90 then
                        if dist3(r2.Position, part2.Position) < TL_INTERRUPT_DIST and dist3(r2.Position, target.part.Position) > 30 then
                            shouldSkip = true; break
                        end
                    end
                end
            end
            if not shouldSkip then
                local ok = goTo(target.part.Position, 4, 5)
                if ok and target.part.Parent then
                    target.collected = true
                    if target.isPurple then stats.purple = stats.purple + 1; lastPurple = target.part; reward = reward + 10
                    else stats.ch = stats.ch + 1; cycle.chCollectedCount = cycle.chCollectedCount + 1
                        if cycle.chCollectedCount >= 3 then cycle.chCollectedCount = 0 end
                        reward = reward + 8
                    end
                end
            end
        end
        if reward > 0 and activeBuffs.PollenMark.active and activeBuffs.PollenMark.pos then
            taskLabel = "🏠 возврат в AreaRing"; goTo(activeBuffs.PollenMark.pos, 6, 4)
        end
        return reward > 0 and reward or -2
    elseif action == "go_dup_tp" then
        local part, t = getDupTargetPractice()
        if not part then return -1 end
        taskLabel = "🎯 Dup"; INTERRUPT = false
        local ok = goTo(part.Position, 5, 5)
        if ok and part.Parent then
            local start = tick()
            while tick() - start < TOKEN_STAND_DUR do
                task.wait(0.1); if not part.Parent or INTERRUPT then break end
                local hrp = getHRP()
                if hrp then hrp.CFrame = CFrame.new(part.Position.X, hrp.Position.Y, part.Position.Z) end
            end
            t.collected = true; return 15
        end
        return -2
    elseif action == "go_petal" then
        if #fieldPetals == 0 then return -1 end
        local collectedAny, totalReward = false, 0; local i = 1
        while i <= #fieldPetals do
            local petal = fieldPetals[i]
            if not petal.part.Parent then table.remove(fieldPetals, i)
            elseif stuckPetals[petal.part] and tick() < stuckPetals[petal.part] then table.remove(fieldPetals, i)
            else
                taskLabel = "🌸 " .. petal.colorName; INTERRUPT = false
                local ok = goTo(Vector3.new(petal.part.Position.X, 0, petal.part.Position.Z), PETAL_COLLECT_DIST, 2.5)
                if ok then stats.petalsCollected = stats.petalsCollected + 1; totalReward = totalReward + 8 + (14 - petal.priority); collectedAny = true; task.wait(0.05); i = i + 1
                else stuckPetals[petal.part] = tick() + 5; table.remove(fieldPetals, i) end
            end
        end
        return collectedAny and totalReward or -1
    elseif action == "go_token_near" then
        local best, bestD = nil, math.huge
        for part, t in pairs(activeTokens) do
            if not t.collected and part.Parent then
                local d = dist3(r.Position, part.Position)
                if d < bestD then best = part; bestD = d end
            end
        end
        if best then
            local t = activeTokens[best]; taskLabel = "💎 " .. t.name; INTERRUPT = false
            local ok = goTo(best.Position, 5, 5)
            if ok and best.Parent then t.collected = true; return 3 + t.prio * 0.2 end
            return -2
        end
        return -1
    elseif action == "go_token_best" then
        local best, bestP = nil, -1; local now = tick()
        for part, t in pairs(activeTokens) do
            if not t.collected and part.Parent and (t.life - (now - t.spawn)) > 0.5 and t.prio > bestP then
                best = part; bestP = t.prio
            end
        end
        if best then
            local t = activeTokens[best]; taskLabel = "💎⭐ " .. t.name; INTERRUPT = false
            local ok = goTo(best.Position, 5, 5)
            if ok and best.Parent then t.collected = true; return 5 + t.prio * 0.3 end
            return -3
        end
        return -1
    elseif action == "patrol_ring" then
        local function rndRing()
            if areaRing and areaRing.Parent and curField then
                local a = math.random() * 2 * math.pi; local rr = areaRingRadius * (0.5 + math.random() * 0.8)
                return clampPos(Vector3.new(areaRing.Position.X + math.cos(a)*rr, 0, areaRing.Position.Z + math.sin(a)*rr))
            elseif curField then
                local c = curField.part.Position; local s = curField.part.Size
                return clampPos(Vector3.new(c.X + (math.random()*2-1)*math.max(s.X/2*0.3,5), 0, c.Z + (math.random()*2-1)*math.max(s.Z/2*0.3,5)))
            else
                local rp = getHRP()
                if rp then return clampPos(rp.Position + Vector3.new((math.random()*2-1)*30, 0, (math.random()*2-1)*30))
                else return clampPos(Vector3.zero) end
            end
        end
        taskLabel = "🚶 кольцо"; INTERRUPT = false
        local target = rndRing()
        if target == Vector3.zero or not isInField(target) then target = getFieldCenter() end
        if target == Vector3.zero then return 0 end
        goTo(target, 6, PATROL_TIMEOUT); task.wait(0.1 + math.random() * 0.3); return 0
    elseif action == "patrol_random" then
        local function rndF()
            if curField then
                local c = curField.part.Position; local s = curField.part.Size
                return clampPos(Vector3.new(c.X + (math.random()*2-1)*math.max(s.X/2-3,1), 0, c.Z + (math.random()*2-1)*math.max(s.Z/2-3,1)))
            else
                local rp = getHRP()
                if rp then return clampPos(rp.Position + Vector3.new((math.random()*2-1)*30, 0, (math.random()*2-1)*30))
                else return clampPos(Vector3.zero) end
            end
        end
        taskLabel = "🚶 патруль"; INTERRUPT = false
        local target = rndF()
        if target == Vector3.zero or not isInField(target) then target = getFieldCenter() end
        if target == Vector3.zero then return 0 end
        goTo(target, 4, PATROL_TIMEOUT); task.wait(0.2 + math.random() * 0.4); return 0
    elseif action == "go_xflame_center" then
        local center = getFieldCenter()
        if center == Vector3.zero then return -1 end
        taskLabel = "🔥 XFlame"; INTERRUPT = false; goTo(center, 3, 3); return 0
    elseif action == "go_xflame_ch" then
        local center = getFieldCenter()
        if center == Vector3.zero then return -1 end
        local bestCH, bestDist = nil, XFLAME_CENTER_RADIUS + 1
        for _, ch in ipairs(chQueue) do
            if not ch.collected and ch.part.Parent then
                local d = dist3(ch.part.Position, center)
                if d <= XFLAME_CENTER_RADIUS and d < bestDist then bestDist = d; bestCH = ch end
            end
        end
        if bestCH then taskLabel = "🔥 XFlame CH"; INTERRUPT = false; goTo(bestCH.part.Position, 2, 3); task.wait(1); return 5 end
        return -1
    end
    return 0
end

-- ===================== ГЛАВНЫЙ HEARTBEAT-ЦИКЛ =====================
local mainLoopStarted = false
local function startMainLoop()
    if mainLoopStarted then return end
    mainLoopStarted = true
    task.wait(2)
    loadQ(); findAreaRing(); findCurrentField()
    logInfo("BSS AI v12.9 готов!")
    print("✅ BSS AI v12.9 safe+ (Heartbeat-оптимизация) готов.")
    taskLabel = "инициализация"; lastMoveTime = tick()
end

-- Загрузка паттернов (редкая операция — через task.spawn)
task.spawn(function()
    loadPatterns()
    logInfo("Паттерны загружены")
end)

RunService.Heartbeat:Connect(function(dt)
    hbFrame = hbFrame + 1
    if not ENABLED then return end

    -- Запуск с задержкой (ждём загрузки)
    if not mainLoopStarted then
        startMainLoop()
        return
    end

    local now = tick()

    -- === КАЖДЫЙ КАДР: AreaRing ===
    findAreaRing()

    -- === КАЖДЫЕ 18 кадров (~0.3 сек): Buffs + Precision ===
    if hbFrame % 18 == 0 then
        scanBuffs()
        scanPrecision()
    end

    -- === КАЖДЫЕ 12 кадров (~0.2 сек): Флеймы ===
    if hbFrame % 12 == 0 then
        scanFlames()
    end

    -- === КАЖДЫЕ 9 кадров (~0.15 сек): Петалы + спидхак + удар флейма ===
    if hbFrame % 9 == 0 then
        scanPetals()
        local h = getHumanoid()
        if h then
            local ts = getAdaptiveSpeed()
            if math.abs(h.WalkSpeed - ts) > 0.5 then h.WalkSpeed = ts end
        end
        tryHitFlame()
    end

    -- === КАЖДЫЕ 6 кадров (~0.1 сек): HPS ===
    if hbFrame % 6 == 0 then
        pcall(updateHPSBuffers)
    end

    -- === КАЖДЫЕ 3 кадра (~0.05 сек): Smile + поле ===
    if hbFrame % 3 == 0 then
        scanSmile()
    end

    -- === КАЖДЫЕ 180 кадров (~3 сек): Поле ===
    if hbFrame % 180 == 0 then
        findCurrentField()
    end

    -- === Каждые 18000 кадров (~5 мин): Сохранение Q-таблицы ===
    if hbFrame % 18000 == 0 then
        pcall(function()
            local qc = 0; for _ in pairs(QTable) do qc = qc + 1 end
            pcall(writefile, "bss_ai_q_v12.json", HttpService:JSONEncode({
                version = Q_VERSION, qtable = QTable,
                meta = {stateCount = qc, epsilon = math.floor(EPSILON*1000)/1000, userId = tostring(LP.UserId), savedAt = os.time(), totalReward = math.floor(stats.totalReward), decisions = stats.decisions}
            }))
        end)
    end

    -- === XFlame emergency ===
    xflameEmergency = (activeBuffs.XFlame.stacks >= 20)
    if xflameEmergency then INTERRUPT = true end
    updateXFlameCircle(); updateScytheCircle()

    -- === Анти-застревание ===
    local r = getHRP()
    if r then
        local vel = r.AssemblyLinearVelocity
        local hSpeed = (Vector3.new(vel.X, 0, vel.Z)).Magnitude
        if hSpeed > 0.2 then lastMoveTime = now; stuckWarning = false
        elseif now - lastMoveTime > 5 and not stuckWarning then
            stuckWarning = true; INTERRUPT = true; taskLabel = "⏳ сброс"
            if lastPurple and not lastPurple.Parent then lastPurple = nil end
            if smileTarget and not smileTarget.Parent then smileTarget = nil; isCollectingSmile = false end
            INTERRUPT = false; lastMoveTime = now
        end
    end

    if INTERRUPT and not smileTarget and not prec.needRefresh and not xflameEmergency then
        INTERRUPT = false
    end

    -- === CH-hit penalty ===
    if prec.isX10 and not prec.needRefresh and r then
        for _, ch in ipairs(chQueue) do
            if ch.part and ch.part.Parent and not ch.collected and not ch.isPurple then
                if isCrosshairHit(ch.part) and now - lastPenaltyTime > 1.5 then
                    lastPenaltyTime = now
                    local state = encodeState()
                    if state and state ~= "dead" then pcall(doUpdateQ, state, "patrol_ring", -20, state) end
                    stats.chAvoided = stats.chAvoided + 1; break
                end
            end
        end
    end

    -- === Главный Q-Learning цикл (каждые 2 кадра ~0.033 сек) ===
    if hbFrame % 2 == 0 then
        local state = encodeState()
        local action = chooseActionWithBuffs(state)
        local ok, reward = pcall(executeAction, action)
        if not ok then reward = -1 end
        local nextState = encodeState()
        pcall(doUpdateQ, state, action, reward, nextState)
    end
end)

-- ===================== Q-ТАБЛИЦА (init) =====================
local function loadQ()
    local ok, raw = pcall(readfile, "bss_ai_q_v12.json")
    if ok and raw then
        local ok2, d = pcall(HttpService.JSONDecode, HttpService, raw)
        if ok2 and type(d) == "table" and d.version == Q_VERSION and type(d.qtable) == "table" then QTable = d.qtable end
    end
end

local function resetQ()
    QTable = {}; EPSILON = 0.1; stats.totalReward = 0; stats.decisions = 0
    pcall(writefile, "bss_ai_q_v12.json", HttpService:JSONEncode({version = Q_VERSION, qtable = {}, meta = {resetAt = os.time()}}))
end

-- ===================== GUI =====================
local sg = Instance.new("ScreenGui", PGui) sg.Name = "BSSAI_GUI"
local frame = Instance.new("Frame", sg) frame.Size = UDim2.new(0, 240, 0, 100) frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30) frame.BackgroundTransparency = 0.15 frame.BorderSizePixel = 0
frame.Active = true frame.Draggable = true Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
local title = Instance.new("TextLabel", frame) title.Size = UDim2.new(1, 0, 0, 20) title.Position = UDim2.new(0, 0, 0, 2)
title.BackgroundTransparency = 1 title.Text = "🧠 BSS AI v12.9 safe+" title.TextColor3 = Color3.fromRGB(100, 200, 255)
title.Font = Enum.Font.GothamBold title.TextSize = 12 title.TextXAlignment = Enum.TextXAlignment.Center
local label = Instance.new("TextLabel", frame) label.Size = UDim2.new(1, 0, 0, 18) label.Position = UDim2.new(0, 0, 0, 24)
label.BackgroundTransparency = 1 label.Text = "Действие: старт" label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.Gotham label.TextSize = 13 label.TextXAlignment = Enum.TextXAlignment.Center
local hpsLabel = Instance.new("TextLabel", frame) hpsLabel.Size = UDim2.new(1, 0, 0, 18) hpsLabel.Position = UDim2.new(0, 0, 0, 44)
hpsLabel.BackgroundTransparency = 1 hpsLabel.Text = "HPS: -- | Рекорд: --" hpsLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
hpsLabel.Font = Enum.Font.Gotham hpsLabel.TextSize = 12 hpsLabel.TextXAlignment = Enum.TextXAlignment.Center
local speedLabel = Instance.new("TextLabel", frame) speedLabel.Size = UDim2.new(1, 0, 0, 18) speedLabel.Position = UDim2.new(0, 0, 0, 64)
speedLabel.BackgroundTransparency = 1 speedLabel.Text = "⚡ --" speedLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
speedLabel.Font = Enum.Font.Gotham speedLabel.TextSize = 11 speedLabel.TextXAlignment = Enum.TextXAlignment.Center
local phaseLabel = Instance.new("TextLabel", frame) phaseLabel.Size = UDim2.new(1, 0, 0, 18) phaseLabel.Position = UDim2.new(0, 0, 0, 82)
phaseLabel.BackgroundTransparency = 1 phaseLabel.Text = "Фаза: --" phaseLabel.TextColor3 = Color3.fromRGB(180, 180, 255)
phaseLabel.Font = Enum.Font.Gotham phaseLabel.TextSize = 11 phaseLabel.TextXAlignment = Enum.TextXAlignment.Center
task.spawn(function() while true do task.wait(0.3) label.Text = "🎯 " .. taskLabel
    local cur = getHoneyPerSecond(); local hpsStr = cur > 0 and string.format("%.0f", cur) or "--"
    local bestStr = bestAvgHPS > 0 and string.format("%.0f", bestAvgHPS) or "--"
    hpsLabel.Text = "HPS: " .. hpsStr .. " | Рекорд: " .. bestStr
    speedLabel.Text = "⚡ спид: " .. string.format("%.0f", currentSpeed)
    phaseLabel.Text = "📊 " .. getPhase() .. " | CH:" .. #chQueue .. " | Ток:" .. stats.tok
end end)
UserInputService.InputBegan:Connect(function(input, gp) if gp then return end
    if input.KeyCode == Enum.KeyCode.T then ENABLED = not ENABLED; sg.Enabled = ENABLED
    elseif input.KeyCode == Enum.KeyCode.G then resetQ()
    elseif input.KeyCode == Enum.KeyCode.P then print("Phase: " .. getPhase() .. " ε:" .. string.format("%.3f", EPSILON) .. " R:" .. stats.totalReward)
        local c = 0; for _ in pairs(QTable) do c = c + 1 end; print("States: " .. c); print("Patterns: " .. #patternsHistory)
    end
end)
LP.CharacterAdded:Connect(function() task.wait(2) activeTokens={} chQueue={} lastPurple=nil curField=nil taskLabel="старт" smileTarget=nil isCollectingSmile=false INTERRUPT=false cycle={chCollectedCount=0} trackedFlames={} fieldPetals={} ignoreNewTokensUntil=0 refreshCHCounter=0 if xflameCircle then xflameCircle:Destroy() xflameCircle=nil end if scytheCircle then scytheCircle:Destroy() scytheCircle=nil end pcall(function()
    local qc = 0; for _ in pairs(QTable) do qc = qc + 1 end
    pcall(writefile, "bss_ai_q_v12.json", HttpService:JSONEncode({version = Q_VERSION, qtable = QTable, meta = {stateCount = qc, savedAt = os.time()}}))
end) end)
print("✅ Готово.")
