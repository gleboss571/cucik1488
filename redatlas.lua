-- BSS AI v14.5 — ERROR-RESILIENT: self-healing with error GUI (Lua 5.1 strict)
-- ===== BOOTSTRAP: Error GUI that survives crashes =====
local errLog = {}
local errGui, errLabel, errCopyBtn, errCloseBtn
local function addErr(msg)
  errLog[#errLog + 1] = ("[%s] %s"):format(os.date and os.date("%H:%M:%S") or "??:??", tostring(msg))
  if errLabel then
    local txt = ""
    local start = math.max(1, #errLog - 18)
    for i = start, #errLog do txt = txt .. errLog[i] .. "\n" end
    errLabel.Text = txt
  end
  warn("BSSAI_ERR:", msg)
end
local function safeCall(name, fn, ...)
  local ok, res = pcall(fn, ...)
  if not ok then addErr(name .. " FAILED: " .. tostring(res)) end
  return ok, res
end
-- Create error GUI FIRST, before anything else
safeCall("errGui", function()
  local sg = Instance.new("ScreenGui")
  sg.Name = "BSSAI_ErrorGUI"
  sg.ResetOnSpawn = false
  sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
  local fr = Instance.new("Frame", sg)
  fr.Size = UDim2.new(0, 400, 0, 260)
  fr.Position = UDim2.new(0.5, -200, 0.5, -130)
  fr.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
  fr.BackgroundTransparency = 0.05
  fr.BorderSizePixel = 0
  fr.Active = true
  fr.Draggable = true
  fr.Visible = true
  fr.ZIndex = 999
  pcall(function()
    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, 8)
    uic.Parent = fr
  end)
  local title = Instance.new("TextLabel", fr)
  title.Size = UDim2.new(1, -60, 0, 26)
  title.Position = UDim2.new(0, 12, 0, 8)
  title.BackgroundTransparency = 1
  title.Text = "⚠ BSS AI v14.5 — Error Log"
  title.TextColor3 = Color3.fromRGB(255, 140, 60)
  title.Font = Enum.Font.GothamBold
  title.TextSize = 13
  title.TextXAlignment = Enum.TextXAlignment.Left
  title.ZIndex = 999
  errCloseBtn = Instance.new("TextButton", fr)
  errCloseBtn.Size = UDim2.new(0, 28, 0, 28)
  errCloseBtn.Position = UDim2.new(1, -36, 0, 6)
  errCloseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
  errCloseBtn.BorderSizePixel = 0
  errCloseBtn.Text = "✕"
  errCloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
  errCloseBtn.Font = Enum.Font.GothamBold
  errCloseBtn.TextSize = 14
  errCloseBtn.ZIndex = 999
  pcall(function()
    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, 4)
    uic.Parent = errCloseBtn
  end)
  errCloseBtn.MouseButton1Click:Connect(function() fr.Visible = false end)
  local sep = Instance.new("Frame", fr)
  sep.Size = UDim2.new(1, -24, 0, 1)
  sep.Position = UDim2.new(0, 12, 0, 38)
  sep.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
  sep.BorderSizePixel = 0
  sep.ZIndex = 999
  errLabel = Instance.new("TextLabel", fr)
  errLabel.Size = UDim2.new(1, -24, 0, 130)
  errLabel.Position = UDim2.new(0, 12, 0, 44)
  errLabel.BackgroundTransparency = 1
  errLabel.Text = "⏳ Инициализация..."
  errLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
  errLabel.Font = Enum.Font.RobotoMono
  errLabel.TextSize = 10
  errLabel.TextXAlignment = Enum.TextXAlignment.Left
  errLabel.TextYAlignment = Enum.TextYAlignment.Top
  errLabel.TextWrapped = true
  errLabel.RichText = true
  errLabel.ZIndex = 999
  errCopyBtn = Instance.new("TextButton", fr)
  errCopyBtn.Size = UDim2.new(0, 140, 0, 28)
  errCopyBtn.Position = UDim2.new(0, 12, 0, 185)
  errCopyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
  errCopyBtn.BorderSizePixel = 0
  errCopyBtn.Text = "📋 Копировать логи"
  errCopyBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
  errCopyBtn.Font = Enum.Font.Gotham
  errCopyBtn.TextSize = 11
  errCopyBtn.ZIndex = 999
  pcall(function()
    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, 4)
    uic.Parent = errCopyBtn
  end)
  errCopyBtn.MouseButton1Click:Connect(function()
    local all = ""
    for i = 1, #errLog do all = all .. errLog[i] .. "\n" end
    if #all == 0 then all = "No errors" end
    pcall(setclipboard, all)
    errCopyBtn.Text = "✅ Скопировано!"
    task.wait(2)
    errCopyBtn.Text = "📋 Копировать логи"
  end)
  local reopenBtn = Instance.new("TextButton", fr)
  reopenBtn.Size = UDim2.new(0, 100, 0, 28)
  reopenBtn.Position = UDim2.new(0, 160, 0, 185)
  reopenBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
  reopenBtn.BorderSizePixel = 0
  reopenBtn.Text = "🔄 Показать GUI"
  reopenBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
  reopenBtn.Font = Enum.Font.Gotham
  reopenBtn.TextSize = 11
  reopenBtn.ZIndex = 999
  pcall(function()
    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, 4)
    uic.Parent = reopenBtn
  end)
  reopenBtn.MouseButton1Click:Connect(function() fr.Visible = true end)
  errGui = sg
  addErr("Error GUI initialized OK")
end)
-- Fallback: if RobotoMono fails, use any monospace
if errLabel then
  safeCall("fontFix", function()
    errLabel.Font = Enum.Font.Code or Enum.Font.RobotoMono or Enum.Font.Legacy
  end)
end

-- ===== PHASE 1: Service Initialization =====
local P, R, U, RS, H, V, L, G, W
safeCall("initServices", function()
  P = game:GetService("Players")
  W = game:GetService("Workspace")
  R = game:GetService("RunService")
  U = game:GetService("UserInputService")
  RS = game:GetService("ReplicatedStorage")
  H = game:GetService("HttpService")
  V = game:GetService("VirtualInputManager")
  L = P.LocalPlayer
  if not L then error("LocalPlayer is nil — not in game?") end
  G = L:WaitForChild("PlayerGui", 10)
  if not G then error("PlayerGui not found after 10s") end
  addErr("Services: OK (P,R,U,RS,H,V,L,G,W)")
end)
if not L then addErr("FATAL: no LocalPlayer — stopping"); return end

-- ===== PHASE 2: Math & Table Locals =====
local mabs, mmax, mmin, mfloor, mcos, msin, mpi, mrnd, mround
local tins, trem, tsrt, tcat
local _pcall, tick, twait, tspawn, _type, fmt, tonum, rawget
safeCall("initLocals", function()
  mabs, mmax, mmin, mfloor = math.abs, math.max, math.min, math.floor
  mcos, msin, mpi, mrnd, mround = math.cos, math.sin, math.pi, math.random, math.round
  tins, trem, tsrt, tcat = table.insert, table.remove, table.sort, table.concat
  _pcall, tick, _type, fmt, tonum, rawget = pcall, tick, type, string.format, tonumber, rawget
  twait = (task and task.wait) or wait or function(d) local t = tick() + (d or 0.03); while tick() < t do end end
  tspawn = (task and task.spawn) or spawn or function(f) coroutine.wrap(f)() end
  addErr("Math/table locals: OK")
end)

-- ===== PHASE 3: V3 & Color =====
local V3, V3z, cfRGB, cfLook
safeCall("initV3", function()
  V3 = Vector3.new
  V3z = Vector3.zero
  cfRGB = Color3.fromRGB
  -- Use CFrame.new(pos, lookAt) for compatibility (CFrame.lookAt is newer API)
  cfLook = function(pos, target)
    return CFrame.new(pos, target)
  end
  addErr("V3/Color: OK (CFrame.lookAt compat)")
end)

-- V3 Pool
local V3P = {}
for i = 1, 64 do V3P[i] = V3(0, 0, 0) end
local vpIdx = 0
local function v3(x, y, z)
  vpIdx = (vpIdx % 64) + 1
  V3P[vpIdx] = V3(x, y, z)
  return V3P[vpIdx]
end

-- ===== PHASE 4: Strings & Logging =====
local S = {
  GT = "⚠ BSS AI v14.5", AI = "иниц", CH = "🎯", SP = "🔥 Спираль",
  RD = "🔄 REFRESH диаг", RA = "🔄 REFRESH", RO = "✅ REFRESH OK",
  RR = "🏠 возвр в кольцо", TP = "🎯 TP фиол", TM = "🟣 TP Precise Mark",
  SM = "😊 Smile", SR = "😊 Smile (Ring)", DR = "🎯 Dup (Ring)",
  UG = "⚡Срочный", PP = "🟣 1с", LK = "💎🔴 Link", DT = "🎯 Dup",
  PT = "🌸 ", TK = "💎 ", TB = "💎⭐ ", PR = "🚶 кольцо", PA = "🚶 патруль",
  XC = "🔥 XFlame центр", XH = "🔥 XFlame CH",
  PHB = "НАБОР", PHX = "X10", PHR = "REFRESH",
  SCI = "INSIDE", SCO = "OUTSIDE", ST = "⏳ сброс", IN = "старт"
}
local LOG_LVL = { ERR = 1, WARN = 2, INFO = 3, DEBUG = 4 }
local LOG = LOG_LVL.INFO
local function log(lvl, f, ...)
  if lvl <= LOG then warn("BSSAI:" .. fmt(f, ...)) end
end

-- ===== PHASE 5: Config =====
local CFG = {
  V = "14.5", PB = 2574507284, PK = 0.02, PM = 10, PR = 15,
  PMID = 2499540966, PMA = 2575093099,
  PU = cfRGB(119, 85, 255), GH = cfRGB(17, 134, 19), CT = 12,
  SP = { [S.PHB] = 70, [S.PHX] = 90, [S.PHR] = 75 }, SJ = 3,
  CARS = 28 * 28, CAS = 20, CAD = 0.1, CIS = 30 * 30, ARD = 20,
  TLDS = 20 * 20, XRS = 12 * 12, PDS = 8 * 8, FM = 20, FMS = 3,
  FHA = 5, FHDS = 14 * 14, FDRS = 20 * 20,
  SMI = 5877939956, SMR = 15, SDN = 6, SCRS = 80 * 80,
  TPI = 8173559749, TLC = 2,
  DMA = 0.35, DMT = 0.8, RDMA = 0.15, RDMT = 0.5,
  CNTS = 30 * 30, CNSS = 20 * 20,
  AL = 0.5, GA = 0.95, ES = 0.3, ED = 0.9995, EM = 0.02,
  AME = 30, ACA = 10, AMIN = 0.2, AMAX = 50,
  PGE = 120, PMX = 30, PGM = 10, PMFG = 5, SRM = 4,
  SWP = 0.8, DCE = 60, TLM = 1, DLM = 21,
  QF = "bss_ai_q_v14.json", PF = "bss_ai_pat_v14.json", MFS = true
}

