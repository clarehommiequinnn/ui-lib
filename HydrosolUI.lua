local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")

local cloneref      = (cloneref or clonereference or function(i) return i end)
local HttpService   = cloneref(game:GetService("HttpService"))

local function tw(obj, info, goals) TweenService:Create(obj, info, goals):Play() end
local function round(n, d) d = d or 0; local m = 10^d; return math.floor(n*m+0.5)/m end
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,r or 8); c.Parent = p; return c end
local function pad(p,t,r,b,l) local x = Instance.new("UIPadding"); x.PaddingTop=UDim.new(0,t or 6); x.PaddingRight=UDim.new(0,r or 6); x.PaddingBottom=UDim.new(0,b or 6); x.PaddingLeft=UDim.new(0,l or 6); x.Parent=p; return x end
local function stroke(p,col,th,tr) local s=Instance.new("UIStroke"); s.Color=col or Color3.fromRGB(55,55,75); s.Thickness=th or 1; s.Transparency=tr or 0.55; s.Parent=p; return s end
local function lbl(parent,text,size,col,font,xalign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency=1; l.Text=text or ""; l.TextSize=size or 13
    l.TextColor3=col or Color3.fromRGB(220,218,255); l.Font=font or Enum.Font.GothamMedium
    l.TextXAlignment=xalign or Enum.TextXAlignment.Left; l.TextWrapped=true
    l.AutomaticSize=Enum.AutomaticSize.Y; l.Size=UDim2.new(1,0,0,0); l.Parent=parent
    return l
end

local T = {
    Bg         = Color3.fromRGB(10, 10, 16),
    Surface    = Color3.fromRGB(16, 16, 24),
    SurfaceAlt = Color3.fromRGB(20, 20, 30),
    Elevated   = Color3.fromRGB(26, 26, 38),
    Border     = Color3.fromRGB(46, 46, 68),
    Accent     = Color3.fromRGB(110, 102, 255),
    AccentDim  = Color3.fromRGB(68,  62, 178),
    AccentGlow = Color3.fromRGB(148, 138, 255),
    AccentSoft = Color3.fromRGB(110, 102, 255),
    Text       = Color3.fromRGB(232, 230, 255),
    TextSub    = Color3.fromRGB(138, 135, 165),
    TextMuted  = Color3.fromRGB(72,  70, 100),
    Success    = Color3.fromRGB(72,  220, 138),
    Warning    = Color3.fromRGB(255, 198, 72),
    Error      = Color3.fromRGB(255, 82,  82),
    ToggleOff  = Color3.fromRGB(40,  40,  56),
    TrackBg    = Color3.fromRGB(30,  30,  46),
    Notify     = Color3.fromRGB(18,  18,  28),
}

-- Solar Icons via CDN  (rbxthumb won't work; we load as ImageLabel from rbxassetid OR use SVG-rendered asset)
-- Since executor lvl7 supports HttpGet, we load icons as ImageLabels using Roblox asset IDs mapped to Solar icon set
-- These are pre-uploaded Solar icon equivalents available as Roblox decals
local ICONS = {
    search     = "rbxassetid://7072706796",
    close      = "rbxassetid://7072725342",
    minus      = "rbxassetid://7072718362",
    chevDown   = "rbxassetid://7072706290",
    check      = "rbxassetid://7072719338",
    settings   = "rbxassetid://7072715066",
    keyboard   = "rbxassetid://7072710953",
    info       = "rbxassetid://7072709593",
    warning    = "rbxassetid://7072725064",
    success    = "rbxassetid://7072719338",
    error      = "rbxassetid://7072725342",
    eye        = "rbxassetid://7072706600",
    eyeOff     = "rbxassetid://7072706654",
    globe      = "rbxassetid://7072708327",
    shield     = "rbxassetid://7072714760",
    sword      = "rbxassetid://7072714436",
    bolt       = "rbxassetid://7072706054",
    user       = "rbxassetid://7072720696",
    save       = "rbxassetid://7072714120",
    folder     = "rbxassetid://7072707994",
    refresh    = "rbxassetid://7072713320",
    lock       = "rbxassetid://7072711366",
    cursor     = "rbxassetid://7072706486",
    layers     = "rbxassetid://7072710722",
    sliders    = "rbxassetid://7072714334",
    terminal   = "rbxassetid://7072714966",
    target     = "rbxassetid://7072714898",
    fire       = "rbxassetid://7072707896",
    diamond    = "rbxassetid://7072707022",
}

local function icon(parent, id, size, col)
    local img = Instance.new("ImageLabel")
    img.BackgroundTransparency = 1
    img.Image = id
    img.ImageColor3 = col or T.TextSub
    img.Size = UDim2.new(0, size or 16, 0, size or 16)
    img.ScaleType = Enum.ScaleType.Fit
    img.Parent = parent
    return img
end

-- ─── SaveManager ──────────────────────────────────────────────────────────────
local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager.new(folder)
    local s = setmetatable({}, SaveManager)
    s.folder = folder or "HydrosolUI"
    s.autoFile = "autoload"
    s._data = {}
    s._flags = {}
    if not isfolder(s.folder) then makefolder(s.folder) end
    return s
end

function SaveManager:_path(n) return self.folder.."/"..n..".json" end
function SaveManager:AddFlag(f, g) self._flags[f] = g end

function SaveManager:_collect()
    local o = {}
    for f, g in pairs(self._flags) do
        local ok, v = pcall(g)
        if ok then o[f] = v end
    end
    return o
end

function SaveManager:Save(n)
    n = n or "default"
    return pcall(writefile, self:_path(n), HttpService:JSONEncode(self:_collect()))
end

function SaveManager:Load(n)
    n = n or "default"
    local p = self:_path(n)
    if not isfile(p) then return false, "not found" end
    local ok, raw = pcall(readfile, p)
    if not ok then return false, raw end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 then return false, data end
    self._data = data
    return true, data
end

function SaveManager:SetAutoload(n)
    return pcall(writefile, self:_path(self.autoFile), n)
end

function SaveManager:LoadAutoloadConfig()
    local p = self:_path(self.autoFile)
    if not isfile(p) then return false end
    local ok, n = pcall(readfile, p)
    if not ok or n == "" then return false end
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

-- ─── Notification ─────────────────────────────────────────────────────────────
local NotifyHolder

local function ensureNotify()
    if NotifyHolder and NotifyHolder.Parent then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "HydrosolNotify"; sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.DisplayOrder = 999
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

    NotifyHolder = Instance.new("Frame")
    NotifyHolder.Name = "NotifyHolder"; NotifyHolder.BackgroundTransparency = 1
    NotifyHolder.Size = UDim2.new(0,320,1,0); NotifyHolder.Position = UDim2.new(1,-332,0,0)
    NotifyHolder.Parent = sg
    local ul = Instance.new("UIListLayout")
    ul.SortOrder = Enum.SortOrder.LayoutOrder
    ul.VerticalAlignment = Enum.VerticalAlignment.Bottom
    ul.Padding = UDim.new(0,6); ul.Parent = NotifyHolder
    pad(NotifyHolder,8,8,8,8)
end

local function Notify(opts)
    opts = opts or {}
    local nType = opts.Type or "info"
    local dur   = opts.Duration or 4
    ensureNotify()

    local tCol = ({ info=T.Accent, success=T.Success, warning=T.Warning, error=T.Error })[nType] or T.Accent
    local icoId = ({ info=ICONS.info, success=ICONS.success, warning=ICONS.warning, error=ICONS.error })[nType] or ICONS.info

    local card = Instance.new("Frame")
    card.Name = "Notify"; card.Size = UDim2.new(1,0,0,70)
    card.BackgroundColor3 = T.Notify; card.BackgroundTransparency = 1
    card.ClipsDescendants = true; card.Parent = NotifyHolder
    corner(card,12); stroke(card,tCol,1,0.45)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0,3,1,0); bar.BackgroundColor3 = tCol; bar.BorderSizePixel = 0; bar.Parent = card
    corner(bar,2)

    local icoFrame = Instance.new("Frame")
    icoFrame.Size = UDim2.new(0,32,0,32); icoFrame.Position = UDim2.new(0,10,0.5,-16)
    icoFrame.BackgroundColor3 = tCol; icoFrame.BackgroundTransparency = 0.82; icoFrame.BorderSizePixel = 0; icoFrame.Parent = card
    corner(icoFrame,8)
    local ico = icon(icoFrame, icoId, 18, tCol)
    ico.Position = UDim2.new(0.5,-9,0.5,-9)

    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency=1; tl.Text=opts.Title or "HydrosolUI"
    tl.TextColor3=T.Text; tl.TextSize=13; tl.Font=Enum.Font.GothamBold
    tl.Size=UDim2.new(1,-52,0,20); tl.Position=UDim2.new(0,48,0,10)
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Parent=card

    local ml = Instance.new("TextLabel")
    ml.BackgroundTransparency=1; ml.Text=opts.Message or ""
    ml.TextColor3=T.TextSub; ml.TextSize=11; ml.Font=Enum.Font.Gotham
    ml.Size=UDim2.new(1,-52,0,30); ml.Position=UDim2.new(0,48,0,30)
    ml.TextXAlignment=Enum.TextXAlignment.Left; ml.TextWrapped=true; ml.Parent=card

    local prog = Instance.new("Frame")
    prog.Size=UDim2.new(1,0,0,2); prog.Position=UDim2.new(0,0,1,-2)
    prog.BackgroundColor3=tCol; prog.BorderSizePixel=0; prog.Parent=card
    local pGrad = Instance.new("UIGradient")
    pGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,T.AccentDim),ColorSequenceKeypoint.new(1,tCol)})
    pGrad.Parent = prog

    tw(card, TweenInfo.new(0.35,Enum.EasingStyle.Quint,Enum.EasingDirection.Out), {BackgroundTransparency=0.06})
    tw(prog, TweenInfo.new(dur,Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,0,2)})

    task.delay(dur, function()
        tw(card, TweenInfo.new(0.3,Enum.EasingStyle.Quint), {BackgroundTransparency=1, Position=UDim2.new(1,24,0,card.Position.Y.Offset)})
        task.delay(0.35, function() card:Destroy() end)
    end)
    return card
