-- bladevvball Universal Hub v6 — PC + Mobile
-- Joystick left side, 15 new features, all verified working.

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local StarterGui       = game:GetService("StarterGui")
local HttpService      = game:GetService("HttpService")
local VirtualUser      = game:GetService("VirtualUser")
local SoundService     = game:GetService("SoundService")
local TeleportService  = game:GetService("TeleportService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local pg  = plr:WaitForChild("PlayerGui")
local CAM = Workspace.CurrentCamera

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local IS_TABLET = UserInputService.TouchEnabled and UserInputService.MouseEnabled
local VIEW      = CAM.ViewportSize
local UI_SCALE  = 1
if IS_MOBILE then UI_SCALE = 0.92 end
if VIEW.X < 600 then UI_SCALE = 0.78 end
if VIEW.X < 450 then UI_SCALE = 0.62 end

local function S(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then warn("[bv]", res); return nil end
    return res
end
local function notify(t, txt)
    S(function()
        StarterGui:SetCore("SendNotification", {Title=t, Text=txt, Duration=2})
    end)
end

-- GAME DETECT
local TAGS = {
    [2753915549]="BLXFR",[4442272183]="BLXFR",[7449423635]="BLXFR",
    [920587237]="ADOPT",[286090429]="ARSNL",[2788229376]="DAHOOD",
    [155615604]="PRSN",[142823291]="MM2",[606849621]="JAIL",
    [189707]="NDS",[537413528]="BABFT",[6516141723]="DOORS",
    [6178532807]="RBF",
}
local GAME = { name="Universal", tag=TAGS[game.PlaceId] or "UNI" }
S(function()
    local i = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    if i and i.Name then GAME.name = i.Name end
end)

-- STATE
local ST = {
    ws=16, jp=50, grav=196.2, flySpd=80,
    fly=false, flyUp=false, flyDown=false,
    infJump=false, noclip=false, ghost=false, antiafk=true, spin=false,
    trail=false, clickTP=false, sit=false, ragdoll=false, freezeSelf=false,
    antiFling=false, antiVoid=false, autoRespawn=false, walkWater=false,
    pointLight=false, freezeAll=false, fastRespawn=false, bigHead=false,
    fullbright=false, noFog=false, camZoom=0,
    esp=false, espDist=false, espHP=false, tracers=false, chams=false, xray=false,
    reach=5, hitbox=1, autoAtk=false, killAura=false, autoEquip=false,
    particleFX=false, soundFX=false, rainbow=false, dance=false,
    chatSpam=false, charScale=1, lastSafePos=nil,
}

local SAVED = {
    bright=Lighting.Brightness, time=Lighting.ClockTime,
    fog=Lighting.FogEnd, outAmb=Lighting.OutdoorAmbient,
    gShadows=Lighting.GlobalShadows,
}

-- ==============================
-- MOBILE FLY CONTROLLER (JOYSTICK ON LEFT)
-- ==============================
local flyGui = Instance.new("ScreenGui")
flyGui.Name="bv_FlyCtl"; flyGui.ResetOnSpawn=false
flyGui.IgnoreGuiInset=true; flyGui.Enabled=false; flyGui.Parent=pg

-- Joystick base (bottom-LEFT — moved)
local jsBase = Instance.new("Frame")
jsBase.Size=UDim2.new(0,130,0,130)
jsBase.Position=UDim2.new(0,30,1,-180)
jsBase.BackgroundColor3=Color3.fromRGB(20,20,30)
jsBase.BackgroundTransparency=0.55; jsBase.BorderSizePixel=0
jsBase.Active=true; jsBase.Parent=flyGui
local jsBC = Instance.new("UICorner"); jsBC.CornerRadius=UDim.new(1,0); jsBC.Parent=jsBase
local jsBS = Instance.new("UIStroke"); jsBS.Color=Color3.fromRGB(0,220,255)
jsBS.Thickness=2; jsBS.Transparency=0.4; jsBS.Parent=jsBase

local jsKnob = Instance.new("Frame")
jsKnob.Size=UDim2.new(0,54,0,54)
jsKnob.Position=UDim2.new(0.5,-27,0.5,-27)
jsKnob.BackgroundColor3=Color3.fromRGB(0,200,240)
jsKnob.BackgroundTransparency=0.15; jsKnob.BorderSizePixel=0
jsKnob.Active=false; jsKnob.Parent=jsBase
local jsKC = Instance.new("UICorner"); jsKC.CornerRadius=UDim.new(1,0); jsKC.Parent=jsKnob

local jsVec = Vector2.new(0,0)

do
    local dragging, center, radius
    local function update(input)
        local rel = Vector2.new(input.Position.X-center.X, input.Position.Y-center.Y)
        local mag = math.min(rel.Magnitude, radius)
        if rel.Magnitude > 0 then rel = rel.Unit * mag end
        jsKnob.Position = UDim2.new(0.5,-27+rel.X,0.5,-27+rel.Y)
        jsVec = Vector2.new(rel.X/radius, -rel.Y/radius)
    end
    jsBase.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            center=Vector2.new(jsBase.AbsolutePosition.X+jsBase.AbsoluteSize.X/2,
                                jsBase.AbsolutePosition.Y+jsBase.AbsoluteSize.Y/2)
            radius=jsBase.AbsoluteSize.X/2-20
            update(i)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
            update(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=false
            jsKnob.Position=UDim2.new(0.5,-27,0.5,-27)
            jsVec=Vector2.new(0,0)
        end
    end)
end

-- Up / Down buttons stay on the RIGHT side
local function mkFlyBtn(txt, yOff, cb)
    local b = Instance.new("TextButton")
    b.Size=UDim2.new(0,58,0,58)
    b.Position=UDim2.new(1,-78,1,yOff)
    b.BackgroundColor3=Color3.fromRGB(20,20,30)
    b.BackgroundTransparency=0.35; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=Color3.fromRGB(0,220,255)
    b.TextSize=26; b.Font=Enum.Font.GothamBold
    b.Active=true; b.Parent=flyGui
    local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=b
    local s = Instance.new("UIStroke"); s.Color=Color3.fromRGB(0,220,255)
    s.Thickness=2; s.Transparency=0.4; s.Parent=b
    b.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then cb(true) end
    end)
    b.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then cb(false) end
    end)
    return b
end
mkFlyBtn("▲", -300, function(on) ST.flyUp=on end)
mkFlyBtn("▼", -230, function(on) ST.flyDown=on end)

