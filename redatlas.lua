-- BSS AI v15.2 — v14.7 SKELETON + CoreStats + ScorchRec + BUILD TP + AntiLag (Lua 5.1)
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local VIM=game:GetService("VirtualInputManager")
local LP=Players.LocalPlayer
local PGui=LP:WaitForChild("PlayerGui")
local Q_VERSION,ENABLED="15.2",true

-- === GUI ОШИБОК ===
local elog,egui,elbl,ebtn,ecnt={},nil,nil,nil,0
local function mkErrGui() pcall(function() if egui then return end
egui=Instance.new("ScreenGui");egui.Name="BSSAI_Err";egui.ResetOnSpawn=false;egui.Parent=PGui
local bg=Instance.new("Frame",egui);bg.Size=UDim2.new(0,380,0,240);bg.Position=UDim2.new(.5,-190,.5,-120)
bg.BackgroundColor3=Color3.fromRGB(15,15,25);bg.BackgroundTransparency=.08;bg.BorderSizePixel=0;bg.Active=true;bg.Draggable=true
Instance.new("UICorner",bg).CornerRadius=UDim.new(0,8)
local t=Instance.new("TextLabel",bg);t.Size=UDim2.new(1,-16,0,24);t.Position=UDim2.new(0,8,0,8);t.BackgroundTransparency=1
t.Text="⚠ BSS AI v15.2 — Error Log";t.TextColor3=Color3.fromRGB(255,180,60);t.Font=Enum.Font.GothamBold;t.TextSize=14;t.TextXAlignment=Enum.TextXAlignment.Left
local sep=Instance.new("Frame",bg);sep.Size=UDim2.new(1,-16,0,1);sep.Position=UDim2.new(0,8,0,36);sep.BackgroundColor3=Color3.fromRGB(80,80,100);sep.BorderSizePixel=0
elbl=Instance.new("TextLabel",bg);elbl.Size=UDim2.new(1,-16,0,130);elbl.Position=UDim2.new(0,8,0,42);elbl.BackgroundTransparency=1
elbl.Text="⏳ Иниц...";elbl.TextColor3=Color3.fromRGB(200,200,200);elbl.Font=Enum.Font.Code;elbl.TextSize=11
elbl.TextXAlignment=Enum.TextXAlignment.Left;elbl.TextYAlignment=Enum.TextYAlignment.Top;elbl.TextWrapped=true;elbl.RichText=true
ebtn=Instance.new("TextButton",bg);ebtn.Size=UDim2.new(0,140,0,28);ebtn.Position=UDim2.new(0,8,0,180)
ebtn.BackgroundColor3=Color3.fromRGB(60,60,80);ebtn.BorderSizePixel=0;ebtn.Text="📋 Копировать логи";ebtn.TextColor3=Color3.fromRGB(220,220,220);ebtn.Font=Enum.Font.Gotham;ebtn.TextSize=11
Instance.new("UICorner",ebtn).CornerRadius=UDim.new(0,4)
local cb=Instance.new("TextButton",bg);cb.Size=UDim2.new(0,80,0,28);cb.Position=UDim2.new(0,156,0,180)
cb.BackgroundColor3=Color3.fromRGB(60,60,80);cb.BorderSizePixel=0;cb.Text="✕ Закрыть";cb.TextColor3=Color3.fromRGB(220,220,220);cb.Font=Enum.Font.Gotham;cb.TextSize=11
Instance.new("UICorner",cb).CornerRadius=UDim.new(0,4)
cb.MouseButton1Click:Connect(function() egui.Enabled=false;egui:Destroy();egui=nil end)
ebtn.MouseButton1Click:Connect(function() local txt=table.concat(elog,"\n");if#txt==0 then txt="Нет ошибок"end;pcall(setclipboard,txt);ebtn.Text="✅ Скоп.";task.wait(1.5);ebtn.Text="📋 Копировать логи"end)
task.spawn(function() task.wait(4);if egui and ecnt==0 then egui.Enabled=false;egui:Destroy();egui=nil end end) end) end
local function logErr(m) ecnt=ecnt+1;table.insert(elog,string.format("[%02d] %s",ecnt,m));while#elog>20 do table.remove(elog,1)end;if elbl then local L={};for i=math.max(1,#elog-12),#elog do table.insert(L,elog[i])end;elbl.Text=table.concat(L,"\n");if ecnt==1 then elbl.TextColor3=Color3.fromRGB(255,140,100)end end;warn("BSSAI:",m)end
local function logOk(m) if elbl then elbl.Text="✅ "..m;elbl.TextColor3=Color3.fromRGB(140,255,160)end end
mkErrGui();logOk("GUI ошибок запущен")

-- === КОНФИГ ===
local SB={["НАБОР"]=70,["X10"]=90,["REFRESH"]=75};local SJ=3
local AM,DGL,FM,AD,MT=1.2,22,3,5,6
local PBI,PPK,PMX,PRAT=2574507284,0.02,10,15
local PURP,PTOL,PST=Color3.fromRGB(119,85,255),12,1
local SMI,SMRT,TSD=5877939956,15,1.1
local CAR,CAS,CAD=28,20,0.1
local ARR,TLID=20,20
local PCD,PFM=8,20
local TPI,TLC,PT,XCR=8173559749,2,8,12
local PCHR=10
local AL,GA,EP,ED=0.5,0.95,0.3,0.9995
local PMBI=2499540966
local FOCI,RBOI=2577384907,2577383393
local FOCUS_RENEW=10;local RB_RENEW=7;local RB_SCORCH_RENEW=9
local SCORCH_BIAS=1.15;local PRELOAD_BIAS=1.3
local PAT_WINDOW=2400;local PAT_TOP=10

local TKS={[1629547638]={n="Token Link",b=4,p=99},[2000457501]={n="Inspire",b=8,p=25},[1472256444]={n="Baby Love",b=8,p=22},[1629649299]={n="Focus",b=4,p=15},[65867881]={n="Haste",b=4,p=15},[1442863423]={n="Blue Boost",b=4,p=12},[1442859163]={n="Red Boost",b=4,p=12},[3877732821]={n="White Boost",b=4,p=12},[1442700745]={n="Rage",b=8,p=10},[253828517]={n="Melody",b=8,p=10},[1472532912]={n="Polar Bear",b=15,p=8,mo=true},[1472491940]={n="Black Bear",b=15,p=8,mo=true},[1472425802]={n="Brown Bear",b=15,p=8,mo=true},[2032949183]={n="Mother Bear",b=15,p=8,mo=true},[1472580249]={n="Panda",b=15,p=8,mo=true},[1489734171]={n="Science Bear",b=15,p=8,mo=true},[1874564120]={n="Pulse",b=12,p=7},[2499514197]={n="Honey Mark",b=8,p=7},[2499540966]={n="Pollen Mark",b=8,p=7},[4528379338]={n="Mark Surge",b=4,p=7},[3582501342]={n="Rain Call",b=24,p=6},[3582519526]={n="Tornado",b=24,p=6},[5877998606]={n="Mind Hack",b=16,p=6},[8083943936]={n="Surprise Party",b=24,p=6},[177997841]={n="Glob",b=4,p=6},[1839454544]={n="Gummy Storm",b=4,p=6},[1442725244]={n="Bomb",b=4,p=5},[5877939956]={n="Smile",b=4,p=5},[4519549299]={n="Inferno",b=4,p=5},[4519523935]={n="Triangulate",b=4,p=5},[4528414666]={n="Summon Frog",b=8,p=5},[4528208186]={n="Flame Fuel",b=8,p=5},[1671281844]={n="Beamstorm",b=12,p=4},[1442764904]={n="Red Bomb+",b=4,p=12},[8083436978]={n="Blue Balloon",b=4,p=4},[1104415222]={n="BondToken",b=4,p=4},[2319100769]={n="Fetch",b=8,p=4},[4889322534]={n="Fuzz Bombs",b=4,p=4},[2319083910]={n="Impale",b=24,p=4},[3080529618]={n="Jelly Bean",b=4,p=4},[4889470194]={n="Pollen Haze",b=4,p=4},[8173559749]={n="Target Practice",b=8,p=3},[107187190]={n="Honey Gift",b=4,p=2},[183390139]={n="Cog",b=4,p=2}}
local AV={[1674871631]=true,[1471882621]=true,[1952740625]=true,[8055428094]=true,[2319943273]=true,[3030569073]=true,[3036899811]=true,[3080740120]=true,[3012679515]=true,[1838129169]=true,[2584584968]=true,[1471849394]=true,[1952682401]=true,[6087969886]=true,[2028574353]=true,[2028453802]=true}
local PC={["Red"]=Color3.fromRGB(249,34,34),["Pink"]=Color3.fromRGB(255,130,201),["Merigold"]=Color3.fromRGB(218,168,28),["Periwinkle"]=Color3.fromRGB(150,156,236),["Violet"]=Color3.fromRGB(94,38,177),["Scarlet"]=Color3.fromRGB(171,19,19),["Green"]=Color3.fromRGB(35,232,5),["Yellow"]=Color3.fromRGB(238,204,79),["Black"]=Color3.fromRGB(11,11,11),["Grey"]=Color3.fromRGB(127,127,127),["Blue"]=Color3.fromRGB(33,66,249),["Cyan"]=Color3.fromRGB(29,196,222),["White"]=Color3.fromRGB(249,249,249)}
local PP={Red=1,Pink=2,Merigold=3,Periwinkle=4,Violet=5,Scarlet=6,Green=7,Yellow=8,Black=9,Grey=10,Blue=11,Cyan=12,White=13}

local SCO_TIPS={"📝 Scorching Star на 25-26 токенах, xFlame ~18","📝 Не бегай активно — пчёлы чаще дают токены","📝 Стой в марках когда Precise Bees стреляют!","📝 Не забывай ставить новые Precision Marks","📝 Digital копирует морф = дотяни до Scorch","📝 Focus x10 + Red Boost x10 = база"}
local scoIdx=0

-- === КОЛЛЕКЦИИ ===
local aT,cQ,lP,curF,tL={},{},nil,nil,"старт"
local prec={st=0,val=0,isX=false,ls=0,sD=60,sS=0,tL=0,nR=false}
local cyc={chC=0};local st={tk=0,ch=0,pr=0,x10=0,rf=0,tR=0,dc=0,sm=0,chA=0,pt=0,chP=0}
local INT,isCS,smT,smTR,igT=false,false,nil,0,0
local fP,aR,aRR={},nil,ARR
local aB={SS={st=0},XF={st=0},PM={a=false},PoM={a=false,pos=nil,m=0},FC={combo=0,dur=20,tL=0},RB={combo=0,dur=15,tL=0}}
local stP=setmetatable({},{__mode="k"})
local rCC,rST=0,0
local hB,aBf,pH,bAH,laT,pF={},{},{},0,0,"bss_ai_pat_v15.json"
local QT,lMT,stW,xfE,xfC,lPT={},tick(),false,false,nil,0
local qTables,pHTables={},{}
local fldHash=nil
local dupCnt=0
local cS=SB["НАБОР"]
local hbF,isA=0,false
local focusRenew,rbSkip=false,false
local isSuperScorch=false

-- v15.2: Honey + Scorch recording
local scriptStartHoney=0;local scriptStartTime=0
local scorchStartHoney=0;local scorchStartTime=0;local scorchActive=false
local scorchRecording=false;local scorchActions={}
local scorchSessions={};local top10patterns={};local bestScorchHoney=0
local preloadPatterns={};local lastPatternSave=0

-- === УТИЛИТЫ ===
local function h() local c=LP.Character;if c then return c:FindFirstChild("HumanoidRootPart")end end
local function hm() local c=LP.Character;if c then return c:FindFirstChildOfClass("Humanoid")end end
local function ti(t) if not t then return nil end;return tonumber(t:match("rbxassetid://(%d+)")or t:match("id=(%d+)"))end
local function d3(a,b) return(Vector3.new(a.X,0,a.Z)-Vector3.new(b.X,0,b.Z)).Magnitude end
local function d3d(a,b) return(a-b).Magnitude end
local function d2Sq(a,b) local dx=a.X-b.X;local dz=a.Z-b.Z;return dx*dx+dz*dz end
local function ph() if not prec.isX then return"НАБОР" elseif prec.nR then return"REFRESH" else return"X10"end end
local function scPh() return aB.SS.st>0 and"INSIDE"or"OUTSIDE"end
local function fmtHoney(v)if v>=1e12 then return string.format("%.2fT",v/1e12)elseif v>=1e9 then return string.format("%.2fB",v/1e9)elseif v>=1e6 then return string.format("%.2fM",v/1e6)elseif v>=1e3 then return string.format("%.1fK",v/1e3)else return string.format("%.0f",v)end end
local function getCoreHoney()local cs=LP:FindFirstChild("CoreStats");if cs then local hv=cs:FindFirstChild("Honey");if hv then return hv.Value or 0 end end;return 0 end
local function getCtxKey()return string.format("%s|%s|%s|%d",ph(),aB.FC.combo>=10 and"F1"or"F0",aB.RB.combo>=10 and"R1"or"R0",math.min(3,aB.PoM.m))end

-- === FIELD HASH ===
local function fldHashFn() if not curF or not curF.part then return"unknown"end;local c=curF.part.Position;return string.format("%.0f_%.0f",c.X/50,c.Z/50)end
local function swFld() local nh=fldHashFn();if nh~=fldHash then if qTables[fldHash]then qTables[fldHash]=QT end;if pHTables[fldHash]then pHTables[fldHash]=pH end;fldHash=nh;QT=qTables[fldHash]or{};pH=pHTables[fldHash]or{}end end

local function fF()
  local r=h();if not r then return curF end;local mp=r.Position
  local z=Workspace:FindFirstChild("FlowerZones")
  if z then local be,bd=nil,math.huge
    for _,zn in ipairs(z:GetChildren())do if zn:IsA("BasePart")then local d=d3(mp,zn.Position);local s=zn.Size
      if math.abs(mp.X-zn.Position.X)<=s.X/2+20 and math.abs(mp.Z-zn.Position.Z)<=s.Z/2+20 then if d<bd then bd=d;be=zn end end
    end end
    if be then curF={part=be};swFld();return curF end
  end
  local fl=Workspace:FindFirstChild("Flowers")
  if fl then local fp={};for _,f in ipairs(fl:GetChildren())do if f:IsA("BasePart")then table.insert(fp,f.Position)end end
    if#fp>0 then local mnX,mxX,mnZ,mxZ=math.huge,-math.huge,math.huge,-math.huge
      for _,p in ipairs(fp)do if p.X<mnX then mnX=p.X end;if p.X>mxX then mxX=p.X end;if p.Z<mnZ then mnZ=p.Z end;if p.Z>mxZ then mxZ=p.Z end end
      curF={part={Position=Vector3.new((mnX+mxX)/2,mp.Y,(mnZ+mxZ)/2),Size=Vector3.new(math.abs(mxX-mnX)+10,1,math.abs(mxZ-mnZ)+10)}};swFld();return curF end end
  if aR then curF={part={Position=aR.Position,Size=Vector3.new(aRR*3,1,aRR*3)}};swFld();return curF end;return curF
end
local function gAS() local p=ph();local b=isSuperScorch and 55 or(SB[p]or SB["НАБОР"]);if hbF%30==0 then local base=b+(math.random()*2-1)*SJ;if math.abs(base-cS)>1 then cS=base end end;return cS end
local function gFC() if curF and curF.part then return curF.part.Position end;local r=h();return r and r.Position or Vector3.zero end
local function cP(pos,sk) if sk then return pos end;if not curF then return pos end;local c=curF.part.Position;local s=curF.part.Size;local mx=math.max(s.X/2-FM,1);local mz=math.max(s.Z/2-FM,1);local cl=Vector3.new(math.clamp(pos.X,c.X-mx,c.X+mx),pos.Y,math.clamp(pos.Z,c.Z-mz,c.Z+mz));if aB.XF.st>=20 then local dx=cl.X-c.X;local dz=cl.Z-c.Z;local dSq=dx*dx+dz*dz;if dSq>0 then local invD=1/math.sqrt(dSq);cl=Vector3.new(c.X+dx*invD*XCR,cl.Y,c.Z+dz*invD*XCR)end end;return cl end
local function iF(pos) if not curF then return false end;local c=curF.part.Position;local s=curF.part.Size;return math.abs(pos.X-c.X)<=s.X/2+PFM and math.abs(pos.Z-c.Z)<=s.Z/2+PFM end

-- === КЭШ (для анти-лага) ===
local CACHE={}
local function cfc(p,n) if not p then return nil end;if CACHE[n]==nil then CACHE[n]=p:FindFirstChild(n)or false end;local r=CACHE[n];if r==false or(r and not r.Parent)then local ok,found=pcall(function()return p:FindFirstChild(n)end);if ok then CACHE[n]=found or false else CACHE[n]=false end end;return CACHE[n]~=false and CACHE[n]or nil end

-- === AREA RING ===
local function fAR() local p=Workspace:FindFirstChild("Particles");if p then for _,o in ipairs(p:GetChildren())do if o.Name=="AreaRing"and o:IsA("BasePart")then aR=o;aRR=(o.Size.X+o.Size.Z)/4;if aRR<5 then aRR=ARR end;return end end end;aR=Workspace:FindFirstChild("AreaRing");if aR and aR:IsA("BasePart")then aRR=(aR.Size.X+aR.Size.Z)/4;if aRR<5 then aRR=ARR end else aR=nil;aRR=ARR end end

-- === КРОСХЕИРЫ ===
local Pt=Workspace:FindFirstChild("Particles")or workspace:WaitForChild("Particles",10)
local function iCl(a,b,tl) tl=tl or PTOL;return math.abs(a.R*255-b.R*255)<=tl and math.abs(a.G*255-b.G*255)<=tl and math.abs(a.B*255-b.B*255)<=tl end
local function iP(p) local ok,c=pcall(function()return p.Color end);if ok and c and iCl(c,PURP)then return true end;local ok2,bc=pcall(function()return p.BrickColor.Color end);return ok2 and bc and iCl(bc,PURP)end
local function aCH(o) if o.Name~="Crosshair"or not o:IsA("BasePart")then return end;for _,ch in ipairs(cQ)do if ch.part==o then return end end;if not o.Parent then return end;table.insert(cQ,{part=o,sT=tick(),col=false,isP=iP(o)})end
if Pt then Pt.DescendantAdded:Connect(aCH);Pt.DescendantRemoving:Connect(function(o)for i=#cQ,1,-1 do if cQ[i].part==o then table.remove(cQ,i)break end end;if lP==o then lP=nil end end);for _,o in ipairs(Pt:GetDescendants())do aCH(o)end end
local function clnCH() for i=#cQ,1,-1 do if not cQ[i].part.Parent or cQ[i].col then table.remove(cQ,i)end end end
local function gCH(op,oR,purpFirst)
  local L={};local P={}
  for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent then
    if(op and ch.isP)or(oR and not ch.isP)or(not op and not oR)then
      if purpFirst and ch.isP then table.insert(P,ch)else table.insert(L,ch)end
    end
  end end
  table.sort(L,function(a,b)return a.sT<b.sT end);table.sort(P,function(a,b)return a.sT<b.sT end)
  if purpFirst then for _,p in ipairs(P)do table.insert(L,1,p)end end
  return L
end
local function gPCH() return gCH(true,false) end
local function gTPG_build()
  local all=gCH(false,false);if#all<3 then return nil end
  local G={};local i=1
  while i<=#all-2 do local a,b,c=all[i],all[i+1],all[i+2]
    if not a.isP and not b.isP and c.isP then if c.sT-a.sT<=2 then table.insert(G,{r1=a,r2=b,pr=c});i=i+3 else i=i+1 end
    else i=i+1 end
  end;return#G>0 and G or nil
end
local function gTPG() if not prec.isX or prec.nR then return nil end;return gTPG_build() end

-- === ИЗБЕГАНИЕ CH ===
local cATCache,cATFrame={},0
local function gRCT(mP,dP)
  if focusRenew or isSuperScorch then return{}end
  if not prec.isX or prec.nR then return{}end
  if cATFrame==hbF and cATCache[mP]then return cATCache[mP]end
  local mf=Vector3.new(mP.X,0,mP.Z);local df=Vector3.new(dP.X,0,dP.Z);local tt=df-mf;if tt.Magnitude<1 then return{}end
  local tD=tt.Unit;local th={}
  for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent and not ch.isP then local cf=Vector3.new(ch.part.Position.X,0,ch.part.Position.Z);local toCh=cf-mf;local d=toCh.Magnitude;if d<CAR and d>1 then local dot=toCh.Unit:Dot(tD);if dot>CAD then local cross=math.abs(toCh.X*tD.Z-toCh.Z*tD.X);if cross<CAR then table.insert(th,{ch=ch,pos=cf,dist=d,cross=cross})end end end end end
  cATFrame=hbF;cATCache={};cATCache[mP]=th;return th end
local function cAT(mP,dP) local th=gRCT(mP,dP);if#th==0 then return nil end;table.sort(th,function(a,b)return a.dist<b.dist end);local t=th[1];local mf=Vector3.new(mP.X,0,mP.Z);local df=Vector3.new(dP.X,0,dP.Z);local tD=(df-mf).Unit;local toCh=t.pos-mf;local p1=Vector3.new(-toCh.Unit.Z,0,toCh.Unit.X);local p2=Vector3.new(toCh.Unit.Z,0,-toCh.Unit.X);local bp=(p2:Dot(tD)>=p1:Dot(tD))and p2 or p1;local ap=t.pos+bp*CAS;st.chA=st.chA+1;return cP(Vector3.new(ap.X,mP.Y,ap.Z))end
local function gDTC() local c=0;local r=h();if not r then return 0 end;for p,t in pairs(aT)do if not t.col and t.dp and p.Parent then if d3(r.Position,p.Position)<80 then c=c+1 end end end;return c end

-- === СБОР CH ПО ПУТИ ===
local function tryCollectNearbyCH(origTargetPart)
  local r=h();if not r then return end
  for _,ch in ipairs(cQ)do
    if not ch.col and ch.part.Parent and ch.part~=origTargetPart then
      if d3(r.Position,ch.part.Position)<=PCHR then
        local hm_=hm();if hm_ then hm_:MoveTo(ch.part.Position)end
        local t0=tick()
        while tick()-t0<1.2 do task.wait(0.04)
          local r2=h();if not r2 or not ch.part.Parent then break end
          if d3(r2.Position,ch.part.Position)<=4 then ch.col=true;st.chP=st.chP+1
            if ch.isP then st.pr=st.pr+1;lP=ch.part else st.ch=st.ch+1 end;break
          end
        end;break
      end
    end
  end
end

-- === GO TO ===
local function goTo(tP,rad,to,sk)
  rad=rad or AD;to=math.min(to or MT,12);if tP==Vector3.zero then return false end
  local r=h();local hm_=hm();if not r or not hm_ then return false end
  tP=cP(tP,sk);if tP==Vector3.zero then local c=gFC();if c==Vector3.zero then return false end;tP=c end
  local oT=Vector3.new(tP.X,r.Position.Y,tP.Z);local cM=oT
  local av=cAT(r.Position,oT);if av then cM=Vector3.new(av.X,r.Position.Y,av.Z)end
  hm_:MoveTo(cM);local t0=tick();local lM=tick();local lA=tick();local lPC=tick()
  while tick()-t0<to do task.wait(0.04)
    if not ENABLED or INT then return false end
    r=h();if not r then return false end
    if d3(r.Position,oT)<=rad then return true end
    if tick()-lA>=0.15 then lA=tick();local na=cAT(r.Position,oT);if na then cM=Vector3.new(na.X,r.Position.Y,na.Z)else cM=oT end end
    if cM~=oT and d3(r.Position,cM)<=4 then local na=cAT(r.Position,oT);cM=na and Vector3.new(na.X,r.Position.Y,na.Z)or oT end
    if tick()-lPC>=0.25 then lPC=tick();tryCollectNearbyCH(nil)end
    if tick()-lM>=0.3 then hm_=hm();if hm_ then hm_:MoveTo(cM)end;lM=tick()end
  end;return false
end

-- === ТОКЕНЫ ===
local function rT(o) if o.Name~="C"or not o:IsA("BasePart")or aT[o]or tick()<igT then return end;local fr=o:FindFirstChild("FrontDecal");if not fr or not fr:IsA("Decal")then return end;local id=ti(fr.Texture);if not id or AV[id]then return end;local df=TKS[id];if not df then return end;local r=h();local dp=r and(o.Position.Y-r.Position.Y)>5;local lf=df.b*AM;if dp then lf=lf*(2+0.05*(DGL-1));dupCnt=dupCnt+1 end;aT[o]={id=id,n=df.n,p=df.p,mo=df.mo or false,s=tick(),l=lf,dp=dp,col=false}end
Workspace.DescendantAdded:Connect(function(o)task.wait(0.05)pcall(rT,o)end)
for _,o in ipairs(Workspace:GetDescendants())do pcall(rT,o)end
game.DescendantRemoving:Connect(function(o)if aT[o]then if aT[o].col then st.tk=st.tk+1 end;if aT[o].dp then dupCnt=math.max(0,dupCnt-1)end;aT[o]=nil end end)

-- === BUFFS ===
local rps=RS:FindFirstChild("Events")and RS.Events:FindFirstChild("RetrievePlayerStats")
local function flatBuffs(t,d)
  if type(t)~="table"then return end
  local bid=rawget(t,"BuffID");if bid then d[bid]=t end
  for _,v in pairs(t)do flatBuffs(v,d)end
end
local function sBf() if not rps then return end;local ok,res=pcall(rps.InvokeServer,rps);if not ok or type(res)~="table"then return end
  local fd={};flatBuffs(res,fd)
  local prevSS=aB.SS.st
  local ss=fd["Scorching Star Aura"];aB.SS.st=ss and tonumber(rawget(ss,"Combo")or 0)or 0
  local xf=fd["X-Flame Aura"];aB.XF.st=xf and tonumber(rawget(xf,"Combo")or 0)or 0
  aB.PM.a=fd[2575093099]and rawget(fd[2575093099],"Removed")~=true
  local pm=fd[PMBI]
  if pm and rawget(pm,"Removed")~=true then aB.PoM.a=true;aB.PoM.m=tonumber(rawget(pm,"Value")or 0)or 1;if aR then aB.PoM.pos=aR.Position end else aB.PoM.a=false;aB.PoM.m=0 end
  local fc=fd[FOCI]
  if fc and rawget(fc,"Removed")~=true then aB.FC.combo=tonumber(rawget(fc,"Combo")or 0)or 0;aB.FC.dur=tonumber(rawget(fc,"Dur")or 20)or 20;aB.FC.tL=math.max(0,aB.FC.dur-(os.clock()-(tonumber(rawget(fc,"Start")or os.clock()))))else aB.FC.combo=0;aB.FC.tL=0 end
  local rb=fd[RBOI]
  if rb and rawget(rb,"Removed")~=true then aB.RB.combo=tonumber(rawget(rb,"Combo")or 0)or 0;aB.RB.dur=tonumber(rawget(rb,"Dur")or 15)or 15;aB.RB.tL=math.max(0,aB.RB.dur-(os.clock()-(tonumber(rawget(rb,"Start")or os.clock()))))else aB.RB.combo=0;aB.RB.tL=0 end
  -- SCORCH RECORDING
  local curHoney=getCoreHoney()
  if aB.SS.st>0 and prevSS==0 then
    scorchStartHoney=curHoney;scorchStartTime=tick();scorchActive=true;scorchRecording=true;scorchActions={}
  elseif aB.SS.st==0 and prevSS>0 then
    scorchActive=false
    if scorchRecording and scorchStartTime>0 then
      local gained=curHoney-scorchStartHoney;local dur=(tick()-scorchStartTime)/60
      if gained>0 then
        local ctx=getCtxKey()
        table.insert(scorchSessions,{honeyGained=gained,durationMin=math.floor(dur*10)/10,time=tick(),ssCombo=prevSS,ctx=ctx,actions=scorchActions})
        if gained>bestScorchHoney then bestScorchHoney=gained end
        table.insert(pH,{hps=gained,scorchHoney=gained,scorchDur=dur,actions=scorchActions,timestamp=tick(),isScorch=true})
        table.sort(pH,function(a,b)return(a.hps or 0)>(b.hps or 0)end)
        while#pH>30 do table.remove(pH)end
      end
      scorchRecording=false;scorchActions={}
    end
  end
end
local function sPr() if not rps then return end;local ok,pd=pcall(rps.InvokeServer,rps);if not ok or type(pd)~="table"then return end
  local fd={};flatBuffs(pd,fd)
  local b=fd[PBI]
  if b and rawget(b,"Removed")~=true then local val=tonumber(b.Value)or 0;if tonumber(b.Start)~=prec.sS then prec.sS=tonumber(b.Start)or 0;prec.sD=tonumber(b.Dur)or 60;prec.ls=os.clock()end;prec.st=math.min(PMX,math.round(val/PPK));prec.val=val;prec.isX=(prec.st>=PMX)else prec.st=0;prec.val=0;prec.isX=false end
  if prec.ls>0 then prec.tL=math.max(0,prec.sD-(os.clock()-prec.ls));prec.nR=prec.isX and(prec.tL<=PRAT);if prec.nR and rCC==0 then rST=tick();rCC=0 end end
end

-- === PETALS ===
local function gPC(p) for n,co in pairs(PC)do if(co.R-p.Color.R)^2+(co.G-p.Color.G)^2+(co.B-p.Color.B)^2<0.002 then return n end end;return nil end
local function sPt() fP={};if not ENABLED or not curF then return end;local pt=Workspace:FindFirstChild("Particles");if not pt then return end;local r=h();if not r then return end
  for _,o in ipairs(pt:GetChildren())do if o.Name=="PetalPart"and o:IsA("BasePart")and iF(o.Position)then local cn=gPC(o);if cn and PP[cn]then table.insert(fP,{part=o,cn=cn,pr=PP[cn],dist=d3d(r.Position,o.Position)})end end end
  table.sort(fP,function(a,b)if a.pr~=b.pr then return a.pr<b.pr end;return a.dist<b.dist end)
end

-- === SMILE ===
local function sSm() local n=tick();smT=nil;smTR=0;local bp,bd,br=nil,math.huge,0;local r=h();if not r then return end;local hp=aB.PoM.a;local rp=aR and aR.Position
  if dupCnt<6 then return end
  for p,t in pairs(aT)do if not t.col and p.Parent and t.id==SMI then local rem=t.l-(n-t.s);if rem<=SMRT and rem>0 then local tk=false;if hp and rp then if d3(p.Position,rp)<=aRR*1.5 then tk=true end else tk=true end;if tk then local d=d3(r.Position,p.Position);if d<bd then bp=p;bd=d;br=rem end end end end end
  if bp then smT=bp;smTR=br;if not isCS then INT=true end end
end

local function uHB() local n=tick();if tL and tL~="старт"then local r=h();table.insert(aBf,{time=n,action=tL,pos=r and r.Position or Vector3.zero,phase=ph(),isSc=aB.SS.st>0,scPh=scPh(),isSS=isSuperScorch})end;local cut=n-300;while#aBf>0 and aBf[1].time<cut do table.remove(aBf,1)end end
local function gPB(action,pos) if#pH==0 then return 0 end;local p_=ph();local isSc=aB.SS.st>0;local be=0
  for _,p in ipairs(pH)do for _,pa in ipairs(p.actions)do if pa.action==action then if d2Sq(pos,pa.pos)<100 then local ms=((pa.phase==p_)and 2 or 1)*((pa.isSc==isSc)and 2 or 1)*((pa.scPh==scPh())and 1.5 or 1);if ms>be then be=ms end end end end end;return 15*be end

-- === PATTERN MGMT ===
local function recalcTop10()
  local now=tick();local recent={}
  for _,s in ipairs(scorchSessions)do if now-s.time<=PAT_WINDOW then table.insert(recent,s)end end
  table.sort(recent,function(a,b)return a.honeyGained>b.honeyGained end)
  top10patterns={};for i=1,math.min(PAT_TOP,#recent)do top10patterns[i]=recent[i]end
end
local function saveScorchSessions()
  if not writefile then return end;if tick()-lastPatternSave<120 then return end
  lastPatternSave=tick();recalcTop10()
  pcall(function()writefile("bss_ai_scorch_v15.json",Http:JSONEncode({version=Q_VERSION,scorchSessions=scorchSessions,bestScorch=bestScorchHoney,top10=top10patterns,time=tick()}))end)
end
local function getPatternBias(action)
  local ctx=getCtxKey();local bias=1.0
  for _,pp in ipairs(preloadPatterns)do if pp.ctx==ctx then for _,pa in ipairs(pp.actions)do if pa.action==action then bias=math.max(bias,PRELOAD_BIAS);break end end end end
  for _,tp in ipairs(top10patterns)do if tp.ctx==ctx then for _,ta in ipairs(tp.actions)do if ta.action==action then bias=math.max(bias,SCORCH_BIAS);break end end end end
  return bias
end
local function recordScorchAction(action) if not scorchRecording then return end;local r=h();table.insert(scorchActions,{action=action,pos=r and r.Position or Vector3.zero,phase=ph(),fc=(aB.FC.combo>=10 and 1 or 0),rb=(aB.RB.combo>=10 and 1 or 0),pm=math.min(3,aB.PoM.m),ssCombo=aB.SS.st})end

-- === Q-LEARNING ===
local function gQ(s,a)return(QT[s]and QT[s][a])or 0 end
local function sQ(s,a,v)if not QT[s]then QT[s]={}end;QT[s][a]=v end
local function hTL() for _,t in pairs(aT)do if not t.col and t.p>=90 and tick()>=igT then return true end end;return false end
local function gDTP() local n=tick();for p,t in pairs(aT)do if not t.col and p.Parent and t.id==TPI and t.dp then if t.l-(n-t.s)>1 then return p,t end end end;return nil,nil end
local function gSDA() local r=h();if not r then return nil end;local rp=aR and aR.Position;if not rp then return nil end;local bpSm,bdSm,bpTp,bdTp=nil,math.huge,nil,math.huge
  for p,t in pairs(aT)do if not t.col and p.Parent then
    if t.id==SMI and d3(p.Position,rp)<=aRR*1.5 then local d=d3(r.Position,p.Position);if d<bdSm then bdSm=d;bpSm=p end end
    if t.id==TPI and t.dp and d3(p.Position,rp)<=aRR*1.5 then local d=d3(r.Position,p.Position);if d<bdTp then bdTp=d;bpTp=p end end
  end end
  if bpSm and bpTp then local n=tick();local st_=aT[bpSm];local smRem=st_ and(st_.l-(n-st_.s))or 0;if smRem<=3 then return bpSm else return bpTp end
  elseif bpSm then return bpSm else return bpTp end
end
local function eS()
  local r=h();if not r then return"dead"end;local p_=ph();local tlD="none"
  for p,t in pairs(aT)do if not t.col and p.Parent and t.p>=90 then local d=d3(r.Position,p.Position);if d<20 then tlD="close"elseif d<60 then tlD="far"end end end
  local prN=math.min(3,#gCH(true,false));local rN=math.min(3,#gCH(false,true));local sU=(smT~=nil);local hP=(#fP>0);local nT=false;local n=tick()
  for p,t in pairs(aT)do if not t.col and p.Parent and(t.l-(n-t.s))>1 and d3(r.Position,p.Position)<30 then nT=true;break end end
  local zn="mid";if curF and curF.part and curF.part.Parent then local c=curF.part.Position;local s=curF.part.Size;if s.X>0 and s.Z>0 then local rx=math.abs(r.Position.X-c.X)/(s.X/2);local rz=math.abs(r.Position.Z-c.Z)/(s.Z/2);if rx>0.7 or rz>0.7 then zn="edge"elseif rx<0.3 and rz<0.3 then zn="center"end end end
  local chT="none";if prec.isX and not prec.nR then local ct=0;for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent and not ch.isP and d3(r.Position,ch.part.Position)<20 then ct=ct+1 end end;if ct>2 then chT="many"elseif ct>0 then chT="some"end end
  local sc=aB.SS.st>0 and"1"or"0";local xf=aB.XF.st>=20 and"1"or"0"
  local fcS=aB.FC.combo>=10 and"1"or"0";local rbS=aB.RB.combo>=10 and"1"or"0";local pmS=math.min(3,aB.PoM.m)
  return string.format("PH:%s|SC:%s|TL:%s|CH:%d|PR:%d|SM:%s|NT:%s|Z:%s|CT:%s|PT:%s|XF:%s|FC:%s|RB:%s|PM:%d",p_,scPh(),tlD,rN,prN,tostring(sU),tostring(nT),zn,chT,tostring(hP),xf,fcS,rbS,pmS)
end

-- === ДЕЙСТВИЯ ===
local function gAWB()
  local ba={};local p_=ph();local n=tick()
  focusRenew=(aB.FC.combo>=10 and aB.FC.tL>0 and aB.FC.tL<=FOCUS_RENEW)
  rbSkip=(aB.RB.combo>=10 and aB.RB.tL>0 and aB.RB.tL<=RB_RENEW)
  isSuperScorch=(aB.SS.st>0 and prec.isX and aB.PoM.m>=3)
  if isSuperScorch then
    local rbScorch=(aB.RB.combo>=10 and aB.RB.tL>0 and aB.RB.tL<=RB_SCORCH_RENEW)
    if rbScorch then local pp=gPCH();if#pp>0 then return{"go_purple_rb_renew"}end;local all=gCH(false,false);if#all>0 then return{"go_skip_one_ch"}end end
    local pp=gPCH();if#pp>=2 then return{"go_multi_purple"}end
    local all=gCH(false,false);if#all>0 then table.insert(ba,"go_crosshair_all")end
    if#ba>0 then return ba end;return{"patrol_ring"}
  end
  if focusRenew then local all=gCH(false,false);if#all>0 then return{"go_focus_renew"}end end
  if hTL()then return{"go_tokenlink"}end
  if p_~="НАБОР"then for p,t in pairs(aT)do if not t.col and p.Parent and(t.l-(n-t.s))<0.3 and(t.l-(n-t.s))>0 then return{"go_urgent_token"}end end end
  if smT and dupCnt>6 then return{"go_smile"}end
  if aB.PoM.a and aR and not isSuperScorch then local t=gSDA();if t then local td=aT[t];if td and td.id==SMI then table.insert(ba,1,"go_smile_area")elseif td and td.id==TPI and td.dp then table.insert(ba,1,"go_dup_area")end end end
  if xfE then local cc=gFC();local bC,bD=nil,XCR+1;if cc~=Vector3.zero then for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent then local d=d3(ch.part.Position,cc);if d<=XCR and d<bD then bD=d;bC=ch end end end end;if bC then return{"go_xflame_ch"}else return{"go_xflame_center"}end end
  if rbSkip then local pp=gPCH();if#pp>0 then return{"go_purple_rb_renew"}else local all=gCH(false,false);if#all>0 then return{"go_skip_one_ch"}end end end
  if p_=="REFRESH"then local all=gCH(false,false);if#all>0 then table.insert(ba,"go_crosshair_refresh_all")else table.insert(ba,"patrol_ring")end;return ba end
  if p_=="X10"then local tp=gTPG();if tp then table.insert(ba,"go_target_practice_purple")else local pp=gCH(true,false);if#pp>0 then table.insert(ba,"go_purple")end end end
  if p_=="НАБОР"then
    local tpBuild=gTPG_build();if tpBuild then return{"go_build_precision"}end
    local pp=gCH(true,false,true);if#pp>0 then table.insert(ba,"go_crosshair")end
    if#fP>0 then table.insert(ba,"go_petal")end
    local ha=false;for _ in pairs(aT)do ha=true;break end;if ha then table.insert(ba,"go_token_near");table.insert(ba,"go_token_best")end
    local dt=gDTP();if dt then table.insert(ba,"go_dup_tp")end
    table.insert(ba,"patrol_ring");table.insert(ba,"patrol_random");return ba
  end
  if p_=="X10"then if#fP>0 then table.insert(ba,"go_petal")end;local all=gCH(false,false);if#all>0 then table.insert(ba,"go_crosshair")end;local ha=false;for _ in pairs(aT)do ha=true;break end;if ha then table.insert(ba,"go_token_near");table.insert(ba,"go_token_best")end;local dt=gDTP();if dt then table.insert(ba,"go_dup_tp")end;table.insert(ba,"patrol_ring");return ba end
  return{"patrol_ring"}
end
local function cAB(s) local v=gAWB();if#v==0 then return"patrol_ring"end;if math.random()<EP then return v[math.random(1,#v)]end;local bA,bQ=v[1],gQ(s,v[1])*getPatternBias(v[1])
  for i=2,#v do local q=gQ(s,v[i])*getPatternBias(v[i]);if q>bQ then bA=v[i];bQ=q end end;return bA end
local function dUQ(s,a,rw,ns) local rr=h();local tR=rw+gPB(a,rr and rr.Position or Vector3.zero);local v=gAWB();local mN=0;for _,a_ in ipairs(v)do local q=gQ(ns,a_);if q>mN then mN=q end end;local nw=gQ(s,a)+AL*(tR+GA*mN-gQ(s,a));sQ(s,a,nw);st.tR=st.tR+tR;st.dc=st.dc+1;EP=math.max(0.02,EP*ED)end

-- === ВИЗУАЛИЗАЦИЯ ===
local function uXC() if xfE then local cc=gFC();if cc==Vector3.zero then local r=h();if r then cc=r.Position end end;if not xfC then xfC=Instance.new("Part");xfC.Name="XFlameCircle";xfC.Shape=Enum.PartType.Cylinder;xfC.Anchored=true;xfC.CanCollide=false;xfC.Transparency=0.6;pcall(function()xfC.BrickColor=BrickColor.new("Really red")end);xfC.Size=Vector3.new(XCR*2,0.2,XCR*2);xfC.Parent=Workspace end;xfC.Position=Vector3.new(cc.X,cc.Y+0.2,cc.Z)else if xfC then xfC:Destroy();xfC=nil end end end
local function gEP(tP) if not aR or not aR.Parent then return tP end;local dir=(tP-aR.Position).Unit;return cP(Vector3.new(aR.Position.X+dir.X*aRR,0,aR.Position.Z+dir.Z*aRR))end
local CHC=Color3.fromRGB(17,134,19)
local function iCH(p) if not p or p.Name~="Crosshair"then return false end;local ok,c=pcall(function()return p.Color end);if not ok then return false end;return math.abs(c.R-CHC.R)<0.05 and math.abs(c.G-CHC.G)<0.05 and math.abs(c.B-CHC.B)<0.05 end

-- === ИСПОЛНЕНИЕ ===
local function eA(action)
  local r=h();if not r then return-1 end
  recordScorchAction(action)
  if action=="go_build_precision"then local tp=gTPG_build();if not tp then return-1 end;local g=tp[1];local rw=0;INT=false
    if g.pr.part.Parent and not g.pr.col then tL="🟣 BUILD TP";local ok=goTo(g.pr.part.Position,4,5);if ok and g.pr.part.Parent then g.pr.col=true;lP=g.pr.part;st.pr=st.pr+1;rw=rw+30;task.wait(0.1)end end
    if g.r1.part.Parent and not g.r1.col then tL="🎯 BUILD r1";local ok=goTo(g.r1.part.Position,4,4);if ok and g.r1.part.Parent then g.r1.col=true;st.ch=st.ch+1;rw=rw+10;task.wait(0.05)end end
    if g.r2.part.Parent and not g.r2.col then tL="🎯 BUILD r2";local ok=goTo(g.r2.part.Position,4,4);if ok and g.r2.part.Parent then g.r2.col=true;st.ch=st.ch+1;rw=rw+10 end end
    if rw>0 and aB.PoM.a and aB.PoM.pos then goTo(aB.PoM.pos,6,3)end;return rw>0 and rw or-2 end
  if action=="go_focus_renew"then local all=gCH(false,false);if#all==0 then return-1 end;local t=all[1];tL="🎯 Focus renew";INT=false;local ok=goTo(t.part.Position,4,4);if ok and t.part.Parent then t.col=true;if t.isP then st.pr=st.pr+1 else st.ch=st.ch+1 end;return 15 end;return-2 end
  if action=="go_purple_rb_renew"then local pp=gPCH();if#pp==0 then return-1 end;local t=pp[1];tL="🟣 RB renew";INT=false;local ok=goTo(t.part.Position,4,4);if ok and t.part.Parent then t.col=true;st.pr=st.pr+1;return 20 end;return-2 end
  if action=="go_skip_one_ch"then local all=gCH(false,false);if#all<=1 then return-1 end;tL="⏭️ Skip CH (RB)";INT=false;return 5 end
  if action=="go_multi_purple"then local pp=gPCH();if#pp<2 then return-1 end;local rw=0;INT=false
    local p1=pp[1];tL="🟣×2 #1";if p1.part.Parent and not p1.col then local ok=goTo(p1.part.Position,4,3);if ok and p1.part.Parent then p1.col=true;st.pr=st.pr+1;rw=rw+20 end end
    local p2=pp[2];if p2.part.Parent and not p2.col then tL="🟣×2 #2";local dist12=d3(p1.part.Position,p2.part.Position)
      if dist12>30 then local ok=goTo(p2.part.Position,4,5);if ok and p2.part.Parent then p2.col=true;st.pr=st.pr+1;local wt=tick();while tick()-wt<1 do task.wait(0.05)end;rw=rw+25 end
      else local ok=goTo(p2.part.Position,4,3);if ok and p2.part.Parent then p2.col=true;st.pr=st.pr+1;rw=rw+20 end end
    end;return rw>0 and rw or-2 end
  if action=="go_crosshair_all"then local all=gCH(false,false);if#all==0 then return-1 end;table.sort(all,function(a,b)return a.sT<b.sT end);local rw=0;INT=false
    for _,ch in ipairs(all)do if ch.part.Parent and not ch.col then if ch.isP then tL="🟣 Scorch";local ok=goTo(ch.part.Position,4,3);if ok and ch.part.Parent then ch.col=true;st.pr=st.pr+1;rw=rw+20 end
    else tL="🎯 Scorch";local ok=goTo(ch.part.Position,4,3);if ok and ch.part.Parent then ch.col=true;st.ch=st.ch+1;rw=rw+10 end end end;return rw>0 and rw or-2 end
  if action=="go_crosshair_refresh_all"then local all=gCH(false,false);if#all==0 then return-1 end;local col=0;INT=false
    for _,ch in ipairs(all)do if ch.part.Parent and not ch.col then if col>=3 then break end;tL="🔄 RFSH "..(col+1);local ok=goTo(ch.part.Position,4,4,true);if ok and ch.part.Parent then ch.col=true;rCC=rCC+1;if ch.isP then st.pr=st.pr+1;lP=ch.part else st.ch=st.ch+1 end;col=col+1;task.wait(0.1)end end end
    if aR and aR.Parent then goTo(aR.Position,6,4)else goTo(cP(r.Position),5,2)end
    if rCC>=3 then prec.nR=false;cyc.chC=0;st.rf=st.rf+1;rCC=0;return 40 end;return col>0 and(col*12)or-2 end
  if action=="go_target_practice_purple"then local tp=gTPG();if not tp then return-1 end;local rw=0;INT=false
    for _,g in ipairs(tp)do if g.pr.part.Parent and not g.pr.col then tL="🎯 TP";local ok=goTo(g.pr.part.Position,4,5);if ok and g.pr.part.Parent then g.pr.col=true;g.r1.col=true;g.r2.col=true;lP=g.pr.part;st.pr=st.pr+1;local t0=tick();while tick()-t0<PST do task.wait(0.05);if smT or prec.nR or not ENABLED then break end end;rw=rw+40 end end end;return rw>0 and rw or-2 end
  if action=="go_smile_area"then local t=gSDA();if not t then return-1 end;local td=aT[t];if not td or td.col or td.id~=SMI then return-1 end;tL="😊 Smile(R)";INT=false;local edge=gEP(t.Position);local ok=goTo(edge,4,4);if ok and t.Parent then local st_=tick();while tick()-st_<TSD do task.wait(0.1);if not t.Parent or INT then break end;local hp=h();if hp then hp.CFrame=CFrame.new(t.Position.X,hp.Position.Y,t.Position.Z)end end;td.col=true;st.sm=st.sm+1;return 45 end;return-10 end
  if action=="go_dup_area"then local t=gSDA();if not t then return-1 end;local td=aT[t];if not td or td.col or td.id~=TPI or not td.dp then return-1 end;tL="🎯 Dup(R)";INT=false;local edge=gEP(t.Position);local ok=goTo(edge,4,4);if ok and t.Parent then local st_=tick();while tick()-st_<TSD do task.wait(0.1);if not t.Parent or INT then break end;local hp=h();if hp then hp.CFrame=CFrame.new(t.Position.X,hp.Position.Y,t.Position.Z)end end;td.col=true;st.tk=st.tk+1;return 15 end;return-2 end
  if action=="go_smile"then local t=smT;if not t or not t.Parent then smT=nil;return-1 end;local td=aT[t];if not td or td.col then smT=nil;return-1 end;isCS=true;tL="😊 Smile";INT=false;local ok=goTo(t.Position,4,math.min(2.5,smTR-0.2));if ok and t.Parent then local st_=tick();while tick()-st_<TSD do task.wait(0.1);if not t.Parent or INT then break end;local hp=h();if hp then hp.CFrame=CFrame.new(t.Position.X,hp.Position.Y,t.Position.Z)end end;td.col=true;smT=nil;st.sm=st.sm+1;isCS=false;return 45 end;isCS=false;smT=nil;return-10 end
  if action=="go_urgent_token"then local n=tick();local be,bl=nil,0.3;for p,t in pairs(aT)do if not t.col and p.Parent then local rem=t.l-(n-t.s);if rem<bl and rem>0 then bl=rem;be=p end end end;if be then tL="⚡Urgent";INT=false;local ok=goTo(be.Position,4,2);if ok and be.Parent then aT[be].col=true;st.tk=st.tk+1;return 25 end;return-2 end;return-1 end
  if action=="go_purple"then local pp=gCH(true,false);if#pp==0 then return-1 end;local rw=0;INT=false;for _,ch in ipairs(pp)do if ch.part.Parent and not ch.col and not smT and not prec.nR then local ok=goTo(ch.part.Position,4,5);if ok and ch.part.Parent then ch.col=true;lP=ch.part;st.pr=st.pr+1;local t0=tick();while tick()-t0<PST do task.wait(0.05);if smT or prec.nR or not ENABLED then break end end;rw=rw+30 end end end;return rw>0 and rw or-2 end
  if action=="go_tokenlink"then for p,t in pairs(aT)do if not t.col and p.Parent and t.p>=90 then tL="💎Link";INT=false;local ok=goTo(p.Position,5,5);if ok and p.Parent then t.col=true;igT=tick()+TLC;return 50 end;return-5 end end;return-2 end
  if action=="go_crosshair"then local all=gCH(false,false,ph()=="НАБОР");if#all==0 then return-1 end;local t=all[1];local rw=0;INT=false;if t.part.Parent and not t.col and not smT and not prec.nR then local sk=false;local r2=h();if r2 then for p2,t2 in pairs(aT)do if not t2.col and p2.Parent and t2.p>=90 then if d3(r2.Position,p2.Position)<TLID and d3(r2.Position,t.part.Position)>30 then sk=true;break end end end end;if not sk then local ok=goTo(t.part.Position,4,5);if ok and t.part.Parent then t.col=true;if t.isP then st.pr=st.pr+1;lP=t.part;rw=rw+10 else st.ch=st.ch+1;cyc.chC=cyc.chC+1;if cyc.chC>=3 then cyc.chC=0 end;rw=rw+8 end end end end
    if rw>0 and aB.PoM.a and aB.PoM.pos then goTo(aB.PoM.pos,6,4)end;return rw>0 and rw or-2 end
  if action=="go_dup_tp"then local p,t=gDTP();if not p then return-1 end;tL="🎯 Dup";INT=false;local ok=goTo(p.Position,5,5);if ok and p.Parent then local st_=tick();while tick()-st_<TSD do task.wait(0.1);if not p.Parent or INT then break end;local hp=h();if hp then hp.CFrame=CFrame.new(p.Position.X,hp.Position.Y,p.Position.Z)end end;t.col=true;return 15 end;return-2 end
  if action=="go_petal"then if#fP==0 then return-1 end;local ca,tr=false,0;local i=1;while i<=#fP do local pt=fP[i];if not pt.part.Parent then table.remove(fP,i)elseif stP[pt.part]and tick()<stP[pt.part]then table.remove(fP,i)else tL="🌸 "..pt.cn;INT=false;local ok=goTo(Vector3.new(pt.part.Position.X,0,pt.part.Position.Z),PCD,2.5);if ok then st.pt=st.pt+1;tr=tr+8+(14-pt.pr);ca=true;task.wait(0.05);i=i+1 else stP[pt.part]=tick()+5;table.remove(fP,i)end end end;return ca and tr or-1 end
  if action=="go_token_near"then local be,bD=nil,math.huge;for p,t in pairs(aT)do if not t.col and p.Parent then local d=d3(r.Position,p.Position);if d<bD then be=p;bD=d end end end;if be then local t=aT[be];tL="💎 "..t.n;INT=false;local ok=goTo(be.Position,5,5);if ok and be.Parent then t.col=true;return 3+t.p*0.2 end;return-2 end;return-1 end
  if action=="go_token_best"then local be,bP=nil,-1;local n=tick();for p,t in pairs(aT)do if not t.col and p.Parent and(t.l-(n-t.s))>0.5 and t.p>bP then be=p;bP=t.p end end;if be then local t=aT[be];tL="💎⭐ "..t.n;INT=false;local ok=goTo(be.Position,5,5);if ok and be.Parent then t.col=true;return 5+t.p*0.3 end;return-3 end;return-1 end
  if action=="patrol_ring"then local function rR() if aR and aR.Parent and curF then local a_=math.random()*2*math.pi;local rr_=aRR*(0.5+math.random()*0.8);return cP(Vector3.new(aR.Position.X+math.cos(a_)*rr_,0,aR.Position.Z+math.sin(a_)*rr_))elseif curF then local c=curF.part.Position;local s=curF.part.Size;return cP(Vector3.new(c.X+(math.random()*2-1)*math.max(s.X/2*0.3,5),0,c.Z+(math.random()*2-1)*math.max(s.Z/2*0.3,5)))else local rp=h();if rp then return cP(rp.Position+Vector3.new((math.random()*2-1)*30,0,(math.random()*2-1)*30))else return cP(Vector3.zero)end end end;tL="🚶 Ring";INT=false;local t=rR();if t==Vector3.zero or not iF(t)then t=gFC()end;if t==Vector3.zero then return 0 end;goTo(t,6,PT);task.wait(0.1+math.random()*0.3);return 0 end
  if action=="patrol_random"then local function rF() if curF then local c=curF.part.Position;local s=curF.part.Size;return cP(Vector3.new(c.X+(math.random()*2-1)*math.max(s.X/2-3,1),0,c.Z+(math.random()*2-1)*math.max(s.Z/2-3,1)))else local rp=h();if rp then return cP(rp.Position+Vector3.new((math.random()*2-1)*30,0,(math.random()*2-1)*30))else return cP(Vector3.zero)end end end;tL="🚶 Rand";INT=false;local t=rF();if t==Vector3.zero or not iF(t)then t=gFC()end;if t==Vector3.zero then return 0 end;goTo(t,4,PT);task.wait(0.2+math.random()*0.4);return 0 end
  if action=="go_xflame_center"then local c=gFC();if c==Vector3.zero then return-1 end;tL="🔥 XF центр";INT=false;goTo(c,3,3);return 0 end
  if action=="go_xflame_ch"then local c=gFC();if c==Vector3.zero then return-1 end;local bC,bD=nil,XCR+1;for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent then local d=d3(ch.part.Position,c);if d<=XCR and d<bD then bD=d;bC=ch end end end;if bC then tL="🔥 XF CH";INT=false;goTo(bC.part.Position,2,3);task.wait(1);return 5 end;return-1 end
  return 0
end

-- === HEARTBEAT ===
local mLS=false
local function sML() if mLS then return end;mLS=true;task.wait(2)
  scriptStartHoney=getCoreHoney();scriptStartTime=tick()
  lQ();fAR();fF();logOk("BSS AI v15.2 ready! Honey: "..fmtHoney(scriptStartHoney));print("✅ v15.2");tL="иниц";lMT=tick()end
task.spawn(function()pcall(function()if not readfile then return end;local ok,raw=pcall(readfile,pF);if ok and raw then local ok2,data=pcall(Http.JSONDecode,Http,raw);if ok2 and type(data)=="table"then if data.scorchSessions then scorchSessions=data.scorchSessions else pH=data end;if data.bestScorch then bestScorchHoney=data.bestScorch end;for _,p in ipairs(data.actions or data)do if(p.hps or 0)>bAH then bAH=(p.hps or 0)end end end end end);logOk("Загр: "..#scorchSessions.." скорчей")end)

-- АНТИ-ЛАГ
task.spawn(function()while true do task.wait(30)
  pcall(function()
    local t=cfc(Workspace,"Terrain")
    if t then for _,d in ipairs(t:GetDescendants())do if(d:IsA("Decal")or d:IsA("Texture"))and not(d.Name and d.Name:find("Crosshair"))then d:Destroy()end end end
    local lt=cfc(Workspace,"Lighting");if lt then lt.GlobalShadows=false;lt.Brightness=2 end
  end)
end end)

if _G._BSSAI_HB then pcall(function()_G._BSSAI_HB:Disconnect()end)end
_G._BSSAI_HB=RunService.Heartbeat:Connect(function()
  hbF=hbF+1;if not ENABLED then return end
  if not mLS then sML();return end
  local n=tick()
  fAR()
  if hbF%18==0 then sBf();sPr()end
  if hbF%9==0 then sPt();local h_=hm();if h_ then local ts=gAS();if math.abs(h_.WalkSpeed-ts)>0.5 then h_.WalkSpeed=ts end end end
  if hbF%6==0 then pcall(uHB)end
  if hbF%3==0 then sSm()end
  if hbF%180==0 then fF()end
  if hbF%60==0 then clnCH()end
  if hbF%30==0 then saveScorchSessions()end
  if hbF%18000==0 then task.spawn(function()local qc=0;for _ in pairs(QT)do qc=qc+1 end;if writefile then pcall(function()writefile("bss_ai_q_v15.json",Http:JSONEncode({version=Q_VERSION,qtable=QT,scorchSessions=scorchSessions,bestScorch=bestScorchHoney,top10=top10patterns,meta={sc=qc,sa=os.time()}}))end)end end)end
  xfE=(aB.XF.st>=20);if xfE then INT=true end;uXC()
  local r=h()
  if r then local vel=r.AssemblyLinearVelocity;local hS=(Vector3.new(vel.X,0,vel.Z)).Magnitude;if hS>0.2 then lMT=n;stW=false elseif n-lMT>5 and not stW then stW=true;INT=true;tL="⏳ сброс";if lP and not lP.Parent then lP=nil end;if smT and not smT.Parent then smT=nil;isCS=false end;INT=false;lMT=n end end
  if INT and not smT and not prec.nR and not xfE then INT=false end
  if prec.isX and not prec.nR and r then for _,ch in ipairs(cQ)do if ch.part and ch.part.Parent and not ch.col and not ch.isP then if iCH(ch.part)and n-lPT>1.5 then lPT=n;local s_=eS();if s_ and s_~="dead"then pcall(dUQ,s_,"patrol_ring",-20,s_)end;st.chA=st.chA+1;break end end end end
  if isA then return end
  if hbF%2==0 then isA=true;local s_=eS();local a_=cAB(s_);local ok,rw=pcall(eA,a_);if not ok then rw=-1;logErr("Action "..a_.." failed: "..tostring(rw))end;local ns=eS();pcall(dUQ,s_,a_,rw,ns);isA=false end
end)

-- === Q-ТАБЛИЦА ===
function lQ() local ok,raw=pcall(readfile,"bss_ai_q_v15.json");if ok and raw then local ok2,d=pcall(Http.JSONDecode,Http,raw);if ok2 and type(d)=="table"and d.version==Q_VERSION and type(d.qtable)=="table"then QT=d.qtable;if d.scorchSessions then scorchSessions=d.scorchSessions end;if d.bestScorch then bestScorchHoney=d.bestScorch end;if d.top10 then top10patterns=d.top10 end end end end
local function rQ() QT={};EP=0.1;st.tR=0;st.dc=0;scorchSessions={};bestScorchHoney=0;top10patterns={};if writefile then pcall(function()writefile("bss_ai_q_v15.json",Http:JSONEncode({version=Q_VERSION,qtable={},scorchSessions={},bestScorch=0,top10={},meta={ra=os.time()}}))end)end end

-- === GUI ===
local sg=Instance.new("ScreenGui",PGui)sg.Name="BSSAI_GUI"
local fr=Instance.new("Frame",sg)fr.Size=UDim2.new(0,270,0,148)fr.Position=UDim2.new(0,10,0,10)
fr.BackgroundColor3=Color3.fromRGB(20,20,30)fr.BackgroundTransparency=0.15 fr.BorderSizePixel=0 fr.Active=true fr.Draggable=true
Instance.new("UICorner",fr).CornerRadius=UDim.new(0,6)
local ti_=Instance.new("TextLabel",fr)ti_.Size=UDim2.new(1,0,0,20)ti_.Position=UDim2.new(0,0,0,2)ti_.BackgroundTransparency=1 ti_.Text="🧠 BSS AI v15.2"ti_.TextColor3=Color3.fromRGB(100,200,255)ti_.Font=Enum.Font.GothamBold ti_.TextSize=12 ti_.TextXAlignment=Enum.TextXAlignment.Center
local lb=Instance.new("TextLabel",fr)lb.Size=UDim2.new(1,0,0,16)lb.Position=UDim2.new(0,0,0,22)lb.BackgroundTransparency=1 lb.Text="Действие: старт"lb.TextColor3=Color3.fromRGB(255,255,255)lb.Font=Enum.Font.Gotham lb.TextSize=11 lb.TextXAlignment=Enum.TextXAlignment.Center
local hl=Instance.new("TextLabel",fr)hl.Size=UDim2.new(1,0,0,16)hl.Position=UDim2.new(0,0,0,38)hl.BackgroundTransparency=1 hl.Text="HPH: --/час"hl.TextColor3=Color3.fromRGB(150,255,150)hl.Font=Enum.Font.Gotham hl.TextSize=11 hl.TextXAlignment=Enum.TextXAlignment.Center
local sl_=Instance.new("TextLabel",fr)sl_.Size=UDim2.new(1,0,0,16)sl_.Position=UDim2.new(0,0,0,54)sl_.BackgroundTransparency=1 sl_.Text="⚡ --"sl_.TextColor3=Color3.fromRGB(255,200,100)sl_.Font=Enum.Font.Gotham sl_.TextSize=11 sl_.TextXAlignment=Enum.TextXAlignment.Center
local pl_=Instance.new("TextLabel",fr)pl_.Size=UDim2.new(1,0,0,16)pl_.Position=UDim2.new(0,0,0,70)pl_.BackgroundTransparency=1 pl_.Text="Φ: --"pl_.TextColor3=Color3.fromRGB(180,180,255)pl_.Font=Enum.Font.Gotham pl_.TextSize=11 pl_.TextXAlignment=Enum.TextXAlignment.Center
local bf_=Instance.new("TextLabel",fr)bf_.Size=UDim2.new(1,0,0,16)bf_.Position=UDim2.new(0,0,0,86)bf_.BackgroundTransparency=1 bf_.Text="FC:-- RB:-- PM:--"bf_.TextColor3=Color3.fromRGB(255,180,100)bf_.Font=Enum.Font.Gotham bf_.TextSize=10 bf_.TextXAlignment=Enum.TextXAlignment.Center
local sh_=Instance.new("TextLabel",fr)sh_.Size=UDim2.new(1,0,0,16)sh_.Position=UDim2.new(0,0,0,102)sh_.BackgroundTransparency=1 sh_.Text="🔥 Скорч: --"sh_.TextColor3=Color3.fromRGB(255,140,80)sh_.Font=Enum.Font.Gotham sh_.TextSize=10 sh_.TextXAlignment=Enum.TextXAlignment.Center
local tip_=Instance.new("TextLabel",fr)tip_.Size=UDim2.new(1,0,0,18)tip_.Position=UDim2.new(0,0,0,120)tip_.BackgroundTransparency=1 tip_.Text=SCO_TIPS[1]tip_.TextColor3=Color3.fromRGB(200,200,150)tip_.Font=Enum.Font.Gotham tip_.TextSize=9 tip_.TextXAlignment=Enum.TextXAlignment.Center tip_.TextWrapped=true
task.spawn(function()while true do task.wait(0.3)
  lb.Text="🎯 "..tL
  local curH=getCoreHoney();local elapsedH=(tick()-scriptStartTime)/3600
  local hph=elapsedH>0 and(curH-scriptStartHoney)/elapsedH or 0
  hl.Text="HPH: "..fmtHoney(hph).."/час | "..fmtHoney(curH)
  sl_.Text="⚡ "..string.format("%.0f",cS)
  pl_.Text=(isSuperScorch and"🔥 "or"")..ph().." CH:"..#cQ.." Tk:"..st.tk.." Pr:"..st.pr
  bf_.Text="FC:"..(aB.FC.combo>=10 and"x10"or"x"..aB.FC.combo).." "..string.format("%.0f",aB.FC.tL).."с RB:"..(aB.RB.combo>=10 and"x10"or"x"..aB.RB.combo).." "..string.format("%.0f",aB.RB.tL).."с PM:"..aB.PoM.m
  if scorchActive and scorchStartTime>0 then local se=(tick()-scorchStartTime)/60;sh_.Text="🔥 "..fmtHoney(curH-scorchStartHoney).." "..string.format("%.1f",se).."мин | "..fmtHoney(bestScorchHoney)
  else sh_.Text="🔥 "..#scorchSessions.." скорчей | Top10:"..#top10patterns.." | "..fmtHoney(bestScorchHoney) end
  if hbF%180==0 then scoIdx=(scoIdx%#SCO_TIPS)+1;tip_.Text=SCO_TIPS[scoIdx]end
end end)

UIS.InputBegan:Connect(function(i,gp)if gp then return end
  if i.KeyCode==Enum.KeyCode.T then ENABLED=not ENABLED;sg.Enabled=ENABLED
  elseif i.KeyCode==Enum.KeyCode.G then rQ()
  elseif i.KeyCode==Enum.KeyCode.P then local c=0;for _ in pairs(QT)do c=c+1 end;print("v15.2 Φ:"..ph().." ε:"..string.format("%.3f",EP).." R:"..st.tR.." S:"..c.." FC:"..aB.FC.combo.." RB:"..aB.RB.combo.." PM:"..aB.PoM.m.." Honey:"..fmtHoney(getCoreHoney()).." Sc:"..#scorchSessions)end
end)

LP.CharacterAdded:Connect(function()task.wait(2)aT={};cQ={};lP=nil;curF=nil;tL="старт";smT=nil;isCS=false;INT=false;cyc={chC=0};fP={};igT=0;rCC=0;dupCnt=0;focusRenew=false;rbSkip=false;isSuperScorch=false;scorchActive=false;scorchRecording=false;scorchActions={};scorchStartHoney=0;scorchStartTime=0;if xfC then xfC:Destroy();xfC=nil end
  task.spawn(function()if writefile then local qc=0;for _ in pairs(QT)do qc=qc+1 end;pcall(writefile,"bss_ai_q_v15.json",Http:JSONEncode({version=Q_VERSION,qtable=QT,scorchSessions=scorchSessions,bestScorch=bestScorchHoney,top10=top10patterns,meta={sc=qc,sa=os.time()}}))end end)end)

print("✅ v15.2 ready")
