-- BSS AI v16.5 — MERGED (v15.7 movement + v16.3 timers + Active Super Scorch)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local VIM = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")
local Q_VERSION = "16.5"
local ENABLED = true

-- ================= НАСТРОЙКИ =================
local ENABLE_ANTI_LAG = true
local SHOW_VISUALS = true
-- =============================================

if not math.round then math.round = function(n) return math.floor(n + 0.5) end end

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
        ti.Text = "⚠ BSS AI v16.5"
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
        elbl.Text = "⏳ v16.5 boot..."
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
        ebtn.Text = "📋 Copy logs"
        ebtn.TextColor3 = Color3.fromRGB(220, 220, 220)
        ebtn.Font = Enum.Font.Gotham
        ebtn.TextSize = 11
        Instance.new("UICorner", ebtn).CornerRadius = UDim.new(0, 4)
        local cb = Instance.new("TextButton", bg)
        cb.Size = UDim2.new(0, 80, 0, 28)
        cb.Position = UDim2.new(0, 156, 0, 180)
        cb.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        cb.BorderSizePixel = 0
        cb.Text = "✕ Close"
        cb.TextColor3 = Color3.fromRGB(220, 220, 220)
        cb.Font = Enum.Font.Gotham
        cb.TextSize = 11
        Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 4)
        cb.MouseButton1Click:Connect(function()
            egui.Enabled = false; egui:Destroy(); egui = nil
        end)
        ebtn.MouseButton1Click:Connect(function()
            local txt = table.concat(elog, "\n")
            if #txt == 0 then txt = "No errors" end
            pcall(setclipboard, txt)
            ebtn.Text = "✅ Done"; task.wait(1.5)
            ebtn.Text = "📋 Copy logs"
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
            table.insert(L, elog[i]); i = i + 1
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
SB["НАБОР"] = 70; SB["X10"] = 90; SB["REFRESH"] = 75
local SJ = 3
local AM = 1.2; local DGL = 22; local FM = 3; local AD = 5; local MT = 6
local PBI = 2574507284; local PLMBI = 2577647417
local PPK = 0.02; local PMX = 10; local PRAT = 25
local PURP = Color3.fromRGB(119, 85, 255); local PTOL = 12; local PST = 1
local SMI = 5877939956; local TSD = 1.1
local CAR = 28; local CAS = 20; local CAD = 0.1; local ARR = 20
local TLID = 20; local PCD = 8; local PFM = 20; local TPI = 8173559749
local TLC = 2; local PT = 8; local XCR = 15; local PCHR = 10
local SCYTHE_DIST = 14; local SCYTHE_CD = 0.4
local AL = 0.5; local GA = 0.95; local EP = 0.3; local ED = 0.9995
local PMBI = 2577647416; local FOCI = 2577384907; local RBOI = 2577383393
local FOCUS_RENEW = 10; local RB_RENEW = 7; local RB_SCORCH_RENEW = 9
local SCORCH_BIAS = 1.15; local PAT_WINDOW = 2400; local PAT_TOP = 10
local scriptStartHoney = 0; local scriptStartTime = 0
local scorchStartHoney = 0; local scorchStartTime = 0
local pollenMarkStacks = 0

-- ===== ALL TOKEN DEFINITIONS (timers for every type) =====
local TKS = {}
-- battle=true: haste, focus, rage, token link, baby love, melody, inferno, flame fuel, target practice, all morphs, glitch/smile
TKS[1629547638] = { n = "Token Link", base = 4, p = 99, prefix = "TL ", normalColor = Color3.new(0,0,0), bgColor = Color3.new(1,1,1), battle = true }
TKS[8173559749] = { n = "TP", base = 8, p = 95, prefix = "TP ", normalColor = Color3.new(0.7, 0.2, 0.9), dupedColor = Color3.new(0.5, 0.1, 0.7), bgColor = Color3.new(0,0,0), battle = true }
TKS[2000457501] = { n = "Inspire", base = 8, p = 25, prefix = "IN ", normalColor = Color3.new(1, 1, 0), dupedColor = Color3.new(1, 0.84, 0), bgColor = Color3.new(0,0,0) }
TKS[1472256444] = { n = "Baby Love", base = 8, p = 22, prefix = "BL ", normalColor = Color3.new(1, 0.7, 0.8), dupedColor = Color3.new(0.8, 0.5, 0.6), bgColor = Color3.new(0,0,0), battle = true }
TKS[1629649299] = { n = "Focus", base = 4, p = 15, prefix = "FC ", normalColor = Color3.new(0.3, 0.6, 1), bgColor = Color3.new(0,0,0), battle = true }
TKS[65867881] = { n = "Haste", base = 4, p = 15, prefix = "HS ", normalColor = Color3.new(0.2, 1, 0.2), bgColor = Color3.new(0,0,0), battle = true }
TKS[1442863423] = { n = "Blue Boost", base = 4, p = 12, prefix = "BB ", normalColor = Color3.new(0.2, 0.4, 1), bgColor = Color3.new(0,0,0) }
TKS[1442859163] = { n = "Red Boost", base = 4, p = 12, prefix = "RB ", normalColor = Color3.new(1, 0.2, 0.2), bgColor = Color3.new(0,0,0) }
TKS[3877732821] = { n = "White Boost", base = 4, p = 12, prefix = "WB ", normalColor = Color3.new(1, 1, 1), bgColor = Color3.new(0,0,0) }
TKS[1442764904] = { n = "Red Bomb+", base = 4, p = 12, prefix = "RB+ ", normalColor = Color3.new(1, 0.3, 0.1), bgColor = Color3.new(0,0,0) }
TKS[1442700745] = { n = "Rage", base = 8, p = 10, prefix = "RG ", normalColor = Color3.new(1, 0.1, 0.1), bgColor = Color3.new(0,0,0), battle = true }
TKS[253828517] = { n = "Melody", base = 8, p = 10, prefix = "ML ", normalColor = Color3.new(1, 0.5, 1), bgColor = Color3.new(0,0,0), battle = true }
TKS[2499514197] = { n = "Honey Mark", base = 8, p = 9, prefix = "HM ", normalColor = Color3.new(1, 0.8, 0.2), bgColor = Color3.new(0,0,0) }
TKS[2499540966] = { n = "Pollen Mark", base = 8, p = 9, prefix = "PM ", normalColor = Color3.new(1, 0.9, 0.4), bgColor = Color3.new(0,0,0) }
TKS[1472532912] = { n = "Polar Bear", base = 15, p = 8, mo = true, prefix = "MO ", normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), battle = true }
TKS[1472491940] = { n = "Black Bear", base = 15, p = 8, mo = true, prefix = "MO ", normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), battle = true }
TKS[1472425802] = { n = "Brown Bear", base = 15, p = 8, mo = true, prefix = "MO ", normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), battle = true }
TKS[2032949183] = { n = "Mother Bear", base = 15, p = 8, mo = true, prefix = "MO ", normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), battle = true }
TKS[1472580249] = { n = "Panda", base = 15, p = 8, mo = true, prefix = "MO ", normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), battle = true }
TKS[1489734171] = { n = "Science Bear", base = 15, p = 8, mo = true, prefix = "MO ", normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), battle = true }
TKS[1874564120] = { n = "Pulse", base = 12, p = 7, prefix = "PL ", normalColor = Color3.new(0.2, 1, 1), bgColor = Color3.new(0,0,0) }
TKS[4528379338] = { n = "Mark Surge", base = 4, p = 7, prefix = "MS ", normalColor = Color3.new(0.8, 0.5, 1), bgColor = Color3.new(0,0,0) }
TKS[3582501342] = { n = "Rain Call", base = 24, p = 6, prefix = "RC ", normalColor = Color3.new(0.3, 0.5, 1), bgColor = Color3.new(0,0,0) }
TKS[3582519526] = { n = "Tornado", base = 24, p = 6, prefix = "TN ", normalColor = Color3.new(0.5, 0.5, 0.5), bgColor = Color3.new(0,0,0) }
TKS[5877998606] = { n = "Mind Hack", base = 16, p = 6, prefix = "MH ", normalColor = Color3.new(0.8, 0.2, 0.8), bgColor = Color3.new(0,0,0) }
TKS[8083943936] = { n = "Surprise Party", base = 24, p = 6, prefix = "SP ", normalColor = Color3.new(1, 0.8, 0.2), bgColor = Color3.new(0,0,0) }
TKS[177997841] = { n = "Glob", base = 4, p = 6, prefix = "GB ", normalColor = Color3.new(0.2, 0.8, 1), bgColor = Color3.new(0,0,0) }
TKS[1839454544] = { n = "Gummy Storm", base = 4, p = 6, prefix = "GS ", normalColor = Color3.new(0.2, 1, 0.5), bgColor = Color3.new(0,0,0) }
TKS[1442725244] = { n = "Bomb", base = 4, p = 5, prefix = "BM ", normalColor = Color3.new(0.5, 0.5, 0.5), bgColor = Color3.new(0,0,0) }
TKS[5877939956] = { n = "Glitch", base = 4, p = 5, prefix = "SM ", normalColor = Color3.new(1,1,1), dupedColor = Color3.new(1,1,1), bgColor = Color3.new(0,0,0), battle = true }
TKS[4519549299] = { n = "Inferno", base = 4, p = 5, prefix = "IF ", normalColor = Color3.new(1, 0.4, 0.1), bgColor = Color3.new(0,0,0), battle = true }
TKS[4519523935] = { n = "Triangulate", base = 4, p = 5, prefix = "TR ", normalColor = Color3.new(0.2, 0.8, 0.3), bgColor = Color3.new(0,0,0) }
TKS[4528414666] = { n = "Summon Frog", base = 8, p = 5, prefix = "SF ", normalColor = Color3.new(0.2, 1, 0.2), bgColor = Color3.new(0,0,0) }
TKS[4528208186] = { n = "Flame Fuel", base = 8, p = 5, prefix = "FF ", normalColor = Color3.new(1, 0.5, 0.1), bgColor = Color3.new(0,0,0), battle = true }
TKS[1671281844] = { n = "Beamstorm", base = 12, p = 4, prefix = "BS ", normalColor = Color3.new(0.9, 0.9, 0.2), bgColor = Color3.new(0,0,0) }
TKS[8083436978] = { n = "Blue Balloon", base = 4, p = 4, prefix = "BBL ", normalColor = Color3.new(0.3, 0.5, 1), bgColor = Color3.new(0,0,0) }
TKS[1104415222] = { n = "BondToken", base = 4, p = 4, prefix = "BT ", normalColor = Color3.new(1, 0.8, 0.5), bgColor = Color3.new(0,0,0) }
TKS[2319100769] = { n = "Fetch", base = 8, p = 4, prefix = "FT ", normalColor = Color3.new(0.7, 0.5, 0.3), bgColor = Color3.new(0,0,0) }
TKS[4889322534] = { n = "Fuzz Bombs", base = 4, p = 4, prefix = "FB ", normalColor = Color3.new(0.9, 0.7, 0.2), bgColor = Color3.new(0,0,0) }
TKS[2319083910] = { n = "Impale", base = 24, p = 4, prefix = "IP ", normalColor = Color3.new(0.6, 0.3, 0.1), bgColor = Color3.new(0,0,0) }
TKS[3080529618] = { n = "Jelly Bean", base = 4, p = 4, prefix = "JB ", normalColor = Color3.new(1, 0.5, 0.8), bgColor = Color3.new(0,0,0) }
TKS[4889470194] = { n = "Pollen Haze", base = 4, p = 4, prefix = "PH ", normalColor = Color3.new(0.9, 0.9, 0.5), bgColor = Color3.new(0,0,0) }
TKS[107187190] = { n = "Honey Gift", base = 4, p = 2, prefix = "HG ", normalColor = Color3.new(1, 0.8, 0.3), bgColor = Color3.new(0,0,0) }
TKS[183390139] = { n = "Cog", base = 4, p = 2, prefix = "CG ", normalColor = Color3.new(0.6, 0.6, 0.6), bgColor = Color3.new(0,0,0) }

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

local aT = {}; local cQ = {}; local lP = nil; local curF = nil; local tL = "старт"

local prec = { st = 0, val = 0, isX = false, ls = 0, sD = 60, sS = 0, tL = 0, nR = false }
local st = { tk = 0, ch = 0, pr = 0, x10 = 0, rf = 0, tR = 0, dc = 0, sm = 0, chA = 0, pt = 0, chP = 0 }
local cyc = { chC = 0 }

local INT = false; local isCS = false; local smT = nil; local smTR = 0; local igT = 0
local fP = {}; local aR = nil; local aRR = ARR

local aB = {}
aB.SS = { st = 0 }; aB.XF = { st = 0 }; aB.PM = { a = false }
aB.PoM = { a = false, pos = nil, m = 0 }  -- Precision of Marks combo
aB.FC = { combo = 0, dur = 20, tL = 0 }; aB.RB = { combo = 0, dur = 15, tL = 0 }
aB.PollM = { combo = 0, active = false, ringPos = nil }  -- Pollen Mark x3

