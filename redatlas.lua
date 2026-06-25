-- BSS AI v12.7 safe + Red Bomb Plus + REFRESH fix + фиол. стойка только при X10 (полный)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")

local Q_VERSION = "12.7"
local ENABLED = true

local SPEED = 70
local ABILITY_MULT = 1.2
local DIG_BEE_LVL = 22
local FIELD_MARGIN = 3
local ARRIVE_DIST = 5
local MOVE_TIMEOUT = 6
local PREC_BUFF_ID = 2574507284
local PREC_PER_STACK = 0.02
local PREC_MAX = 10
local PREC_REFRESH_AT = 15
local PURPLE = Color3.fromRGB(119,85,255)
local PURPLE_TOL = 12
local PURPLE_STAND = 1
local SMILE_TOKEN_ID = 5877939956
local SMILE_REACT_TIME = 10
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

local HPS_READ_INTERVAL = 0.5
local HPS_ANALYZE_INTERVAL = 10
local HPS_WINDOW = 120
local HPS_RECORD_THRESHOLD = 0.03
local PATTERN_BONUS = 15
local PATTERN_COORD_TOLERANCE = 10
local MAX_PATTERNS = 30

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
    ["Red"] = Color3.fromRGB(249,34,34), ["Pink"] = Color3.fromRGB(255,130,201),
    ["Merigold"] = Color3.fromRGB(218,168,28), ["Periwinkle"] = Color3.fromRGB(150,156,236),
    ["Violet"] = Color3.fromRGB(94,38,177), ["Scarlet"] = Color3.fromRGB(171,19,19),
    ["Green"] = Color3.fromRGB(35,232,5), ["Yellow"] = Color3.fromRGB(238,204,79),
    ["Black"] = Color3.fromRGB(11,11,11), ["Grey"] = Color3.fromRGB(127,127,127),
    ["Blue"] = Color3.fromRGB(33,66,249), ["Cyan"] = Color3.fromRGB(29,196,222),
    ["White"] = Color3.fromRGB(249,249,249),
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

local prec = {stacks=0, value=0, isX10=false, localStart=0, serverDur=60, serverStart=0, timeLeft=0, needRefresh=false}
local cycle = {chCollectedCount = 0}
local stats = {tok=0, ch=0, purple=0, x10=0, ref=0, totalReward=0, decisions=0, smileCollected=0, chAvoided=0, petalsCollected=0, flamesHit=0}
local INTERRUPT = false
local trackedFlames = {}
local fieldPetals = {}
local areaRing = nil
local areaRingRadius = AREA_RING_RADIUS
local isCollectingSmile = false
local smileTarget = nil
local smileTargetRem = 0
local ignoreNewTokensUntil = 0
local activeBuffs = {ScorchingStar={stacks=0}, XFlame={stacks=0}, PreciseMark={active=false}, PollenMark={active=false, pos=nil}}
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
local hasTL = false
local lastMoveTime = tick()
local stuckWarning = false
local xflameEmergency = false
local xflameCircle = nil
local scytheCircle = nil
local lastPenaltyTime = 0

-- ===================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====================
local function getHRP() local c=LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHumanoid() local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function texId(t) if not t then return nil end; return tonumber(t:match("rbxassetid://(%d+)") or t:match("id=(%d+)")) end
local function dist3(a,b) return (Vector3.new(a.X,0,a.Z)-Vector3.new(b.X,0,b.Z)).Magnitude end
local function dist3D(a,b) return (a-b).Magnitude end
local function getPhase() if not prec.isX10 then return "НАБОР" elseif prec.needRefresh then return "REFRESH" else return "X10" end end
local function getFieldCenter() if curField and curField.part then return curField.part.Position end; local r=getHRP(); return r and r.Position or Vector3.zero end
local function clampPos(pos, skipClamp)
    if skipClamp then return pos end
    if not curField then return pos end
    local c = curField.part.Position; local s = curField.part.Size
    local mx = math.max(s.X/2 - FIELD_MARGIN, 1); local mz = math.max(s.Z/2 - FIELD_MARGIN, 1)
    local cl = Vector3.new(math.clamp(pos.X,c.X-mx,c.X+mx), pos.Y, math.clamp(pos.Z,c.Z-mz,c.Z+mz))
    if activeBuffs.XFlame.stacks >= 20 then
        local dx, dz = cl.X - c.X, cl.Z - c.Z
        local dist = math.sqrt(dx*dx + dz*dz)
        if dist > XFLAME_CENTER_RADIUS then
            local scale = XFLAME_CENTER_RADIUS / dist
            cl = Vector3.new(c.X + dx*scale, cl.Y, c.Z + dz*scale)
        end
    end
    return cl
end
local function isInField(pos) if not curField then return false end; local c=curField.part.Position; local s=curField.part.Size; return math.abs(pos.X-c.X)<=s.X/2+PETAL_FIELD_MARGIN and math.abs(pos.Z-c.Z)<=s.Z/2+PETAL_FIELD_MARGIN end

-- ===================== AREA RING =====================
local function findAreaRing()
    local particles = Workspace:FindFirstChild("Particles")
    if particles then for _,ch in ipairs(particles:GetChildren()) do if ch.Name=="AreaRing" and ch:IsA("BasePart") then areaRing=ch; local s=ch.Size; areaRingRadius=(s.X+s.Z)/4; if areaRingRadius<5 then areaRingRadius=AREA_RING_RADIUS end; return end end end
    areaRing = Workspace:FindFirstChild("AreaRing")
    if areaRing and areaRing:IsA("BasePart") then local s=areaRing.Size; areaRingRadius=(s.X+s.Z)/4; if areaRingRadius<5 then areaRingRadius=AREA_RING_RADIUS end
    else areaRing=nil; areaRingRadius=AREA_RING_RADIUS end
end
task.spawn(function() while true do task.wait(5) findAreaRing() end end)