-- ===== PHASE 6: Token/Color tables =====
local TK = {
  [1629547638] = { n = "Token Link", b = 4, p = 99 },
  [2000457501] = { n = "Inspire", b = 8, p = 25 },
  [1472256444] = { n = "Baby Love", b = 8, p = 22 },
  [1629649299] = { n = "Focus", b = 4, p = 15 },
  [65867881] = { n = "Haste", b = 4, p = 15 },
  [1442863423] = { n = "Blue Boost", b = 4, p = 12 },
  [1442859163] = { n = "Red Boost", b = 4, p = 12 },
  [3877732821] = { n = "White Boost", b = 4, p = 12 },
  [1442700745] = { n = "Rage", b = 8, p = 10 },
  [253828517] = { n = "Melody", b = 8, p = 10 },
  [1472532912] = { n = "Polar Bear", b = 15, p = 8, mo = 1 },
  [1472491940] = { n = "Black Bear", b = 15, p = 8, mo = 1 },
  [1472425802] = { n = "Brown Bear", b = 15, p = 8, mo = 1 },
  [2032949183] = { n = "Mother Bear", b = 15, p = 8, mo = 1 },
  [1472580249] = { n = "Panda", b = 15, p = 8, mo = 1 },
  [1489734171] = { n = "Science Bear", b = 15, p = 8, mo = 1 },
  [1874564120] = { n = "Pulse", b = 12, p = 7 },
  [2499514197] = { n = "Honey Mark", b = 8, p = 7 },
  [2499540966] = { n = "Pollen Mark", b = 8, p = 7 },
  [4528379338] = { n = "Mark Surge", b = 4, p = 7 },
  [3582501342] = { n = "Rain Call", b = 24, p = 6 },
  [3582519526] = { n = "Tornado", b = 24, p = 6 },
  [5877998606] = { n = "Mind Hack", b = 16, p = 6 },
  [8083943936] = { n = "Surprise Party", b = 24, p = 6 },
  [177997841] = { n = "Glob", b = 4, p = 6 },
  [1839454544] = { n = "Gummy Storm", b = 4, p = 6 },
  [1442725244] = { n = "Bomb", b = 4, p = 5 },
  [5877939956] = { n = "Smile", b = 4, p = 5 },
  [4519549299] = { n = "Inferno", b = 4, p = 5 },
  [4519523935] = { n = "Triangulate", b = 4, p = 5 },
  [4528414666] = { n = "Summon Frog", b = 8, p = 5 },
  [4528208186] = { n = "Flame Fuel", b = 8, p = 5 },
  [1671281844] = { n = "Beamstorm", b = 12, p = 4 },
  [1442764904] = { n = "Red Bomb+", b = 4, p = 12 },
  [8083436978] = { n = "Blue Balloon", b = 4, p = 4 },
  [1104415222] = { n = "BondToken", b = 4, p = 4 },
  [2319100769] = { n = "Fetch", b = 8, p = 4 },
  [4889322534] = { n = "Fuzz Bombs", b = 4, p = 4 },
  [2319083910] = { n = "Impale", b = 24, p = 4 },
  [3080529618] = { n = "Jelly Bean", b = 4, p = 4 },
  [4889470194] = { n = "Pollen Haze", b = 4, p = 4 },
  [8173559749] = { n = "Target Practice", b = 8, p = 3 },
  [107187190] = { n = "Honey Gift", b = 4, p = 2 },
  [183390139] = { n = "Cog", b = 4, p = 2 }
}
local AV = {
  [1674871631] = 1, [1471882621] = 1, [1952740625] = 1, [8055428094] = 1,
  [2319943273] = 1, [3030569073] = 1, [3036899811] = 1, [3080740120] = 1,
  [3012679515] = 1, [1838129169] = 1, [2584584968] = 1, [1471849394] = 1,
  [1952682401] = 1, [6087969886] = 1, [2028574353] = 1, [2028453802] = 1
}
local PCOL = {
  ["Red"] = cfRGB(249, 34, 34), ["Pink"] = cfRGB(255, 130, 201),
  ["Merigold"] = cfRGB(218, 168, 28), ["Periwinkle"] = cfRGB(150, 156, 236),
  ["Violet"] = cfRGB(94, 38, 177), ["Scarlet"] = cfRGB(171, 19, 19),
  ["Green"] = cfRGB(35, 232, 5), ["Yellow"] = cfRGB(238, 204, 79),
  ["Black"] = cfRGB(11, 11, 11), ["Grey"] = cfRGB(127, 127, 127),
  ["Blue"] = cfRGB(33, 66, 249), ["Cyan"] = cfRGB(29, 196, 222),
  ["White"] = cfRGB(249, 249, 249)
}
local PPRIO = {
  Red = 1, Pink = 2, Merigold = 3, Periwinkle = 4, Violet = 5,
  Scarlet = 6, Green = 7, Yellow = 8, Black = 9, Grey = 10,
  Blue = 11, Cyan = 12, White = 13
}

-- ===== PHASE 7: Cache =====
local CACHE = {}
local function cfc(p, n)
  if not p then return nil end
  if CACHE[n] == nil then CACHE[n] = p:FindFirstChild(n) or false end
  local r = CACHE[n]
  if r == false or (r and not r.Parent) then
    local ok, found = pcall(function() return p:FindFirstChild(n) end)
    if ok then CACHE[n] = found or false else CACHE[n] = false end
  end
  return CACHE[n] ~= false and CACHE[n] or nil
end
local function clrCache() CACHE = {} end
local function cacheP()
  safeCall("cacheP.Particles", function() CACHE.Particles = W:FindFirstChild("Particles") end)
  safeCall("cacheP.PlayerFlames", function() CACHE.PlayerFlames = W:FindFirstChild("PlayerFlames") end)
  safeCall("cacheP.FlowerZones", function() CACHE.FlowerZones = W:FindFirstChild("FlowerZones") end)
  safeCall("cacheP.Flowers", function() CACHE.Flowers = W:FindFirstChild("Flowers") end)
  safeCall("cacheP.Terrain", function() CACHE.Terrain = W:FindFirstChild("Terrain") end)
  safeCall("cacheP.Lighting", function() CACHE.Lighting = W:FindFirstChild("Lighting") end)
end
cacheP()

-- ===== PHASE 8: Distance helpers =====
local function d2Sq(a, b) local dx = a.X - b.X; local dz = a.Z - b.Z; return dx * dx + dz * dz end
local function d2(a, b) return d2Sq(a, b) ^ 0.5 end
local function p2Sq(px, pz, bx, bz) local dx = px - bx; local dz = pz - bz; return dx * dx + dz * dz end

-- ===== PHASE 9: State =====
local ST = {
  ps = 0, pv = 0, pX = false, pl = 0, pd = 60, psS = 0, plf = 0, prf = false,
  sc = 0, sa = false, xf = 0, xe = false, pma = false, pmP = nil, fh = 0,
  cf = nil, ar = nil, arR = CFG.ARD, al = S.IN, la = nil,
  tk = 0, ch = 0, pr = 0, rd = 0, tr = 0, dc = 0, sm = 0, ca = 0,
  pt = 0, fl = 0, cg = 0, dg = 0, lm = 0, st = false, ig = 0,
  lps = 0, lsc = 0, lg = 0, lmh = 0, int = false,
  smA = false, smT = nil, smL = 0, hf = 0, en = true, _cS = nil, _apT = nil
}
local function ph()
  if not ST.pX then return S.PHB elseif ST.prf then return S.PHR else return S.PHX end
end
local function scPh() return ST.sa and S.SCI or S.SCO end

-- ===== PHASE 10: Collections =====
local chs, pts = {}, {}
local tks = setmetatable({}, { __mode = "k" })
local fls = setmetatable({}, { __mode = "k" })
local tkBT = {}
local aH, hH, pH, gP = {}, {}, {}, {}
local qT, aP = {}, { scrD = 4, pst = 1, tsd = 1.1, mcd = 10, pt = 8, arr = 5, mt = 6 }
local qTables, pHTables = {}, {}
local fldHash = nil
local dT = setmetatable({}, { __mode = "k" })
local bHP, eps = 0, CFG.ES
local chDrty = true
local cDiag, cRefDiag, cTP = nil, nil, nil
local ptPrevCnt = 0
local ptDirty = true
local sCache = {}
local afCH, afTP, afPL, afTL, afUg, afSc, afSm, afPM, afXF, afPt, afTk, afDTP =
  false, false, false, false, false, false, false, false, false, false, false, false
local aSt = {}
local rA = {}
local petCD = setmetatable({}, { __mode = "k" })
local tQ, tQLock = {}, false

-- ===== PHASE 11: Helpers =====
local function HR()
  local c = L.Character
  return c and c:FindFirstChild("HumanoidRootPart")
end
local function HM()
  local c = L.Character
  return c and c:FindFirstChildOfClass("Humanoid")
end
local function gTID(t)
  return tonum((t or ""):match("rbxassetid://(%d+)") or t:match("id=(%d+)"))
end
local function cP(pos, sk)
  if sk or not ST.cf then return pos end
  local f = ST.cf
  local c = f.Center
  local s = f.Size
  local mx = mmax(s.X / 2 - CFG.FMS, 1)
  local mz = mmax(s.Z / 2 - CFG.FMS, 1)
  local cl = V3(mmin(mmax(pos.X, c.X - mx), c.X + mx), pos.Y, mmin(mmax(pos.Z, c.Z - mz), c.Z + mz))
  if ST.xe then
    local dx, dz = cl.X - c.X, cl.Z - c.Z
    local dSq = dx * dx + dz * dz
    if dSq > 0 then
      local r = CFG.XRS ^ 0.5
      local invD = 1 / dSq ^ 0.5
      cl = V3(c.X + dx * invD * r, cl.Y, c.Z + dz * invD * r)
    end
  end
  return cl
end
local function iF(pos)
  if not ST.cf then return false end
  local f = ST.cf
  local c = f.Center
  local s = f.Size
  return mabs(pos.X - c.X) <= s.X / 2 + CFG.FM and mabs(pos.Z - c.Z) <= s.Z / 2 + CFG.FM
end
local function gFC()
  if ST.cf then return ST.cf.Center end
  local r = HR()
  return (r and r.Position) or V3z
end

-- FIELD HASH for multi-field support
local function fldHashFn()
  local f = ST.cf
  if not f then return "unknown" end
  local c = f.Center
  return fmt("%.0f_%.0f", c.X / 50, c.Z / 50)
end
local function swFld()
  local nh = fldHashFn()
  if nh ~= fldHash then
    if qTables[fldHash] then qTables[fldHash] = qT end
    if pHTables[fldHash] then pHTables[fldHash] = pH end
    fldHash = nh
    qT = qTables[fldHash] or {}
    pH = pHTables[fldHash] or {}
    -- Reset flame spiral on field change
    sprC = nil; sprA = 0; sprR = 0
  end
end

-- FIELD DETECTOR
local function detF()
  local r = HR()
  if not r then return end
  local mp = r.Position
  local z = cfc(W, "FlowerZones")
  if z then
    local be, bd = nil, 1e9
    for _, zn in ipairs(z:GetChildren()) do
      if zn:IsA("BasePart") then
        local dSv = d2Sq(mp, zn.Position)
        local s = zn.Size
        if mabs(mp.X - zn.Position.X) <= s.X / 2 + 20 and mabs(mp.Z - zn.Position.Z) <= s.Z / 2 + 20 then
          if dSv < bd then bd = dSv; be = zn end
        end
      end
    end
    if be then
      ST.cf = { part = be, Center = be.Position, Size = be.Size }
      if CFG.MFS then swFld() end
      return
    end
  end
  local fl = cfc(W, "Flowers")
  if fl then
    local mnX, mxX, mnZ, mxZ = 1e9, -1e9, 1e9, -1e9
    for _, f in ipairs(fl:GetChildren()) do
      if f:IsA("BasePart") then
        local p = f.Position
        if p.X < mnX then mnX = p.X end
        if p.X > mxX then mxX = p.X end
        if p.Z < mnZ then mnZ = p.Z end
        if p.Z > mxZ then mxZ = p.Z end
      end
    end
    if mnX < 1e9 then
      ST.cf = {
        part = nil,
        Center = V3((mnX + mxX) / 2, mp.Y, (mnZ + mxZ) / 2),
        Size = V3(mabs(mxX - mnX) + 10, 1, mabs(mxZ - mnZ) + 10)
      }
      if CFG.MFS then swFld() end
      return
    end
  end
  if ST.ar then
    ST.cf = { part = nil, Center = ST.ar.Position, Size = V3(ST.arR * 3, 1, ST.arR * 3) }
    if CFG.MFS then swFld() end
  end