local stP = setmetatable({}, { __mode = "k" })
local rCC = 0; local rST = 0
local hB = {}; local pH = {}; local bAH = 0; local laT = 0
local pF = "bss_ai_pat_v15.json"
local QT = {}; local lMT = tick(); local stW = false
local xfE = false; local xfC = nil; local lPT = 0
local qTables = {}; local pHTables = {}; local fldHash = nil; local dupCnt = 0
-- ===== ADVANCED Q-LEARNING =====
local eligibility = {}     -- { state = { action = trace } }  TD-lambda traces
local visitCount = {}      -- { state = { action = count } }   UCB visit counters
local totalSteps = 0       -- total action steps for UCB
local TD_LAMBDA = 0.7      -- trace decay
local UCB_C = 1.5          -- exploration constant
local lastActionTime = 0   -- time-penalty tracking
local flamesHitThisStep = 0
local chDetourThisStep = 0
local abortedThisStep = false
local cS = SB["НАБОР"]; local hbF = 0; local isA = false
-- focusRenew/rbSkip removed
local scorchActive = false; local scorchRecording = false
local scorchActions = {}; local scorchSessions = {}; local top10patterns = {}
local bestScorchHoney = 0; local lastPatternSave = 0
local scytheParts = setmetatable({}, { __mode = "k" })
local lastScytheHit = 0; local scVis = nil; local syVis = nil
local fixedXFlameCenter = nil
local lastTokenLinkTime = 0; local lastFocusCHTime = 0
local goSmileGuard = false  -- restricts sticky detours during go_smile
local activeCoconuts = {}; local activeShowers = {}
local activeTokenGuis = {}; local activeBlooms = {}
-- ===== X-Flame & Scorch progress tracking =====
local xfProgress = 0      -- from PlayerAbilityEvent
local scorchProgress = 0  -- from PlayerAbilityEvent
local lastBloomHit = 0
-- ===== Bloom petal buff tracking =====
local redPetalTimer = 0   -- tick() when last red petal collected (8s buff)
-- ===== Session statistics =====
local stChMin = 0; local stTkMin = 0; local stFlMin = 0; local stBloomMin = 0

-- ===== TIMER CREATION FOR ALL TOKENS =====
local function createTimer(part, id, totalLifetime, duped, def)
    if activeTokenGuis[part] then return end
    local gui = Instance.new("BillboardGui")
    gui.Adornee = part
    gui.Size = UDim2.new(0, 80, 0, 24)
    gui.StudsOffset = Vector3.new(0, 2, 0)
    gui.AlwaysOnTop = true
    gui.Parent = part
    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 0.2
    label.BackgroundColor3 = def.bgColor or Color3.new(0,0,0)
    local tc = duped and (def.dupedColor or def.normalColor or Color3.new(1,1,1)) or (def.normalColor or Color3.new(1,1,1))
    label.TextColor3 = tc
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    local prefix = def.prefix or ""
    label.Text = prefix .. string.format("%.1f", totalLifetime)
    activeTokenGuis[part] = {
        gui = gui, label = label, startTime = tick(),
        totalLifetime = totalLifetime, prefix = prefix
    }
end

local function applyAntiLag()
    if not ENABLE_ANTI_LAG then return end
    task.spawn(function()
        local targets = {
            "Flowers", "Bees", "Kukurudza_dontreal", "FieldDecos",
            "Collectibles", "NPCs", "OnettNPC", "Noob Bear", "Top Bear", "Pro Bear"
        }
        for _, name in pairs(targets) do
            local f = Workspace:FindFirstChild(name)
            if f then
                local desc = f:GetDescendants()
                for i = 1, #desc do
                    local obj = desc[i]
                    if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                        obj.Transparency = 1; obj.CastShadow = false
                        obj.Material = Enum.Material.SmoothPlastic
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        obj:Destroy()
                    end
                    if i % 100 == 0 then task.wait() end
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
    local dx = a.X - b.X; local dz = a.Z - b.Z
    return math.sqrt(dx * dx + dz * dz)
end

local function d3d(a, b) return (a - b).Magnitude end

local function d2Sq(a, b)
    local dx = a.X - b.X; local dz = a.Z - b.Z
    return dx * dx + dz * dz
end

local function gQ(s, a)
    if not QT[s] then QT[s] = {} end
    return QT[s][a] or 0
end

local function sQ(s, a, v)
    if not QT[s] then QT[s] = {} end
    QT[s][a] = v
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
    -- X-Flame bracket: 0-9, 10-17, 18-21, 22-25 (near trigger)
    local xfBracket = 0
    if xfProgress >= 22 then xfBracket = 3
    elseif xfProgress >= 18 then xfBracket = 2
    elseif xfProgress >= 10 then xfBracket = 1
    end
    return string.format("%s|PM%d|PLL%d|XF%d", ph(), math.min(3, aB.PoM.m), math.min(1, pollenMarkStacks >= 3 and 1 or 0), xfBracket)
end

local function fldHashFn()
    if not curF or not curF.part then return "unknown" end
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
        local be, bd = nil, math.huge
        local children = z:GetChildren()
        for ci = 1, #children do
            local zn = children[ci]
            if zn:IsA("BasePart") then
                local d = d3(mp, zn.Position)
                if math.abs(mp.X - zn.Position.X) <= zn.Size.X / 2 + 20 then
                    if math.abs(mp.Z - zn.Position.Z) <= zn.Size.Z / 2 + 20 then
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
        for _, f_ in ipairs(fl:GetChildren()) do
            if f_:IsA("BasePart") then table.insert(fp, f_.Position) end
        end
        if #fp > 0 then
            local mnX, mxX, mnZ, mxZ = math.huge, -math.huge, math.huge, -math.huge
            for _, p in ipairs(fp) do
                if p.X < mnX then mnX = p.X end; if p.X > mxX then mxX = p.X end
                if p.Z < mnZ then mnZ = p.Z end; if p.Z > mxZ then mxZ = p.Z end
            end
            curF = { part = { Position = Vector3.new((mnX + mxX) / 2, mp.Y, (mnZ + mxZ) / 2), Size = Vector3.new(math.abs(mxX - mnX) + 10, 1, math.abs(mxZ - mnZ) + 10) } }
            swFld(); return curF
        end
    end
    if aR then curF = { part = { Position = aR.Position, Size = Vector3.new(aRR * 3, 1, aRR * 3) } }; swFld(); return curF end
    return curF
end

local function gFC()
    if xfE and fixedXFlameCenter then return fixedXFlameCenter end
    if curF and curF.part then return curF.part.Position end
    local r = h()
    return r and r.Position or Vector3.zero
end

local function gAS()
    local p = ph()
    local b = SB[p] or SB["НАБОР"]
    -- Active Super Scorch: keep speed, don't slow down
    if hbF % 30 == 0 then
        local base = b + (math.random() * 2 - 1) * SJ
        if math.abs(base - cS) > 1 then cS = base end
    end
    return cS
end

local function cP(pos, sk)
    if sk then return pos end
    if not curF then return pos end
    local c = curF.part.Position; local s = curF.part.Size
    local mx = math.max(s.X / 2 - FM, 1); local mz = math.max(s.Z / 2 - FM, 1)
    local cl = Vector3.new(math.clamp(pos.X, c.X - mx, c.X + mx), pos.Y, math.clamp(pos.Z, c.Z - mz, c.Z + mz))
    if aB.XF.st >= 19 then
        local dx = cl.X - c.X; local dz = cl.Z - c.Z
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
    local c = curF.part.Position; local s = curF.part.Size
    return math.abs(pos.X - c.X) <= s.X / 2 + PFM and math.abs(pos.Z - c.Z) <= s.Z / 2 + PFM
end

local function gEP(tP)
    if not aR or not aR.Parent then return tP end
    local dir = (tP - aR.Position).Unit
    return cP(Vector3.new(aR.Position.X + dir.X * aRR, 0, aR.Position.Z + dir.Z * aRR))
end

Workspace.DescendantAdded:Connect(function(o)
    if o.Name == "AreaRing" and o:IsA("BasePart") then
        aR = o; aRR = (o.Size.X + o.Size.Z) / 4
        if aRR < 5 then aRR = ARR end
    end
end)

local function fAR()
    local p = Workspace:FindFirstChild("Particles")
    if p then
        for _, o in ipairs(p:GetChildren()) do
            if o.Name == "AreaRing" and o:IsA("BasePart") then
                aR = o; aRR = (o.Size.X + o.Size.Z) / 4
                if aRR < 5 then aRR = ARR end; return
            end
        end
    end
    aR = Workspace:FindFirstChild("AreaRing")
    if aR and aR:IsA("BasePart") then
        aRR = (aR.Size.X + aR.Size.Z) / 4
        if aRR < 5 then aRR = ARR end
    else aR = nil; aRR = ARR end
end

local Pt = Workspace:FindFirstChild("Particles")
if not Pt then Pt = workspace:WaitForChild("Particles", 10) end

local function iCl(a, b, tl)
    tl = tl or PTOL
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
    for i = 1, #cQ do if cQ[i].part == o then return end end
    task.spawn(function()
        task.wait(0.06)
        if not o.Parent then return end
        table.insert(cQ, { part = o, sT = tick(), col = false, isP = iP(o) })
    end)
end

-- Bloom tracking
local poppable = Workspace:FindFirstChild("Happenings") and Workspace.Happenings:FindFirstChild("PoppablePlants")
if poppable then
    for _, b in ipairs(poppable:GetChildren()) do
        if b.Name == "Bloom" then activeBlooms[b] = true end
    end
    poppable.ChildAdded:Connect(function(b)
        if b.Name == "Bloom" then activeBlooms[b] = true end
    end)
    poppable.ChildRemoved:Connect(function(b)
        if activeBlooms[b] then activeBlooms[b] = nil end
    end)
end

if Pt then
    Pt.DescendantAdded:Connect(function(o)
        aCH(o)
        if o.Name == "WarningDisk" and o:IsA("BasePart") then
            local sx = o.Size.X
            if math.abs(sx - 23.4) < 2 then
                table.insert(activeCoconuts, { part = o, spawnTime = tick(), collected = false })
            elseif math.abs(sx - 8.0) < 1 then
                table.insert(activeShowers, { part = o, spawnTime = tick(), collected = false })
            end
        end
    end)
    Pt.DescendantRemoving:Connect(function(o)
        for i = #cQ, 1, -1 do if cQ[i].part == o then table.remove(cQ, i); break end end
        if lP == o then lP = nil end
        for i = #activeCoconuts, 1, -1 do if activeCoconuts[i].part == o then table.remove(activeCoconuts, i); break end end
        for i = #activeShowers, 1, -1 do if activeShowers[i].part == o then table.remove(activeShowers, i); break end end
    end)
    for _, o in ipairs(Pt:GetDescendants()) do aCH(o) end
end

local function clnCH()
    for i = #cQ, 1, -1 do
        local ch = cQ[i]
        if not ch.part or not ch.part.Parent or ch.col then table.remove(cQ, i) end
    end
end

local function gCH(onlyPurple, onlyReg, purpFirst)
    local L, P = {}, {}
    for i = #cQ, 1, -1 do
        local ch = cQ[i]
        local alive = false
        pcall(function() if ch.part and ch.part.Parent then alive = true end end)
        if not alive then table.remove(cQ, i)
        elseif not ch.col then
            if (onlyPurple and ch.isP) or (onlyReg and not ch.isP) or (not onlyPurple and not onlyReg) then
                if purpFirst and ch.isP then table.insert(P, ch) else table.insert(L, ch) end
            end
        end
    end
    table.sort(L, function(a, b) return a.sT < b.sT end)
    table.sort(P, function(a, b) return a.sT < b.sT end)
    if purpFirst then
        local result = {}
        for _, ch in ipairs(P) do table.insert(result, ch) end
        for _, ch in ipairs(L) do table.insert(result, ch) end
        return result
    end
    return L
end

local function gPCH() return gCH(true, false, false) end

local function gTPG_build()
    local all = gCH(false, false, false)
    if #all < 3 then return nil end
    local G = {}
    for i = 1, #all do
        local c = all[i]
        if c.isP then
            local closest = {}
            for j = 1, #all do
                if not all[j].isP and i ~= j then
                    local dist = d3(c.part.Position, all[j].part.Position)
                    if dist < 25 then table.insert(closest, {ch = all[j], d = dist}) end
                end
            end
            table.sort(closest, function(a, b) return a.d < b.d end)
            if #closest >= 2 then
                table.insert(G, { pr = c, r1 = closest[1].ch, r2 = closest[2].ch })
            end
        end
    end
    return #G > 0 and G or nil
end

local function gTPG()
    if not prec.isX or prec.nR then return nil end
    return gTPG_build()
end

local function gCH_nearest_center()
    local cc = gFC()
    if cc == Vector3.zero then return nil end
    local best, bestD = nil, math.huge
    for i = 1, #cQ do
        local ch = cQ[i]
        if not ch.col and ch.part.Parent then
            local d = d3(ch.part.Position, cc)
            if d < bestD then bestD = d; best = ch end
        end
    end
    return best
end

local function gCH_nearest()
    local r = h()
    if not r then return nil end
    local best, bestD = nil, math.huge
    for i = 1, #cQ do
        local ch = cQ[i]
        if not ch.col and ch.part.Parent then
            local d = d3(r.Position, ch.part.Position)
            if d < bestD then bestD = d; best = ch end
        end
    end
    return best
end

local cATCache = {}; local cATFrame = 0

local function gRCT(mP, dP)
    if not prec.isX or prec.nR then return {} end
    if cATFrame == hbF and cATCache[mP] then return cATCache[mP] end
    local mf = Vector3.new(mP.X, 0, mP.Z)
    local df = Vector3.new(dP.X, 0, dP.Z)
    local tt = df - mf
    if tt.Magnitude < 1 then return {} end
    local tD = tt.Unit; local th = {}
    for i = 1, #cQ do
        local ch = cQ[i]
        if not ch.col and ch.part.Parent and not ch.isP then
            local cf = Vector3.new(ch.part.Position.X, 0, ch.part.Position.Z)
            local toCh = cf - mf; local d = toCh.Magnitude
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
    cATFrame = hbF; cATCache = {}; cATCache[mP] = th
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
    local bp = p2:Dot(tD) >= p1:Dot(tD) and p2 or p1
    st.chA = st.chA + 1
    return cP(Vector3.new(t.pos.X + bp.X * CAS, mP.Y, t.pos.Z + bp.Z * CAS))
end

local function tryRedirectToCH(origTarget)
    local r = h()
    if not r then return false end
    local onlyPurple = (prec.isX and not prec.nR)
    local best, bestD = nil, math.huge
    for i = 1, #cQ do
        local ch = cQ[i]
        if not ch.col and ch.part.Parent then
            if not (onlyPurple and not ch.isP) then
                local d = d3(r.Position, ch.part.Position)
                if d <= PCHR and d < bestD then bestD = d; best = ch end
            end
        end
    end
    if not best then return false end
    if origTarget and best.part == origTarget then return false end
    local hm_ = hm()
    if not hm_ then return false end
    hm_:MoveTo(best.part.Position)
    local t0 = tick()
    while tick() - t0 < 0.6 do
        task.wait(0.03)
        local r2 = h()
        if not r2 then break end
        if not best.part.Parent then best.col = true; break end
        if d3(r2.Position, best.part.Position) <= 4 then
            best.col = true; st.chP = st.chP + 1
            if best.isP then st.pr = st.pr + 1; lP = best.part else st.ch = st.ch + 1 end
            return true
        end
    end
    if best.part.Parent then best.col = true; st.chP = st.chP + 1
        if best.isP then st.pr = st.pr + 1 else st.ch = st.ch + 1 end
    end
    return true
end

-- ===== BLOOM SCYTHE INTEGRATION =====
local function hitNearbyBloom()
    local r = h()
    if not r then return end
    local n = tick()
    if n - lastBloomHit < SCYTHE_CD then return end
    local isScorchActive = (aB.SS.st > 0)
    local bestBloom, bestPetals = nil, math.huge
    for bloom in pairs(activeBlooms) do
        if bloom.Parent then
            local dist = d3(r.Position, bloom.Position)
            if dist <= SCYTHE_DIST then
                -- Count petals
                local petalCount = 0
                for _, p in ipairs(bloom:GetChildren()) do
                    if p.Name == "Petal" then petalCount = petalCount + 1 end
                end
                -- Count nearby flames for scorch-aware decision
                local flamesNearby = 0
                if isScorchActive then
                    for fl in pairs(scytheParts) do
                        if fl and fl.Parent and d3(bloom.Position, fl.Position) < 15 then
                            flamesNearby = flamesNearby + 1
                        end
                    end
                end
                -- During scorch: only hit bloom if ≤3 flames nearby
                local eligible = isScorchActive and (flamesNearby <= 3) or (not isScorchActive)
                if eligible and petalCount < bestPetals then
                    bestPetals = petalCount
                    bestBloom = bloom
                end
            end
        else
            activeBlooms[bloom] = nil
        end
    end
    if not bestBloom then return end
    lastBloomHit = n
    local bg = r:FindFirstChild("AI_BG_Bloom")
    if not bg then
        bg = Instance.new("BodyGyro"); bg.Name = "AI_BG_Bloom"
        bg.MaxTorque = Vector3.new(0, 40000, 0); bg.P = 10000; bg.D = 500
        bg.Parent = r
    end
    local dir = bestBloom.Position - r.Position
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude > 0.1 then bg.CFrame = CFrame.lookAt(r.Position, r.Position + dir) end
    local ev = RS:FindFirstChild("Events")
    local tce = ev and ev:FindFirstChild("ToolCollect")
    if tce then pcall(function() tce:FireServer() end) end
    task.spawn(function()
        task.wait(0.15)
        if bg then bg:Destroy() end
    end)
end

-- ===== FLAME CLUSTER PATH WEAVING =====
-- Scans flames near the movement corridor and returns a nudge position
-- to steer the player through the densest flame cluster along the way.
local function computeFlameStrafe(mP, dP)
    local mf = Vector3.new(mP.X, 0, mP.Z)
    local df = Vector3.new(dP.X, 0, dP.Z)
    local tt = df - mf
    if tt.Magnitude < 1 then return nil end
    local tD = tt.Unit
    local bestCluster = nil
    local bestScore = -1
    local n = tick()
    -- Group flames into clusters (simple: find flame with most neighbors)
    local flameList = {}
    for fl, data in pairs(scytheParts) do
        if fl and fl.Parent and data then
            local nm = fl.Name or ""
            local bcName = safeBrickColorName(fl)
            local isDark = (nm:find("Dark") or bcName == "Really black")
            local cd = flameCooldowns[fl]
            if not isDark and (not cd or n >= cd) and (n - data.sT) >= 6.0 then
                table.insert(flameList, { part = fl, sT = data.sT })
            end
        end
    end
    if #flameList == 0 then return nil end
    -- For each flame, check if near the path corridor
    for _, fe in ipairs(flameList) do
        local fl = fe.part
        if fl and fl.Parent then
            local fp = Vector3.new(fl.Position.X, 0, fl.Position.Z)
            local toFl = fp - mf
            local alongDist = toFl:Dot(tD)
            if alongDist > 0 and alongDist < 40 then
                local crossDist = math.abs(toFl.X * tD.Z - toFl.Z * tD.X)
                if crossDist < 10 then
                    local neighbors = 0
                    for _, fe2 in ipairs(flameList) do
                        if fe2.part ~= fl and fe2.part and fe2.part.Parent then
                            if d3(fl.Position, fe2.part.Position) < 8 then
                                neighbors = neighbors + 1
                            end
                        end
                    end
                    local age = n - fe.sT
                    local remLife = math.max(0, 7.0 - age)
                    local ageScore = math.min(1.0, remLife / 2.0)
                    local score = (1 + neighbors) * (1 - crossDist / 10) * (0.5 + ageScore * 0.5)
                    if score > bestScore then
                        bestScore = score
                        local nudgeDist = math.min(6, crossDist * 0.7 + 2)
                        local sign = (toFl.X * tD.Z - toFl.Z * tD.X) > 0 and 1 or -1
                        local perpX = -tD.Z * sign
                        local perpZ = tD.X * sign
                        bestCluster = {
                            pos = Vector3.new(
                                mP.X + tD.X * alongDist + perpX * nudgeDist,
                                mP.Y,
                                mP.Z + tD.Z * alongDist + perpZ * nudgeDist
                            ),
                            score = score
                        }
                    end
                end
            end
        end
    end
    return bestCluster
end

-- ===== HIT NON-DARK FLAMES WHILE MOVING (superficial) =====
-- ===== FLAME COOLDOWN TRACKING =====
local flameCooldowns = setmetatable({}, { __mode = "k" })

-- SAFE helper: get BrickColor.Name without crashing on GC'd objects
local function safeBrickColorName(obj)
    if not obj then return "" end
    local ok, bc = pcall(function() return obj.BrickColor end)
    if ok and bc then
        local ok2, nm = pcall(function() return bc.Name end)
        if ok2 and nm then return nm end
    end
    return ""
end

local function hitNearbyFlames()
    local r = h()
    if not r then return end
    local n = tick()
    if n - lastScytheHit < SCYTHE_CD then return end
    for fl, data in pairs(scytheParts) do
        if fl and fl.Parent then
            local nm = fl.Name or ""
            local bcName = safeBrickColorName(fl)
            local isDark = (nm:find("Dark") or bcName == "Really black")
            local cd = flameCooldowns[fl]
            if not isDark and (not cd or n >= cd) then
                local dist = d3(r.Position, fl.Position)
                if dist <= SCYTHE_DIST * 2 and data and (n - data.sT) >= 6.0 then
                    lastScytheHit = n
                    flameCooldowns[fl] = n + 5.0
                    flamesHitThisStep = flamesHitThisStep + 1
                    stFlMin = stFlMin + 1
                    local bg = r:FindFirstChild("AI_BG_Scythe")
                    if not bg then
                        bg = Instance.new("BodyGyro"); bg.Name = "AI_BG_Scythe"
                        bg.MaxTorque = Vector3.new(0, 40000, 0); bg.P = 10000; bg.D = 500
                        bg.Parent = r
                    end
                    local dir = fl.Position - r.Position
                    dir = Vector3.new(dir.X, 0, dir.Z)
                    if dir.Magnitude > 0.1 then bg.CFrame = CFrame.lookAt(r.Position, r.Position + dir) end
                    -- Fire tool collect immediately (no wait), then clean up in background
                    local ev = RS:FindFirstChild("Events")
                    local tce = ev and ev:FindFirstChild("ToolCollect")
                    if tce then pcall(function() tce:FireServer() end)
                    else
                        pcall(function()
                            local cam = workspace.CurrentCamera; local vp = cam.ViewportSize
                            VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 1)
                            VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 1)
                        end)
                    end
                    -- Background cleanup: remove BodyGyro after short delay
                    task.spawn(function()
                        task.wait(0.15)
                        if bg then bg:Destroy() end
                    end)
                    break
                end
            end
        else
            scytheParts[fl] = nil
            flameCooldowns[fl] = nil
        end
    end