-- ===================== КРОСХЕИРЫ =====================
local Parts = Workspace:FindFirstChild("Particles") or workspace:WaitForChild("Particles",10)
local function isClose(a,b,tol) tol=tol or PURPLE_TOL; return math.abs(a.R*255 - b.R*255)<=tol and math.abs(a.G*255 - b.G*255)<=tol and math.abs(a.B*255 - b.B*255)<=tol end
local function isPurple(part) local ok,c=pcall(function() return part.Color end); if ok and c and isClose(c,PURPLE) then return true end; local ok2,bc=pcall(function() return part.BrickColor.Color end); return ok2 and bc and isClose(bc,PURPLE) end
local function addCH(obj) if obj.Name~="Crosshair" or not obj:IsA("BasePart") then return end; for _,ch in ipairs(chQueue) do if ch.part==obj then return end end; task.wait(0.06); if not obj.Parent then return end; table.insert(chQueue,{part=obj,spawnTime=tick(),collected=false,isPurple=isPurple(obj)}) end
if Parts then Parts.DescendantAdded:Connect(addCH); Parts.DescendantRemoving:Connect(function(obj) for i=#chQueue,1,-1 do if chQueue[i].part==obj then table.remove(chQueue,i) break end end; if lastPurple==obj then lastPurple=nil end end); for _,o in ipairs(Parts:GetDescendants()) do addCH(o) end end
local function getCH(onlyP,onlyR) local list={}; for _,ch in ipairs(chQueue) do if not ch.collected and ch.part.Parent then if (onlyP and ch.isPurple) or (onlyR and not ch.isPurple) or (not onlyP and not onlyR) then table.insert(list,ch) end end end; return list end

-- ===================== ИЗБЕГАНИЕ CH =====================
local function getRegCHThreats(myPos,destPos) if not prec.isX10 or prec.needRefresh then return {} end; local mf=Vector3.new(myPos.X,0,myPos.Z); local df=Vector3.new(destPos.X,0,destPos.Z); local tt=df-mf; if tt.Magnitude<1 then return {} end; local tD=tt.Unit; local th={}; for _,ch in ipairs(chQueue) do if not ch.collected and ch.part.Parent and not ch.isPurple then local cf=Vector3.new(ch.part.Position.X,0,ch.part.Position.Z); local toCh=cf-mf; local d=toCh.Magnitude; if d<CH_AVOID_RADIUS and d>1 then local dot=toCh.Unit:Dot(tD); if dot>CH_AVOID_DOT_MIN then local cross=math.abs(toCh.X*tD.Z - toCh.Z*tD.X); if cross<CH_AVOID_RADIUS then table.insert(th,{ch=ch,pos=cf,dist=d,cross=cross}) end end end end end; return th end
local function calcAvoidTarget(myPos,destPos) local th=getRegCHThreats(myPos,destPos); if #th==0 then return nil end; table.sort(th,function(a,b) return a.dist<b.dist end); local t=th[1]; local mf=Vector3.new(myPos.X,0,myPos.Z); local df=Vector3.new(destPos.X,0,destPos.Z); local tD=(df-mf).Unit; local toCh=t.pos-mf; local p1=Vector3.new(-toCh.Unit.Z,0,toCh.Unit.X); local p2=Vector3.new(toCh.Unit.Z,0,-toCh.Unit.X); local bp=p1; if p2:Dot(tD)>=p1:Dot(tD) then bp=p2 end; local ap=t.pos+bp*CH_AVOID_STEER; stats.chAvoided=stats.chAvoided+1; return clampPos(Vector3.new(ap.X,myPos.Y,ap.Z)) end
local function getDupedTokenCount() local c=0; local r=getHRP(); if not r then return 0 end; for part,t in pairs(activeTokens) do if not t.collected and t.duped and part.Parent and dist3(r.Position,part.Position)<80 then c=c+1 end end; return c end

-- ===================== GO TO =====================
local function goTo(targetPos,radius,timeout,skipClamp)
    radius=radius or ARRIVE_DIST; timeout=timeout or MOVE_TIMEOUT; if targetPos==Vector3.zero then return false end
    local r=getHRP(); local h=getHumanoid(); if not r or not h then return false end
    targetPos=clampPos(targetPos,skipClamp)
    if targetPos==Vector3.zero then local center=getFieldCenter(); if center==Vector3.zero then return false end; targetPos=center end
    local origTarget=Vector3.new(targetPos.X,r.Position.Y,targetPos.Z)
    local curMove=origTarget; local avoid=calcAvoidTarget(r.Position,origTarget); if avoid then curMove=Vector3.new(avoid.X,r.Position.Y,avoid.Z) end
    h:MoveTo(curMove)
    local t0=tick(); local lastMove=tick(); local lastAvoid=tick(); local sc=0.15
    while tick()-t0<timeout do
        task.wait(0.05)
        if not ENABLED then return false end; if INTERRUPT then return false end
        r=getHRP(); if not r then return false end
        if dist3(r.Position,origTarget)<=radius then return true end
        if tick()-lastAvoid>=sc then lastAvoid=tick(); local na=calcAvoidTarget(r.Position,origTarget); if na then curMove=Vector3.new(na.X,r.Position.Y,na.Z) else curMove=origTarget end end
        if curMove~=origTarget and dist3(r.Position,curMove)<=4 then local na=calcAvoidTarget(r.Position,origTarget); curMove=na and Vector3.new(na.X,r.Position.Y,na.Z) or origTarget end
        if tick()-lastMove>=0.3 then h=getHumanoid(); if h then h:MoveTo(curMove) end; lastMove=tick() end
    end
    return false
end

-- ===================== SMILE TOKEN (исправлен continue) =====================
task.spawn(function() while true do task.wait(0.05); if not ENABLED then return end; local n=tick(); smileTarget=nil; smileTargetRem=0; local bp=nil; local bd=math.huge; local br=0; local r=getHRP(); if not r then return end; local hp=activeBuffs.PollenMark.active; local rp=areaRing and areaRing.Position; for part,t in pairs(activeTokens) do if not t.collected and part.Parent and t.id==SMILE_TOKEN_ID then local rem=t.life-(n-t.spawn); if rem<=SMILE_REACT_TIME and rem>0 then local take=false; if hp and rp then if dist3(part.Position,rp)<=areaRingRadius*1.5 then take=true end else take=true end; if take then local d=dist3(r.Position,part.Position); if d<bd then bp=part; bd=d; br=rem end end end end end; if bp then smileTarget=bp; smileTargetRem=br; if not isCollectingSmile then INTERRUPT=true end end end end)

-- ===================== ФЛЕЙМЫ =====================
local toolCollectEvent = nil do local e = ReplicatedStorage:FindFirstChild("Events"); if e then toolCollectEvent=e:FindFirstChild("ToolCollect") end end
local function isFlmDark(flm) local pf=flm:FindFirstChild("PF"); if pf then local color=nil; if pf:IsA("ColorSequenceValue") then local seq=pf.Value; if seq and seq.Keypoints and #seq.Keypoints>0 then local key=seq.Keypoints[1]; if key and type(key)=="table" and key.Value then color=key.Value elseif key and type(key)=="userdata" and key.Value then color=key.Value end end elseif pf:IsA("Color3Value") then color=pf.Value elseif pf:IsA("BasePart") then local ok,c=pcall(function() return pf.Color end); if ok then color=c end end; if color then return color.G<0.3 and color.B>0.5 end end; local ok,c=pcall(function() return flm.Color end); if ok and c then return c.G<0.3 and c.B>0.5 end; return false end
task.spawn(function() while true do task.wait(0.2); local flames=Workspace:FindFirstChild("PlayerFlames"); if flames then local n=tick(); local seen={}; for _,flm in ipairs(flames:GetChildren()) do if flm.Name:sub(1,3)=="Flm" then seen[flm]=true; if not trackedFlames[flm] then trackedFlames[flm]={spawnTime=n,isDark=isFlmDark(flm),hit=false} else trackedFlames[flm].isDark=isFlmDark(flm) end end end; for flm in pairs(trackedFlames) do if not seen[flm] then trackedFlames[flm]=nil end end end end end)
local function swingScythe() if toolCollectEvent then pcall(toolCollectEvent.FireServer,toolCollectEvent); task.wait(0.1) else pcall(function() local cam=workspace.CurrentCamera; local vp=cam.ViewportSize; VirtualInputManager:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,true,game,1); task.wait(0.05); VirtualInputManager:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,false,game,1) end) end end
task.spawn(function() while true do task.wait(0.15); if not ENABLED then return end; local r=getHRP(); if not r then return end; local n=tick(); for flm,data in pairs(trackedFlames) do if not data.hit and not data.isDark and flm.Parent then local age=n-data.spawnTime; if age>=FLAME_HIT_AFTER then local d=dist3(r.Position,flm.Position); if d<=FLAME_HIT_DIST then INTERRUPT=true; task.wait(0.05); local bg=r:FindFirstChild("AI_BG"); if not bg then bg=Instance.new("BodyGyro"); bg.Name="AI_BG"; bg.MaxTorque=Vector3.new(0,40000,0); bg.P=10000; bg.D=500; bg.Parent=r end; local dir=(flm.Position-r.Position); dir=Vector3.new(dir.X,0,dir.Z); if dir.Magnitude>0.1 then bg.CFrame=CFrame.lookAt(r.Position,r.Position+dir) end; task.wait(0.1); swingScythe(); task.wait(0.15); if bg then bg:Destroy() end; data.hit=true; stats.flamesHit=stats.flamesHit+1; task.wait(0.2); INTERRUPT=false; break end end end end end end)

