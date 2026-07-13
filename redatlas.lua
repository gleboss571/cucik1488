-- BSS AI v16.9 — Shower prio, TP→CH, no spin, PARSE safe
-- FIXES: scorch CH priority, coconut full wait, flame clusters, TP→CH cycle, 9+ duped
local P=game:GetService("Players");local W=game:GetService("Workspace")
local R=game:GetService("RunService");local U=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage");local H=game:GetService("HttpService")
local V=game:GetService("VirtualInputManager");local L=P.LocalPlayer
local G=L:WaitForChild("PlayerGui");local ENABLED=true;local ELA=true
if not math.round then math.round=function(n)return math.floor(n+.5)end end
Q_VERSION="v16.9"
wait(2)

-- ERROR GUI
local elog,egui,elbl,ebtn,ecnt={},nil,nil,nil,0
local function mkE()pcall(function()if egui then return end
egui=Instance.new("ScreenGui");egui.Name="E";egui.ResetOnSpawn=false;egui.Parent=G
local b=Instance.new("Frame",egui);b.Size=UDim2.new(0,380,0,240);b.Position=UDim2.new(.5,-190,.5,-120)
b.BackgroundColor3=Color3.fromRGB(15,15,25);b.BackgroundTransparency=.08;b.BorderSizePixel=0;b.Active=true;b.Draggable=true
Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
local t=Instance.new("TextLabel",b);t.Size=UDim2.new(1,-16,0,24);t.Position=UDim2.new(0,8,0,8);t.BackgroundTransparency=1
t.Text="BSS AI v16.9";t.TextColor3=Color3.fromRGB(255,180,60);t.Font=Enum.Font.GothamBold;t.TextSize=14;t.TextXAlignment=Enum.TextXAlignment.Left
elbl=Instance.new("TextLabel",b);elbl.Size=UDim2.new(1,-16,0,130);elbl.Position=UDim2.new(0,8,0,42);elbl.BackgroundTransparency=1
elbl.Text="v16.9 boot...";elbl.TextColor3=Color3.fromRGB(200,200,200);elbl.Font=Enum.Font.Code;elbl.TextSize=11;elbl.TextWrapped=true;elbl.RichText=true
ebtn=Instance.new("TextButton",b);ebtn.Size=UDim2.new(0,140,0,28);ebtn.Position=UDim2.new(0,8,0,180)
ebtn.Text="Copy logs";ebtn.TextColor3=Color3.fromRGB(220,220,220);ebtn.Font=Enum.Font.Gotham;ebtn.TextSize=11
Instance.new("UICorner",ebtn).CornerRadius=UDim.new(0,4)
local cb=Instance.new("TextButton",b);cb.Size=UDim2.new(0,80,0,28);cb.Position=UDim2.new(0,156,0,180)
cb.Text="Close";cb.TextColor3=Color3.fromRGB(220,220,220);cb.Font=Enum.Font.Gotham;cb.TextSize=11
Instance.new("UICorner",cb).CornerRadius=UDim.new(0,4)
cb.MouseButton1Click:Connect(function()egui.Enabled=false;egui:Destroy()end)
ebtn.MouseButton1Click:Connect(function()local x=table.concat(elog,"
");if#x==0 then x="No errors"end;pcall(setclipboard,x);ebtn.Text="Done";wait(1.5);ebtn.Text="Copy logs"end)
spawn(function()wait(4);if egui and ecnt==0 then egui.Enabled=false;egui:Destroy()end end)
end)end
local function le(m)ecnt=ecnt+1;table.insert(elog,string.format("[%02d] %s",ecnt,m));while#elog>20 do table.remove(elog,1)end;if elbl then local L={};for i=math.max(1,#elog-12),#elog do table.insert(L,elog[i])end;elbl.Text=table.concat(L,"
");if ecnt==1 then elbl.TextColor3=Color3.fromRGB(255,140,100)end end;warn("BSSAI:",m)end
local function lo(m)if elbl then elbl.Text="o "..m;elbl.TextColor3=Color3.fromRGB(140,255,160)end end
mkE();lo("GUI OK")

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
DPRI={[4519549299]=true,[2499540966]=true,[2499514197]=true,[4528379338]=true,[1442859163]=true,[1442863423]=true,[3877732821]=true,[1442764904]=true,[4528208186]=true,[8173559749]=true}
FLAME_CLUSTER_RADIUS=8;FLAME_CLUSTER_MIN=4;FLAME_PATH_STEP=6

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

-- HELPERS
local function h()local c=L.Character;if c then return c:FindFirstChild("HumanoidRootPart")end;return nil end
local function hm()local c=L.Character;if c then return c:FindFirstChildOfClass("Humanoid")end;return nil end
local function ti(t)if not t then return nil end;return tonumber(t:match("rbxassetid://(%d+)")or t:match("id=(%d+)"))end
local function d3(a,b)local dx=a.X-b.X;local dz=a.Z-b.Z;return math.sqrt(dx*dx+dz*dz)end
local function d3d(a,b)return(a-b).Magnitude end
local function d2Sq(a,b)local dx=a.X-b.X;local dz=a.Z-b.Z;return dx*dx+dz*dz end
local function fmtH(v)if v>=1e12 then return string.format("%.2fT",v/1e12)end;if v>=1e9 then return string.format("%.2fB",v/1e9)end;if v>=1e6 then return string.format("%.2fM",v/1e6)end;if v>=1e3 then return string.format("%.1fK",v/1e3)end;return string.format("%.0f",v)end
local function getHoney()local cs=L:FindFirstChild("CoreStats");if cs then local hv=cs:FindFirstChild("Honey");if hv then return hv.Value or 0 end end;return 0 end
-- v16.9 3-LAYER PRECISION: InvokeServer → GUI → Manual Counter
local precSrc="invoke";local precManual=0;local precManualCH=0;local precCache={data=nil,t=0};local okTimes={};local backoff=0
local function precFromInvoke()
 local rps=RS:FindFirstChild("Events")and RS.Events:FindFirstChild("RetrievePlayerStats")
 if not rps then return false end
 if precCache.data and tick()-precCache.t<3 then
  local b=precCache.data;if b and b.Removed~=true then local rv=b.Value;prec.val=tonumber(rv or 0)or 0;local ns=math.min(PMX,math.round(prec.val/PPK));prec.isX=(ns>=PMX);prec.st=ns;if prec.isX then prec.ls=os.clock();prec.sD=60;prec.nR=false;rCC=0 end end;return true end
 local ok,res=pcall(function()return rps:InvokeServer()end)
 if not ok or type(res)~="table"then return false end
 local fd={};local function ffb(t,d)if type(t)~="table"then return end;local bid=rawget(t,"BuffID");if bid then d[bid]=t end;for _,v in pairs(t)do if type(v)=="table"then ffb(v,d)end end end;ffb(res,fd)
 local b=fd[2574507284]or fd["Precision"];precCache.data=b;precCache.t=tick()
 if b and rawget(b,"Removed")~=true then local rv=rawget(b,"Value");prec.val=tonumber(rv or 0)or 0;local ns=math.min(PMX,math.round(prec.val/PPK));prec.isX=(ns>=PMX);prec.st=ns;if prec.isX then prec.ls=os.clock();prec.sD=60;prec.nR=false;rCC=0 end;precSrc="invoke";return true end
 prec.val=0;prec.st=0;prec.isX=false;return true end
local function precFromGUI()
 for _,o in ipairs(G:GetDescendants())do if o:IsA("TextLabel")then local t=o.Text;local n=t:match("x(%d+)")or t:match("Prec[^%d]*(%d+)")
  if n then local s=tonumber(n);if s and s>=0 and s<=10 then prec.st=s;prec.isX=(s>=PMX);prec.val=s*PPK;if prec.isX then prec.ls=os.clock();prec.sD=60;prec.nR=false;rCC=0 end;precSrc="gui";return true end end end;return false end
local function precFromManual()
 if prec.isX then prec.ls=os.clock();prec.sD=60;return true end;precSrc="manual";return false end
local function pollPrecision()
 precFromInvoke()or precFromGUI()or precFromManual()
 if prec.ls>0 then prec.tL=math.max(0,prec.sD-(os.clock()-prec.ls));prec.nR=prec.isX and(prec.tL<=PRAT);if prec.nR and rCC==0 then rST=tick();rCC=0 end end;if prec.tL<=0 and prec.isX then prec.isX=false;prec.st=0;prec.val=0;prec.ls=0 end end
spawn(function()while true do wait(0.5)if ENABLED and mLS then spawn(function()pcall(pollPrecision)end)end end end)
R.Heartbeat:Connect(function()if prec.ls>0 then prec.tL=math.max(0,prec.sD-(os.clock()-prec.ls));prec.nR=prec.isX and(prec.tL<=PRAT)end end)
print("BSS AI v16.9 — 3-layer Precision: invoke→gui→manual + PARSE immune")