end

local function goTo(tP, rad, to, sk)
    rad = rad or AD; to = to or MT
    if to > 12 then to = 12 end
    if tP == Vector3.zero then return false end
    local r = h(); local hm_ = hm()
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
    local t0 = tick(); local lM = tick(); local lA = tick(); local lPC = tick()
    local stickyUsedThisGo = false
    local abortTimer = tick(); local abortLastPos = r.Position
    while tick() - t0 < to do
        task.wait(0.04)
        if not ENABLED or INT then return false end
        r = h()
        if not r then return false end
        -- Superficial: hit nearby blooms (scorch-aware) + flames while moving
        pcall(hitNearbyBloom)
        local hasFlameNearby = false
        for fl, data in pairs(scytheParts) do
            if fl and fl.Parent and d3(r.Position, fl.Position) <= SCYTHE_DIST * 2 then
                hasFlameNearby = true; break
            end
        end
        if hasFlameNearby then pcall(hitNearbyFlames) end
        -- Superficial: collect nearby petals while moving
        if #fP > 0 then
            for i = 1, #fP do
                local pt = fP[i]
                if pt.part and pt.part.Parent and d3(r.Position, pt.part.Position) < 6 then
                    if not stP[pt.part] or tick() >= stP[pt.part] then
                        st.pt = st.pt + 1; stP[pt.part] = tick() + 5
                    end
                end
            end
        end
        -- Sticky-token: whitelist (BL, Inspire, Morphs, TL non-duped), max 1 per goTo, go_smile guard
        if hbF % 3 == 0 and not stickyUsedThisGo then
            local nSticky = tick()
            local bestSticky, bestScore = nil, -1
            for p, t in pairs(aT) do
                if not t.col and p.Parent then
                    local def = TKS[t.id]
                    local whitelisted = false
                    if def then
                        if t.id == 1472256444 or t.id == 2000457501 or def.mo
                           or (t.id == 1629547638 and not t.dp) then
                            whitelisted = true
                        end
                    end
                    if whitelisted then
                        local rem = t.l - (nSticky - t.s)
                        -- Adaptive radius: tighter during X10 to avoid wasting Precision time
                        local baseDist = prec.isX and 8 or 14
                        local maxDist = (goSmileGuard and smTR < 3.0) and 4 or baseDist
                        if rem > 0 and rem < 3.0 and d3(r.Position, p.Position) < maxDist then
                            local score = t.p * (1 - rem / t.l)
                            if score > bestScore then bestScore = score; bestSticky = p end
                        end
                    end
                end
            end
            if bestSticky and not INT then
                stickyUsedThisGo = true
                local detourPos = bestSticky.Position
                local hmDetour = hm()
                if hmDetour then hmDetour:MoveTo(Vector3.new(detourPos.X, r.Position.Y, detourPos.Z)) end
                local tDetour = tick()
                while tick() - tDetour < 0.8 do
                    task.wait(0.04)
                    if INT then break end
                    local rDetour = h()
                    if not rDetour then break end
                    if d3(rDetour.Position, detourPos) < 5 then
                        if aT[bestSticky] then aT[bestSticky].col = true; st.tk = st.tk + 1 end
                        chDetourThisStep = chDetourThisStep + 1
                        break
                    end
                end
                hm_ = hm()
                if hm_ then hm_:MoveTo(cM) end
            end
        end

        -- goTo abort: if stuck (distance reduced < 2 studs in 4s) -> abort
        if tick() - abortTimer > 4.0 then
            if d3(r.Position, abortLastPos) < 2 then
                abortedThisStep = true
                return false
            end
            abortTimer = tick()
            abortLastPos = r.Position
        end

        if d3(r.Position, oT) <= rad then return true end
        if tick() - lA >= 0.15 then
            lA = tick()
            local na = cAT(r.Position, oT)
            cM = na and Vector3.new(na.X, r.Position.Y, na.Z) or oT
            -- Flame cluster weaving: nudge cM toward densest flame cluster along path
            local strafe = computeFlameStrafe(r.Position, cM)
            if strafe then
                cM = Vector3.new(
                    cM.X + (strafe.pos.X - cM.X) * 0.4,
                    cM.Y,
                    cM.Z + (strafe.pos.Z - cM.Z) * 0.4
                )
            end
        end
        if cM ~= oT and d3(r.Position, cM) <= 4 then
            local na = cAT(r.Position, oT)
            cM = na and Vector3.new(na.X, r.Position.Y, na.Z) or oT
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
            if hm_ then hm_:MoveTo(cM) end; lM = tick()
        end
    end
    return false
end

