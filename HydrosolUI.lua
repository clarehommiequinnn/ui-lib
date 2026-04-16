local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")

local cloneref    = (cloneref or clonereference or function(i) return i end)
local HttpService = cloneref(game:GetService("HttpService"))

local function tw(o, t, g) TweenService:Create(o, t, g):Play() end
local function ease(o, d, g) tw(o, TweenInfo.new(d, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), g) end
local function round(n, d) d=d or 0; local m=10^d; return math.floor(n*m+0.5)/m end

local function mkCorner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = p; return c
end
local function mkPad(p, t, r, b, l)
    local x = Instance.new("UIPadding")
    x.PaddingTop=UDim.new(0,t or 0); x.PaddingRight=UDim.new(0,r or 0)
    x.PaddingBottom=UDim.new(0,b or 0); x.PaddingLeft=UDim.new(0,l or 0)
    x.Parent=p; return x
end
local function mkStroke(p, col, th, tr)
    local s=Instance.new("UIStroke"); s.Color=col or Color3.fromRGB(50,50,70)
    s.Thickness=th or 1; s.Transparency=tr or 0.6; s.Parent=p; return s
end
local function mkLabel(p, txt, sz, col, fnt, xa)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1
    l.Text=txt or ""; l.TextSize=sz or 13
    l.TextColor3=col or Color3.fromRGB(220,218,255)
    l.Font=fnt or Enum.Font.GothamMedium
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextTruncate=Enum.TextTruncate.AtEnd
    l.Size=UDim2.new(1,0,1,0); l.Parent=p; return l
end
local function mkImg(p, id, sz, col)
    local i=Instance.new("ImageLabel"); i.BackgroundTransparency=1
    i.Image=id; i.ImageColor3=col or Color3.fromRGB(140,138,168)
    i.Size=UDim2.new(0,sz or 16,0,sz or 16)
    i.ScaleType=Enum.ScaleType.Fit; i.Parent=p; return i
end

-- ── Theme ─────────────────────────────────────────────
local T = {
    Win        = Color3.fromRGB(14, 14, 20),
    Surface    = Color3.fromRGB(20, 20, 30),
    SurfaceB   = Color3.fromRGB(17, 17, 26),
    Card       = Color3.fromRGB(24, 24, 36),
    Hover      = Color3.fromRGB(30, 30, 44),
    Border     = Color3.fromRGB(44, 44, 64),
    BorderSub  = Color3.fromRGB(34, 34, 52),
    Accent     = Color3.fromRGB(108, 100, 255),
    AccentDim  = Color3.fromRGB(66,  60, 180),
    AccentHi   = Color3.fromRGB(148, 140, 255),
    Text       = Color3.fromRGB(228, 226, 255),
    TextSub    = Color3.fromRGB(130, 128, 160),
    TextMuted  = Color3.fromRGB(68,  66,  96),
    Success    = Color3.fromRGB(68,  218, 134),
    Warning    = Color3.fromRGB(255, 196, 68),
    Error      = Color3.fromRGB(255, 78,  78),
    ToggleOff  = Color3.fromRGB(38,  38,  54),
    SliderBg   = Color3.fromRGB(28,  28,  42),
    Notify     = Color3.fromRGB(18,  18,  28),
}

-- ── Icons (Solar icon set, Roblox asset IDs) ──────────
local I = {
    close    = "rbxassetid://7072725342",
    minus    = "rbxassetid://7072718362",
    chevDown = "rbxassetid://7072706290",
    check    = "rbxassetid://7072719338",
    search   = "rbxassetid://7072706796",
    keyboard = "rbxassetid://7072710953",
    info     = "rbxassetid://7072709593",
    warning  = "rbxassetid://7072725064",
    success  = "rbxassetid://7072719338",
    error    = "rbxassetid://7072725342",
    eye      = "rbxassetid://7072706600",
    shield   = "rbxassetid://7072714760",
    sword    = "rbxassetid://7072714436",
    bolt     = "rbxassetid://7072706054",
    user     = "rbxassetid://7072720696",
    save     = "rbxassetid://7072714120",
    folder   = "rbxassetid://7072707994",
    refresh  = "rbxassetid://7072713320",
    lock     = "rbxassetid://7072711366",
    layers   = "rbxassetid://7072710722",
    sliders  = "rbxassetid://7072714334",
    terminal = "rbxassetid://7072714966",
    target   = "rbxassetid://7072714898",
    fire     = "rbxassetid://7072707896",
    diamond  = "rbxassetid://7072707022",
    globe    = "rbxassetid://7072708327",
    cursor   = "rbxassetid://7072706486",
    settings = "rbxassetid://7072715066",
    home     = "rbxassetid://7072709007",
    star     = "rbxassetid://7072714574",
    grid     = "rbxassetid://7072708534",
    cpu      = "rbxassetid://7072706418",
    chart    = "rbxassetid://7072706180",
}

-- ── SaveManager ───────────────────────────────────────
local SaveManager = {}
SaveManager.__index = SaveManager
function SaveManager.new(folder)
    local s = setmetatable({}, SaveManager)
    s.folder = folder or "HydrosolUI"; s.autoFile = "autoload"
    s._data = {}; s._flags = {}
    if not isfolder(s.folder) then makefolder(s.folder) end
    return s
end
function SaveManager:_path(n) return self.folder.."/"..n..".json" end
function SaveManager:AddFlag(f, g) self._flags[f] = g end
function SaveManager:_collect()
    local o = {}
    for f, g in pairs(self._flags) do local ok, v = pcall(g); if ok then o[f]=v end end
    return o
end
function SaveManager:Save(n)
    n = n or "default"
    return pcall(writefile, self:_path(n), HttpService:JSONEncode(self:_collect()))
end
function SaveManager:Load(n)
    n = n or "default"; local p = self:_path(n)
    if not isfile(p) then return false, "not found" end
    local ok, raw = pcall(readfile, p); if not ok then return false, raw end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 then return false, data end
    self._data = data; return true, data
end
function SaveManager:SetAutoload(n) return pcall(writefile, self:_path(self.autoFile), n) end
function SaveManager:LoadAutoloadConfig()
    local p = self:_path(self.autoFile); if not isfile(p) then return false end
    local ok, n = pcall(readfile, p); if not ok or n=="" then return false end
    return self:Load(n)
end
function SaveManager:GetValue(f) return self._data[f] end
function SaveManager:ListConfigs()
    local out = {}
    for _, f in ipairs(listfiles(self.folder)) do
        local n = f:match("[^/\\]+$"):gsub("%.json$","")
        if n ~= self.autoFile then table.insert(out, n) end
    end
    return out
end