-- ===================== ТОКЕНЫ =====================
local function regToken(obj) if obj.Name~="C" or not obj:IsA("BasePart") or activeTokens[obj] or tick()<ignoreNewTokensUntil then return end; local front=obj:FindFirstChild("FrontDecal"); if not front or not front:IsA("Decal") then return end; local id=texId(front.Texture); if not id or AVOID[id] then return end; local def=TOKENS[id]; if not def then return end; local r=getHRP(); local duped=r and (obj.Position.Y-r.Position.Y)>5; local life=def.base*ABILITY_MULT; if duped then life=life*(2+0.05*(DIG_BEE_LVL-1)) end; activeTokens[obj]={id=id,name=def.name,prio=def.prio,mo=def.mo or false,spawn=tick(),life=life,duped=duped,collected=false} end
Workspace.DescendantAdded:Connect(function(o) task.wait(0.05) pcall(regToken,o) end)
for _,o in ipairs(Workspace:GetDescendants()) do pcall(regToken,o) end
game.DescendantRemoving:Connect(function(obj) if activeTokens[obj] then if activeTokens[obj].collected then stats.tok=stats.tok+1 end; activeTokens[obj]=nil end end)

-- ===================== BUFFS =====================
local rps = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RetrievePlayerStats")
task.spawn(function() while true do task.wait(0.5); if not rps then return end; local ok,result=pcall(rps.InvokeServer,rps); if ok and type(result)=="table" then local function findBuff(tbl,src) if type(tbl)~="table" then return nil end; if rawget(tbl,"Src")==src then local combo=rawget(tbl,"Combo") or 0; return {stacks=tonumber(combo)} end; for _,v in pairs(tbl) do local f=findBuff(v,src); if f then return f end end; return nil end; local ss=findBuff(result,"Scorching Star Aura"); activeBuffs.ScorchingStar.stacks=ss and ss.stacks or 0; local xf=findBuff(result,"X-Flame Aura"); activeBuffs.XFlame.stacks=xf and xf.stacks or 0; local function findPreciseMark(tbl) if type(tbl)~="table" then return false end; if rawget(tbl,"BuffID")==2575093099 and rawget(tbl,"Removed")~=true then return true end; for _,v in pairs(tbl) do if findPreciseMark(v) then return true end end; return false end; activeBuffs.PreciseMark.active=findPreciseMark(result); local function findPollenMark(tbl) if type(tbl)~="table" then return nil end; if rawget(tbl,"BuffID")==POLLEN_MARK_BUFF_ID and rawget(tbl,"Removed")~=true then return rawget(tbl,"Value") or 1 end; for _,v in pairs(tbl) do local f=findPollenMark(v); if f then return f end end; return nil end; local pm=findPollenMark(result); if pm and pm>0 then activeBuffs.PollenMark.active=true; activeBuffs.PollenMark.multiplier=pm; if areaRing then activeBuffs.PollenMark.pos=areaRing.Position end else activeBuffs.PollenMark.active=false end end end end)

-- ===================== ЦЕНТР ОГНЯ =====================
local function getFireClusterCenter() local flames={}; for flm in pairs(trackedFlames) do if flm.Parent then table.insert(flames,flm.Position) end end; if #flames==0 then return nil end; local sum=Vector3.new(0,0,0); for _,p in ipairs(flames) do sum=sum+p end; return clampPos(sum/#flames) end

-- ===================== ПЕТАЛЫ (исправлен continue) =====================
local function getPetalColor(part) for name,col in pairs(PETAL_COLORS) do if (col.R - part.Color.R)^2 + (col.G - part.Color.G)^2 + (col.B - part.Color.B)^2 < 0.002 then return name end end; return nil end
task.spawn(function() while true do task.wait(0.15); fieldPetals={}; if not ENABLED or not curField then return end; local particles=Workspace:FindFirstChild("Particles"); if not particles then return end; local r=getHRP(); if not r then return end; for _,obj in ipairs(particles:GetChildren()) do if obj.Name=="PetalPart" and obj:IsA("BasePart") and isInField(obj.Position) then local cName=getPetalColor(obj); if cName and PETAL_PRIORITY[cName] then local d=dist3D(r.Position,obj.Position); table.insert(fieldPetals,{part=obj,colorName=cName,priority=PETAL_PRIORITY[cName],dist=d}) end end end; table.sort(fieldPetals,function(a,b) if a.priority~=b.priority then return a.priority<b.priority end; return a.dist<b.dist end) end end)

-- ===================== HPS и ПАТТЕРНЫ (восстановлены) =====================
local function findHPSLabel()
    local sg = LP.PlayerGui:FindFirstChild("ScreenGui"); if not sg then return nil end
    local mh = sg:FindFirstChild("MeterHUD"); if not mh then return nil end
    local hm = mh:FindFirstChild("HoneyMeter"); if not hm then return nil end
    local bar = hm:FindFirstChild("Bar"); if not bar then return nil end
    return bar:FindFirstChild("PerSecLabel")