-- ===== TOKEN REGISTRATION WITH TIMERS FOR ALL =====
local function rT(o)
    if o.Name ~= "C" or not o:IsA("BasePart") or aT[o] or tick() < igT then return end
    local fr = o:FindFirstChild("FrontDecal")
    if not fr or not fr:IsA("Decal") then return end
    local id = ti(fr.Texture)
    if not id or AV[id] then return end
    local df = TKS[id]
    if not df then return end
    -- Always use Map.Ground for duped detection (player may be on elevated terrain)
    local map = Workspace:FindFirstChild("Map")
    local ground = map and map:FindFirstChild("Ground")
    local dp = false
    if ground then
        dp = (o.Position.Y - ground.Position.Y) > 5
    else
        local r = h()
        if r then dp = (o.Position.Y - r.Position.Y) > 5 end
    end
    local lf = df.base * AM
    if dp then
        lf = lf * (2 + 0.05 * (DGL - 1))
        dupCnt = dupCnt + 1
    end
    aT[o] = { id = id, n = df.n, p = df.p, mo = df.mo or false, s = tick(), l = lf, dp = dp, col = false }
    -- Create timer for ALL tokens (not just select ones)
    if dp and id == 1629547638 then return end
    createTimer(o, id, lf, dp, df)
end

Workspace.DescendantAdded:Connect(function(o)
    if o.Name == "C" then pcall(rT, o) end
end)

do
    for _, o in ipairs(Workspace:GetDescendants()) do pcall(rT, o) end
end

game.DescendantRemoving:Connect(function(o)
    if aT[o] then
        if aT[o].col then st.tk = st.tk + 1 end
        if aT[o].dp then dupCnt = math.max(0, dupCnt - 1) end
        aT[o] = nil
    end
    if activeTokenGuis[o] then
        pcall(function() if activeTokenGuis[o].gui then activeTokenGuis[o].gui:Destroy() end end)
        activeTokenGuis[o] = nil
    end
    -- Clean up flame cooldowns when flame part is removed
    if scytheParts[o] then scytheParts[o] = nil; flameCooldowns[o] = nil end
end)

-- ===== BATTLE TOKEN FIELD COUNTER (for X-Flame prediction) =====
local function countBattleTokensNear(pos, radius)
    local count = 0
    for part, t in pairs(aT) do
        if not t.col and part.Parent then
            if d3(part.Position, pos) <= radius then
                local def = TKS[t.id]
                if def and def.battle then count = count + 1 end
            end
        end
    end
    return count
end

RunService.Heartbeat:Connect(function()
    local now = tick()
    for part, data in pairs(activeTokenGuis) do
        if part and part.Parent and data and data.label then
            local remaining = data.totalLifetime - (now - data.startTime)
            if remaining > 0 then
                data.label.Text = data.prefix .. string.format("%.1f", remaining)
                if remaining < 3.0 then data.label.TextColor3 = Color3.new(1, 0.3, 0.3) end
            elseif remaining <= 0 then
                data.label.Text = data.prefix .. "0.0"
            end
        else
            pcall(function() if data and data.gui then data.gui:Destroy() end end)
            activeTokenGuis[part] = nil
        end
    end
end)

local rps = nil
local PlayerAbilityEvent = nil
do
    local e = RS:FindFirstChild("Events")
    if e then
        rps = e:FindFirstChild("RetrievePlayerStats")
        PlayerAbilityEvent = e:FindFirstChild("PlayerAbilityEvent")
    end
end

-- ===== PLAYER ABILITY EVENT (X-Flame + Scorch progress) =====
if PlayerAbilityEvent then
    PlayerAbilityEvent.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        for tag, info in pairs(data) do
            if type(tag) == "string" and type(info) == "table" and info.Action == "Update" then
                local stacks = info.Values and info.Values[1]
                if stacks then
                    local lower = tag:lower()
                    if lower:find("flame") then
                        xfProgress = stacks
                    elseif lower:find("scorching") then
                        scorchProgress = stacks
                    end
                end
            end
        end
    end)
end

local function flatBuffs(t, d)
    if type(t) ~= "table" then return end
    local bid = rawget(t, "BuffID")
    if bid then d[bid] = t end
    local src = rawget(t, "Src")
    if src then d[src] = t end
    for _, val in pairs(t) do
        if type(val) == "table" then flatBuffs(val, d) end
    end
end

-- ===== UNIFIED BUFF POLLING (one InvokeServer call, handles all buffs + precision) =====
local function pollAllBuffs()
    if not rps then return end
    local ok, res = pcall(rps.InvokeServer, rps)
    if not ok or type(res) ~= "table" then return end
    local fd = {}
    flatBuffs(res, fd)

    -- === Scorching Star ===
    local prevSS = aB.SS.st
    local ss = fd["Scorching Star Aura"]
    if ss and rawget(ss, "Removed") ~= true then
        aB.SS.st = tonumber(rawget(ss, "Combo") or 0) or 0
    else
        aB.SS.st = 0
        -- Reset scorchProgress when Scorching Star aura disappears
        if scorchProgress > 0 then scorchProgress = 0 end
    end

    -- === X-Flame ===
    local xf = fd["X-Flame Aura"]
    if xf and rawget(xf, "Removed") ~= true then
        aB.XF.st = tonumber(rawget(xf, "Combo") or 0) or 0
    else
        aB.XF.st = 0
        -- Reset xfProgress when X-Flame aura disappears (after use / expires)
        if xfProgress > 0 then xfProgress = 0 end
    end

    -- === Pollen Mark (basic) ===
    aB.PM.a = (fd[2575093099] and rawget(fd[2575093099], "Removed") ~= true)

    -- === Precision of Marks (PoM) ===
    local pm = fd[PMBI]
    if pm and rawget(pm, "Removed") ~= true then
        aB.PoM.a = true
        aB.PoM.m = tonumber(rawget(pm, "Combo") or 0) or 1
        if aR then aB.PoM.pos = aR.Position end
    else aB.PoM.a = false; aB.PoM.m = 0 end

    -- === Precision (X10 tracking) ===
    -- Precision stores Value as fraction: 0.02=1stack, 0.04=2... 0.20=X10
    local b = fd[PBI] or fd["Precision"]  -- try BuffID first, then Src name
    if b and rawget(b, "Removed") ~= true then
        local rawVal = rawget(b, "Value")
        prec.val = tonumber(rawVal or 0) or 0
        -- Stacks = Value / 0.02 (e.g. 0.14 / 0.02 = 7)
        local newSt = 0
        if prec.val > 0 then
            newSt = math.min(PMX, math.round(prec.val / PPK))
        end
        prec.isX = (newSt >= PMX)
        local bDur = tonumber(rawget(b, "Dur") or 60) or 60
        prec.sD = bDur
        -- Reset timer on stack increase OR new Precision session (Refresh extends Start time)
        local bStart = tonumber(rawget(b, "Start"))
        if newSt ~= prec.st or (bStart and bStart ~= prec.sS) then
            prec.st = newSt
            prec.ls = os.clock()
            if bStart then prec.sS = bStart end
            if prec.isX then prec.nR = false; rCC = 0 end
        end
    else
        prec.st = 0; prec.val = 0; prec.isX = false
        prec.ls = 0; prec.tL = 0; prec.nR = false
    end

    -- === Pollen Mark x3 ===
    local plm = fd[PLMBI]
    if plm and rawget(plm, "Removed") ~= true then
        pollenMarkStacks = tonumber(rawget(plm, "Combo") or rawget(plm, "Value") or 0) or 0
        aB.PollM.combo = pollenMarkStacks
        aB.PollM.active = (aB.PollM.combo >= 3)
        if aB.PollM.active and aR then aB.PollM.ringPos = aR.Position end
    else
        pollenMarkStacks = 0; aB.PollM.active = false; aB.PollM.combo = 0
    end

    -- === Precision timer ===
    if prec.ls > 0 then
        prec.tL = math.max(0, prec.sD - (os.clock() - prec.ls))
        prec.nR = prec.isX and (prec.tL <= PRAT)
        if prec.nR and rCC == 0 then rST = tick(); rCC = 0 end
    end

    -- === Scorch start/end detection ===
    local curH = getCoreHoney()
    if aB.SS.st > 0 and prevSS == 0 then
        scorchStartHoney = curH; scorchStartTime = tick()
        scorchActive = true; scorchRecording = true; scorchActions = {}
    elseif aB.SS.st == 0 and prevSS > 0 then
        scorchActive = false
        if scorchRecording and scorchStartTime > 0 then
            local gained = curH - scorchStartHoney
            local dur = (tick() - scorchStartTime) / 60
            if gained > 0 then
                table.insert(scorchSessions, {
                    honeyGained = gained, durationMin = math.floor(dur * 10) / 10,
                    time = tick(), ssCombo = prevSS, ctx = getCtxKey(), actions = scorchActions
                })
                if gained > bestScorchHoney then bestScorchHoney = gained end
            end
            scorchRecording = false; scorchActions = {}
        end
    end
end

local function gPC(p)
    for nxt, co in pairs(PC) do
        local dr, dg, db = co.R - p.Color.R, co.G - p.Color.G, co.B - p.Color.B
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
    for _, o in ipairs(pt:GetChildren()) do
        if o.Name == "PetalPart" and o:IsA("BasePart") and iF(o.Position) then
            local cn = gPC(o)
            if cn and PP[cn] then
                table.insert(fP, { part = o, cn = cn, pr = PP[cn], dist = d3d(r.Position, o.Position) })
            end
        end
    end
    -- Bloom petal buff: red petal buff lasts 8s, with <4s remaining prioritize red
    if redPetalTimer > 0 then
        local rem = 8.0 - (tick() - redPetalTimer)
        if rem > 0 and rem < 4.0 then
            -- Prioritize red petals above all others
            for _, fp in ipairs(fP) do
                if fp.cn == "Red" then fp.pr = 0 end -- force top priority
            end
        elseif rem <= 0 then
            redPetalTimer = 0 -- buff expired
        end
    end
    table.sort(fP, function(a, b)
        if a.pr ~= b.pr then return a.pr < b.pr end
        return a.dist < b.dist
    end)
end

local function sSm()
    local n = tick(); smT = nil; smTR = math.huge
    local r = h()
    if not r then return end
    if dupCnt < 6 then return end
    for p, t in pairs(aT) do
        if not t.col and p.Parent and t.id == SMI then
            local rem = t.l - (n - t.s)
            if rem > 0 and rem < smTR then smT = p; smTR = rem end
        end
    end
    if smT and not isCS then INT = true end
end