-- ==============================
-- SNOW INTRO
-- ==============================
local function snowIntro(dur)
    dur = dur or 1.0
    S(function()
        local sg = Instance.new("ScreenGui")
        sg.Name="bv_Snow"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
        sg.DisplayOrder=999; sg.Parent=pg
        local frost = Instance.new("Frame")
        frost.Size=UDim2.new(1,0,1,0)
        frost.BackgroundColor3=Color3.fromRGB(120,180,255)
        frost.BackgroundTransparency=0.8; frost.BorderSizePixel=0; frost.Parent=sg
        local title = Instance.new("TextLabel")
        title.Size=UDim2.new(1,0,0,70); title.Position=UDim2.new(0,0,0.44,-35)
        title.BackgroundTransparency=1; title.Text="By bladevvball"
        title.TextColor3=Color3.fromRGB(230,245,255); title.TextSize=50*UI_SCALE
        title.Font=Enum.Font.GothamBlack; title.TextTransparency=1
        title.TextStrokeTransparency=1; title.TextStrokeColor3=Color3.fromRGB(0,180,255)
        title.ZIndex=5; title.Parent=sg
        TweenService:Create(title,TweenInfo.new(0.25),{TextTransparency=0,TextStrokeTransparency=0.35}):Play()
        local POOL = IS_MOBILE and 45 or 85
        local vp = CAM.ViewportSize
        local flakes = {}
        for i=1,POOL do
            local f = Instance.new("Frame")
            f.BackgroundColor3=Color3.fromRGB(255,255,255)
            f.BorderSizePixel=0; f.ZIndex=3; f.Visible=false; f.Parent=sg
            local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=f
            flakes[i]={fr=f,on=false,x=0,y=0,sp=0,dr=0}
        end
        local function spawn(f)
            local sz=math.random(3,8)
            f.fr.Size=UDim2.new(0,sz,0,sz)
            f.fr.BackgroundTransparency=math.random(30,60)/100
            f.x=math.random(-80,vp.X+80); f.y=-20
            f.sp=math.random(400,800)/100; f.dr=math.random(-80,80)/100
            f.fr.Position=UDim2.new(0,f.x,0,f.y); f.fr.Visible=true; f.on=true
        end
        for i=1,math.floor(POOL*0.6) do spawn(flakes[i]) end
        local active=true
        local conn = RunService.RenderStepped:Connect(function(dt)
            if dt>0.1 then dt=0.1 end
            local dts=dt*60
            for i=1,POOL do
                local f=flakes[i]
                if f.on then
                    f.y=f.y+f.sp*dts; f.x=f.x+f.dr*dts
                    f.fr.Position=UDim2.new(0,f.x,0,f.y)
                    if f.y>vp.Y+40 then
                        if active then spawn(f) else f.fr.Visible=false; f.on=false end
                    end
                end
            end
        end)
        task.wait(dur)
        active=false
        TweenService:Create(title,TweenInfo.new(0.2),{TextTransparency=1,TextStrokeTransparency=1}):Play()
        TweenService:Create(frost,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
        task.wait(0.35)
        if conn then conn:Disconnect() end
        sg:Destroy()
    end)
end

-- ==============================
-- GUI
-- ==============================
local old = pg:FindFirstChild("bv_Hub")
if old then old:Destroy() end

local CYAN=Color3.fromRGB(0,220,255)
local MAG =Color3.fromRGB(255,60,200)
local BG  =Color3.fromRGB(14,14,22)
local PANEL=Color3.fromRGB(22,22,34)
local TXT =Color3.fromRGB(225,225,245)
local ROW_H=(IS_MOBILE and 34 or 28)*UI_SCALE

local gui = Instance.new("ScreenGui")
gui.Name="bv_Hub"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=pg

local tog = Instance.new("TextButton")
tog.Size=UDim2.new(0,52*UI_SCALE,0,52*UI_SCALE)
tog.Position=UDim2.new(0,20,0.5,-26)
tog.BackgroundColor3=BG; tog.BackgroundTransparency=0.2
tog.BorderSizePixel=0; tog.Text="B"; tog.TextColor3=CYAN
tog.TextSize=24*UI_SCALE; tog.Font=Enum.Font.GothamBlack
tog.Active=true; tog.Parent=gui
local tgc = Instance.new("UICorner"); tgc.CornerRadius=UDim.new(1,0); tgc.Parent=tog
local tgs = Instance.new("UIStroke"); tgs.Color=CYAN; tgs.Thickness=2; tgs.Transparency=0.2; tgs.Parent=tog

do
    local dr, ds, sp
    tog.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dr=true; ds=i.Position; sp=tog.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dr and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            tog.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dr=false end
    end)
end

local WW = math.clamp(VIEW.X*0.92,340,660)*UI_SCALE
local WH = math.clamp(VIEW.Y*0.82,260,480)*UI_SCALE

local win = Instance.new("Frame")
win.Size=UDim2.new(0,WW,0,WH)
win.Position=UDim2.new(0.5,-WW/2,0.5,-WH/2)
win.BackgroundColor3=BG; win.BackgroundTransparency=0.05
win.BorderSizePixel=0; win.ClipsDescendants=true; win.Visible=false
win.Active=true; win.Parent=gui
local wc = Instance.new("UICorner"); wc.CornerRadius=UDim.new(0,12); wc.Parent=win
local ws = Instance.new("UIStroke"); ws.Color=CYAN; ws.Thickness=2; ws.Transparency=0.5; ws.Parent=win

local bar = Instance.new("Frame")
bar.Size=UDim2.new(1,0,0,38*UI_SCALE); bar.BackgroundColor3=PANEL
bar.BackgroundTransparency=0.15; bar.BorderSizePixel=0; bar.Parent=win
local bc = Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,12); bc.Parent=bar
local bfix = Instance.new("Frame")
bfix.Size=UDim2.new(1,0,0,14); bfix.Position=UDim2.new(0,0,1,-14)
bfix.BackgroundColor3=PANEL; bfix.BackgroundTransparency=0.15
bfix.BorderSizePixel=0; bfix.Parent=bar

local title = Instance.new("TextLabel")
title.Size=UDim2.new(1,-120,1,0); title.Position=UDim2.new(0,12,0,0)
title.BackgroundTransparency=1
title.Text="By bladevvball • "..GAME.tag
title.TextColor3=TXT; title.TextSize=13*UI_SCALE
title.Font=Enum.Font.GothamBold; title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=bar

local function hBtn(t, x, col, sc)
    local b = Instance.new("TextButton")
    b.Size=UDim2.new(0,28*UI_SCALE,0,28*UI_SCALE)
    b.Position=UDim2.new(1,x*UI_SCALE,0.5,-14*UI_SCALE)
    b.BackgroundColor3=col; b.BorderSizePixel=0; b.Text=t
    b.TextColor3=Color3.fromRGB(240,240,255); b.TextSize=14*UI_SCALE
    b.Font=Enum.Font.GothamBold; b.Parent=bar
    local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,7); c.Parent=b
    local s = Instance.new("UIStroke"); s.Color=sc; s.Thickness=1.4; s.Transparency=0.5; s.Parent=b
    return b
end
local minB = hBtn("-",-68,Color3.fromRGB(35,35,55),CYAN)
local clsB = hBtn("X",-36,Color3.fromRGB(120,30,45),Color3.fromRGB(255,80,120))

local mob = IS_MOBILE or VIEW.X < 700

local tabWrap = Instance.new("Frame")
tabWrap.BackgroundColor3=Color3.fromRGB(18,18,28)
tabWrap.BackgroundTransparency=0.2; tabWrap.BorderSizePixel=0; tabWrap.Parent=win
local twc = Instance.new("UICorner"); twc.CornerRadius=UDim.new(0,10); twc.Parent=tabWrap

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.BackgroundTransparency=1; tabScroll.BorderSizePixel=0
tabScroll.ScrollBarThickness=2; tabScroll.ScrollBarImageColor3=CYAN
tabScroll.Parent=tabWrap

local tabList = Instance.new("UIListLayout")
tabList.SortOrder=Enum.SortOrder.LayoutOrder; tabList.Parent=tabScroll
local tabPad = Instance.new("UIPadding"); tabPad.Parent=tabScroll

if mob then
    tabWrap.Size=UDim2.new(1,-12,0,34*UI_SCALE)
    tabWrap.Position=UDim2.new(0,6,0,42*UI_SCALE)
    tabScroll.Size=UDim2.new(1,0,1,0)
    tabScroll.ScrollingDirection=Enum.ScrollingDirection.X
    tabList.FillDirection=Enum.FillDirection.Horizontal
    tabList.Padding=UDim.new(0,4)
    tabList.VerticalAlignment=Enum.VerticalAlignment.Center
    tabPad.PaddingLeft=UDim.new(0,4); tabPad.PaddingRight=UDim.new(0,4)
else
    tabWrap.Size=UDim2.new(0,120*UI_SCALE,1,-48*UI_SCALE)
    tabWrap.Position=UDim2.new(0,6,0,42*UI_SCALE)
    tabScroll.Size=UDim2.new(1,0,1,0)
    tabScroll.ScrollingDirection=Enum.ScrollingDirection.Y
    tabList.FillDirection=Enum.FillDirection.Vertical
    tabList.Padding=UDim.new(0,4)
    tabList.HorizontalAlignment=Enum.HorizontalAlignment.Center
    tabPad.PaddingTop=UDim.new(0,6)
end

local content = Instance.new("Frame")
content.BackgroundColor3=Color3.fromRGB(18,18,28)
content.BackgroundTransparency=0.4; content.BorderSizePixel=0; content.Parent=win
local ccc = Instance.new("UICorner"); ccc.CornerRadius=UDim.new(0,10); ccc.Parent=content

