-- Marmot Z v4.0 — Predictive Pre-positioning, Spatial State, Momentum Strafing, PER, XF Camp, Tabbed GUI
local P=game:GetService("Players");local W=game:GetService("Workspace")
local R=game:GetService("RunService");local U=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage");local H=game:GetService("HttpService")
local V=game:GetService("VirtualInputManager");local D=game:GetService("Debris")
local L=P.LocalPlayer;local G=L:WaitForChild("PlayerGui");local ENABLED=true;local ELA=true
if not math.round then math.round=function(n)return math.floor(n+.5)end end
Q_VERSION="Marmot Z - HRL & Velocity Overdrive v4.0"
task.wait(2)

-- COMPAT
local ZERO=Vector3.new(0,0,0)
local function cfLookAt(from,to)
 local ok,res=pcall(function()return CFrame.lookAt(from,to)end)
 if ok and res then return res end
 return CFrame.new(from,to)
end

-- ERROR GUI
local elog,egui,elbl,ebtn,ecnt={},nil,nil,nil,0
local function mkE()pcall(function()if egui then return end
egui=Instance.new("ScreenGui");egui.Name="E";egui.ResetOnSpawn=false;egui.Parent=G
local b=Instance.new("Frame",egui);b.Size=UDim2.new(0,380,0,240);b.Position=UDim2.new(.5,-190,.5,-120)
b.BackgroundColor3=Color3.fromRGB(15,15,25);b.BackgroundTransparency=.08;b.BorderSizePixel=0;b.Active=true;b.Draggable=true
Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
local t=Instance.new("TextLabel",b);t.Size=UDim2.new(1,-16,0,24);t.Position=UDim2.new(0,8,0,8);t.BackgroundTransparency=1
t.Text="Marmot Z v4.0";t.TextColor3=Color3.fromRGB(255,180,60);t.Font=Enum.Font.GothamBold;t.TextSize=14;t.TextXAlignment=Enum.TextXAlignment.Left
elbl=Instance.new("TextLabel",b);elbl.Size=UDim2.new(1,-16,0,130);elbl.Position=UDim2.new(0,8,0,42);elbl.BackgroundTransparency=1
elbl.Text="Marmot Z boot...";elbl.TextColor3=Color3.fromRGB(200,200,200);elbl.Font=Enum.Font.Code;elbl.TextSize=11;elbl.TextWrapped=true;elbl.RichText=true
ebtn=Instance.new("TextButton",b);ebtn.Size=UDim2.new(0,140,0,28);ebtn.Position=UDim2.new(0,8,0,180)
ebtn.Text="Copy logs";ebtn.TextColor3=Color3.fromRGB(220,220,220);ebtn.Font=Enum.Font.Gotham;ebtn.TextSize=11
Instance.new("UICorner",ebtn).CornerRadius=UDim.new(0,4)
local cb=Instance.new("TextButton",b);cb.Size=UDim2.new(0,80,0,28);cb.Position=UDim2.new(0,156,0,180)
cb.Text="Close";cb.TextColor3=Color3.fromRGB(220,220,220);cb.Font=Enum.Font.Gotham;cb.TextSize=11
Instance.new("UICorner",cb).CornerRadius=UDim.new(0,4)
cb.MouseButton1Click:Connect(function()egui.Enabled=false;egui:Destroy()end)
ebtn.MouseButton1Click:Connect(function()local x=table.concat(elog,"\n");if#x==0 then x="No errors"end;pcall(setclipboard,x);ebtn.Text="Done";task.wait(1.5);ebtn.Text="Copy logs"end)
task.spawn(function()task.wait(4);if egui and ecnt==0 then egui.Enabled=false;egui:Destroy()end end)
end)end
local function le(m)ecnt=ecnt+1;table.insert(elog,string.format("[%02d] %s",ecnt,m));while#elog>20 do table.remove(elog,1)end;if elbl then local L={};for i=math.max(1,#elog-12),#elog do table.insert(L,elog[i])end;elbl.Text=table.concat(L,"\n");if ecnt==1 then elbl.TextColor3=Color3.fromRGB(255,140,100)end end;warn("MarmotZ:",m)end
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

-- ===== FEATURE 1: Predictive Pre-positioning — Raycast for high-altitude CH =====
local RaycastParams=RaycastParams.new();RaycastParams.FilterType=Enum.RaycastFilterType.Whitelist
local function getRayTargets()
 local targets={}
 local fl=W:FindFirstChild("Flowers");if fl then for _,f in ipairs(fl:GetChildren())do if f:IsA("BasePart")then table.insert(targets,f)end end end
 local fz=W:FindFirstChild("FlowerZones");if fz then for _,z in ipairs(fz:GetChildren())do if z:IsA("BasePart")then table.insert(targets,z)end end end
 return targets
end
local function predictLandingPos(chPart)
 if chPart.Position.Y<=20 then return nil end
 local targets=getRayTargets()
 if#targets==0 then return nil end
 RaycastParams.FilterDescendantsInstances=targets
 local origin=chPart.Position+Vector3.new(0,2,0)
 local dir=Vector3.new(0,-200,0)
 local res=W:Raycast(origin,dir,RaycastParams)
 if res then return res.Position end
 return nil
end

-- ANIM & DEBRIS
local function lootAnim(pos,dur)if not pos then return end
 local r=h();if not r then return end
 local spark=Instance.new("Part");spark.Shape=0;spark.Size=Vector3.new(1.2,1.2,1.2)
 spark.Anchored=true;spark.CanCollide=false;spark.Position=Vector3.new(pos.X,pos.Y+2,pos.Z)
 spark.BrickColor=BrickColor.new("Bright yellow");spark.Material=Enum.Material.Neon;spark.Transparency=0.3;spark.Parent=W
 D:AddItem(spark,dur+0.2)
 task.spawn(function()for i=1,10 do task.wait(dur/10);if spark then spark.Transparency=0.3+i*0.07;spark.Size=spark.Size+Vector3.new(0.3,0.3,0.3)end end end)
 local bg=r:FindFirstChild("BG_Loot")or Instance.new("BodyGyro")
 bg.Name="BG_Loot";bg.MaxTorque=Vector3.new(0,40000,0);local isScActive=(aB.SS.st>0);bg.P=isScActive and 25000 or 8000;bg.D=isScActive and 75 or 300;bg.Parent=r
 local dir=pos-r.Position;dir=Vector3.new(dir.X,0,dir.Z)
 if dir.Magnitude>0.1 then bg.CFrame=CFrame.new(r.Position,r.Position+dir)end
 D:AddItem(bg,dur*1.2)
end

-- DIAG VISUAL
local diagLines={};local diagVis=nil
local function showDiag(sP,eP,suc)
 for _,l in ipairs(diagLines)do pcall(function()l:Destroy()end)end;diagLines={}
 if diagVis then pcall(function()diagVis:Destroy()end);diagVis=nil end
 local mid=(sP+eP)/2;local dist=(eP-sP).Magnitude
 local line=Instance.new("Part");line.Anchored=true;line.CanCollide=false;line.Size=Vector3.new(dist,0.08,0.08)
 line.CFrame=CFrame.new(mid,eP)*CFrame.Angles(math.pi/2,0,0)
 line.BrickColor=suc and BrickColor.new("Bright green")or BrickColor.new("Bright orange")
 line.Material=Enum.Material.Neon;line.Transparency=0.4;line.Parent=W;table.insert(diagLines,line)
 D:AddItem(line,1.2)
end

-- CONSTANTS
SB={NABOR=70,X10=90,REFRESH=75}
SJ=3;AM=1.2;DGL=22;FM=3;AD=5;MT=6
PBI=2574507284;PLMBI=2577647417;PPK=0.02;PMX=10;PRAT=25
PURP=Color3.fromRGB(119,85,255);PTOL=12;SMI=5877939956;TSD=1.1
CAR=35;CAS=24;CAD=0.05;ARR=20;TLID=20;PCD=8;PFM=20;TPI=8173559749
TLC=2;PT=8;XCR=15;PCHR=10;SCYTHE_DIST=14;SCYTHE_CD=0.4
AL=0.5;GA=0.95;EP=0.3;ED=0.9995;PMBI=2577647416
FOCI=2577384907;RBOI=2577383393;FOCUS_RENEW=10;RB_RENEW=7;RB_SCORCH_RENEW=9
SCORCH_BIAS=1.15;PAT_WINDOW=2400;PAT_TOP=10;TD_LAMBDA=0.7;UCB_C=1.5
FLAME_CLUSTER_RADIUS=8;FLAME_CLUSTER_MIN=4;FLAME_PATH_STEP=6
DPRI={[4519549299]=true,[2499540966]=true,[2499514197]=true,[4528379338]=true,[1442859163]=true,[1442863423]=true,[3877732821]=true,[1442764904]=true,[4528208186]=true,[8173559749]=true}

-- TOKEN DEFS
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
PC={Red=Color3.fromRGB(249,34,34),Pink=Color3.fromRGB(255,130,201),Merigold=Color3.fromRGB(218,168,28),Periwinkle=Color3.fromRGB(150,156,236),Violet=Color3.fromRGB(94,38,177),Scarlet=Color3.fromRGB(171,19,19),Green=Color3.fromRGB(35,232,5),Yellow=Color3.fromRGB(238,204,79),Black=Color3.fromRGB(11,11,11),Grey=Color3.fromRGB(127,127,127),Blue=Color3.fromRGB(33,66,249),Cyan=Color3.fromRGB(29,196,222),White=Color3.fromRGB(249,249,249)}
PP={Red=1,Pink=2,Merigold=3,Periwinkle=4,Violet=5,Scarlet=6,Green=7,Yellow=8,Black=9,Grey=10,Blue=11,Cyan=12,White=13}

-- STATE
aT,cQ,lP,curF,tL={},{},nil,nil,"start"
prec={st=0,val=0,isX=false,ls=0,sD=60,sS=0,tL=0,nR=false}
st={tk=0,ch=0,pr=0,rf=0,tR=0,dc=0,sm=0,chA=0,pt=0,chP=0}
cyc={chC=0};INT=false;isCS=false;smT=nil;smTR=0;igT=0
fP={};aR=nil;aRR=ARR
aB={SS={st=0},XF={st=0},PM={a=false},PoM={a=false,pos=nil,m=0},PollM={combo=0,active=false,ringPos=nil},FC={combo=0,dur=20,tL=0},RB={combo=0,dur=15,tL=0}}
stP=setmetatable({},{__mode="k"})
rCC=0;rST=0;pH={}
QT={};lMT=os.clock();stW=false;xfE=false;xfC=nil;lPT=0
qTables={};fldHash=nil;dupCnt=0
eligibility={};visitCount={};totalSteps=0
lastActionTime=0;flHit=0;chStick=0;aborted=false
cS=70;hbF=0;isA=false
scorchActive=false;scorchRecording=false;scorchActions={};scorchSessions={};top10={}
bestSH=0;lastPS=0
scytheParts=setmetatable({},{__mode="k"});lastSHit=0;scVis=nil;syVis=nil;fixedXFC=nil
lastTLT=0;goSm=false
activeCocos={};activeShowers={};activeTG={};activeBlooms={}
xfP=0;scP=0;lastBH=0;redPT=0;stFlMin=0;xGCH=0
flameCD=setmetatable({},{__mode="k"})
scriptStartH=0;scriptStartT=0;scorchStartH=0;scorchStartT=0;pollMS=0
lastSOTime=0;scorchDupedMorphDone=false
scorchPurpleCount=0;scorchPurpleTime=0;scorchAllCHMode=false;scorchPurpleTotal=0
tokenVerify={};ndMorph=nil
scorchTPIndex=0;scorchTPTable={};scorchTPCycle=false
local xfStartTime=0
-- ===== FIX #2: Token Blacklist (анти-застревание) =====
local tokenBL=setmetatable({},{__mode="k"})
-- ===== FIX #3: Green CH Memory (не наступать повторно) =====
local greenCH_cache=setmetatable({},{__mode="k"})
-- ===== FIX #6: Precise Bee Learning Array =====
local preciseLearn={}

-- ===== FEATURE 2: getSpatialState — C(enter)/E(dge)/M(id) =====
local function getSpatialState()
 local r=h();if not r or not curF or not curF.part then return"N"end
 local c=curF.part.Position;local s=curF.part.Size
 if s.X>0 and s.Z>0 then
  local rx=math.abs(r.Position.X-c.X)/(s.X/2);local rz=math.abs(r.Position.Z-c.Z)/(s.Z/2)
  if rx>0.7 or rz>0.7 then return"E"end;if rx<0.3 and rz<0.3 then return"C"end
 end;return"M"
end

-- PHASE HELPERS
local function ph()if not prec.isX then return"NABOR"end;if prec.nR then return"REFRESH"end;return"X10"end
local function scPh()if aB.SS.st>0 then return"INSIDE"end;return"OUTSIDE"end
local function gQ(s,a)if not QT[s]then QT[s]={}end;return QT[s][a]or 0 end
local function sQ(s,a,v)if not QT[s]then QT[s]={}end;QT[s][a]=v end
-- ===== FEATURE 2: getCK включает Spatial State =====
local function getCK()local xfB=0;if xfP>=22 then xfB=3 elseif xfP>=18 then xfB=2 elseif xfP>=10 then xfB=1 end;return string.format("%s|%s|FC%s|RB%s|PM%d|XF%d",ph(),getSpatialState(),(aB.FC.combo>=10 and"1"or"0"),(aB.RB.combo>=10 and"1"or"0"),math.min(3,aB.PoM.m),xfB)end

-- FIELD DETECTION
local function fldHashF()if not curF or not curF.part then return"unknown"end;return string.format("%.0f%.0f",curF.part.Position.X/50,curF.part.Position.Z/50)end
local function swFld()local nh=fldHashF();if nh==fldHash then return end;if qTables[fldHash]then qTables[fldHash]=QT end;fldHash=nh;QT=qTables[fldHash]or{}end
local function fF()
 local r=h();if not r then return curF end;local mp=r.Position
 local z=W:FindFirstChild("FlowerZones")
 if z then local be,bd=nil,math.huge;for _,zn in ipairs(z:GetChildren())do if zn:IsA("BasePart")then local d=d3(mp,zn.Position);if math.abs(mp.X-zn.Position.X)<=zn.Size.X/2+20 and math.abs(mp.Z-zn.Position.Z)<=zn.Size.Z/2+20 and d<bd then bd=d;be=zn end end end;if be then curF={part=be};swFld();return curF end end
 local fl=W:FindFirstChild("Flowers")
 if fl then local fp={};for _,f_ in ipairs(fl:GetChildren())do if f_:IsA("BasePart")then table.insert(fp,f_.Position)end end
  if#fp>0 then local mnX,mxX,mnZ,mxZ=math.huge,-math.huge,math.huge,-math.huge;for _,p in ipairs(fp)do if p.X<mnX then mnX=p.X end;if p.X>mxX then mxX=p.X end;if p.Z<mnZ then mnZ=p.Z end;if p.Z>mxZ then mxZ=p.Z end end;curF={part={Position=Vector3.new((mnX+mxX)/2,mp.Y,(mnZ+mxZ)/2),Size=Vector3.new(math.abs(mxX-mnX)+10,1,math.abs(mxZ-mnZ)+10)}};swFld();return curF end
 end
 if aR then curF={part={Position=aR.Position,Size=Vector3.new(aRR*3,1,aRR*3)}};swFld();return curF end
 return curF
end
local function gFC()if xfE and fixedXFC then return fixedXFC end;if curF and curF.part then return curF.part.Position end;local r=h();return r and r.Position or ZERO end
local function gAS()local p=ph();local b=SB[p]or 70;if hbF%30==0 then local base=b+(math.random()*2-1)*SJ;if math.abs(base-cS)>1 then cS=base end end;return cS end
local function cP(pos,sk)if sk then return pos end;if not curF then return pos end;local c=curF.part.Position;local s=curF.part.Size;local mx=math.max(s.X/2-FM,1);local mz=math.max(s.Z/2-FM,1);local cl=Vector3.new(math.clamp(pos.X,c.X-mx,c.X+mx),pos.Y,math.clamp(pos.Z,c.Z-mz,c.Z+mz));if aB.XF.st>=19 then local dx=cl.X-c.X;local dz=cl.Z-c.Z;local dSq=dx*dx+dz*dz;if dSq>0 then local invD=1/math.sqrt(dSq);cl=Vector3.new(c.X+dx*invD*XCR,cl.Y,c.Z+dz*invD*XCR)end end;return cl end
local function iF(pos)if not curF then return false end;local c=curF.part.Position;local s=curF.part.Size;return math.abs(pos.X-c.X)<=s.X/2+PFM and math.abs(pos.Z-c.Z)<=s.Z/2+PFM end
local function gEP(tP)if not aR or not aR.Parent then return tP end;local dir=(tP-aR.Position).Unit;return cP(Vector3.new(aR.Position.X+dir.X*aRR,0,aR.Position.Z+dir.Z*aRR))end

-- PARTICLES
W.DescendantAdded:Connect(function(o)if o.Name=="AreaRing"and o:IsA("BasePart")then aR=o;aRR=(o.Size.X+o.Size.Z)/4;if aRR<5 then aRR=ARR end end end)
local function fAR()local p=W:FindFirstChild("Particles");if p then for _,o in ipairs(p:GetChildren())do if o.Name=="AreaRing"and o:IsA("BasePart")then aR=o;aRR=(o.Size.X+o.Size.Z)/4;if aRR<5 then aRR=ARR end;return end end end;aR=W:FindFirstChild("AreaRing");if aR and aR:IsA("BasePart")then aRR=(aR.Size.X+aR.Size.Z)/4;if aRR<5 then aRR=ARR end else aR=nil;aRR=ARR end end
local Pt=W:FindFirstChild("Particles");if not Pt then Pt=workspace:WaitForChild("Particles",10)end
local function iCl(a,b,tl)tl=tl or PTOL;return math.abs(a.R*255-b.R*255)<=tl and math.abs(a.G*255-b.G*255)<=tl and math.abs(a.B*255-b.B*255)<=tl end
local function iP(p)
 local ok1,c1=pcall(function()return p.Color end);if ok1 and c1 and iCl(c1,PURP,20)then return true end
 local ok2,bc=pcall(function()return p.BrickColor.Color end);if ok2 and bc and iCl(bc,PURP,20)then return true end
 local ok3,bcn=pcall(function()return p.BrickColor.Name end);if ok3 and bcn then local bn=bcn:lower();if bn:find("lavender")or bn:find("violet")or bn:find("purple")or bn:find("alder")or bn:find("bright violet")or bn:find("lilac")or bn:find("magenta")then return true end end
 return false
end

-- ===== FEATURE 1: aCH с Predictive Pre-positioning =====
local function aCH(o)if o.Name~="Crosshair"or not o:IsA("BasePart")then return end;for i=1,#cQ do if cQ[i].part==o then return end end;local pPos=nil;if o.Position.Y>20 then pPos=predictLandingPos(o)end;local e={part=o,sT=os.clock(),col=false,isP=iP(o),pPos=pPos};table.insert(cQ,e);if not e.isP then task.spawn(function()task.wait(0.06);if o.Parent and not e.col then e.isP=iP(o);if not e.pPos and o.Position.Y>20 then e.pPos=predictLandingPos(o)end end end)end end
local poppable=W:FindFirstChild("Happenings")and W.Happenings:FindFirstChild("PoppablePlants")
if poppable then for _,b in ipairs(poppable:GetChildren())do if b.Name=="Bloom"then activeBlooms[b]=true end end;poppable.ChildAdded:Connect(function(b)if b.Name=="Bloom"then activeBlooms[b]=true end end);poppable.ChildRemoved:Connect(function(b)if activeBlooms[b]then activeBlooms[b]=nil end end)end
if Pt then Pt.DescendantAdded:Connect(function(o)aCH(o);if o.Name=="WarningDisk"and o:IsA("BasePart")then local sx=o.Size.X;if math.abs(sx-23.4)<2 then table.insert(activeCocos,{part=o,spawnTime=os.clock(),collected=false})elseif math.abs(sx-8.0)<1 then table.insert(activeShowers,{part=o,spawnTime=os.clock(),collected=false})end end end);Pt.DescendantRemoving:Connect(function(o)for i=#cQ,1,-1 do if cQ[i].part==o then table.remove(cQ,i);break end end;if lP==o then lP=nil end;for i=#activeCocos,1,-1 do if activeCocos[i].part==o then table.remove(activeCocos,i);break end end;for i=#activeShowers,1,-1 do if activeShowers[i].part==o then table.remove(activeShowers,i);break end end end);for _,o in ipairs(Pt:GetDescendants())do aCH(o)end end
local function clnCH()for i=#cQ,1,-1 do local ch=cQ[i];if not ch.part or not ch.part.Parent or ch.col then table.remove(cQ,i)end end end
local function gCH(op,oR,purpFirst)
 local L,P={},{}
 for i=#cQ,1,-1 do local ch=cQ[i];local alive=false;pcall(function()if ch.part and ch.part.Parent then alive=true end end);if not alive then table.remove(cQ,i)
 elseif not ch.col then if(op or purpFirst)and not ch.isP and ch.part.Parent then ch.isP=iP(ch.part)end
  if(op and ch.isP)or(oR and not ch.isP)or(not op and not oR)then if purpFirst and ch.isP then table.insert(P,ch)else table.insert(L,ch)end end end end
 table.sort(L,function(a,b)return a.sT<b.sT end);table.sort(P,function(a,b)return a.sT<b.sT end)
 if purpFirst then local r={};for _,ch in ipairs(P)do table.insert(r,ch)end;for _,ch in ipairs(L)do table.insert(r,ch)end;return r end
 return L
end
local function gPCH()return gCH(true,false,false)end
local function gTPG_build()local all=gCH(false,false,false);if#all<3 then return nil end;local G={};for i=1,#all do local c=all[i];if c.isP then local cl={};for j=1,#all do if not all[j].isP and i~=j then local dist=d3(c.part.Position,all[j].part.Position);if dist<25 then table.insert(cl,{ch=all[j],d=dist})end end end;table.sort(cl,function(a,b)return a.d<b.d end);if#cl>=2 then table.insert(G,{pr=c,r1=cl[1].ch,r2=cl[2].ch})end end end;return#G>0 and G or nil end
local function gTPG()if not prec.isX or prec.nR then return nil end;return gTPG_build()end
local function gCH_nc()local cc=gFC();if cc==ZERO then return nil end;local best,bestD=nil,math.huge;for i=1,#cQ do local ch=cQ[i];if not ch.col and ch.part.Parent then local d=d3(ch.part.Position,cc);if d<bestD then bestD=d;best=ch end end end;return best end
local function gCH_n()local r=h();if not r then return nil end;local best,bestD=nil,math.huge;for i=1,#cQ do local ch=cQ[i];if not ch.col and ch.part.Parent then local d=d3(r.Position,ch.part.Position);if d<bestD then bestD=d;best=ch end end end;return best end

-- ===== FIX #3: Diagonal Looting — сортируем CH вдоль одной оси при 6+ =====
local function gDiagonalLoot()
 local all=gCH(false,false,false);if#all<6 then return all end
 -- Считаем разброс по X и Z
 local mnX,mxX,mnZ,mxZ=math.huge,-math.huge,math.huge,-math.huge
 for i=1,#all do local p=all[i].part.Position;if p.X<mnX then mnX=p.X end;if p.X>mxX then mxX=p.X end;if p.Z<mnZ then mnZ=p.Z end;if p.Z>mxZ then mxZ=p.Z end end
 local spanX,spanZ=mxX-mnX,mxZ-mnZ
 -- Сортируем по длинной оси — так бот бежит по прямой
 if spanX>spanZ then table.sort(all,function(a,b)return a.part.Position.X<b.part.Position.X end)
 else table.sort(all,function(a,b)return a.part.Position.Z<b.part.Position.Z end)end
 return all
end

-- ===== FIX #6: Precise Bee Prediction =====
local function findPreciseBees()
 local bees=W:FindFirstChild("Bees");if not bees then return{}end
 local res={}
 for _,b in ipairs(bees:GetChildren())do
  if b:IsA("Model")then
   local nm=b.Name or"";local hrp=b:FindFirstChild("HumanoidRootPart")
   if hrp and(nm:find("Precise")or nm:find("precise"))then table.insert(res,b)end
  end
 end
 return res
end
local function predictPreciseShot()
 local bees=findPreciseBees();if#bees==0 then return nil end
 local r=h();if not r then return nil end
 for _,b in ipairs(bees)do
  local hrp=b:FindFirstChild("HumanoidRootPart");if not hrp then continue end
  local look=hrp.CFrame.LookVector;local key=string.format("%.0f,%.0f,%.0f",hrp.Position.X/3,hrp.Position.Z/3,look.X*10)
  -- Проверяем запись в самообучающейся таблице
  if preciseLearn[key]then
   local rec=preciseLearn[key]
   if os.clock()-rec.t<60 and d2Sq(r.Position,rec.pos)>36 then return rec.pos end
  end
  -- Иначе пускаем Raycast из пчелы в сторону поля
  local targets={};local fl=W:FindFirstChild("Flowers");if fl then for _,f in ipairs(fl:GetChildren())do if f:IsA("BasePart")then table.insert(targets,f)end end end
  if#targets>0 then
   local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Whitelist;rp.FilterDescendantsInstances=targets
   local origin=hrp.Position+look*5+Vector3.new(0,0,0)
   local res=W:Raycast(origin,Vector3.new(0,-100,0),rp)
   if res then
    -- Сохраняем в learning array
    preciseLearn[key]={pos=res.Position,t=os.clock()}
    if d2Sq(r.Position,res.Position)>36 then return res.Position end
   end
  end
 end
 return nil
end

-- ===== FEATURE 1: gCH_with_predict — получает CH с pPos для пре-позиционирования =====
local function gCH_predict()local r=h();if not r then return nil end;local best,bestD=nil,math.huge;for i=1,#cQ do local ch=cQ[i];if not ch.col and ch.part.Parent and not ch.isP and ch.pPos then local d=d2Sq(r.Position,ch.pPos);if d<bestD then bestD=d;best=ch end end end;return best end

local function hasNearPurpleCH()local r=h();if not r then return false end;for i=1,#cQ do if not cQ[i].col and cQ[i].part.Parent and cQ[i].isP and d2Sq(r.Position,cQ[i].part.Position)<900 then return true end end;return false end

-- CROSSHAIR AVOIDANCE (O(N log N) grid-lines)
local cATCache={};local cATFrame=0
local function gRCT(mP,dP)
 if not prec.isX or prec.nR then return{}end
 if cATFrame==hbF then return cATCache end
 local mf=Vector3.new(mP.X,0,mP.Z);local df=Vector3.new(dP.X,0,dP.Z);local tD=(df-mf).Unit;local th={}
 local hasPurp=hasNearPurpleCH();local valid={}
 for i=1,#cQ do local ch=cQ[i]
  if not ch.col and ch.part.Parent and not ch.isP then table.insert(valid,ch)
   local cf=Vector3.new(ch.part.Position.X,0,ch.part.Position.Z);local dSq=d2Sq(mf,cf)
   local sz=math.max(ch.part.Size.X,ch.part.Size.Z,4);local isScActive=(aB.SS.st>0);local effR=sz*1.8+6+(hasPurp and sz*0.4+4 or 0);if isScActive then effR=sz*1.1+2 end
   if dSq<(effR*effR)and dSq>0.04 then local toCh=cf-mf;if toCh.Unit:Dot(tD)>-0.1 then
    local cross=math.abs(toCh.X*tD.Z-toCh.Z*tD.X)
    if cross<effR*0.85 then table.insert(th,{ch=ch,pos=cf,dist=math.sqrt(dSq),cross=cross,sz=sz})end
   end end
  end
 end
 local function scanG(ax)
  table.sort(valid,function(a,b)return a.part.Position[ax]<b.part.Position[ax]end)
  local grp={}
  for i=1,#valid do
   if#grp==0 or math.abs(valid[i].part.Position[ax]-grp[1].part.Position[ax])<=3.5 then table.insert(grp,valid[i])
   else if#grp>=(hasPurp and 2 or 3)then
    local mn,mx=math.huge,-math.huge;local ox=(ax=="X")and"Z"or"X"
    for _,m in ipairs(grp)do if m.part.Position[ox]<mn then mn=m.part.Position[ox]end;if m.part.Position[ox]>mx then mx=m.part.Position[ox]end end
    local mid=(mn+mx)/2;local ext=(mx-mn)/2+8+(hasPurp and 12 or 0)
    local proj=Vector3.new(ax=="X"and grp[1].part.Position.X or mid,0,ax=="Z"and grp[1].part.Position.Z or mid)
    local pDSq=d2Sq(proj,mf)
    if pDSq<2500 and pDSq>0.04 and(proj-mf).Unit:Dot(tD)>0.05 then table.insert(th,{ch=cQ[1],pos=proj,dist=math.sqrt(pDSq),cross=0,sz=math.min(ext,35)})end
   end;grp={valid[i]}end
  end
 end
 scanG("X");scanG("Z")
 cATFrame=hbF;cATCache=th;return th
end
-- ===== FIX #1: Tangent Path — игнорируем фиолетовый CH при обходе, чистая касательная =====
local function cAT(mP,dP,targetIsPurple)
 local th=gRCT(mP,dP);if#th==0 then return nil end
 local mf=Vector3.new(mP.X,0,mP.Z);local df=Vector3.new(dP.X,0,dP.Z);local tD=(df-mf).Unit
 -- ФИЛЬТРУЕМ: если цель фиолетовая — НЕ обходим фиолетовые CH вообще
 local fTh={}
 for i=1,#th do local h=th[i];if h.ch and h.ch.isP then
  -- Если идём к фиолетовому — пропускаем все фиолетовые из обхода
  if not targetIsPurple then table.insert(fTh,h)end
 else table.insert(fTh,h)end end
 if#fTh==0 then return nil end
 table.sort(fTh,function(a,b)return a.dist<b.dist end);local t=fTh[1]
 local uCh=(t.pos-mf).Unit
 local pD=math.max(22,t.sz*2+14);if hasNearPurpleCH()then pD=pD*1.8 end
 -- Чистая касательная: перпендикуляр к направлению на CH
 local p1=Vector3.new(-uCh.Z,0,uCh.X);local p2=Vector3.new(uCh.Z,0,-uCh.X)
 local bp=p2:Dot(tD)>=p1:Dot(tD)and p2 or p1
 st.chA=st.chA+1;return cP(Vector3.new(t.pos.X+bp.X*pD,mP.Y,t.pos.Z+bp.Z*pD))
end

-- GREEN CH DETECT
local GREEN_RGB={R=17/255,G=134/255,B=19/255};local GREEN_TOL=8
local function isGreenCH(ch)if not ch.part.Parent then return false end;local ok,c=pcall(function()return ch.part.Color end);if ok and c then return math.abs(c.R-GREEN_RGB.R)*255<=GREEN_TOL and math.abs(c.G-GREEN_RGB.G)*255<=GREEN_TOL and math.abs(c.B-GREEN_RGB.B)*255<=GREEN_TOL end;return false end
local function tryR(origTarget)local r=h();if not r then return false end;local onlyP=(prec.isX and not prec.nR);local best,bestD=nil,math.huge;for i=1,#cQ do local ch=cQ[i];if not ch.col and ch.part.Parent then if not(onlyP and not ch.isP)then local d=d3(r.Position,ch.part.Position);if d<=PCHR and d<bestD then bestD=d;best=ch end end end end;if not best then return false end;if origTarget and best.part==origTarget then return false end;local hm_=hm();if not hm_ then return false end;lootAnim(best.part.Position,0.6);hm_:MoveTo(best.part.Position);local t0=os.clock();while os.clock()-t0<0.6 do task.wait(0.03);local r2=h();if not r2 then break end;if not best.part.Parent then best.col=true;break end;if d3(r2.Position,best.part.Position)<=4 then best.col=true;st.chP=st.chP+1;if best.isP then st.pr=st.pr+1;lP=best.part else st.ch=st.ch+1 end;return true end end;if best.part.Parent then best.col=true;st.chP=st.chP+1;if best.isP then st.pr=st.pr+1 else st.ch=st.ch+1 end end;return true end

-- SAFE HELPERS
local function sBC(obj)if not obj then return""end;local ok,bc=pcall(function()return obj.BrickColor end);if ok and bc then local ok2,nm=pcall(function()return bc.Name end);if ok2 and nm then return nm end end;return""end

-- BLOOM (Debris fixed)
local function hitBloom()
 local r=h();if not r then return end;local n=os.clock();if n-lastBH<SCYTHE_CD then return end
 local bb,bp=nil,math.huge
 for bloom in pairs(activeBlooms)do if bloom.Parent and d2Sq(r.Position,bloom.Position)<=196 then bb=bloom;break end end
 if not bb then return end;lastBH=n
 local bg=r:FindFirstChild("BG_B")or Instance.new("BodyGyro");bg.Name="BG_B";bg.MaxTorque=Vector3.new(0,40000,0);bg.P=10000;bg.D=500;bg.Parent=r
 local dir=bb.Position-r.Position;dir=Vector3.new(dir.X,0,dir.Z);if dir.Magnitude>0.1 then bg.CFrame=cfLookAt(r.Position,r.Position+dir)end
 local ev=RS:FindFirstChild("Events");local tce=ev and ev:FindFirstChild("ToolCollect");if tce then pcall(function()tce:FireServer()end)end
 D:AddItem(bg,0.15)
end

-- FLAME CLUSTER DETECTION
local function gFCB()local clusters={};local visited={};for fl,data in pairs(scytheParts)do if fl and fl.Parent and not visited[fl]then local nm=fl.Name or"";local bn=sBC(fl);local isD=(nm:find("Dark")or bn=="Really black");if not isD then local cluster={fl};visited[fl]=true;local changed=true;while changed do changed=false;for fl2 in pairs(scytheParts)do if fl2 and fl2.Parent and not visited[fl2]then local nm2=fl2.Name or"";local bn2=sBC(fl2);local isD2=(nm2:find("Dark")or bn2=="Really black");if not isD2 then for _,cf in ipairs(cluster)do if d3(cf.Position,fl2.Position)<=FLAME_CLUSTER_RADIUS then table.insert(cluster,fl2);visited[fl2]=true;changed=true;break end end end end end end;if#cluster>=FLAME_CLUSTER_MIN then local cx,cz=0,0;for _,cf in ipairs(cluster)do cx=cx+cf.Position.X;cz=cz+cf.Position.Z end;table.insert(clusters,{center=Vector3.new(cx/#cluster,0,cz/#cluster),size=#cluster,flames=cluster})end end end end;table.sort(clusters,function(a,b)return a.size>b.size end);return clusters end
local function gFCPath(rPos)local clusters=gFCB();if#clusters==0 then return nil end;local rPosFlat=Vector3.new(rPos.X,0,rPos.Z);table.sort(clusters,function(a,b)return d3(rPosFlat,a.center)<d3(rPosFlat,b.center)end);local path={};local cp=rPosFlat;for i=1,#clusters do local c=clusters[i];if d3(cp,c.center)>FLAME_PATH_STEP then table.insert(path,c.center);cp=c.center end end;return#path>0 and path or nil end

-- FLAME STRAFE
local function cFS(mP,dP)
 local mf=Vector3.new(mP.X,0,mP.Z);local df=Vector3.new(dP.X,0,dP.Z);local tt=df-mf;if tt.Magnitude<1 then return nil end;local tD=tt.Unit;local bc=nil;local bs=-1;local n=os.clock();local fl={}
 for fl2,data in pairs(scytheParts)do if fl2 and fl2.Parent and data then local nm=fl2.Name or"";local bn=sBC(fl2);local isD=(nm:find("Dark")or bn=="Really black");local cd=flameCD[fl2];if not isD and(not cd or n>=cd)and(n-data.sT)>=6.0 then table.insert(fl,{p=fl2,sT=data.sT})end end end
 if#fl==0 then return nil end
 for _,fe in ipairs(fl)do local f_=fe.p;if f_ and f_.Parent then local fp=Vector3.new(f_.Position.X,0,f_.Position.Z);local toF=fp-mf;local ad=toF:Dot(tD);if ad>0 and ad<40 then local cd=math.abs(toF.X*tD.Z-toF.Z*tD.X);if cd<10 then local nb=0;for _,fe2 in ipairs(fl)do if fe2.p~=f_ and fe2.p and fe2.p.Parent then if d3(f_.Position,fe2.p.Position)<8 then nb=nb+1 end end end;local age=n-fe.sT;local rl=math.max(0,7.0-age);local as=math.min(1.0,rl/2.0);local sc=(1+nb)*(1-cd/10)*(0.5+as*0.5);if sc>bs then bs=sc;local nd=math.min(6,cd*0.7+2);local sg=(toF.X*tD.Z-toF.Z*tD.X)>0 and 1 or-1;local px=-tD.Z*sg;local pz=tD.X*sg;bc={pos=Vector3.new(mP.X+tD.X*ad+px*nd,mP.Y,mP.Z+tD.Z*ad+pz*nd),score=sc}end end end end end
 return bc
end
-- HIT FLAMES (Debris fixed)
local function hitFlames()
 local r=h();if not r then return end;local n=os.clock();if n-lastSHit<SCYTHE_CD then return end
 local allFlames=(scorchActive and scorchStartT>0 and(n-scorchStartT)>=35)
 for fl,data in pairs(scytheParts)do
  if fl and fl.Parent then
   local nm=fl.Name or"";local bn=sBC(fl);local isD=(nm:find("Dark")or bn=="Really black")
   local cd=flameCD[fl];local canHit=allFlames or(not isD)
   if canHit and(not cd or n>=cd)and d2Sq(r.Position,fl.Position)<=784 and data and(n-data.sT)>=6.0 then
    lastSHit=n;flameCD[fl]=n+(allFlames and 2.0 or 5.0);flHit=flHit+1
    local bg=r:FindFirstChild("BG_S")or Instance.new("BodyGyro");bg.Name="BG_S";bg.MaxTorque=Vector3.new(0,40000,0);bg.P=10000;bg.D=500;bg.Parent=r
    local dir=fl.Position-r.Position;dir=Vector3.new(dir.X,0,dir.Z);if dir.Magnitude>0.1 then bg.CFrame=cfLookAt(r.Position,r.Position+dir)end
    local ev=RS:FindFirstChild("Events");local tce=ev and ev:FindFirstChild("ToolCollect");if tce then pcall(function()tce:FireServer()end)else pcall(function()local cam=workspace.CurrentCamera;local vp=cam.ViewportSize;V:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,true,game,1);V:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,false,game,1)end)end
    D:AddItem(bg,0.15);if not allFlames then break end
   end
  else scytheParts[fl]=nil;flameCD[fl]=nil end
 end
