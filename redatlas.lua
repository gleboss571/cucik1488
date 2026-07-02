-- BSS AI v15.7 — FINAL (SuperOutside, 9+ Dupes, BabyLove, Purples Fix)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local VIM = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")
local Q_VERSION = "15.7"
local ENABLED = true

local elog = {}
local egui = nil
local elbl = nil
local ebtn = nil
local ecnt = 0

local function mkErrGui()
    pcall(function()
        if egui then return end
        egui = Instance.new("ScreenGui")
        egui.Name = "BSSAI_Err"
        egui.ResetOnSpawn = false
        egui.Parent = PGui
        local bg = Instance.new("Frame", egui)
        bg.Size = UDim2.new(0, 380, 0, 240)
        bg.Position = UDim2.new(0.5, -190, 0.5, -120)
        bg.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        bg.BackgroundTransparency = 0.08
        bg.BorderSizePixel = 0
        bg.Active = true
        bg.Draggable = true
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
        local ti = Instance.new("TextLabel", bg)
        ti.Size = UDim2.new(1, -16, 0, 24)
        ti.Position = UDim2.new(0, 8, 0, 8)
        ti.BackgroundTransparency = 1
        ti.Text = "⚠ BSS AI v15.7"
        ti.TextColor3 = Color3.fromRGB(255, 180, 60)
        ti.Font = Enum.Font.GothamBold
        ti.TextSize = 14
        ti.TextXAlignment = Enum.TextXAlignment.Left
        local sep = Instance.new("Frame", bg)
        sep.Size = UDim2.new(1, -16, 0, 1)
        sep.Position = UDim2.new(0, 8, 0, 36)
        sep.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
        sep.BorderSizePixel = 0
        elbl = Instance.new("TextLabel", bg)
        elbl.Size = UDim2.new(1, -16, 0, 130)
        elbl.Position = UDim2.new(0, 8, 0, 42)
        elbl.BackgroundTransparency = 1
        elbl.Text = "⏳ v15.7 boot..."
        elbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        elbl.Font = Enum.Font.Code
        elbl.TextSize = 11
        elbl.TextXAlignment = Enum.TextXAlignment.Left
        elbl.TextYAlignment = Enum.TextYAlignment.Top
        elbl.TextWrapped = true
        elbl.RichText = true
        ebtn = Instance.new("TextButton", bg)
        ebtn.Size = UDim2.new(0, 140, 0, 28)
        ebtn.Position = UDim2.new(0, 8, 0, 180)
        ebtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        ebtn.BorderSizePixel = 0
        ebtn.Text = "📋 Копировать логи"
        ebtn.TextColor3 = Color3.fromRGB(220, 220, 220)
        ebtn.Font = Enum.Font.Gotham
        ebtn.TextSize = 11
        Instance.new("UICorner", ebtn).CornerRadius = UDim.new(0, 4)
        local cb = Instance.new("TextButton", bg)
        cb.Size = UDim2.new(0, 80, 0, 28)
        cb.Position = UDim2.new(0, 156, 0, 180)
        cb.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        cb.BorderSizePixel = 0
        cb.Text = "✕ Закрыть"
        cb.TextColor3 = Color3.fromRGB(220, 220, 220)
        cb.Font = Enum.Font.Gotham
        cb.TextSize = 11
        Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 4)
        cb.MouseButton1Click:Connect(function()
            egui.Enabled = false
            egui:Destroy()
            egui = nil
        end)
        ebtn.MouseButton1Click:Connect(function()
            local txt = table.concat(elog, "\n")
            if #txt == 0 then txt = "Нет ошибок" end
            pcall(setclipboard, txt)
            ebtn.Text = "✅ Скоп."
            task.wait(1.5)
            ebtn.Text = "📋 Копировать логи"
        end)
        task.spawn(function()
            task.wait(4)
            if egui and ecnt == 0 then egui.Enabled = false; egui:Destroy(); egui = nil end
        end)
    end)
end