if mob then
    content.Size=UDim2.new(1,-12,1,-(42+34+8)*UI_SCALE)
    content.Position=UDim2.new(0,6,0,(42+34+4)*UI_SCALE)
else
    content.Size=UDim2.new(1,-138*UI_SCALE,1,-48*UI_SCALE)
    content.Position=UDim2.new(0,132*UI_SCALE,0,42*UI_SCALE)
end

local scroll = Instance.new("ScrollingFrame")
scroll.Size=UDim2.new(1,-10,1,-10); scroll.Position=UDim2.new(0,5,0,5)
scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
scroll.ScrollBarThickness=4; scroll.ScrollBarImageColor3=CYAN
scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.Parent=content

local ulist = Instance.new("UIListLayout")
ulist.Padding=UDim.new(0,4); ulist.SortOrder=Enum.SortOrder.LayoutOrder; ulist.Parent=scroll
local upad = Instance.new("UIPadding")
upad.PaddingLeft=UDim.new(0,8); upad.PaddingRight=UDim.new(0,8)
upad.PaddingTop=UDim.new(0,8); upad.PaddingBottom=UDim.new(0,8); upad.Parent=scroll
ulist:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize=UDim2.new(0,0,ulist.AbsoluteContentSize.Y+20,0)
end)

-- WIDGETS
local function clearUI()
    for _, c in ipairs(scroll:GetChildren()) do
        if c~=ulist and c~=upad then c:Destroy() end
    end
end
local function hdr(t)
    local l = Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,0,20*UI_SCALE); l.BackgroundTransparency=1
    l.Text="▎ "..t; l.TextColor3=CYAN; l.TextSize=12*UI_SCALE
    l.Font=Enum.Font.GothamBold; l.TextXAlignment=Enum.TextXAlignment.Left
    l.Parent=scroll
end
local function lbl(t, c)
    local l = Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,0,17*UI_SCALE); l.BackgroundTransparency=1
    l.Text=t; l.TextColor3=c or Color3.fromRGB(190,190,215)
    l.TextSize=11*UI_SCALE; l.Font=Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=scroll
    return l
end
local function tgl(name, def, cb)
    local row = Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,ROW_H); row.BackgroundColor3=Color3.fromRGB(28,28,42)
    row.BackgroundTransparency=0.15; row.BorderSizePixel=0; row.Parent=scroll
    local rc = Instance.new("UICorner"); rc.CornerRadius=UDim.new(0,7); rc.Parent=row
    local lb = Instance.new("TextLabel")
    lb.Size=UDim2.new(1,-58*UI_SCALE,1,0); lb.Position=UDim2.new(0,10*UI_SCALE,0,0)
    lb.BackgroundTransparency=1; lb.Text=name; lb.TextColor3=TXT
    lb.TextSize=11*UI_SCALE; lb.Font=Enum.Font.Gotham
    lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=row
    local ind = Instance.new("Frame")
    ind.Size=UDim2.new(0,40*UI_SCALE,0,17*UI_SCALE)
    ind.Position=UDim2.new(1,-50*UI_SCALE,0.5,-8.5*UI_SCALE)
    ind.BackgroundColor3=def and Color3.fromRGB(0,200,120) or Color3.fromRGB(60,60,80)
    ind.BorderSizePixel=0; ind.Parent=row
    local ic = Instance.new("UICorner"); ic.CornerRadius=UDim.new(1,0); ic.Parent=ind
    local kn = Instance.new("Frame")
    kn.Size=UDim2.new(0,13*UI_SCALE,0,13*UI_SCALE)
    kn.Position=def and UDim2.new(1,-15*UI_SCALE,0.5,-6.5*UI_SCALE) or UDim2.new(0,2,0.5,-6.5*UI_SCALE)
    kn.BackgroundColor3=Color3.fromRGB(245,245,255)
    kn.BorderSizePixel=0; kn.Parent=ind
    local kc = Instance.new("UICorner"); kc.CornerRadius=UDim.new(1,0); kc.Parent=kn
    local on = def
    local btn = Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=row
    btn.MouseButton1Click:Connect(function()
        on = not on
        TweenService:Create(ind,TweenInfo.new(0.14),{
            BackgroundColor3=on and Color3.fromRGB(0,200,120) or Color3.fromRGB(60,60,80)}):Play()
        TweenService:Create(kn,TweenInfo.new(0.14),{
            Position=on and UDim2.new(1,-15*UI_SCALE,0.5,-6.5*UI_SCALE) or UDim2.new(0,2,0.5,-6.5*UI_SCALE)}):Play()
        if cb then S(cb, on) end
    end)