end

-- ===== FEATURE 3: goTo — Momentum Strafing + Overshoot =====
local function goTo(tP,rad,to,sk)
 rad=math.min(rad or 1.5,2.5)
 to=to or MT;if to>12 then to=12 end;if tP==ZERO then return false end
 local r=h();local hm_=hm();if not r or not hm_ then return false end
 tP=cP(tP,sk);local oT=Vector3.new(tP.X,r.Position.Y,tP.Z);local cM=oT
 local av=cAT(r.Position,oT,sk);if av then cM=Vector3.new(av.X,r.Position.Y,av.Z)end
 local function moveFast()
  local dir=(cM-r.Position).Unit
  local vel=r.AssemblyLinearVelocity;local flatVel=Vector3.new(vel.X,0,vel.Z)
  -- FEATURE 3: Momentum strafe — если скорость >10 и угол < 90°, делаем дугу
  if flatVel.Magnitude>10 and dir:Dot(flatVel.Unit)>0.5 then
   local strafeDir=(dir+flatVel.Unit*0.5).Unit
   hm_:MoveTo(cM+Vector3.new(strafeDir.X*3,0,strafeDir.Z*3))
  else
   if dir.Magnitude>0 then hm_:MoveTo(cM+Vector3.new(dir.X*2,0,dir.Z*2))else hm_:MoveTo(cM)end
  end
 end
 moveFast()
 local t0=os.clock();local lA=os.clock();local hb0=hbF
 while os.clock()-t0<to do
  if hbF-hb0>to*60 then return false end
  task.wait(0.03);if not ENABLED or INT then return false end
  r=h();if not r then return false end
  pcall(hitBloom);pcall(hitFlames)
  if d2Sq(r.Position,oT)<=(rad*rad)then
   -- FIX #2: blacklist tokens we just passed through
   for p,_ in pairs(aT)do if p and p.Position and d2Sq(r.Position,p.Position)<=4 then tokenBL[p]=os.clock()+1.2 end end
   return true end
  if os.clock()-lA>=0.1 then
   lA=os.clock();local na=cAT(r.Position,oT,sk)
   cM=na and Vector3.new(na.X,r.Position.Y,na.Z)or oT
   moveFast()
  end
 end
 return false