-- ── Notifications ─────────────────────────────────────
local NotifyHolder
local function ensureNotify()
    if NotifyHolder and NotifyHolder.Parent then return end
    local sg = Instance.new("ScreenGui")
    sg.Name="HydrosolNotify"; sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.DisplayOrder=999
    pcall(function() sg.Parent=CoreGui end)
    if not sg.Parent then sg.Parent=Players.LocalPlayer:WaitForChild("PlayerGui") end
    NotifyHolder = Instance.new("Frame")
    NotifyHolder.Name="NH"; NotifyHolder.BackgroundTransparency=1
    NotifyHolder.Size=UDim2.new(0,300,1,0); NotifyHolder.Position=UDim2.new(1,-312,0,0)
    NotifyHolder.Parent=sg
    local ul=Instance.new("UIListLayout"); ul.SortOrder=Enum.SortOrder.LayoutOrder
    ul.VerticalAlignment=Enum.VerticalAlignment.Bottom; ul.Padding=UDim.new(0,6); ul.Parent=NotifyHolder
    mkPad(NotifyHolder,8,8,8,8)
end

local function Notify(opts)
    opts = opts or {}
    local nType = opts.Type or "info"
    local dur   = opts.Duration or 4
    ensureNotify()
    local col = ({info=T.Accent,success=T.Success,warning=T.Warning,error=T.Error})[nType] or T.Accent
    local icoId = ({info=I.info,success=I.success,warning=I.warning,error=I.error})[nType] or I.info

    local card = Instance.new("Frame")
    card.Size=UDim2.new(1,0,0,68); card.BackgroundColor3=T.Notify
    card.BackgroundTransparency=1; card.ClipsDescendants=true
    card.Position=UDim2.new(1,20,0,0); card.Parent=NotifyHolder
    mkCorner(card,10); mkStroke(card,col,1,0.45)

    -- left accent bar
    local bar=Instance.new("Frame"); bar.Size=UDim2.new(0,3,1,0)
    bar.BackgroundColor3=col; bar.BorderSizePixel=0; bar.Parent=card; mkCorner(bar,2)

    -- icon pill
    local pill=Instance.new("Frame"); pill.Size=UDim2.new(0,30,0,30)
    pill.Position=UDim2.new(0,10,0.5,-15); pill.BackgroundColor3=col
    pill.BackgroundTransparency=0.8; pill.BorderSizePixel=0; pill.Parent=card; mkCorner(pill,8)
    local ico=mkImg(pill,icoId,16,col); ico.Position=UDim2.new(0.5,-8,0.5,-8)

    local tl=Instance.new("TextLabel"); tl.BackgroundTransparency=1
    tl.Text=opts.Title or "HydrosolUI"; tl.TextColor3=T.Text; tl.TextSize=13; tl.Font=Enum.Font.GothamBold
    tl.Size=UDim2.new(1,-50,0,18); tl.Position=UDim2.new(0,46,0,10)
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Parent=card

    local ml=Instance.new("TextLabel"); ml.BackgroundTransparency=1
    ml.Text=opts.Message or ""; ml.TextColor3=T.TextSub; ml.TextSize=11; ml.Font=Enum.Font.Gotham
    ml.Size=UDim2.new(1,-50,0,26); ml.Position=UDim2.new(0,46,0,28)
    ml.TextXAlignment=Enum.TextXAlignment.Left; ml.TextWrapped=true; ml.Parent=card

    local prog=Instance.new("Frame"); prog.Size=UDim2.new(1,0,0,2)
    prog.Position=UDim2.new(0,0,1,-2); prog.BackgroundColor3=col; prog.BorderSizePixel=0; prog.Parent=card

    ease(card, 0.32, {BackgroundTransparency=0.04, Position=UDim2.new(0,0,0,0)})
    tw(prog, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,0,2)})
    task.delay(dur, function()
        ease(card, 0.28, {BackgroundTransparency=1, Position=UDim2.new(1,20,0,0)})
        task.delay(0.3, function() card:Destroy() end)
    end)
    return card
end

-- ─────────────────────────────────────────────────────
-- HydrosolUI
-- ─────────────────────────────────────────────────────
local HydrosolUI = {}
HydrosolUI.__index = HydrosolUI
HydrosolUI.Version = "2.0.0"
HydrosolUI.Theme   = T
HydrosolUI.Icons   = I
HydrosolUI.Notify  = Notify