end

-- ─── HydrosolUI ───────────────────────────────────────────────────────────────
local HydrosolUI = {}
HydrosolUI.__index = HydrosolUI
HydrosolUI.Version = "1.1.0"
HydrosolUI.Theme   = T
HydrosolUI.Icons   = ICONS
HydrosolUI.Notify  = Notify

function HydrosolUI:CreateWindow(opts)
    opts = opts or {}
    local winTitle   = opts.Title      or "HydrosolUI"
    local winSize    = opts.Size       or UDim2.new(0,820,0,520)
    local saveFolder = opts.SaveFolder or (winTitle:gsub("%s+","").."Configs")
    local hideKey    = opts.ToggleKey  or Enum.KeyCode.RightAlt

    ensureNotify()

    local sg = Instance.new("ScreenGui")
    sg.Name = "Hydrosol_"..winTitle:gsub("%s+",""); sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.DisplayOrder=100
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

    pcall(function()
        local blur = Instance.new("BlurEffect"); blur.Size=0; blur.Parent=game:GetService("Lighting")
        tw(blur,TweenInfo.new(0.5),{Size=10})
        sg:GetPropertyChangedSignal("Parent"):Connect(function()
            if not sg.Parent then tw(blur,TweenInfo.new(0.4),{Size=0}); task.delay(0.5,function() blur:Destroy() end) end
        end)
    end)

    local shadow = Instance.new("Frame")
    shadow.AnchorPoint=Vector2.new(0.5,0.5); shadow.Position=UDim2.new(0.5,6,0.5,8)
    shadow.Size=winSize; shadow.BackgroundColor3=Color3.fromRGB(0,0,0)
    shadow.BackgroundTransparency=0.55; shadow.BorderSizePixel=0; shadow.Parent=sg
    corner(shadow,16)

    local shadow2 = Instance.new("Frame")
    shadow2.AnchorPoint=Vector2.new(0.5,0.5); shadow2.Position=UDim2.new(0.5,2,0.5,3)
    shadow2.Size=winSize; shadow2.BackgroundColor3=T.AccentDim
    shadow2.BackgroundTransparency=0.88; shadow2.BorderSizePixel=0; shadow2.Parent=sg
    corner(shadow2,14)

    local root = Instance.new("Frame")
    root.Name="Root"; root.AnchorPoint=Vector2.new(0.5,0.5)
    root.Position=UDim2.new(0.5,0,0.5,0); root.Size=winSize
    root.BackgroundColor3=T.Bg; root.BorderSizePixel=0; root.ClipsDescendants=true
    root.Parent=sg; corner(root,12)
    stroke(root, T.Border, 1, 0.35)

    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,  Color3.fromRGB(22,18,44)),
        ColorSequenceKeypoint.new(0.4,T.Bg),
        ColorSequenceKeypoint.new(1,  T.Bg),
    })
    bgGrad.Rotation = 125; bgGrad.Parent = root

    -- Title bar
    local tb = Instance.new("Frame")
    tb.Name="TitleBar"; tb.Size=UDim2.new(1,0,0,46)
    tb.BackgroundColor3=T.Surface; tb.BorderSizePixel=0; tb.Parent=root
    local tbGrad = Instance.new("UIGradient")
    tbGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(24,20,46)),ColorSequenceKeypoint.new(1,T.Surface)})
    tbGrad.Rotation=90; tbGrad.Parent=tb

    -- logo mark
    local logoWrap = Instance.new("Frame")
    logoWrap.Size=UDim2.new(0,28,0,28); logoWrap.Position=UDim2.new(0,12,0.5,-14)
    logoWrap.BackgroundColor3=T.Accent; logoWrap.BackgroundTransparency=0.75; logoWrap.BorderSizePixel=0; logoWrap.Parent=tb
    corner(logoWrap,8)
    stroke(logoWrap,T.Accent,1,0.4)
    local logoIco = icon(logoWrap, ICONS.diamond, 16, T.AccentGlow)
    logoIco.Position=UDim2.new(0.5,-8,0.5,-8)

    local winLbl = Instance.new("TextLabel")
    winLbl.BackgroundTransparency=1; winLbl.Text=winTitle
    winLbl.TextColor3=T.Text; winLbl.TextSize=14; winLbl.Font=Enum.Font.GothamBold
    winLbl.Position=UDim2.new(0,48,0,0); winLbl.Size=UDim2.new(0.5,0,1,0)
    winLbl.TextXAlignment=Enum.TextXAlignment.Left; winLbl.Parent=tb

    local vBadge = Instance.new("TextLabel")
    vBadge.BackgroundColor3=T.Elevated; vBadge.TextColor3=T.TextMuted
    vBadge.Text="v"..HydrosolUI.Version; vBadge.TextSize=9; vBadge.Font=Enum.Font.GothamMedium
    vBadge.Size=UDim2.new(0,36,0,16); vBadge.Position=UDim2.new(0,148,0.5,-8); vBadge.Parent=tb
    corner(vBadge,4); pad(vBadge,0,5,0,5)

    -- window controls
    local function winBtn(xOff, bgCol, icoId, icoCol)
        local b = Instance.new("TextButton")
        b.Size=UDim2.new(0,26,0,26); b.Position=UDim2.new(1,xOff,0.5,-13)
        b.BackgroundColor3=bgCol; b.BackgroundTransparency=0.5; b.Text=""
        b.BorderSizePixel=0; b.Parent=tb
        corner(b,7)
        local i = icon(b,icoId,14,icoCol)
        i.AnchorPoint=Vector2.new(0.5,0.5); i.Position=UDim2.new(0.5,0,0.5,0)
        b.MouseEnter:Connect(function() tw(b,TweenInfo.new(0.12),{BackgroundTransparency=0.1}) end)
        b.MouseLeave:Connect(function() tw(b,TweenInfo.new(0.12),{BackgroundTransparency=0.5}) end)
        return b, i
    end

    local closeBtn = winBtn(-34, Color3.fromRGB(80,28,36), ICONS.close, T.Error)
    local minBtn, minIco = winBtn(-66, T.Elevated, ICONS.minus, T.TextSub)

    closeBtn.MouseButton1Click:Connect(function()
        tw(root,   TweenInfo.new(0.32,Enum.EasingStyle.Quint),{Size=UDim2.new(0,winSize.X.Offset,0,0),BackgroundTransparency=1})
        tw(shadow, TweenInfo.new(0.32,Enum.EasingStyle.Quint),{Size=UDim2.new(0,winSize.X.Offset,0,0)})
        tw(shadow2,TweenInfo.new(0.32,Enum.EasingStyle.Quint),{Size=UDim2.new(0,winSize.X.Offset,0,0)})
        task.delay(0.38, function() sg:Destroy() end)
    end)

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        local target = minimized and UDim2.new(0,winSize.X.Offset,0,46) or winSize
        tw(root,   TweenInfo.new(0.38,Enum.EasingStyle.Quint),{Size=target})
        tw(shadow, TweenInfo.new(0.38,Enum.EasingStyle.Quint),{Size=target})
        tw(shadow2,TweenInfo.new(0.38,Enum.EasingStyle.Quint),{Size=target})
    end)

    -- drag
    local dragging, dragStart, startPos = false, nil, nil
    tb.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=i.Position; startPos=root.Position
        end
    end)
    tb.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    RunService.RenderStepped:Connect(function()
        if not dragging then return end
        local d = UserInputService:GetMouseLocation()-Vector2.new(dragStart.X,dragStart.Y)
        local np = UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        root.Position=np; shadow.Position=UDim2.new(np.X.Scale,np.X.Offset+6,np.Y.Scale,np.Y.Offset+8)
        shadow2.Position=UDim2.new(np.X.Scale,np.X.Offset+2,np.Y.Scale,np.Y.Offset+3)
    end)

    -- toggle visibility
    UserInputService.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode==hideKey then
            local v = not root.Visible
            root.Visible=v; shadow.Visible=v; shadow2.Visible=v
        end
    end)

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name="Sidebar"; sidebar.Size=UDim2.new(0,48,1,-46)
    sidebar.Position=UDim2.new(0,0,0,46); sidebar.BackgroundColor3=T.Surface
    sidebar.BorderSizePixel=0; sidebar.Parent=root
    local sideGrad = Instance.new("UIGradient")
    sideGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(18,16,36)),ColorSequenceKeypoint.new(1,T.Surface)})
    sideGrad.Rotation=90; sideGrad.Parent=sidebar
    local sideList = Instance.new("UIListLayout")
    sideList.SortOrder=Enum.SortOrder.LayoutOrder; sideList.HorizontalAlignment=Enum.HorizontalAlignment.Center
    sideList.Padding=UDim.new(0,4); sideList.Parent=sidebar
    pad(sidebar,10,0,10,0)

    -- sidebar bottom divider line
    local sdiv = Instance.new("Frame")
    sdiv.Size=UDim2.new(0,1,1,-46); sdiv.Position=UDim2.new(0,48,0,46)
    sdiv.BackgroundColor3=T.Border; sdiv.BackgroundTransparency=0.4; sdiv.BorderSizePixel=0; sdiv.Parent=root

    -- Content
    local content = Instance.new("Frame")
    content.Name="Content"; content.Size=UDim2.new(1,-48,1,-46)
    content.Position=UDim2.new(0,48,0,46); content.BackgroundTransparency=1
    content.ClipsDescendants=true; content.Parent=root

    -- Entrance anim
    root.Size=UDim2.new(0,winSize.X.Offset,0,0); root.BackgroundTransparency=1
    tw(root, TweenInfo.new(0.5,Enum.EasingStyle.Quint,Enum.EasingDirection.Out), {Size=winSize,BackgroundTransparency=0})
    shadow.Size=UDim2.new(0,winSize.X.Offset,0,0)
    tw(shadow, TweenInfo.new(0.5,Enum.EasingStyle.Quint,Enum.EasingDirection.Out), {Size=winSize})
    shadow2.Size=UDim2.new(0,winSize.X.Offset,0,0)
    tw(shadow2, TweenInfo.new(0.5,Enum.EasingStyle.Quint,Enum.EasingDirection.Out), {Size=winSize})

    local Window = { _tabs={}, _activeTab=nil, _sidebar=sidebar, _content=content, _root=root, _sg=sg }
    Window.SaveManager = SaveManager.new(saveFolder)
    Window.Notify = Notify

    function Window:AddTab(tabOpts)
        tabOpts = tabOpts or {}
        local tabName = tabOpts.Title or ("Tab "..#self._tabs+1)
        local tabIcoId = tabOpts.Icon or ICONS.layers

        -- sidebar button
        local sBtn = Instance.new("Frame")
        sBtn.Size=UDim2.new(0,36,0,36); sBtn.BackgroundColor3=T.Elevated
        sBtn.BackgroundTransparency=1; sBtn.BorderSizePixel=0
        sBtn.LayoutOrder=#self._tabs+1; sBtn.Parent=self._sidebar
        corner(sBtn,10)
        local sBtnIco = icon(sBtn, tabIcoId, 18, T.TextMuted)
        sBtnIco.AnchorPoint=Vector2.new(0.5,0.5); sBtnIco.Position=UDim2.new(0.5,0,0.5,0)
        local sBtnClick = Instance.new("TextButton")
        sBtnClick.Size=UDim2.new(1,0,1,0); sBtnClick.BackgroundTransparency=1
        sBtnClick.Text=""; sBtnClick.ZIndex=sBtn.ZIndex+1; sBtnClick.Parent=sBtn

        -- tooltip
        local tip = Instance.new("Frame")
        tip.BackgroundColor3=T.Elevated; tip.Size=UDim2.new(0,0,0,26)
        tip.Position=UDim2.new(1,8,0.5,-13); tip.AutomaticSize=Enum.AutomaticSize.X
        tip.Visible=false; tip.ZIndex=30; tip.ClipsDescendants=true; tip.Parent=sBtn
        corner(tip,7); stroke(tip,T.Border,1,0.5)
        pad(tip,0,10,0,10)
        local tipLbl = lbl(tip,tabName,11,T.Text,Enum.Font.GothamMedium)
        tipLbl.AutomaticSize=Enum.AutomaticSize.XY; tipLbl.Size=UDim2.new(0,0,0,26)
        tipLbl.TextYAlignment=Enum.TextYAlignment.Center; tipLbl.ZIndex=31

        sBtn.MouseEnter:Connect(function()
            tip.Visible=true
            tw(sBtn,TweenInfo.new(0.15),{BackgroundTransparency=0.55})
            tw(sBtnIco,TweenInfo.new(0.15),{ImageColor3=T.Text})
        end)
        sBtn.MouseLeave:Connect(function()
            tip.Visible=false
        end)

        -- page
        local page = Instance.new("ScrollingFrame")
        page.Name="Page_"..tabName; page.Size=UDim2.new(1,0,1,0)
        page.BackgroundTransparency=1; page.BorderSizePixel=0
        page.ScrollBarThickness=3; page.ScrollBarImageColor3=T.Accent
        page.ScrollBarImageTransparency=0.5; page.CanvasSize=UDim2.new(0,0,0,0)
        page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.Visible=false; page.Parent=self._content
        pad(page,12,12,12,12)

        local pageList = Instance.new("UIListLayout")
        pageList.SortOrder=Enum.SortOrder.LayoutOrder; pageList.Padding=UDim.new(0,0); pageList.Parent=page

        -- 2-column
        local colRow = Instance.new("Frame")
        colRow.Name="ColRow"; colRow.Size=UDim2.new(1,0,0,0); colRow.AutomaticSize=Enum.AutomaticSize.Y
        colRow.BackgroundTransparency=1; colRow.LayoutOrder=1; colRow.Parent=page
        local colLayout = Instance.new("UIListLayout")
        colLayout.FillDirection=Enum.FillDirection.Horizontal; colLayout.SortOrder=Enum.SortOrder.LayoutOrder
        colLayout.Padding=UDim.new(0,8); colLayout.Parent=colRow

        local colLeft = Instance.new("Frame"); colLeft.Name="L"; colLeft.Size=UDim2.new(0.5,-4,0,0)
        colLeft.AutomaticSize=Enum.AutomaticSize.Y; colLeft.BackgroundTransparency=1; colLeft.LayoutOrder=1; colLeft.Parent=colRow
        local llayout = Instance.new("UIListLayout"); llayout.SortOrder=Enum.SortOrder.LayoutOrder; llayout.Padding=UDim.new(0,7); llayout.Parent=colLeft

        local colRight = Instance.new("Frame"); colRight.Name="R"; colRight.Size=UDim2.new(0.5,-4,0,0)
        colRight.AutomaticSize=Enum.AutomaticSize.Y; colRight.BackgroundTransparency=1; colRight.LayoutOrder=2; colRight.Parent=colRow
        local rlayout = Instance.new("UIListLayout"); rlayout.SortOrder=Enum.SortOrder.LayoutOrder; rlayout.Padding=UDim.new(0,7); rlayout.Parent=colRight

        local Tab = { _page=page, _colLeft=colLeft, _colRight=colRight, _ctr={l=0,r=0}, _sBtn=sBtn, _sBtnIco=sBtnIco, _window=self }

        function Tab:_nextCol()
            if self._ctr.l<=self._ctr.r then self._ctr.l=self._ctr.l+1; return self._colLeft,self._ctr.l
            else self._ctr.r=self._ctr.r+1; return self._colRight,self._ctr.r end
        end
        function Tab:_col(s)
            if s=="right" then self._ctr.r=self._ctr.r+1; return self._colRight,self._ctr.r
            else self._ctr.l=self._ctr.l+1; return self._colLeft,self._ctr.l end
        end

        -- section builder
        local function mkSec(parent, order, title, secIcon)
            local sec = Instance.new("Frame")
            sec.Name="Sec_"..(title or ""); sec.Size=UDim2.new(1,0,0,0); sec.AutomaticSize=Enum.AutomaticSize.Y
            sec.BackgroundColor3=T.Surface; sec.BackgroundTransparency=0.15; sec.BorderSizePixel=0
            sec.LayoutOrder=order; sec.Parent=parent
            corner(sec,12); stroke(sec,T.Border,1,0.5)

            local secList = Instance.new("UIListLayout"); secList.SortOrder=Enum.SortOrder.LayoutOrder; secList.Padding=UDim.new(0,0); secList.Parent=sec

            if title and title~="" then
                local hdr = Instance.new("Frame")
                hdr.Size=UDim2.new(1,0,0,34); hdr.BackgroundColor3=T.Elevated
                hdr.BackgroundTransparency=0.2; hdr.BorderSizePixel=0; hdr.LayoutOrder=0; hdr.Parent=sec
                local hGrad = Instance.new("UIGradient")
                hGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(28,24,52)),ColorSequenceKeypoint.new(1,T.Elevated)})
                hGrad.Rotation=90; hGrad.Parent=hdr
                corner(hdr,12)
                -- flatten bottom corners
                local flat = Instance.new("Frame"); flat.Size=UDim2.new(1,0,0.5,0); flat.Position=UDim2.new(0,0,0.5,0)
                flat.BackgroundColor3=T.Elevated; flat.BackgroundTransparency=0.2; flat.BorderSizePixel=0; flat.Parent=hdr

                if secIcon then
                    local si = icon(hdr,secIcon,14,T.Accent); si.Position=UDim2.new(0,10,0.5,-7)
                end
                local hl = lbl(hdr,title,11,T.TextSub,Enum.Font.GothamBold)
                hl.Size=UDim2.new(1,-22,1,0); hl.Position=UDim2.new(0,(secIcon and 28 or 10),0,0)
                hl.AutomaticSize=Enum.AutomaticSize.None; hl.TextYAlignment=Enum.TextYAlignment.Center

                local accentBar = Instance.new("Frame")
                accentBar.Size=UDim2.new(0,2,0,14); accentBar.AnchorPoint=Vector2.new(0,0.5)
                accentBar.Position=UDim2.new(0,(secIcon and 24 or 6),0.5,0)
                accentBar.BackgroundColor3=T.Accent; accentBar.BorderSizePixel=0; accentBar.Parent=hdr
                corner(accentBar,1)
            end

            local body = Instance.new("Frame"); body.Name="Body"; body.Size=UDim2.new(1,0,0,0)
            body.AutomaticSize=Enum.AutomaticSize.Y; body.BackgroundTransparency=1; body.LayoutOrder=1; body.Parent=sec
            local bodyList = Instance.new("UIListLayout"); bodyList.SortOrder=Enum.SortOrder.LayoutOrder; bodyList.Padding=UDim.new(0,0); bodyList.Parent=body
            return body, sec
        end

        -- row builder
        local function mkRow(parent, order, h)
            h = h or 40
            local row = Instance.new("Frame")
            row.Size=UDim2.new(1,0,0,h); row.BackgroundColor3=T.SurfaceAlt
            row.BackgroundTransparency=0.65; row.BorderSizePixel=0; row.LayoutOrder=order; row.Parent=parent
            pad(row,0,12,0,12)
            local div = Instance.new("Frame"); div.Size=UDim2.new(1,0,0,1)
            div.BackgroundColor3=T.Border; div.BackgroundTransparency=0.78; div.BorderSizePixel=0; div.ZIndex=row.ZIndex; div.Parent=row
            row.MouseEnter:Connect(function() tw(row,TweenInfo.new(0.1),{BackgroundTransparency=0.35}) end)
            row.MouseLeave:Connect(function() tw(row,TweenInfo.new(0.1),{BackgroundTransparency=0.65}) end)
            return row
        end

        function Tab:AddSection(sOpts)
            sOpts = sOpts or {}
            local side = sOpts.Side or "auto"
            local col, order = (side=="auto") and self:_nextCol() or self:_col(side)
            local body, sec = mkSec(col, order, sOpts.Title, sOpts.Icon)
            local Section = { _body=body, _sec=sec, _n=0, _tab=self }

            function Section:AddParagraph(o)
                o = o or {}; self._n=self._n+1
                local row = mkRow(self._body,self._n,nil)
                row.AutomaticSize=Enum.AutomaticSize.Y; row.Size=UDim2.new(1,0,0,0)
                local inner = Instance.new("Frame"); inner.BackgroundTransparency=1
                inner.Size=UDim2.new(1,0,0,0); inner.AutomaticSize=Enum.AutomaticSize.Y; inner.Parent=row
                pad(inner,7,0,7,0)
                local iList = Instance.new("UIListLayout"); iList.SortOrder=Enum.SortOrder.LayoutOrder; iList.Padding=UDim.new(0,3); iList.Parent=inner
                local tl = lbl(inner,o.Title or "",12,T.TextSub,Enum.Font.GothamBold); tl.LayoutOrder=1
                local bl = lbl(inner,o.Content or "",11,T.TextMuted,Enum.Font.Gotham); bl.LayoutOrder=2
                local P = {}
                function P:Set(t,c) if t~=nil then tl.Text=t end; if c~=nil then bl.Text=c end end
                function P:SetTitle(t) tl.Text=t end
                function P:SetContent(c) bl.Text=c end
                return P
            end

            function Section:AddButton(o)
                o = o or {}; self._n=self._n+1
                local row = mkRow(self._body,self._n,40)
                if o.Icon then
                    local bi = icon(row,o.Icon,15,T.TextSub); bi.Position=UDim2.new(0,0,0.5,-7)
                end
                local offset = o.Icon and 20 or 0
                local l = lbl(row,o.Title or "Button",12,T.Text)
                l.Position=UDim2.new(0,offset,0,0); l.Size=UDim2.new(0.6,-offset,1,0)
                l.AutomaticSize=Enum.AutomaticSize.None; l.TextYAlignment=Enum.TextYAlignment.Center

                local btn = Instance.new("TextButton")
                btn.Size=UDim2.new(0,76,0,26); btn.Position=UDim2.new(1,-76,0.5,-13)
                btn.BackgroundColor3=T.Accent; btn.Text=o.BtnText or "Run"
                btn.TextColor3=Color3.fromRGB(255,255,255); btn.TextSize=11; btn.Font=Enum.Font.GothamBold
                btn.BorderSizePixel=0; btn.Parent=row; corner(btn,7)
                local bGrad = Instance.new("UIGradient")
                bGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,T.AccentGlow),ColorSequenceKeypoint.new(1,T.AccentDim)})
                bGrad.Rotation=90; bGrad.Parent=btn

                btn.MouseEnter:Connect(function() tw(btn,TweenInfo.new(0.12),{BackgroundColor3=T.AccentDim}) end)
                btn.MouseLeave:Connect(function() tw(btn,TweenInfo.new(0.12),{BackgroundColor3=T.Accent}) end)
                btn.MouseButton1Click:Connect(function()
                    tw(btn,TweenInfo.new(0.06),{BackgroundColor3=T.AccentGlow})
                    task.delay(0.06,function() tw(btn,TweenInfo.new(0.18),{BackgroundColor3=T.Accent}) end)
                    if o.Callback then pcall(o.Callback) end
                end)
                return btn
            end

            function Section:AddToggle(o)
                o = o or {}; self._n=self._n+1
                local row = mkRow(self._body,self._n,40)
                if o.Icon then local ti=icon(row,o.Icon,15,T.TextSub); ti.Position=UDim2.new(0,0,0.5,-7) end
                local offset = o.Icon and 20 or 0
                local l = lbl(row,o.Title or "Toggle",12,T.Text)
                l.Position=UDim2.new(0,offset,0,0); l.Size=UDim2.new(0.72,-offset,1,0)
                l.AutomaticSize=Enum.AutomaticSize.None; l.TextYAlignment=Enum.TextYAlignment.Center

                local state = o.Default or false
                local track = Instance.new("Frame"); track.Size=UDim2.new(0,44,0,24); track.Position=UDim2.new(1,-44,0.5,-12)
                track.BackgroundColor3=state and T.Accent or T.ToggleOff; track.BorderSizePixel=0; track.Parent=row; corner(track,12)

                local trackGrad = Instance.new("UIGradient")
                trackGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,T.AccentGlow),ColorSequenceKeypoint.new(1,T.Accent)})
                trackGrad.Parent=track; trackGrad.Enabled=state

                local thumb = Instance.new("Frame")
                thumb.Size=UDim2.new(0,18,0,18); thumb.Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
                thumb.BackgroundColor3=Color3.fromRGB(255,255,255); thumb.BorderSizePixel=0; thumb.Parent=track; corner(thumb,9)
                stroke(thumb,Color3.fromRGB(200,200,220),1,0.7)

                local ca = Instance.new("TextButton"); ca.Size=UDim2.new(1,0,1,0); ca.BackgroundTransparency=1; ca.Text=""; ca.Parent=row
                local Tgl = { Value=state }

                local function setState(v, silent)
                    state=v; Tgl.Value=v
                    tw(track,TweenInfo.new(0.22,Enum.EasingStyle.Quint),{BackgroundColor3=v and T.Accent or T.ToggleOff})
                    tw(thumb,TweenInfo.new(0.22,Enum.EasingStyle.Quint),{Position=v and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)})
                    trackGrad.Enabled=v
                    if not silent and o.Callback then pcall(o.Callback,v) end
                end

                ca.MouseButton1Click:Connect(function() setState(not state) end)
                function Tgl:Set(v) setState(v,true) end

                if o.Flag and Tab._window.SaveManager then
                    Tab._window.SaveManager:AddFlag(o.Flag,function() return Tgl.Value end)
                end
                return Tgl
            end

            function Section:AddSlider(o)
                o = o or {}; self._n=self._n+1
                local row = mkRow(self._body,self._n,50)
                local minV,maxV,dp = o.Min or 0, o.Max or 100, o.Decimals or 0
                local sfx = o.Suffix or ""
                local cur = math.clamp(o.Default or minV, minV, maxV)

                if o.Icon then local si=icon(row,o.Icon,15,T.TextSub); si.Position=UDim2.new(0,0,0,8) end
                local offset = o.Icon and 20 or 0
                local l = lbl(row,o.Title or "Slider",12,T.Text)
                l.Position=UDim2.new(0,offset,0,5); l.Size=UDim2.new(0.68,-offset,0,18); l.AutomaticSize=Enum.AutomaticSize.None

                local vl = Instance.new("TextLabel"); vl.BackgroundTransparency=1
                vl.Text=round(cur,dp)..sfx; vl.TextColor3=T.Accent; vl.TextSize=12; vl.Font=Enum.Font.GothamBold
                vl.Size=UDim2.new(0.32,0,0,18); vl.Position=UDim2.new(0.68,0,0,5)
                vl.TextXAlignment=Enum.TextXAlignment.Right; vl.Parent=row

                local tf = Instance.new("Frame"); tf.Size=UDim2.new(1,0,0,6); tf.Position=UDim2.new(0,0,1,-14)
                tf.BackgroundColor3=T.TrackBg; tf.BorderSizePixel=0; tf.Parent=row; corner(tf,3)

                local fill = Instance.new("Frame"); fill.Size=UDim2.new((cur-minV)/(maxV-minV),0,1,0)
                fill.BackgroundColor3=T.Accent; fill.BorderSizePixel=0; fill.Parent=tf; corner(fill,3)
                local fGrad=Instance.new("UIGradient"); fGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,T.AccentDim),ColorSequenceKeypoint.new(1,T.AccentGlow)}); fGrad.Parent=fill

                local thm = Instance.new("Frame"); thm.Size=UDim2.new(0,14,0,14); thm.AnchorPoint=Vector2.new(0.5,0.5)
                thm.Position=UDim2.new((cur-minV)/(maxV-minV),0,0.5,0); thm.BackgroundColor3=Color3.fromRGB(255,255,255)
                thm.BorderSizePixel=0; thm.ZIndex=tf.ZIndex+1; thm.Parent=tf; corner(thm,7)
                stroke(thm,T.Accent,1.5,0.4)

                local draggingS=false; local Sld={Value=cur}
                local function setS(v,silent)
                    v=math.clamp(round(v,dp),minV,maxV); cur=v; Sld.Value=v
                    local p=(v-minV)/(maxV-minV)
                    tw(fill,TweenInfo.new(0.04),{Size=UDim2.new(p,0,1,0)})
                    tw(thm,TweenInfo.new(0.04),{Position=UDim2.new(p,0,0.5,0)})
                    vl.Text=round(v,dp)..sfx
                    if not silent and o.Callback then pcall(o.Callback,v) end
                end
                local function fromMouse()
                    local mx=UserInputService:GetMouseLocation(); local ta=tf.AbsolutePosition; local ts=tf.AbsoluteSize
                    setS(minV+math.clamp((mx.X-ta.X)/ts.X,0,1)*(maxV-minV))
                end
                tf.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then draggingS=true; fromMouse() end end)
                UserInputService.InputChanged:Connect(function(i) if draggingS and i.UserInputType==Enum.UserInputType.MouseMovement then fromMouse() end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then draggingS=false end end)
                function Sld:Set(v) setS(v,true) end
                if o.Flag and Tab._window.SaveManager then Tab._window.SaveManager:AddFlag(o.Flag,function() return Sld.Value end) end
                return Sld
            end

            local function buildDrop(o, multi)
                o = o or {}; self._n=self._n+1
                local row = mkRow(self._body,self._n,40)
                if o.Icon then local di=icon(row,o.Icon,15,T.TextSub); di.Position=UDim2.new(0,0,0.5,-7) end
                local offset = o.Icon and 20 or 0
                local l = lbl(row,o.Title or "Dropdown",12,T.Text)
                l.Position=UDim2.new(0,offset,0,0); l.Size=UDim2.new(0.44,-offset,1,0)
                l.AutomaticSize=Enum.AutomaticSize.None; l.TextYAlignment=Enum.TextYAlignment.Center

                local opts = o.Options or {}
                local selected = multi and {} or (o.Default or opts[1] or "None")
                if multi and o.Default then for _,v in ipairs(o.Default) do selected[v]=true end end

                local disp = Instance.new("TextButton"); disp.Size=UDim2.new(0.56,-4,0,28); disp.Position=UDim2.new(0.44,4,0.5,-14)
                disp.BackgroundColor3=T.Elevated; disp.BorderSizePixel=0; disp.Font=Enum.Font.GothamMedium; disp.TextSize=11
                disp.TextColor3=T.TextSub; disp.TextXAlignment=Enum.TextXAlignment.Left; disp.ClipsDescendants=true; disp.Parent=row
                corner(disp,8); pad(disp,0,26,0,10); stroke(disp,T.Border,1,0.45)

                local chevIco = icon(disp, ICONS.chevDown, 12, T.TextMuted)
                chevIco.AnchorPoint=Vector2.new(1,0.5); chevIco.Position=UDim2.new(1,-4,0.5,0)

                local function refreshDisp()
                    if multi then
                        local s={}; for k,v in pairs(selected) do if v then table.insert(s,k) end end
                        disp.Text=#s==0 and "None" or table.concat(s,", ")
                    else disp.Text=tostring(selected) end
                end
                refreshDisp()

                local open=false
                local panel=Instance.new("Frame"); panel.BackgroundColor3=T.Elevated; panel.Size=UDim2.new(0,200,0,0)
                panel.BackgroundTransparency=0.04; panel.Visible=false; panel.ZIndex=60; panel.Parent=sg
                corner(panel,10); stroke(panel,T.Border,1,0.35)

                local searchRow=Instance.new("Frame"); searchRow.Size=UDim2.new(1,-12,0,30); searchRow.Position=UDim2.new(0,6,0,6)
                searchRow.BackgroundColor3=T.Surface; searchRow.BorderSizePixel=0; searchRow.ZIndex=61; searchRow.Parent=panel
                corner(searchRow,7); stroke(searchRow,T.Border,1,0.5)
                local sIcoImg=icon(searchRow,ICONS.search,14,T.TextMuted); sIcoImg.Position=UDim2.new(0,8,0.5,-7); sIcoImg.ZIndex=62
                local sBox=Instance.new("TextBox"); sBox.Size=UDim2.new(1,-32,1,0); sBox.Position=UDim2.new(0,28,0,0)
                sBox.BackgroundTransparency=1; sBox.Text=""; sBox.PlaceholderText="Search..."; sBox.PlaceholderColor3=T.TextMuted
                sBox.TextColor3=T.Text; sBox.TextSize=11; sBox.Font=Enum.Font.Gotham; sBox.ClearTextOnFocus=false
                sBox.ZIndex=62; sBox.Parent=searchRow

                local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-8,0,0); scroll.Position=UDim2.new(0,4,0,42)
                scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=2
                scroll.ScrollBarImageColor3=T.Accent; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
                scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.ZIndex=61; scroll.Parent=panel
                local sl=Instance.new("UIListLayout"); sl.SortOrder=Enum.SortOrder.LayoutOrder; sl.Padding=UDim.new(0,2); sl.Parent=scroll

                local Drop={Value=selected}; local itemRefs={}

                local function mkItem(opt)
                    local itm=Instance.new("TextButton"); itm.Size=UDim2.new(1,0,0,30); itm.BackgroundColor3=T.SurfaceAlt
                    itm.BackgroundTransparency=0.55; itm.Text=tostring(opt); itm.TextColor3=T.TextSub; itm.TextSize=11
                    itm.Font=Enum.Font.GothamMedium; itm.TextXAlignment=Enum.TextXAlignment.Left
                    itm.BorderSizePixel=0; itm.ZIndex=62; itm.Parent=scroll; corner(itm,6); pad(itm,0,0,0,10)
                    local chkIco=icon(itm,ICONS.check,12,T.Accent); chkIco.AnchorPoint=Vector2.new(1,0.5)
                    chkIco.Position=UDim2.new(1,-8,0.5,0); chkIco.ZIndex=63; chkIco.Visible=false

                    local function refChk()
                        local sel = multi and selected[opt] or (selected==opt)
                        chkIco.Visible=sel; itm.TextColor3=sel and T.Text or T.TextSub
                        itm.BackgroundColor3=sel and T.Elevated or T.SurfaceAlt
                    end
                    refChk()
                    itm.MouseButton1Click:Connect(function()
                        if multi then selected[opt]=not selected[opt] else selected=opt end
                        Drop.Value=selected; refChk(); refreshDisp()
                        if o.Callback then pcall(o.Callback,selected) end
                        if not multi then open=false; tw(panel,TweenInfo.new(0.18,Enum.EasingStyle.Quint),{Size=UDim2.new(0,panel.AbsoluteSize.X,0,0)}); tw(chevIco,TweenInfo.new(0.15),{Rotation=0}); task.delay(0.2,function() panel.Visible=false end) end
                    end)
                    itm.MouseEnter:Connect(function() tw(itm,TweenInfo.new(0.08),{BackgroundTransparency=0.25}) end)
                    itm.MouseLeave:Connect(function() tw(itm,TweenInfo.new(0.08),{BackgroundTransparency=0.55}) end)
                    return itm, refChk
                end

                for _,o2 in ipairs(opts) do local i,r=mkItem(o2); table.insert(itemRefs,{btn=i,text=tostring(o2),refresh=r}) end

                sBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local q=sBox.Text:lower()
                    for _,r in ipairs(itemRefs) do r.btn.Visible=(q=="" or r.text:lower():find(q,1,true)~=nil) end
                end)

                local function openP()
                    local a=disp.AbsolutePosition; local s=disp.AbsoluteSize
                    local mh=math.min(#opts*32+50,210)
                    panel.Position=UDim2.new(0,a.X,0,a.Y+s.Y+4); panel.Size=UDim2.new(0,s.X,0,0)
                    scroll.Size=UDim2.new(1,-8,0,mh-48); panel.Visible=true
                    tw(panel,TweenInfo.new(0.22,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,s.X,0,mh)})
                    tw(chevIco,TweenInfo.new(0.15),{Rotation=180})
                end
                local function closeP()
                    tw(panel,TweenInfo.new(0.18,Enum.EasingStyle.Quint),{Size=UDim2.new(0,panel.AbsoluteSize.X,0,0)})
                    tw(chevIco,TweenInfo.new(0.15),{Rotation=0})
                    task.delay(0.2,function() panel.Visible=false end)
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
                    for _,o2 in ipairs(newOpts) do local i,r=mkItem(o2); table.insert(itemRefs,{btn=i,text=tostring(o2),refresh=r}) end
                end
                if o.Flag and Tab._window.SaveManager then Tab._window.SaveManager:AddFlag(o.Flag,function() return Drop.Value end) end
                return Drop
            end

            function Section:AddDropdown(o) return buildDrop(o,false) end
            function Section:AddMultiDropdown(o) return buildDrop(o,true) end

            function Section:AddKeybind(o)
                o = o or {}; self._n=self._n+1
                local row = mkRow(self._body,self._n,40)
                if o.Icon then local ki=icon(row,o.Icon,15,T.TextSub); ki.Position=UDim2.new(0,0,0.5,-7) end
                local offset = o.Icon and 20 or 0
                local l=lbl(row,o.Title or "Keybind",12,T.Text)
                l.Position=UDim2.new(0,offset,0,0); l.Size=UDim2.new(0.55,-offset,1,0)
                l.AutomaticSize=Enum.AutomaticSize.None; l.TextYAlignment=Enum.TextYAlignment.Center

                local key = o.Default or Enum.KeyCode.Unknown; local listening=false
                local kBtn=Instance.new("TextButton"); kBtn.Size=UDim2.new(0,86,0,26); kBtn.Position=UDim2.new(1,-86,0.5,-13)
                kBtn.BackgroundColor3=T.Elevated; kBtn.Text=key.Name; kBtn.TextColor3=T.Accent; kBtn.TextSize=11
                kBtn.Font=Enum.Font.GothamBold; kBtn.BorderSizePixel=0; kBtn.Parent=row; corner(kBtn,7)
                stroke(kBtn,T.Accent,1,0.55); pad(kBtn,0,8,0,8)

                local kbdIco=icon(kBtn,ICONS.keyboard,12,T.AccentGlow)
                kbdIco.Position=UDim2.new(0,4,0.5,-6)

                local Kb={Value=key}
                kBtn.MouseButton1Click:Connect(function()
                    listening=true; kBtn.Text="  . . ."; tw(kBtn,TweenInfo.new(0.1),{BackgroundColor3=T.AccentDim})
                end)
                UserInputService.InputBegan:Connect(function(i,gp)
                    if not listening then
                        if i.KeyCode==key and not gp then if o.Callback then pcall(o.Callback,key) end end; return
                    end
                    if i.UserInputType==Enum.UserInputType.Keyboard then
                        listening=false; key=i.KeyCode; Kb.Value=key; kBtn.Text=key.Name
                        tw(kBtn,TweenInfo.new(0.1),{BackgroundColor3=T.Elevated})
                        if o.Changed then pcall(o.Changed,key) end
                    end
                end)
                function Kb:Set(k) key=k; Kb.Value=k; kBtn.Text=k.Name end
                if o.Flag and Tab._window.SaveManager then Tab._window.SaveManager:AddFlag(o.Flag,function() return Kb.Value.Name end) end
                return Kb
            end

            function Section:AddInput(o)
                o = o or {}; self._n=self._n+1
                local row = mkRow(self._body,self._n,40)
                if o.Icon then local ii=icon(row,o.Icon,15,T.TextSub); ii.Position=UDim2.new(0,0,0.5,-7) end
                local offset = o.Icon and 20 or 0
                local l=lbl(row,o.Title or "Input",12,T.Text)
                l.Position=UDim2.new(0,offset,0,0); l.Size=UDim2.new(0.38,-offset,1,0)
                l.AutomaticSize=Enum.AutomaticSize.None; l.TextYAlignment=Enum.TextYAlignment.Center

                local box=Instance.new("TextBox"); box.Size=UDim2.new(0.62,-4,0,28); box.Position=UDim2.new(0.38,4,0.5,-14)
                box.BackgroundColor3=T.Elevated; box.BorderSizePixel=0; box.Text=o.Default or ""
                box.PlaceholderText=o.Placeholder or "..."; box.PlaceholderColor3=T.TextMuted
                box.TextColor3=T.Text; box.TextSize=11; box.Font=Enum.Font.Gotham
                box.ClearTextOnFocus=o.ClearOnFocus~=false; box.Parent=row; corner(box,8); pad(box,0,8,0,8)
                stroke(box,T.Border,1,0.5)

                box.Focused:Connect(function() tw(box,TweenInfo.new(0.15),{BackgroundColor3=T.SurfaceAlt}) end)
                box.FocusLost:Connect(function(enter)
                    tw(box,TweenInfo.new(0.15),{BackgroundColor3=T.Elevated})
                    if o.Callback then pcall(o.Callback,box.Text,enter) end
                end)
                local Inp={Value=box.Text}
                box:GetPropertyChangedSignal("Text"):Connect(function() Inp.Value=box.Text; if o.Changed then pcall(o.Changed,box.Text) end end)
                function Inp:Set(v) box.Text=tostring(v) end
                if o.Flag and Tab._window.SaveManager then Tab._window.SaveManager:AddFlag(o.Flag,function() return Inp.Value end) end
                return Inp
            end

            function Section:AddLabel(o)
                o = o or {}; self._n=self._n+1
                local row = mkRow(self._body,self._n,34)
                row.AutomaticSize=Enum.AutomaticSize.Y; row.Size=UDim2.new(1,0,0,34)
                local l=lbl(row,o.Text or "",11,T.TextSub,Enum.Font.Gotham)
                l.Position=UDim2.new(0,0,0,0); l.Size=UDim2.new(1,0,1,0); l.AutomaticSize=Enum.AutomaticSize.None; l.TextYAlignment=Enum.TextYAlignment.Center
                local L={}; function L:Set(t) l.Text=t end; return L
            end

            return Section
        end

        sBtnClick.MouseButton1Click:Connect(function() self:_setActive(Tab) end)
        table.insert(self._tabs,Tab)
        if #self._tabs==1 then self:_setActive(Tab) end
        return Tab
    end

    function Window:_setActive(tab)
        for _,t in ipairs(self._tabs) do
            t._page.Visible=false
            tw(t._sBtn,TweenInfo.new(0.15),{BackgroundTransparency=1})
            tw(t._sBtnIco,TweenInfo.new(0.15),{ImageColor3=T.TextMuted})
        end
        tab._page.Visible=true; self._activeTab=tab
        tw(tab._sBtn,TweenInfo.new(0.18),{BackgroundTransparency=0.45})
        tw(tab._sBtnIco,TweenInfo.new(0.18),{ImageColor3=T.AccentGlow})

        if self._sideInd then self._sideInd:Destroy() end
        local ind=Instance.new("Frame"); ind.Size=UDim2.new(0,3,0,22); ind.AnchorPoint=Vector2.new(0,0.5)
        ind.Position=UDim2.new(0,0,0,tab._sBtn.AbsolutePosition.Y-self._sidebar.AbsolutePosition.Y+18)
        ind.BackgroundColor3=T.Accent; ind.BorderSizePixel=0; ind.ZIndex=6; ind.Parent=self._sidebar; corner(ind,2)
        local indGrad=Instance.new("UIGradient"); indGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,T.AccentGlow),ColorSequenceKeypoint.new(1,T.Accent)}); indGrad.Rotation=90; indGrad.Parent=ind
        self._sideInd=ind
    end

    return Window
end

return HydrosolUI
