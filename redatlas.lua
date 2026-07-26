-- Marmot Z v5.2.8
local P=game:GetService("Players");local W=game:GetService("Workspace")
local R=game:GetService("RunService");local U=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage");local H=game:GetService("HttpService")
local V=game:GetService("VirtualInputManager");local D=game:GetService("Debris")
local L=P.LocalPlayer;local G=L:WaitForChild("PlayerGui");local ENABLED=true;local ELA=true
if not math.round then math.round=function(n)return math.floor(n+.5)end end
Q_VERSION="Marmot Z - HRL & Velocity Overdrive v5.2.8"
task.wait(2)

-- COMPAT
local ZERO=Vector3.new(0,0,0)
local function cfLookAt(from,to)local ok,res=pcall(function()return CFrame.lookAt(from,to)end);if ok and res then return res end;return CFrame.new(from,to)end

-- FORWARD DECLARATIONS (используются раньше, чем определяются ниже по файлу)
local gFCB,gFCPath,scanPreciseBee

-- ERROR GUI
local elog,egui,elbl,ebtn,ecnt={},nil,nil,nil,0
local function mkE()pcall(function()if egui then return end
egui=Instance.new("ScreenGui");egui.Name="E";egui.ResetOnSpawn=false;egui.Parent=G
local b=Instance.new("Frame",egui);b.Size=UDim2.new(0,380,0,240);b.Position=UDim2.new(.5,-190,.5,-120)
b.BackgroundColor3=Color3.fromRGB(15,15,25);b.BackgroundTransparency=.08;b.BorderSizePixel=0;b.Active=true;b.Draggable=true
Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
local t=Instance.new("TextLabel",b);t.Size=UDim2.new(1,-16,0,24);t.Position=UDim2.new(0,8,0,8);t.BackgroundTransparency=1
t.Text="Marmot Z v5.2.5";t.TextColor3=Color3.fromRGB(255,180,60);t.Font=Enum.Font.GothamBold;t.TextSize=14;t.TextXAlignment=Enum.TextXAlignment.Left
elbl=Instance.new("TextLabel",b);elbl.Size=UDim2.new(1,-16,0,130);elbl.Position=UDim2.new(0,8,0,42);elbl.BackgroundTransparency=1
elbl.Text="Marmot Z boot...";elbl.TextColor3=Color3.fromRGB(200,200,200);elbl.Font=Enum.Font.Code;elbl.TextSize=11;elbl.TextWrapped=true;elbl.RichText=true
ebtn=Instance.new("TextButton",b);ebtn.Size=UDim2.new(0,140,0,28);ebtn.Position=UDim2.new(0,8,0,180)
ebtn.Text="Copy logs";ebtn.TextColor3=Color3.fromRGB(220,220,220);ebtn.Font=Enum.Font.Gotham;ebtn.TextSize=11
Instance.new("UICorner",ebtn).CornerRadius=UDim.new(0,4)
local cb=Instance.new("TextButton",b);cb.Size=UDim2.new(0,80,0,28);cb.Position=UDim2.new(0,156,0,180)
cb.Text="Close";cb.TextColor3=Color3.fromRGB(220,220,220);cb.Font=Enum.Font.Gotham;cb.TextSize=11
Instance.new("UICorner",cb).CornerRadius=UDim.new(0,4)
cb.MouseButton1Click:Connect(function()egui.Enabled=false;egui:Destroy()end)
ebtn.MouseButton1Click:Connect(function()local x=table.concat(elog,"\n");if #x==0 then x="No errors"end;pcall(setclipboard,x);ebtn.Text="Done";task.wait(1.5);ebtn.Text="Copy logs"end)
task.spawn(function()task.wait(4);if egui and ecnt==0 then egui.Enabled=false;egui:Destroy()end end)end)end
local function le(m)ecnt=ecnt+1;table.insert(elog,string.format("[%02d] %s",ecnt,m));while #elog>20 do table.remove(elog,1)end;if elbl then local LL={};for i=math.max(1,#elog-12),#elog do table.insert(LL,elog[i])end;elbl.Text=table.concat(LL,"\n");if ecnt==1 then elbl.TextColor3=Color3.fromRGB(255,140,100)end end;warn("MarmotZ:",m)end
local function lo(m)if elbl then elbl.Text="o "..m;elbl.TextColor3=Color3.fromRGB(140,255,160)end end
mkE();lo("GUI OK")

-- HELPERS
local HRP,HUM=nil,nil
local function upC(c)if c then HRP=c:WaitForChild("HumanoidRootPart",3);HUM=c:WaitForChild("Humanoid",3)else HRP,HUM=nil,nil end end
if L.Character then upC(L.Character)end
L.CharacterAdded:Connect(upC)
L.CharacterRemoving:Connect(function()HRP,HUM=nil,nil end)
local function h()return HRP end
local function hm()return HUM end
local function ti(t)if not t then return nil end;return tonumber(t:match("rbxassetid://(%d+)")or t:match("id=(%d+)"))end
local function d3(a,b)local dx=a.X-b.X;local dz=a.Z-b.Z;return math.sqrt(dx*dx+dz*dz)end
local function d3d(a,b)return(a-b).Magnitude end
local function d2Sq(a,b)local dx=a.X-b.X;local dz=a.Z-b.Z;return dx*dx+dz*dz end
local function fmtH(v)if v>=1e12 then return string.format("%.2fT",v/1e12)end;if v>=1e9 then return string.format("%.2fB",v/1e9)end;if v>=1e6 then return string.format("%.2fM",v/1e6)end;if v>=1e3 then return string.format("%.1fK",v/1e3)end;return string.format("%.0f",v)end
local function getHoney()local cs=L:FindFirstChild("CoreStats");if cs then local hv=cs:FindFirstChild("Honey");if hv then return hv.Value or 0 end end;return 0 end

-- ANIM
local function lootAnim(pos,dur)if not pos then return end;local r=h();if not r then return end
local spark=Instance.new("Part");spark.Shape=0;spark.Size=Vector3.new(1.2,1.2,1.2);spark.Anchored=true;spark.CanCollide=false;spark.Position=Vector3.new(pos.X,pos.Y+2,pos.Z)
spark.BrickColor=BrickColor.new("Bright yellow");spark.Material=Enum.Material.Neon;spark.Transparency=0.3;spark.Parent=W;D:AddItem(spark,dur+0.2)
local bg=r:FindFirstChild("BG_Loot")or Instance.new("BodyGyro");bg.Name="BG_Loot";bg.MaxTorque=Vector3.new(0,40000,0);bg.P=8000;bg.D=300;bg.Parent=r
local dir=pos-r.Position;dir=Vector3.new(dir.X,0,dir.Z);if dir.Magnitude>0.1 then bg.CFrame=CFrame.new(r.Position,r.Position+dir)end;D:AddItem(bg,dur*1.2)end

-- CONSTANTS
SB={NABOR=70,X10=90,REFRESH=75}
SJ=3;AM=1.2;DGL=22;FM=3;AD=5;MT=6
PBI=2574507284;PLMBI=2577647417;PPK=0.02;PMX=10;PRAT=25
PURP=Color3.fromRGB(119,85,255);PTOL=12;SMI=5877939956;TSD=1.1
ARR=20;TLID=20;PCD=8;PFM=20;TPI=8173559749
TLC=2;PT=8;XCR=15;PCHR=10;SCYTHE_DIST=14;SCYTHE_CD=0.1
AL=0.5;GA=0.95;EP=0.3;ED=0.9995;PMBI=2577647416;epT0=0;lastActA="";lastActRw=0;xfcCd=0
SCORCH_BIAS=1.15;PAT_WINDOW=2400;PAT_TOP=10;TD_LAMBDA=0.7;UCB_C=1.5
FLAME_CLUSTER_RADIUS=8;FLAME_CLUSTER_MIN=3;FLAME_PATH_STEP=6-- v5.1.8: min кластера 4->3, флейм-патхи формируются чаще (больше бега по огням); кемп одиночного кластера по-прежнему требует size>=4 (явные проверки)
DPRI={[4519549299]=true,[2499540966]=true,[2499514197]=true,[4528379338]=true,[1442859163]=true,[1442863423]=true,[3877732821]=true,[1442764904]=true,[4528208186]=true,[8173559749]=true}
-- TOKEN DEFS (v5.1: ПОЛНЫЙ сет из v4.0 — префиксы, цвета, dc для дюпед; bt=true — батл-токен)
TKS={}
TKS[1629547638]={n="TL",base=4,p=99,pre="TL ",nc=Color3.new(0,0,0),bg=Color3.new(1,1,1),bt=true}
TKS[8173559749]={n="TP",base=8,p=95,pre="TP ",nc=Color3.new(.7,.2,.9),dc=Color3.new(.5,.1,.7),bg=Color3.new(0,0,0),bt=true}
TKS[2000457501]={n="IN",base=8,p=25,pre="IN ",nc=Color3.new(1,1,0),dc=Color3.new(1,.84,0),bg=Color3.new(0,0,0)}
TKS[1472256444]={n="BL",base=8,p=22,pre="BL ",nc=Color3.new(1,.7,.8),dc=Color3.new(.8,.5,.6),bg=Color3.new(0,0,0),bt=true}
TKS[1629649299]={n="FC",base=4,p=15,pre="FC ",nc=Color3.new(.3,.6,1),bg=Color3.new(0,0,0),bt=true}
TKS[65867881]={n="HS",base=4,p=15,pre="HS ",nc=Color3.new(.2,1,.2),bg=Color3.new(0,0,0),bt=true}
TKS[1442863423]={n="BB",base=4,p=12,pre="BB ",nc=Color3.new(.2,.4,1),bg=Color3.new(0,0,0)}
TKS[1442859163]={n="RB",base=4,p=12,pre="RB ",nc=Color3.new(1,.2,.2),bg=Color3.new(0,0,0)}
TKS[3877732821]={n="WB",base=4,p=12,pre="WB ",nc=Color3.new(1,1,1),bg=Color3.new(0,0,0)}
TKS[1442764904]={n="R+",base=4,p=12,pre="R+ ",nc=Color3.new(1,.3,.1),bg=Color3.new(0,0,0)}
TKS[1442700745]={n="RG",base=8,p=10,pre="RG ",nc=Color3.new(1,.1,.1),bg=Color3.new(0,0,0),bt=true}
TKS[253828517]={n="ML",base=8,p=10,pre="ML ",nc=Color3.new(1,.5,1),bg=Color3.new(0,0,0),bt=true}
TKS[2499514197]={n="HM",base=8,p=9,pre="HM ",nc=Color3.new(1,.8,.2),bg=Color3.new(0,0,0)}
TKS[2499540966]={n="PM",base=8,p=9,pre="PM ",nc=Color3.new(1,.9,.4),bg=Color3.new(0,0,0)}
for _,id in ipairs({1472532912,1472491940,1472425802,2032949183,1472580249,1489734171})do TKS[id]={n="MO",base=15,p=8,mo=true,pre="MO ",nc=Color3.new(.9,.7,.5),dc=Color3.new(.6,.4,.2),bg=Color3.new(0,0,0),bt=true}end
TKS[1874564120]={n="PL",base=12,p=7,pre="PL ",nc=Color3.new(.2,1,1),bg=Color3.new(0,0,0)}
TKS[4528379338]={n="MS",base=4,p=7,pre="MS ",nc=Color3.new(.8,.5,1),bg=Color3.new(0,0,0)}
TKS[3582501342]={n="RC",base=24,p=6,pre="RC ",nc=Color3.new(.3,.5,1),bg=Color3.new(0,0,0)}
TKS[3582519526]={n="TN",base=24,p=6,pre="TN ",nc=Color3.new(.5,.5,.5),bg=Color3.new(0,0,0)}
TKS[5877998606]={n="MH",base=16,p=6,pre="MH ",nc=Color3.new(.8,.2,.8),bg=Color3.new(0,0,0)}
TKS[8083943936]={n="SP",base=24,p=6,pre="SP ",nc=Color3.new(1,.8,.2),bg=Color3.new(0,0,0)}
TKS[177997841]={n="GB",base=4,p=6,pre="GB ",nc=Color3.new(.2,.8,1),bg=Color3.new(0,0,0)}
TKS[1839454544]={n="GS",base=4,p=6,pre="GS ",nc=Color3.new(.2,1,.5),bg=Color3.new(0,0,0)}
TKS[1442725244]={n="BM",base=4,p=5,pre="BM ",nc=Color3.new(.5,.5,.5),bg=Color3.new(0,0,0)}
TKS[5877939956]={n="SM",base=4,p=5,pre="SM ",nc=Color3.new(1,1,1),dc=Color3.new(1,1,1),bg=Color3.new(0,0,0),bt=true}
TKS[4519549299]={n="IF",base=4,p=5,pre="IF ",nc=Color3.new(1,.4,.1),bg=Color3.new(0,0,0),bt=true}
TKS[4519523935]={n="TR",base=4,p=5,pre="TR ",nc=Color3.new(.2,.8,.3),bg=Color3.new(0,0,0)}
TKS[4528414666]={n="SF",base=8,p=5,pre="SF ",nc=Color3.new(.2,1,.2),bg=Color3.new(0,0,0)}
TKS[4528208186]={n="FF",base=8,p=5,pre="FF ",nc=Color3.new(1,.5,.1),bg=Color3.new(0,0,0),bt=true}
TKS[1671281844]={n="BS",base=12,p=4,pre="BS ",nc=Color3.new(.9,.9,.2),bg=Color3.new(0,0,0)}
TKS[8083436978]={n="BBL",base=4,p=4,pre="BBL ",nc=Color3.new(.3,.5,1),bg=Color3.new(0,0,0)}
TKS[1104415222]={n="BT",base=4,p=4,pre="BT ",nc=Color3.new(1,.8,.5),bg=Color3.new(0,0,0)}
TKS[2319100769]={n="FT",base=8,p=4,pre="FT ",nc=Color3.new(.7,.5,.3),bg=Color3.new(0,0,0)}
TKS[4889322534]={n="FB",base=4,p=4,pre="FB ",nc=Color3.new(.9,.7,.2),bg=Color3.new(0,0,0)}
TKS[2319083910]={n="IP",base=24,p=4,pre="IP ",nc=Color3.new(.6,.3,.1),bg=Color3.new(0,0,0)}
TKS[3080529618]={n="JB",base=4,p=4,pre="JB ",nc=Color3.new(1,.5,.8),bg=Color3.new(0,0,0)}
TKS[4889470194]={n="PH",base=4,p=4,pre="PH ",nc=Color3.new(.9,.9,.5),bg=Color3.new(0,0,0)}
TKS[107187190]={n="HG",base=4,p=2,pre="HG ",nc=Color3.new(1,.8,.3),bg=Color3.new(0,0,0)}
TKS[183390139]={n="CG",base=4,p=2,pre="CG ",nc=Color3.new(.6,.6,.6),bg=Color3.new(0,0,0)}
AV={};for _,v in ipairs({1674871631,1471882621,1952740625,8055428094,2319943273,3030569073,3036899811,3080740120,3012679515,1838129169,2584584968,1471849394,1952682401,6087969886,2028574353,2028453802})do AV[v]=true end
PC={Red=Color3.fromRGB(249,34,34),Pink=Color3.fromRGB(255,130,201)};PP={Red=1,Pink=2}

-- STATE
aT,cQ,lP,curF,tL={},{},nil,nil,"start"
prec={st=0,val=0,isX=false,ls=0,sD=60,sS=0,tL=0,nR=false}
st={tk=0,ch=0,pr=0,rf=0,tR=0,dc=0,sm=0,chA=0,pt=0,chP=0}
cyc={chC=0};INT=false;isCS=false;smT=nil;smTR=0
fP={};aR=nil;aRR=ARR
aB={SS={st=0},XF={st=0},PM={a=false},PoM={a=false,pos=nil,m=0},PollM={combo=0,active=false} }
stP=setmetatable({},{__mode="k"})
QT={};lMT=os.clock();stW=false;xfE=false;lPT=0;rCC=0;rST=0
qTables={};fldHash=nil;dupCnt=0;eligibility={};visitCount={};totalSteps=0
lastActionTime=0;flHit=0;chStick=0;aborted=false
cS=70;hbF=0;isA=false;scorchActive=false;scorchRecording=false;scorchActions={};scorchSessions={};top10={}
bestSH=0;lastPS=0;scytheParts=setmetatable({},{__mode="k"});lastSHit=0
activeCocos={};activeShowers={};activeTG={};activeBlooms={};flameCD=setmetatable({},{__mode="k"})
scriptStartH=0;scriptStartT=0;scorchStartH=0;scorchStartT=0;pollMS=0
scorchPurpleCount=0;scorchPurpleTime=0;scorchAllCHMode=false;scorchPurpleTotal=0;lastSOTime=0;scorchDupedMorphDone=false
xfP=0;scP=0;lastBH=0;redPT=0;stFlMin=0;xGCH=0;lastTLT=0;goSm=false
tokenVerify={};ndMorph=nil;scorchTPIndex=0;scorchTPTable={};scorchTPCycle=false;actLog={};scorchAllCHT0=0;flCampAcc=0;flCampCd=0;ptSeen={};tcFires=0;pabCalls=0;_tcPrev=0;_pabPrev=0;_tkPrev=0;smCd=0;cATLastSide=0;prPauseUntil=0;prPauseNext=os.clock()+900-- v5.2.8: пауза лута прецов: раз в 15 мин (900с) вне скорча — 30с без прецов. v5.2.5: _tkPrev(база собранных токенов для дельты col), smCd(кулдаун смайла), cATLastSide(сторона обхода для гистерезиса). v5.2.4: счётчики частоты ремоутов (tcFires=ToolCollect:FireServer, pabCalls=RetrievePlayerStats:InvokeServer) для замера в кик-снапшоте (гипотеза E3: 277 от спама синхронных ремоутов)
local xfStartTime=0;local flameCampStart=0
local cocoCnt=0;local showerCnt=0;local purpleMarkCnt=0;cocoCycle=0;showerCycle=0-- v5.2.6: счётчики цикла по ворнинг-дискам (глобалы): сбрасываются, когда все диски кокоса/шовера исчезли
local tokenBL=setmetatable({},{__mode="k"})
local greenCH_cache={};local preciseLearn={}
-- v5.0: нектары и Hachapuri (глобалы, чтобы не упереться в лимит локалов)
NECTAR_SRC={["Invigorating Nectar"]="inv",["Refreshing Nectar"]="ref",["Satisfying Nectar"]="sat",["Motivating Nectar"]="mot",["Comforting Nectar"]="comf"}
nectarRem={inv=0,ref=0,sat=0,mot=0,comf=0}
hchDodge=false;hchBusy=false;hchSmT0=0

-- CONFIG
local cfg={ss_on=false,sp_x10=90,sp_nab=70,sp_ref=75,coco_on=true,coco_lim=0,shower_on=true,shower_lim=0,purple_on=true,purple_lim=0,hachapuri=false,pl_auto=false,pl_inv=false,pl_ref=false,pl_sat=false,pl_mot=false,pl_comf=false,pl_inv_h=22,pl_ref_h=22,pl_sat_h=22,pl_mot_h=22,pl_comf_h=22,pl_min=43,mv_mode="tp",tw_speed=150,ac_test=false,rejoin_on=true}
-- v5.1.4: конфиг и история плантеров в ОДНОМ файле marmot_z_data.json ({cfg=...,plHist=...}); старые marmot_z_config.json/marmot_z_planters.json читаются один раз как фолбэк для миграции
local function saveCfg()if writefile then pcall(function()writefile("marmot_z_data.json",H:JSONEncode({cfg=cfg,plHist=plHist or PLHIST_LOADED}))end)end end
local function loadCfg()if not readfile then return end
local d=nil
local ok,raw=pcall(readfile,"marmot_z_data.json")
if ok and raw then local ok2,dd=pcall(H.JSONDecode,H,raw);if ok2 and type(dd)=="table"then d=dd.cfg;if type(dd.plHist)=="table"then PLHIST_LOADED=dd.plHist end end end
if not d then local ok3,raw3=pcall(readfile,"marmot_z_config.json");if ok3 and raw3 then local ok4,d4=pcall(H.JSONDecode,H,raw3);if ok4 and type(d4)=="table"then d=d4 end end end
if type(d)=="table"then for k,v in pairs(d)do if cfg[k]~=nil then cfg[k]=v end end;SB.X10=cfg.sp_x10;SB.NABOR=cfg.sp_nab;SB.REFRESH=cfg.sp_ref end
end
loadCfg()
-- v5.0.5: диагностика прав на файлы — если экзекутор не дал writefile, ни один JSON не сохранится — теперь об этом будет красное сообщение в GUI ошибок
task.spawn(function()task.wait(3)
if not writefile then le("writefile НЕДОСТУПЕН: JSON (data/scorch/q/pat) НЕ сохраняются! Включи доступ к файлам в настройках executor")
else local okW=pcall(function()writefile("marmot_z_wtest.json","{}")end)
if not okW then le("writefile есть, но запись падает — проверь папку workspace у executor")
else
-- v5.1.4: тест-файл marmot_z_wtest.json удаляем сразу после проверки; после первой записи marmot_z_data.json подчищаем старые config/planters json
if delfile then pcall(delfile,"marmot_z_wtest.json")end
pcall(saveCfg)
if delfile and isfile and isfile("marmot_z_data.json")then pcall(delfile,"marmot_z_config.json");pcall(delfile,"marmot_z_planters.json")end
end end
end)

-- SPATIAL STATE (оптимизировано: кэш + ленивый пересчёт только при реальном движении)
local function ph()if not prec.isX then return"NABOR"end;if prec.nR then return"REFRESH"end;return"X10"end
local function scPh()if aB.SS.st>0 then return"INSIDE"end;return"OUTSIDE"end
local function gQ(s,a)if not QT[s]then QT[s]={}end;return QT[s][a]or 0 end
local function sQ(s,a,v)if not QT[s]then QT[s]={}end;QT[s][a]=v end
local getSpatialState,getCK
do
local abs,format=math.abs,string.format
local EDGE_T=0.7
local CENTER_T=0.3
local MOVE_EPS_SQ=2.25 -- (1.5 studs)^2
local cachedState="N"
local lastX,lastZ=math.huge,math.huge
local cachedField=nil
local fCX,fCZ,fInvHX,fInvHZ
local function refreshFieldCache(part)
cachedField=part
local pos,size=part.Position,part.Size
fCX,fCZ=pos.X,pos.Z
fInvHX=size.X>0 and 2/size.X or nil
fInvHZ=size.Z>0 and 2/size.Z or nil
lastX=math.huge
end
function getSpatialState()
local r=h()
local field=curF and curF.part
if not r or not field then cachedState,cachedField="N",nil;return"N"end
if field~=cachedField then refreshFieldCache(field)end
local p=r.Position
local px,pz=p.X,p.Z
local dx,dz=px-lastX,pz-lastZ
if dx*dx+dz*dz<MOVE_EPS_SQ then return cachedState end
lastX,lastZ=px,pz
if not(fInvHX and fInvHZ)then cachedState="M";return"M"end
local rx=abs(px-fCX)*fInvHX
local rz=abs(pz-fCZ)*fInvHZ
if rx>EDGE_T or rz>EDGE_T then cachedState="E"
elseif rx<CENTER_T and rz<CENTER_T then cachedState="C"
else cachedState="M"end
return cachedState
end
local ckCache="N"
local ckPh,ckSp,ckPM,ckXF
function getCK()
local phase=ph()
local sp=getSpatialState()
local pm=math.min(3,aB.PoM.m)
local xfB=(xfP>=22 and 3)or(xfP>=18 and 2)or(xfP>=10 and 1)or 0
if phase~=ckPh or sp~=ckSp or pm~=ckPM or xfB~=ckXF then
ckPh,ckSp,ckPM,ckXF=phase,sp,pm,xfB
ckCache=format("%s|%s|PM%d|XF%d",phase,sp,pm,xfB)
end
return ckCache
end
end

-- FIELD DETECTION
local function fldHashF()if not curF or not curF.part then return"unknown"end;return string.format("%.0f%.0f",curF.part.Position.X/50,curF.part.Position.Z/50)end
local function swFld()local nh=fldHashF();if nh==fldHash then return end;if fldHash then qTables[fldHash]=QT end;fldHash=nh;QT=qTables[fldHash]or{}end
local function fF()
local r=h();if not r then return curF end
local mp=r.Position
local z=W:FindFirstChild("FlowerZones")
if z then
local be,bd=nil,math.huge
for _,zn in ipairs(z:GetChildren())do
if zn:IsA("BasePart")then
local d=d3(mp,zn.Position)
if math.abs(mp.X-zn.Position.X)<=zn.Size.X/2+20 and math.abs(mp.Z-zn.Position.Z)<=zn.Size.Z/2+20 and d<bd then bd=d;be=zn end
end
end
if be then curF={part=be};swFld();return curF end
end
if aR then curF={part={Position=aR.Position,Size=Vector3.new(aRR*3,1,aRR*3)} };swFld();return curF end
-- v5.0.2: фолбэк по bounding box всех Flowers (из v4.0)
local fls2=W:FindFirstChild("Flowers");if fls2 then local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge;for _,f2 in ipairs(fls2:GetChildren())do if f2:IsA("BasePart")then local p2=f2.Position;if p2.X<minX then minX=p2.X end;if p2.X>maxX then maxX=p2.X end;if p2.Z<minZ then minZ=p2.Z end;if p2.Z>maxZ then maxZ=p2.Z end end end;if maxX>minX then local cx2=(minX+maxX)/2;local cz2=(minZ+maxZ)/2;curF={part={Position=Vector3.new(cx2,0,cz2),Size=Vector3.new(maxX-minX+20,1,maxZ-minZ+20)}};swFld();return curF end end
return curF
end
local fixedXFC=nil
local function gFC()
-- v5.0.2: fixedXFC — при XF>=19 центр кемпа фиксируется на FP18-10-13, как в v4.0
if aB.XF.st>=19 then
if not fixedXFC then local fls3=W:FindFirstChild("Flowers");local fp3=fls3 and fls3:FindFirstChild("FP18-10-13");if fp3 then fixedXFC=fp3.Position end end
if fixedXFC then return fixedXFC end
end
if curF and curF.part then return curF.part.Position end;local r=h();return r and r.Position or ZERO end
local function gAS()local p=ph();local b=SB[p]or 70;if hbF%30==0 then local base=b+(math.random()*2-1)*SJ;if math.abs(base-cS)>1 then cS=base end end;return cS end
local function cP(pos,sk)
if sk then return pos end
if not curF then return pos end
local c=curF.part.Position;local s=curF.part.Size
local mx=math.max(s.X/2-FM,1);local mz=math.max(s.Z/2-FM,1)
local cl=Vector3.new(math.clamp(pos.X,c.X-mx,c.X+mx),pos.Y,math.clamp(pos.Z,c.Z-mz,c.Z+mz))
if aB.XF.st>=19 then
local dx=cl.X-c.X;local dz=cl.Z-c.Z
local dSq=dx*dx+dz*dz
if dSq>0 then
local invD=1/math.sqrt(dSq)
cl=Vector3.new(c.X+dx*invD*XCR,cl.Y,c.Z+dz*invD*XCR)
end
end
return cl
end
-- PARTICLES
W.DescendantAdded:Connect(function(o)if o.Name=="AreaRing"and o:IsA("BasePart")then aR=o;aRR=(o.Size.X+o.Size.Z)/4;if aRR<5 then aRR=ARR end end end)
local function fAR()local p=W:FindFirstChild("Particles");if p then for _,o in ipairs(p:GetChildren())do if o.Name=="AreaRing"and o:IsA("BasePart")then aR=o;aRR=(o.Size.X+o.Size.Z)/4;if aRR<5 then aRR=ARR end;return end end end;aR=W:FindFirstChild("AreaRing");if aR and aR:IsA("BasePart")then aRR=(aR.Size.X+aR.Size.Z)/4;if aRR<5 then aRR=ARR end else aR=nil;aRR=ARR end end
-- v5.0.2: детект блюмов через Happenings.PoppablePlants (из v4.0)
task.spawn(function()local hap=W:FindFirstChild("Happenings");if not hap then hap=W:WaitForChild("Happenings",10)end;if not hap then return end;local ppf=hap:FindFirstChild("PoppablePlants");if not ppf then ppf=hap:WaitForChild("PoppablePlants",5)end;if not ppf then return end;for _,b in ipairs(ppf:GetChildren())do if b:IsA("BasePart")then activeBlooms[b]=true end end;ppf.ChildAdded:Connect(function(b)if b:IsA("BasePart")then activeBlooms[b]=true end end);ppf.ChildRemoved:Connect(function(b)activeBlooms[b]=nil end);print("MarmotZ: Bloom tracking active, initial blooms="..#ppf:GetChildren())end)
local Pt=W:FindFirstChild("Particles");if not Pt then Pt=workspace:WaitForChild("Particles",10)end
local function iCl(a,b,tl)tl=tl or PTOL;return math.abs(a.R*255-b.R*255)<=tl and math.abs(a.G*255-b.G*255)<=tl and math.abs(a.B*255-b.B*255)<=tl end
local function iP(p)local ok1,c1=pcall(function()return p.Color end);if ok1 and c1 and iCl(c1,PURP,20)then return true end;local ok2,bc=pcall(function()return p.BrickColor end);if ok2 and bc then local bn=bc.Name:lower();if bn:find("lavender")or bn:find("violet")or bn:find("purple")or bn:find("lilac")or bn:find("magenta")then return true end end;return false end
-- v4.9: предикт места приземления высоких кросхейров (raycast из v4.0) + видимые точки предикта
local rcp=RaycastParams.new();rcp.FilterType=Enum.RaycastFilterType.Whitelist
local function predictLandingPos(chPart)
if chPart.Position.Y<=20 then return nil end
local targets={}
local fl=W:FindFirstChild("Flowers");if fl then for _,f in ipairs(fl:GetChildren())do if f:IsA("BasePart")then table.insert(targets,f)end end end
local fz=W:FindFirstChild("FlowerZones");if fz then for _,z in ipairs(fz:GetChildren())do if z:IsA("BasePart")then table.insert(targets,z)end end end
if #targets==0 then return nil end
rcp.FilterDescendantsInstances=targets
local res=W:Raycast(chPart.Position+Vector3.new(0,2,0),Vector3.new(0,-200,0),rcp)
if res then return res.Position end
return nil
end
local function mkPredictDot(pos,isP2)
local d=Instance.new("Part");d.Shape=Enum.PartType.Ball;d.Size=Vector3.new(1.4,1.4,1.4);d.Anchored=true;d.CanCollide=false;pcall(function()d.CanQuery=false end)
d.Material=Enum.Material.Neon;d.Color=isP2 and Color3.fromRGB(190,110,255)or Color3.fromRGB(0,255,255);d.Transparency=0.1
d.Position=pos+Vector3.new(0,1.2,0);d.Name="MZ_Predict";d.Parent=W;D:AddItem(d,6);return d
end
local function aCH(o)if o.Name~="Crosshair"or not o:IsA("BasePart")then return end;for i=1,#cQ do if cQ[i].part==o then return end end;local pPos=nil;if o.Position.Y>20 then pPos=predictLandingPos(o)end;local e={part=o,sT=os.clock(),col=false,isP=iP(o),pPos=pPos};if pPos then e.dot=mkPredictDot(pPos,e.isP)end;table.insert(cQ,e)end
if Pt then
Pt.DescendantAdded:Connect(function(o)
aCH(o)
if o.Name=="WarningDisk"and o:IsA("BasePart")then
local sx=o.Size.X
if math.abs(sx-23.4)<2 then table.insert(activeCocos,{part=o,spawnTime=os.clock(),collected=false})
elseif math.abs(sx-8.0)<1 then table.insert(activeShowers,{part=o,spawnTime=os.clock(),collected=false})end
end
end)
Pt.DescendantRemoving:Connect(function(o)
for i=#cQ,1,-1 do if cQ[i].part==o then if cQ[i].dot then pcall(function()cQ[i].dot:Destroy()end)end;table.remove(cQ,i);break end end
for i=#activeCocos,1,-1 do if activeCocos[i].part==o then table.remove(activeCocos,i);break end end
if #activeCocos==0 then cocoCycle=0 end-- v5.2.6: все ворнинг-диски кокоса исчезли — сброс счётчика цикла, следующая пачка снова лутается до лимита Farm Coconuts
for i=#activeShowers,1,-1 do if activeShowers[i].part==o then table.remove(activeShowers,i);break end end
if #activeShowers==0 then showerCycle=0 end-- v5.2.6: все ворнинг-диски шовера исчезли — сброс счётчика цикла
end)
for _,o in ipairs(Pt:GetDescendants())do aCH(o)end
end
local function clnCH()for i=#cQ,1,-1 do local ch=cQ[i];if not ch.part or not ch.part.Parent or ch.col then table.remove(cQ,i)end end end
local function gCH(op,oR,purpFirst)
local lst,pl={},{}
for i=#cQ,1,-1 do
local ch=cQ[i]
local alive=false
pcall(function()if ch.part and ch.part.Parent then alive=true end end)
if not alive then table.remove(cQ,i)
elseif not ch.col then
if(op or purpFirst)and not ch.isP and ch.part.Parent then ch.isP=iP(ch.part)end
if(grnBad==nil or not grnBad(ch))and((op and ch.isP)or(oR and not ch.isP)or(not op and not oR))then -- v5.1.5: зелёные при x10 в списки лута не попадают
if purpFirst and ch.isP then table.insert(pl,ch)else table.insert(lst,ch)end
end
end
end
table.sort(lst,function(a,b)return a.sT<b.sT end)
table.sort(pl,function(a,b)return a.sT<b.sT end)
if purpFirst then
local res={}
for _,ch in ipairs(pl)do table.insert(res,ch)end
for _,ch in ipairs(lst)do table.insert(res,ch)end
return res
end
return lst
end
local function gPCH()return gCH(true,false,false)end
local function gCH_n()local r=h();if not r then return nil end;local best,bestD=nil,math.huge;for i=1,#cQ do local ch=cQ[i];if not ch.col and ch.part.Parent and not(grnBad and grnBad(ch))then local d=d3(r.Position,ch.part.Position);if d<bestD then bestD=d;best=ch end end end;return best end -- v5.1.5: ближайший кросхейр — не зелёный при x10
local function hasNearPurpleCH()local r=h();if not r then return false end;for i=1,#cQ do if not cQ[i].col and cQ[i].part.Parent and cQ[i].isP and d2Sq(r.Position,cQ[i].part.Position)<900 then return true end end;return false end
local function gCH_nc()local cc=gFC();if cc==ZERO then return nil end;local best,bestD=nil,math.huge;for i=1,#cQ do local ch=cQ[i];if not ch.col and ch.part.Parent then local d=d3(ch.part.Position,cc);if d<bestD then bestD=d;best=ch end end end;return best end
function gFCPath(rPos)
local clusters=gFCB();if #clusters==0 then return nil end
local rPosFlat=Vector3.new(rPos.X,0,rPos.Z)
table.sort(clusters,function(a,b)return d3(rPosFlat,a.center)<d3(rPosFlat,b.center)end)
local path={};local cp=rPosFlat
for i=1,#clusters do
local c=clusters[i]
if d3(cp,c.center)>FLAME_PATH_STEP then table.insert(path,c.center);cp=c.center end
end
return #path>0 and path or nil
end

-- CROSSHAIR AVOIDANCE (Tangent Path)
local cATCache={};local cATFrame=0
local function gRCT(mP,dP,tp)
-- v5.0.1: обход в X10 всегда; до X10 — только когда цель ФИОЛЕТОВЫЙ кросхейр (чтобы не наступать на обычный по пути к нему)
if(not prec.isX or prec.nR)and not tp then return{}end
if cATFrame~=hbF then cATCache={};cATFrame=hbF end
local cached=cATCache[mP];if cached and cached.tp==tp then return cached.th end
local mf=Vector3.new(mP.X,0,mP.Z)
local df=Vector3.new(dP.X,0,dP.Z)
local tD=(df-mf).Unit;local th={}
local hasPurp=hasNearPurpleCH()
local isScActive=(aB.SS.st>0)
for i=1,#cQ do
local ch=cQ[i]
if not ch.col and ch.part.Parent and not ch.isP and d2Sq(df,ch.part.Position)>(tp and 4 or 16)then -- v5.1.5: при цели-ФИОЛЕТОВОМ обычные кросхейры рядом с ним тоже угрозы (бот шёл на пролом через пару CH и лутал их)
local cf=Vector3.new(ch.part.Position.X,0,ch.part.Position.Z)
local dSq=d2Sq(mf,cf)
local sz=math.max(ch.part.Size.X,ch.part.Size.Z,4)
local effR=sz*0.5+8 -- v5.0.4: держим ~8 студов от края кросхейра (было 6 — бот наступал на них)
if isScActive then effR=sz*0.5+6 end -- v5.1.5: в скорче было +3 — главная причина GREEN CH -80; теперь +6
if isGrnCH and isGrnCH(ch)then effR=effR+4 end -- v5.1.5: зелёным — доп. запас +4
if dSq<((effR+14)*(effR+14))and dSq>0.04 then -- v5.1.6: детект угрозы за +14 студов — обход начинается заранее и идёт широкой дугой
local toCh=cf-mf
if toCh.Unit:Dot(tD)>-0.25 then
local cross=math.abs(toCh.X*tD.Z-toCh.Z*tD.X)
if cross<effR then table.insert(th,{ch=ch,pos=cf,dist=math.sqrt(dSq),cross=cross,sz=sz})end
end
end
end
end
cATCache[mP]={tp=tp,th=th};return th
end
-- v4.8: новый обход — оценивает обе стороны и учитывает ВСЕ кросхейры рядом с объездной точкой, а не только ближайший
local function cAT(mP,dP,targetIsPurple)local th=gRCT(mP,dP,targetIsPurple);if #th==0 then return nil end
local mf=Vector3.new(mP.X,0,mP.Z);local df=Vector3.new(dP.X,0,dP.Z);local tD=(df-mf).Unit
table.sort(th,function(a,b)return a.dist<b.dist end);local t=th[1];local uCh=(t.pos-mf).Unit
local pD=math.max(math.min(t.sz*0.5+(targetIsPurple and 22 or 14),(df-mf).Magnitude*0.95),targetIsPurple and 12 or 6)-- v5.2.5: к ФИОЛЕТОВОМУ боковой шаг шире (22 студа, мин 12) — заходим на фиолетовый в плотном кластере сбоку, а не толкаемся в соседние. v5.1.6: базовый ~14 студов
local tA=Vector3.new(-uCh.Z,0,uCh.X);local tB=Vector3.new(uCh.Z,0,-uCh.X)
local function sideScore(tang)
local wp=Vector3.new(t.pos.X+tang.X*pD,0,t.pos.Z+tang.Z*pD)
local sc=tang:Dot(tD)*2-(wp-df).Magnitude*0.05
for i=1,#cQ do local ch=cQ[i]
if not ch.col and ch.part.Parent and not ch.isP and(not t.ch or ch.part~=t.ch.part)then
local cf=Vector3.new(ch.part.Position.X,0,ch.part.Position.Z)
local sz=math.max(ch.part.Size.X,ch.part.Size.Z,4)
local dd=d3(wp,cf)
if dd<sz*0.5+8 then sc=sc-(sz*0.5+8-dd)end
end
end
return sc
end
-- v5.2.5: гистерезис стороны обхода — сторона не флипается каждый кадр (причина дрожи в кластере из 6 кросхейров: sideScore почти равны и знак прыгал -> бот дрожал на месте)
local sA,sB=sideScore(tA),sideScore(tB)
local tang
if cATLastSide==1 then tang=(sA>=sB-8)and tA or tB elseif cATLastSide==2 then tang=(sB>=sA-8)and tB or tA else tang=(sA>=sB)and tA or tB end
cATLastSide=(tang==tA)and 1 or 2
st.chA=st.chA+1
-- v5.0.8: объездная точка отодвигается, пока не очистит ВСЕ соседние кросхейры — раньше могла лечь прямо на соседний, и бот наступал на него по пути к фиолетовому
local wpX,wpZ=t.pos.X+tang.X*pD,t.pos.Z+tang.Z*pD
for _=1,8 do-- v5.2.5: было 4 итерации — в углу с 6 кросхейрами точка не очищалась; 8 x (+4) = до +32 студов
local bad=false
for i=1,#cQ do local ch2=cQ[i]
if not ch2.col and ch2.part.Parent and not ch2.isP then
local sz2=math.max(ch2.part.Size.X,ch2.part.Size.Z,4)
local dxw,dzw=wpX-ch2.part.Position.X,wpZ-ch2.part.Position.Z
if dxw*dxw+dzw*dzw<(sz2*0.5+8)*(sz2*0.5+8)then bad=true;break end -- v5.1.5: объездная точка держит +8 от соседних кросхейров (было +6)
end
end
if not bad then break end
pD=pD+4;wpX,wpZ=t.pos.X+tang.X*pD,t.pos.Z+tang.Z*pD
end
return cP(Vector3.new(wpX,mP.Y,wpZ))
end

-- GREEN CH
local GREEN_RGB={R=17/255,G=134/255,B=19/255};local GREEN_TOL=8
local function isGreenCH(ch)if not ch.part.Parent then return false end;local ok,c=pcall(function()return ch.part.Color end);if ok and c then return math.abs(c.R-GREEN_RGB.R)*255<=GREEN_TOL and math.abs(c.G-GREEN_RGB.G)*255<=GREEN_TOL and math.abs(c.B-GREEN_RGB.B)*255<=GREEN_TOL end;return false end
function isGrnCH(ch)return isGreenCH(ch)end -- v5.1.5: глобальный доступ для gRCT/gCH (объявлены выше по файлу, вызов в рантайме)
function grnBad(ch)return prec and prec.isX and not prec.nR and not ch.isP and isGreenCH(ch)end -- v5.1.5: зелёный кросхейр НЕЛЬЗЯ лутать при активном x10-прецизионе (-80)
function moHold(t)if not(t and t.mo and t.dp)then return false end;local nH=os.clock();if(t.l-(nH-t.s))<6 then return false end;if aB.SS.st>0 and scorchStartT>0 and(nH-scorchStartT)>=15 then return false end;return true end -- v5.1.6: дюпед морф «на удержании»: лутать можно ТОЛЬКО при остатке <6с или после 15с от начала скорча — все универсальные сборщики токенов его пропускают
local function sBC(obj)if not obj then return""end;local ok,bc=pcall(function()return obj.BrickColor end);if ok and bc then local ok2,nm=pcall(function()return bc.Name end);if ok2 and nm then return nm end end;return""end
-- BLOOM + FLAMES
local function hitBloom()
local r=h();if not r then return end
local n=os.clock();if n-lastBH<SCYTHE_CD then return end
local bb=nil
for bloom in pairs(activeBlooms)do
if bloom.Parent and d2Sq(r.Position,bloom.Position)<=196 then bb=bloom;break end
end
if not bb then return end;lastBH=n
local bg=r:FindFirstChild("BG_B")or Instance.new("BodyGyro")
bg.Name="BG_B";bg.MaxTorque=Vector3.new(0,40000,0)
bg.P=10000;bg.D=500;bg.Parent=r
local dir=bb.Position-r.Position;dir=Vector3.new(dir.X,0,dir.Z)
if dir.Magnitude>0.1 then bg.CFrame=cfLookAt(r.Position,r.Position+dir)end
local ev=RS:FindFirstChild("Events")
local tce=ev and ev:FindFirstChild("ToolCollect")
if tce then tcFires=tcFires+1;pcall(function()tce:FireServer()end)end
D:AddItem(bg,0.15)
end
function gFCB()local clusters={};local visited={};for fl,data in pairs(scytheParts)do if fl and fl.Parent and not visited[fl]then local nm=fl.Name or"";local bn=sBC(fl);local isD=(nm:find("Dark")or bn=="Really black");if not isD then local cluster={fl};visited[fl]=true;local changed=true;while changed do changed=false;for fl2 in pairs(scytheParts)do if fl2 and fl2.Parent and not visited[fl2]then local nm2=fl2.Name or"";local bn2=sBC(fl2);local isD2=(nm2:find("Dark")or bn2=="Really black");if not isD2 then for _,cf in ipairs(cluster)do if d3(cf.Position,fl2.Position)<=FLAME_CLUSTER_RADIUS then table.insert(cluster,fl2);visited[fl2]=true;changed=true;break end end end end end end;if #cluster>=FLAME_CLUSTER_MIN then local cx,cz=0,0;for _,cf in ipairs(cluster)do cx=cx+cf.Position.X;cz=cz+cf.Position.Z end;table.insert(clusters,{center=Vector3.new(cx/#cluster,0,cz/#cluster),size=#cluster,flames=cluster})end end end end;table.sort(clusters,function(a,b)return a.size>b.size end);return clusters end
local function hitFlames()local r=h();if not r then return end;local n=os.clock();if n-lastSHit<SCYTHE_CD then return end;local allFlames=(scorchActive and scorchStartT>0 and(n-scorchStartT)>=35)
for fl,data in pairs(scytheParts)do if fl and fl.Parent then local nm=fl.Name or"";local bn=sBC(fl);local isD=(nm:find("Dark")or bn=="Really black");local cd=flameCD[fl];local canHit=allFlames or(not isD)
if canHit and(not cd or n>=cd)and d2Sq(r.Position,fl.Position)<=784 and data and(n-data.sT)>=6.0 then lastSHit=n;flameCD[fl]=n+(allFlames and 2.0 or 5.0);flHit=flHit+1
local bg=r:FindFirstChild("BG_S")or Instance.new("BodyGyro");bg.Name="BG_S";bg.MaxTorque=Vector3.new(0,40000,0);bg.P=10000;bg.D=500;bg.Parent=r
local dir=fl.Position-r.Position;dir=Vector3.new(dir.X,0,dir.Z);if dir.Magnitude>0.1 then bg.CFrame=cfLookAt(r.Position,r.Position+dir)end
local ev=RS:FindFirstChild("Events");local tce=ev and ev:FindFirstChild("ToolCollect");if tce then tcFires=tcFires+1;pcall(function()tce:FireServer()end)else pcall(function()V:SendMouseButtonEvent(0,0,0,true,game,1);task.wait(0.05);V:SendMouseButtonEvent(0,0,0,false,game,1)end)end;D:AddItem(bg,0.15);if not allFlames then break end end -- FIX v4.7.2: этот end закрывает if canHit (причина ошибки :1085)
else scytheParts[fl]=nil;flameCD[fl]=nil end end end

-- GOTO with Momentum Strafing
local function goTo(tP,rad,to,sk)
rad=math.min(rad or 1.5,2.5);to=to or MT
if to>12 then to=12 end;if tP==ZERO then return false end
local r=h();local hm_=hm();if not r or not hm_ then return false end
tP=cP(tP,sk);local oT=Vector3.new(tP.X,r.Position.Y,tP.Z)
local cM=oT;local committedSide=nil
local av=cAT(r.Position,oT,sk)
if av then
cM=Vector3.new(av.X,r.Position.Y,av.Z)
committedSide=(av.X-r.Position.X>0 and"right"or"left")
end
local function moveFast()
-- v4.9: строже стрейф — меньше перелёт, вблизи идём точно в цель
local dv=cM-r.Position
local dist=dv.Magnitude
if dist<6 then hm_:MoveTo(cM)return end
local dir=dv.Unit
local vel=r.AssemblyLinearVelocity
local flatVel=Vector3.new(vel.X,0,vel.Z)
if flatVel.Magnitude>10 and dir:Dot(flatVel.Unit)>0.7 then
local strafeDir=(dir+flatVel.Unit*0.25).Unit
hm_:MoveTo(cM+Vector3.new(strafeDir.X*1.5,0,strafeDir.Z*1.5))
else
hm_:MoveTo(cM+Vector3.new(dir.X*1,0,dir.Z*1))
end
end
moveFast()
local t0=os.clock();local lA=os.clock();local hb0=hbF
while os.clock()-t0<to do
if hbF-hb0>to*60 then return false end
task.wait(0.03)
if not ENABLED or INT then return false end
r=h();if not r then return false end
pcall(hitBloom);pcall(hitFlames)
if d2Sq(r.Position,oT)<=(rad*rad)then for p,_ in pairs(aT)do if p and p.Position and d2Sq(r.Position,p.Position)<=4 then tokenBL[p]=os.clock()+1.2 end end;return true end
if os.clock()-lA>=0.05 then lA=os.clock();local na=cAT(r.Position,oT,sk);cM=na and Vector3.new(na.X,r.Position.Y,na.Z)or oT;moveFast()end
end
return false
end

-- STAND ON PURPLE
local function standOnPurple(ch,timeout)local r=h();local hm_=hm();if not r or not hm_ or not ch.part.Parent then return false end;tL="P Stand";INT=false
goTo(ch.part.Position,3,math.min(timeout,8),true)-- v4.8: подход к пурпурной метке через goTo с обходом кросхейров, а не напролом
r=h();if not r or not ch.part.Parent then return false end;local t0=os.clock();local bestD=math.huge;local stuckT=os.clock()
while os.clock()-t0<timeout do task.wait(0.03);r=h();if not r or not ch.part.Parent then break end;if INT or not ENABLED then return false end;pcall(hitBloom);pcall(hitFlames)
local dNow=d2Sq(r.Position,ch.part.Position)
if dNow<=9 then hm_:MoveTo(ch.part.Position)
else
if dNow<bestD-1 then bestD=dNow;stuckT=os.clock()end
if os.clock()-stuckT>1.0 then local toP=ch.part.Position-r.Position;toP=Vector3.new(toP.X,0,toP.Z);if toP.Magnitude>0.1 then local u=toP.Unit;hm_:MoveTo(cP(r.Position+Vector3.new(-u.Z,0,u.X)*12+u*4))end;stuckT=os.clock();bestD=math.huge else local dir=(ch.part.Position-r.Position).Unit;hm_:MoveTo(ch.part.Position+Vector3.new(dir.X*1.5,0,dir.Z*1.5))end
end
end
if not ch.part.Parent then ch.col=true;st.pr=st.pr+1;lP=ch.part;st.chP=st.chP+1;return true end;return false end

-- TOKEN REG
-- v4.9: таймеры над токенами в стиле v4.0 — префикс, фон, цвет по типу токена, отдельный цвет для дюпед
local function cT(part,id,tl,dp,df)if activeTG[part]then return end;local gui=Instance.new("BillboardGui");gui.Adornee=part;gui.Size=dp and UDim2.new(0,100,0,30)or UDim2.new(0,80,0,24);gui.StudsOffset=Vector3.new(0,2,0);gui.AlwaysOnTop=true;gui.Parent=part;local lb=Instance.new("TextLabel",gui);lb.Size=UDim2.new(1,0,1,0);lb.BackgroundTransparency=0.2;lb.BackgroundColor3=df.bg or Color3.new(0,0,0);lb.TextColor3=dp and(df.dc or df.nc or Color3.new(1,1,1))or(df.nc or Color3.new(1,1,1));lb.TextScaled=true;lb.Font=Enum.Font.SourceSansBold;lb.TextStrokeTransparency=0;lb.TextStrokeColor3=Color3.new(0,0,0);lb.Text=(df.pre or"")..string.format("%.1f",tl);activeTG[part]={gui=gui,label=lb,startTime=os.clock(),totalLifetime=tl,prefix=df.pre or""}end
-- v5.1: таймеры ТОЛЬКО над токенами из TKS (полный сет v4.0, как ты и просил), GEN_DF выпилен — неизвестные токены не трекаем; в aT добавлен bt (батл-токен)
local function rT(o)if o.Name~="C"or not o:IsA("BasePart")or aT[o]or tokenBL[o]then return end;local fr=o:FindFirstChild("FrontDecal");if not fr or not fr:IsA("Decal")then return end;local id=ti(fr.Texture);if not id or AV[id]then return end;local df=TKS[id];if not df then return end;local r=h();local dp=false;if r then dp=(o.Position.Y-r.Position.Y)>5 end;local lf=df.base*AM;if dp then lf=lf*(2+0.05*(DGL-1));dupCnt=dupCnt+1 end;aT[o]={id=id,n=df.n,p=df.p,mo=df.mo or false,bt=df.bt or false,s=os.clock(),l=lf,dp=dp,col=false};tokenVerify[o]=(os.clock()+0.5);pcall(cT,o,id,lf,dp,df)end
-- v5.0.1: ретраи FrontDecal остались, но рескан теперь ТОЛЬКО по папкам, где реально спавнятся токены (фикс FPS-спайков от W:GetDescendants каждые 2с)
local tokParents={}
local function remTokParent(par)if par then tokParents[par]=true end end
W.DescendantAdded:Connect(function(o)if o.Name=="C"then task.spawn(function()pcall(rT,o);if not aT[o]then task.wait(0.2);pcall(rT,o);if not aT[o]then task.wait(0.5);pcall(rT,o)end end;if aT[o]then remTokParent(o.Parent)end end)end end)
do for _,o in ipairs(W:GetDescendants())do pcall(rT,o);if aT[o]then remTokParent(o.Parent)end end end
task.spawn(function()while true do task.wait(2)pcall(function()for par in pairs(tokParents)do if par.Parent then for _,o in ipairs(par:GetChildren())do if o.Name=="C"and not aT[o]then pcall(rT,o)end end else tokParents[par]=nil end end end)end end)
-- v5.0.4: safety-net полный рескан раз в 6с — восстанавливает 100% покрытие таймеров токенов (как в v4.0), даже если DescendantAdded проиграл из-за медленной загрузки FrontDecal
task.spawn(function()while true do task.wait(6)pcall(function()for _,o in ipairs(W:GetDescendants())do if o.Name=="C"and not aT[o]then pcall(rT,o);if aT[o]then remTokParent(o.Parent)end end end end)end end)
game.DescendantRemoving:Connect(function(o)if aT[o]then if aT[o].col then st.tk=st.tk+1 end;if aT[o].dp then dupCnt=math.max(0,dupCnt-1)end;aT[o]=nil end;if scytheParts[o]then scytheParts[o]=nil;flameCD[o]=nil end;tokenVerify[o]=nil;tokenBL[o]=nil;if activeTG[o]then pcall(function()activeTG[o].gui:Destroy()end);activeTG[o]=nil end end)
local function verifyTokens()local n=os.clock();local r=h();if not r then return end;for p,v in pairs(tokenVerify)do if n>v then if p and p.Parent and aT[p]and aT[p].col then local d=d3(r.Position,p.Position);if d<15 then aT[p].col=false;tokenVerify[p]=n+3 end end end end end
-- v4.9: обновление таймеров каждый кадр, как в v4.0 (красный цвет при <3с)
R.Heartbeat:Connect(function()local now=os.clock();for p,d in pairs(activeTG)do if p and p.Parent and d and d.label then local r2=d.totalLifetime-(now-d.startTime);if r2>0 then d.label.Text=d.prefix..string.format("%.1f",r2);if r2<3.0 then d.label.TextColor3=Color3.new(1,0.3,0.3)end else d.label.Text=d.prefix.."0.0"end else pcall(function()if d and d.gui then d.gui:Destroy()end end);activeTG[p]=nil end end end)
-- BUFF POLLING
local rps=nil;local PAE=nil
do local e=RS:FindFirstChild("Events");if e then rps=e:FindFirstChild("RetrievePlayerStats");PAE=e:FindFirstChild("PlayerAbilityEvent")end end
if PAE then PAE.OnClientEvent:Connect(function(data)if type(data)~="table"then return end;for tag,info in pairs(data)do if type(tag)=="string"and type(info)=="table"and info.Action=="Update"and info.Values then local sts=info.Values[1];if sts then local lower=tag:lower();if lower:find("flame")then xfP=sts elseif lower:find("scorching")then scP=sts end end end end end)end
local function fb(t,d)if type(t)~="table"then return end;local bid=rawget(t,"BuffID");if bid then d[bid]=t end;local src=rawget(t,"Src");if src then d[src]=t end;for _,val in pairs(t)do if type(val)=="table"then fb(val,d)end end end
local function pAB()
if not rps then return end
pabCalls=pabCalls+1
local ok,res=pcall(function()return rps:InvokeServer()end)
if not ok or type(res)~="table"then return end
local fd={};fb(res,fd)
local prevSS=aB.SS.st
local ss=fd["Scorching Star Aura"]
if ss and rawget(ss,"Removed")~=true then
aB.SS.st=tonumber(rawget(ss,"Combo")or 0)or 0
else aB.SS.st=0;if scP>0 then scP=0 end
end
local xf=fd["X-Flame Aura"]
if xf and rawget(xf,"Removed")~=true then
aB.XF.st=tonumber(rawget(xf,"Combo")or 0)or 0
else aB.XF.st=0;if xfP>0 then xfP=0 end
end
aB.PM.a=(fd[2575093099]and rawget(fd[2575093099],"Removed")~=true)
local pm=fd[PMBI]
if pm and rawget(pm,"Removed")~=true then
aB.PoM.a=true;aB.PoM.m=tonumber(rawget(pm,"Combo")or 0)or 1
if aR then aB.PoM.pos=aR.Position end
else aB.PoM.a=false;aB.PoM.m=0 end
local plm=fd[PLMBI]
if plm and rawget(plm,"Removed")~=true then
pollMS=tonumber(rawget(plm,"Combo")or rawget(plm,"Value")or 0)or 0
aB.PollM.combo=pollMS;aB.PollM.active=(aB.PollM.combo>=3)
else pollMS=0;aB.PollM.active=false;aB.PollM.combo=0 end
-- v5.0: остатки нектаров по Src (Start и Dur — unix-время): remaining = Start+Dur-os.time()
for srcName,varn in pairs(NECTAR_SRC)do
local nb=fd[srcName]
if nb and rawget(nb,"Removed")~=true then
local ns=tonumber(rawget(nb,"Start")or 0)or 0
local nd=tonumber(rawget(nb,"Dur")or 0)or 0
nectarRem[varn]=math.max(0,(ns+nd)-os.time())
else nectarRem[varn]=0 end
end
local b=fd[PBI]or fd["Precision"]
if b and rawget(b,"Removed")~=true then
local rv=rawget(b,"Value")
prec.val=tonumber(rv or 0)or 0
local ns=0
if prec.val>0 then ns=math.min(PMX,math.round(prec.val/PPK))end
prec.isX=(ns>=PMX)
local bd=tonumber(rawget(b,"Dur")or 60)or 60
prec.sD=bd
local bStart=tonumber(rawget(b,"Start"))
if ns~=prec.st or(bStart and bStart~=prec.sS)then
prec.st=ns
prec.ls=os.clock()
if bStart then prec.sS=bStart end
if prec.isX then prec.nR=false;rCC=0 end
end
else
prec.st=0;prec.val=0;prec.isX=false
prec.ls=0;prec.tL=0;prec.nR=false
end
if prec.ls>0 then
prec.tL=math.max(0,prec.sD-(os.clock()-prec.ls))
prec.nR=prec.isX and(prec.tL<=PRAT)
if prec.nR and rCC==0 then rST=os.clock();rCC=0 end
end
local curH=getHoney()
if aB.SS.st>0 and prevSS==0 then
scorchStartH=curH;scorchStartT=os.clock()
scorchActive=true;scorchRecording=true;scorchActions={}
scorchDupedMorphDone=false;scorchPurpleCount=0;scorchPurpleTime=0
scorchAllCHMode=false;scorchPurpleTotal=0
scorchTPIndex=0;scorchTPTable={};scorchTPCycle=false;flameCampStart=0;scorchAllCHT0=0;flCampAcc=0;flCampCd=0
elseif aB.SS.st==0 and prevSS>0 then
scorchActive=false
if scorchRecording and scorchStartT>0 then
local gained=curH-scorchStartH
local dur=(os.clock()-scorchStartT)/60
if gained>0 then
table.insert(scorchSessions,{honeyGained=gained,honeyGainedFmt=fmtH(gained),durationMin=math.floor(dur*10)/10,time=os.clock(),ssCombo=prevSS,ctx=getCK(),actions=scorchActions,purpleTotal=scorchPurpleTotal})
if gained>bestSH then bestSH=gained end
end
pcall(sSS);pcall(sPat)-- v5.0.6: автосохранение скорча (теперь С действиями) и паттерн-лога после каждой сессии
scorchRecording=false;scorchActions={}
end
end
end

-- SCANNERS
local function gPC(p)for nxt,co in pairs(PC)do if(co.R-p.Color.R)^2+(co.G-p.Color.G)^2+(co.B-p.Color.B)^2<0.002 then return nxt end end;return nil end
local function sPt()
fP={};if not ENABLED or not curF then return end
local pt=W:FindFirstChild("Particles");if not pt then return end
local r=h();if not r then return end
-- v5.1.2: запоминаем время первого появления каждого петала (ptSeen) — они летают ~2-3с после спавна
local seen2={}
for _,o in ipairs(pt:GetChildren())do
if o.Name=="PetalPart"and o:IsA("BasePart")then
seen2[o]=ptSeen[o]or os.clock()
local cn=gPC(o)
if cn and PP[cn]then
table.insert(fP,{part=o,cn=cn,pr=PP[cn],dist=d3d(r.Position,o.Position)})
end
end
end
ptSeen=seen2
-- v5.1.3: мягкий приоритет вместо жёсткого фильтра: севшие петалы (age>=2.5) идут первыми, летящие — в конце списка, но лутабельны в любой момент
table.sort(fP,function(a,b)local n5=os.clock();local la=(n5-(ptSeen[a.part]or 0))>=2.5;local lb=(n5-(ptSeen[b.part]or 0))>=2.5;if la~=lb then return la end;if a.pr~=b.pr then return a.pr<b.pr end;return a.dist<b.dist end)
end
local function sSm()local n=os.clock();smT=nil;smTR=math.huge;local r=h();if not r then return end;if dupCnt<6 then return end
local bestInRing,bestInRem=nil,math.huge;local bestOut,bestOutRem=nil,math.huge
for p,t in pairs(aT)do if not t.col and p.Parent and t.id==SMI and not tokenBL[p]then local rem=t.l-(n-t.s);if rem>0 then local inRing=(aR and aR.Parent and d2Sq(p.Position,aR.Position)<=aRR*aRR*1.2);if inRing and rem<bestInRem then bestInRem=rem;bestInRing=p elseif not inRing and rem<bestOutRem then bestOutRem=rem;bestOut=p end end end end
if bestInRing then smT=bestInRing;smTR=bestInRem elseif bestOut then smT=bestOut;smTR=bestOutRem end;if smT and not isCS and not chBusy then INT=true end end -- v5.1.6: смайл не прерывает активную серию кросхейров
local function scS()local pf=W:FindFirstChild("PlayerFlames");if not pf then return end;for fl,_ in pairs(scytheParts)do if not fl.Parent then scytheParts[fl]=nil;flameCD[fl]=nil end end;for _,f in ipairs(pf:GetChildren())do local nm=f.Name or"";if nm:sub(1,3)=="Flm"or nm:find("Scythe")or nm:find("Flame")then if not scytheParts[f]then scytheParts[f]={sT=os.clock(),hit=false}end end end end
local PETAL_CLUSTER_R=12;local PETAL_CLUSTER_MIN=3-- v5.0.8: кластер петалов уже от 3 шт (больше акцент на петалы)
local function gPetCluster()if #fP<PETAL_CLUSTER_MIN then return nil end;local clusters={};local used={}
for i=1,#fP do if not used[i]then local cl={fP[i]};used[i]=true;local changed=true;while changed do changed=false;for j=1,#fP do if not used[j]then for _,m in ipairs(cl)do if d3(m.part.Position,fP[j].part.Position)<=PETAL_CLUSTER_R then table.insert(cl,fP[j]);used[j]=true;changed=true;break end end end end end;if #cl>=PETAL_CLUSTER_MIN then local cx,cz=0,0;for _,m in ipairs(cl)do cx=cx+m.part.Position.X;cz=cz+m.part.Position.Z end;table.insert(clusters,{center=Vector3.new(cx/#cl,0,cz/#cl),size=#cl,members=cl})end end end;table.sort(clusters,function(a,b)return a.size>b.size end);return #clusters>0 and clusters or nil end
-- v5.1: батл-токены (bt=true). При 22+ XF НЕ лутаем батл-токены в углу (дальше XCR*2 от центра). Калькулятор линка: если XF-пассивка + ВСЕ живые батл-токены на поле >= 24, угловой линк можно лутать — XF в углу уже не заспавнится (пример: 20 XF + линк + 3 БТ = 24 -> лутаем)
function cntBT()local n=os.clock();local c=0;for p,t in pairs(aT)do if not t.col and p.Parent and t.bt and(t.l-(n-t.s))>0.3 then c=c+1 end end;return c end
function btBlocked(p,t)if not t or not t.bt then return false end;if xfP<22 then return false end;local cc=gFC();if cc==ZERO then return false end;if d3(p.Position,cc)<=XCR*2 then return false end;if xfP+cntBT()>=24 then return false end;return true end
local function hTL()local n=os.clock();for p,t in pairs(aT)do if not t.col and p.Parent and t.p>=90 and not tokenBL[p]and(t.l-(n-t.s))>0.3 and not btBlocked(p,t)then return true end end;return false end
local function eS()local r=h();if not r then return"dead"end;return string.format("PH:%s|CH:%d|PR:%d|XF:%d|SS:%d",ph(),#cQ,st.pr,xfP,scP)end
local function gSC()local cx,cz,ct=0,0,0;local dw=5;for fl,_ in pairs(scytheParts)do if fl and fl.Parent then local nm=fl.Name or"";local bn=sBC(fl);local isD=(nm:find("Dark")or bn=="Really black");local w=isD and dw or 1;cx=cx+fl.Position.X*w;cz=cz+fl.Position.Z*w;ct=ct+w end end;if ct>0 then return Vector3.new(cx/ct,0,cz/ct),true,0 end;if curF and curF.part then return curF.part.Position,false,0 end;local r2=h();if r2 then return r2.Position,false,0 end;return ZERO,false,0 end
-- ACTION BUILDER
local function gAWB()local ba={};local p_=ph();local n=os.clock();local isSc=(aB.SS.st>0);local isSS=(isSc and prec.isX and aB.PoM.m>=3 and pollMS>=3)
if not isSc and n>=prPauseNext then prPauseUntil=n+30;prPauseNext=n+900;pcall(klog,"PREC PAUSE: 30s без прецов (цикл 15 мин)")end-- v5.2.8: раз в 15 минут ВНЕ скорча стартует 30с-пауза лута прецов (если на 15-й минуте идёт скорч — пауза ждёт его конца)
if scorchAllCHMode and(os.clock()-scorchAllCHT0)>45 then scorchAllCHMode=false;scorchPurpleCount=0 end -- v5.0.8: окно AllCH ровно 45с, потом снова копим 3 фиолетовых
local hdm=false;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.mo then hdm=true;break end end;local isSO=(not isSc)and prec.isX and hdm
ndMorph=nil;for p,t in pairs(aT)do if not t.col and p.Parent and t.mo and not t.dp then ndMorph=p;break end end
local cs=L:FindFirstChild("CoreStats");if cs then local cap=cs:FindFirstChild("Capacity");local pol=cs:FindFirstChild("Pollen");if cap and pol and cap.Value>0 and(pol.Value/cap.Value)>=0.9 then local pp=gPCH();if #pp>0 then return{"go_backpack_dump_purple"}end;local all=gCH(false,false,false);if #all>0 then return{"go_backpack_dump"}end end end
local r=h();if not r then return{"patrol_ring"}end
-- SHOWER (with limit)
if cfg.shower_on and(cfg.shower_lim==0 or showerCycle<cfg.shower_lim)and not(prec.isX and prec.tL>0 and prec.tL<16)then-- v5.0.8: шовер НЕ лутаем, если x10-прецизиону осталось <16с
for i=1,#activeShowers do local sh=activeShowers[i];if not sh.collected and sh.part.Parent and(n-sh.spawnTime)<1.2 then if d3(r.Position,sh.part.Position)<80 then return{"go_shower"}end end end
for i=1,#activeShowers do local sh=activeShowers[i];if not sh.collected and sh.part.Parent and(n-sh.spawnTime)<0.8 and d3(r.Position,sh.part.Position)<60 then if not(prec.isX and prec.tL>0 and prec.tL<15)then return{"go_shower"}end end end end
-- v5.1.5: умирающий дюпед морф (<6с) — ФОРСИРОВАННО поверх всего: раньше ветка стояла ниже кемпа/петалов/флеймов и её перебивали — морф протухал
for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.mo then local remM=t.l-(n-t.s);if remM<6 and remM>0 then return{"go_duped_morph"}end end end
-- v5.1.6: смайл при 6+ дюпед — сразу после форс-морфа: раньше его перебивали ветки скорча/19+ XF/ndMorph и смайл в ареаринге протухал
if smT and smT.Parent and dupCnt>=6 and not isSS and smTR<10 and(smTR<4 or os.clock()>=(smCd or 0))then if aB.PoM.a and aR and aR.Parent then return{"go_smile_area"}end;return{"go_smile"}end-- v5.2.5: топ-приоритет смайла ТОЛЬКО для срочного (<10с) и с кулдауном 12с (жалоба: при 6+ дюпед смайл собирался слишком часто и перебивал скорч/кросхейры); совсем срочный <4с игнорит кулдаун
-- v5.0.6: 24+ пассивок скорча: <10 X-Flame — лутаем ВСЕ кросхейры (копим X-Flame); 10+ — ВСТАЁМ на фиолетовые (счёт в scorchPurpleCount); после 3 фиолетовых — все кросхейры до конца скорча
if scP>=24 and xfP<10 and not scorchAllCHMode then local allW=gCH(false,false,true);if #allW>0 then return{"go_crosshair_all"}end end
if scP>=24 and xfP>=10 then
if scorchPurpleCount>=3 and not scorchAllCHMode then scorchAllCHMode=true;scorchAllCHT0=os.clock()end
if scorchAllCHMode then local allW2=gCH(false,false,true);if #allW2>0 then return{"go_crosshair_all"}end
else local ppW=gCH(true,false,false);if #ppW>0 then return{"go_purple_scorch"}end end
end
-- XF Camping
-- v5.0.7: кемп больше не глушит кросхейры: если есть кросхейр в радиусе XCR*2 от центра — сначала ВСТАЁМ на ближайший к центру (go_center_ch), потом назад в кемп
if xfE then
local ccX=gFC()
if ccX~=ZERO then local bCX=gCH_nc();if bCX and d3(bCX.part.Position,ccX)<=XCR*2 then return{"go_center_ch"}end end
if isSc then if n-xfStartTime<=4.0 then return{"go_xflame_center_camp"}end;if scorchAllCHMode then local all=gCH(false,false,true);if #all>0 then return{"go_crosshair_all"}end end;return{"go_xflame_center_camp"}else return{"go_xflame_center_camp"}end end-- v5.0.8: массовый лут в кемпе тоже только в окне AllCH
-- v5.0.1: предикт прецайсов больше НЕ перебивает лут кросхейров/смайла — перенесён ниже по приоритету (прецайсов много — он срабатывал постоянно и бот игнорировал всё остальное)
-- XF center
if xfP>=22 and scP>=20 and not isSS then local cc=gFC();if cc~=ZERO and d3(r.Position,cc)>XCR*2 then return{"go_xflame_center"}end end
-- Super Scorch
if isSS then
if scorchActive and scorchStartT>0 and(n-scorchStartT)>=35 and scorchAllCHMode then local all=gCH(false,false,true);if #all>0 then return{"go_crosshair_all"}end;local path=gFCPath(r.Position);if path then return{"go_flame_path"}end;return{"patrol_scorch_flames"}end-- v5.0.8: массовый лут после 35с тоже только в окне AllCH
for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==4519549299 then return{"go_duped_inferno_scorch"}end end
if scorchActive and scorchStartT>0 and(n-scorchStartT)>=15 and not scorchDupedMorphDone then if smT and smT.Parent then return{"go_smile"}end;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.mo then return{"go_duped_morph_scorch"}end end end
if scorchAllCHMode then for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==TPI then return{"go_duped_tp_scorch"}end end;local all=gCH(false,false,true);if #all>0 then return{"go_crosshair_all"}end;local path=gFCPath(r.Position);if path then return{"go_flame_path"}end;return{"patrol_scorch_flames"}end
if not scorchAllCHMode then
if scorchPurpleCount>=3 then scorchAllCHMode=true;scorchAllCHT0=os.clock();scorchPurpleTime=os.clock();local all=gCH(false,false,true);if #all>0 then return{"go_crosshair_all"}end;local path=gFCPath(r.Position);if path then return{"go_flame_path"}end;return{"patrol_scorch_flames"}end
-- v5.0.6: убран фолбэк "AllCH через 1с после ПЕРВОГО фиолетового" — из-за него режим всех кросхейров включался после 1 фиолетового, а не после 3; теперь СТРОГО scorchPurpleCount>=3
local pp=gCH(true,false,false);if #pp>0 then return{"go_purple_scorch"}end end
-- v5.0.8: вне окна AllCH массовый лут запрещён: акцент на огни (кемп кластера ~12с/пауза 10с), одиночный ближайший кросхейр — можно
local nc2=gCH_n();if nc2 then return{"go_crosshair"}end -- v5.1.5: кросхейр ПЕРЕД кемпом кластера
if os.clock()>flCampCd then local clF=gFCB();if #clF>0 and clF[1].size>=4 then return{"go_flame_cluster_center"}end end
local path2=gFCPath(r.Position);if path2 then return{"go_flame_path"}end;return{"patrol_scorch_flames"}end
if isSc and scorchStartT>0 and(n-scorchStartT)>=15 and not scorchDupedMorphDone then if smT and smT.Parent then return{"go_smile"}end;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.mo then return{"go_duped_morph_scorch"}end end end
-- Scorch petal+flame focus
if isSc and not isSS then local ptCl=gPetCluster();if ptCl and #ptCl>0 then return{"go_petal_cluster"}end;if #fP>=2 then return{"go_petal"}end-- v5.0.8: в скорче петалы уже от 2 шт 
-- v5.0.8: акцент на огни ЖИВОЙ: старое условие n-flameCampStart<=15 при flameCampStart=0 было всегда ложным (мёртвая ветка). Теперь каденс: ~12с у кластера, потом пауза 10с
local ncS=gCH_n();if ncS then return{"go_crosshair"}end -- v5.1.5: в скорче ближайший кросхейр приоритетнее стояния у флеймов
local spth=gFCPath(r.Position);if spth then return{"go_flame_path"}end -- v5.1.8: ПРИОРИТЕТ флейм-патха в скорче — бот бежит по цепочке кластеров огня вместо стояния у одного (запрос: больше бегать по флеймам)
if os.clock()>flCampCd then local clust=gFCB();if #clust>0 then local bestC,bestSz=nil,0;for i=1,math.min(3,#clust)do if clust[i].size>bestSz and clust[i].size>=4 then bestSz=clust[i].size;bestC=clust[i].center end end;if bestC then return{"go_flame_cluster_center"}end end end end
if isSO then
if n-lastSOTime>=10 then return{"go_super_outside"}end;local nearCH=gCH_n();if nearCH and not smT and not xfE then return{"go_crosshair"}end
if hTL()then return{"go_tokenlink"}end
for i,coco in ipairs(activeCocos)do if not coco.collected and coco.part.Parent and(3.0-(n-coco.spawnTime))<=1.0 and cfg.coco_on and(cfg.coco_lim==0 or cocoCycle<cfg.coco_lim)then return{"go_coconut"}end end
if p_=="REFRESH"then local all=gCH(false,false,true);if #all>0 then return{"go_crosshair_refresh_all"}end;return{"patrol_ring"}end
if p_=="X10"then return{"patrol_ring"}end;table.insert(ba,"patrol_ring");return ba end
-- v5.0.8: при 19+ XF ближайший к центру кросхейр в ЛЮБОЙ фазе (был кейс: 22 XF, фаза REFRESH — бот ушёл на фиолетовый в углу); дальше XCR*2 от центра — игнор, ждём у центра
if xfP>=19 and not isSS and not isSO then local cc=gFC();if cc~=ZERO then local bC=gCH_nc();if bC and d3(bC.part.Position,cc)<=XCR*2 then return{"go_center_ch"}end end;if(p_=="X10"or p_=="REFRESH")and os.clock()>=xfcCd then return{"go_xflame_center"}end end
if ndMorph and not isSc and not isSO then local hasSmiles=false;for p,t in pairs(aT)do if not t.col and p.Parent and t.id==SMI then hasSmiles=true;break end end;if hasSmiles then return{"go_smile_stand"}end;return{"go_noduped_morph"}end
-- v5.1.5: форс-лут морфа <6с перенесён в САМЫЙ ВЕРХ gAWB
if isSc then
-- v5.0.2: go_scorch_token — свежий TL/TP токен во время скорча (из v4.0)
for p,t in pairs(aT)do if not t.col and p.Parent and not t.dp and(t.id==TPI or t.id==1629547638)and(n-t.s)<2.5 and not btBlocked(p,t)then return{"go_scorch_token"}end end
-- v5.0.2: go_scorch_tp_cycle — цикл по дюпед TP в скорче
if scorchTPCycle then for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==TPI then return{"go_scorch_tp_cycle"}end end end
for p,t in pairs(aT)do if not t.col and p.Parent and t.id==2000457501 and t.dp and(n-t.s)>2.0 then return{"go_duped_inspire_scorch"}end end
else if #gCH(false,false,true)==0 then for p,t in pairs(aT)do if not t.col and p.Parent and t.dp then local age=n-t.s;local rem=t.l-age
if t.id==2000457501 and rem<2.0 and rem>0 then return{"go_duped_inspire_normal"}elseif t.id==1472256444 and rem<5.0 and rem>0 then return{"go_duped_babylove"}elseif(t.id==8173559749 or t.id==1442859163 or t.id==1442863423 or t.id==3877732821)and age>3 and rem>0 then return{"go_duped_boost"}end end end end end-- v5.0.8: дюпед бусты лутаем ТОЛЬКО когда на поле нет кросхейров — кросхейры приоритетнее
if #gCH(false,false,true)==0 then for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==1472256444 then local rem=t.l-(n-t.s);if rem<5.0 and rem>0 then return{"go_duped_babylove"}end end end end
-- v5.0.2: go_duped_pri — при 9+ дюпед собрать цепочку приоритетных DPRI (из v4.0 go_duped_pri)
if dupCnt>=9 then local hasDpri=false;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and DPRI[t.id]then hasDpri=true;break end end;if hasDpri then return{"go_duped_pri"}end end
-- v5.1.6: ветки смайла (go_smile_area/go_smile при 6+ дюпед) перенесены в самый верх gAWB — сразу после форс-морфа
-- v5.1.5: в фазе REFRESH таргет-практика приоритетнее петалов/линка/предикта (раньше ветка REFRESH стояла в самом низу)
if p_=="REFRESH"and not isSc and not isSS then local allR=gCH(false,false,true);if #allR>0 then return{"go_crosshair_refresh_all"}end end
if p_=="X10"and not isSO and xfP<19 then local pp=gCH(true,false,false);if #pp>0 and n>=prPauseUntil and cfg.purple_on and(cfg.purple_lim==0 or purpleMarkCnt<cfg.purple_lim)then return{"go_purple"}end end-- v5.2.8: в паузу прецов на фиолетовые не встаём -- v5.1.5: при 19+ XF на фиолетовый НЕ встаём — ждём/кемпим X-Flame
local ptCl=gPetCluster();if ptCl and #ptCl>0 then return{"go_petal_cluster"}end
if #fP>=2 and not isSS then return{"go_petal"}end-- v5.0.8: больше акцент на петалы — лутаем уже от 2 шт и вне скорча (раньше go_petal вне скорча вообще не возвращался)
-- v5.0.2: go_diagonal_loot — при 6+ кросхейров лут вдоль длинной оси (из v4.0)
local allForDiag=gCH(false,false,true);if #allForDiag>=6 and not isSc and not isSS and not isSO then return{"go_diagonal_loot"}end
-- v5.0.2: go_predictive_ch — бот бежит к точке предсказанного приземления высокого кросхейра
for _i2=1,#cQ do local _ch2=cQ[_i2];if not _ch2.col and _ch2.pPos and _ch2.part.Position.Y>20 then return{"go_predictive_ch"}end end
local nearCH=gCH_n()
-- v4.9: если на поле есть хоть один фиолетовый — сперва он, а не ближайший обычный
if nearCH and nearCH.isP and n<prPauseUntil then nearCH=nil end-- v5.2.8: пауза прецов: ближайший фиолетовый не лутаем
if nearCH and not smT and not xfE and not isSS and not isSO then if not nearCH.isP and xfP<19 and n>=prPauseUntil then local pp=gCH(true,false,false);if #pp>0 then return{"go_purple"}end end;return{"go_crosshair"}end -- v5.1.5: при 19+ XF не переключаемся с ближнего кросхейра на фиолетовый
if hTL()then return{"go_tokenlink"}end
for i,coco in ipairs(activeCocos)do if not coco.collected and coco.part.Parent and(3.0-(n-coco.spawnTime))<=1.0 and cfg.coco_on and(cfg.coco_lim==0 or cocoCycle<cfg.coco_lim)then return{"go_coconut"}end end
if smT and dupCnt>=6 and not isSO and os.clock()>=(smCd or 0)then return{"go_smile"}end-- v5.2.5: кулдаун смайла 12с и на нижнем приоритете
if not isSc and n>=prPauseUntil then local predPos=scanPreciseBee();if predPos then return{"go_precise_predict"}end end -- v5.0.1: PreBee теперь здесь, после кросхейров/смайла/кокосов
if p_=="REFRESH"then local all=gCH(false,false,true);if #all>0 then return{"go_crosshair_refresh_all"}end;return{"patrol_ring"}end
if p_=="X10"then return{"patrol_ring"}end
if p_=="NABOR"then
-- v5.0.2: go_token_near — ближайший ценный токен в NABOR (из v4.0)
local r3=h();if r3 then local bt3,bd3=nil,math.huge;for p,t in pairs(aT)do if not t.col and p.Parent and not tokenBL[p]and t.p>=7 and(t.l-(n-t.s))>0.3 and not btBlocked(p,t)and not moHold(t)then local d=d3(r3.Position,p.Position);if d<bd3 then bd3=d;bt3=p end end end;if bt3 and bd3<25 then return{"go_token_near"}end end
if hTL()then return{"go_tokenlink"}end;table.insert(ba,"patrol_ring");return ba end
return{"patrol_ring"}end

-- UCB
-- v5.1: выводы из анализатора паттернов вшиты в выбор действия: худшие связки — самоповторы (duped_boost>duped_boost n=225 avg=-1.3, dump_purple>dump_purple, duped_pri>duped_pri, inspire_scorch>inspire_scorch) — запрещаем то же действие два раза подряд; лучшие связки (линк/кокос/предикт -> петалы avg 70-77, фиолетовый -> линк avg 74) — форсим, когда оба доступны
PAT_REPBAD={go_duped_boost=true,go_backpack_dump_purple=true,go_duped_pri=true,go_duped_inspire_scorch=true};lastPatAct=""
-- v5.1.2: адаптивный эпсилон исследования — линейный спад 0.2 -> 0.03 за 2000 шагов; epT0 сбрасывается кнопкой Reset во вкладке Patterns — обучение перезапускается
function gEP()local st2=math.max(0,totalSteps-(epT0 or 0));if st2>=2000 then return 0.03 end;return 0.2-(0.17*st2/2000)end
local function cAB(s)local v=gAWB();if #v==0 then return"patrol_ring"end
local function has(a)for i=1,#v do if v[i]==a then return true end end;return false end
if(lastPatAct=="go_tokenlink"or lastPatAct=="go_coconut"or lastPatAct=="go_predictive_ch")and(has("go_petal_cluster")or has("go_petal"))then local pk=has("go_petal_cluster")and"go_petal_cluster"or"go_petal";lastPatAct=pk;return pk end
if lastPatAct=="go_purple"and has("go_tokenlink")then lastPatAct="go_tokenlink";return"go_tokenlink"end
local bA
if math.random()<gEP()then bA=v[math.random(1,#v)]
else
if not visitCount[s]then visitCount[s]={}end
local bS=-math.huge;bA=v[1]
for i=1,#v do local act=v[i];local qV=gQ(s,act);local nv=visitCount[s][act]or 0;local ub=UCB_C*math.sqrt(math.log(totalSteps+1)/(nv+1));local sc=qV+ub;if sc>bS then bA=act;bS=sc end end
visitCount[s][bA]=(visitCount[s][bA]or 0)+1
end
-- v5.1.3: динамический анти-повтор: не повторяем подряд ЛЮБОЕ действие, чей последний результат <=0 (ловит спам go_petal/go_xflame_center), плюс статический PAT_REPBAD
if bA==lastPatAct and(PAT_REPBAD[bA]or(lastActA==bA and(tonumber(lastActRw)or 0)<=0))then local alt=nil;for i=1,#v do if v[i]~=bA then alt=v[i];break end end;bA=alt or"patrol_ring"end
lastPatAct=bA;return bA end

-- Q-UPDATE (eligibility traces + prioritized replay)
local replayBuffer={};local replayMaxSize=100;local replayIndex=1
local function dUQ(s,a,rw,ns)local r=h();local tR=rw+flHit*2+chStick*1;if aborted then tR=tR-5 end;local now=os.clock();local comboMult=1;if lastActionTime>0 then local dt=now-lastActionTime;if dt<0.2 then comboMult=1.5 end;tR=(tR-(math.exp(dt*0.8)*0.5))*comboMult end;lastActionTime=now
if not eligibility[s]then eligibility[s]={}end;for stt,acts in pairs(eligibility)do for act,trace in pairs(acts)do eligibility[stt][act]=trace*0.95*0.7;if eligibility[stt][act]<0.001 then eligibility[stt][act]=nil end end end;eligibility[s][a]=(eligibility[s][a]or 0)+1
local v=gAWB();local mN=0;for i=1,#v do local q=gQ(ns,v[i]);if q>mN then mN=q end end;local tdError=tR+0.95*mN-gQ(s,a)
for stt,acts in pairs(eligibility)do for act,trace in pairs(acts)do sQ(stt,act,gQ(stt,act)+0.5*tdError*trace)end end
replayBuffer[replayIndex]={s=s,a=a,tR=tR,ns=ns,err=math.abs(tdError)};replayIndex=(replayIndex%replayMaxSize)+1
if totalSteps%5==0 and #replayBuffer>10 then local temp={};for i=1,#replayBuffer do table.insert(temp,replayBuffer[i])end;table.sort(temp,function(r1,r2)return r1.err>r2.err end);for i=1,math.min(3,#temp)do local exp=temp[i];local exp_mN=0;for j=1,#v do local q2=gQ(exp.ns,v[j]);if q2>exp_mN then exp_mN=q2 end end;local exp_tdError=exp.tR+0.95*exp_mN-gQ(exp.s,exp.a);sQ(exp.s,exp.a,gQ(exp.s,exp.a)+0.5*exp_tdError*0.8)end end
st.tR=st.tR+tR;st.dc=st.dc+1;totalSteps=totalSteps+1;EP=math.max(0.02,EP*ED);flHit=0;chStick=0;aborted=false end
-- EXECUTE
local function stToken(p)if not p or not p.Parent then return end;local t0=os.clock();while os.clock()-t0<1.1 do task.wait(0.05);if not p.Parent then break end;local h__=hm();if h__ then h__:MoveTo(Vector3.new(p.Position.X,p.Position.Y,p.Position.Z))end end end
local function eA(action)
local r=h();if not r then return-1 end
tL=action;pcall(hitBloom);pcall(hitFlames)
chBusy=(action=="go_crosshair"or action=="go_crosshair_all"or action=="go_crosshair_refresh_all"or action=="go_diagonal_loot"or action=="go_backpack_dump"or action=="go_backpack_dump_purple")-- v5.1.6: серия кросхейров дожимается до конца: пока идёт лут кросхейров, смайл-скан не дёргает INT
if action=="go_xflame_center_camp"then
local cc=gFC();if cc==ZERO then return-1 end
tL="XF Camp";INT=true
local hh=hm()
if hh then
local dir=(cc-Vector3.new(r.Position.X,0,r.Position.Z)).Unit
if dir.Magnitude>0 then hh:MoveTo(cc+Vector3.new(dir.X*1,0,dir.Z*1))else hh:MoveTo(cc)end end
task.wait(0.05);return 2 end
if action=="go_precise_predict"then local pp=scanPreciseBee();if not pp then return-1 end;tL="PreBee";INT=false;if goTo(Vector3.new(pp.X,r.Position.Y,pp.Z),2.5,4)then return 8 end;return-2 end
if action=="go_flame_path"then
local path=gFCPath(r.Position)
if not path then return-1 end
tL="FPth";INT=false;local rw=0
for i=1,#path do
local wp=path[i]
if goTo(Vector3.new(wp.X,r.Position.Y,wp.Z),4,2.5)then
rw=rw+5
-- v5.2.5: во время флейм-паса добираем ОДИН ближайший истекающий/ценный токен (Token Link p>=90 или любой с остатком <3с, радиус ~50 студов) — жалоба: линк <1с и короткоживущие токены пропускались
local gp,gk=nil,math.huge
for p,t in pairs(aT)do if not t.col and p.Parent and not tokenBL[p]and not btBlocked(p,t)and not moHold(t)then local rem=t.l-(os.clock()-t.s);if rem>0 and d2Sq(r.Position,p.Position)<=2500 and(t.p>=90 or rem<3.0)then local key=(t.p>=90 and-1000 or 0)+rem;if key<gk then gk=key;gp=p end end end end
if gp and aT[gp]then tL="FPth+tk";if goTo(Vector3.new(gp.Position.X,r.Position.Y,gp.Position.Z),3,2)and gp.Parent then aT[gp].col=true;tokenBL[gp]=os.clock()+1.5;st.tk=st.tk+1;rw=rw+8 end;r=h()or r end
local st_=os.clock()
while os.clock()-st_<0.5 do task.wait(0.05);pcall(hitFlames);pcall(hitBloom)end
else break end end
if rw>0 then
local sc=gSC()
if sc~=ZERO then goTo(Vector3.new(sc.X,r.Position.Y,sc.Z),5,2)end end
return rw>0 and rw+5 or-2 end
if action=="go_flame_cluster_center"then
local clust=gFCB();if #clust==0 then return-1 end
local bestC,bestSz=nil,0
for i=1,math.min(3,#clust)do
if clust[i].size>bestSz then bestSz=clust[i].size;bestC=clust[i].center end
end
if not bestC then return-1 end
if flameCampStart==0 then flameCampStart=os.clock()end
tL="FlClust";INT=false
goTo(Vector3.new(bestC.X,r.Position.Y,bestC.Z),4,3)
local campRw=bestSz;local st_=os.clock();local dashCd=0
while os.clock()-st_<1.5 do task.wait(0.03);pcall(hitFlames);pcall(hitBloom);if INT or not ENABLED then break end;r=h();if r then
local nearCH=nil;local nearD=math.huge;for i=1,#cQ do local ch=cQ[i];if not ch.col and ch.part.Parent and not(grnBad and grnBad(ch))then local dd=d2Sq(r.Position,ch.part.Position);if dd<nearD and dd<900 then nearD=dd;nearCH=ch end end end -- v5.1.5: дэш из кемпа тоже не на зелёные
if nearCH and nearD>16 and os.clock()>dashCd then
if goTo(nearCH.part.Position,2,2,(nearCH.isP or nil))and nearCH.part.Parent then
nearCH.col=true
if nearCH.isP then st.pr=st.pr+1;campRw=campRw+20
else st.ch=st.ch+1;campRw=campRw+10 end
end
local hm_=hm()
if hm_ then hm_:MoveTo(Vector3.new(bestC.X,r.Position.Y,bestC.Z))end
dashCd=os.clock()+0.5
end
for p,t in pairs(aT)do
if not t.col and p.Parent and not tokenBL[p]and d2Sq(r.Position,p.Position)<400 and(t.l-(os.clock()-t.s))>0.3 then
if t.p>=90 or t.id==SMI or t.id==TPI then
if d2Sq(r.Position,p.Position)<4 then
t.col=true;tokenBL[p]=os.clock()+1.2;st.tk=st.tk+1;campRw=campRw+15
else
local hm_=hm()
if hm_ then hm_:MoveTo(Vector3.new(p.Position.X,r.Position.Y,p.Position.Z))end
end;break
end
end
end
end -- closes if r then
end -- FIX v4.7.1: этот end закрывает while (его не хватало в v4.7 — причина ошибки на строке 1055)
flCampAcc=flCampAcc+1.5;if flCampAcc>=6 then flCampCd=os.clock()+8;flCampAcc=0 end-- v5.1.5: суммарно ~6с у флеймов, потом пауза 8с (12с стояния было слишком долго)
return math.max(10,campRw)end
if action=="go_smile_stand"then
local bp=nil;local bd=math.huge
for p,t in pairs(aT)do
if not t.col and p.Parent and t.id==SMI then
local d=d3(r.Position,p.Position)
if d<bd then bd=d;bp=p end end end
if bp then tL="Sm 1.1";INT=false
if goTo(bp.Position,4,4)and bp.Parent then
stToken(bp)
if aT[bp]then aT[bp].col=true;st.sm=st.sm+1 end
return 20 end end;return-2 end
if action=="go_noduped_morph"then if not ndMorph or not ndMorph.Parent then return-1 end;local t=aT[ndMorph];if not t then return-1 end;tL="MO(gnd)";INT=false;if goTo(ndMorph.Position,4,4)and ndMorph.Parent then stToken(ndMorph);t.col=true;return 20 end;return-2 end
if action=="go_duped_morph"then
local n=os.clock()
for p,t in pairs(aT)do
if not t.col and p.Parent and t.dp and t.mo and(t.l-(n-t.s))<6.0 then
tL="Morph(D)";INT=false
if goTo(p.Position,3,3)and p.Parent then
local t0=os.clock()
while os.clock()-t0<1.2 do
task.wait(0.05)
if not p.Parent then break end
local h__=hm()
if h__ then h__:MoveTo(Vector3.new(p.Position.X,p.Position.Y,p.Position.Z))end end
t.col=true;return 25 end end end;return-2 end
if action=="go_duped_morph_scorch"then local bp=nil;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.mo then bp=p;break end end;if bp then tL="MO(Sc)";INT=false;if goTo(bp.Position,4,3)and bp.Parent then stToken(bp);if aT[bp]then aT[bp].col=true;scorchDupedMorphDone=true end;return 30 end end;return-2 end
if action=="go_purple_scorch"then
local pp=gCH(true,false,false);if #pp==0 then return-1 end
local ch=pp[1]
if ch.part.Parent and not ch.col then
tL="P ScC";INT=false
-- v5.0.6: в скорче ВСТАЁМ на фиолетовый до срабатывания (standOnPurple), а не пробегаем — счёт 3 фиолетовых идёт по реальным стояниям
local okP=standOnPurple(ch,6)
if okP or not ch.part.Parent then
if not okP then ch.col=true;st.pr=st.pr+1 end
scorchPurpleCount=scorchPurpleCount+1
scorchPurpleTotal=scorchPurpleTotal+1
scorchPurpleTime=os.clock()
purpleMarkCnt=purpleMarkCnt+1;return 20
end
end;return-2
end
if action=="go_shower"then
-- v4.9: лут шоверов из v4.0 — цепочка TP по всем свежим шоверам, затем ценный токен и кросхейр
-- v5.2.6: восстановлен СТАРЫЙ лут шовера — velocity во время стояния на шовере больше НЕ прибивается к 0 каждый кадр (скорость считается нормально, лут не «залипает»). Оставлено одно мгновенное гашение velocity сразу после CFrame-ТП, чтобы телепорт-скачок не реплицировался как рывок. Настоящий фикс кика — кламп кросхейр-репульсии до 75 (см. HEATMAP)
for i=1,#activeShowers do
local sh=activeShowers[i]
if not sh.collected and sh.part.Parent and(os.clock()-sh.spawnTime)<1.2 then
tL="Shower";INT=false
r.CFrame=CFrame.new(sh.part.Position.X,sh.part.Position.Y+3,sh.part.Position.Z);r.AssemblyLinearVelocity=ZERO
local t0=os.clock()
while os.clock()-t0<2.0 do
task.wait(0.05);pcall(hitBloom);pcall(hitFlames)
if not sh.part.Parent then break end
end
sh.collected=true;showerCnt=showerCnt+1;showerCycle=showerCycle+1
local nf=true
while nf and not INT do nf=false
if cfg.shower_lim>0 and showerCycle>=cfg.shower_lim then break end-- v5.2.6: лимит за цикл ворнинг-дисков — цепочка не добирает сверх Farm Showers
for j=1,#activeShowers do
local ns=activeShowers[j]
if not ns.collected and ns.part.Parent and ns~=sh and(os.clock()-ns.spawnTime)<3.5 then
tL="Shower TP";r.CFrame=CFrame.new(ns.part.Position.X,ns.part.Position.Y+3,ns.part.Position.Z);r.AssemblyLinearVelocity=ZERO
local t1=os.clock()
while os.clock()-t1<2.0 do task.wait(0.05);pcall(hitBloom);pcall(hitFlames);if not ns.part.Parent then break end end
ns.collected=true;showerCnt=showerCnt+1;showerCycle=showerCycle+1;nf=true;break
end
end
end
acHold=0;local after=nil;local ad=math.huge-- v5.1.8: цепочка шоверов закончена — возвращаем управление CFrame-двигателю для добора токена/кросхейра
for p,t in pairs(aT)do
if not t.col and p.Parent then
local ok2=false
if t.id==SMI or t.id==2000457501 or(t.mo and not moHold(t))or t.id==8173559749 or t.p>=90 then ok2=true end -- v5.1.6: дюпед морф после шовера не трогаем, пока он «на удержании»
if ok2 and(t.l-(os.clock()-t.s))>0.3 then local d=d3(r.Position,p.Position);if d<ad then ad=d;after=p end end
end
end
if after then tL="Sh->Tk";goTo(after.Position,4,3);if after.Parent and aT[after]then aT[after].col=true;st.tk=st.tk+1 end end
local nch=gCH_n()
if nch and nch.isP then tL="Sh->P";goTo(nch.part.Position,4,3,true);if nch.part.Parent then nch.col=true;st.pr=st.pr+1 end
elseif nch then tL="Sh->CH";goTo(nch.part.Position,4,3);if nch.part.Parent then nch.col=true;st.ch=st.ch+1 end end
return 10+math.min(40,#activeShowers*10)
end
end;return-1
end
-- Coconut (with limit counter)
if action=="go_coconut"then
local n=os.clock()
-- v5.0: лутаем БЛИЖАЙШИЙ кокос, а не первый по времени появления
local bestCo,bestCoD=nil,math.huge
for i,c2 in ipairs(activeCocos)do if not c2.collected and c2.part.Parent and(3.0-(n-c2.spawnTime))<=1.0 then local dd=d3(r.Position,c2.part.Position);if dd<bestCoD then bestCoD=dd;bestCo=c2 end end end
local coco=bestCo
if coco then
tL="Coco";INT=false
local hh=hm();local origSp=cS
if hh then hh.WalkSpeed=cS+10 end
local cRad=math.max(coco.part.Size.X,coco.part.Size.Z)/2*0.65
local toCoco=coco.part.Position-r.Position
toCoco=Vector3.new(toCoco.X,0,toCoco.Z)
local edgePos
if toCoco.Magnitude>cRad then
edgePos=coco.part.Position-toCoco.Unit*cRad
else edgePos=coco.part.Position end
edgePos=Vector3.new(edgePos.X,r.Position.Y,edgePos.Z)
if goTo(edgePos,1.8,2.5)then
if hh then hh.WalkSpeed=origSp end
if coco.part.Parent then
coco.collected=true;cocoCnt=cocoCnt+1;cocoCycle=cocoCycle+1 end
return 30 end
if hh then hh.WalkSpeed=origSp end end;return-2 end
if action=="go_crosshair_all"then
local all=gCH(false,false,true);if #all==0 then return-1 end
local rw=0;INT=false
for i=1,#all do
local ch=all[i]
if ch.part.Parent and not ch.col then
if goTo(ch.part.Position,4,3,true)and ch.part.Parent then
ch.col=true
if ch.isP then st.pr=st.pr+1;rw=rw+20
else st.ch=st.ch+1;rw=rw+10 end end end end
-- v5.0.8: после лута кросхейров в СКОРЧЕ возвращаемся на кластер флеймов
if rw>0 and aB.SS.st>0 then local clA=gFCB();if #clA>0 then local rA=h();if rA then goTo(Vector3.new(clA[1].center.X,rA.Position.Y,clA[1].center.Z),4,3)end end end
return rw>0 and rw or-2 end
if action=="go_crosshair"then
local all=gCH(false,false,true);if #all==0 then return-1 end -- v4.9: фиолетовые всегда первыми
local t=all[1];local rw=0;INT=false
if t.part.Parent and not t.col then -- v5.1.6: смайл больше не блокирует уже начатый лут кросхейра
local sk=false
if xfE then
local cc=gFC()
if cc~=ZERO and d3(t.part.Position,cc)>XCR*1.5 then sk=true end
end
if not sk and hasNearPurpleCH()and not t.isP then sk=true end
if not sk then
if goTo(t.part.Position,4,5)and t.part.Parent then
t.col=true
if t.isP then
st.pr=st.pr+1;lP=t.part
rw=rw+(prec.nR and 5 or 10)
else
st.ch=st.ch+1;cyc.chC=cyc.chC+1
if cyc.chC>=3 then cyc.chC=0 end;rw=rw+8
end
end
end
end;return rw>0 and rw or-2
end
if action=="go_purple"then
local pp=gCH(true,false,false);if #pp==0 then return-1 end
if xfP>=19 then local ccP=gFC();if ccP~=ZERO then table.sort(pp,function(a,b)return d3(a.part.Position,ccP)<d3(b.part.Position,ccP)end)end end-- v5.0.8: при 19+ XF фиолетовые в порядке близости к центру, а не по времени спавна (фикс похода в угол при 22 XF)
local rw=0;INT=false
for i=1,#pp do
local ch=pp[i]
if ch.part.Parent and not ch.col and not smT then
if i==#pp then
if standOnPurple(ch,12)then rw=rw+25;tL="P stand"end
else
if goTo(ch.part.Position,3,3,true)and ch.part.Parent then
ch.col=true;lP=ch.part;st.pr=st.pr+1
tL="P run";rw=rw+15
end
end
if rw>0 then purpleMarkCnt=purpleMarkCnt+1 end
end
end;return rw>0 and rw or-2
end
if action=="go_tokenlink"then
local tl={};local n_=os.clock()
for p,t in pairs(aT)do
if not t.col and p.Parent and t.p>=90 and not tokenBL[p]and not btBlocked(p,t)then
local rem=t.l-(n_-t.s)
if rem>0.3 then table.insert(tl,{p=p,t=t,rem=rem})else tokenBL[p]=n_+10 end
end
end
if #tl==0 then return-2 end
table.sort(tl,function(a,b)return a.rem<b.rem end)
local bT=tl[1];if not bT then return-2 end
tL="Link";INT=false
-- v5.0.8: фикс "мёртвого линка": идём нарезками по 0.7с и каждую проверяем, что токен ещё жив/не истёк (раньше goTo 5с бежал к позиции уже исчезнувшего токена и бот стоял на пустом месте)
local okL=false;local tls=os.clock()
while os.clock()-tls<5 do
if not bT.p.Parent or not aT[bT.p]or aT[bT.p].col then tokenBL[bT.p]=os.clock()+8;return-4 end
if(bT.t.l-(os.clock()-bT.t.s))<=0 then tokenBL[bT.p]=os.clock()+10;return-4 end
if goTo(bT.p.Position,2.5,0.7)then okL=true;break end
if INT or not ENABLED then return-3 end
end
if okL and bT.p.Parent then
bT.t.col=true;lastTLT=os.clock();tokenBL[bT.p]=os.clock()+3
-- v5.1: ФИКС НАСОВСЕМ «стоит после лута линка»: стоячий цикл ожидания второго TL (2.5с, task.wait в холостую — бот стоял на месте) убран. Второй TL берём ТОЛЬКО если он уже жив на поле прямо сейчас, иначе мгновенно отдаём управление следующему действию
local r5=h()
if r5 then for p2c,t2c in pairs(aT)do if not t2c.col and p2c.Parent and t2c.id==1629547638 and d3(r5.Position,p2c.Position)<40 and(t2c.l-(os.clock()-t2c.s))>0.3 and not btBlocked(p2c,t2c)then if goTo(p2c.Position,4,3)and p2c.Parent then t2c.col=true;lastTLT=os.clock();return 80 end end end end
return 50
end;tokenBL[bT.p]=os.clock()+8;return-5
end
if action=="go_token_best"then
local n=os.clock();local cand={}
for p,t in pairs(aT)do
if not t.col and p.Parent and not tokenBL[p]then
local rem=t.l-(n-t.s)
if rem>0.5 and not btBlocked(p,t)and not moHold(t)then
-- v5.1.2: единая метрика: приоритет x остаток жизни x дистанция (clamp 40/d: ближние до x1.5, дальние до x0.3) — бот не бежит через всё поле за дешёвым токеном
local dTk=d3(r.Position,p.Position)
table.insert(cand,{p=p,score=t.p*(rem/t.l)*(t.dp and 1.3 or 1)*math.clamp(40/math.max(dTk,1),0.3,1.5)})
end
end
end
if #cand==0 then return-1 end
table.sort(cand,function(a,b)return a.score>b.score end)
local be=cand[1].p
if be then
tL=aT[be].n;INT=false
if goTo(be.Position,5,5)and be.Parent then
aT[be].col=true;tokenBL[be]=os.clock()+1.2
return 5+aT[be].p*0.3
end;return-3
end;return-1
end
if action=="go_smile"then local sm=smT;if not sm or not sm.Parent then smT=nil;return-1 end;local td=aT[sm];if not td or td.col then smT=nil;return-1 end;isCS=true;tL="Sm";INT=false;goSm=true;local hh=hm();local origSp=cS
for _,fp in ipairs(fP)do if fp.cn=="Pink"and fp.part.Parent then if hh then hh.WalkSpeed=cS+10 end;tL="Sm+10";if goTo(Vector3.new(fp.part.Position.X,0,fp.part.Position.Z),PCD,1.5)then st.pt=st.pt+1 end;break end end
local smTarget=sm.Position
if aR and aR.Parent then
local toSm=sm.Position-aR.Position
toSm=Vector3.new(toSm.X,0,toSm.Z)
if toSm.X*toSm.X+toSm.Z*toSm.Z>aRR*aRR then
smTarget=aR.Position+toSm.Unit*aRR*0.92
end
goTo(aR.Position,5,2)
local wt=os.clock()
while os.clock()-wt<0.3 do
task.wait(0.05)
local h__=hm()
if h__ then h__:MoveTo(Vector3.new(aR.Position.X,aR.Position.Y,aR.Position.Z))end
end
end
local toVal=math.max(0.5,math.min(3,smTR-0.3))
local ok=goTo(Vector3.new(smTarget.X,r.Position.Y,smTarget.Z),4,toVal)
goSm=false;if hh then hh.WalkSpeed=origSp end
if ok and sm.Parent then
if not td.dp then
td.col=true;smT=nil;st.sm=st.sm+1;isCS=false;dupCnt=0;smCd=os.clock()+12;return 45
end
local st_=os.clock()
while os.clock()-st_<TSD do
task.wait(0.1)
if not sm.Parent then break end
local h__=hm()
if h__ then h__:MoveTo(Vector3.new(smTarget.X,smTarget.Y,smTarget.Z))end
end
td.col=true;smT=nil;st.sm=st.sm+1;isCS=false;dupCnt=0;smCd=os.clock()+12;return 45
end
isCS=false;smT=nil;goSm=false
if hh then hh.WalkSpeed=origSp end;return-10
end
if action=="go_petal_cluster"then
local cl=gPetCluster();if not cl then return-1 end
local c=cl[1];tL="PtCl"..c.size;INT=false
local hh=hm();local origSp=cS
if hh then hh.WalkSpeed=cS+10 end
if goTo(c.center,5,3)then
local rw=0
for _,m in ipairs(c.members)do
if m.part.Parent then
if goTo(Vector3.new(m.part.Position.X,0,m.part.Position.Z),PCD,1.2)then
st.pt=st.pt+1;rw=rw+6+(14-m.pr)
if m.cn=="Red"then redPT=os.clock()end
end
end
end
if hh then hh.WalkSpeed=origSp end;return rw>0 and rw or 3
end
if hh then hh.WalkSpeed=origSp end;return-2
end
if action=="go_petal"then
if #fP==0 then return-1 end
-- v5.1.3: жёсткий возрастной фильтр УБРАН (он порождал спам go_petal>go_petal n=2051 avg=-0.9): лутаем в любой момент с появления — goTo идёт под точку падения и сам дожидается посадки (таймаут 2.5с); мягкий приоритет севшим даёт сортировка в sPt
local ca=false;local tr=0;local i=1
while i<=#fP do
local pt=fP[i]
if not pt.part.Parent then table.remove(fP,i)
elseif stP[pt.part]and os.clock()<stP[pt.part]then table.remove(fP,i)
else
tL=pt.cn;INT=false
if goTo(Vector3.new(pt.part.Position.X,0,pt.part.Position.Z),PCD,2.5)then
st.pt=st.pt+1;tr=tr+8+(14-pt.pr);ca=true
if pt.cn=="Red"then redPT=os.clock()end
task.wait(0.05);i=i+1
else stP[pt.part]=os.clock()+5;table.remove(fP,i)end
end
end;return ca and tr or-1
end
if action=="patrol_ring"then
local bt=nil;local bs2=-1;local n_=os.clock()
for p,td in pairs(aT)do
if not td.col and p.Parent and not tokenBL[p]then
local d=d3(r.Position,p.Position)
local rem=td.l-(n_-td.s)
if rem>0.5 and td.p>=1 and not btBlocked(p,td)and not moHold(td)then -- v5.1.6: патруль не лутает дюпед морф вне окна
local sc2=td.p*(1+(td.dp and 0.5 or 0))/(d+1)
if sc2>bs2 then bs2=sc2;bt=p end
end
end
end
if bt then
goTo(bt.Position,4,4)
if bt.Parent and aT[bt]then aT[bt].col=true;st.tk=st.tk+1 end
end
if aR and aR.Parent then
local ang=math.random()*2*math.pi
goTo(Vector3.new(aR.Position.X+math.cos(ang)*aRR*0.5*math.random(),r.Position.Y,aR.Position.Z+math.sin(ang)*aRR*0.5*math.random()),6,PT)
end
tL="R->AR";INT=false;task.wait(0.03);return 0
end
if action=="go_xflame_center"then local c=gFC();if c==ZERO then return-1 end;tL="XF c";INT=false;xfcCd=os.clock()+1.5;goTo(c,3,3);return 0 end
if action=="patrol_scorch_flames"then
local sc=gSC();tL="SS Patrol";INT=false
if sc~=ZERO then
local ang=math.random()*2*math.pi
local tp=Vector3.new(sc.X+math.cos(ang)*math.random()*aRR*0.4,r.Position.Y,sc.Z+math.sin(ang)*math.random()*aRR*0.4)
goTo(tp,5,PT)
end
task.wait(0.03);return 0
end
-- v4.8: недостающие исполнители действий (раньше они падали в return 0 и бот стоял AFK)
if action=="go_duped_boost"or action=="go_duped_babylove"or action=="go_duped_inspire_scorch"or action=="go_duped_inspire_normal"or action=="go_duped_inferno_scorch"or action=="go_duped_tp_scorch"then
local want
if action=="go_duped_boost"then want=function(t)return t.id==8173559749 or t.id==1442859163 or t.id==1442863423 or t.id==3877732821 end
elseif action=="go_duped_babylove"then want=function(t)return t.id==1472256444 end
elseif action=="go_duped_inferno_scorch"then want=function(t)return t.id==4519549299 end
elseif action=="go_duped_tp_scorch"then want=function(t)return t.id==TPI end
else want=function(t)return t.id==2000457501 end end
local bp,bd=nil,math.huge
for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and want(t)and not tokenBL[p]then local d=d3(r.Position,p.Position);if d<bd then bd=d;bp=p end end end
if not bp then return-1 end
tL="DupTk";INT=false
if goTo(bp.Position,3,3)and bp.Parent then stToken(bp);if aT[bp]then aT[bp].col=true end;return 25 end
return-2 end
if action=="go_backpack_dump"or action=="go_backpack_dump_purple"then
local lst=(action=="go_backpack_dump_purple")and gPCH()or gCH(false,false,true)
if #lst==0 then return-1 end
tL="Dump";INT=false;local rw=0
-- v5.0.5: при дампе СТОИМ на кросхейре до его срабатывания (до 6с), а не пробегаем мимо
for i=1,math.min(3,#lst)do local ch=lst[i];if ch.part.Parent and not ch.col then
if goTo(ch.part.Position,3,4,(ch.isP or nil))and ch.part.Parent then
local hm3=hm();local t0d=os.clock()
while os.clock()-t0d<6 and ch.part.Parent do task.wait(0.05);pcall(hitBloom);pcall(hitFlames);if INT or not ENABLED then break end;if hm3 then hm3:MoveTo(ch.part.Position)end end
ch.col=true;if ch.isP then st.pr=st.pr+1;rw=rw+20 else st.ch=st.ch+1;rw=rw+10 end end end end
return rw>0 and rw or-2 end
if action=="go_super_outside"then
lastSOTime=os.clock();tL="SO";INT=false
-- v5.0.5: дюпед морф НЕ лутаем сразу — дежурим в ~5 студах от него и ждём скорча (как в v4.0); подбор только в скорче или при rem<2.5
local bp,bd=nil,math.huge
for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.mo and not tokenBL[p]then local d=d3(r.Position,p.Position);if d<bd then bd=d;bp=p end end end
if bp then local off=r.Position-bp.Position;off=Vector3.new(off.X,0,off.Z);local dir=off.Magnitude>0.5 and off.Unit or Vector3.new(1,0,0)
if goTo(bp.Position+dir*5,2.5,4)then return 10 end;return-2 end
return-1 end
-- v5.0.2: go_diagonal_loot executor
if action=="go_diagonal_loot"then
local all=gCH(false,false,true);if #all<6 then return-1 end
local sumX,sumZ,sumXX,sumZZ,ct2=0,0,0,0,0
for _,ch in ipairs(all)do local p2=ch.part.Position;sumX=sumX+p2.X;sumZ=sumZ+p2.Z;sumXX=sumXX+p2.X*p2.X;sumZZ=sumZZ+p2.Z*p2.Z;ct2=ct2+1 end
local varX=ct2>0 and(sumXX/ct2-(sumX/ct2)^2)or 0;local varZ=ct2>0 and(sumZZ/ct2-(sumZ/ct2)^2)or 0
local useX=varX>varZ
table.sort(all,function(a,b)return(useX and a.part.Position.X or a.part.Position.Z)<(useX and b.part.Position.X or b.part.Position.Z)end)
local rw=0;tL="Diag"..#all;INT=false
for _,ch in ipairs(all)do if ch.part.Parent and not ch.col then if goTo(ch.part.Position,4,3,(ch.isP or nil))and ch.part.Parent then ch.col=true;if ch.isP then st.pr=st.pr+1;rw=rw+20 else st.ch=st.ch+1;rw=rw+10 end end end end
return rw>0 and rw or-2 end
-- v5.0.2: go_predictive_ch executor — идём к предсказанной точке приземления
if action=="go_predictive_ch"then
local best2,bestD2=nil,math.huge;local r2=h();if not r2 then return-1 end
for _i=1,#cQ do local ch=cQ[_i];if not ch.col and ch.pPos and ch.part.Position.Y>20 then local d=d3(r2.Position,ch.pPos);if d<bestD2 then bestD2=d;best2=ch end end end
if not best2 then return-1 end;tL="PredCH";INT=false
if goTo(Vector3.new(best2.pPos.X,r2.Position.Y,best2.pPos.Z),3,5)then if best2.part.Parent and not best2.col then best2.col=true;if best2.isP then st.pr=st.pr+1;return 18 else st.ch=st.ch+1;return 12 end end;return 5 end;return-2 end
-- v5.0.2: go_token_near executor
if action=="go_token_near"then
local r4=h();if not r4 then return-1 end;local bt4,bd4=nil,math.huge;local n4=os.clock()
for p,t in pairs(aT)do if not t.col and p.Parent and not tokenBL[p]and t.p>=7 and(t.l-(n4-t.s))>0.3 and not btBlocked(p,t)and not moHold(t)then local d=d3(r4.Position,p.Position);if d<bd4 then bd4=d;bt4=p end end end
if not bt4 then return-1 end;tL=aT[bt4].n;INT=false
if goTo(bt4.Position,4,4)and bt4.Parent then aT[bt4].col=true;tokenBL[bt4]=os.clock()+1.2;return 3+aT[bt4].p*0.2 end;tokenBL[bt4]=os.clock()+3;return-2 end
-- v5.0.2: go_duped_pri executor — цепочка DPRI при 9+ дюпед
if action=="go_duped_pri"then
local n2=os.clock();local cand={};for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and DPRI[t.id]then table.insert(cand,{p=p,t=t,rem=t.l-(n2-t.s)})end end
if #cand==0 then return-1 end;table.sort(cand,function(a,b)return a.t.p>b.t.p end)
tL="DupPri";INT=false;local rw=0
for _,e in ipairs(cand)do if e.p.Parent and not e.t.col and e.rem>0 then if goTo(e.p.Position,3,3)and e.p.Parent then stToken(e.p);e.t.col=true;rw=rw+30 end end end
return rw>0 and rw or-2 end
-- v5.0.2: go_smile_area executor — к краю AreaRing, затем смайл (из v4.0)
if action=="go_smile_area"then
local sm2=smT;if not sm2 or not sm2.Parent then smT=nil;return-1 end
if not aR or not aR.Parent then return-1 end
tL="SmArea";INT=false;isCS=true
local toSm=sm2.Position-aR.Position;toSm=Vector3.new(toSm.X,0,toSm.Z)
local edgePos=aR.Position+toSm.Unit*(aRR*0.9)
goTo(edgePos,3,2)
local ok3=goTo(Vector3.new(sm2.Position.X,r.Position.Y,sm2.Position.Z),4,5)
isCS=false
if ok3 and sm2.Parent then if aT[sm2]then aT[sm2].col=true end;smT=nil;st.sm=st.sm+1;dupCnt=0;smCd=os.clock()+12;return 50 end
if not sm2.Parent then smT=nil end -- v5.1.5: смайл теряем только если он реально исчез; после неудачи ретрай (раньше smT=nil и -8 — смайл в ареаринге бросался с первой неудачи)
return-2 end
-- v5.0.2: go_scorch_token executor — свежий TL/TP в скорче
if action=="go_scorch_token"then
local n3=os.clock();local bp5,bd5=nil,math.huge
for p,t in pairs(aT)do if not t.col and p.Parent and not t.dp and(t.id==TPI or t.id==1629547638)and(n3-t.s)<2.5 and not btBlocked(p,t)then local d=d3(r.Position,p.Position);if d<bd5 then bd5=d;bp5=p end end end
if not bp5 then return-1 end;tL="ScTok";INT=false
if goTo(bp5.Position,4,3)and bp5.Parent then if aT[bp5]then aT[bp5].col=true end;st.tk=st.tk+1;return 20 end;return-2 end
-- v5.0.2: go_scorch_tp_cycle executor
if action=="go_scorch_tp_cycle"then
local bp6,bd6=nil,math.huge;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==TPI then local d=d3(r.Position,p.Position);if d<bd6 then bd6=d;bp6=p end end end
if not bp6 then scorchTPCycle=false;return-1 end;tL="ScTP";INT=false
if goTo(bp6.Position,3,3)and bp6.Parent then stToken(bp6);if aT[bp6]then aT[bp6].col=true end;scorchTPIndex=scorchTPIndex+1;return 25 end;return-2 end
if action=="go_center_ch"then
-- v5.0.7: раньше действие было мёртвым: при xfE Heartbeat каждый кадр ставит INT=true и goTo сразу падал, а cP клампил цель на кольцо XCR. Теперь прямой MoveTo (как у кемпа) и СТОИМ на кросхейре до срабатывания (до 4с)
local ch=gCH_nc();if not ch then return-1 end
tL="C-CH";local hmC=hm();if not hmC then return-1 end
local t0c=os.clock();local xfE0=xfE
while os.clock()-t0c<4 and ch.part.Parent and not ch.col do
task.wait(0.05);pcall(hitBloom);pcall(hitFlames)
if not ENABLED then return-2 end
-- v5.1.2: кросхейр сработал ВО ВРЕМЯ стояния (X-Flame заспавнился) — немедленно отменяем стояние, не достаиваем 4с
if xfE and not xfE0 then break end
hmC:MoveTo(ch.part.Position)
end
if xfE and not xfE0 then ch.col=true;st.ch=st.ch+1;return 15 end
-- v5.0.8: фиолетовый у центра идёт в счёт 3 фиолетовых скорча (иначе при xfE-кемпе окно AllCH никогда бы не открылось)
if not ch.part.Parent then ch.col=true;if ch.isP then st.pr=st.pr+1;if aB.SS.st>0 then scorchPurpleCount=scorchPurpleCount+1;scorchPurpleTotal=scorchPurpleTotal+1;scorchPurpleTime=os.clock()end else st.ch=st.ch+1 end;return 15 end
local rC=h()
if rC and d2Sq(rC.Position,ch.part.Position)<=16 then ch.col=true;if ch.isP then st.pr=st.pr+1;if aB.SS.st>0 then scorchPurpleCount=scorchPurpleCount+1;scorchPurpleTotal=scorchPurpleTotal+1;scorchPurpleTime=os.clock()end else st.ch=st.ch+1 end;return 12 end
return-2 end
if action=="go_crosshair_refresh_all"then
local all=gCH(false,false,true);if #all==0 then return-1 end
local rw=0;INT=false;tL="RefAll"
for i=1,#all do local ch=all[i];if ch.part.Parent and not ch.col then if goTo(ch.part.Position,4,3,(ch.isP or nil))and ch.part.Parent then ch.col=true;if ch.isP then st.pr=st.pr+1;rw=rw+15 else st.ch=st.ch+1;rw=rw+8 end end end end
return rw>0 and rw or-2 end
return 0 end
-- HEATMAP (crosshair repulsion)
R.RenderStepped:Connect(function()
if not ENABLED then return end
local r=h();if not r then return end
local refV=ZERO
if cATFrame==hbF then
local nearD=math.huge-- v5.2.6: НЕ суммируем отталкивание по кластеру (раньше 140×N кросхейров) — берём только БЛИЖАЙШИЙ
for _,cc in pairs(cATCache)do
local th=cc and cc.th
if type(th)=="table"then
for _,t in ipairs(th)do
if t.pos then
local toCh=r.Position-t.pos
local dist=toCh.Magnitude
if dist<(t.sz*0.5+8)and dist>0.1 and dist<nearD then nearD=dist;refV=toCh.Unit*75 end
end
end
end
end
end
if refV.Magnitude>0.1 then
-- v5.2.6: АНТИ-КИК (корень кика при луте кросхейров): раньше сюда вливалась сырая velocity 140×N поверх текущей — velocity-чек ловил спайк 140-560. Теперь итоговая горизонтальная скорость клампится до легитных 75 студ/с
local v=r.AssemblyLinearVelocity
local nv=Vector3.new(v.X+refV.X,0,v.Z+refV.Z)
if nv.Magnitude>75 then nv=nv.Unit*75 end
r.AssemblyLinearVelocity=Vector3.new(nv.X,v.Y,nv.Z)
end
end)

-- v5.0.6: НЕЗАВИСИМЫЙ анти-стак вотчдог: старый жил в Heartbeat и ПРОПУСКАЛСЯ при isA=true (во время любого действия) — поэтому бот мог вечно стоять на линке ВНУТРИ goTo. Этот работает всегда.
STK_T=os.clock()
task.spawn(function()while true do task.wait(0.5)
pcall(function()
if not ENABLED or hchBusy or hchDodge or goSm or isCS then STK_T=os.clock()return end
local lbl=tostring(tL or"")
if lbl=="P Stand"or lbl=="Dump"or lbl=="XF Camp"or lbl=="unstuck"or lbl:find("Shower")or lbl:find("Sm")or lbl:find("Hachapuri")then STK_T=os.clock()return end
local r9=h();if not r9 then STK_T=os.clock()return end
local v9=r9.AssemblyLinearVelocity
if Vector3.new(v9.X,0,v9.Z).Magnitude>0.5 then STK_T=os.clock()return end
if os.clock()-STK_T>6 then
STK_T=os.clock()
le("WATCHDOG: застрял на '"..lbl.."' — блэклист целей рядом и сброс")
for p,t in pairs(aT)do if not t.col and p.Parent and d3(r9.Position,p.Position)<10 then tokenBL[p]=os.clock()+8 end end
for i=1,#cQ do local ch=cQ[i];if not ch.col and ch.part.Parent and d3(r9.Position,ch.part.Position)<10 then ch.col=true end end
INT=true;tL="unstuck"
task.delay(1.2,function()if tL=="unstuck"then INT=false end end)
end
end)
end end)

-- ANTI LAG
if ELA then task.spawn(function()
local tg={"Flowers","Bees","FieldDecos","Collectibles","NPCs"}
for _,n in pairs(tg)do
local f=W:FindFirstChild(n)
if f then
local d=f:GetDescendants()
for i=1,#d do
local o=d[i]
if o:IsA("BasePart")or o:IsA("MeshPart")then
o.Transparency=1;o.CastShadow=false;o.Material=Enum.Material.SmoothPlastic
elseif(o:IsA("Decal")or o:IsA("Texture"))and o.Name~="FaceTexture"then
o:Destroy()-- v5.0: FaceTexture прецайсов не трогаем — нужен для детекта диагонали
end
if i%100==0 then task.wait()end
end
end
end
local lt=W:FindFirstChild("Lighting")
if lt then lt.GlobalShadows=false;lt.Brightness=2 end
end)end

-- v5.2.0: АНТИ-ЛАГ FFlag-пак (Volt performance pack). ВНИМАНИЕ: большинство рендер-флагов Roblox читает при СТАРТЕ клиента — надёжнее держать их в fastflags-конфиге исполнителя (volt-headless файл). Здесь применяем в рантайме, если исполнитель поддерживает setfflag. v5.2.1: сетевые DFIntDataSenderRate/PhysicsReplicationSenderRate УБРАНЫ — учащали репликацию позиции и повышали риск кика при AC Test. Добавлен FPS-блок (TargetFps/текстуры/свет).
task.spawn(function()if not setfflag then return end
local FF={
{"FFlagTaskSchedulerBlocking","false"},{"FFlagTaskSchedulerLimitTargetFpsTo2402","false"},{"FFlagHandleAltEnterFullscreenManually","false"},{"DFFlagThrottleRenderUntilGameLoaded","false"},
{"FFlagDebugGraphicsPreferD3D11","true"},{"FFlagDebugGraphicsDisableD3D10","true"},{"FFlagDebugGraphicsDisableOpenGL","true"},{"FFlagDebugGraphicsDisableVulkan","true"},{"FFlagDebugGraphicsDisableMetal","true"},{"FFlagDebugGraphicsDisableDirect3D11","false"},
{"DFIntDebugFRMQualityLevelOverride","1"},{"FFlagCommitToGraphicsQualityFix","true"},{"FFlagFixGraphicsQuality","true"},{"DFIntTextureQualityOverride","1"},{"DFIntTextureCompositorActiveJobs","0"},
{"FFlagDisablePostFx","true"},{"FIntRenderShadowIntensity","0"},{"DFFlagDebugPauseVoxelizer","true"},{"DFFlagDebugRenderForceTechnologyVoxel","true"},{"FFlagDebugSkyGray","true"},{"FFlagFastGPULightCulling3","true"},{"FIntDebugForceMSAASamples","0"},{"FIntAntiAliasingMaxQuality","0"},{"FFlagAntiAliasingEnabled","false"},
{"FIntTerrainArraySliceSize","4"},{"FIntFRMMinGrassDistance","0"},{"FIntFRMMaxGrassDistance","0"},{"DFIntCSGLevelOfDetailSwitchingDistance","0"},{"DFIntCSGLevelOfDetailSwitchingDistanceL12","0"},{"DFIntCSGLevelOfDetailSwitchingDistanceL23","0"},{"DFIntCSGLevelOfDetailSwitchingDistanceL34","0"},
{"DFIntParticleCloneLimit","0"},{"FIntSmoothClusterMaxParticleEffectsPerFrame","10"},{"DFIntRenderingThrottleDelayInMS","100"},
{"FStringPartTexturePackTable2022",""},{"FStringPartTexturePackTablePre2022",""},{"FStringTerrainMaterialTablePre2022",""},{"FStringTerrainMaterialTable2022",""},
{"DFIntCharacterAnimationLodFullDistance","0"},{"DFIntAnimationDistanceFactor","0"},
{"DFIntReplicationDataCacheNumWaitingPacketsLimit","1024"},{"DFIntInterpolationAddSyncOffset","0"},{"FIntRakNetResendRtt","10"},{"DFFlagDebugBypassRakNetClient","false"},
{"FFlagHttpClientJsonV2","true"},
{"DFIntMaxAvailablePhysicalMemoryMB","8192"},{"DFIntMemStorageQueueSize","10000"},
{"DFIntSecondsBetweenDynamicVariableReloading","99999"},{"FFlagAdServiceEnabled","false"},{"FFlagDebugDisplayFPS","true"},{"FFlagDebugForceFutureIsBrightPhase3","false"},{"FIntTerrainOTAUpdatesPerFrame","0"},{"FFlagDebugSimDefaultPrimalSolver","true"},
{"DFIntTaskSchedulerTargetFps","360"},{"DFFlagTextureQualityOverrideEnabled","true"},{"FIntRenderLocalLightUpdatesMax","0"},{"FIntRenderLocalLightUpdatesMin","0"},{"FFlagDebugForceFutureIsBrightPhase2","false"}
}
local ok_=0;for _,f in ipairs(FF)do if pcall(setfflag,f[1],f[2])then ok_=ok_+1 end end;if lo then pcall(lo,"AntiLag FFlags: "..ok_.."/"..#FF)end
end)

-- PRECISE BEE
-- v5.0: прецайсов много (Workspace.Bees.Precise), у каждого FaceTexture — если прецайс ВЫШЕ игрока, смотрим куда повёрнут FaceTexture и детектим диагональ
local function findPreciseBees()local bees=W:FindFirstChild("Bees");if not bees then return{}end;local res={};for _,b in ipairs(bees:GetChildren())do local nm=b.Name or"";if nm:find("Precise")or nm:find("precise")then if b:IsA("BasePart")then table.insert(res,b)elseif b:IsA("Model")then local hrp2=b:FindFirstChild("HumanoidRootPart")or b:FindFirstChildWhichIsA("BasePart");if hrp2 then table.insert(res,hrp2)end end end end;return res end
pbCacheRes,pbCacheT=nil,-1
pbTargets,pbTargetsT=nil,-10
pbRP=RaycastParams.new();pbRP.FilterType=Enum.RaycastFilterType.Whitelist
function scanPreciseBee()
-- v5.0.1: фикс FPS-спайков PreBee — результат кэшируется на 0.25с, цели и RaycastParams пересобираются раз в 5с
local nowP=os.clock()
if nowP-pbCacheT<0.25 then return pbCacheRes end
pbCacheT=nowP;pbCacheRes=nil
local bees=findPreciseBees();if #bees==0 then return nil end;local r=h();if not r then return nil end
if not pbTargets or nowP-pbTargetsT>5 then
pbTargets={};pbTargetsT=nowP
local fl=W:FindFirstChild("Flowers");if fl then for _,f in ipairs(fl:GetChildren())do if f:IsA("BasePart")then table.insert(pbTargets,f)end end end
local fz=W:FindFirstChild("FlowerZones");if fz then for _,z in ipairs(fz:GetChildren())do if z:IsA("BasePart")then table.insert(pbTargets,z)end end end
pbRP.FilterDescendantsInstances=pbTargets
end
local targets=pbTargets
if #targets==0 then return nil end
local rp=pbRP
for _,bp in ipairs(bees)do
if bp.Parent and bp.Position.Y>r.Position.Y+1 then
local ft=bp:FindFirstChild("FaceTexture")
local look
if ft and(ft:IsA("Decal")or ft:IsA("Texture"))then look=bp.CFrame:VectorToWorldSpace(Vector3.FromNormalId(ft.Face))else look=bp.CFrame.LookVector end
local key=string.format("%.0f,%.0f,%.1f,%.1f",bp.Position.X/3,bp.Position.Z/3,look.X,look.Z)
if preciseLearn[key]then local rec=preciseLearn[key];if os.clock()-rec.t<60 and d2Sq(r.Position,rec.pos)>36 then pbCacheRes=rec.pos;return pbCacheRes end end
local res=W:Raycast(bp.Position,look.Unit*300,rp)-- диагональ вдоль взгляда FaceTexture
if not res then local flat=Vector3.new(look.X,0,look.Z);if flat.Magnitude>0.05 then res=W:Raycast(bp.Position,(flat.Unit+Vector3.new(0,-1,0)).Unit*300,rp)end end
if res then preciseLearn[key]={pos=res.Position,t=os.clock()};if d2Sq(r.Position,res.Position)>36 then pbCacheRes=res.Position;return pbCacheRes end end
end
end;return nil end

-- v4.8: визуал предикта кросхейров — небольшие неоновые точки в предсказанных местах
local predictDots={}
task.spawn(function()while true do task.wait(0.4)
pcall(function()
local n=os.clock()
local live={}
for key,rec in pairs(preciseLearn)do
if n-rec.t<60 then
live[key]=true
local d=predictDots[key]
if not d or not d.Parent then
d=Instance.new("Part");d.Shape=Enum.PartType.Ball;d.Size=Vector3.new(1.1,1.1,1.1);d.Anchored=true;d.CanCollide=false;pcall(function()d.CanQuery=false end)
d.Material=Enum.Material.Neon;d.Color=Color3.fromRGB(0,255,255);d.Transparency=0.15
d.Position=rec.pos+Vector3.new(0,1.5,0);d.Name="MZ_Predict";d.Parent=W
predictDots[key]=d
end
end
end
for key,d in pairs(predictDots)do
if not live[key]then pcall(function()d:Destroy()end);predictDots[key]=nil end
end
end)
end end)

-- INIT
local mLS=false
local function sML()if mLS then return end;mLS=true;task.wait(2);scriptStartH=getHoney()or 0;scriptStartT=os.clock();lQ();lSS();lPat();fAR();fF();lo("Marmot Z v5.2.6 ready! "..fmtH(scriptStartH));print("Marmot Z v5.2.6 — Complete");tL="init";lMT=os.clock()end
task.spawn(function()while true do task.wait(30);pcall(function()local lt=W:FindFirstChild("Lighting");if lt then lt.GlobalShadows=false;lt.Brightness=2 end end)end end)
task.spawn(function()while true do task.wait(scorchActive and 1.0 or 1.5);if mLS then pcall(pAB)end end end)-- v5.2.5: кап pAB в скорче 0.5->1.0с (скорч-спайк ~96->~48/мин, финальный добив E3); онсет скорча всё равно ловится вне скорча на 1.5с. v5.2.4: адаптивный троттлинг pAB — 0.5с в скорче, 1.5с вне скорча: режет RetrievePlayerStats:InvokeServer со 120/мин до ~40/мин вне скорча (комбо xf/sc идут через PAE.OnClientEvent, событийно, поэтому детект скорча не страдает; онсет скорча ловится с задержкой <=1.5с — на 2-3 мин скорча это ~1%)
-- v5.0: спидхак работает ВСЕГДА, даже после кнопки STOP
task.spawn(function()while true do task.wait(0.25)pcall(function()local h_=hm();if h_ then local ts=gAS();if math.abs(h_.WalkSpeed-ts)>0.5 then h_.WalkSpeed=ts end end end)end end)
-- v5.2.6: AC Test (CFrame-движок) удалён — режим больше не нужен; кик лечится клампом кросхейр-репульсии (см. HEATMAP)

-- HEARTBEAT (FIX v4.7.1: getgenv() вместо G — G это PlayerGui, на нём нельзя хранить коннект)
local genv=(getgenv and getgenv())or _G
if genv.MarmotZ_HB then pcall(function()genv.MarmotZ_HB:Disconnect()end)end
genv.MarmotZ_HB=R.Heartbeat:Connect(function()
hbF=hbF+1;if not ENABLED then return end;if not mLS then sML();return end;local n=os.clock();if hbF%15==0 then fAR()end -- v5.0.6: fAR сканировал Particles КАЖДЫЙ кадр — теперь раз в 15 кадров
if hbF%9==0 then sPt();scS();verifyTokens();local h_=hm();if h_ then local ts=gAS();if math.abs(h_.WalkSpeed-ts)>0.5 then h_.WalkSpeed=ts end end end
if hbF%3==0 then sSm()end;if hbF%180==0 then fF()end;if hbF%60==0 then clnCH()end
if prec.isX and not prec.nR then local r=h();if r then for i=1,#cQ do local ch=cQ[i];if ch.part and ch.part.Parent and not ch.col and not ch.isP and d3(r.Position,ch.part.Position)<4 then if isGreenCH(ch)then if n-lPT>1.5 then lPT=n;local s_=eS();if s_ and s_~="dead"then pcall(dUQ,s_,"patrol_ring",-80,s_)end;st.chA=st.chA+1;xGCH=xGCH+1;le("GREEN CH -80! total:"..xGCH);local gck=string.format("%.0f,%.0f",ch.part.Position.X,ch.part.Position.Z);greenCH_cache[gck]=os.clock()+10 end end;break end end end end
local nowBL=os.clock();for p,exp in pairs(tokenBL)do if type(exp)=="number"and nowBL>exp then tokenBL[p]=nil end end
if hchDodge or hchBusy then return end -- v5.0: во время фаз Hachapuri (сдача/додж Мондо) автофарм не вмешивается
if isA then return end
isA=true -- v4.8: решение каждый кадр (было через кадр)
local gr=h()
if gr then
flHit=0;chStick=0;aborted=false
local s_=eS()
local a_=cAB(s_)
local ok,rw=pcall(eA,a_)
if not ok then
le(a_.." crash: "..tostring(rw));rw=-1 end
local ns=eS()
-- v5.0.6: запись ВСЕХ действий как в v4.0: actLog -> marmot_z_pat.json; в скорче дополнительно scorchActions -> marmot_z_scorch.json (раньше в scorchActions НИЧЕГО не писалось — не было ни одного table.insert)
-- v5.1.3: подряд идущие одинаковые действия с наградой <=0 схлопываются в одну запись (счётчик n2) — лог не вымывается спамом; lastActA/lastActRw кормят анти-повтор в cAB
lastActA=a_;lastActRw=rw
local le9=actLog[#actLog]
if le9 and le9.a==a_ and rw<=0 and(tonumber(le9.rw)or 0)<=0 then le9.n2=(le9.n2 or 1)+1;le9.t=math.floor((os.clock()-(scriptStartT or 0))*10)/10
else table.insert(actLog,{a=a_,rw=rw,t=math.floor((os.clock()-(scriptStartT or 0))*10)/10,ctx=s_})end
while #actLog>PAT_WINDOW do table.remove(actLog,1)end
if scorchRecording then table.insert(scorchActions,{a=a_,rw=rw,t=math.floor((os.clock()-scorchStartT)*10)/10})end
pcall(dUQ,s_,a_,rw,ns)end
isA=false
local prevXfE=xfE;xfE=(aB.XF.st>=19 and xfP>=10);if xfE and not prevXfE then xfStartTime=os.clock()end;if xfE then INT=true end
local r=h();if r then local vel=r.AssemblyLinearVelocity;if(Vector3.new(vel.X,0,vel.Z)).Magnitude>0.2 then lMT=n;stW=false elseif n-lMT>5 and not stW then stW=true;lMT=n
-- v5.0.4: бот реально застрял (>5с без движения) — блэклистим всё рядом (битые токены/кросхейры) и сбрасываем цель вместо вечного AFK (раньше INT=true сразу же сбрасывался и ни на что не влиял)
le("STUCK on '"..(tL or"?").."' -> forced unstuck")
for p,t in pairs(aT)do if not t.col and p.Parent and d3(r.Position,p.Position)<8 then tokenBL[p]=os.clock()+4 end end
for i=1,#cQ do local ch=cQ[i];if not ch.col and ch.part.Parent and d3(r.Position,ch.part.Position)<8 then ch.col=true end end
smT=nil;isCS=false;INT=true;tL="unstuck"
end end
if INT and not smT and not prec.nR and not xfE then INT=false end
end)

-- Q-TABLE LOAD/SAVE
function lQ()if not readfile then return end;local ok,raw=pcall(readfile,"marmot_z_q.json");if ok and raw then local ok2,d=pcall(H.JSONDecode,H,raw);if ok2 and type(d)=="table"and d.version==Q_VERSION and type(d.qtable)=="table"then QT=d.qtable end end end
-- v5.0.5 FIX: sSS/lSS были local и объявлены НИЖЕ по файлу, чем pAB и sML — те видели только nil-глобалы, поэтому файл скорча НИКОГДА не писался и не читался. Теперь это глобалы.
function sSS()if not writefile then return end;pcall(function()writefile("marmot_z_scorch.json",H:JSONEncode({sessions=scorchSessions,best=bestSH}))end)end
function lSS()if not readfile then return end;local ok,raw=pcall(readfile,"marmot_z_scorch.json");if ok and raw then local ok2,d=pcall(H.JSONDecode,H,raw);if ok2 and type(d)=="table"then if type(d.sessions)=="table"then scorchSessions=d.sessions;print("MarmotZ: loaded "..#scorchSessions.." scorch sessions")end;if type(d.best)=="number"then bestSH=d.best end end end end
-- v5.0.5: автосейв каждые 5 минут: Q-таблица + скорч + конфиг (раньше Q-таблица вообще никогда не сохранялась — не было кода записи)
function sQF()if not writefile then return end;pcall(function()if fldHash then qTables[fldHash]=QT end;writefile("marmot_z_q.json",H:JSONEncode({version=Q_VERSION,qtable=QT}))end)end
function sPat()if not writefile then return end;pcall(function()writefile("marmot_z_pat.json",H:JSONEncode({actions=actLog}))end)end
function lPat()if not readfile then return end;local ok,raw=pcall(readfile,"marmot_z_pat.json");if ok and raw then local ok2,d=pcall(H.JSONDecode,H,raw);if ok2 and type(d)=="table"and type(d.actions)=="table"then actLog=d.actions;while #actLog>PAT_WINDOW do table.remove(actLog,1)end;print("MarmotZ: loaded "..#actLog.." pattern actions")end end end
-- v5.0.7: АНАЛИЗАТОР ПАТТЕРНОВ — статистика по actLog: топ действий по награде, лучшие/худшие связки A>B, награда в минуту
function analyzePat()
if #actLog==0 then return"Нет данных: actLog пуст — подожди пару минут фарма"end
local sA={};for i=1,#actLog do local e=actLog[i];local a2=tostring(e.a or"?");local s2=sA[a2];if not s2 then s2={n=0,sum=0}sA[a2]=s2 end;s2.n=s2.n+1;s2.sum=s2.sum+(tonumber(e.rw)or 0)end
local rows={};for a2,s2 in pairs(sA)do table.insert(rows,{a=a2,n=s2.n,avg=s2.sum/s2.n,sum=s2.sum})end
table.sort(rows,function(x,y)return x.sum>y.sum end)
local bi={};for i=1,#actLog-1 do local k2=tostring(actLog[i].a).." > "..tostring(actLog[i+1].a);local b=bi[k2];if not b then b={n=0,sum=0}bi[k2]=b end;b.n=b.n+1;b.sum=b.sum+(tonumber(actLog[i+1].rw)or 0)end
local brow={};for k2,b in pairs(bi)do if b.n>=3 then table.insert(brow,{k=k2,n=b.n,avg=b.sum/b.n})end end
table.sort(brow,function(x,y)return x.avg>y.avg end)
local t0p=tonumber(actLog[1].t)or 0;local t1p=tonumber(actLog[#actLog].t)or 0;local durM=math.max(0.1,(t1p-t0p)/60)
local totRw=0;for i=1,#actLog do totRw=totRw+(tonumber(actLog[i].rw)or 0)end
local out={string.format("=== ПАТТЕРНЫ: %d действий | %.1f мин | награда %.0f (%.1f/мин) ===",#actLog,durM,totRw,totRw/durM)}
table.insert(out,"— ТОП действий по сумме награды:")
for i=1,math.min(PAT_TOP,#rows)do local rr=rows[i];table.insert(out,string.format("%2d. %s  n=%d  avg=%.1f  sum=%.0f",i,rr.a,rr.n,rr.avg,rr.sum))end
table.insert(out,"— Лучшие связки A > B (n>=3):")
for i=1,math.min(5,#brow)do local rr=brow[i];table.insert(out,string.format("+ %s  n=%d  avg=%.1f",rr.k,rr.n,rr.avg))end
if #brow>5 then
table.insert(out,"— Худшие связки:")
for i=math.max(6,#brow-4),#brow do local rr=brow[i];table.insert(out,string.format("- %s  n=%d  avg=%.1f",rr.k,rr.n,rr.avg))end
end
return table.concat(out,"\n")
end
task.spawn(function()while true do task.wait(300)pcall(sQF);pcall(sSS);pcall(saveCfg);pcall(sPat)end end)
local function rQ()QT={};EP=0.1;st.tR=0;st.dc=0;scorchSessions={};bestSH=0;top10={};eligibility={};visitCount={};totalSteps=0 end
-- GUI
task.spawn(function()while true do task.wait(1);if cfg.ss_on then pcall(function()RS.Events.PlayerActivesCommand:FireServer({["Name"]="Super Smoothie"})end);task.wait(1200)end end end)
local sgV4=Instance.new("ScreenGui",G);sgV4.Name="MarmotZ_V4"
local frV4=Instance.new("Frame",sgV4);frV4.Size=UDim2.new(0,440,0,310);frV4.Position=UDim2.new(0,10,0,10)
frV4.BackgroundColor3=Color3.fromRGB(20,20,30);frV4.BorderSizePixel=0;frV4.Active=true;frV4.Draggable=true;Instance.new("UICorner",frV4).CornerRadius=UDim.new(0,8)
local titleV4=Instance.new("TextLabel",frV4);titleV4.Size=UDim2.new(1,0,0,28);titleV4.BackgroundTransparency=1;titleV4.Position=UDim2.new(0,0,0,2)
titleV4.Text="  Marmot Z v5.2.5";titleV4.TextColor3=Color3.fromRGB(150,200,255);titleV4.Font=Enum.Font.GothamBold;titleV4.TextSize=15;titleV4.TextXAlignment=Enum.TextXAlignment.Left
local sideBar=Instance.new("Frame",frV4);sideBar.Size=UDim2.new(0,110,1,-34);sideBar.Position=UDim2.new(0,0,0,32);sideBar.BackgroundColor3=Color3.fromRGB(15,15,22);sideBar.BorderSizePixel=0;Instance.new("UICorner",sideBar).CornerRadius=UDim.new(0,6)
local tMain=Instance.new("Frame",frV4);tMain.Size=UDim2.new(1,-120,1,-40);tMain.Position=UDim2.new(0,115,0,35);tMain.BackgroundTransparency=1;tMain.Visible=true
local tBoost=Instance.new("Frame",frV4);tBoost.Size=UDim2.new(1,-120,1,-40);tBoost.Position=UDim2.new(0,115,0,35);tBoost.BackgroundTransparency=1;tBoost.Visible=false
local tSet=Instance.new("Frame",frV4);tSet.Size=UDim2.new(1,-120,1,-40);tSet.Position=UDim2.new(0,115,0,35);tSet.BackgroundTransparency=1;tSet.Visible=false
local tAuto=Instance.new("Frame",frV4);tAuto.Size=UDim2.new(1,-120,1,-40);tAuto.Position=UDim2.new(0,115,0,35);tAuto.BackgroundTransparency=1;tAuto.Visible=false
local tFarm=Instance.new("Frame",frV4);tFarm.Size=UDim2.new(1,-120,1,-40);tFarm.Position=UDim2.new(0,115,0,35);tFarm.BackgroundTransparency=1;tFarm.Visible=false
local tPlant=Instance.new("Frame",frV4);tPlant.Size=UDim2.new(1,-120,1,-40);tPlant.Position=UDim2.new(0,115,0,35);tPlant.BackgroundTransparency=1;tPlant.Visible=false
tPat=Instance.new("Frame",frV4);tPat.Size=UDim2.new(1,-120,1,-40);tPat.Position=UDim2.new(0,115,0,35);tPat.BackgroundTransparency=1;tPat.Visible=false -- v5.0.7: вкладка Patterns (глобал — лимит локалов)
local selectedTab=nil
local function selectTab(btn,panel)if selectedTab then selectedTab.BackgroundColor3=Color3.fromRGB(30,30,45)end;btn.BackgroundColor3=Color3.fromRGB(55,55,75);selectedTab=btn;for _,p in ipairs({tMain,tBoost,tSet,tAuto,tFarm,tPlant,tPat})do p.Visible=(p==panel)end end
local function mkSideBtn(y,name,panel)local b=Instance.new("TextButton",sideBar);b.Size=UDim2.new(1,-8,0,32);b.Position=UDim2.new(0,4,0,y);b.Text="  "..name;b.BackgroundColor3=Color3.fromRGB(30,30,45);b.TextColor3=Color3.fromRGB(200,200,200);b.Font=Enum.Font.GothamSemibold;b.TextSize=11;b.TextXAlignment=Enum.TextXAlignment.Left;Instance.new("UICorner",b).CornerRadius=UDim.new(0,4);b.MouseButton1Click:Connect(function()selectTab(b,panel)end);return b end
local btnStats=mkSideBtn(2,"Stats",tMain);local btnAuto=mkSideBtn(38,"Autofarm",tAuto);local btnBoost=mkSideBtn(74,"Boosts",tBoost);local btnFarm=mkSideBtn(110,"Farm pattern",tFarm);local btnPlant=mkSideBtn(146,"Planters",tPlant);local btnSet=mkSideBtn(182,"Settings",tSet);btnPat=mkSideBtn(218,"Patterns",tPat);selectTab(btnStats,tMain)
-- Stats
local function mkStat(y,color)local l=Instance.new("TextLabel",tMain);l.Size=UDim2.new(1,0,0,17);l.Position=UDim2.new(0,4,0,y);l.BackgroundTransparency=1;l.Font=Enum.Font.Gotham;l.TextSize=11;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextColor3=color or Color3.new(1,1,1);return l end
local lb=mkStat(0);local hl=mkStat(30,Color3.fromRGB(150,255,150));local tmLbl=mkStat(44,Color3.fromRGB(255,220,120));tmLbl.Text="Time: --:--"-- v5.0: время компьютера в статах
-- v4.8: строка Scorch кликабельна — открывает топ-24 скорчей по мёду
local scLab=Instance.new("TextButton",tMain);scLab.Size=UDim2.new(1,-8,0,17);scLab.Position=UDim2.new(0,4,0,60);scLab.BackgroundTransparency=1;scLab.Font=Enum.Font.Gotham;scLab.TextSize=11;scLab.TextXAlignment=Enum.TextXAlignment.Left;scLab.TextColor3=Color3.fromRGB(255,180,80);scLab.Text="Scorch: --"
local scScroll=Instance.new("ScrollingFrame",frV4);scScroll.Size=UDim2.new(1,-120,1,-40);scScroll.Position=UDim2.new(0,115,0,35);scScroll.BackgroundColor3=Color3.fromRGB(15,15,22);scScroll.BorderSizePixel=0;scScroll.Visible=false;scScroll.ScrollBarThickness=4;scScroll.ZIndex=5;Instance.new("UICorner",scScroll).CornerRadius=UDim.new(0,6)
local scList=Instance.new("UIListLayout",scScroll);scList.SortOrder=Enum.SortOrder.LayoutOrder;scList.Padding=UDim.new(0,2)
local scClose=Instance.new("TextButton",scScroll);scClose.Size=UDim2.new(1,-8,0,18);scClose.BackgroundTransparency=1;scClose.Font=Enum.Font.GothamBold;scClose.TextSize=11;scClose.TextXAlignment=Enum.TextXAlignment.Left;scClose.TextColor3=Color3.fromRGB(255,180,80);scClose.Text="< Top-24 Scorch (клик — закрыть)";scClose.LayoutOrder=0;scClose.ZIndex=6;scClose.MouseButton1Click:Connect(function()scScroll.Visible=false end)
local function refreshScTop()
for _,c in ipairs(scScroll:GetChildren())do if c:IsA("TextLabel")then c:Destroy()end end
local tmp={};for i=1,#scorchSessions do table.insert(tmp,scorchSessions[i])end
table.sort(tmp,function(a,b)return a.honeyGained>b.honeyGained end)
local cnt=math.min(24,#tmp)
for i=1,cnt do local s=tmp[i]
local row=Instance.new("TextLabel",scScroll);row.Size=UDim2.new(1,-8,0,16);row.BackgroundTransparency=1;row.Font=Enum.Font.Code;row.TextSize=10;row.TextXAlignment=Enum.TextXAlignment.Left;row.LayoutOrder=i;row.ZIndex=6;row.TextTruncate=Enum.TextTruncate.AtEnd
row.TextColor3=(i<=3)and Color3.fromRGB(255,215,80)or Color3.fromRGB(200,200,200)
-- v5.1.4: как в Patterns — по каждому скорчу видно, ЧТО бот делал (топ-3 действия из s.actions) и сколько мёда сделано
local acts=""
if type(s.actions)=="table"and #s.actions>0 then
local cA={};for j=1,#s.actions do local a3=tostring(s.actions[j].a or"?");cA[a3]=(cA[a3]or 0)+1 end
local ar={};for a3,n3 in pairs(cA)do table.insert(ar,{a=a3,n=n3})end
table.sort(ar,function(x,y)return x.n>y.n end)
local pieces={};for j=1,math.min(3,#ar)do table.insert(pieces,(ar[j].a:gsub("^go_","")).." x"..ar[j].n)end
acts=" | "..table.concat(pieces,", ")
end
row.Text=string.format("#%d +%s %.1fm SSx%d%s",i,s.honeyGainedFmt or fmtH(s.honeyGained),s.durationMin or 0,s.ssCombo or 0,acts)
end
if cnt==0 then local row=Instance.new("TextLabel",scScroll);row.Size=UDim2.new(1,-8,0,16);row.BackgroundTransparency=1;row.Font=Enum.Font.Code;row.TextSize=11;row.TextXAlignment=Enum.TextXAlignment.Left;row.TextColor3=Color3.fromRGB(150,150,150);row.Text="No scorch sessions yet";row.LayoutOrder=1;row.ZIndex=6 end
scScroll.CanvasSize=UDim2.new(0,0,0,math.max(cnt,1)*18+30)
end
scLab.MouseButton1Click:Connect(function()scScroll.Visible=not scScroll.Visible;if scScroll.Visible then refreshScTop()end end)
local sb=Instance.new("TextButton",tMain);sb.Size=UDim2.new(1,-8,0,30);sb.Position=UDim2.new(0,4,1,-30);sb.BackgroundColor3=Color3.fromRGB(180,40,40);sb.Text="STOP";sb.TextColor3=Color3.new(1,1,1);sb.Font=Enum.Font.GothamBold;sb.TextSize=13;Instance.new("UICorner",sb).CornerRadius=UDim.new(0,5);sb.MouseButton1Click:Connect(function()ENABLED=not ENABLED;sb.Text=ENABLED and"STOP"or"RESUME";sb.BackgroundColor3=ENABLED and Color3.fromRGB(180,40,40)or Color3.fromRGB(40,180,40)end)
-- Boosts
local bTitle=Instance.new("TextLabel",tBoost);bTitle.Size=UDim2.new(1,0,0,22);bTitle.Position=UDim2.new(0,4,0,2);bTitle.BackgroundTransparency=1;bTitle.Text="Auto Use Materials";bTitle.TextColor3=Color3.new(1,1,1);bTitle.Font=Enum.Font.GothamBold;bTitle.TextSize=13;bTitle.TextXAlignment=Enum.TextXAlignment.Left
local function mkToggle(y,name,key)local b=Instance.new("TextButton",tBoost);b.Size=UDim2.new(1,-8,0,30);b.Position=UDim2.new(0,4,0,y);b.BackgroundColor3=Color3.fromRGB(35,35,50);b.TextColor3=Color3.fromRGB(200,200,200);b.Font=Enum.Font.Gotham;b.TextSize=12;b.TextXAlignment=Enum.TextXAlignment.Left;Instance.new("UICorner",b).CornerRadius=UDim.new(0,4);b.MouseButton1Click:Connect(function()cfg[key]=not cfg[key];b.Text=(cfg[key]and"[X] "or"[ ] ")..name;b.TextColor3=cfg[key]and Color3.fromRGB(100,255,100)or Color3.fromRGB(200,200,200);saveCfg()end);b.Text=(cfg[key]and"[X] "or"[ ] ")..name;b.TextColor3=cfg[key]and Color3.fromRGB(100,255,100)or Color3.fromRGB(200,200,200);return b end
local ssBtn=mkToggle(28,"Super Smoothie (20m)","ss_on")
-- Autofarm
local faTitle=Instance.new("TextLabel",tAuto);faTitle.Size=UDim2.new(1,0,0,22);faTitle.Position=UDim2.new(0,4,0,2);faTitle.BackgroundTransparency=1;faTitle.Text="Autofarm Limits (0=unlimited)";faTitle.TextColor3=Color3.new(1,1,1);faTitle.Font=Enum.Font.GothamBold;faTitle.TextSize=12;faTitle.TextXAlignment=Enum.TextXAlignment.Left
local function mkLimit(y,name,onKey,limKey,maxVal)local row=Instance.new("Frame",tAuto);row.Size=UDim2.new(1,-4,0,30);row.Position=UDim2.new(0,4,0,y);row.BackgroundTransparency=1
local tg=Instance.new("TextButton",row);tg.Size=UDim2.new(0,165,1,0);tg.BackgroundColor3=Color3.fromRGB(35,35,50);tg.TextColor3=Color3.fromRGB(200,200,200);tg.Font=Enum.Font.Gotham;tg.TextSize=11;tg.TextXAlignment=Enum.TextXAlignment.Left;Instance.new("UICorner",tg).CornerRadius=UDim.new(0,4)
tg.Text=(cfg[onKey]and"[X] "or"[ ] ")..name;tg.TextColor3=cfg[onKey]and Color3.fromRGB(100,255,100)or Color3.fromRGB(200,200,200);tg.MouseButton1Click:Connect(function()cfg[onKey]=not cfg[onKey];tg.Text=(cfg[onKey]and"[X] "or"[ ] ")..name;tg.TextColor3=cfg[onKey]and Color3.fromRGB(100,255,100)or Color3.fromRGB(200,200,200);saveCfg()end)
local bx=Instance.new("TextBox",row);bx.Size=UDim2.new(0,55,1,0);bx.Position=UDim2.new(1,-60,0,0);bx.BackgroundColor3=Color3.fromRGB(35,35,45);bx.TextColor3=Color3.new(1,1,1);bx.Text=tostring(cfg[limKey]);bx.Font=Enum.Font.Code;bx.TextSize=12;bx.TextXAlignment=Enum.TextXAlignment.Center;Instance.new("UICorner",bx).CornerRadius=UDim.new(0,4)
bx.FocusLost:Connect(function()local n=tonumber(bx.Text);if n and n>=0 and n<=(maxVal or 999)then cfg[limKey]=n;bx.Text=tostring(n)else bx.Text=tostring(cfg[limKey])end;saveCfg()end);return tg,bx end
local cocoTg,cocoBx=mkLimit(28,"Farm Coconuts","coco_on","coco_lim",11)
local shwTg,shwBx=mkLimit(68,"Farm Showers","shower_on","shower_lim",15)
local prpTg,prpBx=mkLimit(108,"Farm Precise Marks","purple_on","purple_lim",10)
-- Settings
local sTitle=Instance.new("TextLabel",tSet);sTitle.Size=UDim2.new(1,0,0,22);sTitle.Position=UDim2.new(0,4,0,2);sTitle.BackgroundTransparency=1;sTitle.Text="Speedhack";sTitle.TextColor3=Color3.new(1,1,1);sTitle.Font=Enum.Font.GothamBold;sTitle.TextSize=13;sTitle.TextXAlignment=Enum.TextXAlignment.Left
local function mkSpd(y,name,key)local l=Instance.new("TextLabel",tSet);l.Size=UDim2.new(0,100,0,22);l.Position=UDim2.new(0,4,0,y);l.BackgroundTransparency=1;l.Text=name;l.TextColor3=Color3.new(1,1,1);l.Font=Enum.Font.Gotham;l.TextSize=11;l.TextXAlignment=Enum.TextXAlignment.Left
local bx=Instance.new("TextBox",tSet);bx.Size=UDim2.new(0,55,0,22);bx.Position=UDim2.new(0,108,0,y);bx.BackgroundColor3=Color3.fromRGB(35,35,45);bx.TextColor3=Color3.new(1,1,1);bx.Text=tostring(cfg[key]);bx.Font=Enum.Font.Code;bx.TextSize=12;Instance.new("UICorner",bx).CornerRadius=UDim.new(0,4)
bx.FocusLost:Connect(function()local n=tonumber(bx.Text);if n then cfg[key]=n;SB.X10=cfg.sp_x10;SB.NABOR=cfg.sp_nab;SB.REFRESH=cfg.sp_ref else bx.Text=tostring(cfg[key])end;saveCfg()end)end
mkSpd(30,"Speed X10","sp_x10");mkSpd(58,"Speed NABOR","sp_nab");mkSpd(86,"Speed REFRESH","sp_ref")
-- v5.1.4: способ перемещения для плантеров/фарм-паттерна: Teleport (мгновенно) или Tween (полёт), + настраиваемая скорость твина (студов/с)
mvTitle=Instance.new("TextLabel",tSet);mvTitle.Size=UDim2.new(1,0,0,22);mvTitle.Position=UDim2.new(0,4,0,118);mvTitle.BackgroundTransparency=1;mvTitle.Text="Movement (planters / farm pattern)";mvTitle.TextColor3=Color3.new(1,1,1);mvTitle.Font=Enum.Font.GothamBold;mvTitle.TextSize=13;mvTitle.TextXAlignment=Enum.TextXAlignment.Left
mvBtn=Instance.new("TextButton",tSet);mvBtn.Size=UDim2.new(0,159,0,26);mvBtn.Position=UDim2.new(0,4,0,144);mvBtn.BackgroundColor3=Color3.fromRGB(35,35,50);mvBtn.Font=Enum.Font.Gotham;mvBtn.TextSize=12;mvBtn.TextXAlignment=Enum.TextXAlignment.Left;Instance.new("UICorner",mvBtn).CornerRadius=UDim.new(0,4)
function updMvBtn()mvBtn.Text=(cfg.mv_mode=="tween")and"  Mode: Tween (fly)"or"  Mode: Teleport";mvBtn.TextColor3=(cfg.mv_mode=="tween")and Color3.fromRGB(120,200,255)or Color3.fromRGB(100,255,100)end
mvBtn.MouseButton1Click:Connect(function()cfg.mv_mode=(cfg.mv_mode=="tween")and"tp"or"tween";updMvBtn();saveCfg()end);updMvBtn()
twLbl=Instance.new("TextLabel",tSet);twLbl.Size=UDim2.new(0,100,0,22);twLbl.Position=UDim2.new(0,4,0,176);twLbl.BackgroundTransparency=1;twLbl.Text="Tween speed";twLbl.TextColor3=Color3.new(1,1,1);twLbl.Font=Enum.Font.Gotham;twLbl.TextSize=11;twLbl.TextXAlignment=Enum.TextXAlignment.Left
twBx=Instance.new("TextBox",tSet);twBx.Size=UDim2.new(0,55,0,22);twBx.Position=UDim2.new(0,108,0,176);twBx.BackgroundColor3=Color3.fromRGB(35,35,45);twBx.TextColor3=Color3.new(1,1,1);twBx.Text=tostring(cfg.tw_speed);twBx.Font=Enum.Font.Code;twBx.TextSize=12;Instance.new("UICorner",twBx).CornerRadius=UDim.new(0,4)
twBx.FocusLost:Connect(function()local n=tonumber(twBx.Text);if n and n>=10 and n<=1000 then cfg.tw_speed=math.floor(n)end;twBx.Text=tostring(cfg.tw_speed);saveCfg()end)
-- v5.2.6: кнопка AC Test убрана из настроек (режим удалён, больше не нужен)

-- ===== FARM PATTERN TAB (v5.0) =====
hchTitle=Instance.new("TextLabel",tFarm);hchTitle.Size=UDim2.new(1,0,0,22);hchTitle.Position=UDim2.new(0,4,0,2);hchTitle.BackgroundTransparency=1;hchTitle.Text="Farm pattern";hchTitle.TextColor3=Color3.new(1,1,1);hchTitle.Font=Enum.Font.GothamBold;hchTitle.TextSize=13;hchTitle.TextXAlignment=Enum.TextXAlignment.Left
hchBtn=Instance.new("TextButton",tFarm);hchBtn.Size=UDim2.new(1,-8,0,30);hchBtn.Position=UDim2.new(0,4,0,28);hchBtn.BackgroundColor3=Color3.fromRGB(35,35,50);hchBtn.Font=Enum.Font.Gotham;hchBtn.TextSize=12;hchBtn.TextXAlignment=Enum.TextXAlignment.Left;Instance.new("UICorner",hchBtn).CornerRadius=UDim.new(0,4)
function updHch()hchBtn.Text=(cfg.hachapuri and"[X] "or"[ ] ").."Hachapuri method";hchBtn.TextColor3=cfg.hachapuri and Color3.fromRGB(100,255,100)or Color3.fromRGB(200,200,200)end
hchBtn.MouseButton1Click:Connect(function()cfg.hachapuri=not cfg.hachapuri;updHch();saveCfg()end);updHch()
hchStat=Instance.new("TextLabel",tFarm);hchStat.Size=UDim2.new(1,-8,0,150);hchStat.Position=UDim2.new(0,4,0,64);hchStat.BackgroundTransparency=1;hchStat.Font=Enum.Font.Code;hchStat.TextSize=10;hchStat.TextXAlignment=Enum.TextXAlignment.Left;hchStat.TextYAlignment=Enum.TextYAlignment.Top;hchStat.TextColor3=Color3.fromRGB(200,200,200);hchStat.TextWrapped=true
hchStat.Text=":43 planters (auto plant)\n:50 pollen dump (canvas)\n:58 Tickets + TP FP14-11-21, x10, purple CH\n:00 Mondo Chick dodge 11 studs\nthen: collect token, sprinkler FP18-10-13, smoothie x2"

-- ===== PLANTERS TAB (v5.0) =====
NCOL={inv=Color3.fromRGB(255,80,80),ref=Color3.fromRGB(90,255,110),sat=Color3.fromRGB(255,255,255),mot=Color3.fromRGB(190,110,255),comf=Color3.fromRGB(90,150,255)}
NNAME={inv="farm inv. nectar",ref="farm ref. nectar",sat="farm sat. nectar",mot="farm mot. nectar",comf="farm comf. nectar"}
NORD={"inv","ref","sat","mot","comf"}
plBtn=Instance.new("TextButton",tPlant);plBtn.Size=UDim2.new(1,-52,0,26);plBtn.Position=UDim2.new(0,4,0,2);plBtn.BackgroundColor3=Color3.fromRGB(35,35,50);plBtn.Font=Enum.Font.Gotham;plBtn.TextSize=12;plBtn.TextXAlignment=Enum.TextXAlignment.Left;Instance.new("UICorner",plBtn).CornerRadius=UDim.new(0,4)
-- v5.1: минута цикла плантеров настраивается (поле справа от тумблера, 0-59)
plMinBx=Instance.new("TextBox",tPlant);plMinBx.Size=UDim2.new(0,40,0,26);plMinBx.Position=UDim2.new(1,-46,0,2);plMinBx.BackgroundColor3=Color3.fromRGB(35,35,45);plMinBx.TextColor3=Color3.new(1,1,1);plMinBx.Text=tostring(cfg.pl_min or 43);plMinBx.Font=Enum.Font.Code;plMinBx.TextSize=12;Instance.new("UICorner",plMinBx).CornerRadius=UDim.new(0,4)
function updPlBtn()plBtn.Text=(cfg.pl_auto and"[X] "or"[ ] ")..string.format("auto plant planters (:%02d)",tonumber(cfg.pl_min)or 43);plBtn.TextColor3=cfg.pl_auto and Color3.fromRGB(100,255,100)or Color3.fromRGB(200,200,200)end
plMinBx.FocusLost:Connect(function()local n2=tonumber(plMinBx.Text);if n2 and n2>=0 and n2<=59 then cfg.pl_min=math.floor(n2)end;plMinBx.Text=tostring(cfg.pl_min or 43);updPlBtn();saveCfg()end)
plBtn.MouseButton1Click:Connect(function()cfg.pl_auto=not cfg.pl_auto;updPlBtn();saveCfg()end);updPlBtn()
plRows={}
for i,k in ipairs(NORD)do
local y=32+(i-1)*42
local tg=Instance.new("TextButton",tPlant);tg.Size=UDim2.new(0,158,0,20);tg.Position=UDim2.new(0,4,0,y);tg.BackgroundColor3=Color3.fromRGB(35,35,50);tg.Font=Enum.Font.Gotham;tg.TextSize=11;tg.TextXAlignment=Enum.TextXAlignment.Left;Instance.new("UICorner",tg).CornerRadius=UDim.new(0,4)
local bx=Instance.new("TextBox",tPlant);bx.Size=UDim2.new(0,34,0,20);bx.Position=UDim2.new(0,166,0,y);bx.BackgroundColor3=Color3.fromRGB(35,35,45);bx.TextColor3=Color3.new(1,1,1);bx.Text=tostring(cfg["pl_"..k.."_h"]);bx.Font=Enum.Font.Code;bx.TextSize=11;Instance.new("UICorner",bx).CornerRadius=UDim.new(0,4)
local remL=Instance.new("TextLabel",tPlant);remL.Size=UDim2.new(0,90,0,20);remL.Position=UDim2.new(0,206,0,y);remL.BackgroundTransparency=1;remL.Font=Enum.Font.Code;remL.TextSize=10;remL.TextXAlignment=Enum.TextXAlignment.Left;remL.TextColor3=NCOL[k];remL.Text="0h 00m"
-- v5.0.3: прогресс-бар нектара: цветная полоска от 0 до pl_*_h часов
local barBg=Instance.new("Frame",tPlant);barBg.Size=UDim2.new(0,290,0,6);barBg.Position=UDim2.new(0,4,0,y+22);barBg.BackgroundColor3=Color3.fromRGB(25,25,35);barBg.BorderSizePixel=0;Instance.new("UICorner",barBg).CornerRadius=UDim.new(0,3)
local barFill=Instance.new("Frame",barBg);barFill.Size=UDim2.new(0,0,1,0);barFill.BackgroundColor3=NCOL[k];barFill.BorderSizePixel=0;Instance.new("UICorner",barFill).CornerRadius=UDim.new(0,3)
local function updTg()tg.Text=(cfg["pl_"..k]and"[X] "or"[ ] ")..NNAME[k];tg.TextColor3=cfg["pl_"..k]and NCOL[k]or Color3.fromRGB(140,140,140)end
tg.MouseButton1Click:Connect(function()cfg["pl_"..k]=not cfg["pl_"..k];updTg();saveCfg()end);updTg()
bx.FocusLost:Connect(function()local n2=tonumber(bx.Text);if n2 and n2>=1 and n2<=22 then cfg["pl_"..k.."_h"]=math.floor(n2)end;bx.Text=tostring(cfg["pl_"..k.."_h"]);saveCfg()end)
plRows[k]={remL=remL,bar=barFill,k=k}
end

-- ===== PATTERNS TAB (v5.0.7): анализатор паттернов =====
patRefBtn=Instance.new("TextButton",tPat);patRefBtn.Size=UDim2.new(0,90,0,26);patRefBtn.Position=UDim2.new(0,4,0,2);patRefBtn.BackgroundColor3=Color3.fromRGB(35,35,50);patRefBtn.Text="Refresh";patRefBtn.TextColor3=Color3.fromRGB(100,255,100);patRefBtn.Font=Enum.Font.Gotham;patRefBtn.TextSize=11;Instance.new("UICorner",patRefBtn).CornerRadius=UDim.new(0,4)
patCpyBtn=Instance.new("TextButton",tPat);patCpyBtn.Size=UDim2.new(0,90,0,26);patCpyBtn.Position=UDim2.new(0,100,0,2);patCpyBtn.BackgroundColor3=Color3.fromRGB(35,35,50);patCpyBtn.Text="Copy";patCpyBtn.TextColor3=Color3.fromRGB(200,200,200);patCpyBtn.Font=Enum.Font.Gotham;patCpyBtn.TextSize=11;Instance.new("UICorner",patCpyBtn).CornerRadius=UDim.new(0,4)
patScroll=Instance.new("ScrollingFrame",tPat);patScroll.Size=UDim2.new(1,-8,1,-36);patScroll.Position=UDim2.new(0,4,0,32);patScroll.BackgroundColor3=Color3.fromRGB(15,15,22);patScroll.BorderSizePixel=0;patScroll.ScrollBarThickness=4;patScroll.CanvasSize=UDim2.new(0,0,0,860);Instance.new("UICorner",patScroll).CornerRadius=UDim.new(0,6)
patLbl=Instance.new("TextLabel",patScroll);patLbl.Size=UDim2.new(1,-8,0,840);patLbl.Position=UDim2.new(0,4,0,2);patLbl.BackgroundTransparency=1;patLbl.Font=Enum.Font.Code;patLbl.TextSize=10;patLbl.TextXAlignment=Enum.TextXAlignment.Left;patLbl.TextYAlignment=Enum.TextYAlignment.Top;patLbl.TextColor3=Color3.fromRGB(200,220,255);patLbl.TextWrapped=true;patLbl.Text="Нажми Refresh — отчёт по actLog появится тут"
patRefBtn.MouseButton1Click:Connect(function()local okA,resA=pcall(analyzePat);patLbl.Text=okA and resA or("Ошибка анализа: "..tostring(resA))end)
patCpyBtn.MouseButton1Click:Connect(function()pcall(setclipboard,patLbl.Text)end)
-- v5.1.1: кнопка Reset — полный сброс паттерн-лога: чистит actLog и lastPatAct, перезаписывает marmot_z_pat.json пустым через sPat()
patRstBtn=Instance.new("TextButton",tPat);patRstBtn.Size=UDim2.new(0,90,0,26);patRstBtn.Position=UDim2.new(0,196,0,2);patRstBtn.BackgroundColor3=Color3.fromRGB(50,30,30);patRstBtn.Text="Reset";patRstBtn.TextColor3=Color3.fromRGB(255,120,120);patRstBtn.Font=Enum.Font.Gotham;patRstBtn.TextSize=11;Instance.new("UICorner",patRstBtn).CornerRadius=UDim.new(0,4)
patRstBtn.MouseButton1Click:Connect(function()actLog={};lastPatAct="";epT0=totalSteps;pcall(sPat);patLbl.Text="Лог паттернов сброшен (actLog=0, marmot_z_pat.json перезаписан). Нажми Refresh после пары минут фарма";print("MarmotZ: pattern log reset")end)

-- ===== PLANTER ENGINE (v5.1): карта нектар->поля ПЕРЕПРОВЕРЕНА по вики BSS =====
-- inv = Clover/Cactus/Mountain Top/Pepper Patch; mot = Mushroom/Spider/Stump/Rose; ref = Blue Flower/Strawberry/Coconut; comf = Dandelion/Bamboo/Pine Tree; sat = Sunflower/Pineapple/Pumpkin
-- Heat-Treated (+40% inv+mot, +50% рост на красных полях): inv -> Cactus/Clover/Mountain Top, mot -> Rose Field (красные цветки, растёт быстрее). v5.1.2: Pepper Patch ЗАПРЕЩЁН для плантеров — там фармим; ЦЕНТР (Flowers.FP18-10-14) остаётся точкой ТП после расстановки
-- Hydroponic (+40% comf+ref, +50% рост на синих полях): ref -> Coconut/Blue Flower, comf -> Bamboo/Pine Tree. На кактус ему нельзя — кактус это inv-поле, для inv там Planter Of Plenty/Heat-Treated
-- The Planter Of Plenty (+50% ВСЕ нектары, +50% рост в Pepper/Stump/Coconut/Mountain Top): inv -> Mountain Top, mot -> Stump, ref -> Coconut
-- ФИКС: планер назывался "Head-Treated Planter" — такого предмета нет, FireServer уходил в пустоту; правильно "Heat-Treated Planter"
NFIELDS={inv={"Mountain Top Field","Cactus Field","Clover Field"},ref={"Coconut Field","Blue Flower Field","Strawberry Field"},sat={"Pumpkin Patch","Pineapple Patch","Sunflower Field"},mot={"Rose Field","Stump Field","Mushroom Field","Spider Field"},comf={"Pine Tree Forest","Bamboo Field","Dandelion Field"}}
NPREF={inv={"Heat-Treated Planter","The Planter Of Plenty","Hydroponic Planter"},ref={"Hydroponic Planter","The Planter Of Plenty","Petal Planter"},sat={"Petal Planter","The Planter Of Plenty","Heat-Treated Planter"},mot={"Heat-Treated Planter","The Planter Of Plenty","Petal Planter"},comf={"Petal Planter","Hydroponic Planter","The Planter Of Plenty"}}
POP_FIELD={inv="Mountain Top Field",mot="Stump Field",ref="Coconut Field"}
PEPPER_FP="FP18-10-14"
function getFieldPos(nm)
if nm=="Pepper Patch"then local fls=W:FindFirstChild("Flowers");local fp=fls and fls:FindFirstChild(PEPPER_FP);if fp then return fp.Position end end
local fz=W:FindFirstChild("FlowerZones");if fz then local z=fz:FindFirstChild(nm);if z and z:IsA("BasePart")then return z.Position end end
return nil end
plHist={idx={},used={},last={}}
-- v5.1.4: история плантеров живёт в marmot_z_data.json вместе с конфигом (загружена в loadCfg как PLHIST_LOADED); старый marmot_z_planters.json — фолбэк для миграции
if PLHIST_LOADED then plHist=PLHIST_LOADED;plHist.idx=plHist.idx or{};plHist.used=plHist.used or{};plHist.last=plHist.last or{}
elseif readfile then local ok,raw=pcall(readfile,"marmot_z_planters.json");if ok and raw then local ok2,d=pcall(H.JSONDecode,H,raw);if ok2 and type(d)=="table"then plHist=d;plHist.idx=plHist.idx or{};plHist.used=plHist.used or{};plHist.last=plHist.last or{}end end end
function savePlHist()saveCfg()end
-- v5.1.6: ДИАГНОСТИКА КИКА АНТИЧИТА: кольцевой лог (ТП, скорость, действие) пишется в marmot_z_kick.json; при дисконнекте GuiService.ErrorMessageChanged дописывает текст кика — последние строки файла покажут, что бот делал прямо перед киком
kickLog={};kickSnp={};kickFrozen=false;lastKPos=nil
local function flushK()if not writefile then return end;pcall(function()local m={};for _,v in ipairs(kickLog)do m[#m+1]=v end;for _,v in ipairs(kickSnp)do m[#m+1]=v end;table.sort(m);writefile("marmot_z_kick.json",H:JSONEncode(m))end)end
function klog(ev)if kickFrozen then return end;table.insert(kickLog,string.format("[%s] %s",os.date("%H:%M:%S"),tostring(ev)));while #kickLog>150 do table.remove(kickLog,1)end;flushK()end
function ksnap(ev)if kickFrozen then return end;table.insert(kickSnp,string.format("[%s] %s",os.date("%H:%M:%S"),tostring(ev)));while #kickSnp>40 do table.remove(kickSnp,1)end;flushK()end
-- v5.1.9: события (TP/KICK/AC) и 5с-снапшоты теперь в РАЗНЫХ буферах (kickLog<=150 событий + kickSnp<=40 снапшотов), объединяются при записи — снапшоты БОЛЬШЕ НЕ вытесняют TP-строки (виден последний телепорт перед киком)
-- v5.1.7: после DISCONNECT/KICK лог ЗАМОРАЖИВАЕТСЯ (kickFrozen) — снапшоты после кика больше не затирают кольцевой буфер, и картина ДО кика сохраняется целиком
pcall(function()game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg)if msg and msg~=""then klog("DISCONNECT/KICK: "..tostring(msg));kickFrozen=true end end)end)-- v5.2.4: АВТО-РЕДЖОЙН УБРАН по просьбе — хук ТОЛЬКО пишет причину дисконнекта в кик-лог и замораживает буфер (нужно для ручного сбора логов при тесте); телепорт/перезапуск и REJOIN_URL/cfg.rejoin_on больше не используются
task.spawn(function()while true do task.wait(15)pcall(function()local rK=h();local hmK=hm()
local dpos=0;if rK and lastKPos then dpos=(rK.Position-lastKPos).Magnitude end;if rK then lastKPos=rK.Position end
local _tcd=tcFires-(_tcPrev or 0);local _pabd=pabCalls-(_pabPrev or 0);_tcPrev=tcFires;_pabPrev=pabCalls-- v5.2.4: дельта ремоутов за 15с окно -> tc/сек и pab/мин
local _hnow=getHoney();local _hd=_hnow-(_hPrev or _hnow);_hPrev=_hnow;local _tkd=st.tk-(_tkPrev or 0);_tkPrev=st.tk-- v5.2.5: дельта мёда и собранных токенов за окно (лейн "токены/прецайсы": проверяем корреляцию кика с гейн-рейтом/сбором/Precision)
ksnap(string.format("snap tL=%s mode=%s ac=%s ws=%.0f vel=%.0f dpos=%.0f(%.0f/s) xf=%d sc=%d tc=%.1f/s pab=%d/min hd=%s/min col=%d dup=%d pv=%.0f ps=%d",tostring(tL),tostring(cfg.mv_mode),cfg.ac_test and"1"or"0",hmK and hmK.WalkSpeed or 0,rK and rK.AssemblyLinearVelocity.Magnitude or 0,dpos,dpos/15,xfP or 0,scP or 0,_tcd/15,_pabd*4,fmtH(_hd*4),_tkd,dupCnt,prec.val or 0,prec.st or 0))end)end end)
TWS=game:GetService("TweenService")
-- v5.1.4: два способа перемещения (вкладка Settings): Teleport — мгновенный CFrame; Tween — плавный полёт TweenService со скоростью cfg.tw_speed студов/с (долететь до цветка, поставить плантер и улететь без ТП)
function tpTo(pos)local r=h();if not r then return false end
if not pos or pos~=pos or pos.Magnitude>100000 then if klog then klog("TP ABORT bad/NaN pos")end;return false end-- v5.1.9: защита от NaN/мусорной цели — ТП на исчезнувший токен/шовер = NaN CFrame = краш физики клиента = "Server error. Please rejoin."
if klog then klog(string.format("TP %.0f studs mode=%s",(r.Position-pos).Magnitude,tostring(cfg.mv_mode)))end -- v5.1.6: каждый телепорт фиксируется в кик-логе
if cfg.mv_mode=="tween"then
local target=CFrame.new(pos+Vector3.new(0,3,0))
local dist=(r.Position-target.Position).Magnitude
local spd=math.max(tonumber(cfg.tw_speed)or 150,10)
local dur=math.max(0.1,dist/spd)
acHold=os.clock()+dur+0.6-- v5.1.9: КЛЮЧЕВОЕ — на всё время твина ставим CFrame-двигатель AC на паузу, иначе ДВА писателя CFrame (твин + mover) дерутся каждый кадр -> флуд/битая матрица поворота -> дисконнект
local tw=TWS:Create(r,TweenInfo.new(dur,Enum.EasingStyle.Linear),{CFrame=target})
local done=false;tw.Completed:Connect(function()done=true end)
tw:Play()
local t0=os.clock()
while not done and os.clock()-t0<dur+2 do task.wait(0.05);if not h()then pcall(function()tw:Cancel()end);return false end end
r=h();if r then r.AssemblyLinearVelocity=ZERO;acHold=os.clock()+0.5;local _h=hm();if _h then _h:MoveTo(r.Position)end end
task.wait(0.1);return true
end
r.CFrame=CFrame.new(pos+Vector3.new(0,3,0));acHold=os.clock()+0.5;local _h2=hm();if _h2 then _h2:MoveTo(r.Position)end;local _t=os.clock();while os.clock()-_t<0.35 do r.AssemblyLinearVelocity=ZERO;R.Heartbeat:Wait()end;return true end-- v5.2.1: АНТИ-КИК — после ТП velocity прибивается к 0 КАЖДЫЙ кадр 0.35с (в логах всплески vel=21-23 на Shower TP/DupTk/Link = единственный момент утечки скорости под velocity-чек)
-- v5.1.6: сбор ВСЕХ стоящих плантеров: фильтр ActorID ослаблен (жёсткое условие Type/Pos/Growth отбрасывало ранее поставленные плантеры — собирался только 1) + второй проход через 2с добирает оставшееся
function collectPlanters()
if not rps then return end
local ev=RS:FindFirstChild("Events");local pmc=ev and ev:FindFirstChild("PlanterModelCollect");if not pmc then return end
local total=0
for pass=1,2 do
local ok,res=pcall(function()return rps:InvokeServer()end)
if ok and type(res)=="table"then
local ids={}
local function scanP(t,depth)if depth>8 or type(t)~="table"then return end
for k2,v in pairs(t)do
if type(v)=="table"then
local aid=rawget(v,"ActorID")or rawget(v,"ActorId")
if not aid and tostring(k2):lower():find("planter")then aid=rawget(v,"ID")end
if aid then ids[tonumber(aid)or aid]=true end
scanP(v,depth+1)
end
end end
scanP(res,0)
for aid in pairs(ids)do pcall(function()pmc:FireServer(aid)end);total=total+1;print("MarmotZ: collect planter ActorID="..tostring(aid).." (pass "..pass..")");task.wait(0.6)end
end
if pass==1 then task.wait(2)end
end
print("MarmotZ: planters collected, fired="..total)
end
function plantPlanters()
pcall(pAB)
local defs={}
for _,k in ipairs(NORD)do if cfg["pl_"..k]then local target=(cfg["pl_"..k.."_h"]or 22)*3600;local d=target-(nectarRem[k]or 0);if d>0 then table.insert(defs,{k=k,d=d})end end end
table.sort(defs,function(a,b)return a.d>b.d end)
if #defs==0 then return end
collectPlanters();task.wait(1)
-- v5.1: помним, куда ставили (plHist.used/plHist.last в marmot_z_data.json): каждый цикл — сбор, потом расстановка на поля, куда ЕЩЁ не ставили; когда все поля нектара пройдены — цепочка начинается заново. PoP идёт на своё быстрое поле, если оно ещё не использовано
plHist.used=plHist.used or{};plHist.last={}
local usedPl={}
local placed=0
for _,e in ipairs(defs)do
if placed>=3 then break end
local pname=nil
for _,cand in ipairs(NPREF[e.k])do if not usedPl[cand]then pname=cand;break end end
if pname then
local flist=NFIELDS[e.k]
plHist.used[e.k]=plHist.used[e.k]or{}
local fname=nil
if pname=="The Planter Of Plenty"and POP_FIELD[e.k]and not plHist.used[e.k][POP_FIELD[e.k]]then fname=POP_FIELD[e.k]end
if not fname then for _,fn in ipairs(flist)do if not plHist.used[e.k][fn]then fname=fn;break end end end
if not fname then plHist.used[e.k]={};fname=flist[1]end
local pos=getFieldPos(fname)
if pos then
usedPl[pname]=true;plHist.used[e.k][fname]=true
table.insert(plHist.last,{pl=pname,f=fname,k=e.k})
tpTo(pos)
pcall(function()RS.Events.PlayerActivesCommand:FireServer({["Name"]=pname})end)
print("MarmotZ: planter "..pname.." -> "..fname.." ("..e.k..")")
placed=placed+1;task.wait(1)
end
end
end
savePlHist()
-- v5.1: после расстановки ВСЕХ плантеров тепаемся на центр Pepper Patch — Workspace.Flowers.FP18-10-14
local fpC=getFieldPos("Pepper Patch")
if fpC then
tpTo(fpC)
-- v5.1.6: после ТП ~5с патрулируем MoveTo-шагами вокруг центра поля — гуманоид цепляется за землю и не сваливается с пеппера
local t0p=os.clock()
while os.clock()-t0p<5 do
local rP=h();local hmP=hm();if not rP or not hmP then break end
local ang=math.random()*2*math.pi
hmP:MoveTo(Vector3.new(fpC.X+math.cos(ang)*5,rP.Position.Y,fpC.Z+math.sin(ang)*5))
task.wait(0.5)
end
end
end

-- ===== HACHAPURI ENGINE (v5.0) =====
function pressE()pcall(function()V:SendKeyEvent(true,Enum.KeyCode.E,false,game);task.wait(0.1);V:SendKeyEvent(false,Enum.KeyCode.E,false,game)end)end
-- useWindShrine убран в v5.0.3 (плохо работал, шрайн не давал награду стабильно)
function runSprinkler()
local r=h();local hum2=hm();if not r or not hum2 then return end
local fls=W:FindFirstChild("Flowers");local flower=fls and fls:FindFirstChild("FP18-10-13");if not flower then return end
hum2.AutoRotate=false
local target=CFrame.new(flower.Position+Vector3.new(0,3,0))
local t0=tick()
while tick()-t0<0.3 do r.CFrame=target;r.AssemblyLinearVelocity=ZERO;R.Heartbeat:Wait()end
pcall(function()RS.Events.PlayerActivesCommand:FireServer({Name="Sprinkler Builder"})end)
for i=1,3 do r.CFrame=target;r.AssemblyLinearVelocity=ZERO;R.Heartbeat:Wait()end
hum2.AutoRotate=true;pcall(function()hum2:ChangeState(Enum.HumanoidStateType.Running)end)
print("MarmotZ: Sprinkler -> FP18-10-13 (no return back)")
end
function mondoDodge()
while true do
local mon=W:FindFirstChild("Monsters");local chick=mon and mon:FindFirstChild("Mondo Chick (Lvl 8)")
if not chick then break end
local r=h();if not r then break end
local cpos,csize=nil,10
if chick:IsA("Model")then local ok,sz=pcall(function()return chick:GetExtentsSize()end);local pp=chick.PrimaryPart or chick:FindFirstChildWhichIsA("BasePart");if pp then cpos=pp.Position end;if ok and sz then csize=math.max(sz.X,sz.Z)end
elseif chick:IsA("BasePart")then cpos=chick.Position;csize=math.max(chick.Size.X,chick.Size.Z)end
local hm2=hm()
if cpos and hm2 then
local keep=csize/2+13 -- v5.1.2: детект сайза петуха + 13 студов (было 11)
local away=Vector3.new(r.Position.X-cpos.X,0,r.Position.Z-cpos.Z)
local dist=away.Magnitude
if dist<keep+2 then
local dir=dist>0.1 and away.Unit or Vector3.new(1,0,0)
hm2:MoveTo(cP(r.Position+dir*(keep+8-dist)))
else
local ang=math.random()*2*math.pi
hm2:MoveTo(cP(Vector3.new(cpos.X+math.cos(ang)*(keep+10),r.Position.Y,cpos.Z+math.sin(ang)*(keep+10))))
end
end
task.wait(0.15)
end
end
function hchTickets()
pcall(function()RS.Events.StickerStackActivate:FireServer("Tickets")end)
local fls=W:FindFirstChild("Flowers");local fp=fls and fls:FindFirstChild("FP14-11-21")
if fp then tpTo(fp.Position)end
print("MarmotZ: :58 Tickets + TP FP14-11-21")
end
function hchDump()
INT=true;tL="Hachapuri dump"
local ok,surf=pcall(function()return W.HiveDeco.StickerCanvases.StickerCanvas6.PlaceableSurfaces end)
if not ok or not surf then print("MarmotZ: StickerCanvas6 not found")INT=false;return end
local part=surf:IsA("BasePart")and surf or surf:FindFirstChildWhichIsA("BasePart",true)
if not part then INT=false;return end
tpTo(part.Position)
task.wait(2);pressE()
local cs=L:FindFirstChild("CoreStats");local pol=cs and cs:FindFirstChild("Pollen")
local t0=os.clock()
while pol and pol.Value>0 and os.clock()-t0<240 do task.wait(0.5)end
t0=os.clock()
while os.clock()-t0<300 do
local ok2,bb=pcall(function()return W.Balloons.HiveBalloons.HiveBalloonInstance.BalloonBody end)
if not ok2 or not bb or not bb.Parent then break end
task.wait(1)
end
INT=false
end
function hchMondoPhase()
local t0=os.clock()
while os.clock()-t0<120 do
local mon=W:FindFirstChild("Monsters")
if mon and mon:FindFirstChild("Mondo Chick (Lvl 8)")then break end
task.wait(1)
end
hchDodge=true;INT=true;tL="Mondo dodge"
pcall(mondoDodge)
hchDodge=false;INT=false
-- Wind Shrine убран (v5.0.3)
for p,t in pairs(aT)do if not t.col and p.Parent and t.id==3835712489 then local r=h();if r then r.CFrame=CFrame.new(p.Position+Vector3.new(0,2,0))end;task.wait(0.5);break end end
runSprinkler()
pcall(function()RS.Events.PlayerActivesCommand:FireServer({["Name"]="Super Smoothie"})end);hchSmT0=os.clock()
print("MarmotZ: Hachapuri cycle done, smoothie #2 in 20 min")
end
-- планировщик по минутам: :43 плантеры (независимо от Hachapuri), :50 сдача, :58 тикеты, :00 Мондо
task.spawn(function()
local lastPl,last50,last58,last00="","","",""
while true do task.wait(5)
pcall(function()
if not ENABLED then return end
local mn=tonumber(os.date("%M"))or-1
local hh2=os.date("%d%H")
if cfg.pl_auto and mn==(tonumber(cfg.pl_min)or 43)and lastPl~=hh2 then lastPl=hh2;task.spawn(function()hchBusy=true;pcall(plantPlanters);hchBusy=false end)end
if cfg.hachapuri then
if mn==50 and last50~=hh2 then last50=hh2;task.spawn(function()hchBusy=true;pcall(hchDump);hchBusy=false end)end
if mn==58 and last58~=hh2 then last58=hh2;pcall(hchTickets)end
if mn==0 and last00~=hh2 then last00=hh2;task.spawn(function()hchBusy=true;pcall(hchMondoPhase);hchBusy=false end)end
end
if hchSmT0>0 and os.clock()-hchSmT0>=1200 then hchSmT0=0;pcall(function()RS.Events.PlayerActivesCommand:FireServer({["Name"]="Super Smoothie"})end);print("MarmotZ: smoothie #2 (20 min)")end
end)
end
end)

-- GUI LOOP
task.spawn(function()while true do task.wait(0.3)pcall(function()
lb.Text="Action: "..(tL or"");tmLbl.Text="Time: "..os.date("%H:%M:%S");local curH=getHoney()or 0;local em=(os.clock()-(scriptStartT or 0))/60;local hp40m=em>0 and(curH-(scriptStartH or 0))/em*40 or 0-- v5.2.1: возврат старой HP40M (средняя за сессию) по запросу
hl.Text="HP40M: "..fmtH(hp40m).." | "..fmtH(curH)
if scorchActive and(scorchStartT or 0)>0 then
local scDur=os.clock()-scorchStartT
local scEarned=curH-(scorchStartH or 0)
scLab.Text="Scorch: "..string.format("%.1fs",scDur).." | +"..fmtH(scEarned)
elseif #scorchSessions>0 then
local ls=scorchSessions[#scorchSessions]
scLab.Text="Scorch last: +"..(ls.honeyGainedFmt or fmtH(ls.honeyGained)).." | best: +"..fmtH(bestSH).." | клик = топ-24"
else scLab.Text="Scorch: --"end
cocoTg.Text=(cfg.coco_on and"[X] "or"[ ] ").."Farm Coconuts"
cocoTg.TextColor3=cfg.coco_on and Color3.fromRGB(100,255,100)or Color3.fromRGB(200,200,200)
cocoBx.Text=tostring(cfg.coco_lim)
shwTg.Text=(cfg.shower_on and"[X] "or"[ ] ").."Farm Showers"
shwTg.TextColor3=cfg.shower_on and Color3.fromRGB(100,255,100)or Color3.fromRGB(200,200,200)
shwBx.Text=tostring(cfg.shower_lim)
prpTg.Text=(cfg.purple_on and"[X] "or"[ ] ").."Farm Precise Marks"
prpTg.TextColor3=cfg.purple_on and Color3.fromRGB(100,255,100)or Color3.fromRGB(200,200,200)
prpBx.Text=tostring(cfg.purple_lim)
for k,row in pairs(plRows or{})do local s=nectarRem[k]or 0;if type(row)=="table"then local tgt=(cfg["pl_"..row.k.."_h"]or 22)*3600;local frac=tgt>0 and math.min(1,s/tgt)or 0;row.remL.Text=string.format("%dh %02dm",math.floor(s/3600),math.floor((s%3600)/60));row.bar.Size=UDim2.new(frac,0,1,0)else row.Text=string.format("%dh %02dm",math.floor(s/3600),math.floor((s%3600)/60))end end
end)
end
end)

-- v5.0: все бинды убраны — управление только кнопками GUI

-- RESPAWN
L.CharacterAdded:Connect(function()
task.wait(2);aT={};cQ={};lP=nil;curF=nil;tL="start";smT=nil;isCS=false;INT=false;cyc={chC=0};fP={};dupCnt=0;pollMS=0;eligibility={};visitCount={};totalSteps=0;replayBuffer={};replayIndex=1
scorchActive=false;scorchRecording=false;scorchActions={};scorchStartH=0;scorchStartT=0;lastTLT=0;xfP=0;scP=0;lastBH=0;xGCH=0;scorchDupedMorphDone=false;scorchPurpleCount=0;scorchPurpleTime=0;scorchAllCHMode=false;scorchPurpleTotal=0;ndMorph=nil;scorchTPIndex=0;scorchTPTable={};scorchTPCycle=false;xfStartTime=0;flameCampStart=0;scorchAllCHT0=0;flCampAcc=0;flCampCd=0;cocoCnt=0;showerCnt=0;cocoCycle=0;showerCycle=0;purpleMarkCnt=0;rCC=0;rST=0;lastSOTime=0;hchDodge=false;hchBusy=false
for _,v in pairs(activeTG)do if v.gui then pcall(function()v.gui:Destroy()end)end end;activeShowers={};activeBlooms={};activeCocos={};activeTG={};tokenVerify={};tokenBL=setmetatable({},{__mode="k"});greenCH_cache={}
for fl in pairs(flameCD)do flameCD[fl]=nil end;for fl in pairs(scytheParts)do scytheParts[fl]=nil end
end)
print("Marmot Z v5.2.8 — Full script active.")