function HydrosolUI:CreateWindow(opts)
    opts = opts or {}
    local title   = opts.Title      or "HydrosolUI"
    local wSize   = opts.Size       or UDim2.new(0, 860, 0, 520)
    local folder  = opts.SaveFolder or (title:gsub("%s+","").."Configs")
    local hideKey = opts.ToggleKey  or Enum.KeyCode.RightAlt

    ensureNotify()

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name="Hydrosol_"..title:gsub("%s+",""); sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.DisplayOrder=100
    pcall(function() sg.Parent=CoreGui end)
    if not sg.Parent then sg.Parent=Players.LocalPlayer:WaitForChild("PlayerGui") end

    pcall(function()
        local blur=Instance.new("BlurEffect"); blur.Size=0; blur.Parent=game:GetService("Lighting")
        ease(blur, 0.5, {Size=12})
        sg:GetPropertyChangedSignal("Parent"):Connect(function()
            if not sg.Parent then ease(blur, 0.4, {Size=0}); task.delay(0.5, function() blur:Destroy() end) end
        end)
    end)

    -- Shadow layers
    local function mkShadow(ox, oy, col, tr, r)
        local s=Instance.new("Frame"); s.AnchorPoint=Vector2.new(0.5,0.5)
        s.Position=UDim2.new(0.5,ox,0.5,oy); s.Size=wSize
        s.BackgroundColor3=col; s.BackgroundTransparency=tr; s.BorderSizePixel=0; s.Parent=sg
        mkCorner(s, r or 14); return s
    end
    local sh1 = mkShadow(5, 8, Color3.new(), 0.5, 16)
    local sh2 = mkShadow(2, 3, T.AccentDim, 0.88, 14)

    -- Root
    local root=Instance.new("Frame")
    root.Name="Root"; root.AnchorPoint=Vector2.new(0.5,0.5)
    root.Position=UDim2.new(0.5,0,0.5,0); root.Size=wSize
    root.BackgroundColor3=T.Win; root.BorderSizePixel=0; root.ClipsDescendants=true
    root.Parent=sg; mkCorner(root,12); mkStroke(root,T.Border,1,0.4)

    -- bg gradient tint
    local bgG=Instance.new("UIGradient")
    bgG.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(20,16,40)),
        ColorSequenceKeypoint.new(0.35,T.Win),
        ColorSequenceKeypoint.new(1,T.Win),
    }); bgG.Rotation=135; bgG.Parent=root

    -- ── Title bar ──────────────────────────────────────
    local topbar=Instance.new("Frame")
    topbar.Name="TopBar"; topbar.Size=UDim2.new(1,0,0,44)
    topbar.BackgroundColor3=T.SurfaceB; topbar.BorderSizePixel=0; topbar.Parent=root
    do
        local g=Instance.new("UIGradient")
        g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(22,18,44)),ColorSequenceKeypoint.new(1,T.SurfaceB)})
        g.Rotation=90; g.Parent=topbar
    end

    -- logo
    local logoBg=Instance.new("Frame"); logoBg.Size=UDim2.new(0,26,0,26)
    logoBg.Position=UDim2.new(0,12,0.5,-13); logoBg.BackgroundColor3=T.Accent
    logoBg.BackgroundTransparency=0.72; logoBg.BorderSizePixel=0; logoBg.Parent=topbar
    mkCorner(logoBg,7); mkStroke(logoBg,T.Accent,1,0.45)
    local logoI=mkImg(logoBg,I.diamond,14,T.AccentHi); logoI.Position=UDim2.new(0.5,-7,0.5,-7)

    local titleLbl=Instance.new("TextLabel"); titleLbl.BackgroundTransparency=1
    titleLbl.Text=title; titleLbl.TextColor3=T.Text; titleLbl.TextSize=13; titleLbl.Font=Enum.Font.GothamBold
    titleLbl.Position=UDim2.new(0,46,0,0); titleLbl.Size=UDim2.new(0.45,0,1,0)
    titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.Parent=topbar

    local vBadge=Instance.new("TextLabel"); vBadge.BackgroundColor3=T.Card
    vBadge.TextColor3=T.TextMuted; vBadge.Text="v"..HydrosolUI.Version
    vBadge.TextSize=9; vBadge.Font=Enum.Font.GothamMedium
    vBadge.Size=UDim2.new(0,34,0,15); vBadge.Position=UDim2.new(0,142,0.5,-7)
    vBadge.Parent=topbar; mkCorner(vBadge,4); mkPad(vBadge,0,5,0,5)

    -- window buttons
    local function wBtn(xOff, bg, icoId, icoCol)
        local b=Instance.new("TextButton"); b.Size=UDim2.new(0,24,0,24)
        b.Position=UDim2.new(1,xOff,0.5,-12); b.BackgroundColor3=bg
        b.BackgroundTransparency=0.5; b.Text=""; b.BorderSizePixel=0; b.Parent=topbar
        mkCorner(b,6)
        local ic=mkImg(b,icoId,13,icoCol); ic.AnchorPoint=Vector2.new(0.5,0.5); ic.Position=UDim2.new(0.5,0,0.5,0)
        b.MouseEnter:Connect(function() ease(b,0.1,{BackgroundTransparency=0.1}) end)
        b.MouseLeave:Connect(function() ease(b,0.1,{BackgroundTransparency=0.5}) end)
        return b
    end
    local closeBtn=wBtn(-32, Color3.fromRGB(80,26,34), I.close, T.Error)
    local minBtn=wBtn(-62, T.Card, I.minus, T.TextSub)

    closeBtn.MouseButton1Click:Connect(function()
        ease(root,0.3,{Size=UDim2.new(0,wSize.X.Offset,0,0),BackgroundTransparency=1})
        ease(sh1,0.3,{Size=UDim2.new(0,wSize.X.Offset,0,0)}); ease(sh2,0.3,{Size=UDim2.new(0,wSize.X.Offset,0,0)})
        task.delay(0.35,function() sg:Destroy() end)
    end)

    local minimized=false
    minBtn.MouseButton1Click:Connect(function()
        minimized=not minimized
        local tgt=minimized and UDim2.new(0,wSize.X.Offset,0,44) or wSize
        ease(root,0.36,{Size=tgt}); ease(sh1,0.36,{Size=tgt}); ease(sh2,0.36,{Size=tgt})
    end)

    -- drag
    local dragging,dragStart,startPos=false,nil,nil
    topbar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=i.Position; startPos=root.Position
        end
    end)
    topbar.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    RunService.RenderStepped:Connect(function()
        if not dragging then return end
        local d=UserInputService:GetMouseLocation()-Vector2.new(dragStart.X,dragStart.Y)
        local np=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        root.Position=np
        sh1.Position=UDim2.new(np.X.Scale,np.X.Offset+5,np.Y.Scale,np.Y.Offset+8)
        sh2.Position=UDim2.new(np.X.Scale,np.X.Offset+2,np.Y.Scale,np.Y.Offset+3)
    end)

    UserInputService.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode==hideKey then
            local v=not root.Visible; root.Visible=v; sh1.Visible=v; sh2.Visible=v
        end
    end)

    -- top divider
    local tdiv=Instance.new("Frame"); tdiv.Size=UDim2.new(1,0,0,1); tdiv.Position=UDim2.new(0,0,0,44)
    tdiv.BackgroundColor3=T.Border; tdiv.BackgroundTransparency=0.5; tdiv.BorderSizePixel=0; tdiv.Parent=root

    -- ── Sidebar ────────────────────────────────────────
    -- Sidebar: icon-only, 52px wide, tabs stacked vertically
    local sidebar=Instance.new("Frame")
    sidebar.Name="Sidebar"; sidebar.Size=UDim2.new(0,52,1,-45)
    sidebar.Position=UDim2.new(0,0,0,45); sidebar.BackgroundColor3=T.SurfaceB
    sidebar.BorderSizePixel=0; sidebar.Parent=root
    do
        local g=Instance.new("UIGradient")
        g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(16,14,34)),ColorSequenceKeypoint.new(1,T.SurfaceB)})
        g.Rotation=90; g.Parent=sidebar
    end
    local sideList=Instance.new("UIListLayout"); sideList.SortOrder=Enum.SortOrder.LayoutOrder
    sideList.HorizontalAlignment=Enum.HorizontalAlignment.Center
    sideList.Padding=UDim.new(0,2); sideList.Parent=sidebar
    mkPad(sidebar,8,0,8,0)

    local sdiv=Instance.new("Frame"); sdiv.Size=UDim2.new(0,1,1,-45); sdiv.Position=UDim2.new(0,52,0,45)
    sdiv.BackgroundColor3=T.Border; sdiv.BackgroundTransparency=0.45; sdiv.BorderSizePixel=0; sdiv.Parent=root

    -- ── Content ────────────────────────────────────────
    local content=Instance.new("Frame")
    content.Name="Content"; content.Size=UDim2.new(1,-52,1,-45)
    content.Position=UDim2.new(0,52,0,45); content.BackgroundTransparency=1
    content.ClipsDescendants=true; content.Parent=root

    -- entrance
    root.Size=UDim2.new(0,wSize.X.Offset,0,0); root.BackgroundTransparency=1
    ease(root,0.48,{Size=wSize,BackgroundTransparency=0})
    sh1.Size=UDim2.new(0,wSize.X.Offset,0,0); ease(sh1,0.48,{Size=wSize})
    sh2.Size=UDim2.new(0,wSize.X.Offset,0,0); ease(sh2,0.48,{Size=wSize})

    local Window={_tabs={},_activeTab=nil,_sg=sg,_sidebar=sidebar,_content=content,_root=root}
    Window.SaveManager=SaveManager.new(folder); Window.Notify=Notify

    -- ── AddTab ─────────────────────────────────────────
    function Window:AddTab(tabOpts)
        tabOpts=tabOpts or {}
        local tabTitle=tabOpts.Title or ("Tab "..#self._tabs+1)
        local tabIcon=tabOpts.Icon or I.layers

        -- sidebar slot
        local slot=Instance.new("Frame")
        slot.Size=UDim2.new(0,38,0,38); slot.BackgroundColor3=T.Card
        slot.BackgroundTransparency=1; slot.BorderSizePixel=0
        slot.LayoutOrder=#self._tabs+1; slot.Parent=self._sidebar; mkCorner(slot,8)

        local slotIco=mkImg(slot,tabIcon,18,T.TextMuted)
        slotIco.AnchorPoint=Vector2.new(0.5,0.5); slotIco.Position=UDim2.new(0.5,0,0.5,0)

        local slotBtn=Instance.new("TextButton"); slotBtn.Size=UDim2.new(1,0,1,0)
        slotBtn.BackgroundTransparency=1; slotBtn.Text=""; slotBtn.ZIndex=slot.ZIndex+1; slotBtn.Parent=slot

        -- tooltip
        local tip=Instance.new("Frame"); tip.BackgroundColor3=T.Hover
        tip.Size=UDim2.new(0,0,0,24); tip.Position=UDim2.new(1,8,0.5,-12)
        tip.AutomaticSize=Enum.AutomaticSize.X; tip.Visible=false; tip.ZIndex=40; tip.Parent=slot
        mkCorner(tip,6); mkStroke(tip,T.Border,1,0.5); mkPad(tip,0,10,0,10)
        local tipL=mkLabel(tip,tabTitle,11,T.Text,Enum.Font.GothamMedium)
        tipL.AutomaticSize=Enum.AutomaticSize.XY; tipL.Size=UDim2.new(0,0,0,24)
        tipL.TextYAlignment=Enum.TextYAlignment.Center; tipL.ZIndex=41

        slot.MouseEnter:Connect(function()
            tip.Visible=true
            ease(slot,0.14,{BackgroundTransparency=0.5})
            ease(slotIco,0.14,{ImageColor3=T.Text})
        end)
        slot.MouseLeave:Connect(function()
            tip.Visible=false
            local isActive=(self._activeTab and self._activeTab._slot==slot)
            ease(slot,0.14,{BackgroundTransparency=isActive and 0.42 or 1})
            ease(slotIco,0.14,{ImageColor3=isActive and T.AccentHi or T.TextMuted})
        end)

        -- page (scrolling)
        local page=Instance.new("ScrollingFrame")
        page.Name="Page_"..tabTitle; page.Size=UDim2.new(1,0,1,0)
        page.BackgroundTransparency=1; page.BorderSizePixel=0
        page.ScrollBarThickness=2; page.ScrollBarImageColor3=T.Accent
        page.ScrollBarImageTransparency=0.5; page.CanvasSize=UDim2.new(0,0,0,0)
        page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.Visible=false; page.Parent=self._content
        mkPad(page,14,14,14,14)

        local pageList=Instance.new("UIListLayout"); pageList.SortOrder=Enum.SortOrder.LayoutOrder
        pageList.Padding=UDim.new(0,0); pageList.Parent=page

        -- 2 equal columns inside the page
        local colRow=Instance.new("Frame"); colRow.Name="Cols"; colRow.Size=UDim2.new(1,0,0,0)
        colRow.AutomaticSize=Enum.AutomaticSize.Y; colRow.BackgroundTransparency=1; colRow.LayoutOrder=1; colRow.Parent=page
        local colLayout=Instance.new("UIListLayout"); colLayout.FillDirection=Enum.FillDirection.Horizontal
        colLayout.SortOrder=Enum.SortOrder.LayoutOrder; colLayout.Padding=UDim.new(0,10); colLayout.Parent=colRow

        local function mkCol(ord)
            local c=Instance.new("Frame"); c.Size=UDim2.new(0.5,-5,0,0)
            c.AutomaticSize=Enum.AutomaticSize.Y; c.BackgroundTransparency=1
            c.LayoutOrder=ord; c.Parent=colRow
            local cl=Instance.new("UIListLayout"); cl.SortOrder=Enum.SortOrder.LayoutOrder; cl.Padding=UDim.new(0,8); cl.Parent=c
            return c
        end
        local colL=mkCol(1); local colR=mkCol(2)

        local Tab={
            _page=page,_colL=colL,_colR=colR,_ctr={l=0,r=0},
            _slot=slot,_slotIco=slotIco,_window=self
        }

        function Tab:_nextCol()
            if self._ctr.l<=self._ctr.r then self._ctr.l=self._ctr.l+1; return self._colL,self._ctr.l
            else self._ctr.r=self._ctr.r+1; return self._colR,self._ctr.r end
        end
        function Tab:_col(s)
            if s=="right" then self._ctr.r=self._ctr.r+1; return self._colR,self._ctr.r
            else self._ctr.l=self._ctr.l+1; return self._colL,self._ctr.l end
        end

        -- ── Section ──────────────────────────────────
        function Tab:AddSection(sOpts)
            sOpts=sOpts or {}
            local side=sOpts.Side or "auto"
            local col, order=(side=="auto") and self:_nextCol() or self:_col(side)

            local sec=Instance.new("Frame"); sec.Name="Sec"
            sec.Size=UDim2.new(1,0,0,0); sec.AutomaticSize=Enum.AutomaticSize.Y
            sec.BackgroundColor3=T.Surface; sec.BackgroundTransparency=0.08
            sec.BorderSizePixel=0; sec.LayoutOrder=order; sec.Parent=col; sec.ClipsDescendants=true
            mkCorner(sec,10); mkStroke(sec,T.Border,1,0.5)

            local secList=Instance.new("UIListLayout"); secList.SortOrder=Enum.SortOrder.LayoutOrder
            secList.Padding=UDim.new(0,0); secList.Parent=sec

            -- header
            if sOpts.Title and sOpts.Title~="" then
                local hdr=Instance.new("Frame"); hdr.Size=UDim2.new(1,0,0,36)
                hdr.BackgroundColor3=T.Card; hdr.BackgroundTransparency=0.05
                hdr.BorderSizePixel=0; hdr.LayoutOrder=0; hdr.Parent=sec
                -- gradient tint
                local hg=Instance.new("UIGradient")
                hg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(30,26,56)),ColorSequenceKeypoint.new(1,T.Card)})
                hg.Rotation=90; hg.Parent=hdr
                -- bottom divider
                local hdiv=Instance.new("Frame"); hdiv.Size=UDim2.new(1,0,0,1)
                hdiv.Position=UDim2.new(0,0,1,-1); hdiv.BackgroundColor3=T.Border
                hdiv.BackgroundTransparency=0.4; hdiv.BorderSizePixel=0; hdiv.Parent=hdr

                local xOff=12
                if sOpts.Icon then
                    local si=mkImg(hdr,sOpts.Icon,14,T.Accent); si.Position=UDim2.new(0,12,0.5,-7); xOff=30
                end
                -- accent pill
                local pill=Instance.new("Frame"); pill.Size=UDim2.new(0,2,0,16)
                pill.Position=UDim2.new(0,xOff,0.5,-8); pill.BackgroundColor3=T.Accent
                pill.BackgroundTransparency=0; pill.BorderSizePixel=0; pill.Parent=hdr; mkCorner(pill,2)

                local hl=mkLabel(hdr,sOpts.Title,11,T.TextSub,Enum.Font.GothamBold)
                hl.Position=UDim2.new(0,xOff+8,0,0); hl.Size=UDim2.new(1,-xOff-20,1,0)
                hl.TextYAlignment=Enum.TextYAlignment.Center
            end

            local body=Instance.new("Frame"); body.Name="Body"; body.Size=UDim2.new(1,0,0,0)
            body.AutomaticSize=Enum.AutomaticSize.Y; body.BackgroundTransparency=1
            body.LayoutOrder=1; body.Parent=sec
            local bodyL=Instance.new("UIListLayout"); bodyL.SortOrder=Enum.SortOrder.LayoutOrder
            bodyL.Padding=UDim.new(0,0); bodyL.Parent=body
            mkPad(body,0,0,6,0)

            local Section={_body=body,_sec=sec,_n=0,_tab=self}

            -- shared row
            local function mkRow(h)
                h=h or 40; Section._n=Section._n+1
                local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,h)
                row.BackgroundColor3=T.SurfaceB; row.BackgroundTransparency=0.7
                row.BorderSizePixel=0; row.LayoutOrder=Section._n; row.Parent=body
                mkPad(row,0,14,0,14)
                -- top divider
                local dv=Instance.new("Frame"); dv.Size=UDim2.new(1,0,0,1)
                dv.BackgroundColor3=T.BorderSub; dv.BackgroundTransparency=0.6
                dv.BorderSizePixel=0; dv.ZIndex=row.ZIndex; dv.Parent=row
                row.MouseEnter:Connect(function() ease(row,0.08,{BackgroundTransparency=0.35}) end)
                row.MouseLeave:Connect(function() ease(row,0.08,{BackgroundTransparency=0.7}) end)
                return row
            end

            -- ── AddParagraph ─────────────────────────
            function Section:AddParagraph(o)
                o=o or {}
                local row=mkRow(nil); row.AutomaticSize=Enum.AutomaticSize.Y; row.Size=UDim2.new(1,0,0,0)
                local inner=Instance.new("Frame"); inner.BackgroundTransparency=1
                inner.Size=UDim2.new(1,0,0,0); inner.AutomaticSize=Enum.AutomaticSize.Y; inner.Parent=row
                mkPad(inner,8,0,8,0)
                local il=Instance.new("UIListLayout"); il.SortOrder=Enum.SortOrder.LayoutOrder; il.Padding=UDim.new(0,3); il.Parent=inner
                local tl=mkLabel(inner,o.Title or "",12,T.TextSub,Enum.Font.GothamBold); tl.LayoutOrder=1; tl.Size=UDim2.new(1,0,0,14); tl.AutomaticSize=Enum.AutomaticSize.Y; tl.TextWrapped=true
                local bl=mkLabel(inner,o.Content or "",11,T.TextMuted,Enum.Font.Gotham); bl.LayoutOrder=2; bl.Size=UDim2.new(1,0,0,14); bl.AutomaticSize=Enum.AutomaticSize.Y; bl.TextWrapped=true
                local P={}
                function P:Set(t,c) if t~=nil then tl.Text=t end; if c~=nil then bl.Text=c end end
                function P:SetTitle(t) tl.Text=t end
                function P:SetContent(c) bl.Text=c end
                return P
            end

            -- ── AddButton ────────────────────────────
            function Section:AddButton(o)
                o=o or {}; local row=mkRow(40)
                if o.Icon then local bi=mkImg(row,o.Icon,15,T.TextSub); bi.Position=UDim2.new(0,0,0.5,-7) end
                local off=o.Icon and 20 or 0
                local l=mkLabel(row,o.Title or "Button",12,T.Text)
                l.Position=UDim2.new(0,off,0,0); l.Size=UDim2.new(0.62,-off,1,0); l.TextYAlignment=Enum.TextYAlignment.Center

                local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0,72,0,26)
                btn.Position=UDim2.new(1,-72,0.5,-13); btn.BackgroundColor3=T.Accent
                btn.Text=o.BtnText or "Run"; btn.TextColor3=Color3.new(1,1,1)
                btn.TextSize=11; btn.Font=Enum.Font.GothamBold; btn.BorderSizePixel=0; btn.Parent=row; mkCorner(btn,7)
                do
                    local g=Instance.new("UIGradient")
                    g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,T.AccentHi),ColorSequenceKeypoint.new(1,T.AccentDim)})
                    g.Rotation=90; g.Parent=btn
                end
                btn.MouseEnter:Connect(function() ease(btn,0.1,{BackgroundColor3=T.AccentDim}) end)
                btn.MouseLeave:Connect(function() ease(btn,0.1,{BackgroundColor3=T.Accent}) end)
                btn.MouseButton1Click:Connect(function()
                    ease(btn,0.05,{BackgroundColor3=T.AccentHi})
                    task.delay(0.05,function() ease(btn,0.16,{BackgroundColor3=T.Accent}) end)
                    if o.Callback then pcall(o.Callback) end
                end)
                return btn
            end

            -- ── AddToggle ────────────────────────────
            function Section:AddToggle(o)
                o=o or {}; local row=mkRow(40)
                if o.Icon then local ti=mkImg(row,o.Icon,15,T.TextSub); ti.Position=UDim2.new(0,0,0.5,-7) end
                local off=o.Icon and 20 or 0
                local l=mkLabel(row,o.Title or "Toggle",12,T.Text)
                l.Position=UDim2.new(0,off,0,0); l.Size=UDim2.new(0.72,-off,1,0); l.TextYAlignment=Enum.TextYAlignment.Center

                local state=o.Default or false

                -- track (pill shape)
                local track=Instance.new("Frame"); track.Size=UDim2.new(0,42,0,22)
                track.Position=UDim2.new(1,-42,0.5,-11); track.BorderSizePixel=0
                track.BackgroundColor3=state and T.Accent or T.ToggleOff; track.Parent=row; mkCorner(track,11)
                do
                    local tg=Instance.new("UIGradient")
                    tg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,T.AccentHi),ColorSequenceKeypoint.new(1,T.Accent)})
                    tg.Parent=track; tg.Enabled=state
                end

                local thumb=Instance.new("Frame"); thumb.Size=UDim2.new(0,16,0,16)
                thumb.Position=state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
                thumb.BackgroundColor3=Color3.new(1,1,1); thumb.BorderSizePixel=0; thumb.Parent=track; mkCorner(thumb,8)

                local ca=Instance.new("TextButton"); ca.Size=UDim2.new(1,0,1,0); ca.BackgroundTransparency=1; ca.Text=""; ca.Parent=row
                local Tgl={Value=state}
                local tGrad=track:FindFirstChildOfClass("UIGradient")

                local function setState(v,silent)
                    state=v; Tgl.Value=v
                    ease(track,0.2,{BackgroundColor3=v and T.Accent or T.ToggleOff})
                    ease(thumb,0.2,{Position=v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)})
                    if tGrad then tGrad.Enabled=v end
                    if not silent and o.Callback then pcall(o.Callback,v) end
                end
                ca.MouseButton1Click:Connect(function() setState(not state) end)
                function Tgl:Set(v) setState(v,true) end
                if o.Flag and Tab._window.SaveManager then Tab._window.SaveManager:AddFlag(o.Flag,function() return Tgl.Value end) end
                return Tgl
            end

            -- ── AddSlider ────────────────────────────
            function Section:AddSlider(o)
                o=o or {}; local row=mkRow(50)
                local minV,maxV,dp=o.Min or 0,o.Max or 100,o.Decimals or 0
                local sfx=o.Suffix or ""; local cur=math.clamp(o.Default or minV,minV,maxV)

                if o.Icon then local si=mkImg(row,o.Icon,15,T.TextSub); si.Position=UDim2.new(0,0,0,8) end
                local off=o.Icon and 20 or 0

                local l=mkLabel(row,o.Title or "Slider",12,T.Text)
                l.Position=UDim2.new(0,off,0,5); l.Size=UDim2.new(0.7,-off,0,16); l.TextYAlignment=Enum.TextYAlignment.Top

                local vl=Instance.new("TextLabel"); vl.BackgroundTransparency=1
                vl.Text=round(cur,dp)..sfx; vl.TextColor3=T.Accent; vl.TextSize=12; vl.Font=Enum.Font.GothamBold
                vl.Size=UDim2.new(0.3,0,0,16); vl.Position=UDim2.new(0.7,0,0,5)
                vl.TextXAlignment=Enum.TextXAlignment.Right; vl.Parent=row

                -- track
                local tf=Instance.new("Frame"); tf.Size=UDim2.new(1,0,0,5); tf.Position=UDim2.new(0,0,1,-13)
                tf.BackgroundColor3=T.SliderBg; tf.BorderSizePixel=0; tf.Parent=row; mkCorner(tf,3)

                local fill=Instance.new("Frame"); fill.Size=UDim2.new((cur-minV)/(maxV-minV),0,1,0)
                fill.BackgroundColor3=T.Accent; fill.BorderSizePixel=0; fill.Parent=tf; mkCorner(fill,3)
                do
                    local fg=Instance.new("UIGradient")
                    fg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,T.AccentDim),ColorSequenceKeypoint.new(1,T.AccentHi)})
                    fg.Parent=fill
                end

                local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,13,0,13)
                knob.AnchorPoint=Vector2.new(0.5,0.5); knob.Position=UDim2.new((cur-minV)/(maxV-minV),0,0.5,0)
                knob.BackgroundColor3=Color3.new(1,1,1); knob.BorderSizePixel=0
                knob.ZIndex=tf.ZIndex+1; knob.Parent=tf; mkCorner(knob,7)
                mkStroke(knob,T.Accent,1.5,0.35)

                local draggingS=false; local Sld={Value=cur}
                local function setS(v,silent)
                    v=math.clamp(round(v,dp),minV,maxV); cur=v; Sld.Value=v
                    local p=(v-minV)/(maxV-minV)
                    ease(fill,0.04,{Size=UDim2.new(p,0,1,0)}); ease(knob,0.04,{Position=UDim2.new(p,0,0.5,0)})
                    vl.Text=round(v,dp)..sfx
                    if not silent and o.Callback then pcall(o.Callback,v) end
                end
                local function fromMouse()
                    local mx=UserInputService:GetMouseLocation()
                    local ta=tf.AbsolutePosition; local ts=tf.AbsoluteSize
                    setS(minV+math.clamp((mx.X-ta.X)/ts.X,0,1)*(maxV-minV))
                end
                tf.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then draggingS=true; fromMouse() end end)
                UserInputService.InputChanged:Connect(function(i) if draggingS and i.UserInputType==Enum.UserInputType.MouseMovement then fromMouse() end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then draggingS=false end end)
                function Sld:Set(v) setS(v,true) end
                if o.Flag and Tab._window.SaveManager then Tab._window.SaveManager:AddFlag(o.Flag,function() return Sld.Value end) end
                return Sld
            end

            -- ── AddDropdown / AddMultiDropdown ────────
            local function buildDrop(o, multi)
                o=o or {}; local row=mkRow(40)
                if o.Icon then local di=mkImg(row,o.Icon,15,T.TextSub); di.Position=UDim2.new(0,0,0.5,-7) end
                local off=o.Icon and 20 or 0
                local l=mkLabel(row,o.Title or "Dropdown",12,T.Text)
                l.Position=UDim2.new(0,off,0,0); l.Size=UDim2.new(0.44,-off,1,0); l.TextYAlignment=Enum.TextYAlignment.Center

                local opts=o.Options or {}
                local selected=multi and {} or (o.Default or opts[1] or "None")
                if multi and o.Default then for _,v in ipairs(o.Default) do selected[v]=true end end

                local disp=Instance.new("TextButton"); disp.Size=UDim2.new(0.56,-4,0,27)
                disp.Position=UDim2.new(0.44,4,0.5,-13); disp.BackgroundColor3=T.Card
                disp.BorderSizePixel=0; disp.Font=Enum.Font.GothamMedium; disp.TextSize=11
                disp.TextColor3=T.TextSub; disp.TextXAlignment=Enum.TextXAlignment.Left
                disp.ClipsDescendants=true; disp.Parent=row; mkCorner(disp,8); mkPad(disp,0,26,0,10); mkStroke(disp,T.Border,1,0.5)

                local chevI=mkImg(disp,I.chevDown,12,T.TextMuted)
                chevI.AnchorPoint=Vector2.new(1,0.5); chevI.Position=UDim2.new(1,-4,0.5,0)

                local function refreshDisp()
                    if multi then
                        local s={}; for k,v in pairs(selected) do if v then table.insert(s,k) end end
                        disp.Text=#s==0 and "None" or table.concat(s,", ")
                    else disp.Text=tostring(selected) end
                end
                refreshDisp()

                local open=false
                local panel=Instance.new("Frame"); panel.BackgroundColor3=T.Card
                panel.Size=UDim2.new(0,200,0,0); panel.BackgroundTransparency=0.04
                panel.Visible=false; panel.ZIndex=70; panel.Parent=sg
                mkCorner(panel,10); mkStroke(panel,T.Border,1,0.35)

                local sRow=Instance.new("Frame"); sRow.Size=UDim2.new(1,-12,0,28); sRow.Position=UDim2.new(0,6,0,6)
                sRow.BackgroundColor3=T.Surface; sRow.BorderSizePixel=0; sRow.ZIndex=71; sRow.Parent=panel
                mkCorner(sRow,7); mkStroke(sRow,T.Border,1,0.55)
                local sIco=mkImg(sRow,I.search,13,T.TextMuted); sIco.Position=UDim2.new(0,7,0.5,-6); sIco.ZIndex=72
                local sBox=Instance.new("TextBox"); sBox.Size=UDim2.new(1,-30,1,0); sBox.Position=UDim2.new(0,26,0,0)
                sBox.BackgroundTransparency=1; sBox.Text=""; sBox.PlaceholderText="Search..."
                sBox.PlaceholderColor3=T.TextMuted; sBox.TextColor3=T.Text; sBox.TextSize=11
                sBox.Font=Enum.Font.Gotham; sBox.ClearTextOnFocus=false; sBox.ZIndex=72; sBox.Parent=sRow

                local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-8,0,0)
                scroll.Position=UDim2.new(0,4,0,40); scroll.BackgroundTransparency=1
                scroll.BorderSizePixel=0; scroll.ScrollBarThickness=2; scroll.ScrollBarImageColor3=T.Accent
                scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.new(0,0,0,0)
                scroll.ZIndex=71; scroll.Parent=panel
                local sl=Instance.new("UIListLayout"); sl.SortOrder=Enum.SortOrder.LayoutOrder; sl.Padding=UDim.new(0,2); sl.Parent=scroll

                local Drop={Value=selected}; local itemRefs={}

                local function mkItem(opt)
                    local itm=Instance.new("TextButton"); itm.Size=UDim2.new(1,0,0,28)
                    itm.BackgroundColor3=T.SurfaceB; itm.BackgroundTransparency=0.5
                    itm.Text=tostring(opt); itm.TextColor3=T.TextSub; itm.TextSize=11
                    itm.Font=Enum.Font.GothamMedium; itm.TextXAlignment=Enum.TextXAlignment.Left
                    itm.BorderSizePixel=0; itm.ZIndex=72; itm.Parent=scroll; mkCorner(itm,6); mkPad(itm,0,0,0,10)
                    local chk=mkImg(itm,I.check,11,T.Accent); chk.AnchorPoint=Vector2.new(1,0.5)
                    chk.Position=UDim2.new(1,-8,0.5,0); chk.ZIndex=73; chk.Visible=false
                    local function refChk()
                        local sel=multi and selected[opt] or (selected==opt)
                        chk.Visible=sel; itm.TextColor3=sel and T.Text or T.TextSub
                        itm.BackgroundColor3=sel and T.Hover or T.SurfaceB
                    end
                    refChk()
                    itm.MouseButton1Click:Connect(function()
                        if multi then selected[opt]=not selected[opt] else selected=opt end
                        Drop.Value=selected; refChk(); refreshDisp()
                        if o.Callback then pcall(o.Callback,selected) end
                        if not multi then
                            open=false
                            ease(panel,0.16,{Size=UDim2.new(0,panel.AbsoluteSize.X,0,0)})
                            ease(chevI,0.14,{Rotation=0}); task.delay(0.18,function() panel.Visible=false end)
                        end
                    end)
                    itm.MouseEnter:Connect(function() ease(itm,0.07,{BackgroundTransparency=0.2}) end)
                    itm.MouseLeave:Connect(function() ease(itm,0.07,{BackgroundTransparency=0.5}) end)
                    return itm,refChk
                end

                for _,op in ipairs(opts) do local it,rc=mkItem(op); table.insert(itemRefs,{btn=it,text=tostring(op),refresh=rc}) end

                sBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local q=sBox.Text:lower()
                    for _,r in ipairs(itemRefs) do r.btn.Visible=(q=="" or r.text:lower():find(q,1,true)~=nil) end
                end)

                local function openP()
                    local a=disp.AbsolutePosition; local s=disp.AbsoluteSize
                    local mh=math.min(#opts*30+50,200)
                    panel.Position=UDim2.new(0,a.X,0,a.Y+s.Y+4); panel.Size=UDim2.new(0,s.X,0,0)
                    scroll.Size=UDim2.new(1,-8,0,mh-46); panel.Visible=true
                    ease(panel,0.2,{Size=UDim2.new(0,s.X,0,mh)}); ease(chevI,0.14,{Rotation=180})
                end
                local function closeP()
                    ease(panel,0.16,{Size=UDim2.new(0,panel.AbsoluteSize.X,0,0)})
                    ease(chevI,0.14,{Rotation=0}); task.delay(0.18,function() panel.Visible=false end)
                end

                disp.MouseButton1Click:Connect(function() open=not open; if open then openP() else closeP() end end)
                UserInputService.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 and open then
                        local m=UserInputService:GetMouseLocation(); local pa=panel.AbsolutePosition; local ps=panel.AbsoluteSize
                        if m.X<pa.X or m.X>pa.X+ps.X or m.Y<pa.Y or m.Y>pa.Y+ps.Y then open=false; closeP() end
                    end
                end)

                function Drop:Set(v)
                    if multi then selected={}; if type(v)=="table" then for _,k in ipairs(v) do selected[k]=true end end
                    else selected=v end
                    Drop.Value=selected; for _,r in ipairs(itemRefs) do r.refresh() end; refreshDisp()
                end
                function Drop:SetOptions(newOpts)
                    for _,r in ipairs(itemRefs) do r.btn:Destroy() end; itemRefs={}
                    for _,op in ipairs(newOpts) do local it,rc=mkItem(op); table.insert(itemRefs,{btn=it,text=tostring(op),refresh=rc}) end
                end
                if o.Flag and Tab._window.SaveManager then Tab._window.SaveManager:AddFlag(o.Flag,function() return Drop.Value end) end
                return Drop
            end

            function Section:AddDropdown(o) return buildDrop(o,false) end
            function Section:AddMultiDropdown(o) return buildDrop(o,true) end

            -- ── AddKeybind ───────────────────────────
            function Section:AddKeybind(o)
                o=o or {}; local row=mkRow(40)
                if o.Icon then local ki=mkImg(row,o.Icon,15,T.TextSub); ki.Position=UDim2.new(0,0,0.5,-7) end
                local off=o.Icon and 20 or 0
                local l=mkLabel(row,o.Title or "Keybind",12,T.Text)
                l.Position=UDim2.new(0,off,0,0); l.Size=UDim2.new(0.55,-off,1,0); l.TextYAlignment=Enum.TextYAlignment.Center

                local key=o.Default or Enum.KeyCode.Unknown; local listening=false
                local kBtn=Instance.new("TextButton"); kBtn.Size=UDim2.new(0,82,0,25)
                kBtn.Position=UDim2.new(1,-82,0.5,-12); kBtn.BackgroundColor3=T.Card
                kBtn.Text=key.Name; kBtn.TextColor3=T.Accent; kBtn.TextSize=11; kBtn.Font=Enum.Font.GothamBold
                kBtn.BorderSizePixel=0; kBtn.Parent=row; mkCorner(kBtn,7); mkStroke(kBtn,T.Accent,1,0.55); mkPad(kBtn,0,8,0,8)

                local kIco=mkImg(kBtn,I.keyboard,11,T.AccentHi); kIco.Position=UDim2.new(0,4,0.5,-5)

                local Kb={Value=key}
                kBtn.MouseButton1Click:Connect(function()
                    listening=true; kBtn.Text="  · · ·"; ease(kBtn,0.1,{BackgroundColor3=T.Hover})
                end)
                UserInputService.InputBegan:Connect(function(i,gp)
                    if not listening then
                        if i.KeyCode==key and not gp then if o.Callback then pcall(o.Callback,key) end end; return
                    end
                    if i.UserInputType==Enum.UserInputType.Keyboard then
                        listening=false; key=i.KeyCode; Kb.Value=key; kBtn.Text=key.Name
                        ease(kBtn,0.1,{BackgroundColor3=T.Card})
                        if o.Changed then pcall(o.Changed,key) end
                    end
                end)
                function Kb:Set(k) key=k; Kb.Value=k; kBtn.Text=k.Name end
                if o.Flag and Tab._window.SaveManager then Tab._window.SaveManager:AddFlag(o.Flag,function() return Kb.Value.Name end) end
                return Kb
            end

            -- ── AddInput ─────────────────────────────
            function Section:AddInput(o)
                o=o or {}; local row=mkRow(40)
                if o.Icon then local ii=mkImg(row,o.Icon,15,T.TextSub); ii.Position=UDim2.new(0,0,0.5,-7) end
                local off=o.Icon and 20 or 0
                local l=mkLabel(row,o.Title or "Input",12,T.Text)
                l.Position=UDim2.new(0,off,0,0); l.Size=UDim2.new(0.38,-off,1,0); l.TextYAlignment=Enum.TextYAlignment.Center

                local box=Instance.new("TextBox"); box.Size=UDim2.new(0.62,-4,0,27)
                box.Position=UDim2.new(0.38,4,0.5,-13); box.BackgroundColor3=T.Card
                box.BorderSizePixel=0; box.Text=o.Default or ""; box.PlaceholderText=o.Placeholder or "..."
                box.PlaceholderColor3=T.TextMuted; box.TextColor3=T.Text; box.TextSize=11; box.Font=Enum.Font.Gotham
                box.ClearTextOnFocus=o.ClearOnFocus~=false; box.Parent=row; mkCorner(box,8); mkPad(box,0,8,0,10); mkStroke(box,T.Border,1,0.55)

                box.Focused:Connect(function() ease(box,0.12,{BackgroundColor3=T.Hover}) end)
                box.FocusLost:Connect(function(enter)
                    ease(box,0.12,{BackgroundColor3=T.Card})
                    if o.Callback then pcall(o.Callback,box.Text,enter) end
                end)
                local Inp={Value=box.Text}
                box:GetPropertyChangedSignal("Text"):Connect(function() Inp.Value=box.Text; if o.Changed then pcall(o.Changed,box.Text) end end)
                function Inp:Set(v) box.Text=tostring(v) end
                if o.Flag and Tab._window.SaveManager then Tab._window.SaveManager:AddFlag(o.Flag,function() return Inp.Value end) end
                return Inp
            end

            -- ── AddLabel ─────────────────────────────
            function Section:AddLabel(o)
                o=o or {}; local row=mkRow(32)
                row.AutomaticSize=Enum.AutomaticSize.Y; row.Size=UDim2.new(1,0,0,32)
                local l=mkLabel(row,o.Text or "",11,T.TextSub,Enum.Font.Gotham)
                l.TextYAlignment=Enum.TextYAlignment.Center; l.TextWrapped=true
                local L={}; function L:Set(t) l.Text=t end; return L
            end

            return Section
        end

        slotBtn.MouseButton1Click:Connect(function() self:_setActive(Tab) end)
        table.insert(self._tabs,Tab)
        if #self._tabs==1 then self:_setActive(Tab) end
        return Tab
    end

    function Window:_setActive(tab)
        for _,t in ipairs(self._tabs) do
            t._page.Visible=false
            ease(t._slot,0.14,{BackgroundTransparency=1})
            ease(t._slotIco,0.14,{ImageColor3=T.TextMuted})
        end
        tab._page.Visible=true; self._activeTab=tab
        ease(tab._slot,0.18,{BackgroundTransparency=0.42})
        ease(tab._slotIco,0.18,{ImageColor3=T.AccentHi})

        if self._sideInd then self._sideInd:Destroy() end
        local ind=Instance.new("Frame"); ind.Size=UDim2.new(0,3,0,20); ind.AnchorPoint=Vector2.new(0,0.5)
        ind.BackgroundColor3=T.Accent; ind.BorderSizePixel=0; ind.ZIndex=6; ind.Parent=self._sidebar; mkCorner(ind,2)
        do
            local ig=Instance.new("UIGradient")
            ig.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,T.AccentHi),ColorSequenceKeypoint.new(1,T.Accent)})
            ig.Rotation=90; ig.Parent=ind
        end
        self._sideInd=ind
        local _slot,_sb=tab._slot,self._sidebar
        task.defer(function()
            local y=_slot.AbsolutePosition.Y-_sb.AbsolutePosition.Y+19
            ind.Position=UDim2.new(0,0,0,y)
        end)
    end

    return Window
end

return HydrosolUI