local function gPB(action, pos)
    if #pH == 0 then return 0 end
    local be = 0
    for i = 1, #pH do
        for j = 1, #pH[i].actions do
            local pa = pH[i].actions[j]
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
    local now = tick(); local recent = {}
    for i = 1, #scorchSessions do
        if now - scorchSessions[i].time <= PAT_WINDOW then
            table.insert(recent, scorchSessions[i])
        end
    end
    table.sort(recent, function(a, b) return a.honeyGained > b.honeyGained end)
    top10patterns = {}
    for j = 1, math.min(PAT_TOP, #recent) do top10patterns[j] = recent[j] end
end

local function saveScorchSessions()
    if not writefile then return end
    if tick() - lastPatternSave < 120 then return end
    lastPatternSave = tick(); recalcTop10()
    pcall(function()
        writefile("bss_ai_scorch_v15.json", Http:JSONEncode({
            scorchSessions = scorchSessions, bestScorch = bestScorchHoney, top10 = top10patterns
        }))
    end)
end

local function getPatternBias(action)
    local ctx = getCtxKey(); local bias = 1.0
    for i = 1, #top10patterns do
        if top10patterns[i].ctx == ctx then
            for j = 1, #top10patterns[i].actions do
                if top10patterns[i].actions[j].action == action and SCORCH_BIAS > bias then
                    bias = SCORCH_BIAS; break
                end
            end
        end
    end
    return bias
end

local function recordScorchAction(action)
    if not scorchRecording then return end
    local r = h()
    table.insert(scorchActions, {
        action = action, pos = r and r.Position or Vector3.zero, phase = ph(),
        fc = (aB.FC.combo >= 10 and 1 or 0), rb = (aB.RB.combo >= 10 and 1 or 0),
        pm = math.min(3, aB.PoM.m), ssCombo = aB.SS.st
    })
end

local function scanScythes()
    local pf = Workspace:FindFirstChild("PlayerFlames")
    if not pf then return end
    -- Clean up stale flame entries
    for fl, _ in pairs(scytheParts) do
        if not fl.Parent then scytheParts[fl] = nil; flameCooldowns[fl] = nil end
    end
    for _, f in ipairs(pf:GetChildren()) do
        local nm = f.Name or ""
        if nm:sub(1, 3) == "Flm" or nm:find("Scythe") or nm:find("Flame") then
            if not scytheParts[f] then scytheParts[f] = { sT = tick(), hit = false } end
        end
    end
end

local function hTL()
    for p, t in pairs(aT) do
        if not t.col and p.Parent and t.p >= 90 then
            if t.dp then
                if tick() - lastTokenLinkTime > 3.0 then return true end
            else return true end
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
    local rp = aR and aR.Position
    if not rp then return nil end
    local bpSm, bdSm = nil, math.huge
    local bpTp, bdTp = nil, math.huge
    for p, t in pairs(aT) do
        if not t.col and p.Parent then
            if d3(p.Position, rp) <= aRR * 1.5 then
                local d = d3(r.Position, p.Position)
                if t.id == SMI and d < bdSm then bdSm = d; bpSm = p end
                if t.id == TPI and t.dp and d < bdTp then bdTp = d; bpTp = p end
            end
        end
    end
    if bpSm and bpTp then
        local st_ = aT[bpSm]
        local smRem = st_ and (st_.l - (tick() - st_.s)) or 0
        return smRem <= 3 and bpSm or bpTp
    end
    return bpSm or bpTp
end

local function eS()
    local r = h()
    if not r then return "dead" end
    local p_ = ph(); local tlD = "none"
    for p, t in pairs(aT) do
        if not t.col and p.Parent and t.p >= 90 then
            local d = d3(r.Position, p.Position)
            if d < 20 then tlD = "close" elseif d < 60 then tlD = "far" end
        end
    end
    local prN = math.min(3, #gCH(true, false, false))
    local rN = math.min(3, #gCH(false, true, false))
    local sU = (smT ~= nil and "1" or "0")
    local hP = (#fP > 0 and "1" or "0")
    local nT = false; local n = tick()
    for p, t in pairs(aT) do
        if not t.col and p.Parent and (t.l - (n - t.s)) > 1 and d3(r.Position, p.Position) < 30 then
            nT = true; break
        end
    end
    local zn = "mid"
    if curF and curF.part and curF.part.Size then
        local c = curF.part.Position; local s = curF.part.Size
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
            if not cQ[i].col and cQ[i].part.Parent and not cQ[i].isP and d3(r.Position, cQ[i].part.Position) < 20 then
                ct = ct + 1
            end
        end
        if ct > 2 then chT = "many" elseif ct > 0 then chT = "some" end
    end
    return string.format("PH:%s|SC:%s|TL:%s|CH:%d|PR:%d|SM:%s|NT:%s|Z:%s|CT:%s|PT:%s|XF:%s|PM:%d|PLL:%d|SSp:%d|XFp:%d",
        p_, scPh(), tlD, rN, prN, sU, tostring(nT), zn, chT, hP,
        (aB.XF.st >= 19 and "1" or "0"),
        math.min(3, aB.PoM.m), pollenMarkStacks,
        scorchProgress, xfProgress)
end

-- ===== ACTIVE SUPER SCORCH: patrol near flames =====
local function getScorchFlameCenter()
    -- Weighted center: prefer dark flame clusters
    local cx, cz, count = 0, 0, 0
    local darkWeight = 5
    for fl, _ in pairs(scytheParts) do
        if fl and fl.Parent then
            local nm = fl.Name or ""
            local bcName = safeBrickColorName(fl)
            local isDark = (nm:find("Dark") or bcName == "Really black")
            local w = isDark and darkWeight or 1
            cx = cx + fl.Position.X * w; cz = cz + fl.Position.Z * w
            count = count + w
        end
    end
    if count > 0 then
        return Vector3.new(cx / count, 0, cz / count), true
    end
    -- Fallback: field center
    if curF and curF.part then return curF.part.Position, false end
    local r = h()
    return r and r.Position or Vector3.zero, false
end

local function gAWB()
    local ba = {}
    local p_ = ph(); local n = tick()
    local isScorchActive = (aB.SS.st > 0)
    -- Super Scorch: Scorch active + Precision X10 + Precision of Marks x3 + Pollen Mark x3
    local isSuperScorch = (isScorchActive and prec.isX and aB.PoM.m >= 3 and pollenMarkStacks >= 3)

    local hasDupedMorph = false
    for p, t in pairs(aT) do
        if not t.col and p.Parent and t.dp and t.mo then hasDupedMorph = true; break end
    end
    local isSuperOutside = (not isScorchActive) and prec.isX and hasDupedMorph

    -- Backpack 90% dump
    local cs = LP:FindFirstChild("CoreStats")
    if cs then
        local cap = cs:FindFirstChild("Capacity"); local pol = cs:FindFirstChild("Pollen")
        if cap and pol then
            if cap.Value > 0 and (pol.Value / cap.Value) >= 0.9 then
                local all = gCH(false, false, false)
                if #all > 0 then return { "go_backpack_dump" } end
            end
        end
    end

    -- Showers auto-loot
    local r = h()
    if r then
        for i = 1, #activeShowers do
            local sh = activeShowers[i]
            if not sh.collected and sh.part.Parent then
                if (n - sh.spawnTime) < 0.8 and d3(r.Position, sh.part.Position) < 60 then
                    return { "go_shower" }
                end
            end
        end
    end

    -- Pre-emptive centering: XF≥22 and SS≥20 → drop everything, rush to center
    if xfProgress >= 22 and scorchProgress >= 20 and not isSuperScorch then
        local cc = gFC()
        if cc ~= Vector3.zero and r and d3(r.Position, cc) > XCR * 2 then
            return { "go_xflame_center" }
        end
    end

    local nearCH = gCH_nearest()
    if nearCH and not smT and not xfE and not isSuperScorch and not isSuperOutside then
        return { "go_crosshair" }
    end

    -- ===== ACTIVE SUPER SCORCH: patrol flames, collect tokens + CH =====
    if isSuperScorch then
        -- Collect tokens near scorch center
        local sc, _ = getScorchFlameCenter()
        if sc ~= Vector3.zero and r then
            local bestTok, bestD = nil, math.huge
            for p, t in pairs(aT) do
                if not t.col and p.Parent and t.p >= 8 then
                    local d = d3(p.Position, sc)
                    if d < 40 and d < bestD then bestD = d; bestTok = p end
                end
            end
            if bestTok then return { "go_scorch_token" } end
        end
        -- Collect nearby crosshairs
        local all = gCH(false, false, true)
        if #all > 0 then return { "go_crosshair_all" } end
        -- Patrol near flames (active movement)
        return { "patrol_scorch_flames" }
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
                if (n - t.s) > 2.0 then return { "go_duped_inspire_scorch" } end
            end
        end
    else
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.dp then
                local rem = t.l - (n - t.s)
                if t.mo and rem < 4.0 and rem > 0 then return { "go_duped_morph" }
                elseif t.id == 2000457501 and rem < 2.0 and rem > 0 then return { "go_duped_inspire_normal" }
                elseif t.id == 1472256444 and rem < 5.0 and rem > 0 then return { "go_duped_babylove" } end
            end
        end
    end

    if hTL() then return { "go_tokenlink" } end

    for i, coco in ipairs(activeCoconuts) do
        if not coco.collected and coco.part.Parent then
            local rem = 3.0 - (n - coco.spawnTime)
            if rem <= 1.0 and rem > 0.0 then return { "go_coconut" } end
        end
    end

    if smT and dupCnt >= 6 and not isSuperOutside then return { "go_smile" } end
    if aB.PoM.a and aR then
        local t = gSDA()
        if t then
            local td = aT[t]
            if td and td.id == SMI then table.insert(ba, 1, "go_smile_area")
            elseif td and td.id == TPI and td.dp then table.insert(ba, 1, "go_dup_area") end
        end
    end
    if p_ == "REFRESH" then
        local all = gCH(false, false, true)
        if #all > 0 then return { "go_crosshair_refresh_all" } end
        return { "patrol_ring" }
    end
    if p_ == "X10" then
        if isSuperOutside then
            -- Just patrol, no focus_ch action
        else
            local pp = gCH(true, false, false)
            if #pp > 0 then return { "go_purple" } end
        end
        return { "patrol_ring" }
    end
    if p_ == "НАБОР" then
        local tpBuild = gTPG_build()
        if tpBuild then return { "go_build_precision" } end
        local allCH = gCH(false, false, false)
        if #allCH > 0 then table.insert(ba, "go_crosshair") end
        if #fP > 0 then table.insert(ba, "go_petal") end
        for fl, data in pairs(scytheParts) do
            if fl and fl.Parent then
                local nm = fl.Name or ""
                local bcName = safeBrickColorName(fl)
                if not (nm:find("Dark") or bcName == "Really black") then
                    local cd = flameCooldowns[fl]
                    if (not cd or n >= cd) and data and (n - data.sT) > 2.0 then
                        table.insert(ba, "go_touch_flame"); break
                    end
                end
            end
        end
        if next(aT) ~= nil then
            table.insert(ba, "go_token_near"); table.insert(ba, "go_token_best")
        end
        local dt, _ = gDTP()
        if dt then table.insert(ba, "go_dup_tp") end
        table.insert(ba, "patrol_ring")
        return ba
    end
    return { "patrol_ring" }
end

-- ===== UCB ACTION SELECTION =====
local function cAB(s)
    local v = gAWB()
    if #v == 0 then return "patrol_ring" end
    -- ε-greedy fallback (only early on, fades with EP)
    if math.random() < EP then return v[math.random(1, #v)] end
    -- UCB: argmax( Q(s,a) * bias + C * sqrt(ln(N_total) / (n(s,a) + 1)) )
    if not visitCount[s] then visitCount[s] = {} end
    local bA, bestScore = v[1], -math.huge
    for i = 1, #v do
        local act = v[i]
        local qVal = gQ(s, act) * getPatternBias(act)
        local n = visitCount[s][act] or 0
        local ucbBonus = UCB_C * math.sqrt(math.log(totalSteps + 1) / (n + 1))
        local score = qVal + ucbBonus
        if score > bestScore then bA = act; bestScore = score end
    end
    -- Track visit
    visitCount[s][bA] = (visitCount[s][bA] or 0) + 1
    return bA
end

local function dUQ(s, a, rw, ns)
    local rr = h()
    local rp = rr and rr.Position or Vector3.zero
    local tR = rw + gPB(a, rp)

    -- === INTERMEDIATE REWARD SHAPING (Idea #9) ===
    tR = tR + flamesHitThisStep * 2           -- +2 per flame lit while moving
    tR = tR + chDetourThisStep * 1            -- +1 per stray CH picked by detour
    if abortedThisStep then tR = tR - 5 end  -- -5 for abort (stuck)

    -- === TIME PENALTY (Idea #7) ===
    local now = tick()
    if lastActionTime > 0 then
        local dt = now - lastActionTime
        tR = tR - dt * 0.5  -- -0.5 per second of idle/movement
    end
    lastActionTime = now

    -- === X-FLAME + SCORCH TIMING REWARD ===
    -- Perfect timing: X-Flame spawns in center when scorch has 27+/30 stacks
    local prevXF = aB.XF.st  -- current value before this action
    -- Check after: did X-Flame just activate?
    if xfProgress == 0 and prevXF >= 24 and scorchProgress >= 27 then
        local cc = gFC()
        local rPos = rr and rr.Position
        -- Bonus if player is near center (within XCR*1.5)
        if cc ~= Vector3.zero and rPos and d3(rPos, cc) <= XCR * 1.5 then
            tR = tR + 100  -- massive bonus for perfect XF+Scorch timing at center
        elseif cc ~= Vector3.zero and rPos and d3(rPos, cc) <= XCR * 4 then
            tR = tR + 40   -- decent bonus, close to center
        else
            tR = tR - 20   -- penalty: X-Flame wasted in corner
        end
    end

    -- === TD-LAMBDA ELIGIBILITY TRACES (Idea #2) ===
    if not eligibility[s] then eligibility[s] = {} end
    -- Decay all traces first
    for st, acts in pairs(eligibility) do
        for act, trace in pairs(acts) do
            eligibility[st][act] = trace * GA * TD_LAMBDA
            if eligibility[st][act] < 0.001 then eligibility[st][act] = nil end
        end
    end
    -- Accumulating trace for current state-action
    eligibility[s][a] = (eligibility[s][a] or 0) + 1

    -- Compute TD error
    local v = gAWB(); local mN = 0
    for i = 1, #v do local q = gQ(ns, v[i]); if q > mN then mN = q end end
    local tdError = tR + GA * mN - gQ(s, a)

    -- Apply TD error to ALL state-actions weighted by their eligibility trace
    for st, acts in pairs(eligibility) do
        for act, trace in pairs(acts) do
            sQ(st, act, gQ(st, act) + AL * tdError * trace)
        end
    end

    st.tR = st.tR + tR; st.dc = st.dc + 1
    totalSteps = totalSteps + 1
    EP = math.max(0.02, EP * ED)

    -- Reset step counters
    flamesHitThisStep = 0
    chDetourThisStep = 0
    abortedThisStep = false
end

-- ===== EXECUTE ACTION =====
local function eA(action)
    local r = h(); local hm_ = hm()
    if not r then return -1 end
    tL = action; recordScorchAction(action)

    -- Hit nearby non-dark flames while running to smile (pre-handler, hardened)
    if action == "go_smile" then
        for fl, data in pairs(scytheParts) do
            if fl and fl.Parent then
                local nm = fl.Name or ""
                local bcName = safeBrickColorName(fl)
                if not (nm:find("Dark") or bcName == "Really black") and d3(r.Position, fl.Position) <= SCYTHE_DIST * 2 then
                    pcall(hitNearbyFlames)
                end
            end
        end
    end

    if action == "patrol_scorch_flames" then
        local sc, hasFlames = getScorchFlameCenter()
        tL = hasFlames and "🔥SS Orbital" or "🔥SS Patrol"
        INT = false
        if sc ~= Vector3.zero and hasFlames then
            -- Orbital patrol: move along circle at SCYTHE_DIST * 0.9 from flame center
            local orbAngle = (tick() * 0.8) % (2 * math.pi)  -- continuous rotation
            local orbDist = SCYTHE_DIST * 0.9
            local px = sc.X + math.cos(orbAngle) * orbDist
            local pz = sc.Z + math.sin(orbAngle) * orbDist
            goTo(Vector3.new(px, r.Position.Y, pz), 4, PT)
        elseif sc ~= Vector3.zero then
            local ang = math.random() * 2 * math.pi
            local dist = math.random() * aRR * 0.5
            goTo(Vector3.new(sc.X + math.cos(ang) * dist, r.Position.Y, sc.Z + math.sin(ang) * dist), 5, PT)
        else
            goTo(r.Position, 5, 2)
        end
        task.wait(0.1 + math.random() * 0.2)
        return 0
    end

    if action == "go_scorch_token" then
        local sc, _ = getScorchFlameCenter()
        if sc == Vector3.zero then return -1 end
        local bestTok, bestD = nil, math.huge
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.p >= 8 then
                local d = d3(p.Position, sc)
                if d < 40 and d < bestD then bestD = d; bestTok = p end
            end
        end
        if bestTok then
            tL = "🔥SS Token"
            INT = false
            local ok = goTo(bestTok.Position, 4, 5)
            if ok and bestTok.Parent and aT[bestTok] then aT[bestTok].col = true; return 20 end
        end
        return -1
    end

    if action == "go_backpack_dump" then
        local all = gCH(false, false, false)
        if #all == 0 then return -1 end
        -- Pick NEAREST CH, not first by spawn time
        local best, bestD = nil, math.huge
        for _, ch in ipairs(all) do
            local d = d3(r.Position, ch.part.Position)
            if d < bestD then bestD = d; best = ch end
        end
        local t = best
        tL = "🎒 90% dump"
        INT = false
        local ok = goTo(t.part.Position, 4, 3)
        if ok and t.part.Parent then
            local t0 = tick()
            while tick() - t0 < 1.0 do
                task.wait(0.05)
                if not t.part.Parent then break end
                local h__ = hm(); if h__ then h__:MoveTo(Vector3.new(t.part.Position.X, t.part.Position.Y, t.part.Position.Z)) end
            end
            t.col = true; st.chP = st.chP + 1
            if t.isP then st.pr = st.pr + 1 else st.ch = st.ch + 1 end
            return 50
        end
        return -2
    end

    if action == "go_shower" then
        for i = 1, #activeShowers do
            local sh = activeShowers[i]
            if not sh.collected and sh.part.Parent and (tick() - sh.spawnTime) < 0.8 then
                tL = "🌊 Shower"; INT = false
                -- Stand on disk for 2 seconds
                r.CFrame = CFrame.new(sh.part.Position.X, sh.part.Position.Y + 3, sh.part.Position.Z)
                local t0 = tick()
                while tick() - t0 < 2.0 do task.wait(0.05); if not sh.part.Parent then break end end
                sh.collected = true
                -- Teleport to next uncollected shower every 2 seconds
                local nextFound = true
                while nextFound and not INT do
                    nextFound = false
                    for j = 1, #activeShowers do
                        local ns = activeShowers[j]
                        if not ns.collected and ns.part.Parent and ns ~= sh and (tick() - ns.spawnTime) < 2.5 then
                            tL = "🌊 Shower TP"
                            r.CFrame = CFrame.new(ns.part.Position.X, ns.part.Position.Y + 3, ns.part.Position.Z)
                            local t1 = tick()
                            while tick() - t1 < 2.0 do task.wait(0.05); if not ns.part.Parent then break end end
                            ns.collected = true
                            nextFound = true
                            break
                        end
                    end
                end
                return 10 + math.min(40, #activeShowers * 10)
            end
        end
        return -1
    end

    if action == "go_duped_morph" then
        local n = tick()
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.dp and t.mo and (t.l - (n - t.s)) < 4.0 then
                tL = "🐻 Morph (Dup)"
                INT = false
                local ok = goTo(p.Position, 4, 3)
                if ok and p.Parent then
                    local t0 = tick()
                    while tick() - t0 < 1.1 do task.wait(0.05); if not p.Parent then break end; local h__ = hm(); if h__ then h__:MoveTo(Vector3.new(p.Position.X, p.Position.Y, p.Position.Z)) end end
                    t.col = true; return 25
                end
            end
        end
        return -2
    end

    if action == "go_duped_babylove" then
        local n = tick()
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.dp and t.id == 1472256444 and (t.l - (n - t.s)) < 5.0 then
                tL = "👶 Baby Love (Dup)"
                INT = false
                local ok = goTo(p.Position, 4, 3)
                if ok and p.Parent then
                    local t0 = tick()
                    while tick() - t0 < 1.1 do task.wait(0.05); if not p.Parent then break end; local h__ = hm(); if h__ then h__:MoveTo(Vector3.new(p.Position.X, p.Position.Y, p.Position.Z)) end end
                    t.col = true; return 25
                end
            end
        end
        return -2
    end

    if action == "go_duped_inspire_scorch" then
        local n = tick()
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.dp and t.id == 2000457501 and (n - t.s) > 2.0 then
                tL = "🔥 Inspire (Scorch)"
                INT = false
                local ok = goTo(p.Position, 4, 3)
                if ok and p.Parent then
                    local t0 = tick()
                    while tick() - t0 < 1.1 do task.wait(0.05); if not p.Parent then break end; local h__ = hm(); if h__ then h__:MoveTo(Vector3.new(p.Position.X, p.Position.Y, p.Position.Z)) end end
                    t.col = true; return 35
                end
            end
        end
        return -2
    end

    if action == "go_duped_inspire_normal" then
        local n = tick()
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.dp and t.id == 2000457501 and (t.l - (n - t.s)) < 2.0 then
                tL = "✨ Inspire (Dup)"
                INT = false
                local ok = goTo(p.Position, 4, 3)
                if ok and p.Parent then
                    local t0 = tick()
                    while tick() - t0 < 1.1 do task.wait(0.05); if not p.Parent then break end; local h__ = hm(); if h__ then h__:MoveTo(Vector3.new(p.Position.X, p.Position.Y, p.Position.Z)) end end
                    t.col = true; return 25
                end
            end
        end
        return -2
    end

    if action == "go_touch_flame" then
        local bestFl, bestD = nil, math.huge; local n = tick()
        for fl, data in pairs(scytheParts) do
            -- Guard: weak table keys can go nil, check all fields safely
            if fl and fl.Parent then
                local nm = fl.Name or ""
                local bcName = safeBrickColorName(fl)
                if not (nm:find("Dark") or bcName == "Really black") then
                    local cd = flameCooldowns[fl]
                    if (not cd or n >= cd) and data and (n - data.sT) > 2.0 then
                        local d = d3(r.Position, fl.Position)
                        if d < bestD then bestD = d; bestFl = fl end
                    end
                end
            end
        end
        if bestFl then
            tL = "🔥 Flame"; INT = false
            -- Position so flame is SCYTHE_DIST in front of player (scythe visual range)
            local dirFromFlame = (r.Position - bestFl.Position).Unit
            if dirFromFlame.Magnitude < 0.1 then dirFromFlame = Vector3.new(1, 0, 0) end
            local approachPos = bestFl.Position + dirFromFlame * SCYTHE_DIST * 0.85
            if goTo(approachPos, 3, 3) then
                flameCooldowns[bestFl] = tick() + 5.0
                return 10
            end
        end
        return -2
    end

    if action == "go_coconut" then
        local n = tick()
        for i, coco in ipairs(activeCoconuts) do
            if not coco.collected and coco.part.Parent and (3.0 - (n - coco.spawnTime)) <= 1.0 then
                tL = "🥥 Coconut"; INT = false
                local ok = goTo(coco.part.Position, 3, 2)
                if ok and coco.part.Parent then
                    local t0 = tick(); local rem = 3.0 - (n - coco.spawnTime)
                    while tick() - t0 < rem do task.wait(0.05); if not coco.part.Parent then break end; local h__ = hm(); if h__ then h__:MoveTo(Vector3.new(coco.part.Position.X, coco.part.Position.Y, coco.part.Position.Z)) end end
                    coco.collected = true; return 30
                end
            end
        end
        return -2
    end

    if action == "go_build_precision" then
        local tp = gTPG_build()
        if not tp then return -1 end
        local g = tp[1]; local rw = 0; INT = false
        if g.pr.part.Parent and not g.pr.col then
            tL = "🟣 BUILD TP"
            if goTo(g.pr.part.Position, 4, 5) and g.pr.part.Parent then g.pr.col = true; lP = g.pr.part; st.pr = st.pr + 1; rw = rw + 30; task.wait(0.1) end
        end
        if g.r1.part.Parent and not g.r1.col then
            tL = "🎯 BUILD r1"
            if goTo(g.r1.part.Position, 4, 4) and g.r1.part.Parent then g.r1.col = true; st.ch = st.ch + 1; rw = rw + 10; task.wait(0.05) end
        end
        if g.r2.part.Parent and not g.r2.col then
            tL = "🎯 BUILD r2"
            if goTo(g.r2.part.Position, 4, 4) and g.r2.part.Parent then g.r2.col = true; st.ch = st.ch + 1; rw = rw + 10 end
        end
        if rw > 0 and aB.PoM.a and aB.PoM.pos then goTo(aB.PoM.pos, 6, 3) end
        return rw > 0 and rw or -2
    end

    if action == "go_multi_purple" then
        local pp = gPCH()
        if #pp < 2 then return -1 end
        local rw = 0; INT = false
        if pp[1].part.Parent then
            tL = "Purpx2 #1"
            if goTo(pp[1].part.Position, 4, 3) and pp[1].part.Parent then pp[1].col = true; st.pr = st.pr + 1; rw = rw + 20 end
        end
        if pp[2].part.Parent then
            tL = "Purpx2 #2"
            if goTo(pp[2].part.Position, 4, 3) and pp[2].part.Parent then pp[2].col = true; st.pr = st.pr + 1; rw = rw + 20 end
        end
        return rw > 0 and rw or -2
    end

    if action == "go_crosshair_all" then
        local all = gCH(false, false, true)
        if #all == 0 then return -1 end
        -- gCH already sorted (purples first by spawn time, then regular by spawn time)
        local rw = 0; INT = false
        for i = 1, #all do
            local ch = all[i]
            if ch.part.Parent and not ch.col then
                tL = ch.isP and "Purp Scorch" or "CH Scorch"
                if goTo(ch.part.Position, 4, 3) and ch.part.Parent then
                    ch.col = true
                    if ch.isP then st.pr = st.pr + 1; rw = rw + 20 else st.ch = st.ch + 1; rw = rw + 10 end
                end
            end
        end
        return rw > 0 and rw or -2
    end

    if action == "go_crosshair_refresh_all" then
        local all = gCH(false, false, true)
        if #all == 0 then return -1 end
        local col = 0; INT = false
        for i = 1, #all do
            local ch = all[i]
            if ch.part.Parent and not ch.col and col < 3 then
                tL = "RFSH " .. (col + 1)
                if goTo(ch.part.Position, 4, 4, true) and ch.part.Parent then
                    ch.col = true; rCC = rCC + 1
                    if ch.isP then st.pr = st.pr + 1; lP = ch.part else st.ch = st.ch + 1 end
                    col = col + 1; task.wait(0.1)
                end
            end
        end
        if aR and aR.Parent then goTo(aR.Position, 6, 4) else goTo(cP(r.Position), 5, 2) end
        if rCC >= 3 then prec.nR = false; cyc.chC = 0; st.rf = st.rf + 1; rCC = 0; return 40 end
        return col > 0 and col * 12 or -2
    end

    if action == "go_smile_area" then
        local t = gSDA()
        if not t or not aT[t] or aT[t].col or aT[t].id ~= SMI then return -1 end
        tL = "Smile(R)"; INT = false
        local ok = goTo(gEP(t.Position), 4, 4)
        if ok and t.Parent then aT[t].col = true; st.sm = st.sm + 1; dupCnt = 0; return 45 end
        return -10
    end

    if action == "go_dup_area" then
        local t = gSDA()
        if not t or not aT[t] or aT[t].col or aT[t].id ~= TPI or not aT[t].dp then return -1 end
        tL = "Dup(R)"; INT = false
        local ok = goTo(gEP(t.Position), 4, 4)
        if ok and t.Parent then aT[t].col = true; st.tk = st.tk + 1; return 15 end
        return -2
    end

    if action == "go_smile" then
        if not smT or not smT.Parent then smT = nil; return -1 end
        local td = aT[smT]
        if not td or td.col then smT = nil; return -1 end
        isCS = true; tL = "Smile"; INT = false
        goSmileGuard = true
        -- Hit ALL non-dark flames while running to smile (aggressive strafe, hardened)
        for fl, data in pairs(scytheParts) do
            if fl and fl.Parent then
                local nm = fl.Name or ""
                local bcName = safeBrickColorName(fl)
                local isDark = (nm:find("Dark") or bcName == "Really black")
                if not isDark and d3(r.Position, fl.Position) <= SCYTHE_DIST * 2 then
                    pcall(hitNearbyFlames)
                end
            end
        end
        local timeout = math.max(0.5, math.min(3, smTR - 0.3))
        local ok = goTo(smT.Position, 4, timeout)
        goSmileGuard = false
        if ok and smT.Parent then
            if not td.dp then
                td.col = true; smT = nil; st.sm = st.sm + 1; isCS = false
                dupCnt = 0
                -- Recalc dupCnt immediately
                for _, tt in pairs(aT) do if tt.dp and not tt.col then dupCnt = dupCnt + 1 end end
                return 45
            end
            local st_ = tick()
            while tick() - st_ < TSD do
                task.wait(0.1)
                if not smT.Parent then break end
                local h__ = hm(); if h__ then h__:MoveTo(Vector3.new(smT.Position.X, smT.Position.Y, smT.Position.Z)) end
            end
            td.col = true; smT = nil; st.sm = st.sm + 1; isCS = false; dupCnt = 0
            for _, tt in pairs(aT) do if tt.dp and not tt.col then dupCnt = dupCnt + 1 end end
            return 45
        end
        isCS = false; smT = nil; goSmileGuard = false; return -10
    end

    if action == "go_purple" then
        local pp = gCH(true, false, false)
        if #pp == 0 then return -1 end
        local rw = 0; INT = false
        for i = 1, #pp do
            local ch = pp[i]
            if ch.part.Parent and not ch.col and not smT then
                if goTo(ch.part.Position, 5, 5) and ch.part.Parent then
                    ch.col = true; lP = ch.part; st.pr = st.pr + 1; tL = "🟣 1s"
                    if prec.isX and not prec.nR then
                        local t0 = tick()
                        while tick() - t0 < 1.0 do task.wait(0.05); if smT or prec.nR then break end; local h__ = hm(); if h__ then h__:MoveTo(Vector3.new(ch.part.Position.X, ch.part.Position.Y, ch.part.Position.Z)) end end
                    end
                    rw = rw + 20
                end
            end
        end
        return rw > 0 and rw or -2
    end

    if action == "go_tokenlink" then
        -- Find all TLs, sort by remaining life (pick most urgent)
        local tlList = {}
        local n_ = tick()
        for p, t in pairs(aT) do
            if not t.col and p.Parent and t.p >= 90 then
                table.insert(tlList, { p = p, t = t, rem = t.l - (n_ - t.s) })
            end
        end
        if #tlList == 0 then return -2 end
        table.sort(tlList, function(a, b) return a.rem < b.rem end)
        -- X-Flame aware: if TL in corner would trigger X-Flame at 25, skip it
        local bestTL = nil
        for _, entry in ipairs(tlList) do
            local shouldSkip = false
            if aB.XF.st > 0 then
                local cc = gFC()
                if cc ~= Vector3.zero then
                    local inCenter = d3(entry.p.Position, cc) <= XCR * 2
                    if not inCenter then
                        local battleNear = countBattleTokensNear(entry.p.Position, 40)
                        if aB.XF.st + battleNear >= 25 then
                            shouldSkip = true
                        end
                    end
                end
            end
            if not shouldSkip then bestTL = entry; break end
        end
        -- If all TLs skipped (would trigger X-Flame in corner), abort
        if not bestTL then return -2 end
        tL = "Link"; INT = false
        if goTo(bestTL.p.Position, 5, 5) and bestTL.p.Parent then
            bestTL.t.col = true; igT = tick() + TLC; lastTokenLinkTime = tick()
            -- TL duo: if another TL nearby with >3s life, wait 2-3s then collect
            for _, entry2 in ipairs(tlList) do
                if entry2.p ~= bestTL.p and entry2.p.Parent and not entry2.t.col then
                    local dist2 = d3(bestTL.p.Position, entry2.p.Position)
                    if dist2 < 40 and entry2.rem > 3.0 then
                        task.wait(math.min(2.5, entry2.rem - 1.0))
                        if entry2.p.Parent and not entry2.t.col then
                            goTo(entry2.p.Position, 5, 4)
                            if entry2.p.Parent then entry2.t.col = true end
                        end
                    elseif dist2 < 40 and entry2.rem <= 3.0 then
                        -- Both urgent, grab second immediately
                        goTo(entry2.p.Position, 5, 4)
                        if entry2.p.Parent then entry2.t.col = true end
                    end
                    break
                end
            end
            return 50
        end
        return -5
    end

    if action == "go_crosshair" then
        local all = gCH(false, false, false)
        if #all == 0 then return -1 end
        local t = all[1]; local rw = 0; INT = false
        if t.part.Parent and not t.col and not smT then
            local sk = false; local r2 = h()
            if r2 then
                for p2, t2 in pairs(aT) do
                    if not t2.col and p2.Parent and t2.p >= 90 and d3(r2.Position, p2.Position) < TLID and d3(r2.Position, t.part.Position) > 30 then
                        sk = true; break
                    end
                end
            end
            if xfE and not sk then
                local cc = gFC()
                if cc ~= Vector3.zero and d3(t.part.Position, cc) > XCR * 1.5 then sk = true end
            end
            if not sk then
                if goTo(t.part.Position, 4, 5) and t.part.Parent then
                    t.col = true
                    if t.isP then st.pr = st.pr + 1; lP = t.part; rw = rw + (prec.nR and 5 or 10)
                    else st.ch = st.ch + 1; cyc.chC = cyc.chC + 1; if cyc.chC >= 3 then cyc.chC = 0 end; rw = rw + 8 end
                end
            end
        end
        if rw > 0 and aB.PoM.a and aB.PoM.pos then goTo(aB.PoM.pos, 6, 4) end
        return rw > 0 and rw or -2
    end

    if action == "go_dup_tp" then
        local p, t = gDTP()
        if not p then return -1 end
        tL = "Dup"; INT = false
        if goTo(p.Position, 5, 5) and p.Parent then t.col = true; return 15 end
        return -2
    end

    if action == "go_petal" then
        if #fP == 0 then return -1 end
        local ca = false; local tr = 0; local i = 1
        while i <= #fP do
            local pt = fP[i]
            if not pt.part.Parent then table.remove(fP, i)
            elseif stP[pt.part] and tick() < stP[pt.part] then table.remove(fP, i)
            else
                tL = "🌸 " .. pt.cn; INT = false
                if goTo(Vector3.new(pt.part.Position.X, 0, pt.part.Position.Z), PCD, 2.5) then
                    st.pt = st.pt + 1; tr = tr + 8 + (14 - pt.pr); ca = true
                    if pt.cn == "Red" then redPetalTimer = tick() end  -- 8s buff timer
                    task.wait(0.05); i = i + 1
                else stP[pt.part] = tick() + 5; table.remove(fP, i) end
            end
        end
        return ca and tr or -1
    end

    if action == "go_token_near" then
        local be, bD = nil, math.huge
        for p, t in pairs(aT) do
            if not t.col and p.Parent then
                local d = d3(r.Position, p.Position)
                if d < bD then be = p; bD = d end
            end
        end
        if be then tL = "💎 " .. aT[be].n; INT = false; if goTo(be.Position, 5, 5) and be.Parent then aT[be].col = true; return 3 + aT[be].p * 0.2 end; return -2 end
        return -1
    end

    if action == "go_token_best" then
        local be, bestScore = nil, -1; local n = tick()
        for p, t in pairs(aT) do
            if not t.col and p.Parent then
                local rem = t.l - (n - t.s)
                if rem > 0.5 then
                    -- Score = priority * urgency (remaining fraction)
                    local score = t.p * (rem / t.l)
                    if t.dp then score = score * 1.3 end  -- duped tokens more urgent
                    if score > bestScore then bestScore = score; be = p end
                end
            end
        end
        if be then tL = "💎⭐ " .. aT[be].n; INT = false; if goTo(be.Position, 5, 5) and be.Parent then aT[be].col = true; return 5 + aT[be].p * 0.3 end; return -3 end
        return -1
    end

    if action == "patrol_ring" then
        local function rR()
            if xfE then
                local cc = gFC()
                if cc ~= Vector3.zero then
                    return cP(Vector3.new(cc.X + math.cos(math.random() * 2 * math.pi) * math.random() * XCR * 0.25, 0, cc.Z + math.sin(math.random() * 2 * math.pi) * math.random() * XCR * 0.25), true)
                end
            end
            if aR and aR.Parent and curF then
                local a_ = math.random() * 2 * math.pi; local rr_ = aRR * (0.5 + math.random() * 0.8)
                return cP(Vector3.new(aR.Position.X + math.cos(a_) * rr_, 0, aR.Position.Z + math.sin(a_) * rr_))
            end
            if curF then
                local c = curF.part.Position; local s = curF.part.Size
                local rp = Vector3.new(c.X + (math.random() * 2 - 1) * math.max(s.X / 2 * 0.3, 5), 0, c.Z + (math.random() * 2 - 1) * math.max(s.Z / 2 * 0.3, 5))
                -- Centripetal bias: if near edge, pull 40% toward center
                local rx = math.abs(rp.X - c.X) / math.max(s.X / 2, 1)
                local rz = math.abs(rp.Z - c.Z) / math.max(s.Z / 2, 1)
                if rx > 0.6 or rz > 0.6 then
                    rp = Vector3.new(rp.X + (c.X - rp.X) * 0.4, 0, rp.Z + (c.Z - rp.Z) * 0.4)
                end
                return cP(rp)
            end
            local rp = h(); return rp and cP(rp.Position + Vector3.new((math.random() * 2 - 1) * 30, 0, (math.random() * 2 - 1) * 30)) or cP(Vector3.zero)
        end
        tL = xfE and "XF Ring" or "Ring"; INT = false
        local t = rR()
        if t == Vector3.zero or (not xfE and not iF(t)) then t = gFC() end
        if t == Vector3.zero then return 0 end
        -- Superficial token grab while patrolling: quick detour only for close tokens
        local bestTok, bestD = nil, math.huge
        local n_ = tick()
        for p, td in pairs(aT) do
            if not td.col and p.Parent then
                local d = d3(r.Position, p.Position)
                if d < 8 and d < bestD then
                    local rem = td.l - (n_ - td.s)
                    if rem > 1 and td.p >= 5 then bestD = d; bestTok = p end
                end
            end
        end
        if bestTok then
            local hm_ = hm()
            if hm_ then hm_:MoveTo(Vector3.new(bestTok.Position.X, r.Position.Y, bestTok.Position.Z)) end
            local tDet = tick()
            while tick() - tDet < 0.5 do
                task.wait(0.03)
                local rd = h(); if not rd then break end
                if d3(rd.Position, bestTok.Position) < 5 then
                    if aT[bestTok] and not aT[bestTok].col then
                        aT[bestTok].col = true; st.tk = st.tk + 1
                    end
                    break
                end
            end
        end
        goTo(t, xfE and 2 or 6, PT); task.wait(0.1 + math.random() * 0.3); return 0
    end

    if action == "go_xflame_center" then
        local c = gFC()
        if c == Vector3.zero then return -1 end
        tL = "XF center"; INT = false; goTo(c, 3, 3); return 0
    end

    if action == "go_xflame_ch" then
        local ch = gCH_nearest_center()
        if not ch then return -1 end
        tL = "XF CH"; INT = false
        if goTo(ch.part.Position, 2, 3) and ch.part.Parent then ch.col = true; st.ch = st.ch + 1; return 5 end
        return -1
    end

    return 0
end

local function uVC()
    local r = h()
    if aB.SS.st > 0 then
        if not scVis then
            local ok, part = pcall(function()
                local p = Instance.new("Part"); p.Name = "ScorchCenter"; p.Shape = Enum.PartType.Cylinder
                p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 0.55
                p.BrickColor = BrickColor.new("Bright orange"); p.Size = Vector3.new(XCR * 3, 0.3, XCR * 3); p.Parent = Workspace; return p
            end)
            if ok then scVis = part end
        end
        if scVis then scVis.CFrame = CFrame.new(gFC().X, gFC().Y + 0.15, gFC().Z) * CFrame.Angles(0, 0, math.pi/2) end
    else if scVis then pcall(function() scVis:Destroy() end); scVis = nil end end

    if xfE then
        local cc = gFC()
        if cc == Vector3.zero and r then cc = r.Position end
        if not xfC then
            local ok, part = pcall(function()
                local p = Instance.new("Part"); p.Name = "XFlameCircle"; p.Shape = Enum.PartType.Cylinder
                p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 0.5
                p.BrickColor = BrickColor.new("Really red"); p.Size = Vector3.new(XCR * 2, 0.2, XCR * 2); p.Parent = Workspace; return p
            end)
            if ok then xfC = part end
        end
        if xfC then xfC.CFrame = CFrame.new(cc.X, cc.Y + 0.1, cc.Z) * CFrame.Angles(0, 0, math.pi/2) end
    else if xfC then pcall(function() xfC:Destroy() end); xfC = nil end end

    if ENABLED and r then
        if not syVis then
            local ok, part = pcall(function()
                local p = Instance.new("Part"); p.Name = "ScytheRadius"; p.Shape = Enum.PartType.Cylinder
                p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 0.55
                p.BrickColor = BrickColor.new("Cyan"); p.Size = Vector3.new(SCYTHE_DIST * 2, 0.15, SCYTHE_DIST * 2); p.Parent = Workspace; return p
            end)
            if ok then syVis = part end
        end
        if syVis then syVis.CFrame = CFrame.new(r.Position.X, r.Position.Y + 0.05, r.Position.Z) * CFrame.Angles(0, 0, math.pi/2) end
    else if syVis then pcall(function() syVis:Destroy() end); syVis = nil end end
end

local mLS = false
local function sML()
    if mLS then return end; mLS = true; task.wait(2)
    scriptStartHoney = getCoreHoney(); scriptStartTime = tick()
    lQ(); fAR(); fF()
    logOk("BSS AI v16.5 ready! " .. fmtHoney(scriptStartHoney))
    print("✅ v16.5"); tL = "init"; lMT = tick()
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
    logOk("Loaded: " .. #scorchSessions)
end)

task.spawn(function()
    while true do task.wait(30); pcall(function()
        local lt = Workspace:FindFirstChild("Lighting")
        if lt then lt.GlobalShadows = false; lt.Brightness = 2 end
    end) end
end)

-- ===== SEPARATE BUFF POLLING LOOP (0.5s) =====
task.spawn(function()
    while true do
        task.wait(0.5)
        if ENABLED and mLS then
            pcall(pollAllBuffs)
        end
    end
end)

if _G.BSSAI_HB then pcall(function() _G.BSSAI_HB:Disconnect() end) end
_G.BSSAI_HB = RunService.Heartbeat:Connect(function()
    hbF = hbF + 1
    if not ENABLED then return end
    if not mLS then sML(); return end
    local n = tick(); fAR()
    -- Buff polling handled by separate spawn loop (pollAllBuffs every 0.5s)
    if hbF % 9 == 0 then sPt(); scanScythes()
        local h_ = hm()
        if h_ then local ts = gAS(); if math.abs(h_.WalkSpeed - ts) > 0.5 then h_.WalkSpeed = ts end end
    end
    -- uHB removed (action buffer was never read, only grew infinitely)
    if hbF % 3 == 0 then sSm() end
    if hbF % 180 == 0 then fF() end
    if hbF % 60 == 0 then clnCH() end
    if hbF % 30 == 0 then saveScorchSessions() end
    -- Q-table decay every ~10 min (hbF ~60/sec => 36000 frames)
    if hbF % 36000 == 0 then
        for _, tbl in pairs(qTables) do
            for k, v in pairs(tbl) do tbl[k] = v * 0.99 end
        end
    end
    if hbF % 18000 == 0 then
        task.spawn(function()
            local qc = 0; for _ in pairs(QT) do qc = qc + 1 end
            if writefile then pcall(function()
                writefile("bss_ai_q_v15.json", Http:JSONEncode({
                    version = Q_VERSION, qtable = QT, scorchSessions = scorchSessions,
                    bestScorch = bestScorchHoney, top10 = top10patterns,
                    eligibility = eligibility, visitCount = visitCount, totalSteps = totalSteps,
                    meta = { sc = qc, sa = os.time() }
                }))
            end) end
        end)
    end
    xfE = (aB.XF.st >= 19)
    if xfE then INT = true
        if not fixedXFlameCenter then
            local tf = Workspace.Flowers:FindFirstChild("FP18-10-13")
            if tf then fixedXFlameCenter = tf.Position end
        end
    else fixedXFlameCenter = nil end
    uVC()
    local r = h()
    if r then
        local vel = r.AssemblyLinearVelocity; local hS = (Vector3.new(vel.X, 0, vel.Z)).Magnitude
        if hS > 0.2 then lMT = n; stW = false
        elseif n - lMT > 5 and not stW then
            stW = true; INT = true; tL = "reset"
            if lP and not lP.Parent then lP = nil end
            if smT and not smT.Parent then smT = nil; isCS = false end
            INT = false; lMT = n
        end
    end
    if INT and not smT and not prec.nR and not xfE then INT = false end
    if prec.isX and not prec.nR and r then
        for i = 1, #cQ do
            local ch = cQ[i]
            if ch.part and ch.part.Parent and not ch.col and not ch.isP and d3(r.Position, ch.part.Position) < 4 then
                if n - lPT > 1.5 then lPT = n
                    local s_ = eS()
                    if s_ and s_ ~= "dead" then pcall(dUQ, s_, "patrol_ring", -20, s_) end
                    st.chA = st.chA + 1; break
                end
            end
        end
    end
    if isA then return end
    if hbF % 2 == 0 then
        isA = true
        local guardRoot = h()
        if guardRoot then
            flamesHitThisStep = 0; chDetourThisStep = 0; abortedThisStep = false
            local s_ = eS(); local a_ = cAB(s_)
            local ok, rw = pcall(eA, a_)
            if not ok then
                -- Actual Lua error (crash), worth logging
                logErr(a_ .. " crash: " .. tostring(rw))
                rw = -1
            end
            -- rw == -1 is normal "no targets" — never log, never treat as error
            local ns = eS(); pcall(dUQ, s_, a_, rw, ns)
        end
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
            if d.eligibility then eligibility = d.eligibility end
            if d.visitCount then visitCount = d.visitCount end
            if d.totalSteps then totalSteps = d.totalSteps end
        end
    end
end

local function rQ()
    QT = {}; EP = 0.1; st.tR = 0; st.dc = 0
    scorchSessions = {}; bestScorchHoney = 0; top10patterns = {}
    eligibility = {}; visitCount = {}; totalSteps = 0
    if writefile then pcall(function()
        writefile("bss_ai_q_v15.json", Http:JSONEncode({
            version = Q_VERSION, qtable = {}, scorchSessions = {},
            bestScorch = 0, top10 = {}, eligibility = {}, visitCount = {}, totalSteps = 0,
            meta = { ra = os.time() }
        }))
    end) end
end

-- ===== GUI =====
local sg = Instance.new("ScreenGui", PGui)
sg.Name = "BSSAI_GUI"
local fr = Instance.new("Frame", sg)
fr.Size = UDim2.new(0, 270, 0, 180)
fr.Position = UDim2.new(0, 10, 0, 10)
fr.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
fr.BackgroundTransparency = 0.15
fr.BorderSizePixel = 0; fr.Active = true; fr.Draggable = true
Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

local ti_gui = Instance.new("TextLabel", fr)
ti_gui.Size = UDim2.new(1, 0, 0, 18); ti_gui.Position = UDim2.new(0, 0, 0, 2)
ti_gui.BackgroundTransparency = 1; ti_gui.Text = "BSS AI v16.5"
ti_gui.TextColor3 = Color3.fromRGB(100, 200, 255)
ti_gui.Font = Enum.Font.GothamBold; ti_gui.TextSize = 12
ti_gui.TextXAlignment = Enum.TextXAlignment.Center

local lb = Instance.new("TextLabel", fr)
lb.Size = UDim2.new(1, 0, 0, 14); lb.Position = UDim2.new(0, 0, 0, 20)
lb.BackgroundTransparency = 1; lb.Text = "Action: start"
lb.TextColor3 = Color3.fromRGB(255, 255, 255)
lb.Font = Enum.Font.Gotham; lb.TextSize = 10
lb.TextXAlignment = Enum.TextXAlignment.Center

local hl = Instance.new("TextLabel", fr)
hl.Size = UDim2.new(1, 0, 0, 14); hl.Position = UDim2.new(0, 0, 0, 34)
hl.BackgroundTransparency = 1; hl.Text = "HP40M: --"
hl.TextColor3 = Color3.fromRGB(150, 255, 150)
hl.Font = Enum.Font.Gotham; hl.TextSize = 10
hl.TextXAlignment = Enum.TextXAlignment.Center

local sl = Instance.new("TextLabel", fr)
sl.Size = UDim2.new(1, 0, 0, 14); sl.Position = UDim2.new(0, 0, 0, 48)
sl.BackgroundTransparency = 1; sl.Text = "S: --"
sl.TextColor3 = Color3.fromRGB(255, 200, 100)
sl.Font = Enum.Font.Gotham; sl.TextSize = 10
sl.TextXAlignment = Enum.TextXAlignment.Center

local pl_ = Instance.new("TextLabel", fr)
pl_.Size = UDim2.new(1, 0, 0, 14); pl_.Position = UDim2.new(0, 0, 0, 62)
pl_.BackgroundTransparency = 1; pl_.Text = "Φ: --"
pl_.TextColor3 = Color3.fromRGB(180, 180, 255)
pl_.Font = Enum.Font.Gotham; pl_.TextSize = 10
pl_.TextXAlignment = Enum.TextXAlignment.Center

local bf = Instance.new("TextLabel", fr)
bf.Size = UDim2.new(1, 0, 0, 14); bf.Position = UDim2.new(0, 0, 0, 76)
bf.BackgroundTransparency = 1; bf.Text = "PM:-- PLM:-- dup:-- XF:-- SS:--"
bf.TextColor3 = Color3.fromRGB(255, 180, 100)
bf.Font = Enum.Font.Gotham; bf.TextSize = 9
bf.TextXAlignment = Enum.TextXAlignment.Center

local xfLine = Instance.new("TextLabel", fr)
xfLine.Size = UDim2.new(1, 0, 0, 14); xfLine.Position = UDim2.new(0, 0, 0, 90)
xfLine.BackgroundTransparency = 1; xfLine.Text = "XF:--/25 SS:--/30 PM:-- PLM:-- dup:--"
xfLine.TextColor3 = Color3.fromRGB(255, 180, 100)
xfLine.Font = Enum.Font.Gotham; xfLine.TextSize = 9
xfLine.TextXAlignment = Enum.TextXAlignment.Center

local sh = Instance.new("TextLabel", fr)
sh.Size = UDim2.new(1, 0, 0, 14); sh.Position = UDim2.new(0, 0, 0, 105)
sh.BackgroundTransparency = 1; sh.Text = "🔥 --"
sh.TextColor3 = Color3.fromRGB(255, 140, 80)
sh.Font = Enum.Font.Gotham; sh.TextSize = 9
sh.TextXAlignment = Enum.TextXAlignment.Center

local stopBtn = Instance.new("TextButton", fr)
stopBtn.Size = UDim2.new(1, -8, 0, 24); stopBtn.Position = UDim2.new(0, 4, 0, 135)
stopBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40); stopBtn.BorderSizePixel = 0
stopBtn.Text = "STOP"; stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold; stopBtn.TextSize = 12
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 4)

stopBtn.MouseButton1Click:Connect(function()
    ENABLED = not ENABLED
    stopBtn.Text = ENABLED and "STOP" or "RESUME"
    stopBtn.BackgroundColor3 = ENABLED and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(40, 160, 40)
end)

task.spawn(function()
    while true do task.wait(0.3); pcall(function()
        lb.Text = tL
        local curH = getCoreHoney(); local elapsedMin = (tick() - scriptStartTime) / 60
        local hp40m = elapsedMin > 0 and (curH - scriptStartHoney) / elapsedMin * 40 or 0
        hl.Text = "HP40M: " .. fmtHoney(hp40m) .. " | " .. fmtHoney(curH)
        local pStacksText = prec.isX and "[X10]" or ("[" .. prec.st .. "/10]")
        local precTimer = prec.tL > 0 and string.format("%.0fs", prec.tL) or "--"
        local precColor = ""
        if prec.isX and prec.tL > 0 and prec.tL <= PRAT then precColor = "⏳"
        elseif prec.isX then precColor = "✅" end
        sl.Text = "S: " .. string.format("%.0f", cS) .. " | " .. precColor .. "PREC: " .. precTimer .. " " .. pStacksText
        pl_.Text = ph() .. " CH:" .. #cQ .. " Tk:" .. st.tk .. " Pr:" .. st.pr .. " Sm:" .. st.sm
        -- Session stats per minute
        local chRate = elapsedMin > 0 and math.floor(st.chP / elapsedMin) or 0
        local tkRate = elapsedMin > 0 and math.floor(st.tk / elapsedMin) or 0
        local flRate = elapsedMin > 0 and math.floor(stFlMin / elapsedMin) or 0
        bf.Text = "CH:" .. chRate .. "/m Tk:" .. tkRate .. "/m Fl:" .. flRate .. "/m"
        xfLine.Text = "XF:" .. xfProgress .. "/25 SS:" .. scorchProgress .. "/30 PM:" .. aB.PoM.m .. " PLM:" .. pollenMarkStacks .. " dup:" .. dupCnt
        if scorchActive and scorchStartTime > 0 then
            local se = (tick() - scorchStartTime) / 60
            sh.Text = "🔥 " .. fmtHoney(curH - scorchStartHoney) .. " " .. string.format("%.1f", se) .. "min | " .. fmtHoney(bestScorchHoney)
        else
            sh.Text = "🔥 " .. #scorchSessions .. " scorches | Top10:" .. #top10patterns .. " | " .. fmtHoney(bestScorchHoney)
        end
    end) end
end)

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.T then ENABLED = not ENABLED
    elseif i.KeyCode == Enum.KeyCode.G then rQ()
    elseif i.KeyCode == Enum.KeyCode.P then
        local c = 0; for _ in pairs(QT) do c = c + 1 end
        print("v16.5 Φ:" .. ph() .. " eps:" .. string.format("%.3f", EP) .. " R:" .. st.tR .. " S:" .. c .. " FC:" .. aB.FC.combo .. " RB:" .. aB.RB.combo .. " PM:" .. aB.PoM.m .. " PLM:" .. pollenMarkStacks .. " Honey:" .. fmtHoney(getCoreHoney()) .. " Sc:" .. #scorchSessions)
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(2)
    aT = {}; cQ = {}; lP = nil; curF = nil; tL = "start"
    smT = nil; isCS = false; INT = false; cyc = { chC = 0 }; fP = {}
    igT = 0; rCC = 0; dupCnt = 0; pollenMarkStacks = 0
    eligibility = {}; visitCount = {}; totalSteps = 0
    scorchActive = false; scorchRecording = false; scorchActions = {}
    scorchStartHoney = 0; scorchStartTime = 0
    fixedXFlameCenter = nil; lastTokenLinkTime = 0; lastFocusCHTime = 0
    xfProgress = 0; scorchProgress = 0; lastBloomHit = 0; redPetalTimer = 0
    stFlMin = 0
    for _, v in pairs(activeTokenGuis) do if v.gui then pcall(function() v.gui:Destroy() end) end end
    activeShowers = {}; activeBlooms = {}; activeCoconuts = {}; activeTokenGuis = {}
    for fl in pairs(flameCooldowns) do flameCooldowns[fl] = nil end
    for fl in pairs(scytheParts) do scytheParts[fl] = nil end
    if xfC then xfC:Destroy(); xfC = nil end
    if scVis then scVis:Destroy(); scVis = nil end
    if syVis then syVis:Destroy(); syVis = nil end
    task.spawn(function()
        if writefile then
            local qc = 0; for _ in pairs(QT) do qc = qc + 1 end
            pcall(function()
                writefile("bss_ai_q_v15.json", Http:JSONEncode({
                    version = Q_VERSION, qtable = QT, scorchSessions = scorchSessions,
                    bestScorch = bestScorchHoney, top10 = top10patterns,
                    eligibility = eligibility, visitCount = visitCount, totalSteps = totalSteps,
                    meta = { sc = qc, sa = os.time() }
                }))
            end)
        end
    end)
end)

print("✅ BSS AI v16.5 MERGED — Advanced Q-Learning + XF/Scorch Timing + UCB + TD-lambda")