end

-- ===== standOnPurple — Non-blocking =====
local function standOnPurple(ch,timeout)
 local r=h();local hm_=hm();if not r or not hm_ or not ch.part.Parent then return false end
 tL="P Stand";INT=false;hm_:MoveTo(ch.part.Position)
 local t0=os.clock()
 while os.clock()-t0<timeout do
  task.wait(0.03)
  r=h();if not r or not ch.part.Parent then break end
  if INT or not ENABLED then return false end
  pcall(hitBloom);pcall(hitFlames)
  if d2Sq(r.Position,ch.part.Position)<=9 then hm_:MoveTo(ch.part.Position)
  else local dir=(ch.part.Position-r.Position).Unit;hm_:MoveTo(ch.part.Position+Vector3.new(dir.X*1.5,0,dir.Z*1.5))end
 end
 if not ch.part.Parent then ch.col=true;st.pr=st.pr+1;lP=ch.part;st.chP=st.chP+1;return true end
 return false
end

-- TOKEN REG + TIMERS
local function cT(part,id,tl,dp,df)if activeTG[part]then return end;local gui=Instance.new("BillboardGui");gui.Adornee=part;gui.Size=UDim2.new(0,80,0,24);gui.StudsOffset=Vector3.new(0,2,0);gui.AlwaysOnTop=true;gui.Parent=part;local lb=Instance.new("TextLabel",gui);lb.Size=UDim2.new(1,0,1,0);lb.BackgroundTransparency=0.2;lb.BackgroundColor3=df.bg or Color3.new(0,0,0);lb.TextColor3=dp and(df.dc or df.nc or Color3.new(1,1,1))or(df.nc or Color3.new(1,1,1));lb.TextScaled=true;lb.Font=Enum.Font.SourceSansBold;lb.Text=(df.pre or"")..string.format("%.1f",tl);activeTG[part]={gui=gui,label=lb,startTime=os.clock(),totalLifetime=tl,prefix=df.pre or""}end
local function rT(o)if o.Name~="C"or not o:IsA("BasePart")or aT[o]or tokenBL[o]then return end;local fr=o:FindFirstChild("FrontDecal");if not fr or not fr:IsA("Decal")then return end;local id=ti(fr.Texture);if not id or AV[id]then return end;local df=TKS[id];if not df then return end;local r=h();local dp=false;if r then dp=(o.Position.Y-r.Position.Y)>5 end;local lf=df.base*AM;if dp then lf=lf*(2+0.05*(DGL-1));dupCnt=dupCnt+1 end;aT[o]={id=id,n=df.n,p=df.p,mo=df.mo or false,s=os.clock(),l=lf,dp=dp,col=false};tokenVerify[o]=(os.clock()+0.5);cT(o,id,lf,dp,df)end
W.DescendantAdded:Connect(function(o)if o.Name=="C"then pcall(rT,o)end end)
do for _,o in ipairs(W:GetDescendants())do pcall(rT,o)end end
game.DescendantRemoving:Connect(function(o)if aT[o]then if aT[o].col then st.tk=st.tk+1 end;if aT[o].dp then dupCnt=math.max(0,dupCnt-1)end;aT[o]=nil end;if activeTG[o]then pcall(function()if activeTG[o].gui then activeTG[o].gui:Destroy()end end);activeTG[o]=nil end;if scytheParts[o]then scytheParts[o]=nil;flameCD[o]=nil end;tokenVerify[o]=nil end)
R.Heartbeat:Connect(function()local now=os.clock();for p,d in pairs(activeTG)do if p and p.Parent and d and d.label then local r2=d.totalLifetime-(now-d.startTime);if r2>0 then d.label.Text=d.prefix..string.format("%.1f",r2);if r2<3.0 then d.label.TextColor3=Color3.new(1,0.3,0.3)end elseif r2<=0 then d.label.Text=d.prefix.."0.0"end else pcall(function()if d and d.gui then d.gui:Destroy()end end);activeTG[p]=nil end end end)
local function verifyTokens()local n=os.clock();local r=h();if not r then return end;for p,v in pairs(tokenVerify)do if n>v then if p and p.Parent and aT[p]and aT[p].col then local d=d3(r.Position,p.Position);if d<15 then aT[p].col=false;tokenVerify[p]=n+3 end end end end end
local function cBT(pos,radius)local c=0;for p,t in pairs(aT)do if not t.col and p.Parent then if d3(p.Position,pos)<=radius then if TKS[t.id]and TKS[t.id].bt then c=c+1 end end end end;return c end

-- BUFF POLLING
local rps=nil;local PAE=nil
do local e=RS:FindFirstChild("Events");if e then rps=e:FindFirstChild("RetrievePlayerStats");PAE=e:FindFirstChild("PlayerAbilityEvent")end end
if PAE then PAE.OnClientEvent:Connect(function(data)if type(data)~="table"then return end;for tag,info in pairs(data)do if type(tag)=="string"and type(info)=="table"and info.Action=="Update"and info.Values then local sts=info.Values[1];if sts then local lower=tag:lower();if lower:find("flame")then xfP=sts elseif lower:find("scorching")then scP=sts end end end end end)end
local function fb(t,d)if type(t)~="table"then return end;local bid=rawget(t,"BuffID");if bid then d[bid]=t end;local src=rawget(t,"Src");if src then d[src]=t end;for _,val in pairs(t)do if type(val)=="table"then fb(val,d)end end end
local function pAB()
 if not rps then return end;local ok,res=pcall(function()return rps:InvokeServer()end);if not ok or type(res)~="table"then return end;local fd={};fb(res,fd)
 local prevSS=aB.SS.st;local ss=fd["Scorching Star Aura"];if ss and rawget(ss,"Removed")~=true then aB.SS.st=tonumber(rawget(ss,"Combo")or 0)or 0 else aB.SS.st=0;if scP>0 then scP=0 end end
 local xf=fd["X-Flame Aura"];if xf and rawget(xf,"Removed")~=true then aB.XF.st=tonumber(rawget(xf,"Combo")or 0)or 0 else aB.XF.st=0;if xfP>0 then xfP=0 end end
 aB.PM.a=(fd[2575093099]and rawget(fd[2575093099],"Removed")~=true)
 local pm=fd[PMBI];if pm and rawget(pm,"Removed")~=true then aB.PoM.a=true;aB.PoM.m=tonumber(rawget(pm,"Combo")or 0)or 1;if aR then aB.PoM.pos=aR.Position end else aB.PoM.a=false;aB.PoM.m=0 end
 local plm=fd[PLMBI];if plm and rawget(plm,"Removed")~=true then pollMS=tonumber(rawget(plm,"Combo")or rawget(plm,"Value")or 0)or 0;aB.PollM.combo=pollMS;aB.PollM.active=(aB.PollM.combo>=3);if aB.PollM.active and aR then aB.PollM.ringPos=aR.Position end else pollMS=0;aB.PollM.active=false;aB.PollM.combo=0 end
 local fc=fd[FOCI];if fc and rawget(fc,"Removed")~=true then aB.FC.combo=tonumber(rawget(fc,"Combo")or 0)or 0;aB.FC.dur=tonumber(rawget(fc,"Dur")or 20)or 20;local fcStart=tonumber(rawget(fc,"Start")or os.clock())or os.clock();aB.FC.tL=math.max(0,aB.FC.dur-(os.clock()-fcStart))else aB.FC.combo=0;aB.FC.tL=0 end
 local rb=fd[RBOI];if rb and rawget(rb,"Removed")~=true then aB.RB.combo=tonumber(rawget(rb,"Combo")or 0)or 0;aB.RB.dur=tonumber(rawget(rb,"Dur")or 15)or 15;local rbStart=tonumber(rawget(rb,"Start")or os.clock())or os.clock();aB.RB.tL=math.max(0,aB.RB.dur-(os.clock()-rbStart))else aB.RB.combo=0;aB.RB.tL=0 end
 local b=fd[PBI]or fd["Precision"];if b and rawget(b,"Removed")~=true then local rv=rawget(b,"Value");prec.val=tonumber(rv or 0)or 0;local ns=0;if prec.val>0 then ns=math.min(PMX,math.round(prec.val/PPK))end;prec.isX=(ns>=PMX);local bd=tonumber(rawget(b,"Dur")or 60)or 60;prec.sD=bd;local bStart=tonumber(rawget(b,"Start"));if ns~=prec.st or(bStart and bStart~=prec.sS)then prec.st=ns;prec.ls=os.clock();if bStart then prec.sS=bStart end;if prec.isX then prec.nR=false;rCC=0 end end else prec.st=0;prec.val=0;prec.isX=false;prec.ls=0;prec.tL=0;prec.nR=false end
 if prec.ls>0 then prec.tL=math.max(0,prec.sD-(os.clock()-prec.ls));prec.nR=prec.isX and(prec.tL<=PRAT);if prec.nR and rCC==0 then rST=os.clock();rCC=0 end end
 local curH=getHoney()
 if aB.SS.st>0 and prevSS==0 then scorchStartH=curH;scorchStartT=os.clock();scorchActive=true;scorchRecording=true;scorchActions={};scorchDupedMorphDone=false;scorchPurpleCount=0;scorchPurpleTime=0;scorchAllCHMode=false;scorchPurpleTotal=0;scorchTPIndex=0;scorchTPTable={};scorchTPCycle=false elseif aB.SS.st==0 and prevSS>0 then scorchActive=false;if scorchRecording and scorchStartT>0 then local gained=curH-scorchStartH;local dur=(os.clock()-scorchStartT)/60;if gained>0 then table.insert(scorchSessions,{honeyGained=gained,honeyGainedFmt=fmtH(gained),durationMin=math.floor(dur*10)/10,time=os.clock(),ssCombo=prevSS,ctx=getCK(),actions=scorchActions,purpleTotal=scorchPurpleTotal});if gained>bestSH then bestSH=gained end end;scorchRecording=false;scorchActions={}end end
