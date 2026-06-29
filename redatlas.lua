-- BSS AI v13.0: самообучающийся ИИ (microHPS %-based + patternGenerator + balanced rewards)
local P=game:GetService("Players")
local W=game:GetService("Workspace")
local R=game:GetService("RunService")
local U=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage")
local H=game:GetService("HttpService")
local V=game:GetService("VirtualInputManager")
local L=P.LocalPlayer
local G=L:WaitForChild("PlayerGui")
local VQ,EN="13.0",true

-- === GUI ОШИБОК ===
local eL,eg,el,eb,ec={},nil,nil,nil,0
local function mE()pcall(function()if eg then return end
eg=Instance.new("ScreenGui",G);eg.Name="BSSAI_Err";eg.ResetOnSpawn=false
local b=Instance.new("Frame",eg);b.Size=UDim2.new(0,380,0,200);b.Position=UDim2.new(.5,-190,.5,-100)
b.BackgroundColor3=Color3.fromRGB(15,15,25);b.BackgroundTransparency=.08;b.BorderSizePixel=0;b.Active=true;b.Draggable=true
Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
local t=Instance.new("TextLabel",b);t.Size=UDim2.new(1,-16,0,20);t.Position=UDim2.new(0,8,0,6);t.BackgroundTransparency=1
t.Text="⚠ BSS AI v13.0";t.TextColor3=Color3.fromRGB(255,180,60);t.Font=Enum.Font.GothamBold;t.TextSize=13;t.TextXAlignment=Enum.TextXAlignment.Left
el=Instance.new("TextLabel",b);el.Size=UDim2.new(1,-16,0,110);el.Position=UDim2.new(0,8,0,28);el.BackgroundTransparency=1
el.Text="⏳ Иниц...";el.TextColor3=Color3.fromRGB(200,200,200);el.Font=Enum.Font.Code;el.TextSize=11
el.TextXAlignment=Enum.TextXAlignment.Left;el.TextYAlignment=Enum.TextYAlignment.Top;el.TextWrapped=true
eb=Instance.new("TextButton",b);eb.Size=UDim2.new(0,100,0,26);eb.Position=UDim2.new(0,8,0,155)
eb.BackgroundColor3=Color3.fromRGB(60,60,80);eb.Text="📋 Копировать";eb.TextColor3=Color3.fromRGB(220,220,220);eb.Font=Enum.Font.Gotham;eb.TextSize=11
Instance.new("UICorner",eb).CornerRadius=UDim.new(0,4)
local cb=Instance.new("TextButton",b);cb.Size=UDim2.new(0,80,0,26);cb.Position=UDim2.new(0,116,0,155)
cb.BackgroundColor3=Color3.fromRGB(60,60,80);cb.Text="✕";cb.TextColor3=Color3.fromRGB(220,220,220);cb.Font=Enum.Font.Gotham;cb.TextSize=11
Instance.new("UICorner",cb).CornerRadius=UDim.new(0,4)
cb.MouseButton1Click:Connect(function()eg.Enabled=false;eg:Destroy();eg=nil end)
eb.MouseButton1Click:Connect(function()local tx=table.concat(eL,"\n");if#tx==0 then tx="OK"end;pcall(setclipboard,tx);eb.Text="✅";task.wait(1.5);eb.Text="📋"end)
task.spawn(function()task.wait(4);if eg and ec==0 then eg:Destroy();eg=nil end end)end)end
local function lE(m)ec=ec+1;table.insert(eL,string.format("[%02d]%s",ec,m));while#eL>20 do table.remove(eL,1)end;if el then local L_={};for i=math.max(1,#eL-12),#eL do table.insert(L_,eL[i])end;el.Text=table.concat(L_,"\n");if ec==1 then el.TextColor3=Color3.fromRGB(255,140,100)end end;warn("BSSAI:",m)end
local function lI(m)if el then el.Text="✅ "..m;el.TextColor3=Color3.fromRGB(140,255,160)end end
mE();lI("GUI OK")

-- === АНТИ-ЛАГ ===
task.spawn(function()while true do task.wait(30)pcall(function()
    local t=W:FindFirstChild("Terrain");if t then for _,d in ipairs(t:GetDescendants())do if(d:IsA("Decal")or d:IsA("Texture"))and not d.Name:find("Crosshair")then d:Destroy()end end end
    local lt=W:FindFirstChild("Lighting");if lt then lt.GlobalShadows=false;lt.Brightness=2 end
end)end end)

-- === АДАПТИВНЫЕ ПАРАМЕТРЫ ===
local aP={scrD=4,pst=1,tsd=1.1,mcd=10,pt=8,arr=5,mt=6}
local aPH={}
local function getAP(n,d)return aP[n]or d end
local function setAP(n,v)aP[n]=math.max(0.2,math.min(50,v))end
local function tryMutateParams()
    if st.dc%30~=0 or st.dc==0 then return end
    local keys={"scrD","pst","tsd","mcd","pt","arr","mt"}
    local k=keys[math.random(1,#keys)]
    local old=aP[k];local delta=(math.random()*2-1)*(old*0.3)
    setAP(k,old+delta);aP._trial={key=k,old=old,new=aP[k],at=tick()}
end
local function checkMutation()
    if not aP._trial then return end
    if tick()-aP._trial.at>10 then
        local cur=gHP();local rec=bAH>0 and bAH or cur
        if cur<rec*0.85 then setAP(aP._trial.key,aP._trial.old)end
        aP._trial=nil
    end
end

-- === microHPS: %-based (реалистичные масштабы HPS) ===
local lastMicroHPS=0
local function snapMicroHPS()lastMicroHPS=math.max(gHP(),1)end
local function getMicroReward()
    local cur=math.max(gHP(),1)
    local pct=(cur-lastMicroHPS)/lastMicroHPS
    lastMicroHPS=cur
    if pct>0.05 then return 8+math.floor(pct*50)
    elseif pct>0.01 then return 4+math.floor(pct*100)
    elseif pct>-0.01 then return 0
    elseif pct>-0.05 then return -(2+math.floor(-pct*50))
    else return -(6+math.floor(-pct*30))
    end
end

-- === ГЕНЕРАТОР ПАТТЕРНОВ ===
local generatedPatterns={}
local function generatePattern()
    if#pH<5 then return end
    local sorted={};for _,p in ipairs(pH)do table.insert(sorted,p)end
    table.sort(sorted,function(a,b)return a.hps>b.hps end)
    local p1=sorted[1];local p2=sorted[math.random(2,math.min(5,#sorted))]
    local newActions={}
    local half1=math.floor(#p1.actions/2)
    for i=1,half1 do table.insert(newActions,{action=p1.actions[i].action,pos=p1.actions[i].pos,phase=p1.actions[i].phase,isSc=p1.actions[i].isSc,to=0})end
    for i=half1+1,#p2.actions do table.insert(newActions,{action=p2.actions[i].action,pos=p2.actions[i].pos,phase=p2.actions[i].phase,isSc=p2.actions[i].isSc,to=0})end
    if#newActions>2 then
        local mi=math.random(1,#newActions)
        local allActions={"go_crosshair","go_purple","go_tokenlink","go_petal","go_token_near","patrol_ring","patrol_random","go_smile","go_target_practice_purple","go_scorching_spiral","go_xflame_center"}
        newActions[mi].action=allActions[math.random(1,#allActions)]
    end
    local gen={hps=0,actions=newActions,timestamp=tick(),ctx=p1.ctx or{},generated=true}
    table.insert(generatedPatterns,gen)
    while#generatedPatterns>10 do table.remove(generatedPatterns,1)end
    table.insert(pH,gen);table.sort(pH,function(a,b)return a.hps>b.hps end)
    while#pH>30 do table.remove(pH)end
end

-- === КОНФИГ ===
local SB={["НАБОР"]=70,["X10"]=90,["REFRESH"]=75};local SJ=3
local AM,DGL,FM=1.2,22,3
local PBI,PPK,PMX,PRAT=2574507284,0.02,10,15
local PURP,PTOL=Color3.fromRGB(119,85,255),12
local SMI,SMRT=5877939956,15
local CAR,CAS,CAD=28,20,0.1
local ARR,TLID=20,20;local PCD,PFM,FHA,FHD=8,20,5,14;local TPI,TLC,XCR=8173559749,2,8,12
local AL,GA,EP,ED=0.5,0.95,0.3,0.9995;local PMBI=2499540966
local CHIT_COLOR=Color3.fromRGB(17,134,19)
local DIAG_MAX_ANGLE=0.35;local DIAG_MAX_TIME=0.8

local TKS={[1629547638]={n="Token Link",b=4,p=99},[2000457501]={n="Inspire",b=8,p=25},[1472256444]={n="Baby Love",b=8,p=22},[1629649299]={n="Focus",b=4,p=15},[65867881]={n="Haste",b=4,p=15},[1442863423]={n="Blue Boost",b=4,p=12},[1442859163]={n="Red Boost",b=4,p=12},[3877732821]={n="White Boost",b=4,p=12},[1442700745]={n="Rage",b=8,p=10},[253828517]={n="Melody",b=8,p=10},[1472532912]={n="Polar Bear",b=15,p=8,mo=true},[1472491940]={n="Black Bear",b=15,p=8,mo=true},[1472425802]={n="Brown Bear",b=15,p=8,mo=true},[2032949183]={n="Mother Bear",b=15,p=8,mo=true},[1472580249]={n="Panda",b=15,p=8,mo=true},[1489734171]={n="Science Bear",b=15,p=8,mo=true},[1874564120]={n="Pulse",b=12,p=7},[2499514197]={n="Honey Mark",b=8,p=7},[2499540966]={n="Pollen Mark",b=8,p=7},[4528379338]={n="Mark Surge",b=4,p=7},[3582501342]={n="Rain Call",b=24,p=6},[3582519526]={n="Tornado",b=24,p=6},[5877998606]={n="Mind Hack",b=16,p=6},[8083943936]={n="Surprise Party",b=24,p=6},[177997841]={n="Glob",b=4,p=6},[1839454544]={n="Gummy Storm",b=4,p=6},[1442725244]={n="Bomb",b=4,p=5},[5877939956]={n="Smile",b=4,p=5},[4519549299]={n="Inferno",b=4,p=5},[4519523935]={n="Triangulate",b=4,p=5},[4528414666]={n="Summon Frog",b=8,p=5},[4528208186]={n="Flame Fuel",b=8,p=5},[1671281844]={n="Beamstorm",b=12,p=4},[1442764904]={n="Red Bomb+",b=4,p=12},[8083436978]={n="Blue Balloon",b=4,p=4},[1104415222]={n="BondToken",b=4,p=4},[2319100769]={n="Fetch",b=8,p=4},[4889322534]={n="Fuzz Bombs",b=4,p=4},[2319083910]={n="Impale",b=24,p=4},[3080529618]={n="Jelly Bean",b=4,p=4},[4889470194]={n="Pollen Haze",b=4,p=4},[8173559749]={n="Target Practice",b=8,p=3},[107187190]={n="Honey Gift",b=4,p=2},[183390139]={n="Cog",b=4,p=2}}
local AV={[1674871631]=true,[1471882621]=true,[1952740625]=true,[8055428094]=true,[2319943273]=true,[3030569073]=true,[3036899811]=true,[3080740120]=true,[3012679515]=true,[1838129169]=true,[2584584968]=true,[1471849394]=true,[1952682401]=true,[6087969886]=true,[2028574353]=true,[2028453802]=true}
local PC={["Red"]=Color3.fromRGB(249,34,34),["Pink"]=Color3.fromRGB(255,130,201),["Merigold"]=Color3.fromRGB(218,168,28),["Periwinkle"]=Color3.fromRGB(150,156,236),["Violet"]=Color3.fromRGB(94,38,177),["Scarlet"]=Color3.fromRGB(171,19,19),["Green"]=Color3.fromRGB(35,232,5),["Yellow"]=Color3.fromRGB(238,204,79),["Black"]=Color3.fromRGB(11,11,11),["Grey"]=Color3.fromRGB(127,127,127),["Blue"]=Color3.fromRGB(33,66,249),["Cyan"]=Color3.fromRGB(29,196,222),["White"]=Color3.fromRGB(249,249,249)}
local PP={Red=1,Pink=2,Merigold=3,Periwinkle=4,Violet=5,Scarlet=6,Green=7,Yellow=8,Black=9,Grey=10,Blue=11,Cyan=12,White=13}

-- === ГЛОБАЛЬНЫЕ ===
local aT,cQ,lP,curF,tL={},{},nil,nil,"старт"
local prec={st=0,val=0,isX=false,ls=0,sD=60,sS=0,tL=0,nR=false}
local cyc={chC=0};local st={tk=0,ch=0,pr=0,x10=0,rf=0,tR=0,dc=0,sm=0,chA=0,pt=0,fl=0,chG=0,diag=0}
local INT,isCS,smT,smTR,igT=false,false,nil,0,0
local tF,fP,aR,aRR={},{},nil,ARR
local aB={SS={st=0},XF={st=0},PM={a=false},PoM={a=false,pos=nil}}
local stP,rCC,rST={},0,0
local hB,aBf,pH,bAH,laT,hML,pF={},{},{},0,0,nil,"bss_ai_pat_v13.json"
local QT,lMT,stW,xfE,xfC,scC,lPT={},tick(),false,false,nil,nil,0
local lSJ,cS,lSM,hbF,isA=0,SB["НАБОР"],0,0,false
local sprA,sprR,sprC=0,0,nil
local lastGenTime=0

-- === УТИЛИТЫ ===
local function hr()local c=L.Character;if c then return c:FindFirstChild("HumanoidRootPart")end end
local function hm()local c=L.Character;if c then return c:FindFirstChildOfClass("Humanoid")end end
local function ti(t)if not t then return nil end;return tonumber(t:match("rbxassetid://(%d+)")or t:match("id=(%d+)"))end
local function d3(a,b)return(Vector3.new(a.X,0,a.Z)-Vector3.new(b.X,0,b.Z)).Magnitude end
local function d3d(a,b)return(a-b).Magnitude end
local function ph()if not prec.isX then return"НАБОР"elseif prec.nR then return"REFRESH"else return"X10"end end
local function fF()local r=hr();if not r then return curF end;local mp=r.Position;local z=W:FindFirstChild("FlowerZones");if z then local be,bd=nil,math.huge;for _,zn in ipairs(z:GetChildren())do if zn:IsA("BasePart")then local d=d3(mp,zn.Position);local s=zn.Size;if math.abs(mp.X-zn.Position.X)<=s.X/2+20 and math.abs(mp.Z-zn.Position.Z)<=s.Z/2+20 then if d<bd then bd=d;be=zn end end end end;if be then curF={part=be};return curF end end;local fl=W:FindFirstChild("Flowers");if fl then local fp={};for _,f in ipairs(fl:GetChildren())do if f:IsA("BasePart")then table.insert(fp,f.Position)end end;if#fp>0 then local mnX,mxX,mnZ,mxZ=math.huge,-math.huge,math.huge,-math.huge;for _,p in ipairs(fp)do if p.X<mnX then mnX=p.X end;if p.X>mxX then mxX=p.X end;if p.Z<mnZ then mnZ=p.Z end;if p.Z>mxZ then mxZ=p.Z end end;curF={part={Position=Vector3.new((mnX+mxX)/2,mp.Y,(mnZ+mxZ)/2),Size=Vector3.new(math.abs(mxX-mnX)+10,1,math.abs(mxZ-mnZ)+10)}};return curF end end;if aR then curF={part={Position=aR.Position,Size=Vector3.new(aRR*3,1,aRR*3)}};return curF end;return curF end
local function gAS()local p=ph();local b=SB[p]or SB["НАБОР"];if hbF%30==0 then cS=b+(math.random()*2-1)*SJ end;return cS end
local function gFC()if curF and curF.part then return curF.part.Position end;local r=hr();return r and r.Position or Vector3.zero end
local function cP(pos,sk)if sk then return pos end;if not curF then return pos end;local c=curF.part.Position;local s=curF.part.Size;local mx=math.max(s.X/2-FM,1);local mz=math.max(s.Z/2-FM,1);local cl=Vector3.new(math.clamp(pos.X,c.X-mx,c.X+mx),pos.Y,math.clamp(pos.Z,c.Z-mz,c.Z+mz));if aB.XF.st>=20 then local dx=cl.X-c.X;local dz=cl.Z-c.Z;local d=math.sqrt(dx*dx+dz*dz);if d>XCR then cl=Vector3.new(c.X+dx*(XCR/d),cl.Y,c.Z+dz*(XCR/d))end end;return cl end
local function iF(pos)if not curF then return false end;local c=curF.part.Position;local s=curF.part.Size;return math.abs(pos.X-c.X)<=s.X/2+PFM and math.abs(pos.Z-c.Z)<=s.Z/2+PFM end
local function fAR()local p=W:FindFirstChild("Particles");if p then for _,o in ipairs(p:GetChildren())do if o.Name=="AreaRing"and o:IsA("BasePart")then aR=o;aRR=(o.Size.X+o.Size.Z)/4;if aRR<5 then aRR=ARR end;return end end end;aR=W:FindFirstChild("AreaRing");if aR and aR:IsA("BasePart")then aRR=(aR.Size.X+aR.Size.Z)/4;if aRR<5 then aRR=ARR end else aR=nil;aRR=ARR end end

-- === КРОСХЕИРЫ ===
local Pt=W:FindFirstChild("Particles")or workspace:WaitForChild("Particles",10)
local function iCl(a,b,tl)tl=tl or PTOL;return math.abs(a.R*255-b.R*255)<=tl and math.abs(a.G*255-b.G*255)<=tl and math.abs(a.B*255-b.B*255)<=tl end
local function iP(p)local ok,c=pcall(function()return p.Color end);if ok and c and iCl(c,PURP)then return true end;local ok2,bc=pcall(function()return p.BrickColor.Color end);return ok2 and bc and iCl(bc,PURP)end
local function isGreen(part)if not part or part.Name~="Crosshair"then return false end;local ok,c=pcall(function()return part.Color end);if not ok then return false end;return math.abs(c.R-CHIT_COLOR.R)<0.08 and math.abs(c.G-CHIT_COLOR.G)<0.08 and math.abs(c.B-CHIT_COLOR.B)<0.08 end
local function updateGreenStatus()for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent then if isGreen(ch.part)and not ch.wasGreen then ch.wasGreen=true;ch.greenTime=tick();if not ch.isP and prec.isX and not prec.nR then st.chG=st.chG+1 end end end end end
local function aCH(o)if o.Name~="Crosshair"or not o:IsA("BasePart")then return end;for _,ch in ipairs(cQ)do if ch.part==o then return end end;if not o.Parent then return end;table.insert(cQ,{part=o,sT=tick(),col=false,isP=iP(o),wasGreen=isGreen(o)})end
if Pt then Pt.DescendantAdded:Connect(aCH);Pt.DescendantRemoving:Connect(function(o)for i=#cQ,1,-1 do if cQ[i].part==o then table.remove(cQ,i)break end end;if lP==o then lP=nil end end);for _,o in ipairs(Pt:GetDescendants())do aCH(o)end end
local function gCH(op,oR,noGreen)local L_={};for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent then if not(noGreen and ch.wasGreen)then if(op and ch.isP)or(oR and not ch.isP)or(not op and not oR)then table.insert(L_,ch)end end end end;table.sort(L_,function(a,b)return a.sT<b.sT end);return L_ end
local function gCHall(op,oR)local L_={};for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent then if(op and ch.isP)or(oR and not ch.isP)or(not op and not oR)then table.insert(L_,ch)end end end;table.sort(L_,function(a,b)return a.sT<b.sT end);return L_ end
local function gUNT(op,oR)return gCH(op,oR,true)end

-- === ДЕТЕКТ ДИАГОНАЛЕЙ ===
local function getDiagonalGroups()local all=gCHall(false,false);if#all<3 then return nil end;local groups={};local used={}
    for i=1,#all-2 do if not used[i]then for j=i+1,#all-1 do if not used[j]then if all[j].sT-all[i].sT<=DIAG_MAX_TIME then
        for k=j+1,#all do if not used[k]then if all[k].sT-all[i].sT<=DIAG_MAX_TIME then
            local p1=all[i].part.Position;local p2=all[j].part.Position;local p3=all[k].part.Position
            if math.abs(math.abs((p2-p1).Unit:Dot((p3-p1).Unit))-1)<DIAG_MAX_ANGLE then
                used[i]=true;used[j]=true;used[k]=true;local c=(p1+p2+p3)/3
                local d1=(p1-c).Magnitude;local d2=(p2-c).Magnitude;local d3_=(p3-c).Magnitude
                local a,b,cc=all[i],all[j],all[k]
                if d1>=d2 and d1>=d3_ then cc,a,b=all[i],all[j],all[k]elseif d2>=d1 and d2>=d3_ then a,cc,b=all[i],all[j],all[k]end
                table.insert(groups,{r1=a,r2=b,pr=cc,center=c})
end end end end end end end end
    return#groups>0 and groups or nil end
local function getDiagonalForRefresh()local all=gCHall(false,false);if#all<3 then return nil end;local groups={};local used={}
    for i=1,#all-2 do if not used[i]then for j=i+1,#all-1 do if not used[j]then if all[j].sT-all[i].sT<=1.5 then
        for k=j+1,#all do if not used[k]then if all[k].sT-all[i].sT<=1.5 then
            local p1,p2,p3=all[i].part.Position,all[j].part.Position,all[k].part.Position
            if math.abs(math.abs((p2-p1).Unit:Dot((p3-p1).Unit))-1)<0.5 then
                used[i]=true;used[j]=true;used[k]=true;local c=(p1+p2+p3)/3
                local d1,d2,d3_=(p1-c).Magnitude,(p2-c).Magnitude,(p3-c).Magnitude
                local a,b,cc=all[i],all[j],all[k]
                if d1>=d2 and d1>=d3_ then cc,a,b=all[i],all[j],all[k]elseif d2>=d1 and d2>=d3_ then a,cc,b=all[i],all[j],all[k]end
                table.insert(groups,{r1=a,r2=b,pr=cc})
end end end end end end end end
    return#groups>0 and groups or nil end

-- === TP ГРУППЫ ===
local function gTPG()if not prec.isX or prec.nR then return nil end;local all=gCH(false,false,true);if#all<3 then return nil end;local G={};local i=1;while i<=#all-2 do local a,b,c=all[i],all[i+1],all[i+2];if not a.isP and not b.isP and c.isP then if c.sT-a.sT<=2 then table.insert(G,{r1=a,r2=b,pr=c});i=i+3 else i=i+1 end else i=i+1 end end;return#G>0 and G or nil end

-- === ИЗБЕГАНИЕ CH ===
local function gRCT(mP,dP)if not prec.isX or prec.nR then return{}end;local mf=Vector3.new(mP.X,0,mP.Z);local df=Vector3.new(dP.X,0,dP.Z);local tt=df-mf;if tt.Magnitude<1 then return{}end;local tD=tt.Unit;local th={};for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent and not ch.isP and not ch.wasGreen then local cf=Vector3.new(ch.part.Position.X,0,ch.part.Position.Z);local toCh=cf-mf;local d=toCh.Magnitude;if d<CAR and d>1 then local dot=toCh.Unit:Dot(tD);if dot>CAD then local cross=math.abs(toCh.X*tD.Z-toCh.Z*tD.X);if cross<CAR then table.insert(th,{ch=ch,pos=cf,dist=d,cross=cross})end end end end end;return th end
local function cAT(mP,dP)local th=gRCT(mP,dP);if#th==0 then return nil end;table.sort(th,function(a,b)return a.dist<b.dist end);local t=th[1];local mf=Vector3.new(mP.X,0,mP.Z);local df=Vector3.new(dP.X,0,dP.Z);local tD=(df-mf).Unit;local toCh=t.pos-mf;local p1=Vector3.new(-toCh.Unit.Z,0,toCh.Unit.X);local p2=Vector3.new(toCh.Unit.Z,0,-toCh.Unit.X);local bp=(p2:Dot(tD)>=p1:Dot(tD))and p2 or p1;local ap=t.pos+bp*CAS;st.chA=st.chA+1;return cP(Vector3.new(ap.X,mP.Y,ap.Z))end
local function gDTC()local c=0;local r=hr();if not r then return 0 end;for p,t in pairs(aT)do if not t.col and t.dp and p.Parent then if d3(r.Position,p.Position)<80 then c=c+1 end end end;return c end

-- === GO TO ===
local CH_INT=30
local function goTo(tP,rad,to,sk)
    rad=rad or getAP("arr",5);to=to or getAP("mt",6)
    if tP==Vector3.zero then return false end
    local r=hr();local h_=hm();if not r or not h_ then return false end
    tP=cP(tP,sk);if tP==Vector3.zero then local c=gFC();if c==Vector3.zero then return false end;tP=c end
    local oT=Vector3.new(tP.X,r.Position.Y,tP.Z);local cM=oT
    local av=cAT(r.Position,oT);if av then cM=Vector3.new(av.X,r.Position.Y,av.Z)end
    h_:MoveTo(cM);local t0=tick();local lM=tick();local lA=tick()
    while tick()-t0<to do task.wait(0.04)
        if not EN or INT then return false end
        r=hr();if not r then return false end
        if d3(r.Position,oT)<=rad then return true end
        if not sk then local rp=r.Position;for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent and not ch.wasGreen then if d3(rp,ch.part.Position)<=CH_INT then return"CH_NEARBY"end end end end
        if tick()-lA>=0.15 then lA=tick();local na=cAT(r.Position,oT);if na then cM=Vector3.new(na.X,r.Position.Y,na.Z)else cM=oT end end
        if cM~=oT and d3(r.Position,cM)<=4 then local na=cAT(r.Position,oT);cM=na and Vector3.new(na.X,r.Position.Y,na.Z)or oT end
        if tick()-lM>=0.3 then h_=hm();if h_ then h_:MoveTo(cM)end;lM=tick()end
    end;return false
end

-- === СПИРАЛЬ + КРАЙ КЛАСТЕРА ===
local function getFlameDensity()local cnt=0;local r=hr();if not r then return 0 end;for fl in pairs(tF)do if fl.Parent and d3(r.Position,fl.Position)<=20 then cnt=cnt+1 end end;return cnt end
local function isLeavingCluster(target)local mcd=getAP("mcd",10);for fl in pairs(tF)do if fl.Parent then if d3(target,fl.Position)<=mcd then return false end end end;return true end
local function gST()if not sprC or tick()-lSM>2 then lSM=tick();sprC=gFCC();if sprC then sprA=0;sprR=1 end end;if not sprC then return nil end
    local density=getFlameDensity();local step=(density>8 and 0.8)or(density>4 and 1.6)or 3.5
    local scrD=getAP("scrD",4)
    sprA=sprA+step/math.max(sprR,1);sprR=1+sprA*step/(2*math.pi);if sprR>scrD*3 then sprA=0;sprR=1 end
    local target=cP(Vector3.new(sprC.X+math.cos(sprA)*sprR,0,sprC.Z+math.sin(sprA)*sprR))
    if isLeavingCluster(target)then local r=hr();local best,br=nil,getAP("mcd",10)+1
        for fl in pairs(tF)do if fl.Parent then local d=d3(r.Position,fl.Position);if d<br then br=d;best=fl end end end
        if best then return cP(best.Position)end
    end;return target
end

-- === ФЛЕЙМЫ ===
local function iFD(flm)local pf=flm:FindFirstChild("PF");if pf then local co=nil;if pf:IsA("ColorSequenceValue")then local sq=pf.Value;if sq and sq.Keypoints and#sq.Keypoints>0 then local k=sq.Keypoints[1];if k and type(k)=="table"and k.Value then co=k.Value elseif k and type(k)=="userdata"and k.Value then co=k.Value end end elseif pf:IsA("Color3Value")then co=pf.Value elseif pf:IsA("BasePart")then local ok,c=pcall(function()return pf.Color end);if ok then co=c end end;if co then return co.G<0.3 and co.B>0.5 end end;local ok,c=pcall(function()return flm.Color end);if ok and c then return c.G<0.3 and c.B>0.5 end;return false end
local function sFl()local n=tick();local fl=W:FindFirstChild("PlayerFlames");if fl then local seen={};for _,f in ipairs(fl:GetChildren())do if f.Name:sub(1,3)=="Flm"then seen[f]=true;if not tF[f]then tF[f]={sT=n,iD=iFD(f),hit=false}else tF[f].iD=iFD(f)end end end;for f in pairs(tF)do if not seen[f]then tF[f]=nil end end end end
local function tHF()if not EN then return false end;local r=hr();if not r then return false end;local n=tick()
    for fl,data in pairs(tF)do if not data.hit and not data.iD and fl.Parent then if n-data.sT>=FHA and d3(r.Position,fl.Position)<=FHD then INT=true;local bg=r:FindFirstChild("AI_BG");if not bg then bg=Instance.new("BodyGyro");bg.Name="AI_BG";bg.MaxTorque=Vector3.new(0,40000,0);bg.P=10000;bg.D=500;bg.Parent=r end;local dir=(fl.Position-r.Position);dir=Vector3.new(dir.X,0,dir.Z);if dir.Magnitude>0.1 then bg.CFrame=CFrame.lookAt(r.Position,r.Position+dir)end;task.wait(0.1);local tce=nil;local e=RS:FindFirstChild("Events");if e then tce=e:FindFirstChild("ToolCollect")end;if tce then pcall(tce.FireServer,tce);task.wait(0.1)else pcall(function()local cam=workspace.CurrentCamera;local vp=cam.ViewportSize;V:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,true,game,1);task.wait(0.05);V:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,false,game,1)end)end;task.wait(0.15);if bg then bg:Destroy()end;data.hit=true;st.fl=st.fl+1;task.wait(0.2);INT=false;return true end end end;return false end
local function gFCC()local pos={};for fl in pairs(tF)do if fl.Parent then table.insert(pos,fl.Position)end end;if#pos==0 then return nil end;local sum=Vector3.new(0,0,0);for _,p in ipairs(pos)do sum=sum+p end;return cP(sum/#pos)end

-- === ТОКЕНЫ ===
local function rT(o)if o.Name~="C"or not o:IsA("BasePart")or aT[o]or tick()<igT then return end;local fr=o:FindFirstChild("FrontDecal");if not fr or not fr:IsA("Decal")then return end;local id=ti(fr.Texture);if not id or AV[id]then return end;local df=TKS[id];if not df then return end;local r=hr();local dp=r and(o.Position.Y-r.Position.Y)>5;local lf=df.b*AM;if dp then lf=lf*(2+0.05*(DGL-1))end;aT[o]={id=id,n=df.n,p=df.p,mo=df.mo or false,s=tick(),l=lf,dp=dp,col=false}end
W.DescendantAdded:Connect(function(o)task.wait(0.05)pcall(rT,o)end)for _,o in ipairs(W:GetDescendants())do pcall(rT,o)end
game.DescendantRemoving:Connect(function(o)if aT[o]then if aT[o].col then st.tk=st.tk+1 end;aT[o]=nil end end)

-- === BUFFS + PRECISION + PETALS ===
local rps=RS:FindFirstChild("Events")and RS.Events:FindFirstChild("RetrievePlayerStats")
local function sBf()if not rps then return end;local ok,res=pcall(rps.InvokeServer,rps);if not ok or type(res)~="table"then return end
    local function fb(t,src)if type(t)~="table"then return nil end;if rawget(t,"Src")==src then return{st=tonumber(rawget(t,"Combo")or 0)}end;for _,v in pairs(t)do local f=fb(v,src);if f then return f end end;return nil end
    local ss=fb(res,"Scorching Star Aura");aB.SS.st=ss and ss.st or 0;local xf=fb(res,"X-Flame Aura");aB.XF.st=xf and xf.st or 0
    local function chk(t)if type(t)~="table"then return false end;if rawget(t,"BuffID")==2575093099 and rawget(t,"Removed")~=true then return true end;for _,v in pairs(t)do if chk(v)then return true end end;return false end;aB.PM.a=chk(res)
    local function fpm(t)if type(t)~="table"then return nil end;if rawget(t,"BuffID")==PMBI and rawget(t,"Removed")~=true then return rawget(t,"Value")or 1 end;for _,v in pairs(t)do local f=fpm(v);if f then return f end end;return nil end
    local pm=fpm(res);if pm and pm>0 then aB.PoM.a=true;aB.PoM.m=pm;if aR then aB.PoM.pos=aR.Position end else aB.PoM.a=false end
end
local function sPr()if not rps then return end;local ok,pd=pcall(rps.InvokeServer,rps);if not ok or type(pd)~="table"then return end
    local function fp(t)if type(t)~="table"then return nil end;if rawget(t,"BuffID")==PBI and rawget(t,"Removed")~=true then return t end;if rawget(t,"Src")=="Precision"then return t end;for _,v in pairs(t)do local f=fp(v);if f then return f end end;return nil end
    local b=fp(pd);if b then local val=tonumber(b.Value)or 0;if tonumber(b.Start)~=prec.sS then prec.sS=tonumber(b.Start)or 0;prec.sD=tonumber(b.Dur)or 60;prec.ls=os.clock()end;prec.st=math.min(PMX,math.round(val/PPK));prec.val=val;prec.isX=(prec.st>=PMX)else prec.st=0;prec.val=0;prec.isX=false end
    if prec.ls>0 then prec.tL=math.max(0,prec.sD-(os.clock()-prec.ls));prec.nR=prec.isX and(prec.tL<=PRAT);if prec.nR and rCC==0 then rST=tick();rCC=0 end end
end
local function gPC(p)for n,co in pairs(PC)do if(co.R-p.Color.R)^2+(co.G-p.Color.G)^2+(co.B-p.Color.B)^2<0.002 then return n end end;return nil end
local function sPt()fP={};if not EN or not curF then return end;local pt=W:FindFirstChild("Particles");if not pt then return end;local r=hr();if not r then return end;for _,o in ipairs(pt:GetChildren())do if o.Name=="PetalPart"and o:IsA("BasePart")and iF(o.Position)then local cn=gPC(o);if cn and PP[cn]then table.insert(fP,{part=o,cn=cn,pr=PP[cn],dist=d3d(r.Position,o.Position)})end end end;table.sort(fP,function(a,b)if a.pr~=b.pr then return a.pr<b.pr end;return a.dist<b.dist end)end

-- === SMILE ===
local function sSm()local n=tick();smT=nil;smTR=0;local bp,bd,br=nil,math.huge,0;local r=hr();if not r then return end;local rp=aR and aR.Position
    for p,t in pairs(aT)do if not t.col and p.Parent and t.id==SMI then local rem=t.l-(n-t.s);if rem<=SMRT and rem>0 then local tk=false;if rp then if d3(p.Position,rp)<=aRR*1.5 then tk=true end else tk=true end;if gDTC()>=6 and tk then local d=d3(r.Position,p.Position);if d<bd then bp=p;bd=d;br=rem end end end end end
    if bp then smT=bp;smTR=br;if not isCS then INT=true end end
end

-- === HPS ===
local function fHL()local sg=L.PlayerGui:FindFirstChild("ScreenGui");if not sg then return nil end;local mh=sg:FindFirstChild("MeterHUD");if not mh then return nil end;local hm_=mh:FindFirstChild("HoneyMeter");if not hm_ then return nil end;local bar=hm_:FindFirstChild("Bar");if not bar then return nil end;return bar:FindFirstChild("PerSecLabel")end
local function pHP(tx)if type(tx)~="string"then return 0 end;tx=tx:gsub(",",""):gsub(" ",""):upper();local n,sf=tx:match("([%d.]+)([KM]?)");if not n then return 0 end;local v=tonumber(n)or 0;if sf=="K"then v=v*1000 elseif sf=="M"then v=v*1000000 end;return v end
local function gHP()if not hML or not hML.Parent then hML=fHL()end;if hML and hML:IsA("TextLabel")then return pHP(hML.Text)end;return 0 end
local function uHB()local n=tick();local hps=gHP();if hps>0 then table.insert(hB,{time=n,hps=hps})end;local cut=n-120;while#hB>0 and hB[1].time<cut do table.remove(hB,1)end;if tL and tL~="старт"then local r=hr();local flCnt=0;for _ in pairs(tF)do flCnt=flCnt+1 end;local chCnt=#cQ;table.insert(aBf,{time=n,action=tL,pos=r and r.Position or Vector3.zero,phase=ph(),isSc=aB.SS.st>0,flCnt=flCnt,chCnt=chCnt})end;while#aBf>0 and aBf[1].time<cut do table.remove(aBf,1)end
    if n-laT>=10 then laT=n;local sum,cn=0,0;for _,e in ipairs(hB)do sum=sum+e.hps;cn=cn+1 end;local av=cn>0 and(sum/cn)or 0
        if av>0 then local ac={};for _,e in ipairs(aBf)do table.insert(ac,{action=e.action,pos=e.pos,to=e.time-(n-120),phase=e.phase,isSc=e.isSc,flCnt=e.flCnt,chCnt=e.chCnt})end
            local totalFl=0;local totalCh=0;for _,e in ipairs(ac)do totalFl=totalFl+e.flCnt;totalCh=totalCh+e.chCnt end
            local avgFl=#ac>0 and math.floor(totalFl/#ac)or 0;local avgCh=#ac>0 and math.floor(totalCh/#ac)or 0
            table.insert(pH,{hps=av,actions=ac,timestamp=n,ctx={flames=avgFl,chs=avgCh,phase=ph(),scorch=aB.SS.st>0 and 1 or 0}})
            table.sort(pH,function(a,b)return a.hps>b.hps end);while#pH>30 do table.remove(pH)end
            if av>bAH then bAH=av end;pcall(function()writefile(pF,H:JSONEncode(pH))end)
        end;if n-lastGenTime>300 then lastGenTime=n;generatePattern()end
    end
end
local function gPB(action,pos)if#pH==0 then return 0 end;local p_=ph();local isSc=aB.SS.st>0;local flCnt=0;for _ in pairs(tF)do flCnt=flCnt+1 end;local chCnt=#cQ;local be=0
    for _,p in ipairs(pH)do for _,pa in ipairs(p.actions)do if pa.action==action then if(pos-pa.pos).Magnitude<10 then
        local phaseMatch=(pa.phase==p_)and 2 or 1
        local scorchMatch=(pa.isSc==isSc)and 2 or 1
        local ctxMatch=1
        if p.ctx then if math.abs((p.ctx.flames or 0)-flCnt)<=3 then ctxMatch=ctxMatch*1.5 end;if math.abs((p.ctx.chs or 0)-chCnt)<=2 then ctxMatch=ctxMatch*1.4 end end
        local noveltyBonus=p.generated and 1.3 or 1
        local ms=phaseMatch*scorchMatch*ctxMatch*noveltyBonus
        if ms>be then be=ms end
    end end end end
    return 15*be
end

-- === Q-LEARNING ===
local function gQ(s,a)return(QT[s]and QT[s][a])or 0 end
local function sQ(s,a,v)if not QT[s]then QT[s]={}end;QT[s][a]=v end
local function hTL()for _,t in pairs(aT)do if not t.col and t.p>=90 then return true end end;return false end
local function gDTP()local n=tick();for p,t in pairs(aT)do if not t.col and p.Parent and t.id==TPI and t.dp then if t.l-(n-t.s)>1 then return p,t end end end;return nil,nil end
local function gSDA()local r=hr();if not r then return nil end;local rp=aR and aR.Position;if not rp then return nil end;local bp,bd=nil,math.huge;for p,t in pairs(aT)do if not t.col and p.Parent then if(t.id==SMI)or(t.id==TPI and t.dp)then if d3(p.Position,rp)<=aRR*1.5 then local d=d3(r.Position,p.Position);if d<bd then bd=d;bp=p end end end end end;return bp end
local function eS()local r=hr();if not r then return"dead"end;local p_=ph();local tlD="none";for p,t in pairs(aT)do if not t.col and p.Parent and t.p>=90 then local d=d3(r.Position,p.Position);if d<20 then tlD="close"elseif d<60 then tlD="far"end end end;local prN=math.min(3,#gCH(true,false));local rN=math.min(3,#gCH(false,true));local sU=(smT~=nil);local hP_=(#fP>0);local nT=false;local n=tick();for p,t in pairs(aT)do if not t.col and p.Parent and(t.l-(n-t.s))>1 and d3(r.Position,p.Position)<30 then nT=true;break end end
    local zn="mid";if curF then local c=curF.part.Position;local s=curF.part.Size;if s.X>0 and s.Z>0 then local rx=math.abs(r.Position.X-c.X)/(s.X/2);local rz=math.abs(r.Position.Z-c.Z)/(s.Z/2);if rx>0.7 or rz>0.7 then zn="edge"elseif rx<0.3 and rz<0.3 then zn="center"end end end
    local chT="none";if prec.isX and not prec.nR then local ct=0;for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent and not ch.isP and not ch.wasGreen and d3(r.Position,ch.part.Position)<20 then ct=ct+1 end end;if ct>2 then chT="many"elseif ct>0 then chT="some"end end
    local di=getDiagonalGroups();local dg=di and#di>0 and"1"or"0"
    return string.format("PH:%s|TL:%s|CH:%d|PR:%d|SM:%s|NT:%s|Z:%s|CT:%s|PT:%s|DG:%s",p_,tlD,rN,prN,tostring(sU),tostring(nT),zn,chT,tostring(hP_),dg)
end

-- === ДЕЙСТВИЯ ===
local function gAWB()local ba={};local p_=ph();local n=tick()
    local untCH=gUNT(false,false)
    if#untCH>0 then if p_=="X10"then local tp=gTPG();if tp then return{"go_target_practice_purple"}end;local pp=gUNT(true,false);if#pp>0 then return{"go_purple"}end end
        if p_=="REFRESH"then local di=getDiagonalForRefresh()
            if di then table.insert(ba,"go_crosshair_refresh_diagonal")else local all=gCHall(false,false);if#all>0 then table.insert(ba,"go_crosshair_refresh_all")else table.insert(ba,"patrol_ring")end end;return ba
        end;table.insert(ba,"go_crosshair")end
    if hTL()then return{"go_tokenlink"}end
    if p_~="НАБОР"then for p,t in pairs(aT)do if not t.col and p.Parent and(t.l-(n-t.s))<0.3 and(t.l-(n-t.s))>0 then return{"go_urgent_token"}end end end
    if aB.SS.st>0 and next(tF)then table.insert(ba,"go_scorching_spiral")end
    if smT then return{"go_smile"}end
    if aB.PoM.a and aR then local t=gSDA();if t then local td=aT[t];if td and td.id==SMI then table.insert(ba,1,"go_smile_area")elseif td and td.id==TPI and td.dp then table.insert(ba,1,"go_dup_area")end end end
    if xfE then local cc=gFC();if cc~=Vector3.zero then local bC,bD=nil,XCR+1;for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent and not ch.wasGreen then local d=d3(ch.part.Position,cc);if d<=XCR and d<bD then bD=d;bC=ch end end end;if bC then return{"go_xflame_ch"}else return{"go_xflame_center"}end end end
    if#fP>0 then table.insert(ba,"go_petal")end
    local ha=false;for _ in pairs(aT)do ha=true;break end;if ha then table.insert(ba,"go_token_near");table.insert(ba,"go_token_best")end
    local dt=gDTP();if dt then table.insert(ba,"go_dup_tp")end;table.insert(ba,"patrol_ring");if p_=="НАБОР"then table.insert(ba,"patrol_random")end;return ba
end
local function cAB(s)local v=gAWB();if#v==0 then return"patrol_ring"end;if math.random()<EP then return v[math.random(1,#v)]end;local bA,bQ=v[1],gQ(s,v[1]);for i=2,#v do local q=gQ(s,v[i]);if q>bQ then bA=v[i];bQ=q end end;return bA end
local function dUQ(s,a,rw,ns)local rr=hr();local mr=getMicroReward();local tR=mr+gPB(a,rr and rr.Position or Vector3.zero);local v=gAWB();local mN=0;for _,a_ in ipairs(v)do local q=gQ(ns,a_);if q>mN then mN=q end end;local nw=gQ(s,a)+AL*(tR+GA*mN-gQ(s,a));sQ(s,a,nw);st.tR=st.tR+tR;st.dc=st.dc+1;EP=math.max(0.02,EP*ED);tryMutateParams()end

-- === ВИЗУАЛИЗАЦИЯ ===
local function uXC()if xfE then local cc=gFC();if cc==Vector3.zero then local r=hr();if r then cc=r.Position end end;if not xfC then xfC=Instance.new("Part");xfC.Name="XFlameCircle";xfC.Shape=Enum.PartType.Cylinder;xfC.Anchored=true;xfC.CanCollide=false;xfC.Transparency=0.6;xfC.BrickColor=BrickColor.Red();xfC.Size=Vector3.new(XCR*2,0.2,XCR*2);xfC.Parent=W end;xfC.Position=Vector3.new(cc.X,cc.Y+0.2,cc.Z)else if xfC then xfC:Destroy();xfC=nil end end end
local function uSC()if EN then local r=hr();if r then if not scC then scC=Instance.new("Part");scC.Name="ScytheRadius";scC.Shape=Enum.PartType.Cylinder;scC.Anchored=true;scC.CanCollide=false;scC.Transparency=0.6;scC.BrickColor=BrickColor.new("Bright orange");scC.Size=Vector3.new(FHD*2,0.2,FHD*2);scC.Parent=W end;scC.Position=Vector3.new(r.Position.X,r.Position.Y+0.2,r.Position.Z)end else if scC then scC:Destroy();scC=nil end end end
local function gEP(tP)if not aR or not aR.Parent then return tP end;local dir=(tP-aR.Position).Unit;return cP(Vector3.new(aR.Position.X+dir.X*aRR,0,aR.Position.Z+dir.Z*aRR))end

-- === ИСПОЛНЕНИЕ ===
local function eA(action)
    local r=hr();if not r then return-1 end
    snapMicroHPS()
    if action=="go_scorching_spiral"then local t=gST();if not t then return-1 end;tL="🔥 Спираль";INT=false;goTo(t,2,2);return 0
    elseif action=="go_crosshair_refresh_diagonal"then local di=getDiagonalForRefresh();if not di then return-1 end
        local g=di[1];local col=0;INT=false
        for _,ch in ipairs({g.r1,g.r2,g.pr})do if ch.part.Parent and not ch.col and not ch.wasGreen then
            tL="🔄 REFRESH диаг ("..(col+1).."/3)";goTo(ch.part.Position,4,4,true)
            if ch.part.Parent then ch.col=true;rCC=rCC+1
                if ch.isP then st.pr=st.pr+1;lP=ch.part else st.ch=st.ch+1 end;col=col+1;st.diag=st.diag+1;task.wait(0.1)
            end
        end end
        if aR and aR.Parent then goTo(aR.Position,6,4)end
        if rCC>=3 then prec.nR=false;cyc.chC=0;st.rf=st.rf+1;rCC=0;tL="✅ REFRESH диаг OK"end;return 0
    elseif action=="go_crosshair_refresh_all"then local all=gCHall(false,false);if#all==0 then return-1 end;local col=0;INT=false
        for _,ch in ipairs(all)do if ch.part.Parent and not ch.col then if col>=3 then break end;if not ch.wasGreen then tL="🔄 REFRESH";goTo(ch.part.Position,4,4,true);if ch.part.Parent then ch.col=true;rCC=rCC+1;if ch.isP then st.pr=st.pr+1;lP=ch.part else st.ch=st.ch+1 end;col=col+1;task.wait(0.1)end end end end
        if aR and aR.Parent then goTo(aR.Position,6,4)else goTo(cP(r.Position),5,2)end
        if rCC>=3 then prec.nR=false;cyc.chC=0;st.rf=st.rf+1;rCC=0;tL="✅ REFRESH OK"end;return 0
    elseif action=="go_target_practice_purple"then local tp=gTPG();if not tp then return-1 end;INT=false
        for _,g in ipairs(tp)do if g.pr.part.Parent and not g.pr.col and not g.pr.wasGreen then tL="🎯 TP фиол";goTo(g.pr.part.Position,4,5);if g.pr.part.Parent then g.pr.col=true;g.r1.col=true;g.r2.col=true;lP=g.pr.part;st.pr=st.pr+1;tL="🟣 TP Precise Mark";local t0=tick();while tick()-t0<getAP("pst",1)do task.wait(0.05);if smT or prec.nR or not EN then break end end end end end;return 0
    elseif action=="go_smile_area"then local t=gSDA();if not t then return-1 end;local td=aT[t];if not td or td.col or td.id~=SMI then return-1 end;tL="😊 Smile (Ring)";INT=false;goTo(gEP(t.Position),4,4);if t.Parent then local st_=tick();while tick()-st_<getAP("tsd",1.1)do task.wait(0.1);if not t.Parent or INT then break end;local hp=hr();if hp then hp.CFrame=CFrame.new(t.Position.X,hp.Position.Y,t.Position.Z)end end;td.col=true;st.sm=st.sm+1 end;return 0
    elseif action=="go_dup_area"then local t=gSDA();if not t then return-1 end;local td=aT[t];if not td or td.col or td.id~=TPI or not td.dp then return-1 end;tL="🎯 Dup (Ring)";INT=false;goTo(gEP(t.Position),4,4);if t.Parent then local st_=tick();while tick()-st_<getAP("tsd",1.1)do task.wait(0.1);if not t.Parent or INT then break end;local hp=hr();if hp then hp.CFrame=CFrame.new(t.Position.X,hp.Position.Y,t.Position.Z)end end;td.col=true;st.tk=st.tk+1 end;return 0
    elseif action=="go_smile"then local t=smT;if not t or not t.Parent then smT=nil;return-1 end;local td=aT[t];if not td or td.col then smT=nil;return-1 end;isCS=true;tL="😊 Smile";INT=false;goTo(t.Position,4,math.min(5,smTR-0.5));if t.Parent then local st_=tick();while tick()-st_<getAP("tsd",1.1)do task.wait(0.1);if not t.Parent or INT then break end;local hp=hr();if hp then hp.CFrame=CFrame.new(t.Position.X,hp.Position.Y,t.Position.Z)end end;td.col=true;smT=nil;st.sm=st.sm+1;isCS=false end;return 0
    elseif action=="go_urgent_token"then local n=tick();local be,bl=nil,0.3;for p,t in pairs(aT)do if not t.col and p.Parent then local rem=t.l-(n-t.s);if rem<bl and rem>0 then bl=rem;be=p end end end;if be then tL="⚡Срочный";INT=false;goTo(be.Position,4,2);if be.Parent then aT[be].col=true;st.tk=st.tk+1 end end;return 0
    elseif action=="go_purple"then local pp=gUNT(true,false);if#pp==0 then return-1 end;INT=false;for _,ch in ipairs(pp)do if ch.part.Parent and not ch.col and not smT and not prec.nR and not ch.wasGreen then goTo(ch.part.Position,4,5);if ch.part.Parent then ch.col=true;lP=ch.part;st.pr=st.pr+1;tL="🟣 1с";local t0=tick();while tick()-t0<getAP("pst",1)do task.wait(0.05);if smT or prec.nR or not EN then break end end end end end;return 0
    elseif action=="go_tokenlink"then for p,t in pairs(aT)do if not t.col and p.Parent and t.p>=90 then tL="💎🔴 Link";INT=false;goTo(p.Position,5,5);if p.Parent then t.col=true;igT=tick()+TLC end;return 0 end end;return 0
    elseif action=="go_crosshair"then local all=gUNT(false,false);if#all==0 then all=gCH(false,false);if#all==0 then return-1 end end;local t=all[1];INT=false
        if t.part.Parent and not t.col and not smT and not prec.nR then local sk=false;local r2=hr()
            if r2 then for p2,t2 in pairs(aT)do if not t2.col and p2.Parent and t2.p>=90 then if d3(r2.Position,p2.Position)<TLID and d3(r2.Position,t.part.Position)>30 then sk=true;break end end end end
            if not sk then goTo(t.part.Position,4,5);if t.part.Parent then t.col=true;if t.isP then st.pr=st.pr+1;lP=t.part else st.ch=st.ch+1 end end end
        end;return 0
    elseif action=="go_dup_tp"then local p,t=gDTP();if not p then return-1 end;tL="🎯 Dup";INT=false;goTo(p.Position,5,5);if p.Parent then local st_=tick();while tick()-st_<getAP("tsd",1.1)do task.wait(0.1);if not p.Parent or INT then break end;local hp=hr();if hp then hp.CFrame=CFrame.new(p.Position.X,hp.Position.Y,p.Position.Z)end end;t.col=true end;return 0
    elseif action=="go_petal"then if#fP==0 then return-1 end;local i=1;while i<=#fP do local pt=fP[i];if not pt.part.Parent then table.remove(fP,i)elseif stP[pt.part]and tick()<stP[pt.part]then table.remove(fP,i)else tL="🌸 "..pt.cn;INT=false;local ok=goTo(Vector3.new(pt.part.Position.X,0,pt.part.Position.Z),PCD,2.5);if ok==true then st.pt=st.pt+1;i=i+1 elseif ok=="CH_NEARBY"then return 0 else stP[pt.part]=tick()+5;table.remove(fP,i)end end end;return 0
    elseif action=="go_token_near"then local be,bD=nil,math.huge;for p,t in pairs(aT)do if not t.col and p.Parent then local d=d3(r.Position,p.Position);if d<bD then be=p;bD=d end end end;if be then local t=aT[be];tL="💎 "..t.n;INT=false;goTo(be.Position,5,5);if be.Parent then t.col=true end end;return 0
    elseif action=="go_token_best"then local be,bP=nil,-1;local n=tick();for p,t in pairs(aT)do if not t.col and p.Parent and(t.l-(n-t.s))>0.5 and t.p>bP then be=p;bP=t.p end end;if be then local t=aT[be];tL="💎⭐ "..t.n;INT=false;goTo(be.Position,5,5);if be.Parent then t.col=true end end;return 0
    elseif action=="patrol_ring"then local function rR()if aR and aR.Parent and curF then local a_=math.random()*2*math.pi;local rr_=aRR*(0.5+math.random()*0.8);return cP(Vector3.new(aR.Position.X+math.cos(a_)*rr_,0,aR.Position.Z+math.sin(a_)*rr_))elseif curF then local c=curF.part.Position;local s=curF.part.Size;return cP(Vector3.new(c.X+(math.random()*2-1)*math.max(s.X/2*0.3,5),0,c.Z+(math.random()*2-1)*math.max(s.Z/2*0.3,5)))else local rp=hr();if rp then return cP(rp.Position+Vector3.new((math.random()*2-1)*30,0,(math.random()*2-1)*30))else return cP(Vector3.zero)end end end;tL="🚶 кольцо";INT=false;local t=rR();if t==Vector3.zero or not iF(t)then t=gFC()end;if t==Vector3.zero then return 0 end;goTo(t,6,getAP("pt",8));task.wait(0.1+math.random()*0.3);return 0
    elseif action=="patrol_random"then local function rF()if curF then local c=curF.part.Position;local s=curF.part.Size;return cP(Vector3.new(c.X+(math.random()*2-1)*math.max(s.X/2-3,1),0,c.Z+(math.random()*2-1)*math.max(s.Z/2-3,1)))else local rp=hr();if rp then return cP(rp.Position+Vector3.new((math.random()*2-1)*30,0,(math.random()*2-1)*30))else return cP(Vector3.zero)end end end;tL="🚶 патруль";INT=false;local t=rF();if t==Vector3.zero or not iF(t)then t=gFC()end;goTo(t,4,getAP("pt",8));task.wait(0.2+math.random()*0.4);return 0
    elseif action=="go_xflame_center"then local c=gFC();if c==Vector3.zero then return-1 end;tL="🔥 XFlame центр";INT=false;goTo(c,3,3);return 0
    elseif action=="go_xflame_ch"then local c=gFC();if c==Vector3.zero then return-1 end;local bC,bD=nil,XCR+1;for _,ch in ipairs(cQ)do if not ch.col and ch.part.Parent and not ch.wasGreen then local d=d3(ch.part.Position,c);if d<=XCR and d<bD then bD=d;bC=ch end end end;if bC then tL="🔥 XFlame CH";INT=false;goTo(bC.part.Position,2,3);task.wait(1)end;return 0
    end
    return 0
end

-- === ГЛАВНЫЙ HEARTBEAT ===
local mLS=false
local function sML()if mLS then return end;mLS=true;task.wait(2);lQ();fAR();fF();lI("BSS AI v13.0!");print("✅ v13.0");tL="иниц";lMT=tick();snapMicroHPS();lastGenTime=tick()end
task.spawn(function()pcall(function()local ok,raw=pcall(readfile,pF);if ok and raw then local ok2,data=pcall(H.JSONDecode,H,raw);if ok2 and type(data)=="table"then pH=data;for _,p in ipairs(pH)do if p.hps and p.hps>bAH then bAH=p.hps end end end end end);lI("Паттерны OK")end)
R.Heartbeat:Connect(function()
    hbF=hbF+1;if not EN then return end;if not mLS then sML();return end
    local n=tick();fAR();updateGreenStatus()
    if hbF%18==0 then sBf();sPr()end
    if hbF%12==0 then sFl()end
    if hbF%9==0 then sPt();local h_=hm();if h_ then local ts=gAS();if math.abs(h_.WalkSpeed-ts)>0.5 then h_.WalkSpeed=ts end end;tHF()end
    if hbF%6==0 then pcall(uHB);checkMutation()end
    if hbF%3==0 then sSm()end
    if hbF%180==0 then fF()end
    if hbF%18000==0 then pcall(function()local qc=0;for _ in pairs(QT)do qc=qc+1 end;pcall(writefile,"bss_ai_q_v13.json",H:JSONEncode({version=VQ,qtable=QT,aP=aP,gen=#generatedPatterns,meta={sc=qc,sa=os.time()}}))end)end
    xfE=(aB.XF.st>=20);if xfE then INT=true end;uXC();uSC()
    local r=hr();if r then local vel=r.AssemblyLinearVelocity;local hS=(Vector3.new(vel.X,0,vel.Z)).Magnitude;if hS>0.2 then lMT=n;stW=false elseif n-lMT>5 and not stW then stW=true;INT=true;tL="⏳ сброс";if lP and not lP.Parent then lP=nil end;if smT and not smT.Parent then smT=nil;isCS=false end;INT=false;lMT=n end end
    if INT and not smT and not prec.nR and not xfE then INT=false end
    if isA then return end
    if hbF%2==0 then isA=true;local s_=eS();local a_=cAB(s_);local ok,rw=pcall(eA,a_);if not ok then rw=-1 end;local ns=eS();pcall(dUQ,s_,a_,rw,ns);isA=false end
end)
function lQ()local ok,raw=pcall(readfile,"bss_ai_q_v13.json");if ok and raw then local ok2,d=pcall(H.JSONDecode,H,raw);if ok2 and type(d)=="table"and d.version==VQ and type(d.qtable)=="table"then QT=d.qtable;if d.aP then for k,v in pairs(d.aP)do aP[k]=v end end end end end
local function rQ()QT={};EP=0.1;st.tR=0;st.dc=0;aP={scrD=4,pst=1,tsd=1.1,mcd=10,pt=8,arr=5,mt=6};generatedPatterns={};lastGenTime=0;pcall(writefile,"bss_ai_q_v13.json",H:JSONEncode({version=VQ,qtable={},aP=aP,meta={ra=os.time()}}))end

-- === GUI ===
local sg=Instance.new("ScreenGui",G)sg.Name="BSSAI_GUI"
local fr=Instance.new("Frame",sg)fr.Size=UDim2.new(0,270,0,120)fr.Position=UDim2.new(0,10,0,10)
fr.BackgroundColor3=Color3.fromRGB(20,20,30)fr.BackgroundTransparency=0.15 fr.BorderSizePixel=0 fr.Active=true fr.Draggable=true Instance.new("UICorner",fr).CornerRadius=UDim.new(0,6)
local ti_=Instance.new("TextLabel",fr)ti_.Size=UDim2.new(1,0,0,20)ti_.Position=UDim2.new(0,0,0,2)ti_.BackgroundTransparency=1 ti_.Text="🧠 BSS AI v13.0 self-gen"ti_.TextColor3=Color3.fromRGB(100,200,255)ti_.Font=Enum.Font.GothamBold ti_.TextSize=12 ti_.TextXAlignment=Enum.TextXAlignment.Center
local lb=Instance.new("TextLabel",fr)lb.Size=UDim2.new(1,0,0,18)lb.Position=UDim2.new(0,0,0,24)lb.BackgroundTransparency=1 lb.Text="Действие: старт"lb.TextColor3=Color3.fromRGB(255,255,255)lb.Font=Enum.Font.Gotham lb.TextSize=13 lb.TextXAlignment=Enum.TextXAlignment.Center
local hl=Instance.new("TextLabel",fr)hl.Size=UDim2.new(1,0,0,18)hl.Position=UDim2.new(0,0,0,44)hl.BackgroundTransparency=1 hl.Text="HPS: -- | Рек: --"hl.TextColor3=Color3.fromRGB(150,255,150)hl.Font=Enum.Font.Gotham hl.TextSize=12 hl.TextXAlignment=Enum.TextXAlignment.Center
local sl_=Instance.new("TextLabel",fr)sl_.Size=UDim2.new(1,0,0,18)sl_.Position=UDim2.new(0,0,0,64)sl_.BackgroundTransparency=1 sl_.Text="⚡ --"sl_.TextColor3=Color3.fromRGB(255,200,100)sl_.Font=Enum.Font.Gotham sl_.TextSize=11 sl_.TextXAlignment=Enum.TextXAlignment.Center
local pl_=Instance.new("TextLabel",fr)pl_.Size=UDim2.new(1,0,0,18)pl_.Position=UDim2.new(0,0,0,82)pl_.BackgroundTransparency=1 pl_.Text="Φ: --"pl_.TextColor3=Color3.fromRGB(180,180,255)pl_.Font=Enum.Font.Gotham pl_.TextSize=11 pl_.TextXAlignment=Enum.TextXAlignment.Center
local al_=Instance.new("TextLabel",fr)al_.Size=UDim2.new(1,0,0,18)al_.Position=UDim2.new(0,0,0,100)al_.BackgroundTransparency=1 al_.Text="AI: --"al_.TextColor3=Color3.fromRGB(255,180,100)al_.Font=Enum.Font.Gotham al_.TextSize=10 al_.TextXAlignment=Enum.TextXAlignment.Center
task.spawn(function()while true do task.wait(0.3)lb.Text="🎯 "..tL;local cur=gHP();local hs=cur>0 and string.format("%.0f",cur)or"--";local bs=bAH>0 and string.format("%.0f",bAH)or"--";hl.Text="HPS: "..hs.." | Рек: "..bs;sl_.Text="⚡ "..string.format("%.0f",cS);pl_.Text="Φ:"..ph().." CH:"..#cQ.." Ген:"..#generatedPatterns;al_.Text="AI s:"..string.format("%.1f",aP.scrD).." p:"..string.format("%.1f",aP.pst).." t:"..string.format("%.1f",aP.tsd)end end)
U.InputBegan:Connect(function(i,gp)if gp then return end;if i.KeyCode==Enum.KeyCode.T then EN=not EN;sg.Enabled=EN elseif i.KeyCode==Enum.KeyCode.G then rQ()end end)
L.CharacterAdded:Connect(function()task.wait(2)aT={};cQ={};lP=nil;curF=nil;tL="старт";smT=nil;isCS=false;INT=false;cyc={chC=0};tF={};fP={};igT=0;rCC=0;sprC=nil;sprA=0;sprR=0;if xfC then xfC:Destroy();xfC=nil end;if scC then scC:Destroy();scC=nil end;pcall(function()local qc=0;for _ in pairs(QT)do qc=qc+1 end;pcall(writefile,"bss_ai_q_v13.json",H:JSONEncode({version=VQ,qtable=QT,aP=aP,meta={sc=qc,sa=os.time()}}))end)end)
print("✅ OK")