end
local function parseHPS(text) if type(text)~="string" then return 0 end; text=text:gsub(",",""):gsub(" ",""):upper(); local num,suffix=text:match("([%d.]+)([KM]?)"); if not num then return 0 end; local val=tonumber(num) or 0; if suffix=="K" then val=val*1000 elseif suffix=="M" then val=val*1000000 end; return val end
local function getHoneyPerSecond() if not hpsMeterLabel or not hpsMeterLabel.Parent then hpsMeterLabel=findHPSLabel() end; if hpsMeterLabel and hpsMeterLabel:IsA("TextLabel") then return parseHPS(hpsMeterLabel.Text) end; return 0 end
local function savePatterns() local ok,j=pcall(HttpService.JSONEncode,HttpService,patternsHistory); if ok then pcall(writefile,patternFile,j) end end
local function loadPatterns() local ok,raw=pcall(readfile,patternFile); if ok and raw then local ok2,data=pcall(HttpService.JSONDecode,HttpService,raw); if ok2 and type(data)=="table" then patternsHistory=data; local maxHPS=0; for _,p in ipairs(patternsHistory) do if p.hps and p.hps>maxHPS then maxHPS=p.hps end end; bestAvgHPS=maxHPS end end end
local function updateHPSBuffers()
    local now=tick(); local hps=getHoneyPerSecond(); if hps>0 then table.insert(hpsBuffer,{time=now,hps=hps}) end
    local cutoff=now-HPS_WINDOW; while #hpsBuffer>0 and hpsBuffer[1].time<cutoff do table.remove(hpsBuffer,1) end
    if taskLabel and taskLabel~="старт" then local r=getHRP(); local pos=r and r.Position or Vector3.zero; table.insert(actionBuffer,{time=now,action=taskLabel,pos=pos,phase=getPhase(),isScorch=activeBuffs.ScorchingStar.stacks>0}) end
    while #actionBuffer>0 and actionBuffer[1].time<cutoff do table.remove(actionBuffer,1) end
    if now-lastAnalyzeTime>=HPS_ANALYZE_INTERVAL then
        lastAnalyzeTime=now; local sum,count=0,0; for _,e in ipairs(hpsBuffer) do sum=sum+e.hps; count=count+1 end; local avg=count>0 and (sum/count) or 0
        if avg>0 then local acts={}; for _,e in ipairs(actionBuffer) do table.insert(acts,{action=e.action,pos=e.pos,timeOffset=e.time-(now-HPS_WINDOW),phase=e.phase,isScorch=e.isScorch}) end
            table.insert(patternsHistory,{hps=avg,actions=acts,timestamp=now}); table.sort(patternsHistory,function(a,b) return a.hps>b.hps end)
            while #patternsHistory>MAX_PATTERNS do table.remove(patternsHistory) end; if avg>bestAvgHPS then bestAvgHPS=avg end; savePatterns()
        end
    end
end
local function getPatternBonus(action,pos)
    if #patternsHistory==0 then return 0 end; local phase=getPhase(); local isScorch=activeBuffs.ScorchingStar.stacks>0; local best=0
    for _,p in ipairs(patternsHistory) do for _,pa in ipairs(p.actions) do if pa.action==action then
        local pm=(pa.phase==phase); local sm=(pa.isScorch==isScorch); local d=(pos-pa.pos).Magnitude
        if d<PATTERN_COORD_TOLERANCE then local ms=1; if pm and sm then ms=2 elseif pm or sm then ms=1.5 end; if ms>best then best=ms end end
    end end end; return PATTERN_BONUS*best
end