end

-- SCANNERS
local function gPC(p)for nxt,co in pairs(PC)do if(co.R-p.Color.R)^2+(co.G-p.Color.G)^2+(co.B-p.Color.B)^2<0.002 then return nxt end end;return nil end
local function sPt()fP={};if not ENABLED or not curF then return end;local pt=W:FindFirstChild("Particles");if not pt then return end;local r=h();if not r then return end;for _,o in ipairs(pt:GetChildren())do if o.Name=="PetalPart"and o:IsA("BasePart")and iF(o.Position)then local cn=gPC(o);if cn and PP[cn]then table.insert(fP,{part=o,cn=cn,pr=PP[cn],dist=d3d(r.Position,o.Position)})end end end;if redPT>0 then local rem=8.0-(os.clock()-redPT);if rem>0 and rem<4.0 then for _,fp in ipairs(fP)do if fp.cn=="Red"then fp.pr=0 end end elseif rem<=0 then redPT=0 end;table.sort(fP,function(a,b)if a.pr~=b.pr then return a.pr<b.pr end;return a.dist<b.dist end)end end
local function sSm()local n=os.clock();smT=nil;smTR=math.huge;local r=h();if not r then return end;if dupCnt<6 then return end;for p,t in pairs(aT)do if not t.col and p.Parent and t.id==SMI then local rem=t.l-(n-t.s);if rem>0 and rem<smTR then smT=p;smTR=rem end end end;if smT and not isCS then INT=true end end
local function gPB(action,pos)if#pH==0 then return 0 end;local be=0;for i=1,#pH do for j=1,#pH[i].actions do local pa=pH[i].actions[j];if pa.action==action and d2Sq(pos,pa.pos)<100 then local ms=1;if pa.phase==ph()then ms=ms*2 end;if pa.isSc and aB.SS.st>0 then ms=ms*2 end;if pa.scPh==scPh()then ms=ms*1.5 end;if ms>be then be=ms end end end end;return 15*be end
local function rT10()local now=os.clock();local rec={};for i=1,#scorchSessions do if now-scorchSessions[i].time<=PAT_WINDOW then table.insert(rec,scorchSessions[i])end end;table.sort(rec,function(a,b)return a.honeyGained>b.honeyGained end);top10={};for j=1,math.min(PAT_TOP,#rec)do top10[j]=rec[j]end end
local function sSS()if not writefile then return end;if os.clock()-lastPS<120 then return end;lastPS=os.clock();rT10();pcall(function()writefile("marmot_z_scorch.json",H:JSONEncode({scorchSessions=scorchSessions,bestScorch=bestSH,top10=top10}))end)end
local function gPB2(action)local ctx=getCK();local bias=1.0;for i=1,#top10 do if top10[i].ctx==ctx then for j=1,#top10[i].actions do if top10[i].actions[j].action==action and SCORCH_BIAS>bias then bias=SCORCH_BIAS;break end end end end;return bias end
local function rSA(action)if not scorchRecording then return end;local r=h();local dc=dupCnt;if action=="go_smile"then dc=0;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id~=SMI then dc=dc+1 end end end;table.insert(scorchActions,{action=action,pos=r and r.Position or ZERO,phase=ph(),pm=math.min(3,aB.PoM.m),ssCombo=aB.SS.st,duped=dc})end
local function scS()local pf=W:FindFirstChild("PlayerFlames");if not pf then return end;for fl,_ in pairs(scytheParts)do if not fl.Parent then scytheParts[fl]=nil;flameCD[fl]=nil end end;for _,f in ipairs(pf:GetChildren())do local nm=f.Name or"";if nm:sub(1,3)=="Flm"or nm:find("Scythe")or nm:find("Flame")then if not scytheParts[f]then scytheParts[f]={sT=os.clock(),hit=false}end end end end
-- PETAL CLUSTER
local PETAL_CLUSTER_R=12;local PETAL_CLUSTER_MIN=4
local function gPetCluster()if#fP<PETAL_CLUSTER_MIN then return nil end;local clusters={};local used={}
 for i=1,#fP do if not used[i]then local cl={fP[i]};used[i]=true
  local changed=true;while changed do changed=false
   for j=1,#fP do if not used[j]then for _,m in ipairs(cl)do if d3(m.part.Position,fP[j].part.Position)<=PETAL_CLUSTER_R then table.insert(cl,fP[j]);used[j]=true;changed=true;break end end end end end
  if#cl>=PETAL_CLUSTER_MIN then local cx,cz=0,0;for _,m in ipairs(cl)do cx=cx+m.part.Position.X;cz=cz+m.part.Position.Z end;table.insert(clusters,{center=Vector3.new(cx/#cl,0,cz/#cl),size=#cl,members=cl})end end end
 table.sort(clusters,function(a,b)return a.size>b.size end);return#clusters>0 and clusters or nil end