end

-- AREA RING
local function fAR()
  local p = cfc(W, "Particles")
  if p then
    for _, o in ipairs(p:GetChildren()) do
      if o.Name == "AreaRing" and o:IsA("BasePart") then
        ST.ar = o
        ST.arR = (o.Size.X + o.Size.Z) / 4
        if ST.arR < 5 then ST.arR = CFG.ARD end
        return
      end
    end
  end
  local a = W:FindFirstChild("AreaRing")
  if a and a:IsA("BasePart") then
    ST.ar = a
    ST.arR = (a.Size.X + a.Size.Z) / 4
    if ST.arR < 5 then ST.arR = CFG.ARD end
  else
    ST.ar = nil
    ST.arR = CFG.ARD
  end
end

-- CROSSHAIRS
local function cM(a, b, tol)
  local t = tol or CFG.CT
  return mabs(a.R * 255 - b.R * 255) <= t
     and mabs(a.G * 255 - b.G * 255) <= t
     and mabs(a.B * 255 - b.B * 255) <= t
end
local function isP(p)
  local ok, c = pcall(function() return p.Color end)
  if ok and c and cM(c, CFG.PU) then return true end
  local ok2, bc = pcall(function() return p.BrickColor.Color end)
  return ok2 and bc and cM(bc, CFG.PU)
end
local function isG(p)
  if not p or p.Name ~= "Crosshair" then return false end
  local ok, c = pcall(function() return p.Color end)
  if not ok then return false end
  return mabs(c.R - CFG.GH.R) < 0.08 and mabs(c.G - CFG.GH.G) < 0.08 and mabs(c.B - CFG.GH.B) < 0.08
end
local function uGS()
  for _, ch in ipairs(chs) do
    if not ch.c and ch.p.Parent then
      if isG(ch.p) and not ch.wG then
        ch.wG = true
        ch.gT = tick()
        if not ch.iP and ST.pX and not ST.prf then ST.cg = ST.cg + 1 end
      end
    end
  end
end
local function aCH(o)
  if o.Name ~= "Crosshair" or not o:IsA("BasePart") then return end
  for _, ch in ipairs(chs) do if ch.p == o then return end end
  if not o.Parent then return end
  tins(chs, { p = o, sT = tick(), c = false, iP = isP(o), wG = isG(o) })
  chDrty = true
end
local function connCH()
  local pt = cfc(W, "Particles")
  if not pt then addErr("Particles not found for CH connect — retrying in heartbeat"); return end
  pt.DescendantAdded:Connect(aCH)
  pt.DescendantRemoving:Connect(function(o)
    for i = #chs, 1, -1 do if chs[i].p == o then trem(chs, i); chDrty = true; break end end
  end)
  for _, o in ipairs(pt:GetDescendants()) do aCH(o) end
  addErr("CH connections: OK, " .. #chs .. " initial crosshairs")
end
safeCall("connCH", connCH)

local function clnCH()
  local rem = 0
  for i = #chs, 1, -1 do
    if not chs[i].p.Parent or chs[i].c then trem(chs, i); rem = rem + 1 end
  end
  if rem > 0 then chDrty = true end
end
local function clnCHFull()
  for i = #chs, 1, -1 do
    if not chs[i].p.Parent or chs[i].c then trem(chs, i); chDrty = true end
  end
end
local function gUCH(pO, rO, iG)
  local L_ = {}
  for _, ch in ipairs(chs) do
    if not ch.c and ch.p.Parent then
      if not (not iG and ch.wG) then
        if (pO and ch.iP) or (rO and not ch.iP) or (not pO and not rO) then
          tins(L_, ch)
        end
      end
    end
  end
  tsrt(L_, function(a, b) return a.sT < b.sT end)
  return L_
end
local function gACH(pO, rO)
  local L_ = {}
  for _, ch in ipairs(chs) do
    if not ch.c and ch.p.Parent then
      if (pO and ch.iP) or (rO and not ch.iP) or (not pO and not rO) then
        tins(L_, ch)
      end
    end
  end
  tsrt(L_, function(a, b) return a.sT < b.sT end)
  return L_
end

-- DIAGONALS + TP
local function cmpDiag()
  local all = gACH(false, false)
  if #all < 3 then return nil end
  local groups, used = {}, {}
  for i = 1, #all - 2 do
    if not used[i] then
      for j = i + 1, #all - 1 do
        if not used[j] then
          if all[j].sT - all[i].sT <= CFG.DMT then
            for k = j + 1, #all do
              if not used[k] then
                if all[k].sT - all[i].sT <= CFG.DMT then
                  local p1, p2, p3 = all[i].p.Position, all[j].p.Position, all[k].p.Position
                  if mabs(mabs((p2 - p1).Unit:Dot((p3 - p1).Unit)) - 1) < CFG.DMA then
                    used[i], used[j], used[k] = true, true, true
                    local c = (p1 + p2 + p3) / 3
                    local d1 = (p1 - c).Magnitude
                    local d2_ = (p2 - c).Magnitude
                    local d3_ = (p3 - c).Magnitude
                    local a, b, cc = all[i], all[j], all[k]
                    if d1 >= d2_ and d1 >= d3_ then cc, a, b = all[i], all[j], all[k]
                    elseif d2_ >= d1 and d2_ >= d3_ then a, cc, b = all[i], all[j], all[k] end
                    tins(groups, { r1 = a, r2 = b, pr = cc, center = c })
                    if #groups >= 1 then break end
                  end
                end
              end
            end
          end
          if #groups >= 1 then break end
        end
      end
      if #groups >= 1 then break end
    end
  end
  return #groups > 0 and groups or nil
end
local function cmpRefDiag()
  local all = gACH(false, false)
  if #all < 3 then return nil end
  local groups, used = {}, {}
  for i = 1, #all - 2 do
    if not used[i] then
      for j = i + 1, #all - 1 do
        if not used[j] then
          if all[j].sT - all[i].sT <= CFG.RDMT then
            for k = j + 1, #all do
              if not used[k] then
                if all[k].sT - all[i].sT <= CFG.RDMT then
                  local p1, p2, p3 = all[i].p.Position, all[j].p.Position, all[k].p.Position
                  if mabs(mabs((p2 - p1).Unit:Dot((p3 - p1).Unit)) - 1) < CFG.RDMA then
                    used[i], used[j], used[k] = true, true, true
                    local c = (p1 + p2 + p3) / 3
                    local d1 = (p1 - c).Magnitude
                    local d2_ = (p2 - c).Magnitude
                    local d3_ = (p3 - c).Magnitude
                    local a, b, cc = all[i], all[j], all[k]
                    if d1 >= d2_ and d1 >= d3_ then cc, a, b = all[i], all[j], all[k]
                    elseif d2_ >= d1 and d2_ >= d3_ then a, cc, b = all[i], all[j], all[k] end
                    tins(groups, { r1 = a, r2 = b, pr = cc })
                    if #groups >= 1 then break end
                  end
                end
              end
            end
          end
          if #groups >= 1 then break end
        end
      end
      if #groups >= 1 then break end
    end
  end
  return #groups > 0 and groups or nil
end
local function cmpTP()
  if not ST.pX or ST.prf then return nil end
  local all = gUCH(false, false, true)
  if #all < 3 then return nil end
  local G_ = {}
  local i = 1
  while i <= #all - 2 do
    local a, b, c = all[i], all[i + 1], all[i + 2]
    if not a.iP and not b.iP and c.iP then
      if c.sT - a.sT <= 2 then
        tins(G_, { r1 = a, r2 = b, pr = c })
        i = i + 3
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end
  return #G_ > 0 and G_ or nil
end
local function gDG() if chDrty then cDiag = cmpDiag(); chDrty = false end; return cDiag end
local function gRD() if chDrty then cRefDiag = cmpRefDiag(); chDrty = false end; return cRefDiag end
local function gTP() if chDrty then cTP = cmpTP(); chDrty = false end; return cTP end

-- CH AVOIDANCE + GO TO
local function cAT(fP, tP)
  if not ST.pX or ST.prf then return nil end
  local mX, mZ = fP.X, fP.Z
  local dX, dZ = tP.X, tP.Z
  local tx, ty = dX - mX, dZ - mZ
  local tMSq = tx * tx + ty * ty
  if tMSq < 1 then return nil end
  local invM = 1 / tMSq ^ 0.5
  local tDX, tDZ = tx * invM, ty * invM
  local th = {}
  for _, ch in ipairs(chs) do
    if not ch.c and ch.p.Parent and not ch.iP and not ch.wG then
      local cX, cZ = ch.p.Position.X, ch.p.Position.Z
      local tcX, tcZ = cX - mX, cZ - mZ
      local dSq = tcX * tcX + tcZ * tcZ
      if dSq < CFG.CARS and dSq > 1 then
        local invD = 1 / dSq ^ 0.5
        local udX, udZ = tcX * invD, tcZ * invD
        local dot = udX * tDX + udZ * tDZ
        if dot > CFG.CAD then
          local cross = mabs(tcX * tDZ - tcZ * tDX)
          if cross < CFG.CARS ^ 0.5 then
            tins(th, { ch = ch, cX = cX, cZ = cZ, dSq = dSq })
          end
        end
      end
    end
  end
  if #th == 0 then return nil end
  tsrt(th, function(a, b) return a.dSq < b.dSq end)
  local t_ = th[1]
  local udX, udZ = (t_.cX - mX) / t_.dSq ^ 0.5, (t_.cZ - mZ) / t_.dSq ^ 0.5
  local p1X, p1Z = -udZ, udX
  local p2X, p2Z = udZ, -udX
  local bpX = (p2X * tDX + p2Z * tDZ >= p1X * tDX + p1Z * tDZ) and p2X or p1X
  local bpZ = (p2X * tDX + p2Z * tDZ >= p1X * tDX + p1Z * tDZ) and p2Z or p1Z
  local apX, apZ = t_.cX + bpX * CFG.CAS, t_.cZ + bpZ * CFG.CAS
  ST.ca = ST.ca + 1
  return cP(V3(apX, fP.Y, apZ))
end

local function goTo(tP, aR, to, sk)
  local arriveRadius = aR or aP.arr
  local timeout = mmin(to or aP.mt, 12)
  if tP == V3z then return false end
  local r = HR()
  local h_ = HM()
  if not r or not h_ then return false end
  tP = cP(tP, sk)
  if tP == V3z then
    local c = gFC()
    if c == V3z then return false end
    tP = c
  end
  local oTX, oTZ = tP.X, tP.Z
  local oT = V3(oTX, r.Position.Y, oTZ)
  local cMo = oT
  local av = cAT(r.Position, oT)
  if av then cMo = V3(av.X, r.Position.Y, av.Z) end
  h_:MoveTo(cMo)
  local t0 = tick()
  local lM = tick()
  local lA = tick()
  while tick() - t0 < timeout do
    twait(0.04)
    if not ST.en or ST.int then return false end
    r = HR()
    if not r then return false end
    if p2Sq(r.Position.X, r.Position.Z, oTX, oTZ) <= arriveRadius * arriveRadius then return true end
    if not sk then
      for _, ch in ipairs(chs) do
        if not ch.c and ch.p.Parent and not ch.wG and not ch.iP then
          if p2Sq(r.Position.X, r.Position.Z, ch.p.Position.X, ch.p.Position.Z) <= CFG.CIS then
            return "CH_NEARBY"
          end
        end
      end
    end
    if tick() - lA >= 0.15 then
      lA = tick()
      local na = cAT(r.Position, oT)
      cMo = (na and V3(na.X, r.Position.Y, na.Z)) or oT
    end
    if cMo ~= oT and p2Sq(r.Position.X, r.Position.Z, cMo.X, cMo.Z) <= 16 then
      local na = cAT(r.Position, oT)
      cMo = (na and V3(na.X, r.Position.Y, na.Z)) or oT
    end
    if tick() - lM >= 0.3 then
      h_ = HM()
      if h_ then h_:MoveTo(cMo) end
      lM = tick()
    end
  end
  return false
end

-- FLAMES
local function iFD(flm)
  local pf = flm:FindFirstChild("PF")
  if pf then
    local co = nil
    if pf:IsA("ColorSequenceValue") then
      local sq = pf.Value
      if sq and sq.Keypoints and #sq.Keypoints > 0 then
        local k = sq.Keypoints[1]
        if k then co = k.Value end
      end
    elseif pf:IsA("Color3Value") then
      co = pf.Value
    elseif pf:IsA("BasePart") then
      local ok, c = pcall(function() return pf.Color end)
      if ok then co = c end
    end
    if co then return co.G < 0.3 and co.B > 0.5 end
  end
  local ok, c = pcall(function() return flm.Color end)
  return ok and c and c.G < 0.3 and c.B > 0.5
end

local function sFl()
  local n = tick()
  local fl = cfc(W, "PlayerFlames")
  if fl then
    local seen = {}
    for _, f in ipairs(fl:GetChildren()) do
      if f.Name:sub(1, 3) == "Flm" then
        seen[f] = true
        if not fls[f] then
          fls[f] = { sT = n, iD = iFD(f), hit = false }
        else
          fls[f].iD = iFD(f)
        end
      end
    end
    local rem = {}
    for f in pairs(fls) do if not seen[f] then rem[#rem + 1] = f end end
    for _, f in ipairs(rem) do fls[f] = nil end
  end
end

local function tHF()
  if not ST.en then return false end
  local r = HR()
  if not r then return false end
  local n = tick()
  for fl, data in pairs(fls) do
    if not data.hit and not data.iD and fl.Parent then
      if n - data.sT >= CFG.FHA and p2Sq(r.Position.X, r.Position.Z, fl.Position.X, fl.Position.Z) <= CFG.FHDS then
        ST.int = true
        local bg = r:FindFirstChild("AI_BG")
        if not bg then
          bg = Instance.new("BodyGyro")
          bg.Name = "AI_BG"
          bg.MaxTorque = V3(0, 40000, 0)
          bg.P = 10000
          bg.D = 500
          bg.Parent = r
        end
        local dir = (fl.Position - r.Position)
        dir = V3(dir.X, 0, dir.Z)
        if dir.Magnitude > 0.1 then
          bg.CFrame = CFrame.new(r.Position, r.Position + dir)
        end
        twait(0.1)
        local e = cfc(RS, "Events")
        local tce = e and e:FindFirstChild("ToolCollect")
        if tce then
          pcall(tce.FireServer, tce)
          twait(0.1)
        else
          pcall(function()
            local cam = workspace.CurrentCamera
            local vp = cam.ViewportSize
            V:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 1)
            twait(0.05)
            V:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 1)
          end)
        end
        twait(0.15)
        if bg then bg:Destroy() end
        data.hit = true
        ST.fl = ST.fl + 1
        twait(0.2)
        ST.int = false
        return true
      end
    end
  end
  return false