-- ===================== Q-LEARNING =====================
local function getQ(s,a) if not QTable[s] then return 0 end; return QTable[s][a] or 0 end
local function setQ(s,a,v) if not QTable[s] then QTable[s]={} end; QTable[s][a]=v end
task.spawn(function() while true do task.wait(0.2); hasTL=false; for _,t in pairs(activeTokens) do if not t.collected and t.prio>=90 then hasTL=true break end end end end)
local function getDupTargetPractice() local n=tick(); for part,t in pairs(activeTokens) do if not t.collected and part.Parent and t.id==TARGET_PRACTICE_ID and t.duped then local rem=t.life-(n-t.spawn); if rem>1 then return part,t end end end; return nil,nil end
local function getSmileOrDupInArea() local r=getHRP(); if not r then return nil end; local rp=areaRing and areaRing.Position; if not rp then return nil end; local bp=nil; local bd=math.huge; for part,t in pairs(activeTokens) do if not t.collected and part.Parent then local isSmile=(t.id==SMILE_TOKEN_ID); local isDup=(t.id==TARGET_PRACTICE_ID and t.duped); if isSmile or isDup then local dToRing=dist3(part.Position,rp); if dToRing<=areaRingRadius*1.5 then local d=dist3(r.Position,part.Position); if d<bd then bd=d; bp=part end end end end; return bp end
local function encodeState() local r=getHRP(); if not r then return "dead" end; local ph=getPhase(); local tlDist="none"; for part,t in pairs(activeTokens) do if not t.collected and part.Parent and t.prio>=90 then local d=dist3(r.Position,part.Position); if d<20 then tlDist="close" elseif d<60 then tlDist="far" end end end; local purN=math.min(3,#getCH(true,false)); local regN=math.min(3,#getCH(false,true)); local smUrgent=(smileTarget~=nil); local hasPetal=(#fieldPetals>0); local nearTok=false; local n=tick(); for part,t in pairs(activeTokens) do if not t.collected and part.Parent then if (t.life-(n-t.spawn))>1 and dist3(r.Position,part.Position)<30 then nearTok=true break end end end; local zone="mid"; if curField and curField.part and curField.part.Parent then local c=curField.part.Position; local s=curField.part.Size; if s.X>0 and s.Z>0 then local rx=math.abs(r.Position.X-c.X)/(s.X/2); local rz=math.abs(r.Position.Z-c.Z)/(s.Z/2); if rx>0.7 or rz>0.7 then zone="edge" elseif rx<0.3 and rz<0.3 then zone="center" end end end; local chT="none"; if prec.isX10 and not prec.needRefresh then local ct=0; for _,ch in ipairs(chQueue) do if not ch.collected and ch.part.Parent and not ch.isPurple then if dist3(r.Position,ch.part.Position)<20 then ct=ct+1 end end end; if ct>2 then chT="many" elseif ct>0 then chT="some" end end; return string.format("PH:%s|TL:%s|CH:%d|PR:%d|SM:%s|NT:%s|Z:%s|CT:%s|PT:%s",ph,tlDist,regN,purN,tostring(smUrgent),tostring(nearTok),zone,chT,tostring(hasPetal)) end

-- ===================== ДЕЙСТВИЯ =====================
local function getActionsWithBuffs()
    local baseActions = {}; local phase = getPhase(); local now = tick()
    if hasTL then return {"go_tokenlink"} end
    if phase ~= "НАБОР" then for part,t in pairs(activeTokens) do if not t.collected and part.Parent then local rem=t.life-(now-t.spawn); if rem<0.3 and rem>0 then return {"go_urgent_token"} end end end end
    if smileTarget and getDupedTokenCount()>6 then return {"go_smile"} end
    if activeBuffs.PollenMark.active and areaRing then local target=getSmileOrDupInArea(); if target then local t=activeTokens[target]; if t.id==SMILE_TOKEN_ID then table.insert(baseActions,1,"go_smile_area") elseif t.id==TARGET_PRACTICE_ID and t.duped then table.insert(baseActions,1,"go_dup_area") end end end
    if xflameEmergency then local center=getFieldCenter(); local closestCH=nil; local closestDist=XFLAME_CENTER_RADIUS+1; if center~=Vector3.zero then for _,ch in ipairs(chQueue) do if not ch.collected and ch.part.Parent then local d=dist3(ch.part.Position,center); if d<=XFLAME_CENTER_RADIUS and d<closestDist then closestDist=d; closestCH=ch end end end end; if closestCH then return {"go_xflame_ch"} else return {"go_xflame_center"} end end
    if phase=="REFRESH" then local all=getCH(false,false); if #all>0 then table.insert(baseActions,"go_crosshair_refresh") else table.insert(baseActions,"patrol_ring") end; return baseActions end
    if phase=="X10" then local purps=getCH(true,false); if #purps>0 then table.insert(baseActions,"go_purple") end end
    if phase=="X10" or phase=="НАБОР" then
        if #fieldPetals>0 then table.insert(baseActions,"go_petal") end
        local all=getCH(false,false); if #all>0 then table.insert(baseActions,"go_crosshair") end
        local hasAny=false; for _ in pairs(activeTokens) do hasAny=true break end
        if hasAny then table.insert(baseActions,"go_token_near"); table.insert(baseActions,"go_token_best") end
        local dtp=getDupTargetPractice(); if dtp then table.insert(baseActions,"go_dup_tp") end
        if activeBuffs.ScorchingStar.stacks>0 and next(trackedFlames) then table.insert(baseActions,"go_scorching_center") end
        table.insert(baseActions,"patrol_ring")
        if phase=="НАБОР" then table.insert(baseActions,"patrol_random") end
        return baseActions
    end
    return {"patrol_ring"}
end

local function chooseActionWithBuffs(state) local valid=getActionsWithBuffs(); if #valid==0 then return "patrol_ring" end; if math.random()<EPSILON then return valid[math.random(1,#valid)] end; local bestA=valid[1]; local bestQ=getQ(state,bestA); for i=2,#valid do local q=getQ(state,valid[i]); if q>bestQ then bestA=valid[i]; bestQ=q end end; return bestA end
local function doUpdateQ(state,action,reward,nextState)
    local r=getHRP(); local pos=r and r.Position or Vector3.zero
    local patternBonus=getPatternBonus(action,pos); local totalReward=reward+patternBonus
    local valid=getActionsWithBuffs(); local maxNext=0; for _,a in ipairs(valid) do local q=getQ(nextState,a); if q>maxNext then maxNext=q end end
    local old=getQ(state,action); local new=old+ALPHA*(totalReward+GAMMA*maxNext-old); setQ(state,action,new)
    stats.totalReward=stats.totalReward+totalReward; stats.decisions=stats.decisions+1; EPSILON=math.max(0.02,EPSILON*EPSILON_DECAY)
end

-- ===================== PRECISION =====================
local rps_event = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RetrievePlayerStats")
task.spawn(function() while true do task.wait(0.3); if not rps_event then return end; local ok,pd=pcall(rps_event.InvokeServer,rps_event); if not ok or type(pd)~="table" then return end; local function fp(t) if type(t)~="table" then return nil end; if rawget(t,"BuffID")==PREC_BUFF_ID and rawget(t,"Removed")~=true then return t end; if rawget(t,"Src")=="Precision" then return t end; for _,v in pairs(t) do local f=fp(v); if f then return f end end; return nil end; local b=fp(pd); if b then local val=tonumber(b.Value) or 0; local st=tonumber(b.Start) or 0; local dur=tonumber(b.Dur) or 60; local stk=math.min(PREC_MAX,math.round(val/PREC_PER_STACK)); if st~=prec.serverStart then prec.serverStart=st; prec.serverDur=dur; prec.localStart=os.clock() end; prec.stacks=stk; prec.value=val; prec.isX10=(stk>=PREC_MAX) else prec.stacks=0; prec.value=0; prec.isX10=false end end end)
RunService.Heartbeat:Connect(function() if prec.localStart>0 then local elapsed=os.clock()-prec.localStart; prec.timeLeft=math.max(0,prec.serverDur-elapsed); prec.needRefresh=prec.isX10 and (prec.timeLeft<=PREC_REFRESH_AT); if prec.needRefresh and refreshCHCounter==0 then refreshStartTime=tick(); refreshCHCounter=0 end end end)

-- ===================== ВИЗУАЛИЗАЦИЯ =====================
local function updateXFlameCircle() if xflameEmergency then local center=getFieldCenter(); if center==Vector3.zero then local r=getHRP(); if r then center=r.Position end end; if not xflameCircle then xflameCircle=Instance.new("Part"); xflameCircle.Name="XFlameCircle"; xflameCircle.Shape=Enum.PartType.Cylinder; xflameCircle.Anchored=true; xflameCircle.CanCollide=false; xflameCircle.Transparency=0.6; xflameCircle.BrickColor=BrickColor.Red(); xflameCircle.Size=Vector3.new(XFLAME_CENTER_RADIUS*2,0.2,XFLAME_CENTER_RADIUS*2); xflameCircle.Parent=Workspace end; xflameCircle.Position=Vector3.new(center.X,center.Y+0.2,center.Z) else if xflameCircle then xflameCircle:Destroy(); xflameCircle=nil end end end
local function updateScytheCircle() if ENABLED then local r=getHRP(); if r then if not scytheCircle then scytheCircle=Instance.new("Part"); scytheCircle.Name="ScytheRadius"; scytheCircle.Shape=Enum.PartType.Cylinder; scytheCircle.Anchored=true; scytheCircle.CanCollide=false; scytheCircle.Transparency=0.6; scytheCircle.BrickColor=BrickColor.new("Bright orange"); scytheCircle.Size=Vector3.new(FLAME_HIT_DIST*2,0.2,FLAME_HIT_DIST*2); scytheCircle.Parent=Workspace end; scytheCircle.Position=Vector3.new(r.Position.X,r.Position.Y+0.2,r.Position.Z) end else if scytheCircle then scytheCircle:Destroy(); scytheCircle=nil end end end
local function getEdgePoint(targetPos) if not areaRing or not areaRing.Parent then return targetPos end; local center=areaRing.Position; local dir=(targetPos-center).Unit; return clampPos(Vector3.new(center.X+dir.X*areaRingRadius,0,center.Z+dir.Z*areaRingRadius)) end

-- ===================== Crosshair Hit =====================
local CROSSHAIR_HIT_COLOR = Color3.fromRGB(17,134,19); local COLOR_TOLERANCE = 0.05
local function isCrosshairHit(part) if not part or part.Name~="Crosshair" then return false end; local ok,col=pcall(function() return part.Color end); if not ok then return false end; return math.abs(col.R-CROSSHAIR_HIT_COLOR.R)<COLOR_TOLERANCE and math.abs(col.G-CROSSHAIR_HIT_COLOR.G)<COLOR_TOLERANCE and math.abs(col.B-CROSSHAIR_HIT_COLOR.B)<COLOR_TOLERANCE end

-- ===================== ИСПОЛНЕНИЕ ДЕЙСТВИЙ (исправлены continue) =====================
local function executeAction(action)
    local r = getHRP(); if not r then return -1 end
    if action == "go_smile_area" then
        local target = getSmileOrDupInArea(); if not target then return -1 end
        local t = activeTokens[target]; if not t or t.collected or t.id ~= SMILE_TOKEN_ID then return -1 end
        taskLabel="😊 Smile (AreaRing)"; INTERRUPT=false; local edge=getEdgePoint(target.Position); local ok=goTo(edge,4,4)
        if ok and target.Parent then local start=tick(); while tick()-start<TOKEN_STAND_DUR do task.wait(0.1); if not target.Parent or INTERRUPT then break end; local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(target.Position.X,hrp.Position.Y,target.Position.Z) end end; t.collected=true; stats.smileCollected=stats.smileCollected+1; return 45 end; return -10
    elseif action == "go_dup_area" then
        local target = getSmileOrDupInArea(); if not target then return -1 end
        local t = activeTokens[target]; if not t or t.collected or t.id~=TARGET_PRACTICE_ID or not t.duped then return -1 end
        taskLabel="🎯 Dup (AreaRing)"; INTERRUPT=false; local edge=getEdgePoint(target.Position); local ok=goTo(edge,4,4)
        if ok and target.Parent then local start=tick(); while tick()-start<TOKEN_STAND_DUR do task.wait(0.1); if not target.Parent or INTERRUPT then break end; local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(target.Position.X,hrp.Position.Y,target.Position.Z) end end; t.collected=true; stats.tok=stats.tok+1; return 15 end; return -2
    elseif action == "go_smile" then
        local target = smileTarget; if not target or not target.Parent then smileTarget=nil; return -1 end
        local t = activeTokens[target]; if not t or t.collected then smileTarget=nil; return -1 end
        isCollectingSmile=true; taskLabel="😊 Smile"; INTERRUPT=false; local ok=goTo(target.Position,4,math.min(2.5,smileTargetRem-0.2))
        if ok and target.Parent then local start=tick(); while tick()-start<TOKEN_STAND_DUR do task.wait(0.1); if not target.Parent or INTERRUPT then break end; local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(target.Position.X,hrp.Position.Y,target.Position.Z) end end; t.collected=true; smileTarget=nil; stats.smileCollected=stats.smileCollected+1; isCollectingSmile=false; return 45 end
        isCollectingSmile=false; smileTarget=nil; return -10
    elseif action == "go_urgent_token" then
        local now=tick(); local best=nil; local bestLife=0.3
        for part,t in pairs(activeTokens) do if not t.collected and part.Parent then local rem=t.life-(now-t.spawn); if rem<bestLife and rem>0 then bestLife=rem; best=part end end end
        if best then taskLabel="⚡Срочный токен"; INTERRUPT=false; local ok=goTo(best.Position,4,2); if ok and best.Parent then activeTokens[best].collected=true; stats.tok=stats.tok+1; return 25 end; return -2 end; return -1
    elseif action == "go_crosshair_refresh" then
        local all=getCH(false,false)
        if #all==0 then taskLabel="🔍 Поиск CH"; INTERRUPT=false; local rp=getHRP(); if rp then local rndPt=clampPos(rp.Position+Vector3.new((math.random()*2-1)*30,0,(math.random()*2-1)*30)); goTo(rndPt,6,3) end; return 0 end
        local target=all[1]; for _,ch in ipairs(all) do if dist3(r.Position,ch.part.Position)<dist3(r.Position,target.part.Position) then target=ch end end
        taskLabel="🔄 REFRESH"; INTERRUPT=false; local ok=goTo(target.part.Position,4,4,true)
        if ok and target.part.Parent then target.collected=true; refreshCHCounter=refreshCHCounter+1; if target.isPurple then stats.purple=stats.purple+1; lastPurple=target.part else stats.ch=stats.ch+1 end
            goTo(clampPos(r.Position),5,2)
            if refreshCHCounter>=3 then prec.needRefresh=false; cycle.chCollectedCount=0; stats.ref=stats.ref+1; refreshCHCounter=0; taskLabel="✅ REFRESH ОК"; return 35 end; return 12
        end; goTo(clampPos(r.Position),5,2); return -2
    elseif action == "go_purple" then
        local purps=getCH(true,false); if #purps==0 then return -1 end; local reward=0; INTERRUPT=false
        for _,ch in ipairs(purps) do if ch.part.Parent and not ch.collected and not smileTarget and not prec.needRefresh then local ok=goTo(ch.part.Position,4,5); if ok and ch.part.Parent then ch.collected=true; lastPurple=ch.part; stats.purple=stats.purple+1; taskLabel="🟣 1с"; local t0=tick(); while tick()-t0<PURPLE_STAND do task.wait(0.05); if smileTarget or prec.needRefresh or not ENABLED then break end end; reward=reward+30 end end end; return reward>0 and reward or -2
    elseif action == "go_purple_fire" then
        local purps=getCH(true,false); if #purps==0 then return -1 end; local reward=0; local fc=getFireClusterCenter()
        for _,ch in ipairs(purps) do if ch.part.Parent and not ch.collected and not smileTarget and not prec.needRefresh then local ok=goTo(ch.part.Position,4,5); if ok and ch.part.Parent then ch.collected=true; lastPurple=ch.part; stats.purple=stats.purple+1; taskLabel="🟣 1с"; local t0=tick(); while tick()-t0<PURPLE_STAND do task.wait(0.05); if smileTarget or prec.needRefresh or not ENABLED then break end end; reward=reward+30; if fc then taskLabel="🔥 возврат"; goTo(fc,6,3) end end end end; return reward>0 and reward or -2
    elseif action == "stay_purple" then
        if lastPurple and lastPurple.Parent and prec.isX10 and lastPurple:IsDescendantOf(workspace) then taskLabel="🟣 стою"; INTERRUPT=false; goTo(lastPurple.Position,3,2); return 5 else lastPurple=nil; return -1 end
    elseif action == "go_tokenlink" then
        for part,t in pairs(activeTokens) do if not t.collected and part.Parent and t.prio>=90 then taskLabel="💎🔴 Link"; INTERRUPT=false; local ok=goTo(part.Position,5,5); if ok and part.Parent then t.collected=true; ignoreNewTokensUntil=tick()+TOKEN_LINK_COOLDOWN; return 50 end; return -5 end end; return -2
    elseif action == "go_crosshair" then
        local all=getCH(false,false); if #all==0 then return -1 end; local reward=0; INTERRUPT=false
        for _,ch in ipairs(all) do if ch.part.Parent and not ch.collected and not smileTarget and not prec.needRefresh then local shouldSkip=false; local r2=getHRP(); if r2 then for part2,t2 in pairs(activeTokens) do if not t2.collected and part2.Parent and t2.prio>=90 then if dist3(r2.Position,part2.Position)<TL_INTERRUPT_DIST and dist3(r2.Position,ch.part.Position)>30 then shouldSkip=true; break end end end end; if not shouldSkip then local ok=goTo(ch.part.Position,4,5); if ok and ch.part.Parent then ch.collected=true; if ch.isPurple then stats.purple=stats.purple+1; lastPurple=ch.part; reward=reward+10 else stats.ch=stats.ch+1; cycle.chCollectedCount=cycle.chCollectedCount+1; if cycle.chCollectedCount>=3 then cycle.chCollectedCount=0 end; reward=reward+8 end end end end end
        if reward>0 and activeBuffs.PollenMark.active and activeBuffs.PollenMark.pos then taskLabel="🏠 возврат в AreaRing"; goTo(activeBuffs.PollenMark.pos,6,4) end; return reward>0 and reward or -2
    elseif action == "go_crosshair_all" then
        local all=getCH(false,false); if #all==0 then return -1 end; local reward=0
        for _,ch in ipairs(all) do if not ch.collected and ch.part.Parent then local ok=goTo(ch.part.Position,4,5); if ok then ch.collected=true; if ch.isPurple then stats.purple=stats.purple+1; lastPurple=ch.part; reward=reward+10 else stats.ch=stats.ch+1; reward=reward+8 end end end end
        if reward>0 and activeBuffs.PollenMark.active and activeBuffs.PollenMark.pos then taskLabel="🏠 возврат в AreaRing"; goTo(activeBuffs.PollenMark.pos,6,4) end; return reward
    elseif action == "go_dup_tp" then
        local part,t=getDupTargetPractice(); if not part then return -1 end; taskLabel="🎯 Dup"; INTERRUPT=false; local ok=goTo(part.Position,5,5)
        if ok and part.Parent then local start=tick(); while tick()-start<TOKEN_STAND_DUR do task.wait(0.1); if not part.Parent or INTERRUPT then break end; local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(part.Position.X,hrp.Position.Y,part.Position.Z) end end; t.collected=true; return 15 end; return -2
    elseif action == "go_petal" then -- исправлен цикл
        if #fieldPetals==0 then return -1 end; local collectedAny=false; local totalReward=0; local i=1
        while i<=#fieldPetals do
            local petal=fieldPetals[i]
            if not petal.part.Parent then table.remove(fieldPetals,i)
            elseif stuckPetals[petal.part] and tick()<stuckPetals[petal.part] then table.remove(fieldPetals,i)
            else
                taskLabel="🌸 "..petal.colorName; INTERRUPT=false; local ok=goTo(Vector3.new(petal.part.Position.X,0,petal.part.Position.Z),PETAL_COLLECT_DIST,2.5)
                if ok then stats.petalsCollected=stats.petalsCollected+1; totalReward=totalReward+8+(14-petal.priority); collectedAny=true; task.wait(0.05); i=i+1
                else stuckPetals[petal.part]=tick()+5; table.remove(fieldPetals,i) end
            end
        end
        return collectedAny and totalReward or -1
    elseif action == "go_token_near" then
        local best=nil; local bestD=math.huge; for part,t in pairs(activeTokens) do if not t.collected and part.Parent then local d=dist3(r.Position,part.Position); if d<bestD then best=part; bestD=d end end end
        if best then local t=activeTokens[best]; taskLabel="💎 "..t.name; INTERRUPT=false; local ok=goTo(best.Position,5,5); if ok and best.Parent then t.collected=true; return 3+t.prio*0.2 end; return -2 end; return -1
    elseif action == "go_token_best" then
        local best=nil; local bestP=-1; local now=tick(); for part,t in pairs(activeTokens) do if not t.collected and part.Parent then local rem=t.life-(now-t.spawn); if rem>0.5 and t.prio>bestP then best=part; bestP=t.prio end end end
        if best then local t=activeTokens[best]; taskLabel="💎⭐ "..t.name; INTERRUPT=false; local ok=goTo(best.Position,5,5); if ok and best.Parent then t.collected=true; return 5+t.prio*0.3 end; return -3 end; return -1
    elseif action == "patrol_ring" then
        local function rndRing() if areaRing and areaRing.Parent and curField then local c=areaRing.Position; local a=math.random()*2*math.pi; local r=areaRingRadius*(0.5+math.random()*0.8); return clampPos(Vector3.new(c.X+math.cos(a)*r,0,c.Z+math.sin(a)*r)) elseif curField then local c=curField.part.Position; local s=curField.part.Size; local mx=math.max(s.X/2*0.3,5); local mz=math.max(s.Z/2*0.3,5); return Vector3.new(c.X+(math.random()*2-1)*mx,0,c.Z+(math.random()*2-1)*mz) else local rp=getHRP(); return rp and rp.Position+Vector3.new((math.random()*2-1)*30,0,(math.random()*2-1)*30) or Vector3.zero end end
        taskLabel="🚶 кольцо"; INTERRUPT=false; local target=rndRing(); if target==Vector3.zero then target=getFieldCenter() end; if target==Vector3.zero then return 0 end; goTo(target,6,PATROL_TIMEOUT); task.wait(0.1+math.random()*0.3); return 0
    elseif action == "patrol_random" then
        local function rndF() if curField then local c=curField.part.Position; local s=curField.part.Size; local mx=math.max(s.X/2-3,1); local mz=math.max(s.Z/2-3,1); return Vector3.new(c.X+(math.random()*2-1)*mx,0,c.Z+(math.random()*2-1)*mz) else local rp=getHRP(); return rp and rp.Position+Vector3.new((math.random()*2-1)*30,0,(math.random()*2-1)*30) or Vector3.zero end end
        taskLabel="🚶 патруль"; INTERRUPT=false; local target=rndF(); if target==Vector3.zero then target=getFieldCenter() end; if target==Vector3.zero then return 0 end; goTo(target,4,PATROL_TIMEOUT); task.wait(0.2+math.random()*0.4); return 0
    elseif action == "go_scorching_center" then
        local center=getFireClusterCenter(); if not center then return -1 end; if dist3(r.Position,center)<=5 then taskLabel="🔥 Scorching (центр)"; INTERRUPT=false; task.wait(0.2); return 2 else taskLabel="🔥 Scorching центр"; INTERRUPT=false; goTo(center,5,5); return 2 end
    elseif action == "go_fire_center" then
        local center=getFireClusterCenter(); if center then taskLabel="🔥 центр огня"; goTo(center,8,3); return 0 end; return -1
    elseif action == "go_field_center" then
        local center=getFieldCenter(); if center and center~=Vector3.zero then taskLabel="🎯 центр поля"; goTo(center,10,3); return 0 end; return -1
    elseif action == "go_field_center_strict" then
        local center=getFieldCenter(); if center and center~=Vector3.zero then taskLabel="🎯 центр (строгий)"; goTo(center,5,3); return 0 end; return -1
    elseif action == "go_nearest_center_ch" then
        local center=getFieldCenter(); if center==Vector3.zero then center=r.Position end; local bestCH=nil; local bestDist=math.huge; for _,ch in ipairs(chQueue) do if not ch.collected and ch.part.Parent then local d=dist3(ch.part.Position,center); if d<bestDist then bestDist=d; bestCH=ch end end end; if bestCH and bestDist<=10 then taskLabel="🎯 CH центр"; goTo(bestCH.part.Position,4,5); return 5 end; return -1
    elseif action == "go_xflame_center" then
        local center=getFieldCenter(); if center==Vector3.zero then return -1 end; taskLabel="🔥 XFlame в центр"; INTERRUPT=false; goTo(center,3,3); return 0
    elseif action == "go_xflame_ch" then
        local center=getFieldCenter(); if center==Vector3.zero then return -1 end; local bestCH=nil; local bestDist=XFLAME_CENTER_RADIUS+1; for _,ch in ipairs(chQueue) do if not ch.collected and ch.part.Parent then local d=dist3(ch.part.Position,center); if d<=XFLAME_CENTER_RADIUS and d<bestDist then bestDist=d; bestCH=ch end end end; if bestCH then taskLabel="🔥 XFlame CH"; INTERRUPT=false; goTo(bestCH.part.Position,2,3); task.wait(1); return 5 end; return -1
    end
    return 0
end

-- ===================== ГЛАВНЫЙ ЦИКЛ =====================
RunService.Heartbeat:Connect(function() if not ENABLED or not prec.isX10 or prec.needRefresh then return end; local r=getHRP(); if not r then return end; local now=tick(); for _,ch in ipairs(chQueue) do if ch.part and ch.part.Parent and not ch.collected and not ch.isPurple then if isCrosshairHit(ch.part) and now-lastPenaltyTime>1.5 then lastPenaltyTime=now; local state=encodeState(); if state and state~="dead" then pcall(doUpdateQ,state,"patrol_ring",-20,state) end; stats.chAvoided=stats.chAvoided+1; break end end end end)

-- ===================== Q-ТАБЛИЦА =====================
local Q_FILE="bss_ai_q_v12.json"
local function resetQ() QTable={}; EPSILON=0.1; stats.totalReward=0; stats.decisions=0; local ok,j=pcall(HttpService.JSONEncode,HttpService,{version=Q_VERSION,qtable={},meta={resetAt=os.time()}}); if ok then pcall(writefile,Q_FILE,j) end end
local function loadQ() local ok,raw=pcall(readfile,Q_FILE); if ok and raw then local ok2,d=pcall(HttpService.JSONDecode,HttpService,raw); if ok2 and type(d)=="table" and d.version==Q_VERSION and type(d.qtable)=="table" then QTable=d.qtable end end end
local function saveQ() local qc=0; for _ in pairs(QTable) do qc=qc+1 end; local d={version=Q_VERSION,qtable=QTable,meta={stateCount=qc,epsilon=math.floor(EPSILON*1000)/1000,userId=tostring(LP.UserId),savedAt=os.time(),totalReward=math.floor(stats.totalReward),decisions=stats.decisions}}; local ok,j=pcall(HttpService.JSONEncode,HttpService,d); if ok then pcall(writefile,Q_FILE,j) end end
task.spawn(function() while true do task.wait(300) saveQ() end end)

-- ===================== ЗАПУСК =====================
task.spawn(function() loadPatterns(); while true do task.wait(HPS_READ_INTERVAL); if ENABLED then pcall(updateHPSBuffers) end end end)
task.spawn(function() task.wait(4); loadQ(); findAreaRing(); print("✅ BSS AI v12.7 safe+ фиол.стойка только при X10. T/G/P"); taskLabel="инициализация"; lastMoveTime=tick()
while true do task.wait(0.03)
    if not ENABLED then task.wait(0.3) else
        xflameEmergency=(activeBuffs.XFlame.stacks>=20); if xflameEmergency then INTERRUPT=true end
        updateXFlameCircle(); updateScytheCircle()
        local r=getHRP()
        if r then local vel=r.AssemblyLinearVelocity; local hSpeed=(Vector3.new(vel.X,0,vel.Z)).Magnitude
            if hSpeed>0.2 then lastMoveTime=tick()
            elseif tick()-lastMoveTime>5 and not stuckWarning then stuckWarning=true; INTERRUPT=true; taskLabel="⏳ сброс"
                if lastPurple and not lastPurple.Parent then lastPurple=nil end
                if smileTarget and not smileTarget.Parent then smileTarget=nil; isCollectingSmile=false end
                INTERRUPT=false; lastMoveTime=tick()
            end
        end
        if INTERRUPT and not smileTarget and not prec.needRefresh and not xflameEmergency then INTERRUPT=false end
        local state=encodeState(); local action=chooseActionWithBuffs(state); local ok,reward=pcall(executeAction,action); if not ok then reward=-1 end; local nextState=encodeState(); pcall(doUpdateQ,state,action,reward,nextState)
    end
end end)

-- ===================== GUI =====================
local sg=Instance.new("ScreenGui",PGui) sg.Name="BSSAI_GUI"
local frame=Instance.new("Frame",sg) frame.Size=UDim2.new(0,220,0,80) frame.Position=UDim2.new(0,10,0,10) frame.BackgroundColor3=Color3.fromRGB(20,20,30) frame.BackgroundTransparency=0.15 frame.BorderSizePixel=0 frame.Active=true frame.Draggable=true Instance.new("UICorner",frame).CornerRadius=UDim.new(0,6)
local title=Instance.new("TextLabel",frame) title.Size=UDim2.new(1,0,0,20) title.Position=UDim2.new(0,0,0,2) title.BackgroundTransparency=1 title.Text="🧠 BSS AI v12.7 safe+" title.TextColor3=Color3.fromRGB(100,200,255) title.Font=Enum.Font.GothamBold title.TextSize=12 title.TextXAlignment=Enum.TextXAlignment.Center
local label=Instance.new("TextLabel",frame) label.Size=UDim2.new(1,0,0,18) label.Position=UDim2.new(0,0,0,24) label.BackgroundTransparency=1 label.Text="Действие: старт" label.TextColor3=Color3.fromRGB(255,255,255) label.Font=Enum.Font.Gotham label.TextSize=13 label.TextXAlignment=Enum.TextXAlignment.Center
local hpsLabel=Instance.new("TextLabel",frame) hpsLabel.Size=UDim2.new(1,0,0,18) hpsLabel.Position=UDim2.new(0,0,0,44) hpsLabel.BackgroundTransparency=1 hpsLabel.Text="HPS: -- | Рекорд: --" hpsLabel.TextColor3=Color3.fromRGB(150,255,150) hpsLabel.Font=Enum.Font.Gotham hpsLabel.TextSize=12 hpsLabel.TextXAlignment=Enum.TextXAlignment.Center
task.spawn(function() while true do task.wait(0.3) label.Text="🎯 "..taskLabel; local cur=getHoneyPerSecond(); local hpsStr=cur>0 and string.format("%.0f",cur) or "--"; local bestStr=bestAvgHPS>0 and string.format("%.0f",bestAvgHPS) or "--"; hpsLabel.Text="HPS: "..hpsStr.." | Рекорд: "..bestStr end end)
UserInputService.InputBegan:Connect(function(input,gp) if gp then return end; if input.KeyCode==Enum.KeyCode.T then ENABLED=not ENABLED; sg.Enabled=ENABLED elseif input.KeyCode==Enum.KeyCode.G then resetQ() elseif input.KeyCode==Enum.KeyCode.P then print("Phase: "..getPhase().." ε:"..string.format("%.3f",EPSILON).." R:"..stats.totalReward); local c=0; for _ in pairs(QTable) do c=c+1 end; print("States: "..c); print("Patterns: "..#patternsHistory) end end)
LP.CharacterAdded:Connect(function() task.wait(2) activeTokens={} chQueue={} lastPurple=nil curField=nil taskLabel="старт" smileTarget=nil isCollectingSmile=false INTERRUPT=false cycle={chCollectedCount=0} trackedFlames={} fieldPetals={} ignoreNewTokensUntil=0 refreshCHCounter=0 if xflameCircle then xflameCircle:Destroy() xflameCircle=nil end if scytheCircle then scytheCircle:Destroy() scytheCircle=nil end saveQ() end)
print("✅ BSS AI v12.7 safe+ готов. Все функции на месте.")