local function hTL()for p,t in pairs(aT)do if not t.col and p.Parent and t.p>=90 then if t.dp then if os.clock()-lastTLT>3.0 then return true end else return true end end end;return false end
local function gDTP()local n=os.clock();for p,t in pairs(aT)do if not t.col and p.Parent and t.id==TPI and t.dp and t.l-(n-t.s)>1 then return p,t end end;return nil,nil end
local function gSDA()local r=h();if not r then return nil end;local rp=aR and aR.Position;if not rp then return nil end;local bs=nil;local bd=math.huge;local bt=nil;local btd=math.huge;for p,t in pairs(aT)do if not t.col and p.Parent then if d3(p.Position,rp)<=aRR*1.5 then local d=d3(r.Position,p.Position);if t.id==SMI and d<bd then bd=d;bs=p end;if t.id==TPI and t.dp and d<btd then btd=d;bt=p end end end end;if bs and bt then local stt=aT[bs];return(stt and(stt.l-(os.clock()-stt.s))<=3)and bs or bt end;return bs or bt end
local function eS()local r=h();if not r then return"dead"end;local p_=ph();local tlD="none";for p,t in pairs(aT)do if not t.col and p.Parent and t.p>=90 then local d=d3(r.Position,p.Position);if d<20 then tlD="close"elseif d<60 then tlD="far"end end end;local prN=math.min(3,#gCH(true,false,false));local rN=math.min(3,#gCH(false,true,false));local sU=(smT~=nil and"1"or"0");local hP=(#fP>0 and"1"or"0");local nT=false;local n=os.clock();for p,t in pairs(aT)do if not t.col and p.Parent and(t.l-(n-t.s))>1 and d3(r.Position,p.Position)<30 then nT=true;break end end;local zn="mid";if curF and curF.part and curF.part.Size then local c=curF.part.Position;local s=curF.part.Size;if s.X>0 and s.Z>0 then local rx=math.abs(r.Position.X-c.X)/(s.X/2);local rz=math.abs(r.Position.Z-c.Z)/(s.Z/2);if rx>0.7 or rz>0.7 then zn="edge"end;if rx<0.3 and rz<0.3 then zn="center"end end end;local chT="none";if prec.isX and not prec.nR then local ct=0;for i=1,#cQ do if not cQ[i].col and cQ[i].part.Parent and not cQ[i].isP and d3(r.Position,cQ[i].part.Position)<20 then ct=ct+1 end end;if ct>2 then chT="many"elseif ct>0 then chT="some"end end;local fcS=(aB.FC.combo>=10 and"1"or"0");local rbS=(aB.RB.combo>=10 and"1"or"0");return string.format("PH:%s|SC:%s|TL:%s|CH:%d|PR:%d|SM:%s|NT:%s|Z:%s|CT:%s|PT:%s|XF:%s|FC:%s|RB:%s|PM:%d|PLL:%d|SSp:%d|XFp:%d",p_,scPh(),tlD,rN,prN,sU,tostring(nT),zn,chT,hP,(aB.XF.st>=19 and"1"or"0"),fcS,rbS,math.min(3,aB.PoM.m),pollMS,scP,xfP)end
local function gSC()local cx,cz,ct=0,0,0;local dw=5;for fl,_ in pairs(scytheParts)do if fl and fl.Parent then local nm=fl.Name or"";local bn=sBC(fl);local isD=(nm:find("Dark")or bn=="Really black");local w=isD and dw or 1;cx=cx+fl.Position.X*w;cz=cz+fl.Position.Z*w;ct=ct+w end end;local dn=0;local r=h();if r then for fl,_ in pairs(scytheParts)do if fl and fl.Parent then if(fl.Name or""):find("Dark")or sBC(fl)=="Really black"then if d3(r.Position,fl.Position)<=SCYTHE_DIST*2 then dn=dn+1 end end end end end;if ct>0 then return Vector3.new(cx/ct,0,cz/ct),true,dn end;if curF and curF.part then return curF.part.Position,false,0 end;local r2=h();if r2 then return r2.Position,false,0 end;return ZERO,false,0 end

-- ===== ACTION BUILDER (Marmot Z v4.0) =====
local function gAWB()
 local ba={};local p_=ph();local n=os.clock();local isSc=(aB.SS.st>0);local isSS=(isSc and prec.isX and aB.PoM.m>=3 and pollMS>=3)
 local hdm=false;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.mo then hdm=true;break end end;local isSO=(not isSc)and prec.isX and hdm
 ndMorph=nil;for p,t in pairs(aT)do if not t.col and p.Parent and t.mo and not t.dp then ndMorph=p;break end end
 local hasDupedTL=false;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==1629547638 then hasDupedTL=true;break end end
 local cs=L:FindFirstChild("CoreStats");if cs then local cap=cs:FindFirstChild("Capacity");local pol=cs:FindFirstChild("Pollen");if cap and pol and cap.Value>0 and(pol.Value/cap.Value)>=0.9 then local pp=gPCH();if#pp>0 then return{"go_backpack_dump_purple"}end;local all=gCH(false,false,false);if#all>0 then return{"go_backpack_dump"}end end end
 local r=h()
 -- ===== FIX #6: Precise Bee prediction =====
 if not isSc then
  local predPos=predictPreciseShot()
  if predPos then return{"go_precise_predict"}end
 end
 -- ===== FIX #3: Diagonal Looting — 6+ CH → бежим по диагонали =====
 if#cQ>=6 and not xfE then
  local diag=gDiagonalLoot();if#diag>=6 then return{"go_diagonal_loot"}end end
 -- SHOWER absolute priority
 if r then for i=1,#activeShowers do local sh=activeShowers[i]
  if not sh.collected and sh.part.Parent and(n-sh.spawnTime)<1.2 then
   if d3(r.Position,sh.part.Position)<80 then return{"go_shower"}end end end end
 if r then for i=1,#activeShowers do local sh=activeShowers[i];if not sh.collected and sh.part.Parent and(n-sh.spawnTime)<0.8 and d3(r.Position,sh.part.Position)<60 then if not(prec.isX and prec.tL>0 and prec.tL<15)then return{"go_shower"}end end end end
 -- ===== FEATURE 5: XF Camping — если xfE активно, стоим в центре =====
 if xfE then
  if isSc then
   -- Если Scorch Star активен: стоим ровно 4 секунды с момента xfStartTime
   if n-xfStartTime<=4.0 then return{"go_xflame_center_camp"}end
   -- После 4 секунд — лутаем кроссхеиры
   local all=gCH(false,false,true);if#all>0 then return{"go_crosshair_all"}end
   return{"go_xflame_center_camp"}
  else
   -- Без Scorch: кемпим центр
   return{"go_xflame_center_camp"}
  end
 end
 -- ===== FEATURE 1: Predictive pre-positioning — идём к pPos CH =====
 if not isSc then
  local predCh=gCH_predict()
  if predCh and predCh.pPos then
   local dd=d2Sq(r.Position,predCh.pPos)
   if dd>36 then return{"go_predictive_ch"}end
  end
 end
 -- XF center
 if xfP>=22 and scP>=20 and not isSS then local cc=gFC();if cc~=ZERO and r and d3(r.Position,cc)>XCR*2 then return{"go_xflame_center"}end end
 -- Super Scorch
 if isSS then
  if scorchActive and scorchStartT>0 and(n-scorchStartT)>=35 then local all=gCH(false,false,true);if#all>0 then return{"go_crosshair_all"}end;local path=gFCPath(r.Position);if path then return{"go_flame_path"}end;return{"patrol_scorch_flames"}end
  for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==4519549299 then return{"go_duped_inferno_scorch"}end end
  if scorchActive and scorchStartT>0 and(n-scorchStartT)>=15 and not scorchDupedMorphDone then
   if smT and smT.Parent then return{"go_smile"}end
   for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.mo then return{"go_duped_morph_scorch"}end end end
  if scorchAllCHMode then
   for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==TPI then return{"go_duped_tp_scorch"}end end
   local all=gCH(false,false,true);if#all>0 then return{"go_crosshair_all"}end
   local path=gFCPath(r.Position);if path then return{"go_flame_path"}end
   return{"patrol_scorch_flames"}end
  if not scorchAllCHMode then
   if scorchPurpleCount>=3 then scorchAllCHMode=true;scorchPurpleTime=os.clock()
    local all=gCH(false,false,true);if#all>0 then return{"go_crosshair_all"}end
    local path=gFCPath(r.Position);if path then return{"go_flame_path"}end
    return{"patrol_scorch_flames"}end
   if scorchPurpleTime>0 and n-scorchPurpleTime>=1 then scorchAllCHMode=true;scorchPurpleTime=os.clock()
    local all=gCH(false,false,true);if#all>0 then return{"go_crosshair_all"}end
    local path=gFCPath(r.Position);if path then return{"go_flame_path"}end
    return{"patrol_scorch_flames"}end
   local pp=gCH(true,false,false);if#pp>0 then return{"go_purple_scorch"}end end
  if scorchTPCycle then
   if scorchTPIndex<#scorchTPTable then
    local tp_p=scorchTPTable[scorchTPIndex+1]
    if tp_p and tp_p.Parent and aT[tp_p]and not aT[tp_p].col then return{"go_scorch_tp_cycle"}end end
   scorchTPCycle=false;scorchTPIndex=0;scorchTPTable={}
   local all=gCH(false,false,true);if#all>0 then return{"go_crosshair_all"}end end
  local sc,_,_=gSC();if sc~=ZERO and r then local bt,bd=nil,math.huge;for p,t in pairs(aT)do if not t.col and p.Parent and t.p>=8 then local d=d3(p.Position,sc);if d<40 and d<bd then bd=d;bt=p end end end;if bt then return{"go_scorch_token"}end end
  local all2=gCH(false,false,true);if#all2>0 then return{"go_crosshair_all"}end
  local path2=gFCPath(r.Position);if path2 then return{"go_flame_path"}end
  return{"patrol_scorch_flames"}end
 if isSc and scorchStartT>0 and(n-scorchStartT)>=15 and not scorchDupedMorphDone then
  if smT and smT.Parent then return{"go_smile"}end
  for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.mo then return{"go_duped_morph_scorch"}end end end
 -- ===== FIX #5: Scorch — приоритет лепестков и флейм-кластеров =====
 if isSc and not isSS then
  local ptCl=gPetCluster();if ptCl and#ptCl>0 then return{"go_petal_cluster"}end
  if#fP>=4 then return{"go_petal"}end
  local clust=gFCB();if#clust>0 then
   local rPos=r.Position;local bestC,bestSz=nil,0
   for i=1,math.min(3,#clust)do if clust[i].size>bestSz and clust[i].size>=6 then bestSz=clust[i].size;bestC=clust[i].center end end
   if bestC then return{"go_flame_cluster_center"}end
  end
  local sc,_,_=gSC();if sc~=ZERO then
   local nearbyTokens=0;for p,t in pairs(aT)do if not t.col and p.Parent and d3(p.Position,sc)<20 then nearbyTokens=nearbyTokens+1 end end
   if nearbyTokens==0 and d3(r.Position,sc)>6 then return{"patrol_scorch_flames"}end
  end
 end
 if isSO then
  if n-lastSOTime>=10 then return{"go_super_outside"}end
  local nearCH=gCH_n();if nearCH and not smT and not xfE then return{"go_crosshair"}end
  if hTL()then return{"go_tokenlink"}end
  for i,coco in ipairs(activeCocos)do if not coco.collected and coco.part.Parent and(3.0-(n-coco.spawnTime))<=1.0 then return{"go_coconut"}end end
  if aB.PoM.a and aR then local t=gSDA();if t then local td=aT[t];if td and td.id==TPI and td.dp then return{"go_dup_area"}end end end
  if p_=="REFRESH"then local all=gCH(false,false,true);if#all>0 then return{"go_crosshair_refresh_all"}end;return{"patrol_ring"}end
  if p_=="X10"then return{"patrol_ring"}end
  local tpBuild=gTPG_build();if tpBuild then return{"go_build_precision"}end
  local aCH=gCH(false,false,false);if#aCH>0 then table.insert(ba,"go_crosshair")end
  if#fP>0 then table.insert(ba,"go_petal")end
  if next(aT)~=nil then table.insert(ba,"go_token_near");table.insert(ba,"go_token_best")end
  table.insert(ba,"patrol_ring");return ba end
 if p_=="X10"and xfP>=19 and not isSS and not isSO then
  local cc=gFC();if cc~=ZERO then local bC=gCH_nc();if bC then return{"go_center_ch"}end end
  for p,t in pairs(aT)do if not t.col and p.Parent and TKS[t.id]and TKS[t.id].bt and d3(p.Position,gFC())<XCR*2 then table.insert(ba,1,"go_center_bt")end end
  if#ba>0 then return ba end;return{"go_xflame_center"}end
 if ndMorph and not hasDupedTL and not isSc and not isSO then
  local hasSmiles=false;for p,t in pairs(aT)do if not t.col and p.Parent and t.id==SMI then hasSmiles=true;break end end
  if hasSmiles then return{"go_smile_stand"}end
  return{"go_noduped_morph"}end
 for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.mo then local rem=t.l-(n-t.s);if rem<7 and rem>0 and not isSO then return{"go_duped_morph"}end end end
 if isSc then
  for p,t in pairs(aT)do if not t.col and p.Parent and t.id==2000457501 and t.dp and(n-t.s)>2.0 then return{"go_duped_inspire_scorch"}end end
 else
  for p,t in pairs(aT)do if not t.col and p.Parent and t.dp then local age=n-t.s;local rem=t.l-age
   if t.id==2000457501 and rem<2.0 and rem>0 then return{"go_duped_inspire_normal"}
   elseif t.id==1472256444 and rem<5.0 and rem>0 then return{"go_duped_babylove"}
   elseif(t.id==8173559749 or t.id==1442859163 or t.id==1442863423 or t.id==3877732821)and age>3 and rem>0 then return{"go_duped_boost"}end end end end
 if smT and dupCnt>=6 and dupCnt>=9 then return{"go_smile"}end
 if dupCnt>=9 then
  local dupedList={};for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and DPRI[t.id]then table.insert(dupedList,{p=p,t=t,age=n-t.s})end end
  if#dupedList>=3 and math.random()<0.6 then return{"go_duped_multi"}end
  local cc=gFC();local bp,bd=nil,math.huge;for _,de in ipairs(dupedList)do local d=d3(de.p.Position,cc);if d<bd then bd=d;bp=de.p end end
  if bp then return{"go_duped_pri"}end end
 if p_=="X10"and not isSO then local pp=gCH(true,false,false);if#pp>0 then return{"go_purple"}end end
 local ptCl=gPetCluster();if ptCl and#ptCl>0 then return{"go_petal_cluster"}end
 if xfP==0 and scP>=24 and not isSc then
  if scP<27 then return{"go_xflame_center"}end
  local all2=gCH(false,false,true);if#all2>0 then return{"go_crosshair_all"}end
  return{"patrol_ring"}end
 local nearCH=gCH_n()
 if nearCH and not smT and not xfE and not isSS and not isSO then
  local hasPurp=hasNearPurpleCH()
  if hasPurp and not nearCH.isP then
   local pp=gCH(true,false,false);if#pp>0 then return{"go_purple"}end
   if not prec.isX then return{"go_purple"}end end
  return{"go_crosshair"}end
 if hTL()then return{"go_tokenlink"}end
 for i,coco in ipairs(activeCocos)do if not coco.collected and coco.part.Parent and(3.0-(n-coco.spawnTime))<=1.0 then return{"go_coconut"}end end
 if smT and dupCnt>=6 and not isSO then return{"go_smile"}end
 if aB.PoM.a and aR then local t=gSDA();if t then local td=aT[t];if td and td.id==SMI then table.insert(ba,1,"go_smile_area")elseif td and td.id==TPI and td.dp then table.insert(ba,1,"go_dup_area")end end end
 if p_=="REFRESH"then local all=gCH(false,false,true);if#all>0 then return{"go_crosshair_refresh_all"}end;return{"patrol_ring"}end
 if p_=="X10"then return{"patrol_ring"}end
 if p_=="NABOR"then
  if hTL()then return{"go_tokenlink"}end
  local tpBuild=gTPG_build();if tpBuild then return{"go_build_precision"}end
  for p,t in pairs(aT)do if not t.col and p.Parent and not tokenBL[p]and t.id==TPI and not t.dp then return{"go_token_best"}end end
  for p,t in pairs(aT)do if not t.col and p.Parent and not tokenBL[p]and(t.id==2499514197 or t.id==2499540966)then tL="HM/PM";INT=false;if goTo(p.Position,5,5)and p.Parent then t.col=true;tokenBL[p]=os.clock()+1.2;st.tk=st.tk+1 end;break end end
  for p,t in pairs(aT)do if not t.col and p.Parent and not tokenBL[p]and t.id==4528379338 then tL="MS";INT=false;if goTo(p.Position,5,5)and p.Parent then t.col=true;tokenBL[p]=os.clock()+1.2;st.tk=st.tk+1 end;break end end
  for p,t in pairs(aT)do if not t.col and p.Parent and not tokenBL[p]and(t.id==1442859163 or t.id==1442863423 or t.id==3877732821)then tL="Boost";INT=false;if goTo(p.Position,5,5)and p.Parent then t.col=true;tokenBL[p]=os.clock()+1.2;st.tk=st.tk+1 end;break end end
  local aCH=gCH(false,false,false);if#aCH>0 then table.insert(ba,"go_crosshair")end
  local ptCl=gPetCluster();if ptCl then table.insert(ba,"go_petal_cluster")end;if#fP>0 then table.insert(ba,"go_petal")end
  for fl,data in pairs(scytheParts)do if fl and fl.Parent then local nm=fl.Name or"";local bn=sBC(fl);if not(nm:find("Dark")or bn=="Really black")then local cd=flameCD[fl];if(not cd or n>=cd)and data and(n-data.sT)>2.0 then table.insert(ba,"go_touch_flame");break end end end end
  if next(aT)~=nil then table.insert(ba,"go_token_best");table.insert(ba,"go_token_near")end
  local dt,_=gDTP();if dt then table.insert(ba,"go_dup_tp")end
  table.insert(ba,"patrol_ring");return ba end
 return{"patrol_ring"}
end

-- UCB
local function cAB(s)local v=gAWB();if#v==0 then return"patrol_ring"end;if math.random()<EP then return v[math.random(1,#v)]end;if not visitCount[s]then visitCount[s]={}end;local bA,bS=v[1],-math.huge;for i=1,#v do local act=v[i];local qV=gQ(s,act)*gPB2(act);local nv=visitCount[s][act]or 0;local ub=UCB_C*math.sqrt(math.log(totalSteps+1)/(nv+1));local sc=qV+ub;if sc>bS then bA=act;bS=sc end end;visitCount[s][bA]=(visitCount[s][bA]or 0)+1;return bA end

-- ===== FEATURE 4: dUQ — Reward Shaping + Prioritized Experience Replay =====
local replayBuffer={};local replayMaxSize=100;local replayIndex=1
local function dUQ(s,a,rw,ns)
 local r=h();local tR=rw+flHit*2+chStick*1;if aborted then tR=tR-5 end
 local now=os.clock();local comboMult=1;if lastActionTime>0 then
  local dt=now-lastActionTime;if dt<0.2 then comboMult=1.5 end
  tR=(tR-(math.exp(dt*0.8)*0.5))*comboMult
 end;lastActionTime=now
 if not eligibility[s]then eligibility[s]={}end
 for stt,acts in pairs(eligibility)do for act,trace in pairs(acts)do eligibility[stt][act]=trace*0.95*0.7;if eligibility[stt][act]<0.001 then eligibility[stt][act]=nil end end end
 eligibility[s][a]=(eligibility[s][a]or 0)+1
 local v=gAWB();local mN=0;for i=1,#v do local q=gQ(ns,v[i]);if q>mN then mN=q end end
 local tdError=tR+0.95*mN-gQ(s,a)
 for stt,acts in pairs(eligibility)do for act,trace in pairs(acts)do sQ(stt,act,gQ(stt,act)+0.5*tdError*trace)end end
 -- Replay Buffer
 replayBuffer[replayIndex]={s=s,a=a,tR=tR,ns=ns,err=math.abs(tdError)};replayIndex=(replayIndex%replayMaxSize)+1
 if totalSteps%5==0 and#replayBuffer>10 then
  local temp={};for i=1,#replayBuffer do table.insert(temp,replayBuffer[i])end;table.sort(temp,function(r1,r2)return r1.err>r2.err end)
  for i=1,math.min(3,#temp)do local exp=temp[i];local exp_mN=0;for j=1,#v do local q2=gQ(exp.ns,v[j]);if q2>exp_mN then exp_mN=q2 end end;local exp_tdError=exp.tR+0.95*exp_mN-gQ(exp.s,exp.a);sQ(exp.s,exp.a,gQ(exp.s,exp.a)+0.5*exp_tdError*0.8)end
 end
 st.tR=st.tR+tR;st.dc=st.dc+1;totalSteps=totalSteps+1;EP=math.max(0.02,EP*ED);flHit=0;chStick=0;aborted=false
end

local function soCH(ch,dur)local r=h();local hm_=hm();if not r or not hm_ then return end;lootAnim(ch.part.Position,dur);hm_:MoveTo(Vector3.new(ch.part.Position.X,r.Position.Y,ch.part.Position.Z));local t0=os.clock();while os.clock()-t0<dur do task.wait(0.05);if not ch.part.Parent then break end end;if ch.part.Parent and not ch.col then ch.col=true;st.chP=st.chP+1;if ch.isP then st.pr=st.pr+1 else st.ch=st.ch+1 end end end

-- EXECUTE
local function stToken(p)if not p or not p.Parent then return end;local t0=os.clock();while os.clock()-t0<1.1 do task.wait(0.05);if not p.Parent then break end;local h__=hm();if h__ then h__:MoveTo(Vector3.new(p.Position.X,p.Position.Y,p.Position.Z))end end end
local function eA(action)
 local r=h();if not r then return-1 end;tL=action;rSA(action)
 pcall(hitBloom);pcall(hitFlames)
 -- ===== FEATURE 1: go_predictive_ch — бежим к pPos =====
 if action=="go_predictive_ch"then local pch=gCH_predict();if not pch or not pch.pPos then return-1 end;tL="P-Pos";INT=false;if goTo(Vector3.new(pch.pPos.X,r.Position.Y,pch.pPos.Z),2.5,4)then return 5 end;return-2 end
 -- ===== FIX #6: go_precise_predict — бежим к позиции предсказанной Precise Bee =====
 if action=="go_precise_predict"then local pp=predictPreciseShot();if not pp then return-1 end;tL="PreBee";INT=false;if goTo(Vector3.new(pp.X,r.Position.Y,pp.Z),2.5,4)then return 8 end;return-2 end
 -- ===== FIX #3: go_diagonal_loot — лутаем CH по диагонали =====
 if action=="go_diagonal_loot"then local diag=gDiagonalLoot();if#diag==0 then return-1 end;local rw=0;INT=false;for i=1,#diag do local ch=diag[i];if ch.part.Parent and not ch.col then if goTo(ch.part.Position,3,2.5,(ch.isP or nil))and ch.part.Parent then ch.col=true;if ch.isP then st.pr=st.pr+1;rw=rw+20 else st.ch=st.ch+1;rw=rw+10 end end end end;return rw>0 and rw or-2 end
 -- ===== FIX #5: go_flame_cluster_center — стоим в центре кластера =====
 if action=="go_flame_cluster_center"then local clust=gFCB();if#clust==0 then return-1 end;local bestC,bestSz=nil,0;for i=1,math.min(3,#clust)do if clust[i].size>bestSz then bestSz=clust[i].size;bestC=clust[i].center end end;if not bestC then return-1 end;tL="FlClust";INT=false;goTo(Vector3.new(bestC.X,r.Position.Y,bestC.Z),3,3);local st_=os.clock();while os.clock()-st_<1.5 do task.wait(0.05);pcall(hitFlames);pcall(hitBloom);if INT or not ENABLED then break end end;return 10+bestSz end
 -- ===== FEATURE 5: go_xflame_center_camp — кемпим центр =====
 if action=="go_xflame_center_camp"then local cc=gFC();if cc==ZERO then return-1 end;tL="XF Camp";INT=true;local hh=hm();if hh then
  local dir=(cc-Vector3.new(r.Position.X,0,r.Position.Z)).Unit
  if dir.Magnitude>0 then hh:MoveTo(cc+Vector3.new(dir.X*1,0,dir.Z*1))else hh:MoveTo(cc)end
 end;task.wait(0.15);return 2 end
 if action=="go_flame_path"then local path=gFCPath(r.Position);if not path then return-1 end;tL="FPth";INT=false;local rw=0;for i=1,#path do local wp=path[i];if goTo(Vector3.new(wp.X,r.Position.Y,wp.Z),4,2.5)then rw=rw+5;local st_=os.clock();while os.clock()-st_<0.5 do task.wait(0.05);pcall(hitFlames);pcall(hitBloom)end else break end end;if rw>0 then local sc,_,_=gSC();if sc~=ZERO then goTo(Vector3.new(sc.X,r.Position.Y,sc.Z),5,2)end end;return rw>0 and rw+5 or-2 end
 if action=="go_smile_stand"then local bp=nil;local bd=math.huge;for p,t in pairs(aT)do if not t.col and p.Parent and t.id==SMI then local d=d3(r.Position,p.Position);if d<bd then bd=d;bp=p end end end;if bp then tL="Sm 1.1";INT=false;if goTo(bp.Position,4,4)and bp.Parent then stToken(bp);if aT[bp]then aT[bp].col=true;st.sm=st.sm+1 end;return 20 end end;return-2 end
 if action=="go_noduped_morph"then if not ndMorph or not ndMorph.Parent then return-1 end;local t=aT[ndMorph];if not t then return-1 end;tL="MO(gnd)";INT=false;if goTo(ndMorph.Position,4,4)and ndMorph.Parent then stToken(ndMorph);t.col=true;return 20 end;return-2 end
 if action=="go_duped_inferno_scorch"then local bp=nil;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==4519549299 then bp=p;break end end;if bp then tL="IF(Sc)";INT=false;if goTo(bp.Position,4,3)and bp.Parent then stToken(bp);if aT[bp]then aT[bp].col=true end;return 25 end end;return-2 end
 if action=="go_scorch_tp_cycle"then local tp_p=scorchTPTable[scorchTPIndex+1];if not tp_p or not tp_p.Parent or not aT[tp_p]or aT[tp_p].col then scorchTPCycle=false;return-1 end;scorchTPIndex=scorchTPIndex+1;tL="TP-CH";INT=false;if goTo(tp_p.Position,4,3)and tp_p.Parent then stToken(tp_p);if aT[tp_p]then aT[tp_p].col=true;st.tk=st.tk+1 end;scorchTPCycle=false;scorchTPIndex=0;scorchTPTable={};return 25 end;scorchTPCycle=false;return-2 end
 if action=="go_duped_boost"then local bp=nil;local bd=math.huge;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp then local id=t.id;if id==1442859163 or id==1442863423 or id==3877732821 or id==8173559749 then local d=d3(r.Position,p.Position);if d<bd then bd=d;bp=p end end end end;if bp then tL="D Boost";INT=false;if goTo(bp.Position,4,3)and bp.Parent then stToken(bp);if aT[bp]then aT[bp].col=true;st.tk=st.tk+1 end;return 15 end end;return-2 end
 if action=="go_duped_pri"then local cc=gFC();local bp,bd=nil,math.huge;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and DPRI[t.id]then local d=d3(p.Position,cc);if d<bd then bd=d;bp=p end end end;if bp then tL="D Pr";INT=false;if goTo(bp.Position,4,3)and bp.Parent then local t0=os.clock();while os.clock()-t0<0.8 do task.wait(0.05);if not bp.Parent then break end end;if aT[bp]then aT[bp].col=true end;return 12 end end;return-2 end
 if action=="go_duped_multi"then local dupedList={};for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and DPRI[t.id]then table.insert(dupedList,{p=p,t=t})end end;if#dupedList<2 then return-1 end;table.sort(dupedList,function(a,b)return d3(r.Position,a.p.Position)<d3(r.Position,b.p.Position)end);local rw=0;INT=false;for i=1,math.min(3,#dupedList)do local de=dupedList[i];if de.p.Parent and not de.t.col then tL="DM"..i;if goTo(de.p.Position,4,3)and de.p.Parent then stToken(de.p);if aT[de.p]then aT[de.p].col=true;rw=rw+10 end end end end;return rw>0 and rw or-2 end
 if action=="go_duped_morph_scorch"then local bp=nil;for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.mo then bp=p;break end end;if bp then tL="MO(Sc)";INT=false;if goTo(bp.Position,4,3)and bp.Parent then stToken(bp);if aT[bp]then aT[bp].col=true;scorchDupedMorphDone=true end;return 30 end end;return-2 end
 if action=="go_duped_tp_scorch"then for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==TPI then tL="TP(Sc)";INT=false;if goTo(p.Position,4,3)and p.Parent then stToken(p);if aT[p]then aT[p].col=true end;scorchTPTable={};scorchTPIndex=0;for p2,t2 in pairs(aT)do if not t2.col and p2.Parent and t2.dp and t2.id==TPI and p2~=p then table.insert(scorchTPTable,p2)end end;if#scorchTPTable>0 then scorchTPCycle=true;scorchTPIndex=0 end;return 25 end end end;return-2 end
 if action=="go_purple_scorch"then local pp=gCH(true,false,false);if#pp==0 then return-1 end;local ch=pp[1];if ch.part.Parent and not ch.col then tL="P ScC";INT=false;if goTo(ch.part.Position,4,3,true)and ch.part.Parent then ch.col=true;st.pr=st.pr+1;scorchPurpleCount=scorchPurpleCount+1;scorchPurpleTotal=scorchPurpleTotal+1;scorchPurpleTime=os.clock();return 20 end end;return-2 end
 if action=="go_smile"then for fl,data in pairs(scytheParts)do if fl and fl.Parent then if not(fl.Name or""):find("Dark")and sBC(fl)~="Really black"and d3(r.Position,fl.Position)<=SCYTHE_DIST*2 then pcall(hitFlames)end end end end
 if action=="go_super_outside"then local pp=gCH(true,false,false);if#pp==0 then lastSOTime=os.clock();return-1 end;local best=nil;for i=1,#pp do local ch=pp[i];if ch.part.Parent and not ch.col then local inCorner=false;if xfE and fixedXFC then if d3(ch.part.Position,fixedXFC)<XCR*1.5 then inCorner=true end end;if not inCorner then best=ch;break end end end;if not best then best=pp[1]end;if best then tL="SO 1.8";INT=false;if goTo(best.part.Position,4,4,true)and best.part.Parent then best.col=true;lP=best.part;st.pr=st.pr+1;stToken(best.part);lastSOTime=os.clock();return 25 end end;lastSOTime=os.clock();return-2 end
 if action=="go_center_ch"then local bC=gCH_nc();if not bC then return-1 end;tL="CT 1.8";INT=false;if goTo(bC.part.Position,4,4,true)and bC.part.Parent then bC.col=true;st.chP=st.chP+1;local t0=os.clock();while bC.part.Parent and os.clock()-t0<8 do task.wait(0.05);local h__=hm();if h__ then h__:MoveTo(Vector3.new(bC.part.Position.X,bC.part.Position.Y,bC.part.Position.Z))end end;return 15 end;return-2 end
 if action=="go_center_bt"then local cc=gFC();local bt,bd=nil,math.huge;for p,t in pairs(aT)do if not t.col and p.Parent and TKS[t.id]and TKS[t.id].bt and d3(p.Position,cc)<XCR*2 then local d=d3(r.Position,p.Position);if d<bd then bd=d;bt=p end end end;if bt then tL="CT BT";INT=false;if goTo(bt.Position,4,4)and bt.Parent and aT[bt]then aT[bt].col=true;st.tk=st.tk+1;return 10 end end;return-1 end
 if action=="patrol_scorch_flames"then local sc,hf,dn=gSC();tL=hf and(dn>=5 and"SS Tight"or dn>=2 and"SS Close"or"SS Orbital")or"SS Patrol";INT=false;if sc~=ZERO and hf then local oa=(os.clock()*0.8)%(2*math.pi);local or2=dn>=5 and SCYTHE_DIST*0.4 or dn>=2 and SCYTHE_DIST*0.6 or SCYTHE_DIST*0.8;local tp=Vector3.new(sc.X+math.cos(oa)*or2,r.Position.Y,sc.Z+math.sin(oa)*or2);local nearby=0;local hasDark=false;for fl,_ in pairs(scytheParts)do if fl and fl.Parent and d3(tp,fl.Position)<10 then nearby=nearby+1;if(fl.Name or""):find("Dark")or sBC(fl)=="Really black"then hasDark=true end end end;if nearby>=3 then tL=hasDark and"SS DStand"or"SS Stand";goTo(tp,3,1.0);local t0=os.clock();while os.clock()-t0<0.5 do task.wait(0.05);local h__=hm();if h__ then h__:MoveTo(Vector3.new(tp.X,tp.Y,tp.Z))end end;return 5 end;goTo(tp,4,PT)elseif sc~=ZERO then local ang=math.random()*2*math.pi;goTo(Vector3.new(sc.X+math.cos(ang)*math.random()*aRR*0.4,r.Position.Y,sc.Z+math.sin(ang)*math.random()*aRR*0.4),5,PT)else goTo(r.Position,5,2)end;task.wait(0.1+math.random()*0.2);return 0 end
 if action=="go_scorch_token"then local sc,_,_=gSC();if sc==ZERO then return-1 end;local bt,bd=nil,math.huge;for p,t in pairs(aT)do if not t.col and p.Parent and t.p>=8 then local d=d3(p.Position,sc);if d<40 and d<bd then bd=d;bt=p end end end;if bt then tL="SS Token";INT=false;if goTo(bt.Position,4,5)and bt.Parent and aT[bt]then aT[bt].col=true;return 20 end end;return-1 end
 if action=="go_backpack_dump_purple"then local pp=gPCH();if#pp==0 then return-1 end;local ch=pp[1];tL="90% P";INT=false;if goTo(ch.part.Position,4,3,true)and ch.part.Parent then local t0=os.clock();while ch.part.Parent and os.clock()-t0<8 do task.wait(0.05);local h__=hm();if h__ then h__:MoveTo(Vector3.new(ch.part.Position.X,ch.part.Position.Y,ch.part.Position.Z))end end;ch.col=true;st.pr=st.pr+1;st.chP=st.chP+1;return 50 end;return-2 end
 if action=="go_backpack_dump"then local all=gCH(false,false,false);if#all==0 then return-1 end;local best,bd=nil,math.huge;for _,ch in ipairs(all)do local d=d3(r.Position,ch.part.Position);if d<bd then bd=d;best=ch end end;tL="90% dump";INT=false;if goTo(best.part.Position,4,3,true)and best.part.Parent then local t0=os.clock();while best.part.Parent and os.clock()-t0<8 do task.wait(0.05);local h__=hm();if h__ then h__:MoveTo(Vector3.new(best.part.Position.X,best.part.Position.Y,best.part.Position.Z))end end;best.col=true;st.chP=st.chP+1;if best.isP then st.pr=st.pr+1 else st.ch=st.ch+1 end;return 50 end;return-2 end
 if action=="go_shower"then for i=1,#activeShowers do local sh=activeShowers[i];if not sh.collected and sh.part.Parent and(os.clock()-sh.spawnTime)<1.2 then tL="Shower";INT=false;r.CFrame=CFrame.new(sh.part.Position.X,sh.part.Position.Y+3,sh.part.Position.Z);local t0=os.clock();while os.clock()-t0<2.0 do task.wait(0.05);pcall(hitBloom);pcall(hitFlames);if not sh.part.Parent then break end end;sh.collected=true;local nf=true;while nf and not INT do nf=false;for j=1,#activeShowers do local ns=activeShowers[j];if not ns.collected and ns.part.Parent and ns~=sh and(os.clock()-ns.spawnTime)<3.5 then tL="Shower TP";r.CFrame=CFrame.new(ns.part.Position.X,ns.part.Position.Y+3,ns.part.Position.Z);local t1=os.clock();while os.clock()-t1<2.0 do task.wait(0.05);pcall(hitBloom);pcall(hitFlames);if not ns.part.Parent then break end end;ns.collected=true;nf=true;break end end end;local after=nil;local ad=math.huge;for p,t in pairs(aT)do if not t.col and p.Parent then local ok=false;if t.id==SMI or t.id==2000457501 or t.mo or t.id==8173559749 or t.p>=90 then ok=true end;if ok then local d=d3(r.Position,p.Position);if d<ad then ad=d;after=p end end end end;if after then tL="Sh->Tk";goTo(after.Position,4,3);if after.Parent and aT[after]then aT[after].col=true;st.tk=st.tk+1 end end;local nch=gCH_n();if nch and nch.isP then tL="Sh->P";goTo(nch.part.Position,4,3,true);if nch.part.Parent then nch.col=true;st.pr=st.pr+1;st.chP=st.chP+1 end elseif nch then tL="Sh->CH";goTo(nch.part.Position,4,3);if nch.part.Parent then nch.col=true;st.ch=st.ch+1 end end;return 10+math.min(40,#activeShowers*10)end end;return-1 end
 if action=="go_duped_morph"then local n=os.clock();for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.mo and(t.l-(n-t.s))<4.0 then tL="Morph(D)";INT=false;if goTo(p.Position,4,3)and p.Parent then stToken(p);t.col=true;return 25 end end end;return-2 end
 if action=="go_duped_babylove"then local n=os.clock();for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==1472256444 and(t.l-(n-t.s))<5.0 then tL="BL(D)1.1";INT=false;if goTo(p.Position,4,3)and p.Parent then stToken(p);t.col=true;return 25 end end end;return-2 end
 if action=="go_duped_inspire_scorch"then local n=os.clock();for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==2000457501 and(n-t.s)>2.0 then tL="IN(Sc)";INT=false;if goTo(p.Position,4,3)and p.Parent then stToken(p);t.col=true;return 35 end end end;return-2 end
 if action=="go_duped_inspire_normal"then local n=os.clock();for p,t in pairs(aT)do if not t.col and p.Parent and t.dp and t.id==2000457501 and(t.l-(n-t.s))<2.0 then tL="IN(D)";INT=false;if goTo(p.Position,4,3)and p.Parent then stToken(p);t.col=true;return 25 end end end;return-2 end
 if action=="go_touch_flame"then local bf=nil;local bd=math.huge;local n=os.clock();for fl,data in pairs(scytheParts)do if fl and fl.Parent then local nm=fl.Name or"";local bn=sBC(fl);if not(nm:find("Dark")or bn=="Really black")then local cd=flameCD[fl];if(not cd or n>=cd)and data and(n-data.sT)>2.0 then local d=d3(r.Position,fl.Position);if d<bd then bd=d;bf=fl end end end end end;if bf then tL="Flame";INT=false;local df=(r.Position-bf.Position).Unit;if df.Magnitude<0.1 then df=Vector3.new(1,0,0)end;if goTo(bf.Position+df*SCYTHE_DIST*0.85,3,3)then flameCD[bf]=os.clock()+5.0;return 10 end end;return-2 end
 if action=="go_coconut"then local n=os.clock();for i,coco in ipairs(activeCocos)do if not coco.collected and coco.part.Parent and(3.0-(n-coco.spawnTime))<=1.0 then tL="Coco";INT=false;local hh=hm();local origSp=cS;if hh then hh.WalkSpeed=cS+10 end;if goTo(coco.part.Position,3,2)and coco.part.Parent then if hh then hh.WalkSpeed=origSp end;local t0=os.clock();while coco.part.Parent do task.wait(0.05);pcall(hitBloom);pcall(hitFlames);if INT or not ENABLED then break end;local h__=hm();if h__ then h__:MoveTo(Vector3.new(coco.part.Position.X,coco.part.Position.Y,coco.part.Position.Z))end;if os.clock()-t0>60 then break end end;coco.collected=true;return 30 end;if hh then hh.WalkSpeed=origSp end end end;return-2 end
 if action=="go_build_precision"then local tp=gTPG_build();if not tp then return-1 end;local g=tp[1];local rw=0;INT=false;if g.pr.part.Parent and not g.pr.col then tL="TP";if goTo(g.pr.part.Position,4,5,true)and g.pr.part.Parent then g.pr.col=true;lP=g.pr.part;st.pr=st.pr+1;rw=rw+30;task.wait(0.1)end end;if g.r1.part.Parent and not g.r1.col then tL="r1";if goTo(g.r1.part.Position,4,4)and g.r1.part.Parent then g.r1.col=true;st.ch=st.ch+1;rw=rw+10;task.wait(0.05)end end;if g.r2.part.Parent and not g.r2.col then tL="r2";if goTo(g.r2.part.Position,4,4)and g.r2.part.Parent then g.r2.col=true;st.ch=st.ch+1;rw=rw+10 end end;if rw>0 and aB.PoM.a and aB.PoM.pos then goTo(aB.PoM.pos,6,3)end;return rw>0 and rw or-2 end
 if action=="go_multi_purple"then local pp=gPCH();if#pp<2 then return-1 end;local rw=0;INT=false;if pp[1].part.Parent then tL="Px2#1";if goTo(pp[1].part.Position,4,3,true)and pp[1].part.Parent then pp[1].col=true;st.pr=st.pr+1;rw=rw+20 end end;if pp[2].part.Parent then tL="Px2#2";if goTo(pp[2].part.Position,4,3,true)and pp[2].part.Parent then pp[2].col=true;st.pr=st.pr+1;rw=rw+20 end end;return rw>0 and rw or-2 end
 if action=="go_crosshair_all"then local all=gCH(false,false,true);if#all==0 then return-1 end;local rw=0;INT=false;for i=1,#all do local ch=all[i];if ch.part.Parent and not ch.col then tL=ch.isP and"P All"or"CH All";if goTo(ch.part.Position,4,3,true)and ch.part.Parent then ch.col=true;if ch.isP then st.pr=st.pr+1;if scorchActive then scorchPurpleTotal=scorchPurpleTotal+1 end;rw=rw+20 else st.ch=st.ch+1;rw=rw+10 end end end end;return rw>0 and rw or-2 end
 if action=="go_crosshair_refresh_all"then local all=gCH(false,false,true);if#all==0 then return-1 end;local col=0;INT=false;for i=1,#all do local ch=all[i];if ch.part.Parent and not ch.col and col<3 then tL="R"..(col+1);if goTo(ch.part.Position,4,4,true)and ch.part.Parent then ch.col=true;rCC=rCC+1;if ch.isP then st.pr=st.pr+1;lP=ch.part else st.ch=st.ch+1 end;col=col+1;task.wait(0.1)end end end;if aR and aR.Parent then goTo(aR.Position,6,4)else goTo(cP(r.Position),5,2)end;if rCC>=3 then prec.nR=false;cyc.chC=0;st.rf=st.rf+1;rCC=0;return 40 end;return col>0 and col*12 or-2 end
 if action=="go_smile_area"then local t=gSDA();if not t or not aT[t]or aT[t].col or aT[t].id~=SMI then return-1 end;tL="Sm(R)";INT=false;if goTo(gEP(t.Position),4,4)and t.Parent then aT[t].col=true;st.sm=st.sm+1;dupCnt=0;return 45 end;return-10 end
 if action=="go_dup_area"then local t=gSDA();if not t or not aT[t]or aT[t].col or aT[t].id~=TPI or not aT[t].dp then return-1 end;tL="D(R)";INT=false;if goTo(gEP(t.Position),4,4)and t.Parent then aT[t].col=true;st.tk=st.tk+1;return 15 end;return-2 end
 if action=="go_smile"then local sm=smT;if not sm or not sm.Parent then smT=nil;return-1 end;local td=aT[sm];if not td or td.col then smT=nil;return-1 end;isCS=true;tL="Sm";INT=false;goSm=true;for fl,data in pairs(scytheParts)do if fl and fl.Parent then if not(fl.Name or""):find("Dark")and sBC(fl)~="Really black"and d3(r.Position,fl.Position)<=SCYTHE_DIST*2 then pcall(hitFlames)end end end;local hh=hm();local origSp=cS;for _,fp in ipairs(fP)do if fp.cn=="Pink"and fp.part.Parent then local dp=d3(r.Position,sm.Position);local fpDist=d3(r.Position,fp.part.Position);if fpDist<dp+10 then hh.WalkSpeed=cS+10;tL="Sm+10";if goTo(Vector3.new(fp.part.Position.X,0,fp.part.Position.Z),PCD,1.5)then st.pt=st.pt+1 end;break end end end;if aR and aR.Parent then goTo(aR.Position,5,2);local wt=os.clock();while os.clock()-wt<0.3 do task.wait(0.05);local h__=hm();if h__ then h__:MoveTo(Vector3.new(aR.Position.X,aR.Position.Y,aR.Position.Z))end end end;local to=math.max(0.5,math.min(3,smTR-0.3));local ok=goTo(sm.Position,4,to);goSm=false;if hh then hh.WalkSpeed=origSp end;if ok and sm.Parent then if not td.dp then td.col=true;smT=nil;st.sm=st.sm+1;isCS=false;dupCnt=0;for _,tt in pairs(aT)do if tt.dp and not tt.col then dupCnt=dupCnt+1 end end;return 45 end;local st_=os.clock();while os.clock()-st_<TSD do task.wait(0.1);if not sm.Parent then break end;local h__=hm();if h__ then h__:MoveTo(Vector3.new(sm.Position.X,sm.Position.Y,sm.Position.Z))end end;td.col=true;smT=nil;st.sm=st.sm+1;isCS=false;dupCnt=0;for _,tt in pairs(aT)do if tt.dp and not tt.col then dupCnt=dupCnt+1 end end;return 45 end;isCS=false;smT=nil;goSm=false;if hh then hh.WalkSpeed=origSp end;return-10 end
 if action=="go_purple"then local pp=gCH(true,false,false);if#pp==0 then return-1 end;local rw=0;INT=false;for i=1,#pp do local ch=pp[i];if ch.part.Parent and not ch.col and not smT then local isLast=(i==#pp);if isLast then if standOnPurple(ch,12)then rw=rw+25;tL="P stand"end else if goTo(ch.part.Position,3,3,true)and ch.part.Parent then ch.col=true;lP=ch.part;st.pr=st.pr+1;tL="P run";rw=rw+15 end end end end;return rw>0 and rw or-2 end
 if action=="go_tokenlink"then local tl={};local n_=os.clock();for p,t in pairs(aT)do if not t.col and p.Parent and t.p>=90 then table.insert(tl,{p=p,t=t,rem=t.l-(n_-t.s)})end end;if#tl==0 then return-2 end;table.sort(tl,function(a,b)return a.rem<b.rem end);local bT=nil;for _,e in ipairs(tl)do local skip=false;if aB.XF.st>0 then local cc=gFC();if cc~=ZERO then if d3(e.p.Position,cc)>XCR*2 then if aB.XF.st+cBT(e.p.Position,40)>=25 then skip=true end end end end;if not skip then bT=e;break end end;if not bT then return-2 end;tL="Link";INT=false;if goTo(bT.p.Position,5,5)and bT.p.Parent then bT.t.col=true;lastTLT=os.clock();for _,e2 in ipairs(tl)do if e2.p~=bT.p and e2.p.Parent and not e2.t.col then local dist2=d3(bT.p.Position,e2.p.Position);if dist2<40 then if e2.rem>3.0 then local wT=math.min(2.5,e2.rem-1.0);local w0=os.clock();local hbS=hbF;while os.clock()-w0<wT and hbF-hbS<300 do task.wait(0.1);pcall(hitBloom);pcall(hitFlames);if INT or not ENABLED then break end;if not e2.p.Parent or e2.t.col then break end end end;if e2.p.Parent and not e2.t.col then goTo(e2.p.Position,5,4);if e2.p.Parent then e2.t.col=true end end end;break end end;return 50 end;return-5 end
 if action=="go_crosshair"then local all=gCH(false,false,false);if#all==0 then return-1 end;local t=all[1];local rw=0;INT=false;if t.part.Parent and not t.col and not smT then local sk=false;local r2=h();if r2 then for p2,t2 in pairs(aT)do if not t2.col and p2.Parent and t2.p>=90 and d3(r2.Position,p2.Position)<TLID and d3(r2.Position,t.part.Position)>30 then sk=true;break end end end;if xfE and not sk then local cc=gFC();if cc~=ZERO and d3(t.part.Position,cc)>XCR*1.5 then sk=true end end;if not sk and hasNearPurpleCH()and not t.isP then sk=true end;if not sk then if goTo(t.part.Position,4,5)and t.part.Parent then t.col=true;if t.isP then st.pr=st.pr+1;lP=t.part;rw=rw+(prec.nR and 5 or 10)else st.ch=st.ch+1;cyc.chC=cyc.chC+1;if cyc.chC>=3 then cyc.chC=0 end;rw=rw+8 end end end end;if rw>0 and aB.PoM.a and aB.PoM.pos then goTo(aB.PoM.pos,6,4)end;return rw>0 and rw or-2 end
 if action=="go_dup_tp"then local p,t=gDTP();if not p then return-1 end;tL="Dup";INT=false;if goTo(p.Position,5,5)and p.Parent then t.col=true;return 15 end;return-2 end
 if action=="go_petal_cluster"then local cl=gPetCluster();if not cl then return-1 end;local c=cl[1];tL="PtCl"..c.size;INT=false;local hh=hm();local origSp=cS;if hh then hh.WalkSpeed=cS+10 end;if goTo(c.center,5,3)then local rw=0;for _,m in ipairs(c.members)do if m.part.Parent then if goTo(Vector3.new(m.part.Position.X,0,m.part.Position.Z),PCD,1.2)then st.pt=st.pt+1;rw=rw+6+(14-m.pr);if m.cn=="Red"then redPT=os.clock()end end end end;if hh then hh.WalkSpeed=origSp end;return rw>0 and rw or 3 end;if hh then hh.WalkSpeed=origSp end;return-2 end
 if action=="go_petal"then if#fP==0 then return-1 end;local ca=false;local tr=0;local i=1;while i<=#fP do local pt=fP[i];if not pt.part.Parent then table.remove(fP,i)elseif stP[pt.part]and os.clock()<stP[pt.part]then table.remove(fP,i)else tL=pt.cn;INT=false;if goTo(Vector3.new(pt.part.Position.X,0,pt.part.Position.Z),PCD,2.5)then st.pt=st.pt+1;tr=tr+8+(14-pt.pr);ca=true;if pt.cn=="Red"then redPT=os.clock()end;task.wait(0.05);i=i+1 else stP[pt.part]=os.clock()+5;table.remove(fP,i)end end end;return ca and tr or-1 end
 if action=="go_token_near"then local be=nil;local bd=math.huge;for p,t in pairs(aT)do if not t.col and p.Parent and not tokenBL[p]then local d=d3(r.Position,p.Position);if d<bd then be=p;bd=d end end end;if be then tL=aT[be].n;INT=false;if goTo(be.Position,5,5)and be.Parent then aT[be].col=true;tokenBL[be]=os.clock()+1.2;return 3+aT[be].p*0.2 end;return-2 end;return-1 end
 if action=="go_token_best"then local bs=cS+5;local be=nil;local br=0;local n=os.clock();local cand={};for p,t in pairs(aT)do if not t.col and p.Parent and not tokenBL[p]then local rem=t.l-(n-t.s);if rem>0.5 then local sc2=t.p*(rem/t.l);if t.dp then sc2=sc2*1.3 end;table.insert(cand,{p=p,t=t,score=sc2,rem=rem})end end end;if#cand==0 then return-1 end;table.sort(cand,function(a,b)return a.score>b.score end);be=cand[1].p;br=cand[1].rem;if be then tL=aT[be].n;INT=false;if goTo(be.Position,5,5)and be.Parent then aT[be].col=true;tokenBL[be]=os.clock()+1.2;return 5+aT[be].p*0.3 end;return-3 end;return-1 end
 if action=="patrol_ring"then local bt=nil;local bs2=-1;local n_=os.clock();for p,td in pairs(aT)do if not td.col and p.Parent then local d=d3(r.Position,p.Position);local rem=td.l-(n_-td.s);if rem>0.5 and td.p>=1 then local sc2=td.p*(1+(td.dp and 0.5 or 0))/(d+1);if sc2>bs2 then bs2=sc2;bt=p end end end end;if bt then goTo(bt.Position,4,4);if bt.Parent and aT[bt]then aT[bt].col=true;st.tk=st.tk+1 end end;if aR and aR.Parent then local ang=math.random()*2*math.pi;goTo(Vector3.new(aR.Position.X+math.cos(ang)*aRR*0.5*math.random(),r.Position.Y,aR.Position.Z+math.sin(ang)*aRR*0.5*math.random()),6,PT)elseif curF then local c=curF.part.Position;local s=curF.part.Size;goTo(Vector3.new(c.X+(math.random()*2-1)*math.max(s.X/2*0.3,5),0,c.Z+(math.random()*2-1)*math.max(s.Z/2*0.3,5)),6,PT)end;tL="R->AR";INT=false;task.wait(0.1+math.random()*0.2);return 0 end
 if action=="go_xflame_center"then local c=gFC();if c==ZERO then return-1 end;tL="XF c";INT=false;goTo(c,3,3);return 0 end
 if action=="go_xflame_ch"then local ch=gCH_nc();if not ch then return-1 end;tL="XF CH";INT=false;if goTo(ch.part.Position,2,3,true)and ch.part.Parent then ch.col=true;st.ch=st.ch+1;return 5 end;return-1 end
 return 0
end

-- VISUALS
local function uVC()
 local r=h()
 if aB.SS.st>0 then if not scVis then local ok,p=pcall(function()local p=Instance.new("Part");p.Name="SC";p.Shape=Enum.PartType.Cylinder;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.Transparency=0.55;p.BrickColor=BrickColor.new("Bright orange");p.Size=Vector3.new(XCR*3,0.3,XCR*3);p.Parent=W;return p end);if ok then scVis=p end end;if scVis then scVis.CFrame=CFrame.new(gFC().X,gFC().Y+0.15,gFC().Z)*CFrame.Angles(0,0,math.pi/2)end else if scVis then pcall(function()scVis:Destroy()end);scVis=nil end end
 if xfE then local cc=gFC();if cc==ZERO and r then cc=r.Position end;if not xfC then local ok,p=pcall(function()local p=Instance.new("Part");p.Name="XF";p.Shape=Enum.PartType.Cylinder;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.Transparency=0.5;p.BrickColor=BrickColor.new("Really red");p.Size=Vector3.new(XCR*2,0.2,XCR*2);p.Parent=W;return p end);if ok then xfC=p end end;if xfC then xfC.CFrame=CFrame.new(cc.X,cc.Y+0.1,cc.Z)*CFrame.Angles(0,0,math.pi/2)end else if xfC then pcall(function()xfC:Destroy()end);xfC=nil end end
 if ENABLED and r then if not syVis then local ok,p=pcall(function()local p=Instance.new("Part");p.Name="SY";p.Shape=Enum.PartType.Cylinder;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.Transparency=0.55;p.BrickColor=BrickColor.new("Cyan");p.Size=Vector3.new(SCYTHE_DIST*2,0.15,SCYTHE_DIST*2);p.Parent=W;return p end);if ok then syVis=p end end;if syVis then syVis.CFrame=CFrame.new(r.Position.X,r.Position.Y+0.05,r.Position.Z)*CFrame.Angles(0,0,math.pi/2)end else if syVis then pcall(function()syVis:Destroy()end);syVis=nil end end
end

-- HEATMAP Object Pooling
local HeatmapPool={};local HeatmapIndex=1
R.RenderStepped:Connect(function()
 if not ENABLED then return end;local r=h();if not r then return end
 local refV=ZERO;local th=cATCache or{}
 for _,t in ipairs(th)do if t.pos then local toCh=r.Position-t.pos;local dist=toCh.Magnitude;if dist<(t.sz+6)and dist>0.1 then refV=refV+(toCh.Unit*150)end end end
 if refV.Magnitude>0.1 then r.AssemblyLinearVelocity=r.AssemblyLinearVelocity+Vector3.new(refV.X,0,refV.Z)end
 if hbF%10==0 and HRL_MACRO_TARGET then
  HeatmapIndex=(HeatmapIndex%5)+1
  local hp=HeatmapPool[HeatmapIndex]
  if not hp then hp=Instance.new("Part");hp.Size=Vector3.new(3,0.5,3);hp.Anchored=true;hp.CanCollide=false;hp.Material=Enum.Material.Neon;hp.Parent=W;HeatmapPool[HeatmapIndex]=hp end
  hp.Color=HRL_ADRENALINE and Color3.fromRGB(255,50,50)or Color3.fromRGB(50,255,100)
  hp.CFrame=CFrame.new(HRL_MACRO_TARGET.X,r.Position.Y-2,HRL_MACRO_TARGET.Z)
 end
end)

-- ANTI LAG
if ELA then task.spawn(function()local tg={"Flowers","Bees","Kukurudza_dontreal","FieldDecos","Collectibles","NPCs","OnettNPC","Noob Bear","Top Bear","Pro Bear"};for _,n in pairs(tg)do local f=W:FindFirstChild(n);if f then local d=f:GetDescendants();for i=1,#d do local o=d[i];if o:IsA("BasePart")or o:IsA("MeshPart")then o.Transparency=1;o.CastShadow=false;o.Material=Enum.Material.SmoothPlastic elseif o:IsA("Decal")or o:IsA("Texture")then o:Destroy()end;if i%100==0 then task.wait()end end end end;local lt=W:FindFirstChild("Lighting");if lt then lt.GlobalShadows=false;lt.Brightness=2 end end)end

-- INIT
local mLS=false
local function sML()if mLS then return end;mLS=true;task.wait(2);scriptStartH=getHoney()or 0;scriptStartT=os.clock();lQ();fAR();fF();lo("Marmot Z HRL v4.0 ready! "..fmtH(scriptStartH));print("Marmot Z v4.0 — Predictive, Spatial State, Momentum Strafing, PER, XF Camp");tL="init";lMT=os.clock()end
task.spawn(function()pcall(function()if not readfile then return end;local ok,raw=pcall(readfile,"marmot_z_pat.json");if ok and raw then local ok2,data=pcall(H.JSONDecode,H,raw);if ok2 and type(data)=="table"then if data.scorchSessions then scorchSessions=data.scorchSessions end;if data.bestScorch then bestSH=data.bestScorch end end end end);lo("Loaded: "..#scorchSessions)end)
task.spawn(function()while true do task.wait(30);pcall(function()local lt=W:FindFirstChild("Lighting");if lt then lt.GlobalShadows=false;lt.Brightness=2 end end)end end)
task.spawn(function()while true do task.wait(0.5);if ENABLED and mLS then pcall(pAB)end end end)

if _G.MarmotZ_HB then pcall(function()_G.MarmotZ_HB:Disconnect()end)end
_G.MarmotZ_HB=R.Heartbeat:Connect(function()
 hbF=hbF+1;if not ENABLED then return end;if not mLS then sML();return end;local n=os.clock();fAR()
 if hbF%9==0 then sPt();scS();local h_=hm();if h_ then local ts=gAS();if math.abs(h_.WalkSpeed-ts)>0.5 then h_.WalkSpeed=ts end end end
 if hbF%3==0 then sSm()end;if hbF%180==0 then fF()end;if hbF%60==0 then clnCH()end;if hbF%30==0 then sSS()end;if hbF%15==0 then verifyTokens()end;if hbF%120==0 then for _,o in ipairs(W:GetDescendants())do pcall(rT,o)end end
 if hbF%36000==0 then for _,tbl in pairs(qTables)do for k,v in pairs(tbl)do tbl[k]=v*0.99 end end end
 if hbF%18000==0 then task.spawn(function()local qc=0;for _ in pairs(QT)do qc=qc+1 end;if writefile then pcall(function()writefile("marmot_z_q.json",H:JSONEncode({version=Q_VERSION,qtable=QT,scorchSessions=scorchSessions,bestScorch=bestSH,top10=top10,eligibility=eligibility,visitCount=visitCount,totalSteps=totalSteps,meta={sc=qc,sa=os.time()}}))end)end end)end
 local prevXfE=xfE;xfE=(aB.XF.st>=19 and xfP>=10);if xfE and not prevXfE then xfStartTime=os.clock()end;if xfE then INT=true;if not fixedXFC then local tf=W.Flowers:FindFirstChild("FP18-10-13");if tf then fixedXFC=tf.Position end end else fixedXFC=nil end;uVC()
 local r=h();if r then local vel=r.AssemblyLinearVelocity;if(Vector3.new(vel.X,0,vel.Z)).Magnitude>0.2 then lMT=n;stW=false elseif n-lMT>5 and not stW then stW=true;INT=true;tL="reset";if lP and not lP.Parent then lP=nil end;if smT and not smT.Parent then smT=nil;isCS=false end;INT=false;lMT=n end end
 if INT and not smT and not prec.nR and not xfE then INT=false end
 if prec.isX and not prec.nR and r then for i=1,#cQ do local ch=cQ[i];if ch.part and ch.part.Parent and not ch.col and not ch.isP and d3(r.Position,ch.part.Position)<4 then if isGreenCH(ch)then if n-lPT>1.5 then lPT=n;local s_=eS();if s_ and s_~="dead"then pcall(dUQ,s_,"patrol_ring",-80,s_)end;st.chA=st.chA+1;xGCH=xGCH+1;le("GREEN CH -80! total:"..xGCH);greenCH_cache[ch.part.Position]=os.clock()+10 end end;break end end end
 -- FIX #2: cleanup token blacklist
 local nowBL=os.clock();for p,exp in pairs(tokenBL)do if type(exp)=="number"and nowBL>exp then tokenBL[p]=nil end end
 if isA then return end
 if hbF%2==0 then isA=true;local gr=h();if gr then flHit=0;chStick=0;aborted=false;local s_=eS();local a_=cAB(s_);local ok,rw=pcall(eA,a_);if not ok then le(a_.." crash: "..tostring(rw));rw=-1 end;local ns=eS();pcall(dUQ,s_,a_,rw,ns)end;isA=false end
end)

function lQ()if not readfile then return end;local ok,raw=pcall(readfile,"marmot_z_q.json");if ok and raw then local ok2,d=pcall(H.JSONDecode,H,raw);if ok2 and type(d)=="table"and d.version==Q_VERSION and type(d.qtable)=="table"then QT=d.qtable;if d.scorchSessions then scorchSessions=d.scorchSessions end;if d.bestScorch then bestSH=d.bestScorch end;if d.top10 then top10=d.top10 end;if d.eligibility then eligibility=d.eligibility end;if d.visitCount then visitCount=d.visitCount end;if d.totalSteps then totalSteps=d.totalSteps end end end end
local function rQ()QT={};EP=0.1;st.tR=0;st.dc=0;scorchSessions={};bestSH=0;top10={};eligibility={};visitCount={};totalSteps=0;if writefile then pcall(function()writefile("marmot_z_q.json",H:JSONEncode({version=Q_VERSION,qtable={},scorchSessions={},bestScorch=0,top10={},eligibility={},visitCount={},totalSteps=0,meta={ra=os.time()}}))end)end end

-- ===== FEATURE 6: TABBED GUI v4.0 + Auto Smoothie =====
local cfg={ss_on=false,sp_x10=90,sp_nab=70,sp_ref=75}

-- Auto Smoothie (каждые 20 минут = 1200 секунд)
task.spawn(function()
 while true do
  task.wait(1)
  if cfg.ss_on then
   pcall(function()RS.Events.PlayerActivesCommand:FireServer({["Name"]="Super Smoothie"})end)
   task.wait(1200)
  end
 end
end)

local sgV4=Instance.new("ScreenGui",G);sgV4.Name="MarmotZ_V4"
local frV4=Instance.new("Frame",sgV4);frV4.Size=UDim2.new(0,340,0,280);frV4.Position=UDim2.new(0,10,0,10)
frV4.BackgroundColor3=Color3.fromRGB(25,25,35);frV4.BorderSizePixel=0;frV4.Active=true;frV4.Draggable=true
Instance.new("UICorner",frV4).CornerRadius=UDim.new(0,8)

local titleV4=Instance.new("TextLabel",frV4);titleV4.Size=UDim2.new(1,0,0,30);titleV4.BackgroundTransparency=1
titleV4.Text=" Marmot Z v4.0 - Velocity";titleV4.TextColor3=Color3.fromRGB(150,200,255);titleV4.Font=Enum.Font.GothamBold;titleV4.TextSize=16;titleV4.TextXAlignment=Enum.TextXAlignment.Left

local tBar=Instance.new("Frame",frV4);tBar.Size=UDim2.new(1,0,0,30);tBar.Position=UDim2.new(0,0,0,30);tBar.BackgroundTransparency=1
local tMain=Instance.new("Frame",frV4);tMain.Size=UDim2.new(1,-20,1,-70);tMain.Position=UDim2.new(0,10,0,65);tMain.BackgroundTransparency=1;tMain.Visible=true
local tBoost=Instance.new("Frame",frV4);tBoost.Size=UDim2.new(1,-20,1,-70);tBoost.Position=UDim2.new(0,10,0,65);tBoost.BackgroundTransparency=1;tBoost.Visible=false
local tSet=Instance.new("Frame",frV4);tSet.Size=UDim2.new(1,-20,1,-70);tSet.Position=UDim2.new(0,10,0,65);tSet.BackgroundTransparency=1;tSet.Visible=false

local function mkTab(name,x,target)
 local b=Instance.new("TextButton",tBar);b.Size=UDim2.new(0,90,0,26);b.Position=UDim2.new(0,x,0,2);b.Text=name
 b.BackgroundColor3=Color3.fromRGB(40,40,55);b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.GothamSemibold;b.TextSize=12
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
 b.MouseButton1Click:Connect(function()tMain.Visible=(target==tMain);tBoost.Visible=(target==tBoost);tSet.Visible=(target==tSet)end)
end
mkTab("Stats",10,tMain);mkTab("Boosts",110,tBoost);mkTab("Settings",210,tSet)

local function mkStat(y)
 local l=Instance.new("TextLabel",tMain);l.Size=UDim2.new(1,0,0,16);l.Position=UDim2.new(0,0,0,y)
 l.BackgroundTransparency=1;l.Font=Enum.Font.Gotham;l.TextSize=12;l.TextXAlignment=Enum.TextXAlignment.Left;return l
end
local lb=mkStat(0);lb.TextColor3=Color3.new(1,1,1)
local hl=mkStat(20);hl.TextColor3=Color3.fromRGB(150,255,150)
local sl=mkStat(40);sl.TextColor3=Color3.fromRGB(255,200,100)
local pl_=mkStat(60);pl_.TextColor3=Color3.fromRGB(180,180,255)
local xl=mkStat(80);xl.TextColor3=Color3.fromRGB(255,180,100)
local pul=mkStat(100);pul.TextColor3=Color3.fromRGB(200,120,255)
local sh=mkStat(120);sh.TextColor3=Color3.fromRGB(255,140,80)
local ssLab=mkStat(140);ssLab.TextColor3=Color3.fromRGB(255,200,100);ssLab.Text="Super Smoothie: OFF"

local sb=Instance.new("TextButton",tMain);sb.Size=UDim2.new(1,0,0,30);sb.Position=UDim2.new(0,0,1,-30)
sb.BackgroundColor3=Color3.fromRGB(180,40,40);sb.Text="STOP SCRIPT";sb.TextColor3=Color3.new(1,1,1);sb.Font=Enum.Font.GothamBold;sb.TextSize=14
Instance.new("UICorner",sb).CornerRadius=UDim.new(0,6)
sb.MouseButton1Click:Connect(function()ENABLED=not ENABLED;sb.Text=ENABLED and"STOP SCRIPT"or"RESUME SCRIPT";sb.BackgroundColor3=ENABLED and Color3.fromRGB(180,40,40)or Color3.fromRGB(40,180,40)end)

-- Boosts tab
local bTitle=Instance.new("TextLabel",tBoost);bTitle.Size=UDim2.new(1,0,0,20);bTitle.BackgroundTransparency=1
bTitle.Text="Auto Use Materials";bTitle.TextColor3=Color3.new(1,1,1);bTitle.Font=Enum.Font.GothamBold;bTitle.TextSize=13;bTitle.TextXAlignment=Enum.TextXAlignment.Left

local ssBtn=Instance.new("TextButton",tBoost);ssBtn.Size=UDim2.new(1,0,0,30);ssBtn.Position=UDim2.new(0,0,0,30)
ssBtn.BackgroundColor3=Color3.fromRGB(40,40,55);ssBtn.Text="[ ] Super Smoothie (20m)"
ssBtn.TextColor3=Color3.fromRGB(200,200,200);ssBtn.Font=Enum.Font.Gotham;ssBtn.TextSize=13
Instance.new("UICorner",ssBtn).CornerRadius=UDim.new(0,4)
ssBtn.MouseButton1Click:Connect(function()cfg.ss_on=not cfg.ss_on;ssBtn.Text=cfg.ss_on and"[X] Super Smoothie (20m)"or"[ ] Super Smoothie (20m)";ssBtn.TextColor3=cfg.ss_on and Color3.fromRGB(100,255,100)or Color3.fromRGB(200,200,200)end)

-- Settings tab
local sBar=Instance.new("Frame",tSet);sBar.Size=UDim2.new(1,0,0,25);sBar.BackgroundTransparency=1
local sSpeed=Instance.new("Frame",tSet);sSpeed.Size=UDim2.new(1,0,1,-30);sSpeed.Position=UDim2.new(0,0,0,30);sSpeed.BackgroundTransparency=1;sSpeed.Visible=true
local sCfg=Instance.new("Frame",tSet);sCfg.Size=UDim2.new(1,0,1,-30);sCfg.Position=UDim2.new(0,0,0,30);sCfg.BackgroundTransparency=1;sCfg.Visible=false

local function mkSub(name,x,target)
 local b=Instance.new("TextButton",sBar);b.Size=UDim2.new(0,100,0,25);b.Position=UDim2.new(0,x,0,0);b.Text=name
 b.BackgroundColor3=Color3.fromRGB(45,45,60);b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.GothamSemibold;b.TextSize=12
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
 b.MouseButton1Click:Connect(function()sSpeed.Visible=(target==sSpeed);sCfg.Visible=(target==sCfg)end)
end
mkSub("Speedhack",0,sSpeed);mkSub("Config",110,sCfg)

local function mkSpd(name,y,key)
 local l=Instance.new("TextLabel",sSpeed);l.Size=UDim2.new(0,120,0,25);l.Position=UDim2.new(0,0,0,y);l.BackgroundTransparency=1
 l.Text=name;l.TextColor3=Color3.new(1,1,1);l.Font=Enum.Font.Gotham;l.TextSize=12;l.TextXAlignment=Enum.TextXAlignment.Left
 local bx=Instance.new("TextBox",sSpeed);bx.Size=UDim2.new(0,60,0,25);bx.Position=UDim2.new(0,130,0,y)
 bx.BackgroundColor3=Color3.fromRGB(35,35,45);bx.TextColor3=Color3.new(1,1,1);bx.Text=tostring(cfg[key]);bx.Font=Enum.Font.Code;bx.TextSize=12
 Instance.new("UICorner",bx).CornerRadius=UDim.new(0,4)
 bx.FocusLost:Connect(function()local n=tonumber(bx.Text);if n then cfg[key]=n;SB.X10=cfg.sp_x10;SB.NABOR=cfg.sp_nab;SB.REFRESH=cfg.sp_ref else bx.Text=tostring(cfg[key])end end)
end
mkSpd("Speed X10",0,"sp_x10");mkSpd("Speed NABOR",35,"sp_nab");mkSpd("Speed REFRESH",70,"sp_ref")

local cfgBox=Instance.new("TextBox",sCfg);cfgBox.Size=UDim2.new(1,0,0,25);cfgBox.Position=UDim2.new(0,0,0,0)
cfgBox.BackgroundColor3=Color3.fromRGB(35,35,45);cfgBox.TextColor3=Color3.new(1,1,1);cfgBox.Text="My_Config"
cfgBox.Font=Enum.Font.Gotham;cfgBox.TextSize=12;Instance.new("UICorner",cfgBox).CornerRadius=UDim.new(0,4)

local function mkCb(name,x,y,fn)
 local b=Instance.new("TextButton",sCfg);b.Size=UDim2.new(0,130,0,25);b.Position=UDim2.new(0,x,0,y);b.Text=name
 b.BackgroundColor3=Color3.fromRGB(45,45,60);b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.Gotham;b.TextSize=11
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
 b.MouseButton1Click:Connect(fn)
end
mkCb("Rename Config",0,35,function()cfgBox.Text="Saved: "..cfgBox.Text end)
mkCb("Delete Config",140,35,function()cfg.ss_on=false;cfg.sp_x10=90;cfg.sp_nab=70;cfg.sp_ref=75;SB.X10=90;SB.NABOR=70;SB.REFRESH=75;ssBtn.Text="[ ] Super Smoothie (20m)";ssBtn.TextColor3=Color3.fromRGB(200,200,200);cfgBox.Text="Config Deleted!"end)
mkCb("Copy Config",0,70,function()pcall(setclipboard,H:JSONEncode(cfg));cfgBox.Text="Copied to clipboard!"end)
mkCb("Load Config",140,70,function()
 local ok,d=pcall(H.JSONDecode,H,cfgBox.Text)
 if ok and type(d)=="table"then
  if d.sp_x10 then cfg.sp_x10=d.sp_x10 end;if d.sp_nab then cfg.sp_nab=d.sp_nab end;if d.sp_ref then cfg.sp_ref=d.sp_ref end;if d.ss_on~=nil then cfg.ss_on=d.ss_on end
  SB.X10=cfg.sp_x10;SB.NABOR=cfg.sp_nab;SB.REFRESH=cfg.sp_ref
  ssBtn.Text=cfg.ss_on and"[X] Super Smoothie (20m)"or"[ ] Super Smoothie (20m)"
  ssBtn.TextColor3=cfg.ss_on and Color3.fromRGB(100,255,100)or Color3.fromRGB(200,200,200);cfgBox.Text="Loaded JSON!"
 else cfgBox.Text="Paste JSON here first!"end
end)

-- GUI update loop
task.spawn(function()
 while true do
  task.wait(0.3)
  pcall(function()
   lb.Text="Action: "..(tL or"")
   local curH=getHoney()or 0;local elapsedMins=(os.clock()-(scriptStartT or 0))/60;local hp40m=elapsedMins>0 and(curH-(scriptStartH or 0))/elapsedMins*40 or 0
   hl.Text="HP40M: "..fmtH(hp40m).." | "..fmtH(curH)
   sl.Text="S: "..string.format("%.0f",cS).." | PREC: "..(prec.isX and"X10"or""..(prec.st or 0)).." "..((prec.tL or 0)>0 and string.format("%.0fs",prec.tL)or"--")
   pl_.Text=ph().." CH:"..#cQ.." Tk:"..(st.tk or 0).." Pr:"..(st.pr or 0)
   xl.Text="XF:"..(xfP or 0).."/25 SS:"..(scP or 0).."/30"
   if scorchActive then pul.Text="Purple Sc:"..(scorchPurpleCount or 0).." | Total:"..(scorchPurpleTotal or 0)else pul.Text="Purple: "..(st.pr or 0).." | GCH:"..(xGCH or 0)end
   if scorchActive and(scorchStartT or 0)>0 then sh.Text=""..fmtH(curH-(scorchStartH or 0)).." "..string.format("%.1f",(os.clock()-(scorchStartT or 0))/60).."min | "..fmtH(bestSH or 0).." | PC:"..(scorchPurpleCount or 0)else sh.Text=""..(#scorchSessions or 0).." scorches | T10:"..(#top10 or 0).." | "..fmtH(bestSH or 0)end
   ssLab.Text="Super Smoothie: "..(cfg.ss_on and"[X] ON"or"[ ] OFF")
  end)
 end
end)

U.InputBegan:Connect(function(i,gp)if gp then return end;if i.KeyCode==Enum.KeyCode.T then ENABLED=not ENABLED elseif i.KeyCode==Enum.KeyCode.G then rQ()elseif i.KeyCode==Enum.KeyCode.P then local c=0;for _ in pairs(QT)do c=c+1 end;print("Marmot Z v4.0 eps:"..string.format("%.3f",EP).." Honey:"..fmtH(getHoney()))end end)

L.CharacterAdded:Connect(function()
 task.wait(2);aT={};cQ={};lP=nil;curF=nil;tL="start";smT=nil;isCS=false;INT=false;cyc={chC=0};fP={};igT=0;rCC=0;dupCnt=0;pollMS=0;eligibility={};visitCount={};totalSteps=0;replayBuffer={};replayIndex=1
 scorchActive=false;scorchRecording=false;scorchActions={};scorchStartH=0;scorchStartT=0;fixedXFC=nil;lastTLT=0;xfP=0;scP=0;lastBH=0;redPT=0;stFlMin=0;xGCH=0;lastSOTime=0;scorchDupedMorphDone=false;scorchPurpleCount=0;scorchPurpleTime=0;scorchAllCHMode=false;scorchPurpleTotal=0;ndMorph=nil;scorchTPIndex=0;scorchTPTable={};scorchTPCycle=false;xfStartTime=0
 for _,v in pairs(activeTG)do if v.gui then pcall(function()v.gui:Destroy()end)end end;activeShowers={};activeBlooms={};activeCocos={};activeTG={};tokenVerify={};tokenBL=setmetatable({},{__mode="k"});greenCH_cache=setmetatable({},{__mode="k"})
 for fl in pairs(flameCD)do flameCD[fl]=nil end;for fl in pairs(scytheParts)do scytheParts[fl]=nil end
 if xfC then xfC:Destroy();xfC=nil end;if scVis then scVis:Destroy();scVis=nil end;if syVis then syVis:Destroy();syVis=nil end
 for _,l in ipairs(diagLines)do pcall(function()l:Destroy()end)end;diagLines={};if diagVis then pcall(function()diagVis:Destroy()end);diagVis=nil end
 task.spawn(function()if writefile then local qc=0;for _ in pairs(QT)do qc=qc+1 end;pcall(function()writefile("marmot_z_q.json",H:JSONEncode({version=Q_VERSION,qtable=QT,scorchSessions=scorchSessions,bestScorch=bestSH,top10=top10,eligibility=eligibility,visitCount=visitCount,totalSteps=totalSteps,meta={sc=qc,sa=os.time()}}))end)end end)
end)
print("Marmot Z HR v4.0 — 6 Features: Predict, SpatialState, MomentumStrafing, PER, XFCamp, TabbedGUI+AutoSmoothie")