end

local function gFCC()
  local pX, pZ, cnt = 0, 0, 0
  for fl in pairs(fls) do
    if fl.Parent then pX = pX + fl.Position.X; pZ = pZ + fl.Position.Z; cnt = cnt + 1 end
  end
  if cnt == 0 then return nil end
  return cP(V3(pX / cnt, 0, pZ / cnt))
end
local function gFD()
  local r = HR()
  if not r then return 0 end
  local cnt = 0
  for fl in pairs(fls) do
    if fl.Parent and p2Sq(r.Position.X, r.Position.Z, fl.Position.X, fl.Position.Z) <= CFG.FDRS then
      cnt = cnt + 1
    end
  end
  return cnt
end
local sprA, sprR, sprC = 0, 0, nil
local function gST()
  if not sprC or tick() - (ST.lsc or 0) > 2 then
    ST.lsc = tick()
    sprC = gFCC()
    if sprC then sprA = 0; sprR = 1 end
  end
  if not sprC then return nil end
  local step = (gFD() > 8 and 0.8) or (gFD() > 4 and 1.6) or 3.5
  sprA = sprA + step / mmax(sprR, 1)
  sprR = 1 + sprA * step / (2 * mpi)
  if sprR > CFG.SRM * 3 then sprA = 0; sprR = 1 end
  local tX, tZ = sprC.X + mcos(sprA) * sprR, sprC.Z + msin(sprA) * sprR
  local target = cP(V3(tX, 0, tZ))
  local leaving = true
  for fl in pairs(fls) do
    if fl.Parent and p2Sq(tX, tZ, fl.Position.X, fl.Position.Z) <= aP.mcd * aP.mcd then
      leaving = false; break
    end
  end
  if leaving then
    local r2 = HR()
    local best, brSv = nil, aP.mcd * aP.mcd + 1
    for fl in pairs(fls) do
      if fl.Parent then
        local dSv = p2Sq(r2.Position.X, r2.Position.Z, fl.Position.X, fl.Position.Z)
        if dSv < brSv then brSv = dSv; best = fl end
      end
    end
    if best then return cP(best.Position) end
  end
  return target
end

-- TOKENS
local function addTI(p, id)
  if not tkBT[id] then tkBT[id] = {} end
  tins(tkBT[id], p)
end
local function remTI(p, id)
  local arr = tkBT[id]
  if not arr then return end
  for i = 1, #arr do if arr[i] == p then trem(arr, i); break end end
end
local function rT(o)
  if o.Name ~= "C" or not o:IsA("BasePart") or tks[o] or tick() < ST.ig then return end
  local fr = o:FindFirstChild("FrontDecal")
  if not fr or not fr:IsA("Decal") then return end
  local id = gTID(fr.Texture)
  if not id or AV[id] then return end
  local df = TK[id]
  if not df then return end
  local r = HR()
  local isDup = r and (o.Position.Y - r.Position.Y) > 5
  local life = df.b * CFG.TLM
  if isDup then life = life * (2 + 0.05 * (CFG.DLM - 1)) end
  tks[o] = { id = id, n = df.n, p = df.p, mo = df.mo or false, sT = tick(), l = life, d = isDup, c = false }
  addTI(o, id)
  if isDup and not ST.sa then dT[o] = true end
end

local function flushTQ()
  if tQLock then return end
  tQLock = true
  local q = tQ
  tQ = {}
  for _, o in ipairs(q) do
    local ok, err = pcall(rT, o)
    if not ok then addErr("rT failed: " .. tostring(err)) end
  end
  tQLock = false
end
W.DescendantAdded:Connect(function(o) tins(tQ, o) end)
for _, o in ipairs(W:GetDescendants()) do tins(tQ, o) end
flushTQ()
game.DescendantRemoving:Connect(function(o)
  if tks[o] then
    if tks[o].c then ST.tk = ST.tk + 1 end
    remTI(o, tks[o].id)
    tks[o] = nil
    dT[o] = nil
  end
end)

-- BUFFS
local rps = nil
local function fRPS()
  local e = cfc(RS, "Events")
  if e then rps = e:FindFirstChild("RetrievePlayerStats") end
end
fRPS()
local function flatBuffs(t, d)
  if _type(t) ~= "table" then return end
  local bid = rawget(t, "BuffID")
  if bid then d[bid] = t end
  for _, v in pairs(t) do flatBuffs(v, d) end
end
local function sAB()
  if not rps then fRPS(); if not rps then return end end
  local ok, res = pcall(rps.InvokeServer, rps)
  if not ok or _type(res) ~= "table" then return end
  local fdict = {}
  flatBuffs(res, fdict)
  local pb = fdict[CFG.PB]
  if pb and rawget(pb, "Removed") ~= true then
    local val = tonum(pb.Value) or 0
    if tonum(pb.Start) ~= ST.psS then
      ST.psS = tonum(pb.Start) or 0
      ST.pd = tonum(pb.Dur) or 60
      ST.pl = os.clock()
    end
    ST.ps = mmin(CFG.PM, mround(val / CFG.PK))
    ST.pv = val
    ST.pX = (ST.ps >= CFG.PM)
  else
    ST.ps = 0; ST.pv = 0; ST.pX = false
  end
  if ST.pl > 0 then
    ST.plf = mmax(0, ST.pd - (os.clock() - ST.pl))
    ST.prf = ST.pX and (ST.plf <= CFG.PR)
  end
  local pmb = fdict[CFG.PMID]
  ST.pma = (pmb and rawget(pmb, "Removed") ~= true)
  if ST.pma and ST.ar then ST.pmP = ST.ar.Position end
  local fFH = false
  for _, v in pairs(fdict) do
    if rawget(v, "Src") == "FlameHeat" then
      ST.fh = tonum(rawget(v, "Value") or 0); fFH = true; break
    end
  end
  if not fFH then ST.fh = 0 end
  local fSc = false
  for _, v in pairs(fdict) do
    if rawget(v, "Src") == "Scorching Star Aura" then
      ST.sc = tonum(rawget(v, "Combo") or 0); fSc = true; break
    end
  end
  if not fSc then ST.sc = 0 end
  ST.sa = (ST.sc > 0)
  local fXF = false
  for _, v in pairs(fdict) do
    if rawget(v, "Src") == "X-Flame Aura" then
      ST.xf = tonum(rawget(v, "Combo") or 0); fXF = true; break
    end
  end
  if not fXF then ST.xf = 0 end
  ST.xe = (ST.xf >= 20)
end

-- PETALS + SMILE + HPS
local function sPt()
  pts = {}
  if not ST.en or not ST.cf then return end
  local pt = cfc(W, "Particles")
  if not pt then return end
  local r = HR()
  if not r then return end
  for _, o in ipairs(pt:GetChildren()) do
    if o.Name == "PetalPart" and o:IsA("BasePart") and iF(o.Position) then
      local cn = nil
      for n, co in pairs(PCOL) do
        if (co.R - o.Color.R) ^ 2 + (co.G - o.Color.G) ^ 2 + (co.B - o.Color.B) ^ 2 < 0.002 then
          cn = n; break
        end
      end
      if cn and PPRIO[cn] then
        tins(pts, { p = o, n = cn, pr = PPRIO[cn], dSq = p2Sq(r.Position.X, r.Position.Z, o.Position.X, o.Position.Z) })
      end
    end
  end
  if #pts ~= ptPrevCnt then ptDirty = true; ptPrevCnt = #pts end
  if ptDirty then
    tsrt(pts, function(a, b)
      if a.pr ~= b.pr then return a.pr < b.pr end
      return a.dSq < b.dSq
    end)
    ptDirty = false
  end
end