local function logErr(m)
    ecnt = ecnt + 1
    table.insert(elog, string.format("[%02d] %s", ecnt, m))
    while #elog > 20 do table.remove(elog, 1) end
    if elbl then
        local L = {}
        local start = math.max(1, #elog - 12)
        local i = start
        while i <= #elog do
            table.insert(L, elog[i])
            i = i + 1
        end
        elbl.Text = table.concat(L, "\n")
        if ecnt == 1 then elbl.TextColor3 = Color3.fromRGB(255, 140, 100) end
    end
    warn("BSSAI:", m)
end

local function logOk(m)
    if elbl then
        elbl.Text = "✅ " .. m
        elbl.TextColor3 = Color3.fromRGB(140, 255, 160)
    end
end

mkErrGui()
logOk("GUI OK")

local SB = {}
SB["НАБОР"] = 70
SB["X10"] = 90
SB["REFRESH"] = 75
local SJ = 3
local AM = 1.2
local DGL = 22
local FM = 3
local AD = 5
local MT = 6
local PBI = 2574507284
local PPK = 0.02
local PMX = 10
local PRAT = 25
local PURP = Color3.fromRGB(119, 85, 255)
local PTOL = 12
local PST = 1
local SMI = 5877939956
local TSD = 1.1
local CAR = 28
local CAS = 20
local CAD = 0.1
local ARR = 20
local TLID = 20
local PCD = 8
local PFM = 20
local TPI = 8173559749
local TLC = 2
local PT = 8
local XCR = 15
local PCHR = 10
local SCYTHE_DIST = 14
local SCYTHE_CD = 0.4
local AL = 0.5
local GA = 0.95
local EP = 0.3
local ED = 0.9995
local PMBI = 2577647416
local FOCI = 2577384907
local RBOI = 2577383393
local FOCUS_RENEW = 10
local RB_RENEW = 7
local RB_SCORCH_RENEW = 9
local SCORCH_BIAS = 1.15
local PAT_WINDOW = 2400
local PAT_TOP = 10

local TKS = {}
TKS[1629547638] = { n = "Token Link", b = 4, p = 99 }
TKS[8173559749] = { n = "Target Practice", b = 8, p = 95 }
TKS[2000457501] = { n = "Inspire", b = 8, p = 25 }
TKS[1472256444] = { n = "Baby Love", b = 8, p = 22 }
TKS[1629649299] = { n = "Focus", b = 4, p = 15 }
TKS[65867881] = { n = "Haste", b = 4, p = 15 }
TKS[1442863423] = { n = "Blue Boost", b = 4, p = 12 }
TKS[1442859163] = { n = "Red Boost", b = 4, p = 12 }
TKS[3877732821] = { n = "White Boost", b = 4, p = 12 }
TKS[1442764904] = { n = "Red Bomb+", b = 4, p = 12 }
TKS[1442700745] = { n = "Rage", b = 8, p = 10 }
TKS[253828517] = { n = "Melody", b = 8, p = 10 }
TKS[2499514197] = { n = "Honey Mark", b = 8, p = 9 }
TKS[2499540966] = { n = "Pollen Mark", b = 8, p = 9 }
TKS[1472532912] = { n = "Polar Bear", b = 15, p = 8, mo = true }
TKS[1472491940] = { n = "Black Bear", b = 15, p = 8, mo = true }
TKS[1472425802] = { n = "Brown Bear", b = 15, p = 8, mo = true }
TKS[2032949183] = { n = "Mother Bear", b = 15, p = 8, mo = true }
TKS[1472580249] = { n = "Panda", b = 15, p = 8, mo = true }
TKS[1489734171] = { n = "Science Bear", b = 15, p = 8, mo = true }
TKS[1874564120] = { n = "Pulse", b = 12, p = 7 }
TKS[4528379338] = { n = "Mark Surge", b = 4, p = 7 }
TKS[3582501342] = { n = "Rain Call", b = 24, p = 6 }
TKS[3582519526] = { n = "Tornado", b = 24, p = 6 }
TKS[5877998606] = { n = "Mind Hack", b = 16, p = 6 }
TKS[8083943936] = { n = "Surprise Party", b = 24, p = 6 }
TKS[177997841] = { n = "Glob", b = 4, p = 6 }
TKS[1839454544] = { n = "Gummy Storm", b = 4, p = 6 }
TKS[1442725244] = { n = "Bomb", b = 4, p = 5 }
TKS[5877939956] = { n = "Smile", b = 4, p = 5 }
TKS[4519549299] = { n = "Inferno", b = 4, p = 5 }
TKS[4519523935] = { n = "Triangulate", b = 4, p = 5 }
TKS[4528414666] = { n = "Summon Frog", b = 8, p = 5 }
TKS[4528208186] = { n = "Flame Fuel", b = 8, p = 5 }
TKS[1671281844] = { n = "Beamstorm", b = 12, p = 4 }
TKS[8083436978] = { n = "Blue Balloon", b = 4, p = 4 }
TKS[1104415222] = { n = "BondToken", b = 4, p = 4 }
TKS[2319100769] = { n = "Fetch", b = 8, p = 4 }
TKS[4889322534] = { n = "Fuzz Bombs", b = 4, p = 4 }
TKS[2319083910] = { n = "Impale", b = 24, p = 4 }
TKS[3080529618] = { n = "Jelly Bean", b = 4, p = 4 }
TKS[4889470194] = { n = "Pollen Haze", b = 4, p = 4 }
TKS[107187190] = { n = "Honey Gift", b = 4, p = 2 }
TKS[183390139] = { n = "Cog", b = 4, p = 2 }

local AV = {}
AV[1674871631] = true; AV[1471882621] = true; AV[1952740625] = true
AV[8055428094] = true; AV[2319943273] = true; AV[3030569073] = true
AV[3036899811] = true; AV[3080740120] = true; AV[3012679515] = true
AV[1838129169] = true; AV[2584584968] = true; AV[1471849394] = true
AV[1952682401] = true; AV[6087969886] = true; AV[2028574353] = true
AV[2028453802] = true

local PC = {}
PC["Red"] = Color3.fromRGB(249, 34, 34); PC["Pink"] = Color3.fromRGB(255, 130, 201)
PC["Merigold"] = Color3.fromRGB(218, 168, 28); PC["Periwinkle"] = Color3.fromRGB(150, 156, 236)
PC["Violet"] = Color3.fromRGB(94, 38, 177); PC["Scarlet"] = Color3.fromRGB(171, 19, 19)
PC["Green"] = Color3.fromRGB(35, 232, 5); PC["Yellow"] = Color3.fromRGB(238, 204, 79)
PC["Black"] = Color3.fromRGB(11, 11, 11); PC["Grey"] = Color3.fromRGB(127, 127, 127)
PC["Blue"] = Color3.fromRGB(33, 66, 249); PC["Cyan"] = Color3.fromRGB(29, 196, 222)
PC["White"] = Color3.fromRGB(249, 249, 249)

local PP = {}
PP.Red = 1; PP.Pink = 2; PP.Merigold = 3; PP.Periwinkle = 4; PP.Violet = 5
PP.Scarlet = 6; PP.Green = 7; PP.Yellow = 8; PP.Black = 9; PP.Grey = 10
PP.Blue = 11; PP.Cyan = 12; PP.White = 13

local aT = {}
local cQ = {}
local lP = nil
local curF = nil
local tL = "старт"

local prec = { st = 0, val = 0, isX = false, ls = 0, sD = 60, sS = 0, tL = 0, nR = false }
local st = { tk = 0, ch = 0, pr = 0, x10 = 0, rf = 0, tR = 0, dc = 0, sm = 0, chA = 0, pt = 0, chP = 0 }
local cyc = { chC = 0 }

local INT = false
local isCS = false
local smT = nil
local smTR = 0
local igT = 0
local fP = {}
local aR = nil
local aRR = ARR

local aB = {}
aB.SS = { st = 0 }; aB.XF = { st = 0 }; aB.PM = { a = false }
aB.PoM = { a = false, pos = nil, m = 0 }
aB.FC = { combo = 0, dur = 20, tL = 0 }; aB.RB = { combo = 0, dur = 15, tL = 0 }

local stP = setmetatable({}, { __mode = "k" })
local rCC = 0
local rST = 0
local hB = {}
local aBf = {}
local pH = {}
local bAH = 0
local laT = 0
local pF = "bss_ai_pat_v15.json"
local QT = {}
local lMT = tick()
local stW = false
local xfE = false
local xfC = nil
local lPT = 0
local qTables = {}
local pHTables = {}
local fldHash = nil
local dupCnt = 0
local cS = SB["НАБОР"]
local hbF = 0
local isA = false
local focusRenew = false
local rbSkip = false
local isSuperScorch = false
local scorchActive = false
local scorchRecording = false
local scorchActions = {}
local scorchSessions = {}
local top10patterns = {}
local bestScorchHoney = 0
local lastPatternSave = 0
local scytheParts = setmetatable({}, { __mode = "k" })
local lastScytheHit = 0
local scVis = nil
local syVis = nil
local fixedXFlameCenter = nil

local lastTokenLinkTime = 0
local lastFocusCHTime = 0

-- Coconuts
local activeCoconuts = {}

local function applyAntiLag()
    pcall(function()
        local targets = {
            "Flowers", "Bees", "Kukurudza_dontreal", "FieldDecos", 
            "Collectibles", "NPCs", "OnettNPC", "Noob Bear", "Top Bear", "Pro Bear"
        }
        for _, name in pairs(targets) do
            local f = Workspace:FindFirstChild(name)
            if f then
                for _, obj in pairs(f:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        obj.CastShadow = false
                        obj.Material = Enum.Material.SmoothPlastic
                        if name ~= "Collectibles" then
                            obj.Transparency = 1
                        end
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        obj:Destroy()
                    elseif obj:IsA("MeshPart") then
                        obj.CastShadow = false
                        obj.Transparency = 1
                    end
                end
            end
        end
        local lt = Workspace:FindFirstChild("Lighting")
        if lt then lt.GlobalShadows = false; lt.Brightness = 2 end
    end)
end

applyAntiLag()

local function h()
    local c = LP.Character
    if c then return c:FindFirstChild("HumanoidRootPart") end
    return nil
end

local function hm()
    local c = LP.Character
    if c then return c:FindFirstChildOfClass("Humanoid") end
    return nil
end

local function ti(t)
    if not t then return nil end
    return tonumber(t:match("rbxassetid://(%d+)") or t:match("id=(%d+)"))
end

local function d3(a, b)
    local dx = a.X - b.X
    local dz = a.Z - b.Z
    return math.sqrt(dx * dx + dz * dz)
end

local function d3d(a, b)
    return (a - b).Magnitude
end

local function d2Sq(a, b)
    local dx = a.X - b.X
    local dz = a.Z - b.Z
    return dx * dx + dz * dz
end

local function ph()
    if not prec.isX then return "НАБОР" end
    if prec.nR then return "REFRESH" end
    return "X10"
end

local function scPh()
    if aB.SS.st > 0 then return "INSIDE" end
    return "OUTSIDE"
end

local function fmtHoney(v)
    if v >= 1e12 then return string.format("%.2fT", v / 1e12) end
    if v >= 1e9 then return string.format("%.2fB", v / 1e9) end
    if v >= 1e6 then return string.format("%.2fM", v / 1e6) end
    if v >= 1e3 then return string.format("%.1fK", v / 1e3) end
    return string.format("%.0f", v)
end

local function getCoreHoney()
    local cs = LP:FindFirstChild("CoreStats")
    if cs then
        local hv = cs:FindFirstChild("Honey")
        if hv then return hv.Value or 0 end
    end
    return 0
end

local function getCtxKey()
    local fcS = "F0"
    if aB.FC.combo >= 10 then fcS = "F1" end
    local rbS = "R0"
    if aB.RB.combo >= 10 then rbS = "R1" end
    return string.format("%s|%s|%s|%d", ph(), fcS, rbS, math.min(3, aB.PoM.m))
end

local function fldHashFn()
    if not curF then return "unknown" end
    if not curF.part then return "unknown" end
    local c = curF.part.Position
    return string.format("%.0f%.0f", c.X / 50, c.Z / 50)
end

local function swFld()
    local nh = fldHashFn()
    if nh == fldHash then return end
    if qTables[fldHash] then qTables[fldHash] = QT end
    if pHTables[fldHash] then pHTables[fldHash] = pH end
    fldHash = nh
    QT = qTables[fldHash] or {}
    pH = pHTables[fldHash] or {}
end

local function fF()
    local r = h()
    if not r then return curF end
    local mp = r.Position
    local z = Workspace:FindFirstChild("FlowerZones")
    if z then
        local be = nil
        local bd = math.huge
        local children = z:GetChildren()
        for ci = 1, #children do
            local zn = children[ci]
            if zn:IsA("BasePart") then
                local d = d3(mp, zn.Position)
                local s = zn.Size
                if math.abs(mp.X - zn.Position.X) <= s.X / 2 + 20 then
                    if math.abs(mp.Z - zn.Position.Z) <= s.Z / 2 + 20 then
                        if d < bd then bd = d; be = zn end
                    end
                end
            end
        end
        if be then curF = { part = be }; swFld(); return curF end
    end
    local fl = Workspace:FindFirstChild("Flowers")
    if fl then
        local fp = {}
        local fchildren = fl:GetChildren()
        for fi = 1, #fchildren do
            local f = fchildren[fi]
            if f:IsA("BasePart") then table.insert(fp, f.Position) end
        end
        if #fp > 0 then
            local mnX, mxX, mnZ, mxZ = math.huge, -math.huge, math.huge, -math.huge
            for pi = 1, #fp do
                local p = fp[pi]
                if p.X < mnX then mnX = p.X end
                if p.X > mxX then mxX = p.X end
                if p.Z < mnZ then mnZ = p.Z end
                if p.Z > mxZ then mxZ = p.Z end
            end
            curF = {
                part = {
                    Position = Vector3.new((mnX + mxX) / 2, mp.Y, (mnZ + mxZ) / 2),
                    Size = Vector3.new(math.abs(mxX - mnX) + 10, 1, math.abs(mxZ - mnZ) + 10)
                }
            }
            swFld()
            return curF
        end
    end
    if aR then
        curF = {
            part = {
                Position = aR.Position,
                Size = Vector3.new(aRR * 3, 1, aRR * 3)
            }
        }
        swFld()
        return curF
    end
    return curF
end

local function gFC()
    if xfE and fixedXFlameCenter then return fixedXFlameCenter end
    if curF and curF.part then return curF.part.Position end
    local r = h()
    if r then return r.Position end
    return Vector3.zero
end

local function gAS()
    local p = ph()
    local b = SB[p] or SB["НАБОР"]
    if isSuperScorch then b = 55 end
    if hbF % 30 == 0 then
        local base = b + (math.random() * 2 - 1) * SJ
        if math.abs(base - cS) > 1 then cS = base end
    end
    return cS
end

local function cP(pos, sk)
    if sk then return pos end
    if not curF then return pos end
    local c = curF.part.Position
    local s = curF.part.Size
    local mx = math.max(s.X / 2 - FM, 1)
    local mz = math.max(s.Z / 2 - FM, 1)
    local cl = Vector3.new(math.clamp(pos.X, c.X - mx, c.X + mx), pos.Y, math.clamp(pos.Z, c.Z - mz, c.Z + mz))
    if aB.XF.st >= 19 then
        local dx = cl.X - c.X
        local dz = cl.Z - c.Z
        local dSq = dx * dx + dz * dz
        if dSq > 0 then
            local invD = 1 / math.sqrt(dSq)
            cl = Vector3.new(c.X + dx * invD * XCR, cl.Y, c.Z + dz * invD * XCR)
        end
    end
    return cl
end

local function iF(pos)
    if not curF then return false end
    local c = curF.part.Position
    local s = curF.part.Size
    return math.abs(pos.X - c.X) <= s.X / 2 + PFM and math.abs(pos.Z - c.Z) <= s.Z / 2 + PFM
end

local function fAR()
    local p = Workspace:FindFirstChild("Particles")
    if p then
        local children = p:GetChildren()
        for i = 1, #children do
            local o = children[i]
            if o.Name == "AreaRing" and o:IsA("BasePart") then
                aR = o
                aRR = (o.Size.X + o.Size.Z) / 4
                if aRR < 5 then aRR = ARR end
                return
            end
        end
    end
    aR = Workspace:FindFirstChild("AreaRing")
    if aR and aR:IsA("BasePart") then
        aRR = (aR.Size.X + aR.Size.Z) / 4
        if aRR < 5 then aRR = ARR end
    else
        aR = nil
        aRR = ARR
    end
end

local Pt = Workspace:FindFirstChild("Particles")
if not Pt then Pt = workspace:WaitForChild("Particles", 10) end

local function iCl(a, b, tl)
    if not tl then tl = PTOL end
    return math.abs(a.R * 255 - b.R * 255) <= tl
       and math.abs(a.G * 255 - b.G * 255) <= tl
       and math.abs(a.B * 255 - b.B * 255) <= tl
end

local function iP(p)
    local ok1, c1 = pcall(function() return p.Color end)
    if ok1 and c1 and iCl(c1, PURP) then return true end
    local ok2, bc = pcall(function() return p.BrickColor.Color end)
    if ok2 and bc and iCl(bc, PURP) then return true end
    return false
end

local function aCH(o)
    if o.Name ~= "Crosshair" or not o:IsA("BasePart") then return end
    for i = 1, #cQ do
        if cQ[i].part == o then return end
    end
    task.spawn(function()
        task.wait(0.06) 
        if not o.Parent then return end
        table.insert(cQ, { part = o, sT = tick(), col = false, isP = iP(o) })
    end)
end

if Pt then
    Pt.DescendantAdded:Connect(function(o)
        aCH(o)
        if o.Name == "WarningDisk" and o:IsA("BasePart") then
            if math.abs(o.Size.X - 8) > 0.5 then 
                table.insert(activeCoconuts, { part = o, spawnTime = tick(), collected = false })
            end
        end
    end)
    Pt.DescendantRemoving:Connect(function(o)
        for i = #cQ, 1, -1 do
            if cQ[i].part == o then table.remove(cQ, i); break end
        end
        if lP == o then lP = nil end
        for i = #activeCoconuts, 1, -1 do
            if activeCoconuts[i].part == o then table.remove(activeCoconuts, i); break end
        end
    end)
    local desc = Pt:GetDescendants()
    for j = 1, #desc do aCH(desc[j]) end
end

local function clnCH()
    for i = #cQ, 1, -1 do
        local ch = cQ[i]
        if not ch.part or not ch.part.Parent or ch.col then table.remove(cQ, i) end
    end
end

local function gCH(op, oR, purpFirst)
    local L = {}
    local P = {}
    for i = #cQ, 1, -1 do
        local ch = cQ[i]
        local alive = false
        pcall(function() if ch.part and ch.part.Parent then alive = true end end)
        if not alive then
            table.remove(cQ, i)
        elseif not ch.col then
            if (op and ch.isP) or (oR and not ch.isP) or (not op and not oR) then
                if purpFirst and ch.isP then table.insert(P, ch) else table.insert(L, ch) end
            end
        end
    end
    table.sort(L, function(a, b) return a.sT < b.sT end)
    table.sort(P, function(a, b) return a.sT < b.sT end)
    if purpFirst then
        for pi = #P, 1, -1 do table.insert(L, 1, P[pi]) end
    end
    return L
end

local function gPCH()
    return gCH(true, false)
end

local function gTPG_build()
    local all = gCH(false, false)
    if #all < 3 then return nil end
    local G = {}
    for i = 1, #all do
        local c = all[i]
        if c.isP then
            local closest = {}
            for j = 1, #all do
                if not all[j].isP and i ~= j then
                    local dist = d3(c.part.Position, all[j].part.Position)
                    if dist < 25 then
                        table.insert(closest, {ch = all[j], d = dist})
                    end
                end
            end
            table.sort(closest, function(a, b) return a.d < b.d end)
            if #closest >= 2 then
                table.insert(G, { pr = c, r1 = closest[1].ch, r2 = closest[2].ch })
            end
        end
    end
    if #G > 0 then return G end
    return nil
end

local function gTPG()
    if not prec.isX or prec.nR then return nil end
    return gTPG_build()
end

local function gCH_nearest_center()
    local cc = gFC()
    if cc == Vector3.zero then return nil end
    local best = nil
    local bestD = math.huge
    for i = 1, #cQ do
        local ch = cQ[i]
        if not ch.col and ch.part.Parent then 
            local d = d3(ch.part.Position, cc)
            if d <= XCR * 2.5 and d < bestD then bestD = d; best = ch end
        end
    end
    return best
end

local function gCH_nearest()
    local r = h()
    if not r then return nil end
    local best = nil
    local bestD = math.huge
    for i = 1, #cQ do
        local ch = cQ[i]
        if not ch.col and ch.part.Parent then
            local d = d3(r.Position, ch.part.Position)
            if d < bestD then bestD = d; best = ch end
        end
    end
    return best
end

local cATCache = {}
local cATFrame = 0

local function gRCT(mP, dP)
    if focusRenew or isSuperScorch then return {} end
    if not prec.isX or prec.nR then return {} end
    if cATFrame == hbF and cATCache[mP] then return cATCache[mP] end
    local mf = Vector3.new(mP.X, 0, mP.Z)
    local df = Vector3.new(dP.X, 0, dP.Z)
    local tt = df - mf
    if tt.Magnitude < 1 then return {} end
    local tD = tt.Unit
    local th = {}
    for i = 1, #cQ do
        local ch = cQ[i]
        if not ch.col and ch.part.Parent and not ch.isP then
            local cf = Vector3.new(ch.part.Position.X, 0, ch.part.Position.Z)
            local toCh = cf - mf
            local d = toCh.Magnitude
            if d < CAR and d > 1 then
                local dot = toCh.Unit:Dot(tD)
                if dot > CAD then
                    local cross = math.abs(toCh.X * tD.Z - toCh.Z * tD.X)
                    if cross < CAR then
                        table.insert(th, { ch = ch, pos = cf, dist = d, cross = cross })
                    end
                end
            end
        end
    end
    cATFrame = hbF
    cATCache = {}
    cATCache[mP] = th
    return th
end

local function cAT(mP, dP)
    local th = gRCT(mP, dP)
    if #th == 0 then return nil end
    table.sort(th, function(a, b) return a.dist < b.dist end)
    local t = th[1]
    local mf = Vector3.new(mP.X, 0, mP.Z)
    local df = Vector3.new(dP.X, 0, dP.Z)
    local tD = (df - mf).Unit
    local toCh = t.pos - mf
    local uCh = toCh.Unit
    local p1 = Vector3.new(-uCh.Z, 0, uCh.X)
    local p2 = Vector3.new(uCh.Z, 0, -uCh.X)
    local bp = nil
    if p2:Dot(tD) >= p1:Dot(tD) then bp = p2 else bp = p1 end
    st.chA = st.chA + 1
    return cP(Vector3.new(t.pos.X + bp.X * CAS, mP.Y, t.pos.Z + bp.Z * CAS))
end

local function tryRedirectToCH(origTarget)
    local r = h()
    if not r then return false end
    local best = nil
    local bestD = math.huge
    for i = 1, #cQ do
        local ch = cQ[i]
        if not ch.col and ch.part.Parent then
            local d = d3(r.Position, ch.part.Position)
            if d <= PCHR and d < bestD then bestD = d; best = ch end
        end
    end
    if not best then return false end
    if origTarget and best.part == origTarget then return false end
    local hm_ = hm()
    if not hm_ then return false end
    hm_:MoveTo(best.part.Position)
    local t0 = tick()
    local collected = false
    while tick() - t0 < 0.6 do
        task.wait(0.03)
        local r2 = h()
        if not r2 then break end
        if not best.part.Parent then best.col = true; break end
        if d3(r2.Position, best.part.Position) <= 4 then
            best.col = true
            st.chP = st.chP + 1
            if best.isP then st.pr = st.pr + 1; lP = best.part else st.ch = st.ch + 1 end
            collected = true
            break
        end
    end
    if not collected and best.part.Parent then
        best.col = true
        st.chP = st.chP + 1
        if best.isP then st.pr = st.pr + 1 else st.ch = st.ch + 1 end
    end
    return true
end

local function goTo(tP, rad, to, sk)
    rad = rad or AD
    to = to or MT
    if to > 12 then to = 12 end
    if tP == Vector3.zero then return false end
    local r = h()
    local hm_ = hm()
    if not r or not hm_ then return false end
    tP = cP(tP, sk)
    if tP == Vector3.zero then
        local c = gFC()
        if c == Vector3.zero then return false end
        tP = c
    end
    local oT = Vector3.new(tP.X, r.Position.Y, tP.Z)
    local cM = oT
    local av = cAT(r.Position, oT)
    if av then cM = Vector3.new(av.X, r.Position.Y, av.Z) end
    hm_:MoveTo(cM)
    local t0 = tick()
    local lM = tick()
    local lA = tick()
    local lPC = tick()
    while tick() - t0 < to do
        task.wait(0.04)
        if not ENABLED or INT then return false end
        r = h()
        if not r then return false end
        if d3(r.Position, oT) <= rad then return true end
        if tick() - lA >= 0.15 then
            lA = tick()
            local na = cAT(r.Position, oT)
            if na then cM = Vector3.new(na.X, r.Position.Y, na.Z) else cM = oT end
        end
        if cM ~= oT and d3(r.Position, cM) <= 4 then
            local na = cAT(r.Position, oT)
            if na then cM = Vector3.new(na.X, r.Position.Y, na.Z) else cM = oT end
        end
        if tick() - lPC >= 0.25 then
            lPC = tick()
            local redirected = tryRedirectToCH(nil)
            if redirected then
                hm_ = hm()
                if hm_ then hm_:MoveTo(cM) end
            end
        end
        if tick() - lM >= 0.3 then
            hm_ = hm()
            if hm_ then hm_:MoveTo(cM) end
            lM = tick()
        end
    end
    return false
end

local function rT(o)
    if o.Name ~= "C" or not o:IsA("BasePart") or aT[o] or tick() < igT then return end
    local fr = o:FindFirstChild("FrontDecal")
    if not fr or not fr:IsA("Decal") then return end
    local id = ti(fr.Texture)
    if not id or AV[id] then return end
    local df = TKS[id]
    if not df then return end
    local r = h()
    local dp = false
    if r then dp = (o.Position.Y - r.Position.Y) > 5 end
    local lf = df.b * AM
    if dp then
        lf = lf * (2 + 0.05 * (DGL - 1))
        dupCnt = dupCnt + 1
    end
    aT[o] = { id = id, n = df.n, p = df.p, mo = df.mo or false, s = tick(), l = lf, dp = dp, col = false }
end

Workspace.DescendantAdded:Connect(function(o) 
    if o.Name == "C" then pcall(rT, o) end 
end)

do
    local allDesc = Workspace:GetDescendants()
    for k = 1, #allDesc do pcall(rT, allDesc[k]) end
end

game.DescendantRemoving:Connect(function(o)
    if aT[o] then
        if aT[o].col then st.tk = st.tk + 1 end
        if aT[o].dp then dupCnt = math.max(0, dupCnt - 1) end
        aT[o] = nil
    end
end)

local rps = nil
do
    local e = RS:FindFirstChild("Events")
    if e then rps = e:FindFirstChild("RetrievePlayerStats") end
end

local function flatBuffs(t, d)
    if type(t) ~= "table" then return end
    local bid = rawget(t, "BuffID")
    if bid then d[bid] = t end
    local src = rawget(t, "Src")
    if src then d[src] = t end
    for nxt, val in pairs(t) do
        if type(val) == "table" then flatBuffs(val, d) end
    end
end

local function sBf()
    if not rps then return end
    local ok, res = pcall(rps.InvokeServer, rps)
    if not ok or type(res) ~= "table" then return end
    local fd = {}
    flatBuffs(res, fd)
    local prevSS = aB.SS.st
    local ss = fd["Scorching Star Aura"]
    if ss then aB.SS.st = tonumber(rawget(ss, "Combo") or 0) or 0 else aB.SS.st = 0 end
    local xf = fd["X-Flame Aura"]
    if xf then aB.XF.st = tonumber(rawget(xf, "Combo") or 0) or 0 else aB.XF.st = 0 end
    aB.PM.a = false
    if fd[2575093099] and rawget(fd[2575093099], "Removed") ~= true then aB.PM.a = true end
    local pm = fd[PMBI]
    if pm and rawget(pm, "Removed") ~= true then
        aB.PoM.a = true
        aB.PoM.m = tonumber(rawget(pm, "Combo") or 0) or 1
        if aR then aB.PoM.pos = aR.Position end
    else aB.PoM.a = false; aB.PoM.m = 0 end
    local fc = fd[FOCI]
    if fc and rawget(fc, "Removed") ~= true then
        aB.FC.combo = tonumber(rawget(fc, "Combo") or 0) or 0
        aB.FC.dur = tonumber(rawget(fc, "Dur") or 20) or 20
        local fcStart = tonumber(rawget(fc, "Start") or os.clock()) or os.clock()
        aB.FC.tL = math.max(0, aB.FC.dur - (os.clock() - fcStart))
    else aB.FC.combo = 0; aB.FC.tL = 0 end
    local rb = fd[RBOI]
    if rb and rawget(rb, "Removed") ~= true then
        aB.RB.combo = tonumber(rawget(rb, "Combo") or 0) or 0
        aB.RB.dur = tonumber(rawget(rb, "Dur") or 15) or 15
        local rbStart = tonumber(rawget(rb, "Start") or os.clock()) or os.clock()
        aB.RB.tL = math.max(0, aB.RB.dur - (os.clock() - rbStart))
    else aB.RB.combo = 0; aB.RB.tL = 0 end
    local curH = getCoreHoney()
    if aB.SS.st > 0 and prevSS == 0 then
        scorchStartHoney = curH
        scorchStartTime = tick()
        scorchActive = true
        scorchRecording = true
        scorchActions = {}
    elseif aB.SS.st == 0 and prevSS > 0 then
        scorchActive = false
        if scorchRecording and scorchStartTime > 0 then
            local gained = curH - scorchStartHoney
            local dur = (tick() - scorchStartTime) / 60
            if gained > 0 then
                table.insert(scorchSessions, {
                    honeyGained = gained,
                    durationMin = math.floor(dur * 10) / 10,
                    time = tick(),
                    ssCombo = prevSS,
                    ctx = getCtxKey(),
                    actions = scorchActions
                })
                if gained > bestScorchHoney then bestScorchHoney = gained end
            end
            scorchRecording = false
            scorchActions = {}
        end
    end
end

local function sPr()
    if not rps then return end
    local ok, pd = pcall(rps.InvokeServer, rps)
    if not ok or type(pd) ~= "table" then return end
    local fd = {}
    flatBuffs(pd, fd)
    local b = fd[PBI]
    if b and rawget(b, "Removed") ~= true then
        prec.val = tonumber(rawget(b, "Value") or 0) or 0
        local bStart = tonumber(rawget(b, "Start"))
        if bStart and bStart ~= prec.sS then
            prec.sS = bStart
            prec.sD = tonumber(rawget(b, "Dur") or 60) or 60
            prec.ls = os.clock()
        end
        prec.st = math.min(PMX, math.round(prec.val / PPK))
        prec.isX = (prec.st >= PMX)
    else prec.st = 0; prec.val = 0; prec.isX = false end
    if prec.ls > 0 then
        prec.tL = math.max(0, prec.sD - (os.clock() - prec.ls))
        prec.nR = prec.isX and (prec.tL <= PRAT)
        if prec.nR and rCC == 0 then rST = tick(); rCC = 0 end
    end
end

local function gPC(p)
    for nxt, co in pairs(PC) do
        local dr = co.R - p.Color.R
        local dg = co.G - p.Color.G
        local db = co.B - p.Color.B
        if dr * dr + dg * dg + db * db < 0.002 then return nxt end
    end
    return nil
end

local function sPt()
    fP = {}
    if not ENABLED or not curF then return end
    local pt = Workspace:FindFirstChild("Particles")
    if not pt then return end
    local r = h()
    if not r then return end
    local children = pt:GetChildren()
    for i = 1, #children do
        local o = children[i]
        if o.Name == "PetalPart" and o:IsA("BasePart") and iF(o.Position) then
            local cn = gPC(o)
            if cn and PP[cn] then
                table.insert(fP, { part = o, cn = cn, pr = PP[cn], dist = d3d(r.Position, o.Position) })
            end
        end
    end
    table.sort(fP, function(a, b)
        if a.pr ~= b.pr then return a.pr < b.pr end
        return a.dist < b.dist
    end)
end

local function sSm()
    local n = tick()
    smT = nil
    smTR = 0
    local bp = nil
    local bd = math.huge
    local br = 0
    local r = h()
    if not r then return end
    if dupCnt < 6 then return end
    local rp = nil
    if aR then rp = aR.Position end
    local hp = aB.PoM.a
    for p, t in pairs(aT) do
        if not t.col and p.Parent and t.id == SMI then
            local rem = t.l - (n - t.s)
            if rem > 0 then
                local tk = true
                if hp and rp then
                    if d3(p.Position, rp) > aRR * 2 then tk = false end
                end
                if tk then
                    local d = d3(r.Position, p.Position)
                    if d < bd then bp = p; bd = d; br = rem end
                end
            end
        end
    end
    if bp then
        smT = bp
        smTR = br
        if not isCS then INT = true end
    end
end

local function uHB()
    local n = tick()
    if tL and tL ~= "старт" then
        local r = h()
        local rp = Vector3.zero
        if r then rp = r.Position end
        table.insert(aBf, { time = n, action = tL, pos = rp, phase = ph(), isSc = aB.SS.st > 0, scPh = scPh(), isSS = isSuperScorch })
    end
    local cut = n - 300
    while #aBf > 0 and aBf[1].time < cut do table.remove(aBf, 1) end
end

local function gPB(action, pos)
    if #pH == 0 then return 0 end
    local be = 0
    for i = 1, #pH do
        local p = pH[i]
        for j = 1, #p.actions do
            local pa = p.actions[j]
            if pa.action == action and d2Sq(pos, pa.pos) < 100 then
                local ms = 1
                if pa.phase == ph() then ms = ms * 2 end
                if pa.isSc and aB.SS.st > 0 then ms = ms * 2 end
                if pa.scPh == scPh() then ms = ms * 1.5 end
                if ms > be then be = ms end
            end
        end
    end
    return 15 * be
end

local function recalcTop10()
    local now = tick()
    local recent = {}
    for i = 1, #scorchSessions do
        local s = scorchSessions[i]
        if now - s.time <= PAT_WINDOW then table.insert(recent, s) end
    end
    table.sort(recent, function(a, b) return a.honeyGained > b.honeyGained end)
    top10patterns = {}
    local limit = math.min(PAT_TOP, #recent)
    for j = 1, limit do top10patterns[j] = recent[j] end
end

local function saveScorchSessions()
    if not writefile then return end
    if tick() - lastPatternSave < 120 then return end
    lastPatternSave = tick()
    recalcTop10()
    pcall(function()
        writefile("bss_ai_scorch_v15.json", Http:JSONEncode({ scorchSessions = scorchSessions, bestScorch = bestScorchHoney, top10 = top10patterns }))
    end)
end

local function getPatternBias(action)
    local ctx = getCtxKey()
    local bias = 1.0
    for i = 1, #top10patterns do
        local tp = top10patterns[i]
        if tp.ctx == ctx then
            for j = 1, #tp.actions do
                local ta = tp.actions[j]
                if ta.action == action and SCORCH_BIAS > bias then bias = SCORCH_BIAS; break end
            end
        end
    end
    return bias
end

local function recordScorchAction(action)
    if not scorchRecording then return end
    local r = h()
    local rp = Vector3.zero
    if r then rp = r.Position end
    table.insert(scorchActions, {
        action = action, pos = rp, phase = ph(),
        fc = (aB.FC.combo >= 10 and 1 or 0),
        rb = (aB.RB.combo >= 10 and 1 or 0),
        pm = math.min(3, aB.PoM.m), ssCombo = aB.SS.st
    })
end

local function scanScythes()
    local pf = Workspace:FindFirstChild("PlayerFlames")
    if not pf then return end
    local children = pf:GetChildren()
    for i = 1, #children do
        local f = children[i]
        local nm = f.Name or ""
        if nm:sub(1, 3) == "Flm" or nm:find("Scythe") or nm:find("Flame") then
            if not scytheParts[f] then scytheParts[f] = { sT = tick(), hit = false } end
        end
    end
end

local function tryHitScythe()
    if not ENABLED then return false end
    local r = h()
    if not r then return false end
    local n = tick()
    if n - lastScytheHit < SCYTHE_CD then return false end
    
    local targetFlame = nil
    for fl, data in pairs(scytheParts) do
        if fl.Parent then
            local isDark = (fl.Name:find("Dark") or fl.BrickColor.Name == "Really black")
            if not isDark then
                local dist = d3(r.Position, fl.Position)
                if dist <= SCYTHE_DIST and (n - data.sT) >= 6.0 then
                    targetFlame = fl
                    break
                end
            end
        else
            scytheParts[fl] = nil
        end
    end

    if not targetFlame then
        local happenings = Workspace:FindFirstChild("Happenings")
        if happenings then
            local poppable = happenings:FindFirstChild("PoppablePlants")
            if poppable then
                local bestBloom = nil
                local minPetals = math.huge
                for _, bloom in ipairs(poppable:GetChildren()) do
                    if bloom.Name == "Bloom" then
                        local dist = d3(r.Position, bloom.Position)
                        if dist <= SCYTHE_DIST then
                            local petalCount = 0
                            for _, p in ipairs(bloom:GetChildren()) do
                                if p.Name == "Petal" then petalCount = petalCount + 1 end
                            end
                            if petalCount < minPetals then
                                minPetals = petalCount
                                bestBloom = bloom
                            end
                        end
                    end
                end
                if bestBloom then targetFlame = bestBloom end
            end
        end
    end

    if targetFlame then
        lastScytheHit = n
        local bg = r:FindFirstChild("AI_BG_Scythe")
        if not bg then
            bg = Instance.new("BodyGyro")
            bg.Name = "AI_BG_Scythe"
            bg.MaxTorque = Vector3.new(0, 40000, 0)
            bg.P = 10000
            bg.D = 500
            bg.Parent = r
        end
        local dir = targetFlame.Position - r.Position
        dir = Vector3.new(dir.X, 0, dir.Z)
        if dir.Magnitude > 0.1 then bg.CFrame = CFrame.lookAt(r.Position, r.Position + dir) end
        
        task.wait(0.08)
        local ev = RS:FindFirstChild("Events")
        local tce = ev and ev:FindFirstChild("ToolCollect")
        local hit = false
        if tce then
            pcall(function() tce:FireServer() end)
            hit = true
        end
        if not hit then
            pcall(function()
                local cam = workspace.CurrentCamera
                local vp = cam.ViewportSize
                VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 1)
                task.wait(0.05)
                VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 1)
            end)
        end
        task.wait(0.1)
        if bg then bg:Destroy() end
        return true
    end
    return false
end

local function gQ(s, a)
    local row = QT[s]
    if row then return row[a] or 0 end
    return 0
end

local function sQ(s, a, v)
    if not QT[s] then QT[s] = {} end
    QT[s][a] = v
end

local function hTL()
    for p, t in pairs(aT) do
        if not t.col and p.Parent and t.p >= 90 then
            if t.dp then
                if tick() - lastTokenLinkTime > 3.0 then return true end
            else
                return true
            end
        end
    end
    return false
end

local function gDTP()
    local n = tick()
    for p, t in pairs(aT) do
        if not t.col and p.Parent and t.id == TPI and t.dp and t.l - (n - t.s) > 1 then
            return p, t
        end
    end
    return nil, nil
end

local function gSDA()
    local r = h()
    if not r then return nil end
    local rp = nil
    if aR then rp = aR.Position end
    if not rp then return nil end
    local bpSm = nil
    local bdSm = math.huge
    local bpTp = nil
    local bdTp = math.huge
    for p, t in pairs(aT) do
        if not t.col and p.Parent then
            local dRing = d3(p.Position, rp)
            if dRing <= aRR * 1.5 then
                local d = d3(r.Position, p.Position)
                if t.id == SMI and d < bdSm then bdSm = d; bpSm = p end
                if t.id == TPI and t.dp and d < bdTp then bdTp = d; bpTp = p end
            end
        end
    end
    if bpSm and bpTp then
        local n = tick()
        local st_ = aT[bpSm]
        local smRem = st_ and (st_.l - (n - st_.s)) or 0
        if smRem <= 3 then return bpSm end
        return bpTp
    elseif bpSm then return bpSm else return bpTp end
end

local function eS()
    local r = h()
    if not r then return "dead" end
    local p_ = ph()
    local tlD = "none"
    for p, t in pairs(aT) do
        if not t.col and p.Parent and t.p >= 90 then
            local d = d3(r.Position, p.Position)
            if d < 20 then tlD = "close" elseif d < 60 then tlD = "far" end
        end
    end
    local prN = math.min(3, #gCH(true, false))
    local rN = math.min(3, #gCH(false, true))
    local sU = (smT ~= nil and "1" or "0")
    local hP = (#fP > 0 and "1" or "0")
    local nT = false
    local n = tick()
    for p, t in pairs(aT) do
        if not t.col and p.Parent and (t.l - (n - t.s)) > 1 and d3(r.Position, p.Position) < 30 then
            nT = true; break
        end
    end
    local zn = "mid"
    if curF and curF.part and curF.part.Parent then
        local c = curF.part.Position
        local s = curF.part.Size
        if s.X > 0 and s.Z > 0 then
            local rx = math.abs(r.Position.X - c.X) / (s.X / 2)
            local rz = math.abs(r.Position.Z - c.Z) / (s.Z / 2)
            if rx > 0.7 or rz > 0.7 then zn = "edge" end
            if rx < 0.3 and rz < 0.3 then zn = "center" end
        end
    end
    local chT = "none"
    if prec.isX and not prec.nR then
        local ct = 0
        for i = 1, #cQ do
            local ch = cQ[i]
            if not ch.col and ch.part.Parent and not ch.isP and d3(r.Position, ch.part.Position) < 20 then
                ct = ct + 1
            end
        end
        if ct > 2 then chT = "many" elseif ct > 0 then chT = "some" end
    end
    local sc = (aB.SS.st > 0 and "1" or "0")
    local xf = (aB.XF.st >= 19 and "1" or "0")
    local fcS = (aB.FC.combo >= 10 and "1" or "0")
    local rbS = (aB.RB.combo >= 10 and "1" or "0")
    local pmS = math.min(3, aB.PoM.m)
    return string.format("PH:%s|SC:%s|TL:%s|CH:%d|PR:%d|SM:%s|NT:%s|Z:%s|CT:%s|PT:%s|XF:%s|FC:%s|RB:%s|PM:%d",
    p_, scPh(), tlD, rN, prN, sU, tostring(nT), zn, chT, hP, xf, fcS, rbS, pmS)
end

local function gAWB()
    local ba = {}
    local p_ = ph()
    local n = tick()

    focusRenew = (aB.FC.combo >= 10 and aB.FC.tL > 0 and aB.FC.tL <= FOCUS_RENEW)
    rbSkip = (aB.RB.combo >= 10 and aB.RB.tL > 0 and aB.RB.tL <= RB_RENEW)
    isSuperScorch = (aB.SS.st > 0 and prec.isX and aB.PoM.m >= 3)
    local isScorchActive = (aB.SS.st > 0)

    local hasDupedMorph = false
    for p, t in pairs(aT) do
        if not t.col and p.Parent and t.dp and t.mo then
            hasDupedMorph = true
            break
        end
    end
    local isSuperOutside = (not isScorchActive) and prec.isX and hasDupedMorph

    local nearCH = gCH_nearest()
    if nearCH and not smT and not xfE then
        if not isSuperScorch and not isSuperOutside then
            return { "go_crosshair" }
        end
    end

    if isSuperScorch then
        local rbScorch = (aB.RB.combo >= 10 and aB.RB.tL > 0 and aB.RB.tL <= RB_SCORCH_RENEW)
        if rbScorch then
            local pp = gPCH()
            if #pp > 0 then return { "go_purple_rb_renew" } end
        end
        local tp = gTPG_build()
        if tp then return { "go_build_precision" } end
        local pp = gPCH()
        if #pp >= 2 then return { "go_multi_purple" } end
        local all = gCH(false, false, true)
        if #all > 0 then return { "go_crosshair_all" } end
        return { "patrol_ring" }
    end

    if xfE then
        local cc = gFC()
        if cc ~= Vector3.zero then
            local bC = gCH_nearest_center()
            if bC then return { "go_xflame_ch" } end
            return { "go_xflame_center" }
        end
    end

    if isScorchActive then
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.id == 2000457501 and t.dp then
                local age = n - t.s
                if age > 2.0 then return { "go_duped_inspire_scorch" } end
            end
        end
    else
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.dp then
                local rem = t.l - (n - t.s)
                if t.mo and rem < 4.0 and rem > 0 then
                    return { "go_duped_morph" }
                elseif t.id == 2000457501 and rem < 2.0 and rem > 0 then
                    return { "go_duped_inspire_normal" }
                elseif t.id == 1472256444 and rem < 5.0 and rem > 0 then
                    return { "go_duped_babylove" }
                end
            end
        end
    end

    if focusRenew then
        local all = gCH(false, false, false)
        if #all > 0 then return { "go_focus_renew" } end
    end

    if hTL() then return { "go_tokenlink" } end
    
    for i, coco in ipairs(activeCoconuts) do
        if not coco.collected and coco.part.Parent then
            local rem = 3.0 - (n - coco.spawnTime)
            if rem <= 1.0 and rem > 0.0 then
                return { "go_coconut" }
            end
        end
    end

    if not isSuperScorch then
        for fl, data in pairs(scytheParts) do
            if fl.Parent then
                local isDark = (fl.Name:find("Dark") or fl.BrickColor.Name == "Really black")
                if not isDark and (n - data.sT) > 2.0 then
                    table.insert(ba, "go_touch_flame")
                    break
                end
            end
        end
    end

    if dupCnt >= 9 then
        local cc = gFC()
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.dp then
                if not t.mo and t.id ~= 2000457501 and t.id ~= 5877939956 and t.id ~= 107187190 and t.id ~= 1472256444 then
                    if d3(p.Position, cc) < 40 then
                        return { "go_duped_9plus" }
                    end
                end
            end
        end
    end

    if smT and dupCnt >= 6 and not isSuperOutside then return { "go_smile" } end

    if aB.PoM.a and aR and not isSuperScorch then
        local t = gSDA()
        if t then
            local td = aT[t]
            if td and td.id == SMI then table.insert(ba, 1, "go_smile_area")
            elseif td and td.id == TPI and td.dp then table.insert(ba, 1, "go_dup_area") end
        end
    end

    if rbSkip then
        local pp = gPCH()
        if #pp > 0 then return { "go_purple_rb_renew" } end
    end

    if p_ == "REFRESH" then
        local all = gCH(false, false, true)
        if #all > 0 then return { "go_crosshair_refresh_all" } end
        return { "patrol_ring" }
    end

    if p_ == "X10" then
        if isSuperOutside then
            if tick() - lastFocusCHTime > 6.0 then
                local all = gCH(false, false, false)
                if #all > 0 then return { "go_focus_ch" } end
            end
        else
            local pp = gPCH()
            if #pp > 0 then return { "go_purple" } end
        end
        return { "patrol_ring" }
    end

    if p_ == "НАБОР" then
        local tpBuild = gTPG_build()
        if tpBuild then return { "go_build_precision" } end
        local allCH = gCH(false, false, true)
        if #allCH > 0 then table.insert(ba, "go_crosshair") end
        
        if #fP > 0 then table.insert(ba, "go_petal") end
        if next(aT) ~= nil then
            table.insert(ba, "go_token_near")
            table.insert(ba, "go_token_best")
        end
        local dt, _ = gDTP()
        if dt then table.insert(ba, "go_dup_tp") end
        table.insert(ba, "patrol_ring")
        table.insert(ba, "patrol_random")
        return ba
    end

    return { "patrol_ring" }
end

local function cAB(s)
    local v = gAWB()
    if #v == 0 then return "patrol_ring" end
    if math.random() < EP then return v[math.random(1, #v)] end
    local bA = v[1]
    local bQ = gQ(s, v[1]) * getPatternBias(v[1])
    for i = 2, #v do
        local q = gQ(s, v[i]) * getPatternBias(v[i])
        if q > bQ then bA = v[i]; bQ = q end
    end
    return bA
end

local function dUQ(s, a, rw, ns)
    local rr = h()
    local rp = Vector3.zero
    if rr then rp = rr.Position end
    local tR = rw + gPB(a, rp)
    local v = gAWB()
    local mN = 0
    for i = 1, #v do
        local q = gQ(ns, v[i])
        if q > mN then mN = q end
    end
    local nw = gQ(s, a) + AL * (tR + GA * mN - gQ(s, a))
    sQ(s, a, nw)
    st.tR = st.tR + tR
    st.dc = st.dc + 1
    EP = math.max(0.02, EP * ED)
end

local function uVC()
    local r = h()
    if aB.SS.st > 0 then
        if not scVis then
            local ok, part = pcall(function()
                local p = Instance.new("Part")
                p.Name = "ScorchCenter"
                p.Shape = Enum.PartType.Cylinder
                p.Anchored = true
                p.CanCollide = false
                p.CanQuery = false
                p.Transparency = 0.55
                p.BrickColor = BrickColor.new("Bright orange")
                p.Size = Vector3.new(XCR * 3, 0.3, XCR * 3)
                p.Parent = Workspace
                return p
            end)
            if ok then scVis = part end
        end
        if scVis then
            local cc = gFC()
            scVis.CFrame = CFrame.new(cc.X, cc.Y + 0.15, cc.Z) * CFrame.Angles(0, 0, math.pi/2)
        end
    else
        if scVis then pcall(function() scVis:Destroy() end); scVis = nil end
    end

    if xfE then
        local cc = gFC()
        if cc == Vector3.zero and r then cc = r.Position end
        if not xfC then
            local ok, part = pcall(function()
                local p = Instance.new("Part")
                p.Name = "XFlameCircle"
                p.Shape = Enum.PartType.Cylinder
                p.Anchored = true
                p.CanCollide = false
                p.CanQuery = false
                p.Transparency = 0.5
                p.BrickColor = BrickColor.new("Really red")
                p.Size = Vector3.new(XCR * 2, 0.2, XCR * 2)
                p.Parent = Workspace
                return p
            end)
            if ok then xfC = part end
        end
        if xfC then xfC.CFrame = CFrame.new(cc.X, cc.Y + 0.1, cc.Z) * CFrame.Angles(0, 0, math.pi/2) end
    else
        if xfC then pcall(function() xfC:Destroy() end); xfC = nil end
    end

    if ENABLED and r then
        if not syVis then
            local ok, part = pcall(function()
                local p = Instance.new("Part")
                p.Name = "ScytheRadius"
                p.Shape = Enum.PartType.Cylinder
                p.Anchored = true
                p.CanCollide = false
                p.CanQuery = false
                p.Transparency = 0.55
                p.BrickColor = BrickColor.new("Cyan")
                p.Size = Vector3.new(SCYTHE_DIST * 2, 0.15, SCYTHE_DIST * 2)
                p.Parent = Workspace
                return p
            end)
            if ok then syVis = part end
        end
        if syVis then syVis.CFrame = CFrame.new(r.Position.X, r.Position.Y + 0.05, r.Position.Z) * CFrame.Angles(0, 0, math.pi/2) end
    else
        if syVis then pcall(function() syVis:Destroy() end); syVis = nil end
    end
end

local function gEP(tP)
    if not aR or not aR.Parent then return tP end
    local dir = (tP - aR.Position).Unit
    return cP(Vector3.new(aR.Position.X + dir.X * aRR, 0, aR.Position.Z + dir.Z * aRR))
end

local CHC = Color3.fromRGB(17, 134, 19)

local function iCH(p)
    if not p or p.Name ~= "Crosshair" then return false end
    local ok, c = pcall(function() return p.Color end)
    if not ok then return false end
    return math.abs(c.R - CHC.R) < 0.05 and math.abs(c.G - CHC.G) < 0.05 and math.abs(c.B - CHC.B) < 0.05
end

local function eA(action)
    local r = h()
    if not r then return -1 end
    recordScorchAction(action)

    if action == "go_duped_morph" then
        local n = tick()
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.dp and t.mo then
                local rem = t.l - (n - t.s)
                if rem < 4.0 and rem > 0 then
                    tL = "🐻 Морф (Дюп)"
                    INT = false
                    local ok = goTo(p.Position, 4, 3)
                    if ok and p.Parent then
                        local t0 = tick()
                        while tick() - t0 < 1.1 do
                            task.wait(0.05)
                            if not ENABLED or not p.Parent then break end
                            local hm_ = hm()
                            if hm_ then hm_:MoveTo(Vector3.new(p.Position.X, p.Position.Y, p.Position.Z)) end
                        end
                        t.col = true
                        return 25
                    end
                end
            end
        end
        return -2
    end

    if action == "go_duped_babylove" then
        local n = tick()
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.dp and t.id == 1472256444 then
                local rem = t.l - (n - t.s)
                if rem < 5.0 and rem > 0 then
                    tL = "👶 Baby Love (Дюп)"
                    INT = false
                    local ok = goTo(p.Position, 4, 3)
                    if ok and p.Parent then
                        local t0 = tick()
                        while tick() - t0 < 1.1 do
                            task.wait(0.05)
                            if not ENABLED or not p.Parent then break end
                            local hm_ = hm()
                            if hm_ then hm_:MoveTo(Vector3.new(p.Position.X, p.Position.Y, p.Position.Z)) end
                        end
                        t.col = true
                        return 25
                    end
                end
            end
        end
        return -2
    end

    if action == "go_duped_9plus" then
        local cc = gFC()
        local bestP = nil
        local bestD = math.huge
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.dp then
                if not t.mo and t.id ~= 2000457501 and t.id ~= 5877939956 and t.id ~= 107187190 and t.id ~= 1472256444 then
                    local d = d3(p.Position, cc)
                    if d < 40 and d < bestD then
                        bestD = d
                        bestP = p
                    end
                end
            end
        end
        if bestP then
            tL = "💎 Дюпы 9+"
            INT = false
            local ok = goTo(bestP.Position, 4, 3)
            if ok and bestP.Parent then
                local t0 = tick()
                while tick() - t0 < 0.5 do
                    task.wait(0.05)
                    if not ENABLED or not bestP.Parent then break end
                    local hm_ = hm()
                    if hm_ then hm_:MoveTo(Vector3.new(bestP.Position.X, bestP.Position.Y, bestP.Position.Z)) end
                end
                if aT[bestP] then aT[bestP].col = true end
                return 15
            end
        end
        return -2
    end

    if action == "go_duped_inspire_scorch" then
        local n = tick()
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.dp and t.id == 2000457501 then
                local age = n - t.s
                if age > 2.0 then
                    tL = "🔥 Инспаер (Скорч)"
                    INT = false
                    local ok = goTo(p.Position, 4, 3)
                    if ok and p.Parent then
                        local t0 = tick()
                        while tick() - t0 < 1.1 do
                            task.wait(0.05)
                            if not ENABLED or not p.Parent then break end
                            local hm_ = hm()
                            if hm_ then hm_:MoveTo(Vector3.new(p.Position.X, p.Position.Y, p.Position.Z)) end
                        end
                        t.col = true
                        return 35
                    end
                end
            end
        end
        return -2
    end

    if action == "go_duped_inspire_normal" then
        local n = tick()
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.dp and t.id == 2000457501 then
                local rem = t.l - (n - t.s)
                if rem < 2.0 and rem > 0 then
                    tL = "✨ Инспаер (Дюп)"
                    INT = false
                    local ok = goTo(p.Position, 4, 3)
                    if ok and p.Parent then
                        local t0 = tick()
                        while tick() - t0 < 1.1 do
                            task.wait(0.05)
                            if not ENABLED or not p.Parent then break end
                            local hm_ = hm()
                            if hm_ then hm_:MoveTo(Vector3.new(p.Position.X, p.Position.Y, p.Position.Z)) end
                        end
                        t.col = true
                        return 25
                    end
                end
            end
        end
        return -2
    end

    if action == "go_touch_flame" then
        local r_ = h()
        if not r_ then return -1 end
        local bestFl = nil
        local bestD = math.huge
        local n = tick()
        for fl, data in pairs(scytheParts) do
            if fl.Parent then
                local isDark = (fl.Name:find("Dark") or fl.BrickColor.Name == "Really black")
                if not isDark and (n - data.sT) > 2.0 then
                    local d = d3(r_.Position, fl.Position)
                    if d < bestD then bestD = d; bestFl = fl end
                end
            end
        end
        if bestFl then
            tL = "🔥 Поджечь флейм"
            INT = false
            local ok = goTo(bestFl.Position, 4, 3)
            if ok then return 10 end
        end
        return -2
    end

    if action == "go_coconut" then
        local n = tick()
        for i, coco in ipairs(activeCoconuts) do
            if not coco.collected and coco.part.Parent then
                local rem = 3.0 - (n - coco.spawnTime)
                if rem <= 1.0 and rem > 0.0 then
                    tL = "🥥 Кокос"
                    INT = false
                    local ok = goTo(coco.part.Position, 3, 2)
                    if ok and coco.part.Parent then
                        local t0 = tick()
                        while tick() - t0 < rem do
                            task.wait(0.05)
                            if not ENABLED or not coco.part.Parent then break end
                            local hm_ = hm()
                            if hm_ then hm_:MoveTo(Vector3.new(coco.part.Position.X, coco.part.Position.Y, coco.part.Position.Z)) end
                        end
                        coco.collected = true
                        return 30
                    end
                end
            end
        end
        return -2
    end

    if action == "go_build_precision" then
        local tp = gTPG_build()
        if not tp then return -1 end
        local g = tp[1]
        local rw = 0
        INT = false
        if g.pr.part.Parent and not g.pr.col then
            tL = "🟣 BUILD TP"
            local ok = goTo(g.pr.part.Position, 4, 5)
            if ok and g.pr.part.Parent then g.pr.col = true; lP = g.pr.part; st.pr = st.pr + 1; rw = rw + 30; task.wait(0.1) end
        end
        if g.r1.part.Parent and not g.r1.col then
            tL = "🎯 BUILD r1"
            local ok = goTo(g.r1.part.Position, 4, 4)
            if ok and g.r1.part.Parent then g.r1.col = true; st.ch = st.ch + 1; rw = rw + 10; task.wait(0.05) end
        end
        if g.r2.part.Parent and not g.r2.col then
            tL = "🎯 BUILD r2"
            local ok = goTo(g.r2.part.Position, 4, 4)
            if ok and g.r2.part.Parent then g.r2.col = true; st.ch = st.ch + 1; rw = rw + 10 end
        end
        if rw > 0 and aB.PoM.a and aB.PoM.pos then goTo(aB.PoM.pos, 6, 3) end
        if rw > 0 then return rw end
        return -2
    end

    if action == "go_focus_renew" then
        local all = gCH(false, false, false)
        if #all == 0 then return -1 end
        local t = all[1]
        tL = "🎯 Focus renew"
        INT = false
        local ok = goTo(t.part.Position, 4, 4)
        if ok and t.part.Parent then t.col = true; if t.isP then st.pr = st.pr + 1 else st.ch = st.ch + 1 end; return 15 end
        return -2
    end
    
    if action == "go_focus_ch" then
        local all = gCH(false, false, false)
        if #all == 0 then return -1 end
        local t = all[1]
        tL = "🎯 Фокус (6с)"
        INT = false
        local ok = goTo(t.part.Position, 4, 4)
        if ok and t.part.Parent then
            t.col = true
            st.ch = st.ch + 1
            lastFocusCHTime = tick()
            return 15
        end
        return -2
    end

    if action == "go_purple_rb_renew" then
        local pp = gPCH()
        if #pp == 0 then return -1 end
        local t = pp[1]
        tL = "🟣 RB renew"
        INT = false
        local ok = goTo(t.part.Position, 4, 4)
        if ok and t.part.Parent then t.col = true; st.pr = st.pr + 1; return 20 end
        return -2
    end

    if action == "go_skip_one_ch" then
        local all = gCH(false, false, false)
        if #all <= 1 then return -1 end
        tL = "Skip CH"
        INT = false
        return 5
    end

    if action == "go_multi_purple" then
        local pp = gPCH()
        if #pp < 2 then return -1 end
        local rw = 0
        INT = false
        local p1 = pp[1]
        tL = "Purpx2 #1"
        if p1.part.Parent and not p1.col then
            local ok = goTo(p1.part.Position, 4, 3)
            if ok and p1.part.Parent then p1.col = true; st.pr = st.pr + 1; rw = rw + 20 end
        end
        local p2 = pp[2]
        if p2.part.Parent and not p2.col then
            tL = "Purpx2 #2"
            local dist12 = d3(p1.part.Position, p2.part.Position)
            if dist12 > 30 then
                local ok = goTo(p2.part.Position, 4, 5)
                if ok and p2.part.Parent then
                    p2.col = true; st.pr = st.pr + 1
                    local wt = tick()
                    while tick() - wt < 1 do task.wait(0.05) end
                    rw = rw + 25
                end
            else
                local ok = goTo(p2.part.Position, 4, 3)
                if ok and p2.part.Parent then p2.col = true; st.pr = st.pr + 1; rw = rw + 20 end
            end
        end
        if rw > 0 then return rw end
        return -2
    end

    if action == "go_crosshair_all" then
        local all = gCH(false, false, true)
        if #all == 0 then return -1 end
        table.sort(all, function(a, b) return a.sT < b.sT end)
        local rw = 0
        INT = false
        for i = 1, #all do
            local ch = all[i]
            if ch.part.Parent and not ch.col then
                if ch.isP then
                    tL = "Purp Scorch"
                    local ok = goTo(ch.part.Position, 4, 3)
                    if ok and ch.part.Parent then ch.col = true; st.pr = st.pr + 1; rw = rw + 20 end
                else
                    tL = "CH Scorch"
                    local ok = goTo(ch.part.Position, 4, 3)
                    if ok and ch.part.Parent then ch.col = true; st.ch = st.ch + 1; rw = rw + 10 end
                end
            end
        end
        if rw > 0 then return rw end
        return -2
    end

    if action == "go_crosshair_refresh_all" then
        local all = gCH(false, false, true)
        if #all == 0 then return -1 end
        local col = 0
        INT = false
        for i = 1, #all do
            local ch = all[i]
            if ch.part.Parent and not ch.col then
                if col >= 3 then break end
                tL = "RFSH " .. (col + 1)
                local ok = goTo(ch.part.Position, 4, 4, true)
                if ok and ch.part.Parent then
                    ch.col = true; rCC = rCC + 1
                    if ch.isP then st.pr = st.pr + 1; lP = ch.part else st.ch = st.ch + 1 end
                    col = col + 1; task.wait(0.1)
                end
            end
        end
        if aR and aR.Parent then goTo(aR.Position, 6, 4) else goTo(cP(r.Position), 5, 2) end
        if rCC >= 3 then prec.nR = false; cyc.chC = 0; st.rf = st.rf + 1; rCC = 0; return 40 end
        if col > 0 then return col * 12 end
        return -2
    end

    if action == "go_target_practice_purple" then
        local tp = gTPG()
        if not tp then return -1 end
        local rw = 0
        INT = false
        for i = 1, #tp do
            local g = tp[i]
            if g.pr.part.Parent and not g.pr.col then
                tL = "TP purp"
                local ok = goTo(g.pr.part.Position, 4, 5)
                if ok and g.pr.part.Parent then
                    g.pr.col = true; g.r1.col = true; g.r2.col = true; lP = g.pr.part; st.pr = st.pr + 1
                    local t0 = tick()
                    while tick() - t0 < PST do task.wait(0.05); if smT or prec.nR or not ENABLED then break end end
                    rw = rw + 40
                end
            end
        end
        if rw > 0 then return rw end
        return -2
    end

    if action == "go_smile_area" then
        local t = gSDA()
        if not t then return -1 end
        local td = aT[t]
        if not td or td.col or td.id ~= SMI then return -1 end
        tL = "Smile(R)"
        INT = false
        local edge = gEP(t.Position)
        local ok = goTo(edge, 4, 4)
        if ok and t.Parent then 
            td.col = true; st.sm = st.sm + 1; 
            dupCnt = 0 
            return 45 
        end
        return -10
    end

    if action == "go_dup_area" then
        local t = gSDA()
        if not t then return -1 end
        local td = aT[t]
        if not td or td.col or td.id ~= TPI or not td.dp then return -1 end
        tL = "Dup(R)"
        INT = false
        local edge = gEP(t.Position)
        local ok = goTo(edge, 4, 4)
        if ok and t.Parent then td.col = true; st.tk = st.tk + 1; return 15 end
        return -2
    end

    if action == "go_smile" then
        local t = smT
        if not t or not t.Parent then smT = nil; return -1 end
        local td = aT[t]
        if not td or td.col then smT = nil; return -1 end
        isCS = true
        tL = "Smile"
        INT = false
        local ok = goTo(t.Position, 4, math.min(3, smTR - 0.3))
        if ok and t.Parent then
            if not td.dp then 
                td.col = true; smT = nil; st.sm = st.sm + 1; isCS = false; 
                dupCnt = 0 
                return 45 
            end
            local st_ = tick()
            while tick() - st_ < TSD do
                task.wait(0.1)
                if not t.Parent or not ENABLED then break end
                local hm_ = hm()
                if hm_ then hm_:MoveTo(Vector3.new(t.Position.X, t.Position.Y, t.Position.Z)) end
            end
            td.col = true; smT = nil; st.sm = st.sm + 1; isCS = false; 
            dupCnt = 0 
            return 45
        end
        isCS = false; smT = nil; return -10
    end

    if action == "go_urgent_token" then
        local n = tick()
        local be = nil
        local bl = 0.7
        for p, t in pairs(aT) do
            if not t.col and p.Parent then
                local rem = t.l - (n - t.s)
                if rem < bl and rem > 0 then bl = rem; be = p end
            end
        end
        if be then
            tL = "Urgent"
            INT = false
            local ok = goTo(be.Position, 4, 2)
            if ok and be.Parent then aT[be].col = true; st.tk = st.tk + 1; return 25 end
            return -2
        end
        return -1
    end

    if action == "go_purple" then
        local pp = gCH(true, false)
        if #pp == 0 then return -1 end
        local rw = 0
        INT = false
        for i = 1, #pp do
            local ch = pp[i]
            if ch.part.Parent and not ch.col and not smT then
                local ok = goTo(ch.part.Position, 5, 5)
                if ok and ch.part.Parent then
                    ch.col = true; lP = ch.part; st.pr = st.pr + 1
                    tL = "🟣 1с"
                    if prec.isX and not prec.nR then
                        local t0 = tick()
                        while tick() - t0 < 1.0 do
                            task.wait(0.05)
                            if smT or prec.nR or not ENABLED then break end
                            local hm_ = hm()
                            if hm_ then hm_:MoveTo(Vector3.new(ch.part.Position.X, ch.part.Position.Y, ch.part.Position.Z)) end
                        end
                    end
                    rw = rw + 20
                end
            end
        end
        if rw > 0 then return rw end
        return -2
    end

    if action == "go_tokenlink" then
        local cc = Vector3.zero
        if xfE then cc = gFC() end
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.p >= 90 then
                if xfE and cc ~= Vector3.zero then
                    if d3(p.Position, cc) <= XCR * 2 then
                        tL = "Link"
                        INT = false
                        local ok = goTo(p.Position, 5, 5)
                        if ok and p.Parent then t.col = true; igT = tick() + TLC; lastTokenLinkTime = tick(); return 50 end
                        return -5
                    end
                else
                    tL = "Link"
                    INT = false
                    local ok = goTo(p.Position, 5, 5)
                    if ok and p.Parent then t.col = true; igT = tick() + TLC; lastTokenLinkTime = tick(); return 50 end
                    return -5
                end
            end
        end
        return -2
    end

    if action == "go_crosshair" then
        local all = gCH(false, false, true) 
        if #all == 0 then return -1 end
        local t = all[1]
        local rw = 0
        INT = false
        if t.part.Parent and not t.col and not smT then
            local sk = false
            local r2 = h()
            if r2 then
                for p2, t2 in pairs(aT) do
                    if not t2.col and p2.Parent and t2.p >= 90 then
                        if d3(r2.Position, p2.Position) < TLID and d3(r2.Position, t.part.Position) > 30 then sk = true; break end
                    end
                end
            end
            if xfE and not sk then
                local cc = gFC()
                if cc ~= Vector3.zero and d3(t.part.Position, cc) > XCR * 1.5 then sk = true end
            end
            if not sk then
                local ok = goTo(t.part.Position, 4, 5)
                if ok and t.part.Parent then
                    t.col = true
                    if t.isP then 
                        st.pr = st.pr + 1; lP = t.part; rw = rw + (prec.nR and 5 or 10)
                    else 
                        st.ch = st.ch + 1; cyc.chC = cyc.chC + 1; 
                        if cyc.chC >= 3 then cyc.chC = 0 end; 
                        rw = rw + 8 
                    end
                end
            end
        end
        if rw > 0 and aB.PoM.a and aB.PoM.pos then goTo(aB.PoM.pos, 6, 4) end
        if rw > 0 then return rw end
        return -2
    end

    if action == "go_dup_tp" then
        local p, t = gDTP()
        if not p then return -1 end
        tL = "Dup"
        INT = false
        local ok = goTo(p.Position, 5, 5)
        if ok and p.Parent then t.col = true; return 15 end
        return -2
    end

    if action == "go_petal" then
        if #fP == 0 then return -1 end
        local ca = false
        local tr = 0
        local i = 1
        while i <= #fP do
            local pt = fP[i]
            if not pt.part.Parent then table.remove(fP, i)
            elseif stP[pt.part] and tick() < stP[pt.part] then table.remove(fP, i)
            else
                tL = "🌸 " .. pt.cn
                INT = false
                local ok = goTo(Vector3.new(pt.part.Position.X, 0, pt.part.Position.Z), PCD, 2.5)
                if ok then st.pt = st.pt + 1; tr = tr + 8 + (14 - pt.pr); ca = true; task.wait(0.05); i = i + 1
                else stP[pt.part] = tick() + 5; table.remove(fP, i) end
            end
        end
        if ca then return tr end
        return -1
    end

    if action == "go_token_near" then
        local be = nil
        local bD = math.huge
        for p, t in pairs(aT) do
            if not t.col and p.Parent then
                local d = d3(r.Position, p.Position)
                if d < bD then be = p; bD = d end
            end
        end
        if be then
            local t = aT[be]
            tL = "💎 " .. t.n
            INT = false
            local ok = goTo(be.Position, 5, 5)
            if ok and be.Parent then t.col = true; return 3 + t.p * 0.2 end
            return -2
        end
        return -1
    end

    if action == "go_token_best" then
        local be = nil
        local bP = -1
        local n = tick()
        for p, t in pairs(aT) do
            if not t.col and p.Parent and (t.l - (n - t.s)) > 0.5 and t.p > bP then be = p; bP = t.p end
        end
        if be then
            local t = aT[be]
            tL = "💎⭐ " .. t.n
            INT = false
            local ok = goTo(be.Position, 5, 5)
            if ok and be.Parent then t.col = true; return 5 + t.p * 0.3 end
            return -3
        end
        return -1
    end

    if action == "patrol_ring" then
        local function rR()
            if isSuperScorch then
                local cx, cz, count = 0, 0, 0
                for fl, _ in pairs(scytheParts) do
                    if fl.Parent then
                        cx = cx + fl.Position.X
                        cz = cz + fl.Position.Z
                        count = count + 1
                    end
                end
                if count > 0 then
                    cx = cx / count
                    cz = cz / count
                    local a_ = math.random() * 2 * math.pi
                    local rr_ = math.random() * 10
                    return cP(Vector3.new(cx + math.cos(a_) * rr_, 0, cz + math.sin(a_) * rr_))
                end
            end
            if xfE then
                local cc = gFC()
                if cc ~= Vector3.zero then
                    local a_ = math.random() * 2 * math.pi
                    local rr_ = math.random() * XCR * 0.25
                    return cP(Vector3.new(cc.X + math.cos(a_) * rr_, 0, cc.Z + math.sin(a_) * rr_), true)
                end
            end
            if aR and aR.Parent and curF then
                local a_ = math.random() * 2 * math.pi
                local rr_ = aRR * (0.5 + math.random() * 0.8)
                return cP(Vector3.new(aR.Position.X + math.cos(a_) * rr_, 0, aR.Position.Z + math.sin(a_) * rr_))
            end
            if curF then
                local c = curF.part.Position
                local s = curF.part.Size
                return cP(Vector3.new(c.X + (math.random() * 2 - 1) * math.max(s.X / 2 * 0.3, 5), 0, c.Z + (math.random() * 2 - 1) * math.max(s.Z / 2 * 0.3, 5)))
            end
            local rp = h()
            if rp then return cP(rp.Position + Vector3.new((math.random() * 2 - 1) * 30, 0, (math.random() * 2 - 1) * 30)) end
            return cP(Vector3.zero)
        end
        tL = xfE and "XF Ring" or "Ring"
        INT = false
        local t = rR()
        if t == Vector3.zero or (not xfE and not iF(t)) then t = gFC() end
        if t == Vector3.zero then return 0 end
        goTo(t, xfE and 2 or 6, PT)
        task.wait(0.1 + math.random() * 0.3)
        return 0
    end

    if action == "patrol_random" then
        local function rF()
            if curF then
                local c = curF.part.Position
                local s = curF.part.Size
                return cP(Vector3.new(c.X + (math.random() * 2 - 1) * math.max(s.X / 2 - 3, 1), 0, c.Z + (math.random() * 2 - 1) * math.max(s.Z / 2 - 3, 1)))
            end
            local rp = h()
            if rp then return cP(rp.Position + Vector3.new((math.random() * 2 - 1) * 30, 0, (math.random() * 2 - 1) * 30)) end
            return cP(Vector3.zero)
        end
        tL = "Rand"
        INT = false
        local t = rF()
        if t == Vector3.zero or not iF(t) then t = gFC() end
        if t == Vector3.zero then return 0 end
        goTo(t, 4, PT)
        task.wait(0.2 + math.random() * 0.4)
        return 0
    end

    if action == "go_xflame_center" then
        local c = gFC()
        if c == Vector3.zero then return -1 end
        tL = "XF центр"
        INT = false
        goTo(c, 3, 3)
        return 0
    end

    if action == "go_xflame_ch" then
        local ch = gCH_nearest_center()
        if not ch then return -1 end
        tL = "XF CH"
        INT = false
        local ok = goTo(ch.part.Position, 2, 3)
        if ok and ch.part.Parent then ch.col = true; st.ch = st.ch + 1; return 5 end
        return -1
    end

    return 0
end

local mLS = false
local function sML()
    if mLS then return end
    mLS = true
    task.wait(2)
    scriptStartHoney = getCoreHoney()
    scriptStartTime = tick()
    lQ()
    fAR()
    fF()
    logOk("BSS AI v15.7 ready! " .. fmtHoney(scriptStartHoney))
    print("✅ v15.7")
    tL = "иниц"
    lMT = tick()
end

task.spawn(function()
    pcall(function()
        if not readfile then return end
        local ok, raw = pcall(readfile, pF)
        if ok and raw then
            local ok2, data = pcall(Http.JSONDecode, Http, raw)
            if ok2 and type(data) == "table" then
                if data.scorchSessions then scorchSessions = data.scorchSessions end
                if data.bestScorch then bestScorchHoney = data.bestScorch end
            end
        end
    end)
    logOk("Загр: " .. #scorchSessions)
end)

task.spawn(function()
    while true do
        task.wait(30)
        pcall(function()
            local lt = Workspace:FindFirstChild("Lighting")
            if lt then lt.GlobalShadows = false; lt.Brightness = 2 end
        end)
    end
end)

if _G.BSSAI_HB then pcall(function() _G.BSSAI_HB:Disconnect() end) end
_G.BSSAI_HB = RunService.Heartbeat:Connect(function()
    hbF = hbF + 1
    if not ENABLED then return end
    if not mLS then sML(); return end
    local n = tick()
    fAR()
    pcall(tryHitScythe)
    if hbF % 18 == 0 then sBf(); sPr() end
    if hbF % 9 == 0 then
        sPt()
        scanScythes()
        local h = hm()
        if h then
            local ts = gAS()
            if math.abs(h.WalkSpeed - ts) > 0.5 then h.WalkSpeed = ts end
        end
    end
    if hbF % 6 == 0 then pcall(uHB) end
    if hbF % 3 == 0 then sSm() end
    if hbF % 180 == 0 then fF() end
    if hbF % 60 == 0 then clnCH() end
    if hbF % 30 == 0 then saveScorchSessions() end
    if hbF % 18000 == 0 then
        task.spawn(function()
            local qc = 0
            for _ in pairs(QT) do qc = qc + 1 end
            if writefile then
                pcall(function()
                    writefile("bss_ai_q_v15.json", Http:JSONEncode({
                        version = Q_VERSION, qtable = QT,
                        scorchSessions = scorchSessions, bestScorch = bestScorchHoney,
                        top10 = top10patterns, meta = { sc = qc, sa = os.time() }
                    }))
                end)
            end
        end)
    end
    xfE = (aB.XF.st >= 19)
    if xfE then 
        INT = true 
        if not fixedXFlameCenter then
            local targetFlower = Workspace.Flowers:FindFirstChild("FP18-10-13")
            if targetFlower then
                fixedXFlameCenter = targetFlower.Position
            end
        end
    else
        fixedXFlameCenter = nil
    end
    uVC()
    local r = h()
    if r then
        local vel = r.AssemblyLinearVelocity
        local hS = (Vector3.new(vel.X, 0, vel.Z)).Magnitude
        if hS > 0.2 then lMT = n; stW = false
        elseif n - lMT > 5 and not stW then
            stW = true; INT = true; tL = "сброс"
            if lP and not lP.Parent then lP = nil end
            if smT and not smT.Parent then smT = nil; isCS = false end
            INT = false; lMT = n
        end
    end
    if INT and not smT and not prec.nR and not xfE then INT = false end
    if prec.isX and not prec.nR and r then
        for i = 1, #cQ do
            local ch = cQ[i]
            if ch.part and ch.part.Parent and not ch.col and not ch.isP and iCH(ch.part) and n - lPT > 1.5 then
                lPT = n
                local s_ = eS()
                if s_ and s_ ~= "dead" then pcall(dUQ, s_, "patrol_ring", -20, s_) end
                st.chA = st.chA + 1
                break
            end
        end
    end
    if isA then return end
    if hbF % 2 == 0 then
        isA = true
        local s_ = eS()
        local a_ = cAB(s_)
        local ok, rw = pcall(eA, a_)
        if not ok then rw = -1; logErr(a_ .. " fail: " .. tostring(rw)) end
        local ns = eS()
        pcall(dUQ, s_, a_, rw, ns)
        isA = false
    end
end)

function lQ()
    if not readfile then return end
    local ok, raw = pcall(readfile, "bss_ai_q_v15.json")
    if ok and raw then
        local ok2, d = pcall(Http.JSONDecode, Http, raw)
        if ok2 and type(d) == "table" and d.version == Q_VERSION and type(d.qtable) == "table" then
            QT = d.qtable
            if d.scorchSessions then scorchSessions = d.scorchSessions end
            if d.bestScorch then bestScorchHoney = d.bestScorch end
            if d.top10 then top10patterns = d.top10 end
        end
    end
end

local function rQ()
    QT = {}
    EP = 0.1
    st.tR = 0
    st.dc = 0
    scorchSessions = {}
    bestScorchHoney = 0
    top10patterns = {}
    if writefile then
        pcall(function()
            writefile("bss_ai_q_v15.json", Http:JSONEncode({
                version = Q_VERSION, qtable = {},
                scorchSessions = {}, bestScorch = 0, top10 = {},
                meta = { ra = os.time() }
            }))
        end)
    end
end

local sg = Instance.new("ScreenGui", PGui)
sg.Name = "BSSAI_GUI"
local fr = Instance.new("Frame", sg)
fr.Size = UDim2.new(0, 270, 0, 165)
fr.Position = UDim2.new(0, 10, 0, 10)
fr.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
fr.BackgroundTransparency = 0.15
fr.BorderSizePixel = 0
fr.Active = true
fr.Draggable = true
Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

local ti_gui = Instance.new("TextLabel", fr)
ti_gui.Size = UDim2.new(1, 0, 0, 18)
ti_gui.Position = UDim2.new(0, 0, 0, 2)
ti_gui.BackgroundTransparency = 1
ti_gui.Text = "BSS AI v15.7"
ti_gui.TextColor3 = Color3.fromRGB(100, 200, 255)
ti_gui.Font = Enum.Font.GothamBold
ti_gui.TextSize = 12
ti_gui.TextXAlignment = Enum.TextXAlignment.Center

local lb = Instance.new("TextLabel", fr)
lb.Size = UDim2.new(1, 0, 0, 14)
lb.Position = UDim2.new(0, 0, 0, 20)
lb.BackgroundTransparency = 1
lb.Text = "Действие: старт"
lb.TextColor3 = Color3.fromRGB(255, 255, 255)
lb.Font = Enum.Font.Gotham
lb.TextSize = 10
lb.TextXAlignment = Enum.TextXAlignment.Center

local hl = Instance.new("TextLabel", fr)
hl.Size = UDim2.new(1, 0, 0, 14)
hl.Position = UDim2.new(0, 0, 0, 34)
hl.BackgroundTransparency = 1
hl.Text = "HPH: --/час"
hl.TextColor3 = Color3.fromRGB(150, 255, 150)
hl.Font = Enum.Font.Gotham
hl.TextSize = 10
hl.TextXAlignment = Enum.TextXAlignment.Center

local sl = Instance.new("TextLabel", fr)
sl.Size = UDim2.new(1, 0, 0, 14)
sl.Position = UDim2.new(0, 0, 0, 48)
sl.BackgroundTransparency = 1
sl.Text = "S: --"
sl.TextColor3 = Color3.fromRGB(255, 200, 100)
sl.Font = Enum.Font.Gotham
sl.TextSize = 10
sl.TextXAlignment = Enum.TextXAlignment.Center

local pl_ = Instance.new("TextLabel", fr)
pl_.Size = UDim2.new(1, 0, 0, 14)
pl_.Position = UDim2.new(0, 0, 0, 62)
pl_.BackgroundTransparency = 1
pl_.Text = "Φ: --"
pl_.TextColor3 = Color3.fromRGB(180, 180, 255)
pl_.Font = Enum.Font.Gotham
pl_.TextSize = 10
pl_.TextXAlignment = Enum.TextXAlignment.Center

local bf = Instance.new("TextLabel", fr)
bf.Size = UDim2.new(1, 0, 0, 14)
bf.Position = UDim2.new(0, 0, 0, 76)
bf.BackgroundTransparency = 1
bf.Text = "FC:-- RB:-- PM:--"
bf.TextColor3 = Color3.fromRGB(255, 180, 100)
bf.Font = Enum.Font.Gotham
bf.TextSize = 9
bf.TextXAlignment = Enum.TextXAlignment.Center

local sh = Instance.new("TextLabel", fr)
sh.Size = UDim2.new(1, 0, 0, 14)
sh.Position = UDim2.new(0, 0, 0, 90)
sh.BackgroundTransparency = 1
sh.Text = "🔥 --"
sh.TextColor3 = Color3.fromRGB(255, 140, 80)
sh.Font = Enum.Font.Gotham
sh.TextSize = 9
sh.TextXAlignment = Enum.TextXAlignment.Center

local stopBtn = Instance.new("TextButton", fr)
stopBtn.Size = UDim2.new(1, -8, 0, 24)
stopBtn.Position = UDim2.new(0, 4, 0, 108)
stopBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
stopBtn.BorderSizePixel = 0
stopBtn.Text = "STOP"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 12
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 4)

stopBtn.MouseButton1Click:Connect(function()
    ENABLED = not ENABLED
    if ENABLED then stopBtn.Text = "STOP"; stopBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    else stopBtn.Text = "RESUME"; stopBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40) end
end)

task.spawn(function()
    while true do
        task.wait(0.3)
        lb.Text = tL
        local curH = getCoreHoney()
        local elapsedH = (tick() - scriptStartTime) / 3600
        local hph = 0
        if elapsedH > 0 then hph = (curH - scriptStartHoney) / elapsedH end
        hl.Text = "HPH: " .. fmtHoney(hph) .. "/час | " .. fmtHoney(curH)
        sl.Text = "S: " .. string.format("%.0f", cS)
        local superTag = ""
        if isSuperScorch then superTag = "🔥 " end
        pl_.Text = superTag .. ph() .. " CH:" .. #cQ .. " Tk:" .. st.tk .. " Pr:" .. st.pr .. " Sm:" .. st.sm
        local fcLabel = "x" .. aB.FC.combo
        if aB.FC.combo >= 10 then fcLabel = "x10" end
        local rbLabel = "x" .. aB.RB.combo
        if aB.RB.combo >= 10 then rbLabel = "x10" end
        bf.Text = "FC:" .. fcLabel .. " " .. string.format("%.0f", aB.FC.tL) .. "с RB:" .. rbLabel .. " " .. string.format("%.0f", aB.RB.tL) .. "с PM:" .. aB.PoM.m .. " dup:" .. dupCnt
        if scorchActive and scorchStartTime > 0 then
            local se = (tick() - scorchStartTime) / 60
            sh.Text = "🔥 " .. fmtHoney(curH - scorchStartHoney) .. " " .. string.format("%.1f", se) .. "мин | " .. fmtHoney(bestScorchHoney)
        else
            sh.Text = "🔥 " .. #scorchSessions .. " скорчей | Топ10:" .. #top10patterns .. " | " .. fmtHoney(bestScorchHoney)
        end
    end
end)

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.T then
        ENABLED = not ENABLED
        if ENABLED then stopBtn.Text = "STOP"; stopBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        else stopBtn.Text = "RESUME"; stopBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40) end
    elseif i.KeyCode == Enum.KeyCode.G then rQ()
    elseif i.KeyCode == Enum.KeyCode.P then
        local c = 0
        for _ in pairs(QT) do c = c + 1 end
        print("v15.7 Φ:" .. ph() .. " eps:" .. string.format("%.3f", EP) .. " R:" .. st.tR .. " S:" .. c .. " FC:" .. aB.FC.combo .. " RB:" .. aB.RB.combo .. " PM:" .. aB.PoM.m .. " Honey:" .. fmtHoney(getCoreHoney()) .. " Sc:" .. #scorchSessions)
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(2)
    aT = {}
    cQ = {}
    lP = nil
    curF = nil
    tL = "старт"
    smT = nil
    isCS = false
    INT = false
    cyc = { chC = 0 }
    fP = {}
    igT = 0
    rCC = 0
    dupCnt = 0
    focusRenew = false
    rbSkip = false
    isSuperScorch = false
    scorchActive = false
    scorchRecording = false
    scorchActions = {}
    scorchStartHoney = 0
    scorchStartTime = 0
    fixedXFlameCenter = nil
    lastTokenLinkTime = 0
    lastFocusCHTime = 0
    if xfC then xfC:Destroy(); xfC = nil end
    if scVis then scVis:Destroy(); scVis = nil end
    if syVis then syVis:Destroy(); syVis = nil end
    task.spawn(function()
        if writefile then
            local qc = 0
            for _ in pairs(QT) do qc = qc + 1 end
            pcall(function()
                writefile("bss_ai_q_v15.json", Http:JSONEncode({
                    version = Q_VERSION, qtable = QT,
                    scorchSessions = scorchSessions, bestScorch = bestScorchHoney,
                    top10 = top10patterns, meta = { sc = qc, sa = os.time() }
                }))
            end)
        end
    end)
end)

print("✅ v15.7 ready")