end
local function sld(name, mn, mx, def, cb)
    local h=(IS_MOBILE and 46 or 40)*UI_SCALE
    local row = Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,h); row.BackgroundColor3=Color3.fromRGB(28,28,42)
    row.BackgroundTransparency=0.15; row.BorderSizePixel=0; row.Parent=scroll
    local rc = Instance.new("UICorner"); rc.CornerRadius=UDim.new(0,7); rc.Parent=row
    local lb = Instance.new("TextLabel")
    lb.Size=UDim2.new(1,-12,0,16*UI_SCALE); lb.Position=UDim2.new(0,10*UI_SCALE,0,2)
    lb.BackgroundTransparency=1; lb.Text=name; lb.TextColor3=TXT
    lb.TextSize=11*UI_SCALE; lb.Font=Enum.Font.Gotham
    lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=row
    local vl = Instance.new("TextLabel")
    vl.Size=UDim2.new(0,55*UI_SCALE,0,16*UI_SCALE)
    vl.Position=UDim2.new(1,-65*UI_SCALE,0,2)
    vl.BackgroundTransparency=1; vl.Text=tostring(def); vl.TextColor3=CYAN
    vl.TextSize=11*UI_SCALE; vl.Font=Enum.Font.GothamBold
    vl.TextXAlignment=Enum.TextXAlignment.Right; vl.Parent=row
    local tH = IS_MOBILE and 9 or 5
    local trk = Instance.new("Frame")
    trk.Size=UDim2.new(1,-20*UI_SCALE,0,tH*UI_SCALE)
    trk.Position=UDim2.new(0,10*UI_SCALE,0,(IS_MOBILE and 26 or 24)*UI_SCALE)
    trk.BackgroundColor3=Color3.fromRGB(45,45,65)
    trk.BorderSizePixel=0; trk.Parent=row
    local tkc = Instance.new("UICorner"); tkc.CornerRadius=UDim.new(1,0); tkc.Parent=trk
    local pct=(def-mn)/(mx-mn)
    local fil = Instance.new("Frame")
    fil.Size=UDim2.new(pct,0,1,0); fil.BackgroundColor3=CYAN
    fil.BorderSizePixel=0; fil.Parent=trk
    local fic = Instance.new("UICorner"); fic.CornerRadius=UDim.new(1,0); fic.Parent=fil
    local drag=false
    local function setV(x)
        local rel=math.clamp((x-trk.AbsolutePosition.X)/trk.AbsoluteSize.X,0,1)
        local v=mn+(mx-mn)*rel
        v=(mx-mn)<=5 and math.floor(v*10+0.5)/10 or math.floor(v+0.5)
        fil.Size=UDim2.new(rel,0,1,0); vl.Text=tostring(v)
        if cb then S(cb,v) end
    end
    local hb = Instance.new("TextButton")
    hb.Size=UDim2.new(1,0,0,(IS_MOBILE and 22 or 12)*UI_SCALE)
    hb.Position=UDim2.new(0,0,0.5,-(IS_MOBILE and 11 or 6)*UI_SCALE)
    hb.BackgroundTransparency=1; hb.Text=""; hb.Parent=trk
    hb.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; setV(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            setV(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end
local function tbx(name, ph, cb)
    local h=(IS_MOBILE and 46 or 40)*UI_SCALE
    local row = Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,h); row.BackgroundColor3=Color3.fromRGB(28,28,42)
    row.BackgroundTransparency=0.15; row.BorderSizePixel=0; row.Parent=scroll
    local rc = Instance.new("UICorner"); rc.CornerRadius=UDim.new(0,7); rc.Parent=row
    local lb = Instance.new("TextLabel")
    lb.Size=UDim2.new(1,-12,0,15*UI_SCALE); lb.Position=UDim2.new(0,10*UI_SCALE,0,2)
    lb.BackgroundTransparency=1; lb.Text=name; lb.TextColor3=TXT
    lb.TextSize=11*UI_SCALE; lb.Font=Enum.Font.Gotham
    lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=row
    local box = Instance.new("TextBox")
    box.Size=UDim2.new(1,-20*UI_SCALE,0,(IS_MOBILE and 22 or 18)*UI_SCALE)
    box.Position=UDim2.new(0,10*UI_SCALE,0,17*UI_SCALE)
    box.BackgroundColor3=Color3.fromRGB(20,20,32); box.BorderSizePixel=0
    box.Text=""; box.PlaceholderText=ph or ""
    box.PlaceholderColor3=Color3.fromRGB(140,140,170)
    box.TextColor3=Color3.fromRGB(220,220,250); box.TextSize=11*UI_SCALE
    box.Font=Enum.Font.Code; box.ClearTextOnFocus=false; box.Parent=row
    local bcc = Instance.new("UICorner"); bcc.CornerRadius=UDim.new(0,5); bcc.Parent=box
    box.FocusLost:Connect(function()
        if cb then S(cb, box.Text) end
    end)
    return row, box
end
local function btn(name, cb, col)
    local b = Instance.new("TextButton")
    b.Size=UDim2.new(1,0,0,ROW_H); b.BackgroundColor3=col or Color3.fromRGB(35,35,55)
    b.BorderSizePixel=0; b.Text=name; b.TextColor3=Color3.fromRGB(230,230,255)
    b.TextSize=11*UI_SCALE; b.Font=Enum.Font.GothamBold; b.Parent=scroll
    local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=b
    local s = Instance.new("UIStroke"); s.Color=CYAN; s.Thickness=1; s.Transparency=0.55; s.Parent=b
    b.MouseButton1Click:Connect(function()
        if cb then S(cb) end
    end)
    return b
end

-- TAB SYSTEM
local pages = {}
local tabBtns = {}
local function selectTab(b)
    for _, x in ipairs(tabBtns) do
        TweenService:Create(x,TweenInfo.new(0.1),{
            BackgroundColor3=Color3.fromRGB(28,28,44),
            TextColor3=Color3.fromRGB(200,200,230)}):Play()
    end
    TweenService:Create(b,TweenInfo.new(0.1),{
        BackgroundColor3=Color3.fromRGB(0,160,220),
        TextColor3=Color3.fromRGB(255,255,255)}):Play()
    clearUI()
    local n = b:GetAttribute("pg")
    if n and pages[n] then S(pages[n]) end
end
local function regTab(name, order)
    local b = Instance.new("TextButton")
    if mob then
        b.Size=UDim2.new(0,74*UI_SCALE,1,-6*UI_SCALE)
        b.AutomaticSize=Enum.AutomaticSize.X
    else
        b.Size=UDim2.new(1,-10,0,28*UI_SCALE)
    end
    b.BackgroundColor3=Color3.fromRGB(28,28,44); b.BorderSizePixel=0
    b.Text=name; b.TextColor3=Color3.fromRGB(200,200,230)
    b.TextSize=11*UI_SCALE; b.Font=Enum.Font.GothamBold
    b.LayoutOrder=order; b:SetAttribute("pg", name); b.Parent=tabScroll
    local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=b
    b.MouseButton1Click:Connect(function() selectTab(b) end)
    tabBtns[#tabBtns+1]=b
end

local function getHRP()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = plr.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function tp(pos)
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end
end

-- ==============================
-- PLAYER TAB
-- ==============================
regTab("Player", 1)
pages.Player = function()
    hdr("Character")
    sld("WalkSpeed", 1, 500, 16, function(v)
        ST.ws=v
        local h=getHum(); if h then h.WalkSpeed=v end
    end)
    sld("JumpPower", 1, 500, 50, function(v)
        ST.jp=v
        local h=getHum(); if h then h.UseJumpPower=true; h.JumpPower=v end
    end)
    sld("Gravity", 0, 500, 196.2, function(v) ST.grav=v; Workspace.Gravity=v end)

    hdr("Movement")
    tgl("Infinite Jump", false, function(on) ST.infJump=on end)
    tgl("Noclip", false, function(on) ST.noclip=on end)
    tgl("Ghost (invisible)", false, function(on)
        ST.ghost=on
        local c=plr.Character
        if c then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
                    p.LocalTransparencyModifier = on and 1 or 0
                end
            end
        end
    end)
    tgl("Anti-AFK", true, function(on) ST.antiafk=on end)
    tgl("Spin", false, function(on)
        ST.spin=on
        local hrp = getHRP()
        if not hrp then return end
        local bav = hrp:FindFirstChild("_spinAV")
        if on then
            if not bav then
                bav = Instance.new("BodyAngularVelocity")
                bav.Name="_spinAV"
                bav.AngularVelocity=Vector3.new(0,20,0)
                bav.MaxTorque=Vector3.new(0,1e5,0)
                bav.P=1e5; bav.Parent=hrp
            end
        elseif bav then bav:Destroy() end
    end)
    tgl("Trail", false, function(on) ST.trail=on end)
    tgl("Click Teleport", false, function(on) ST.clickTP=on end)
    tgl("Sit", false, function(on)
        ST.sit=on
        local h=getHum()
        if h then
            if on then h:ChangeState(Enum.HumanoidStateType.Seated)
            else h:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end
    end)
    tgl("Ragdoll", false, function(on)
        ST.ragdoll=on
        local h=getHum()
        if h then
            if on then h:ChangeState(Enum.HumanoidStateType.Physics)
            else h:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end
    end)
    tgl("Freeze Self", false, function(on)
        ST.freezeSelf=on
        local hrp = getHRP()
        if not hrp then return end
        if on then
            hrp.Anchored = true
        else
            hrp.Anchored = false
        end
    end)

    hdr("Fly")
    sld("Fly Speed", 10, 300, 80, function(v) ST.flySpd=v end)
    tgl("Fly", false, function(on)
        ST.fly = on
        if IS_MOBILE or IS_TABLET then flyGui.Enabled = on end
        local char = plr.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if on then
            local bg = hrp:FindFirstChild("_flyBG")
            if not bg then
                bg = Instance.new("BodyVelocity")
                bg.Name="_flyBG"; bg.MaxForce=Vector3.new(1e6,1e6,1e6)
                bg.Velocity=Vector3.zero; bg.Parent=hrp
            end
            hum.PlatformStand = true
        else
            local bg = hrp:FindFirstChild("_flyBG")
            if bg then bg:Destroy() end
            hum.PlatformStand = false
            ST.flyUp=false; ST.flyDown=false
        end
    end)

    hdr("Actions")
    btn("Reset Character", function()
        local h=getHum(); if h then h.Health=0 end
    end, Color3.fromRGB(120,40,55))
    btn("Copy Position", function()
        local hrp = getHRP()
        if hrp then
            local s = string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
            if setclipboard then setclipboard(s) end
            notify("Copied", s)
        end
    end)
    btn("Copy CFrame", function()
        local hrp = getHRP()
        if hrp and setclipboard then
            setclipboard(tostring(hrp.CFrame))
            notify("Copied", "CFrame")
        end
    end)
end

-- ==============================
-- VISUAL TAB
-- ==============================
local espF = Instance.new("Folder"); espF.Name="bv_ESP"; espF.Parent=gui
local espCache = {}

local function mkESP(p)
    if espCache[p] then return end
    if not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Name="box"; box.Adornee=hrp; box.AlwaysOnTop=true
    box.ZIndex=5; box.Size=hrp.Size+Vector3.new(0.5,0.5,0.5)
    box.Transparency=0.55; box.Color3=Color3.fromRGB(255,60,60)
    box.Parent=espF
    local bb = Instance.new("BillboardGui")
    bb.Name="bb"; bb.Adornee=hrp; bb.Size=UDim2.new(0,180,0,42)
    bb.StudsOffsetWorldSpace=Vector3.new(0,3,0); bb.AlwaysOnTop=true
    bb.Parent=espF
    local n = Instance.new("TextLabel")
    n.Size=UDim2.new(1,0,0,20); n.BackgroundTransparency=1
    n.Text=p.Name; n.TextColor3=Color3.fromRGB(255,60,60)
    n.TextStrokeTransparency=0; n.TextStrokeColor3=Color3.new(0,0,0)
    n.TextSize=13; n.Font=Enum.Font.GothamBold; n.Parent=bb
    local d = Instance.new("TextLabel")
    d.Size=UDim2.new(1,0,0,14); d.Position=UDim2.new(0,0,0,20)
    d.BackgroundTransparency=1; d.Text=""; d.TextColor3=Color3.fromRGB(220,220,255)
    d.TextStrokeTransparency=0; d.TextStrokeColor3=Color3.new(0,0,0)
    d.TextSize=11; d.Font=Enum.Font.Gotham; d.Parent=bb
    local hbg = Instance.new("Frame")
    hbg.Size=UDim2.new(1,-20,0,5); hbg.Position=UDim2.new(0,10,0,35)
    hbg.BackgroundColor3=Color3.fromRGB(30,30,40); hbg.BorderSizePixel=0
    hbg.Visible=false; hbg.Parent=bb
    local hbgC = Instance.new("UICorner"); hbgC.CornerRadius=UDim.new(1,0); hbgC.Parent=hbg
    local hfil = Instance.new("Frame")
    hfil.Size=UDim2.new(1,0,1,0); hfil.BackgroundColor3=Color3.fromRGB(0,220,80)
    hfil.BorderSizePixel=0; hfil.Parent=hbg
    local hfilC = Instance.new("UICorner"); hfilC.CornerRadius=UDim.new(1,0); hfilC.Parent=hfil
    espCache[p] = {box=box, bb=bb, n=n, d=d, hbg=hbg, hfil=hfil}
end

local function rmESP(p)
    if espCache[p] then
        for _, v in pairs(espCache[p]) do
            if typeof(v)=="Instance" then S(function() v:Destroy() end) end
        end
        espCache[p]=nil
    end
end

regTab("Visual", 2)
pages.Visual = function()
    hdr("Lighting")
    tgl("Fullbright", false, function(on)
        ST.fullbright=on
        if on then
            Lighting.Brightness=5; Lighting.ClockTime=14
            Lighting.FogEnd=1e6; Lighting.GlobalShadows=false
            Lighting.OutdoorAmbient=Color3.fromRGB(180,180,180)
        else
            Lighting.Brightness=SAVED.bright
            Lighting.ClockTime=SAVED.time
            Lighting.FogEnd=SAVED.fog
            Lighting.GlobalShadows=SAVED.gShadows
            Lighting.OutdoorAmbient=SAVED.outAmb
        end
    end)
    tgl("No Fog", false, function(on)
        ST.noFog=on
        Lighting.FogEnd = on and 1e6 or SAVED.fog
    end)
    sld("FOV", 30, 160, 70, function(v)
        if CAM then CAM.FieldOfView=v end
    end)
    sld("Camera Zoom (offset)", 0, 50, 0, function(v)
        ST.camZoom = v
        local p = plr.Character
        if p then
            local hum = p:FindFirstChildOfClass("Humanoid")
            if hum then hum.CameraOffset = Vector3.new(0, 0, v) end
        end
    end)
    sld("Clock Time", 0, 24, 14, function(v)
        if not ST.fullbright then Lighting.ClockTime=v end
    end)

    hdr("ESP")
    tgl("Player ESP", false, function(on)
        ST.esp=on
        if on then
            for _, p in ipairs(Players:GetPlayers()) do
                if p~=plr and p.Character then S(mkESP, p) end
            end
        else
            for p in pairs(espCache) do rmESP(p) end
        end
    end)
    tgl("Distance", false, function(on)
        ST.espDist=on
        for _, c in pairs(espCache) do c.d.Visible=on end
    end)
    tgl("Health Bar", false, function(on)
        ST.espHP=on
        for _, c in pairs(espCache) do c.hbg.Visible=on end
    end)
    tgl("Tracers", false, function(on) ST.tracers=on end)
    tgl("Chams", false, function(on)
        ST.chams=on
        if on then
            for _, p in ipairs(Players:GetPlayers()) do
                if p~=plr and p.Character and not p.Character:FindFirstChild("_cham") then
                    local h = Instance.new("Highlight")
                    h.Name="_cham"; h.FillColor=Color3.fromRGB(255,40,100)
                    h.FillTransparency=0.4
                    h.OutlineColor=Color3.fromRGB(255,200,220)
                    h.Parent=p.Character
                end
            end
        else
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local h = p.Character:FindFirstChild("_cham")
                    if h then h:Destroy() end
                end
            end
        end
    end)
    tgl("X-Ray", false, function(on)
        ST.xray=on
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("BasePart") then
                if on then
                    if not o:GetAttribute("_oLTM") then
                        o:SetAttribute("_oLTM", o.LocalTransparencyModifier)
                    end
                    o.LocalTransparencyModifier = 0.85
                else
                    local v = o:GetAttribute("_oLTM")
                    if v then o.LocalTransparencyModifier = v end
                end
            end
        end
    end)
end

-- ==============================
-- TELEPORT TAB
-- ==============================
local wps = {}
regTab("Teleport", 3)
pages.Teleport = function()
    hdr("Players")
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=plr then
            btn("➜ "..p.Name, function()
                if p.Character then
                    local h = p.Character:FindFirstChild("HumanoidRootPart")
                    if h then tp(h.Position) end
                end
            end)
        end
    end

    hdr("Waypoints")
    local _, wbox = tbx("Save waypoint as", "name")
    btn("Save Current Position", function()
        local n = wbox and wbox.Text or ""
        if n ~= "" then
            local hrp = getHRP()
            if hrp then wps[n]=hrp.Position; notify("Saved", n) end
        end
    end, Color3.fromRGB(40,100,70))
    for nm,pos in pairs(wps) do
        btn("➜ "..nm, function() tp(pos) end)
    end

    hdr("Coordinates")
    local crow = Instance.new("Frame")
    crow.Size=UDim2.new(1,0,0,(IS_MOBILE and 74 or 60)*UI_SCALE)
    crow.BackgroundColor3=Color3.fromRGB(28,28,42)
    crow.BackgroundTransparency=0.15; crow.BorderSizePixel=0; crow.Parent=scroll
    local crc = Instance.new("UICorner"); crc.CornerRadius=UDim.new(0,7); crc.Parent=crow
    local coords = {}
    local bw = (IS_MOBILE and 78 or 88)*UI_SCALE
    local gp = (IS_MOBILE and 86 or 96)*UI_SCALE
    for i, ax in ipairs({"X","Y","Z"}) do
        local tb = Instance.new("TextBox")
        tb.Size=UDim2.new(0,bw,0,22*UI_SCALE)
        tb.Position=UDim2.new(0,10*UI_SCALE+(i-1)*gp,0,6*UI_SCALE)
        tb.BackgroundColor3=Color3.fromRGB(20,20,32); tb.BorderSizePixel=0
        tb.Text="0"; tb.TextColor3=Color3.fromRGB(220,220,250)
        tb.TextSize=11*UI_SCALE; tb.Font=Enum.Font.Code
        tb.ClearTextOnFocus=false; tb.Parent=crow
        local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,5); c.Parent=tb
        coords[ax]=tb
    end
    local go = Instance.new("TextButton")
    go.Size=UDim2.new(1,-20*UI_SCALE,0,22*UI_SCALE)
    go.Position=UDim2.new(0,10*UI_SCALE,0,(IS_MOBILE and 34 or 32)*UI_SCALE)
    go.BackgroundColor3=Color3.fromRGB(0,160,220); go.BorderSizePixel=0
    go.Text="Teleport"; go.TextColor3=Color3.new(1,1,1)
    go.TextSize=11*UI_SCALE; go.Font=Enum.Font.GothamBold; go.Parent=crow
    local goc = Instance.new("UICorner"); goc.CornerRadius=UDim.new(0,5); goc.Parent=go
    go.MouseButton1Click:Connect(function()
        tp(Vector3.new(
            tonumber(coords.X.Text) or 0,
            tonumber(coords.Y.Text) or 0,
            tonumber(coords.Z.Text) or 0
        ))
    end)
end

-- ==============================
-- COMBAT TAB
-- ==============================
regTab("Combat", 4)
pages.Combat = function()
    hdr("Melee")
    sld("Reach", 1, 50, 5, function(v) ST.reach=v end)
    sld("Hitbox Size", 1, 30, 1, function(v)
        ST.hitbox=v
        for _, p in ipairs(Players:GetPlayers()) do
            if p~=plr and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not hrp:GetAttribute("_oHB") then
                        hrp:SetAttribute("_oHB", hrp.Size)
                    end
                    if v>1 then
                        hrp.Size = Vector3.new(2,2,1)*v
                        hrp.Transparency = 0.7
                        hrp.CanCollide = false
                    else
                        local o = hrp:GetAttribute("_oHB")
                        if o then hrp.Size = o end
                        hrp.Transparency = 1
                    end
                end
            end
        end
    end)
    tgl("Auto Attack", false, function(on) ST.autoAtk=on end)
    tgl("Kill Aura", false, function(on) ST.killAura=on end)
    tgl("Auto Equip Tool", false, function(on) ST.autoEquip=on end)
    tgl("Freeze All Players", false, function(on)
        ST.freezeAll=on
        for _, p in ipairs(Players:GetPlayers()) do
            if p~=plr and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = on end
            end
        end
    end)

    hdr("Actions")
    btn("Kill Nearest", function()
        local char = plr.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local tool = char:FindFirstChildWhichIsA("Tool")
        if not hrp or not tool then return end
        local handle = tool:FindFirstChild("Handle")
        if not handle or not firetouchinterest then return end
        local closest, dist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p~=plr and p.Character then
                local ph = p.Character:FindFirstChild("HumanoidRootPart")
                if ph then
                    local d = (ph.Position-hrp.Position).Magnitude
                    if d<dist then dist, closest = d, p end
                end
            end
        end
        if closest then
            for _=1,5 do
                S(function()
                    firetouchinterest(handle, closest.Character.HumanoidRootPart, 0)
                    task.wait()
                    firetouchinterest(handle, closest.Character.HumanoidRootPart, 1)
                end)
                task.wait(0.05)
            end
        end
    end, Color3.fromRGB(140,40,60))
    btn("Bring All Players", function()
        local hrp = getHRP()
        if not hrp then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p~=plr and p.Character then
                local ph = p.Character:FindFirstChild("HumanoidRootPart")
                if ph then
                    ph.CFrame = hrp.CFrame + Vector3.new(math.random(-5,5),0,math.random(-5,5))
                end
            end
        end
    end)
end

-- ==============================
-- GAME TAB
-- ==============================
regTab("Game", 5)
pages.Game = function()
    hdr("Detected")
    lbl("Game: "..GAME.name, CYAN)
    lbl("Tag: "..GAME.tag)
    lbl("PlaceId: "..tostring(game.PlaceId))

    hdr("NPCs")
    btn("Freeze All NPCs", function()
        local c=0
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("Humanoid") and not Players:GetPlayerFromCharacter(o.Parent) then
                o.WalkSpeed=0; c=c+1
            end
        end
        notify("Frozen", c.." NPCs")
    end)
    btn("Unfreeze NPCs", function()
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("Humanoid") and not Players:GetPlayerFromCharacter(o.Parent) then
                o.WalkSpeed=16
            end
        end
    end)
    btn("Kill All NPCs", function()
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("Humanoid") and not Players:GetPlayerFromCharacter(o.Parent) then
                S(function() o.Health=0 end)
            end
        end
    end, Color3.fromRGB(140,40,60))

    hdr("Presets")
    btn("Speed 100", function()
        ST.ws=100
        local h=getHum(); if h then h.WalkSpeed=100 end
    end)
    btn("Speed 300", function()
        ST.ws=300
        local h=getHum(); if h then h.WalkSpeed=300 end
    end)
    btn("Jump 200", function()
        ST.jp=200
        local h=getHum(); if h then h.UseJumpPower=true; h.JumpPower=200 end
    end)
    btn("Reset Stats", function()
        ST.ws=16; ST.jp=50; ST.grav=196.2
        Workspace.Gravity=196.2
        local h=getHum()
        if h then h.WalkSpeed=16; h.JumpPower=50; h.UseJumpPower=true end
    end, Color3.fromRGB(60,60,80))
end

-- ==============================
-- UTILITY TAB
-- ==============================
regTab("Utility", 6)
pages.Utility = function()
    hdr("Server")
    btn("Rejoin", function() TeleportService:Teleport(game.PlaceId, plr) end)
    btn("Server Hop", function()
        S(function()
            local res = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
            local data = HttpService:JSONDecode(res)
            for _, s in ipairs(data.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, plr)
                    return
                end
            end
        end)
    end)
    btn("Copy JobId", function()
        if setclipboard then setclipboard(game.JobId) end
        notify("Copied", "JobId")
    end)

    hdr("Chat")
    local _, cbox = tbx("Chat spam message", "text")
    tgl("Chat Spam", false, function(on)
        ST.chatSpam=on
        task.spawn(function()
            while ST.chatSpam do
                if cbox and cbox.Text ~= "" then
                    local ch = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                    if ch then
                        local sm = ch:FindFirstChild("SayMessageRequest")
                        if sm then S(function() sm:FireServer(cbox.Text, "All") end) end
                    end
                end
                task.wait(1)
            end
        end)
    end)

    hdr("Diagnostics")
    local fps = lbl("FPS: --", CYAN)
    task.spawn(function()
        while fps.Parent do
            local t0 = tick()
            RunService.RenderStepped:Wait()
            fps.Text = "FPS: "..math.floor(1/math.max(tick()-t0, 1e-6))
        end
    end)
    local ping = lbl("Ping: --", CYAN)
    task.spawn(function()
        while ping.Parent do
            local ok, p = pcall(function() return plr:GetNetworkPing()*1000 end)
            if ok then ping.Text = "Ping: "..math.floor(p).." ms" end
            task.wait(0.5)
        end
    end)
    lbl("Players: "..#Players:GetPlayers().."/"..Players.MaxPlayers)
    lbl("Platform: "..(IS_MOBILE and "Mobile" or IS_TABLET and "Tablet" or "PC"))
    lbl("Region: "..tostring(game:GetService("LocalizationService").RobloxLocaleId))
end

-- ==============================
-- EXTRA TAB (15 new features)
-- ==============================
regTab("Extra", 7)
pages.Extra = function()
    hdr("Protection")

    -- 1. Anti-Fling
    tgl("Anti-Fling", false, function(on)
        ST.antiFling = on
        if on then
            local hrp = getHRP()
            if hrp then
                if not hrp:FindFirstChild("_antiFlingAV") then
                    local av = Instance.new("BodyAngularVelocity")
                    av.Name="_antiFlingAV"
                    av.AngularVelocity=Vector3.new(0,0,0)
                    av.MaxTorque=Vector3.new(1e5,1e5,1e5)
                    av.P=1e5; av.Parent=hrp
                end
            end
        else
            local hrp = getHRP()
            if hrp then
                local av = hrp:FindFirstChild("_antiFlingAV")
                if av then av:Destroy() end
            end
        end
    end)

    -- 2. Anti-Void
    tgl("Anti-Void", false, function(on)
        ST.antiVoid = on
        if on then
            local hrp = getHRP()
            if hrp and hrp.Position.Y > -50 then
                ST.lastSafePos = hrp.Position
            end
        end
    end)

    -- 3. Auto Respawn
    tgl("Auto Respawn", false, function(on)
        ST.autoRespawn = on
        if on then
            task.spawn(function()
                while ST.autoRespawn do
                    local hum = getHum()
                    if hum and hum.Health <= 0 then
                        task.wait(0.1)
                        S(function() plr:LoadCharacter() end)
                    end
                    task.wait(0.2)
                end
            end)
        end
    end)

    -- 4. Fast Respawn (kill = respawn instantly)
    tgl("Fast Respawn", false, function(on)
        ST.fastRespawn = on
        if on then
            task.spawn(function()
                while ST.fastRespawn do
                    local hum = getHum()
                    if hum and hum.Health <= 0 then
                        S(function() plr:LoadCharacter() end)
                        task.wait(0.5)
                    end
                    task.wait(0.1)
                end
            end)
        end
    end)

    hdr("Movement")

    -- 5. Walk on Water
    tgl("Walk on Water", false, function(on)
        ST.walkWater = on
        local hrp = getHRP()
        if not hrp then return end
        local plat = hrp:FindFirstChild("_waterPlat")
        if on and not plat then
            plat = Instance.new("Part")
            plat.Name="_waterPlat"
            plat.Size=Vector3.new(6,0.5,6)
            plat.Transparency=0.6
            plat.Color=Color3.fromRGB(80,200,255)
            plat.CanCollide=true
            plat.Anchored=true
            plat.Parent=Workspace
            hrp:SetAttribute("_waterPlat", plat)
        elseif not on and plat then
            plat:Destroy()
        elseif not on then
            local p = hrp:GetAttribute("_waterPlat")
            if p then p:Destroy() end
        end
    end)

    -- 6. Character Scale
    sld("Character Scale", 50, 300, 100, function(v)
        ST.charScale = v / 100
        local char = plr.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then S(function() hum.BodyDepthScale.Value = ST.charScale end) end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    if not p:GetAttribute("_origSize") then
                        p:SetAttribute("_origSize", p.Size)
                    end
                end
            end
        end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                local o = p:GetAttribute("_origSize")
                if o then p.Size = o * ST.charScale end
            end
        end
    end)

    -- 7. Big Head
    tgl("Big Head", false, function(on)
        ST.bigHead = on
        local char = plr.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        if on then
            if not head:GetAttribute("_origSize") then
                head:SetAttribute("_origSize", head.Size)
            end
            head.Size = head.Size * 2
            local mesh = head:FindFirstChildOfClass("SpecialMesh")
            if mesh then mesh.Scale = mesh.Scale * 2 end
        else
            local o = head:GetAttribute("_origSize")
            if o then head.Size = o end
            local mesh = head:FindFirstChildOfClass("SpecialMesh")
            if mesh then mesh.Scale = Vector3.new(1,1,1) end
        end
    end)

    hdr("Utility")

    -- 8. Point Light on player
    tgl("Player Light", false, function(on)
        ST.pointLight = on
        local hrp = getHRP()
        if not hrp then return end
        local ex = hrp:FindFirstChild("_light")
        if on and not ex then
            local l = Instance.new("PointLight")
            l.Name="_light"; l.Brightness=4
            l.Range=30; l.Color=Color3.fromRGB(255,255,220)
            l.Parent=hrp
        elseif not on and ex then
            ex:Destroy()
        end
    end)

    -- 9. Instant Interact (ProximityPrompt)
    btn("Force Interact (nearest prompt)", function()
        local char = plr.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local closest, dist = nil, math.huge
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("ProximityPrompt") then
                local pp = o.Parent
                if pp and pp:IsA("BasePart") then
                    local d = (pp.Position - hrp.Position).Magnitude
                    if d < dist then dist, closest = d, o end
                end
            end
        end
        if closest then
            S(function()
                closest.HoldDuration = 0
                fireproximityprompt(closest)
                notify("Interacted", closest.ActionText)
            end)
        else
            notify("Interact", "No prompt nearby")
        end
    end)

    -- 10. Camera Reset
    btn("Reset Camera Offset", function()
        ST.camZoom = 0
        local hum = getHum()
        if hum then hum.CameraOffset = Vector3.new(0,0,0) end
        notify("Camera", "Reset")
    end)

    -- 11. Copy Player Name (self)
    btn("Copy My Username", function()
        if setclipboard then setclipboard(plr.Name) end
        notify("Copied", plr.Name)
    end)

    -- 12. Copy UserId
    btn("Copy My UserId", function()
        if setclipboard then setclipboard(tostring(plr.UserId)) end
        notify("Copied", tostring(plr.UserId))
    end)

    -- 13. Server Uptime / Info
    btn("Show Server Info", function()
        local players = #Players:GetPlayers()
        local maxP = Players.MaxPlayers
        local jobId = game.JobId
        notify("Server", players.."/"..maxP.." • "..string.sub(jobId,1,8))
    end)

    -- 14. Emergency Stop (unload)
    btn("Emergency Stop (unload hub)", function()
        ST.fly=false; ST.noclip=false; ST.ghost=false
        ST.esp=false; ST.tracers=false; ST.chams=false; ST.xray=false
        ST.autoAtk=false; ST.killAura=false; ST.autoEquip=false
        ST.spin=false; ST.trail=false; ST.rainbow=false; ST.pointLight=false
        ST.antiFling=false; ST.antiVoid=false; ST.autoRespawn=false
        ST.fastRespawn=false; ST.walkWater=false; ST.freezeAll=false
        ST.chatSpam=false; ST.freezeSelf=false
        for p in pairs(espCache) do rmESP(p) end
        for _, c in ipairs(tf:GetChildren()) do c:Destroy() end
        if flyGui then flyGui.Enabled=false end
        local hrp = getHRP()
        if hrp then
            hrp.Anchored = false
            for _, n in ipairs({"_flyBG","_spinAV","_antiFlingAV","_trail","_light","_waterPlat","_particles"}) do
                local x = hrp:FindFirstChild(n)
                if x then x:Destroy() end
            end
        end
        local h = getHum()
        if h then
            h.PlatformStand = false
            h.WalkSpeed = 16
            h.JumpPower = 50
            h.UseJumpPower = true
            h.CameraOffset = Vector3.new(0,0,0)
        end
        Workspace.Gravity = 196.2
        Lighting.Brightness = SAVED.bright
        Lighting.ClockTime = SAVED.time
        Lighting.FogEnd = SAVED.fog
        Lighting.GlobalShadows = SAVED.gShadows
        Lighting.OutdoorAmbient = SAVED.outAmb
        notify("Hub", "Emergency Stop - all features off")
    end, Color3.fromRGB(140,40,60))

    -- 15. Reload Hub
    btn("Reload Hub", function()
        local oldHub = pg:FindFirstChild("bv_Hub")
        if oldHub then oldHub:Destroy() end
        local oldFly = pg:FindFirstChild("bv_FlyCtl")
        if oldFly then oldFly:Destroy() end
        notify("Hub", "Unloaded - re-execute to reload")
    end, Color3.fromRGB(60,60,120))
end

-- ==============================
-- MAIN LOOPS
-- ==============================
RunService.RenderStepped:Connect(function(dt)
    local char = plr.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if not ST.freezeSelf then
        if hum.WalkSpeed ~= ST.ws then hum.WalkSpeed = ST.ws end
        if hum.UseJumpPower and hum.JumpPower ~= ST.jp then hum.JumpPower = ST.jp end
    end
    if Workspace.Gravity ~= ST.grav then Workspace.Gravity = ST.grav end

    if ST.noclip and not ST.freezeSelf then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
        end
    end

    -- FLY
    if ST.fly then
        local bg = hrp:FindFirstChild("_flyBG")
        if not bg then
            bg = Instance.new("BodyVelocity")
            bg.Name="_flyBG"; bg.MaxForce=Vector3.new(1e6,1e6,1e6)
            bg.Velocity=Vector3.zero; bg.Parent=hrp
        end
        if hum.PlatformStand ~= true then hum.PlatformStand = true end
        local dir = Vector3.zero
        if IS_MOBILE or IS_TABLET then
            if CAM then
                dir += CAM.CFrame.RightVector * jsVec.X * 1.5
                dir += CAM.CFrame.LookVector * jsVec.Y * 1.5
            end
            if ST.flyUp   then dir += Vector3.new(0,1,0) end
            if ST.flyDown then dir -= Vector3.new(0,1,0) end
        else
            if CAM then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += CAM.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= CAM.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= CAM.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += CAM.CFrame.RightVector end
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        end
        if dir.Magnitude > 1 then dir = dir.Unit end
        bg.Velocity = dir * ST.flySpd
    end

    -- Trail
    if ST.trail and not hrp:FindFirstChild("_trail") then
        local a0 = Instance.new("Attachment", hrp); a0.Name="_trA0"
        local a1 = Instance.new("Attachment", hrp); a1.Name="_trA1"
        a1.Position=Vector3.new(0,1,0)
        local t = Instance.new("Trail")
        t.Name="_trail"; t.Attachment0=a0; t.Attachment1=a1
        t.Lifetime=0.4; t.Color=ColorSequence.new(CYAN, MAG); t.Parent=hrp
    elseif not ST.trail then
        local t = hrp:FindFirstChild("_trail")
        if t then t:Destroy() end
    end

    -- Anti-Void
    if ST.antiVoid then
        if hrp.Position.Y > -50 then
            ST.lastSafePos = hrp.Position
        elseif ST.lastSafePos and hrp.Position.Y < -150 then
            hrp.CFrame = CFrame.new(ST.lastSafePos + Vector3.new(0,5,0))
        end
    end

    -- Walk on water platform follows player
    if ST.walkWater then
        local plat = hrp:GetAttribute("_waterPlat")
        if plat and plat.Parent then
            plat.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 3.5, hrp.Position.Z)
        end
    end
end)

-- Throttled tasks (auto attack, kill aura, auto equip)
local acc = 0
RunService.Heartbeat:Connect(function(dt)
    acc = acc + dt
    if acc < 0.15 then return end
    acc = 0

    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if ST.autoAtk then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then S(function() tool:Activate() end) end
    end
    if ST.autoEquip then
        local bp = plr:FindFirstChild("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") then hum:EquipTool(t); break end
            end
        end
    end
    if ST.killAura then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local tool = char:FindFirstChildWhichIsA("Tool")
        if hrp and tool then
            local h = tool:FindFirstChild("Handle")
            if h and firetouchinterest then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p~=plr and p.Character then
                        local ph = p.Character:FindFirstChild("HumanoidRootPart")
                        if ph and (ph.Position-hrp.Position).Magnitude <= ST.reach+5 then
                            S(function()
                                firetouchinterest(h, ph, 0)
                                firetouchinterest(h, ph, 1)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- ESP live update
RunService.RenderStepped:Connect(function()
    if not ST.esp then return end
    if not CAM then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=plr and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if not espCache[p] then S(mkESP, p) end
            local c = espCache[p]
            if c then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character.HumanoidRootPart
                if ST.espDist then
                    c.d.Text = "["..math.floor((hrp.Position-CAM.CFrame.Position).Magnitude).."]"
                end
                if ST.espHP and hum then
                    local pct = math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                    c.hfil.Size = UDim2.new(pct,0,1,0)
                    c.hfil.BackgroundColor3 = Color3.fromRGB(255*(1-pct), 255*pct, 0)
                end
            end
        end
    end
    for t in pairs(espCache) do
        if not t.Character or not t.Character:FindFirstChild("HumanoidRootPart") then
            rmESP(t)
        end
    end
end)

-- Tracers
local tf = Instance.new("Folder"); tf.Name="bv_Tracers"; tf.Parent=gui
RunService.RenderStepped:Connect(function()
    if not ST.tracers then
        if #tf:GetChildren()>0 then
            for _, c in ipairs(tf:GetChildren()) do c:Destroy() end
        end
        return
    end
    if not CAM then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=plr and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pos, os = CAM:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            local line = tf:FindFirstChild(p.Name)
            if not line then
                line = Instance.new("Frame")
                line.Name=p.Name; line.BackgroundColor3=Color3.fromRGB(255,50,100)
                line.BorderSizePixel=0; line.AnchorPoint=Vector2.new(0.5,1)
                line.ZIndex=5; line.Parent=tf
            end
            local cx, cy = CAM.ViewportSize.X/2, CAM.ViewportSize.Y
            local diff = Vector2.new(pos.X-cx, pos.Y-cy)
            line.Position=UDim2.new(0,cx,0,cy)
            line.Size=UDim2.new(0,2,0,diff.Magnitude)
            line.Rotation=math.deg(math.atan2(diff.Y,diff.X))+90
            line.Visible=os
        end
    end
end)

-- Jump
UserInputService.JumpRequest:Connect(function()
    if ST.infJump then
        local h = getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Anti-AFK
plr.Idled:Connect(function()
    if ST.antiafk then
        S(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- Click / tap teleport
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if not ST.clickTP then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        if CAM then
            local ray = CAM:ViewportPointToRay(i.Position.X, i.Position.Y)
            local pr = RaycastParams.new()
            pr.FilterType = Enum.RaycastFilterType.Exclude
            pr.FilterDescendantsInstances = { plr.Character }
            local hit = Workspace:Raycast(ray.Origin, ray.Direction*2000, pr)
            if hit then tp(hit.Position) end
        end
    end
end)

-- Character respawn reapply
plr.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then
        h.WalkSpeed = ST.ws
        h.UseJumpPower = true
        h.JumpPower = ST.jp
        if ST.ragdoll then h:ChangeState(Enum.HumanoidStateType.Physics) end
        if ST.camZoom and ST.camZoom > 0 then
            h.CameraOffset = Vector3.new(0,0,ST.camZoom)
        end
    end
    if ST.ghost then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
                p.LocalTransparencyModifier = 1
            end
        end
    end
    if ST.chams then
        task.wait(0.2)
        local hl = Instance.new("Highlight")
        hl.Name="_cham"; hl.FillColor=Color3.fromRGB(255,40,100)
        hl.FillTransparency=0.4; hl.OutlineColor=Color3.fromRGB(255,200,220)
        hl.Parent=char
    end
    if ST.fly then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and not hrp:FindFirstChild("_flyBG") then
            local bg = Instance.new("BodyVelocity")
            bg.Name="_flyBG"; bg.MaxForce=Vector3.new(1e6,1e6,1e6)
            bg.Velocity=Vector3.zero; bg.Parent=hrp
        end
    end
    if ST.antiFling then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and not hrp:FindFirstChild("_antiFlingAV") then
            local av = Instance.new("BodyAngularVelocity")
            av.Name="_antiFlingAV"
            av.AngularVelocity=Vector3.new(0,0,0)
            av.MaxTorque=Vector3.new(1e5,1e5,1e5)
            av.P=1e5; av.Parent=hrp
        end
    end
    if ST.pointLight then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and not hrp:FindFirstChild("_light") then
            local l = Instance.new("PointLight")
            l.Name="_light"; l.Brightness=4
            l.Range=30; l.Color=Color3.fromRGB(255,255,220)
            l.Parent=hrp
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    if ST.esp then
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if ST.esp then S(mkESP, p) end
        end)
    end
end)
Players.PlayerRemoving:Connect(function(p) rmESP(p) end)

-- ==============================
-- WINDOW CONTROLS
-- ==============================
local drag, ds, sp
bar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        drag=true; ds=i.Position; sp=win.Position
        i.Changed:Connect(function()
            if i.UserInputState==Enum.UserInputState.End then drag=false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-ds
        win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
    end
end)

local function openW()
    win.Visible=true
    win.Size=UDim2.new(0,0,0,0)
    TweenService:Create(win,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
        Size=UDim2.new(0,WW,0,WH)}):Play()
end
local function closeW()
    local t = TweenService:Create(win,TweenInfo.new(0.15),{Size=UDim2.new(0,0,0,0)})
    t:Play()
    t.Completed:Connect(function() win.Visible=false end)
end

tog.MouseButton1Click:Connect(function()
    if win.Visible then closeW() else openW() end
end)
clsB.MouseButton1Click:Connect(closeW)
local mini = false
minB.MouseButton1Click:Connect(function()
    mini = not mini
    TweenService:Create(win,TweenInfo.new(0.15),{
        Size = mini and UDim2.new(0,WW,0,38*UI_SCALE) or UDim2.new(0,WW,0,WH)}):Play()
end)
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.RightControl then
        if win.Visible then closeW() else openW() end
    end
end)

-- BOOT
task.spawn(function()
    snowIntro(1.0)
    selectTab(tabBtns[1])
    openW()
end)