local function sSm()
  local n = tick()
  ST.smT = nil; ST.smL = 0
  local bp, bdSv, brem = nil, 1e9, 0
  local r = HR()
  if not r then return end
  local rp = ST.ar and ST.ar.Position
  local smToks = tkBT[CFG.SMI]
  if not smToks then return end
  for _, p in ipairs(smToks) do
    local t = tks[p]
    if t and not t.c and p.Parent then
      local rem = t.l - (n - t.sT)
      if rem <= CFG.SMR and rem > 0 then
        local tk = false
        if rp then
          if d2Sq(p.Position, rp) <= ST.arR * ST.arR * 2.25 then tk = true end
        else
          tk = true
        end
        local dc = 0
        for id, arr in pairs(tkBT) do
          for _, pp in ipairs(arr) do
            local tt = tks[pp]
            if tt and not tt.c and tt.d and pp.Parent and d2Sq(r.Position, pp.Position) < CFG.SCRS then
              dc = dc + 1
            end
          end
        end
        if dc >= CFG.SDN and tk then
          local dSv = d2Sq(r.Position, p.Position)
          if dSv < bdSv then bp = p; bdSv = dSv; brem = rem end
        end
      end
    end
  end
  if bp then ST.smT = bp; ST.smL = brem; ST.int = true end
end

local hL = nil
local function gHP()
  if not hL or not hL.Parent then
    local sg = G:FindFirstChild("ScreenGui")
    if sg then
      local mh = sg:FindFirstChild("MeterHUD")
      if mh then
        local hm = mh:FindFirstChild("HoneyMeter")
        if hm then
          local bar = hm:FindFirstChild("Bar")
          if bar then hL = bar:FindFirstChild("PerSecLabel") end
        end
      end
    end
  end
  if hL and hL:IsA("TextLabel") then
    local tx = hL.Text:gsub(",", ""):gsub(" ", ""):upper()
    local n, sf = tx:match("([%d.]+)([KM]?)")
    if n then
      local v = tonum(n) or 0
      if sf == "K" then v = v * 1000 elseif sf == "M" then v = v * 1000000 end
      return v
    end
  end
  return 0
end
local function sMH() ST.lmh = mmax(gHP(), 1) end
local function gMR()
  local cur = mmax(gHP(), 1)
  local pct = (cur - ST.lmh) / ST.lmh
  ST.lmh = cur
  if pct > 0.05 then return 8 + mfloor(pct * 50)
  elseif pct > 0.01 then return 4 + mfloor(pct * 100)
  elseif pct > -0.01 then return 0
  elseif pct > -0.05 then return -(2 + mfloor(-pct * 50))
  else return -(6 + mfloor(-pct * 30)) end
end
local function uH()
  local n = tick()
  local hps = gHP()
  if hps > 0 then tins(hH, { time = n, hps = hps }) end
  local cut = n - 120
  while #hH > 0 and hH[1].time < cut do trem(hH, 1) end
  if ST.al and ST.al ~= S.IN then
    local r = HR()
    local flCnt = 0
    for _ in pairs(fls) do flCnt = flCnt + 1 end
    tins(aH, { time = n, action = ST.al, pos = (r and r.Position) or V3z, phase = ph(), isSc = ST.sa, scPh = scPh(), flCnt = flCnt, chCnt = #chs })
  end
  while #aH > 0 and aH[1].time < cut do trem(aH, 1) end
  if n - (ST.lps or 0) >= 10 then
    ST.lps = n
    local sum, cn = 0, 0
    for _, e in ipairs(hH) do sum = sum + e.hps; cn = cn + 1 end
    local av = cn > 0 and (sum / cn) or 0
    if av > 0 then
      local ac = {}
      for _, e in ipairs(aH) do
        tins(ac, { action = e.action, pos = e.pos, to = e.time - (n - 120), phase = e.phase, isSc = e.isSc, scPh = e.scPh, flCnt = e.flCnt, chCnt = e.chCnt })
      end
      tins(pH, { hps = av, actions = ac, timestamp = n, ctx = { phase = ph(), scorch = ST.sa and 1 or 0, scPh = scPh() } })
      tsrt(pH, function(a, b) return a.hps > b.hps end)
      while #pH > CFG.PMX do trem(pH) end
      if av > bHP then bHP = av end
      safeCall("savePatterns", function()
        if writefile then writefile(CFG.PF, H:JSONEncode(pH)) end
      end)
    end
  end
end

-- PATTERN GEN
local function gPatt()
  if #pH < CFG.PMFG then return end
  local sorted = {}
  for _, p in ipairs(pH) do tins(sorted, p) end
  tsrt(sorted, function(a, b) return a.hps > b.hps end)
  local p1 = sorted[1]
  local p2 = sorted[mrnd(2, mmin(5, #sorted))]
  local na = {}
  local half1 = mfloor(#p1.actions / 2)
  for i = 1, half1 do
    tins(na, { action = p1.actions[i].action, pos = p1.actions[i].pos, phase = p1.actions[i].phase, isSc = p1.actions[i].isSc, scPh = p1.actions[i].scPh })
  end
  for i = half1 + 1, #p2.actions do
    tins(na, { action = p2.actions[i].action, pos = p2.actions[i].pos, phase = p2.actions[i].phase, isSc = p2.actions[i].isSc, scPh = p2.actions[i].scPh })
  end
  if #na > 2 then
    local mi = mrnd(1, #na)
    local aa = { "go_crosshair", "go_purple", "go_tokenlink", "go_petal", "go_token_near", "patrol_ring", "patrol_random", "go_smile", "go_target_practice_purple", "go_scorching_spiral", "go_xflame_center" }
    na[mi].action = aa[mrnd(1, #aa)]
  end
  local gen = { hps = 0, actions = na, timestamp = tick(), ctx = p1.ctx or {}, generated = true }
  tins(gP, gen)
  while #gP > CFG.PGM do trem(gP, 1) end
  tins(pH, gen)
  tsrt(pH, function(a, b) return a.hps > b.hps end)
  while #pH > CFG.PMX do trem(pH) end
end
local function gPB(action, pos)
  if #pH == 0 then return 0 end
  local p_ = ph()
  local isSc = ST.sa
  local scP = scPh()
  local be = 0
  for _, p in ipairs(pH) do
    for _, pa in ipairs(p.actions) do
      if pa.action == action then
        if d2Sq(pos, pa.pos) < 100 then
          local ms = ((pa.phase == p_) and 2 or 1) * ((pa.isSc == isSc) and 2 or 1) * ((pa.scPh == scP) and 1.5 or 1) * (p.generated and 1.3 or 1)
          if ms > be then be = ms end
        end
      end
    end
  end
  return 15 * be
end

-- Q-LEARNING
local function gQ(s, a) return (qT[s] and qT[s][a]) or 0 end
local function sQ(s, a, v)
  if not qT[s] then qT[s] = {} end
  qT[s][a] = v
end
local function decayE() eps = mmax(CFG.EM, eps * CFG.ED) end
local function eS()
  local r = HR()
  if not r then sCache._k = nil; return "dead" end
  local p_ = ph()
  local scP = scPh()
  local h = fmt("%s|%s|%d|%d|%d|%s|%s", p_, scP, #chs, ST.ps, ST.sc, ST.smT and "1" or "0", ST.xe and "1" or "0")
  if sCache._k == h then return sCache._v end
  sCache._k = h
  local tlD = "none"
  local tlArr = tkBT[1629547638]
  if tlArr then
    for _, p in ipairs(tlArr) do
      local t = tks[p]
      if t and not t.c and p.Parent then
        local dSv = d2Sq(r.Position, p.Position)
        if dSv < 400 then tlD = "close" elseif dSv < 3600 then tlD = "far" end
      end
    end
  end
  local prN = mmin(3, #gUCH(true, false))
  local rN = mmin(3, #gUCH(false, true))
  local sU = (ST.smT ~= nil)
  local hp_ = (#pts > 0)
  local nT = false
  local n = tick()
  for p, t in pairs(tks) do
    if not t.c and p.Parent and (t.l - (n - t.sT)) > 1 and d2Sq(r.Position, p.Position) < 900 then
      nT = true; break
    end
  end
  local zn = "mid"
  if ST.cf then
    local c = ST.cf.Center
    local s = ST.cf.Size
    if s.X > 0 and s.Z > 0 then
      local rx = mabs(r.Position.X - c.X) / (s.X / 2)
      local rz = mabs(r.Position.Z - c.Z) / (s.Z / 2)
      if rx > 0.7 or rz > 0.7 then zn = "edge"
      elseif rx < 0.3 and rz < 0.3 then zn = "center" end
    end
  end
  local chT = "none"
  if ST.pX and not ST.prf then
    local ct = 0
    for _, ch in ipairs(chs) do
      if not ch.c and ch.p.Parent and not ch.iP and not ch.wG and p2Sq(r.Position.X, r.Position.Z, ch.p.Position.X, ch.p.Position.Z) < CFG.CNSS then
        ct = ct + 1
      end
    end
    if ct > 2 then chT = "many" elseif ct > 0 then chT = "some" end
  end
  local dg = gDG()
  local res = fmt("PH:%s|SC:%s|TL:%s|CH:%d|PR:%d|SM:%s|NT:%s|Z:%s|CT:%s|PT:%s|XF:%s|DG:%s",
    p_, scP, tlD, rN, prN, (sU and "1" or "0"), (nT and "1" or "0"), zn, chT, (hp_ and "1" or "0"),
    (ST.xe and "1" or "0"), (dg and #dg > 0 and "1" or "0"))
  sCache._v = res
  return res
end
local function gSWP(action)
  if ST.la == action then return 1 end
  local swC = 0
  for _, ra in ipairs(rA) do if ra.action == action then swC = swC + 1 end end
  return swC > 0 and CFG.SWP or 1
end
local function uQ(state, action, reward, nextState)
  local rr = HR()
  local mr = gMR()
  local tR = mr + reward + gPB(action, (rr and rr.Position) or V3z)
  local mN = 0
  for _, a_ in ipairs(ACTS) do
    if a_.condition() then
      local q = gQ(nextState, a_.name)
      if q > mN then mN = q end
    end
  end
  local penalty = gSWP(action)
  local nw = gQ(state, action) + CFG.AL * (tR * penalty + CFG.GA * mN - gQ(state, action))
  sQ(state, action, nw)
  ST.tr = ST.tr + tR
  ST.dc = ST.dc + 1
  decayE()
end

-- ACTION SYSTEM
ACTS = {}
local function regA(name, priority, cond)
  local a = { name = name, priority = priority, condition = cond }
  tins(ACTS, a)
  tsrt(ACTS, function(a, b) return a.priority > b.priority end)
end
local function bA()
  ACTS = {}
  local p_ = ph()
  if p_ == S.PHX and afTP then regA("go_target_practice_purple", 98, function() return true end) end
  if p_ == S.PHX and afPL then regA("go_purple", 97, function() return true end) end
  if p_ == S.PHR and gRD() ~= nil then regA("go_crosshair_refresh_diagonal", 96, function() return true end) end
  if p_ == S.PHR and #gACH(false, false) > 0 then regA("go_crosshair_refresh_all", 95, function() return true end) end
  if afCH then regA("go_crosshair", 94, function() return true end) end
  if afTL then regA("go_tokenlink", 93, function() return true end) end
  if afUg then regA("go_urgent_token", 92, function() return true end) end
  if afSc then regA("go_scorching_spiral", 80, function() return true end) end
  if afSm then regA("go_smile", 75, function() return true end) end
  if afPM and afSm then regA("go_smile_area", 70, function() return true end) end
  if afPM and afDTP then regA("go_dup_area", 69, function() return true end) end
  if afXF then
    regA("go_xflame_ch", 65, function() return true end)
    regA("go_xflame_center", 64, function() return true end)
  end
  if afPt then regA("go_petal", 60, function() return true end) end
  if afTk then
    regA("go_token_best", 55, function() return true end)
    regA("go_token_near", 54, function() return true end)
  end
  if afDTP then regA("go_dup_tp", 53, function() return true end) end
  regA("patrol_ring", 10, function() return true end)
  if p_ == S.PHB then regA("patrol_random", 9, function() return true end) end
end
local function cA()
  bA()
  if #ACTS == 0 then return "patrol_ring" end
  if mrnd() < eps then
    local c = {}
    for _, a in ipairs(ACTS) do if a.condition() then tins(c, a) end end
    if #c > 0 then return c[mrnd(1, #c)].name end
  end
  local s_ = eS()
  local bA_, bQ = ACTS[1].name, gQ(s_, ACTS[1].name)
  for i = 2, #ACTS do
    if ACTS[i].condition() then
      local q = gQ(s_, ACTS[i].name)
      if q > bQ then bA_ = ACTS[i].name; bQ = q end
    end
  end
  return bA_
end
local function tA(action, success)
  if not aSt[action] then aSt[action] = { a = 0, s = 0 } end
  local s = aSt[action]; s.a = s.a + 1
  if success then s.s = s.s + 1 end
end
local function rAS(action)
  tins(rA, { action = action, time = tick() })
  while #rA > 5 do trem(rA, 1) end
  ST.la = action
end

-- EXECUTE
local function eoR(tP)
  if not ST.ar or not ST.ar.Parent then return tP end
  local dir = (tP - ST.ar.Position).Unit
  return cP(V3(ST.ar.Position.X + dir.X * ST.arR, 0, ST.ar.Position.Z + dir.Z * ST.arR))
end
local function gSDA()
  local r = HR()
  if not r then return end
  local rp = ST.ar and ST.ar.Position
  if not rp then return end
  local bpSm, bdSm, bpTp, bdTp = nil, 1e9, nil, 1e9
  local smArr = tkBT[CFG.SMI]
  local tpArr = tkBT[CFG.TPI]
  if smArr then
    for _, p in ipairs(smArr) do
      local t = tks[p]
      if t and not t.c and p.Parent and d2Sq(p.Position, rp) <= ST.arR * ST.arR * 2.25 then
        local dSv = d2Sq(r.Position, p.Position)
        if dSv < bdSm then bdSm = dSv; bpSm = p end
      end
    end
  end
  if tpArr then
    for _, p in ipairs(tpArr) do
      local t = tks[p]
      if t and not t.c and p.Parent and t.d and d2Sq(p.Position, rp) <= ST.arR * ST.arR * 2.25 then
        local dSv = d2Sq(r.Position, p.Position)
        if dSv < bdTp then bdTp = dSv; bpTp = p end
      end
    end
  end
  if bpSm and bpTp then
    local n = tick()
    local st = tks[bpSm]
    local smRem = st and (st.l - (n - st.sT)) or 0
    if smRem <= 3 then return bpSm else return bpTp end
  elseif bpSm then return bpSm
  else return bpTp end
end

local function eA(action)
  local r = HR()
  if not r then tA(action, false); rAS(action); return -1 end
  sMH()
  local s_ = true
  local rw = 0
  rAS(action)

  if action == "go_scorching_spiral" then
    local t = gST()
    if not t then s_ = false else ST.al = S.SP; ST.int = false; goTo(t, 2, 2); twait(0.12); rw = 2 end
  elseif action == "go_crosshair_refresh_diagonal" then
    local di = gRD()
    if not di then s_ = false else
      local g = di[1]; local col = 0; ST.int = false
      for _, ch in ipairs({ g.r1, g.r2, g.pr }) do
        if ch.p.Parent and not ch.c and not ch.wG then
          ST.al = S.RD .. " (" .. (col + 1) .. "/3)"
          goTo(ch.p.Position, 4, 4, true)
          if ch.p.Parent then
            ch.c = true
            if ch.iP then ST.pr = ST.pr + 1 else ST.ch = ST.ch + 1 end
            col = col + 1; ST.dg = ST.dg + 1; twait(0.1)
          end
        end
      end
      if ST.ar and ST.ar.Parent then goTo(ST.ar.Position, 6, 4) end
      if col >= 3 then ST.prf = false; ST.rd = ST.rd + 1; ST.al = S.RO .. " диаг" end
    end
  elseif action == "go_crosshair_refresh_all" then
    local all = gACH(false, false)
    if #all == 0 then s_ = false else
      local col = 0; ST.int = false
      for _, ch in ipairs(all) do
        if ch.p.Parent and not ch.c then
          if col >= 3 then break end
          if not ch.wG then
            ST.al = S.RA .. " (" .. (col + 1) .. "/3)"
            local ok = goTo(ch.p.Position, 4, 4, true)
            if ok and ch.p.Parent then
              ch.c = true
              if ch.iP then ST.pr = ST.pr + 1 else ST.ch = ST.ch + 1 end
              col = col + 1; twait(0.1)
            end
          end
        end
      end
      if ST.ar and ST.ar.Parent then ST.al = S.RR; goTo(ST.ar.Position, 6, 4) else goTo(cP(r.Position), 5, 2) end
      if col >= 3 then ST.prf = false; ST.rd = ST.rd + 1; ST.al = S.RO; rw = 40 end
      if col > 0 and rw == 0 then rw = col * 12 end
    end
  elseif action == "go_target_practice_purple" then
    local tp = gTP()
    if not tp then s_ = false else
      ST.int = false
      for _, g in ipairs(tp) do
        if g.pr.p.Parent and not g.pr.c and not g.pr.wG then
          ST.al = S.TP
          local ok = goTo(g.pr.p.Position, 4, 5)
          if ok and g.pr.p.Parent then
            g.pr.c = true; g.r1.c = true; g.r2.c = true; ST.pr = ST.pr + 1; ST.al = S.TM
            local wt = tick()
            while tick() - wt < aP.pst do twait(0.05); if ST.smT or ST.prf or not ST.en then break end end
            rw = rw + 40
          end
        end
      end
    end
  elseif action == "go_smile" then
    local t = ST.smT
    if not t or not t.Parent then ST.smT = nil; s_ = false else
      local td = tks[t]
      if not td or td.c then ST.smT = nil; s_ = false else
        ST.smA = true; ST.al = S.SM; ST.int = false
        local ok = goTo(t.Position, 4, mmin(5, ST.smL - 0.5))
        if ok and t.Parent then
          local st_ = tick()
          while tick() - st_ < aP.tsd do
            twait(0.1)
            if not t.Parent or ST.int then break end
            local hp = HR()
            if hp then hp.CFrame = CFrame.new(t.Position.X, hp.Position.Y, t.Position.Z) end
          end
          td.c = true; ST.smT = nil; ST.sm = ST.sm + 1; ST.smA = false; rw = 45
        end
        if rw <= 0 then ST.smA = false; s_ = false end
      end
    end
  elseif action == "go_smile_area" then
    local t = gSDA()
    if not t then s_ = false else
      local td = tks[t]
      if not td or td.c or td.id ~= CFG.SMI then s_ = false else
        ST.al = S.SR; ST.int = false
        local edge = eoR(t.Position)
        local ok = goTo(edge, 4, 4)
        if ok and t.Parent then
          local st_ = tick()
          while tick() - st_ < aP.tsd do
            twait(0.1)
            if not t.Parent or ST.int then break end
            local hp = HR()
            if hp then hp.CFrame = CFrame.new(t.Position.X, hp.Position.Y, t.Position.Z) end
          end
          td.c = true; ST.sm = ST.sm + 1; rw = 45
        else s_ = false end
      end
    end
  elseif action == "go_dup_area" then
    local t = gSDA()
    if not t then s_ = false else
      local td = tks[t]
      if not td or td.c or td.id ~= CFG.TPI or not td.d then s_ = false else
        ST.al = S.DR; ST.int = false
        local edge = eoR(t.Position)
        local ok = goTo(edge, 4, 4)
        if ok and t.Parent then
          local st_ = tick()
          while tick() - st_ < aP.tsd do
            twait(0.1)
            if not t.Parent or ST.int then break end
            local hp = HR()
            if hp then hp.CFrame = CFrame.new(t.Position.X, hp.Position.Y, t.Position.Z) end
          end
          td.c = true; ST.tk = ST.tk + 1; rw = 15
        else s_ = false end
      end
    end
  elseif action == "go_urgent_token" then
    local n = tick(); local be, bl = nil, 0.3
    for p, t in pairs(tks) do
      if not t.c and p.Parent then
        local rem = t.l - (n - t.sT)
        if rem < bl and rem > 0 then bl = rem; be = p end
      end
    end
    if be then ST.al = S.UG; ST.int = false; local ok = goTo(be.Position, 4, 2)
      if ok and be.Parent then tks[be].c = true; ST.tk = ST.tk + 1; rw = 25 else s_ = false end
    else s_ = false end
  elseif action == "go_purple" then
    local pp = gUCH(true, false)
    if #pp == 0 then s_ = false else
      ST.int = false
      for _, ch in ipairs(pp) do
        if ch.p.Parent and not ch.c and not ST.smT and not ST.prf and not ch.wG then
          local ok = goTo(ch.p.Position, 4, 5)
          if ok and ch.p.Parent then ch.c = true; ST.pr = ST.pr + 1; ST.al = S.PP
            local wt = tick()
            while tick() - wt < aP.pst do twait(0.05); if ST.smT or ST.prf or not ST.en then break end end
            rw = rw + 30
          end
        end
      end
    end
  elseif action == "go_tokenlink" then
    local tlArr = tkBT[1629547638]
    if not tlArr then s_ = false else
      for _, p in ipairs(tlArr) do
        local t = tks[p]
        if t and not t.c and p.Parent and t.p >= 90 then
          ST.al = S.LK; ST.int = false
          local ok = goTo(p.Position, 5, 5)
          if ok and p.Parent then t.c = true; ST.ig = tick() + CFG.TLC; rw = 50; break else s_ = false end
        end
      end
    end
  elseif action == "go_crosshair" then
    local all = gUCH(false, false)
    if #all == 0 then all = gUCH(false, false, true); if #all == 0 then s_ = false end end
    if s_ then
      local t = all[1]; rw = 0; ST.int = false
      if t.p.Parent and not t.c and not ST.smT and not ST.prf then
        local sk = false
        local r2 = HR()
        if r2 then
          local tlArr2 = tkBT[1629547638]
          if tlArr2 then
            for _, p2 in ipairs(tlArr2) do
              local t2 = tks[p2]
              if t2 and not t2.c and p2.Parent and t2.p >= 90 then
                if d2Sq(r2.Position, p2.Position) < CFG.TLDS and d2Sq(r2.Position, t.p.Position) > CFG.CNTS then sk = true; break end
              end
            end
          end
        end
        if not sk then
          local ok = goTo(t.p.Position, 4, 5)
          if ok and t.p.Parent then
            t.c = true
            if t.iP then ST.pr = ST.pr + 1; rw = rw + 10 else ST.ch = ST.ch + 1; rw = rw + 8 end
          end
        end
      end
      if rw > 0 and ST.pma and ST.pmP then ST.al = S.RR; goTo(ST.pmP, 6, 4) end
    end
  elseif action == "go_dup_tp" then
    local bp = nil; local n = tick()
    local tpArr = tkBT[CFG.TPI]
    if tpArr then
      for _, p in ipairs(tpArr) do
        local t = tks[p]
        if t and not t.c and p.Parent and t.d and (t.l - (n - t.sT)) > 1 then bp = p; break end
      end
    end
    if not bp then s_ = false else
      local t = tks[bp]; ST.al = S.DT; ST.int = false
      local ok = goTo(bp.Position, 5, 5)
      if ok and bp.Parent then
        local st_ = tick()
        while tick() - st_ < aP.tsd do
          twait(0.1)
          if not bp.Parent or ST.int then break end
          local hp = HR()
          if hp then hp.CFrame = CFrame.new(bp.Position.X, hp.Position.Y, bp.Position.Z) end
        end
        t.c = true; rw = 15
      end
    end
  elseif action == "go_petal" then
    if #pts == 0 then s_ = false else
      local ca = false; local i = 1
      while i <= #pts do
        local pt = pts[i]
        if not pt.p.Parent then trem(pts, i)
        elseif petCD[pt.p] and tick() < petCD[pt.p] then trem(pts, i)
        else
          ST.al = S.PT .. pt.n; ST.int = false
          local ok = goTo(V3(pt.p.Position.X, 0, pt.p.Position.Z), CFG.PDS ^ 0.5, 2.5)
          if ok then ST.pt = ST.pt + 1; rw = rw + 8 + (14 - pt.pr); ca = true; twait(0.05); i = i + 1
          elseif ok == "CH_NEARBY" then tA(action, false); rAS(action); return 0
          else petCD[pt.p] = tick() + 5; trem(pts, i) end
        end
      end
      if not ca then s_ = false end
    end
  elseif action == "go_token_near" then
    local be, bdSv = nil, 1e9
    for p, t in pairs(tks) do
      if not t.c and p.Parent then
        local dSv = d2Sq(r.Position, p.Position)
        if dSv < bdSv then be = p; bdSv = dSv end
      end
    end
    if be then
      local t = tks[be]; ST.al = S.TK .. t.n; ST.int = false
      local ok = goTo(be.Position, 5, 5)
      if ok and be.Parent then t.c = true; rw = 3 + t.p * 0.2 else s_ = false end
    end
  elseif action == "go_token_best" then
    local be, bP = nil, -1; local n = tick()
    for p, t in pairs(tks) do
      if not t.c and p.Parent and (t.l - (n - t.sT)) > 0.5 and t.p > bP then be = p; bP = t.p end
    end
    if be then
      local t = tks[be]; ST.al = S.TB .. t.n; ST.int = false
      local ok = goTo(be.Position, 5, 5)
      if ok and be.Parent then t.c = true; rw = 5 + t.p * 0.3 else s_ = false end
    end
  elseif action == "patrol_ring" then
    local function rR()
      if ST.ar and ST.ar.Parent and ST.cf then
        local a_ = mrnd() * 2 * mpi; local rr_ = ST.arR * (0.5 + mrnd() * 0.8)
        return cP(V3(ST.ar.Position.X + mcos(a_) * rr_, 0, ST.ar.Position.Z + msin(a_) * rr_))
      elseif ST.cf then
        local c = ST.cf.Center; local s = ST.cf.Size
        return cP(V3(c.X + (mrnd() * 2 - 1) * mmax(s.X / 2 * 0.3, 5), 0, c.Z + (mrnd() * 2 - 1) * mmax(s.Z / 2 * 0.3, 5)))
      else
        local rp = HR()
        if rp then return cP(rp.Position + V3((mrnd() * 2 - 1) * 30, 0, (mrnd() * 2 - 1) * 30)) else return cP(V3z) end
      end
    end
    ST.al = S.PR; ST.int = false; local t = rR()
    if t == V3z or not iF(t) then t = gFC() end
    if t == V3z then rw = 0 else goTo(t, 6, aP.pt); twait(0.1 + mrnd() * 0.3) end
  elseif action == "patrol_random" then
    local function rF()
      if ST.cf then
        local c = ST.cf.Center; local s = ST.cf.Size
        return cP(V3(c.X + (mrnd() * 2 - 1) * mmax(s.X / 2 - 3, 1), 0, c.Z + (mrnd() * 2 - 1) * mmax(s.Z / 2 - 3, 1)))
      else
        local rp = HR()
        if rp then return cP(rp.Position + V3((mrnd() * 2 - 1) * 30, 0, (mrnd() * 2 - 1) * 30)) else return cP(V3z) end
      end
    end
    ST.al = S.PA; ST.int = false; local t = rF()
    if t == V3z or not iF(t) then t = gFC() end
    if t == V3z then rw = 0 else goTo(t, 4, aP.pt); twait(0.2 + mrnd() * 0.4) end
  elseif action == "go_xflame_center" then
    local c = gFC()
    if c == V3z then s_ = false else ST.al = S.XC; ST.int = false; goTo(c, 3, 3) end
  elseif action == "go_xflame_ch" then
    local c = gFC()
    if c == V3z then s_ = false else
      local bC, bDSq = nil, CFG.XRS + 1
      for _, ch in ipairs(chs) do
        if not ch.c and ch.p.Parent and not ch.wG then
          local dSv = p2Sq(ch.p.Position.X, ch.p.Position.Z, c.X, c.Z)
          if dSv <= CFG.XRS and dSv < bDSq then bDSq = dSv; bC = ch end
        end
      end
      if bC then ST.al = S.XH; ST.int = false; goTo(bC.p.Position, 2, 3); twait(1); rw = 5 end
    end
  end
  tA(action, s_)
  return s_ and rw or -2
end

-- ADAPTIVE PARAMS
local function getAP(n, d) return aP[n] or d end
local function setAP(n, v) aP[n] = mmax(CFG.AMIN, mmin(CFG.AMAX, v)) end
local function tMP()
  if ST.dc % CFG.AME ~= 0 or ST.dc == 0 then return end
  local keys = { "scrD", "pst", "tsd", "mcd", "pt", "arr", "mt" }
  local k = keys[mrnd(1, #keys)]
  local old = aP[k]
  local delta = (mrnd() * 2 - 1) * (old * 0.3)
  setAP(k, old + delta)
  ST._apT = { key = k, old = old, new = aP[k], at = tick() }
end
local function cM_()
  if not ST._apT then return end
  if tick() - ST._apT.at > CFG.ACA then
    local cur = gHP()
    local rec = bHP > 0 and bHP or cur
    if cur < rec * 0.85 then setAP(ST._apT.key, ST._apT.old) end
    ST._apT = nil
  end
end

-- SPEEDHACK
local function gAS()
  local p = ph()
  local b = CFG.SP[p] or CFG.SP[S.PHB]
  if ST.hf % 30 == 0 then
    local density = 0
    for _ in pairs(fls) do density = density + 1 end
    local base = b + (mrnd() * 2 - 1) * CFG.SJ
    if density > 8 then base = mmin(base, 60) end
    if mabs(base - (ST._cS or b)) > 1 then ST._cS = base end
  end
  return ST._cS or b
end

-- VISUALS
local xfC, scC = nil, nil
local function uV()
  if ST.xe then
    local cc = gFC()
    if cc == V3z then local r = HR(); if r then cc = r.Position end end
    if not xfC then
      xfC = Instance.new("Part"); xfC.Name = "XFlameCircle"; xfC.Shape = "Cylinder"
      xfC.Anchored = true; xfC.CanCollide = false; xfC.Transparency = 0.6
      xfC.BrickColor = BrickColor.Red()
      xfC.Size = V3(CFG.XRS ^ 0.5 * 2, 0.2, CFG.XRS ^ 0.5 * 2)
      xfC.Parent = W
    end
    xfC.Position = V3(cc.X, cc.Y + 0.2, cc.Z)
  else
    if xfC then xfC:Destroy(); xfC = nil end
  end
  if ST.en then
    local r = HR()
    if r then
      if not scC then
        scC = Instance.new("Part"); scC.Name = "ScytheRadius"; scC.Shape = "Cylinder"
        scC.Anchored = true; scC.CanCollide = false; scC.Transparency = 0.6
        -- Use numeric palette for compatibility
        pcall(function() scC.BrickColor = BrickColor.palette(106) end)
        scC.Size = V3(CFG.FHDS ^ 0.5 * 2, 0.2, CFG.FHDS ^ 0.5 * 2)
        scC.Parent = W
      end
      scC.Position = V3(r.Position.X, r.Position.Y + 0.2, r.Position.Z)
    end
  else
    if scC then scC:Destroy(); scC = nil end
  end
end

-- COMPONENTS
local function makeComp(name, every, updateFn)
  return { name = name, every = every, enabled = true, update = updateFn }
end
local COMP = {
  makeComp("buffs", 18, sAB),
  makeComp("flames", 12, sFl),
  makeComp("petals", 9, sPt),
  makeComp("flameHit", 9, tHF),
  makeComp("speed", 9, function()
    local h_ = HM()
    if h_ then
      local ts = gAS()
      if mabs(h_.WalkSpeed - ts) > 0.5 then h_.WalkSpeed = ts end
    end
  end),
  makeComp("history", 6, function() safeCall("uH", uH) end),
  makeComp("mutCheck", 6, cM_),
  makeComp("mutParams", 6, tMP),
  makeComp("smile", 3, sSm),
  makeComp("ring", 3, fAR),
  makeComp("field", 180, detF),
  makeComp("cache", 600, cacheP),
  makeComp("deadClean", CFG.DCE, function() clnCHFull() end),
  makeComp("flushTokens", 8, function() flushTQ() end),
  makeComp("save", 18000, function()
    tspawn(function()
      local qc = 0; for _ in pairs(qT) do qc = qc + 1 end
      safeCall("saveQTable", function()
        if writefile then writefile(CFG.QF, H:JSONEncode({ version = CFG.V, qtable = qT, aP = aP, gen = #gP, stats = aSt, meta = { sc = qc, sa = os.time() } })) end
      end)
    end)
  end),
  makeComp("patGen", 1800, function()
    local n = tick()
    if n - (ST.lg or 0) > CFG.PGE then ST.lg = n; gPatt() end
  end)
}
local function runComps()
  for _, c in ipairs(COMP) do
    if c.enabled and ST.hf % c.every == 0 then
      local ok, err = pcall(c.update)
      if not ok then addErr(c.name .. " component failed: " .. tostring(err)) end
    end
  end
end
local function stopComps() for _, c in ipairs(COMP) do c.enabled = false end end
local function startComps() for _, c in ipairs(COMP) do c.enabled = true end end

-- MAIN GUI
local mainGui = nil
safeCall("mainGui", function()
  local sg = Instance.new("ScreenGui", G)
  sg.Name = "BSSAI_GUI"
  local fr = Instance.new("Frame", sg)
  fr.Size = UDim2.new(0, 265, 0, 112)
  fr.Position = UDim2.new(0, 10, 0, 10)
  fr.BackgroundColor3 = cfRGB(20, 20, 30)
  fr.BackgroundTransparency = 0.15
  fr.BorderSizePixel = 0
  fr.Active = true; fr.Draggable = true
  pcall(function()
    local uic = Instance.new("UICorner", fr)
    uic.CornerRadius = UDim.new(0, 6)
  end)
  local ti_ = Instance.new("TextLabel", fr)
  ti_.Size = UDim2.new(1, 0, 0, 20); ti_.Position = UDim2.new(0, 0, 0, 2)
  ti_.BackgroundTransparency = 1; ti_.Text = "🧠 BSS AI v14.5"
  ti_.TextColor3 = cfRGB(100, 200, 255); ti_.Font = Enum.Font.GothamBold; ti_.TextSize = 12
  ti_.TextXAlignment = Enum.TextXAlignment.Center
  local lb = Instance.new("TextLabel", fr)
  lb.Size = UDim2.new(1, 0, 0, 18); lb.Position = UDim2.new(0, 0, 0, 24)
  lb.BackgroundTransparency = 1; lb.Text = "Действие: старт"
  lb.TextColor3 = cfRGB(255, 255, 255); lb.Font = Enum.Font.Gotham; lb.TextSize = 13
  lb.TextXAlignment = Enum.TextXAlignment.Center
  local hl = Instance.new("TextLabel", fr)
  hl.Size = UDim2.new(1, 0, 0, 18); hl.Position = UDim2.new(0, 0, 0, 44)
  hl.BackgroundTransparency = 1; hl.Text = "HPS: -- | Рек: --"
  hl.TextColor3 = cfRGB(150, 255, 150); hl.Font = Enum.Font.Gotham; hl.TextSize = 12
  hl.TextXAlignment = Enum.TextXAlignment.Center
  local sl_ = Instance.new("TextLabel", fr)
  sl_.Size = UDim2.new(1, 0, 0, 18); sl_.Position = UDim2.new(0, 0, 0, 64)
  sl_.BackgroundTransparency = 1; sl_.Text = "⚡ --"
  sl_.TextColor3 = cfRGB(255, 200, 100); sl_.Font = Enum.Font.Gotham; sl_.TextSize = 11
  sl_.TextXAlignment = Enum.TextXAlignment.Center
  local pl_ = Instance.new("TextLabel", fr)
  pl_.Size = UDim2.new(1, 0, 0, 18); pl_.Position = UDim2.new(0, 0, 0, 82)
  pl_.BackgroundTransparency = 1; pl_.Text = "Φ: --"
  pl_.TextColor3 = cfRGB(180, 180, 255); pl_.Font = Enum.Font.Gotham; pl_.TextSize = 11
  pl_.TextXAlignment = Enum.TextXAlignment.Center
  local al_ = Instance.new("TextLabel", fr)
  al_.Size = UDim2.new(1, 0, 0, 18); al_.Position = UDim2.new(0, 0, 0, 98)
  al_.BackgroundTransparency = 1; al_.Text = "G:--"
  al_.TextColor3 = cfRGB(255, 180, 100); al_.Font = Enum.Font.Gotham; al_.TextSize = 10
  al_.TextXAlignment = Enum.TextXAlignment.Center
  tspawn(function()
    while true do
      twait(0.3)
      pcall(function()
        lb.Text = ST.al
        local cur = gHP()
        local hs = cur > 0 and fmt("%.0f", cur) or "--"
        local bs = bHP > 0 and fmt("%.0f", bHP) or "--"
        hl.Text = "HPS: " .. hs .. " | Рек: " .. bs
        sl_.Text = "⚡ " .. fmt("%.0f", ST._cS or 0)
        pl_.Text = "Φ:" .. ph() .. " Sc:" .. scPh() .. " CH:" .. #chs
        al_.Text = "Tk:" .. ST.tk .. " Зл:" .. ST.cg .. " G:" .. #gP
      end)
    end
  end)
  mainGui = sg
end)

-- LOAD Q-TABLE
local function loadQTable()
  if not readfile then addErr("readfile not available — Q-table starts fresh"); return end
  local ok, raw = pcall(readfile, CFG.QF)
  if ok and raw then
    local ok2, d = pcall(H.JSONDecode, H, raw)
    if ok2 and _type(d) == "table" and d.version == CFG.V and _type(d.qtable) == "table" then
      qT = d.qtable
      if d.aP then for k, v in pairs(d.aP) do aP[k] = v end end
      if d.stats then aSt = d.stats end
      addErr("Q-table loaded: " .. tostring(#qT) .. " states")
    end
  end
end

-- ===== PHASE 12: Heartbeat =====
local mL = false

addErr("=== BSS AI v14.5 bootstrap complete ===")
addErr("Waiting for Heartbeat init...")

-- Anti-lag terrain cleanup
tspawn(function()
  while true do
    twait(30)
    safeCall("terrainCleanup", function()
      local t = cfc(W, "Terrain")
      if t then
        for _, d in ipairs(t:GetDescendants()) do
          if (d:IsA("Decal") or d:IsA("Texture")) and not (d.Name and d.Name:find("Crosshair")) then
            d:Destroy()
          end
        end
      end
      local lt = cfc(W, "Lighting")
      if lt then lt.GlobalShadows = false; lt.Brightness = 2 end
    end)
  end
end)

-- Load patterns
tspawn(function()
  safeCall("loadPatterns", function()
    if not readfile then return end
    local ok, raw = pcall(readfile, CFG.PF)
    if ok and raw then
      local ok2, data = pcall(H.JSONDecode, H, raw)
      if ok2 and _type(data) == "table" then
        pH = data
        for _, p in ipairs(pH) do if p.hps and p.hps > bHP then bHP = p.hps end end
        addErr("Patterns loaded: " .. #pH .. " entries, best HPS: " .. fmt("%.0f", bHP))
      end
    end
  end)
end)

-- HEARTBEAT
if _G._BSSAI_HB then pcall(function() _G._BSSAI_HB:Disconnect() end) end
_G._BSSAI_HB = R.Heartbeat:Connect(function()
  if not ST.en then return end
  if not mL then
    mL = true
    twait(2)
    safeCall("hbInit.loadQTable", loadQTable)
    safeCall("hbInit.fAR", fAR)
    safeCall("hbInit.detF", detF)
    addErr("v14.5 Heartbeat init complete — running!")
    print("✅ BSS AI v14.5 ready!")
    ST.al = S.AI; ST.lm = tick(); sMH(); ST.lg = tick()
    -- Hide error GUI once running (but keep it accessible)
    if errGui and errGui.Enabled then
      -- Don't hide, just update status
      addErr("All systems GO — error GUI stays for monitoring")
    end
    return
  end
  ST.hf = ST.hf + 1
  if ST.hf % 4 == 0 then pcall(collectgarbage, "step", 2) end
  runComps()
  uGS(); ST.xe = (ST.xf >= 20)
  if ST.xe then ST.int = true end
  safeCall("hb.uV", uV)
  local r = HR()
  if r then
    local vel = r.AssemblyLinearVelocity
    local n = tick()
    local hS = (V3(vel.X, 0, vel.Z)).Magnitude
    if hS > 0.2 then
      ST.lm = n; ST.st = false
    elseif n - ST.lm > 5 and not ST.st then
      ST.st = true; ST.int = true; ST.al = S.ST
      if ST.smT and not ST.smT.Parent then ST.smT = nil; ST.smA = false end
      ST.int = false; ST.lm = n
    end
  end
  if ST.int and not ST.smT and not ST.prf and not ST.xe then ST.int = false end
  if ST.hf % 2 == 0 then
    local n = tick()
    local p_ = ph()
    -- Pre-compute action flags
    afCH = false
    for _, ch in ipairs(chs) do if not ch.c and ch.p.Parent and not ch.wG then afCH = true; break end end
    local tp = gTP(); afTP = tp ~= nil
    afPL = false
    for _, ch in ipairs(chs) do if not ch.c and ch.p.Parent and ch.iP and not ch.wG then afPL = true; break end end
    local tlA = tkBT[1629547638]; afTL = false
    if tlA then for _, p in ipairs(tlA) do local t = tks[p]; if t and not t.c and p.Parent then afTL = true; break end end end
    afUg = false
    if p_ ~= S.PHB then
      for p, t in pairs(tks) do
        if not t.c and p.Parent then
          if t.l - (n - t.sT) < 0.3 and t.l - (n - t.sT) > 0 then afUg = true; break end
        end
      end
    end
    afSc = ST.sa and next(fls) ~= nil
    afSm = ST.smT ~= nil
    afPM = ST.pma and ST.ar ~= nil
    afXF = ST.xe
    afPt = #pts > 0
    afTk = false; for _ in pairs(tks) do afTk = true; break end
    local tpA = tkBT[CFG.TPI]; afDTP = false
    if tpA then
      for _, p in ipairs(tpA) do
        local t = tks[p]
        if t and not t.c and p.Parent and t.d and t.l - (n - t.sT) > 1 then afDTP = true; break end
      end
    end
    local s_ = eS()
    local a_ = cA()
    local ok, rw = safeCall("eA." .. a_, function() return eA(a_) end)
    if not ok then rw = -1; addErr("Action " .. a_ .. " crashed: " .. tostring(rw)) end
    local ns = eS()
    safeCall("uQ", function() uQ(s_, a_, rw, ns) end)
  end
end)

-- INPUT
U.InputBegan:Connect(function(i, gp)
  if gp then return end
  if i.KeyCode == Enum.KeyCode.T then
    ST.en = not ST.en
    if ST.en then startComps() else stopComps() end
    if mainGui then mainGui.Enabled = ST.en end
    addErr("Toggled: " .. (ST.en and "ON" or "OFF"))
  elseif i.KeyCode == Enum.KeyCode.G then
    qT = {}; eps = CFG.ES; ST.tr = 0; ST.dc = 0
    aP = { scrD = 4, pst = 1, tsd = 1.1, mcd = 10, pt = 8, arr = 5, mt = 6 }
    gP = {}; ST.lg = 0; aSt = {}
    safeCall("resetQTable", function()
      if writefile then writefile(CFG.QF, H:JSONEncode({ version = CFG.V, qtable = {}, aP = aP, meta = { ra = os.time() } })) end
    end)
    addErr("Q-table RESET")
  elseif i.KeyCode == Enum.KeyCode.P then
    local qc = 0; for _ in pairs(qT) do qc = qc + 1 end
    print("Φ:" .. ph() .. " Sc:" .. scPh() .. " eps:" .. fmt("%.3f", eps) .. " R:" .. ST.tr .. " S:" .. qc .. " P:" .. #pH)
    for n, s in pairs(aSt) do
      print("  " .. n .. ": " .. s.s .. "/" .. s.a .. " (" .. fmt("%.0f", s.s / mmax(1, s.a) * 100) .. "%)")
    end
    addErr("Stats: Φ=" .. ph() .. " Sc=" .. scPh() .. " eps=" .. fmt("%.3f", eps) .. " states=" .. qc)
  end
end)

-- CHARACTER RESPAWN
L.CharacterAdded:Connect(function()
  twait(2)
  tks = {}; tkBT = {}; chs = {}; pts = {}; ST.cf = nil
  ST.al = S.IN; ST.smT = nil; ST.smA = false; ST.int = false
  ST.ps = 0; ST.pX = false; ST.prf = false; fls = {}; ST.ig = 0
  sprC = nil; sprA = 0; sprR = 0; dT = {}
  clrCache(); cacheP()
  chDrty = true; cDiag, cRefDiag, cTP = nil, nil, nil
  rA = {}; sCache._k = nil
  if xfC then xfC:Destroy(); xfC = nil end
  if scC then scC:Destroy(); scC = nil end
  -- Re-scan world
  local scanned = 0
  for _, o in ipairs(W:GetDescendants()) do tins(tQ, o); scanned = scanned + 1 end
  addErr("Respawn: re-scanning " .. scanned .. " objects for tokens")
  local qc = 0; for _ in pairs(qT) do qc = qc + 1 end
  tspawn(function()
    safeCall("saveOnDeath", function()
      if writefile then writefile(CFG.QF, H:JSONEncode({ version = CFG.V, qtable = qT, aP = aP, stats = aSt, meta = { sc = qc, sa = os.time() } })) end
    end)
  end)
end)

addErr("=== All hooks registered ===")
print("✅ BSS AI v14.5 ready — Error GUI active, check top-left corner")
