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

local _iconCache={}
local function resolveIconImage(id)
    if type(id)~="string" then return id end
    if not id:match("^https?://") then return id end
    if _iconCache[id] then return _iconCache[id] end

    -- Fallback: if ImageLabel can't load remote https image in your environment,
    -- we fetch bytes and convert to data URI (base64).
    local ok, body = pcall(function()
        return game:HttpGet(id)
    end)
    if not ok or type(body)~="string" or body=="" then
        _iconCache[id]=id
        return id
    end

    local ok2, b64 = pcall(function()
        return HttpService:Base64Encode(body)
    end)
    if not ok2 or type(b64)~="string" or b64=="" then
        _iconCache[id]=id
        return id
    end

    local dataUri = "data:image/png;base64,"..b64
    _iconCache[id]=dataUri
    return dataUri
end

local function mkCorner(p, r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 6); c.Parent=p; return c
end
local function mkPad(p, t, r, b, l)
    local x=Instance.new("UIPadding")
    x.PaddingTop=UDim.new(0,t or 0); x.PaddingRight=UDim.new(0,r or 0)
    x.PaddingBottom=UDim.new(0,b or 0); x.PaddingLeft=UDim.new(0,l or 0)
    x.Parent=p; return x
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
    if id then
        i.Image=resolveIconImage(id)
        i.ImageColor3=col or Color3.fromRGB(140,138,168)
        i.Visible=true
    else
        -- No icon provided: keep object invisible to preserve layout safety.
        i.Image=""
        i.ImageColor3=col or Color3.fromRGB(140,138,168)
        i.Visible=false
    end
    i.Size=UDim2.new(0,sz or 16,0,sz or 16)
    i.ScaleType=Enum.ScaleType.Fit; i.Parent=p
    i.ImageTransparency=0
    -- Ensure icons render above underlying labels/buttons.
    i.ZIndex=((p and p.ZIndex) or 0) + 2
    return i
end

-- ── Theme (ImguiMenu-faithful) ────────────────────────
local T = {
    Win        = Color3.fromRGB(25, 25, 32),
    Bar        = Color3.fromRGB(17, 17, 22),
    Child      = Color3.fromRGB(20, 20, 27),
    ChildBdr   = Color3.fromRGB(25, 25, 33),
    Line       = Color3.fromRGB(54, 55, 66),
    Accent     = Color3.fromRGB(103, 100, 255),
    AccentDim  = Color3.fromRGB(66,  60, 180),
    AccentHi   = Color3.fromRGB(148, 140, 255),
    WdgBg      = Color3.fromRGB(28, 28, 39),
    WdgActive  = Color3.fromRGB(35, 35, 46),
    WdgInact   = Color3.fromRGB(47, 47, 63),
    Text       = Color3.fromRGB(255, 255, 255),
    TextInact  = Color3.fromRGB(86,  85, 106),
    TextSub    = Color3.fromRGB(130, 128, 160),
    Success    = Color3.fromRGB(68,  218, 134),
    Warning    = Color3.fromRGB(255, 196, 68),
    Error      = Color3.fromRGB(255, 78,  78),
    Notify     = Color3.fromRGB(20,  20,  27),
}

-- Icons are optional.
-- Your current environment can easily break asset rendering (assetid blocked/missing),
-- so we keep the API but ship with an empty icon map.
-- Icons via web API (Iconify) so we don't depend on Roblox asset ids.
-- Notes:
-- - Roblox ImageLabel can render `https://...png` directly.
-- - We keep icons monochrome (white) and recolor them using `ImageColor3`.
local I = (function()
    local base="https://api.iconify.design"
    local function url(provider, name)
        -- Use png to avoid SVG parsing (Roblox ImageLabel doesn't support SVG).
        return base.."/"..provider.."/"..name..".png?width=24&height=24&color=%23FFFFFF"
    end
    return {
        -- window controls
        close    = url("lucide","x"),
        minus    = url("lucide","minus"),
        chevDown = url("lucide","chevron-down"),
        check    = url("lucide","check"),

        search   = url("lucide","search"),
        keyboard = url("lucide","keyboard"),
        info     = url("lucide","info"),
        warning  = url("lucide","alert-triangle"),

        success  = url("lucide","check-circle"),
        error    = url("lucide","x-circle"),

        eye      = url("lucide","eye"),
        shield   = url("lucide","shield"),

        -- demo UI icons
        sword    = url("lucide","sword"),
        bolt     = url("lucide","bolt"),
        user     = url("lucide","user"),
        save     = url("lucide","save"),
        folder   = url("lucide","folder"),
        refresh  = url("lucide","refresh-cw"),
        lock     = url("lucide","lock"),
        layers   = url("lucide","layers"),
        sliders  = url("lucide","sliders-horizontal"),
        terminal = url("lucide","terminal"),
        target   = url("lucide","target"),
        fire     = url("lucide","fire"),
        diamond  = url("lucide","gem"),
        globe    = url("lucide","globe"),
        cursor   = url("lucide","mouse-pointer"),
        settings = url("lucide","settings"),
        home     = url("lucide","home"),
        star     = url("lucide","star"),
        grid     = url("lucide","grid"),
        cpu      = url("lucide","cpu"),
        chart    = url("lucide","bar-chart-2"),
    }
end)()

-- ── SaveManager ───────────────────────────────────────
local SaveManager = {}
SaveManager.__index = SaveManager
function SaveManager.new(folder)
    local s=setmetatable({},SaveManager)
    s.folder=folder or "HydrosolUI"; s.autoFile="autoload"
    s._data={}; s._flags={}
    if not isfolder(s.folder) then makefolder(s.folder) end
    return s
end
function SaveManager:_path(n) return self.folder.."/"..n..".json" end
function SaveManager:AddFlag(f,g) self._flags[f]=g end
function SaveManager:_collect()
    local o={}
    for f,g in pairs(self._flags) do local ok,v=pcall(g); if ok then o[f]=v end end
    return o
end
function SaveManager:Save(n)
    n=n or "default"
    return pcall(writefile,self:_path(n),HttpService:JSONEncode(self:_collect()))
end
function SaveManager:Load(n)
    n=n or "default"; local p=self:_path(n)
    if not isfile(p) then return false,"not found" end
    local ok,raw=pcall(readfile,p); if not ok then return false,raw end
    local ok2,data=pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 then return false,data end
    self._data=data; return true,data
end
function SaveManager:SetAutoload(n) return pcall(writefile,self:_path(self.autoFile),n) end
function SaveManager:LoadAutoloadConfig()
    local p=self:_path(self.autoFile); if not isfile(p) then return false end
    local ok,n=pcall(readfile,p); if not ok or n=="" then return false end
    return self:Load(n)
end
function SaveManager:GetValue(f) return self._data[f] end
function SaveManager:ListConfigs()
    local out={}
    for _,f in ipairs(listfiles(self.folder)) do
        local n=f:match("[^/\\]+$"):gsub("%.json$","")
        if n~=self.autoFile then table.insert(out,n) end
    end
    return out
end

-- ── Notifications ─────────────────────────────────────
local NotifyHolder
local _notifyStates={}
local _notifyConn=nil

local NOTIFY_W=290
local NOTIFY_H=62
local NOTIFY_PAD_X=20
local NOTIFY_PAD_Y=20
local NOTIFY_SPACING=20
local NOTIFY_MIN_BG_T=0.06 -- at full alpha

local function ensureNotify()
    if NotifyHolder and NotifyHolder.Parent then return end
    local sg=Instance.new("ScreenGui")
    sg.Name="HydrosolNotify"; sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.DisplayOrder=999
    pcall(function() sg.Parent=CoreGui end)
    if not sg.Parent then sg.Parent=Players.LocalPlayer:WaitForChild("PlayerGui") end
    NotifyHolder=Instance.new("Frame")
    NotifyHolder.Name="NH"; NotifyHolder.BackgroundTransparency=1
    NotifyHolder.Size=UDim2.new(0,NOTIFY_W,1,0)
    -- x padding from the right, stacked from the top padding.
    NotifyHolder.Position=UDim2.new(1,-(NOTIFY_W+NOTIFY_PAD_X),0,0)
    NotifyHolder.Parent=sg

    -- Animate notify like the ImguiMenu C++ version:
    -- alpha easing (speed 4) + position easing (speed 8) + stacked target positions (spacing 20).
    _notifyConn = RunService.RenderStepped:Connect(function(dt)
        -- 1) Update alpha/timers
        for i=#_notifyStates,1,-1 do
            local st=_notifyStates[i]
            if not st or not st.card or not st.card.Parent then
                table.remove(_notifyStates,i)
            else
                st.timer=st.timer + dt
                local targetAlpha = (st.timer < st.duration) and 1 or 0
                local a=st.alpha
                -- easing(speed=4)
                local kAlpha = 1 - math.exp(-4*dt)
                a = a + (targetAlpha - a) * kAlpha
                st.alpha=a

                -- visual update
                local bgT = 1 - a*(1-NOTIFY_MIN_BG_T)
                st.card.BackgroundTransparency = bgT
                st.bar.BackgroundTransparency = 1 - a
                st.ico.ImageTransparency = 1 - a
                st.title.TextTransparency = 1 - a
                st.msg.TextTransparency = 1 - a

                local trackMinT = 0.65
                st.progBg.BackgroundTransparency = 1 - a*(1-trackMinT)

                local rem = 1 - (st.timer / st.duration)
                if rem < 0 then rem = 0 end
                st.prog.Size = UDim2.new(rem,0,0,2)
                st.prog.BackgroundTransparency = 1 - a
            end
        end

        -- 2) Compute target positions for visible notifications
        local acc=0
        for i=1,#_notifyStates do
            local st=_notifyStates[i]
            if st and st.card and st.card.Parent and st.alpha > 0.01 then
                st._targetY = NOTIFY_PAD_Y + acc
                acc = acc + (NOTIFY_H + NOTIFY_SPACING)
            else
                st._targetY = nil
            end
        end

        -- 3) Ease position toward target positions
        for i=1,#_notifyStates do
            local st=_notifyStates[i]
            if st and st.card and st.card.Parent and st._targetY then
                local kPos = 1 - math.exp(-8*dt) -- easing(speed=8)
                st.pos = st.pos + (st._targetY - st.pos) * kPos
                st.card.Position = UDim2.new(0,0,0,st.pos)
            end
        end

        -- 4) Destroy when faded out
        for i=#_notifyStates,1,-1 do
            local st=_notifyStates[i]
            if st and st.card and st.card.Parent and st.timer >= st.duration and st.alpha < 0.01 then
                st.card:Destroy()
                table.remove(_notifyStates,i)
            end
        end
    end)
end

local function Notify(opts)
    opts=opts or {}
    local nType=opts.Type or "info"
    local dur=opts.Duration or 15 -- match ImguiMenu default (notify_time)
    ensureNotify()
    local col=({info=T.Accent,success=T.Success,warning=T.Warning,error=T.Error})[nType] or T.Accent

    local card=Instance.new("Frame")
    card.Size=UDim2.new(0,NOTIFY_W,0,NOTIFY_H); card.BackgroundColor3=T.Notify
    card.BackgroundTransparency=1; card.ClipsDescendants=true
    card.Position=UDim2.new(0,0,0,NOTIFY_PAD_Y)
    card.Parent=NotifyHolder
    mkCorner(card,8)

    -- left accent bar
    local bar=Instance.new("Frame"); bar.Size=UDim2.new(0,3,0,NOTIFY_H)
    bar.BackgroundColor3=col; bar.BorderSizePixel=0; bar.Parent=card; mkCorner(bar,100)
    bar.BackgroundTransparency=1

    -- icon
    local ico=mkImg(card,({info=I.info,success=I.success,warning=I.warning,error=I.error})[nType] or I.info,16,col)
    ico.Position=UDim2.new(0,12,0.5,-8); ico.AnchorPoint=Vector2.new(0,0.5)
    ico.ImageTransparency=1

    -- title
    local tl=mkLabel(card,opts.Title or "HydrosolUI",13,T.Text,Enum.Font.GothamBold)
    tl.Size=UDim2.new(1,-36,0,16); tl.Position=UDim2.new(0,34,0,10)
    tl.TextTransparency=1

    -- message
    local ml=mkLabel(card,opts.Message or "",11,T.TextSub,Enum.Font.Gotham)
    ml.Size=UDim2.new(1,-36,0,22); ml.Position=UDim2.new(0,34,0,28); ml.TextWrapped=true
    ml.TextTransparency=1

    -- progress bar (rounded)
    local progBg=Instance.new("Frame"); progBg.Size=UDim2.new(1,0,0,2)
    progBg.Position=UDim2.new(0,0,1,-2); progBg.BackgroundColor3=col; progBg.BorderSizePixel=0; progBg.Parent=card; mkCorner(progBg,1000)
    progBg.BackgroundTransparency=1

    local prog=Instance.new("Frame"); prog.Size=UDim2.new(1,0,0,2)
    prog.Position=UDim2.new(0,0,1,-2); prog.BackgroundColor3=col; prog.BorderSizePixel=0; prog.Parent=card; mkCorner(prog,1000)
    prog.BackgroundTransparency=1

    local st={
        card=card,
        bar=bar,
        ico=ico,
        title=tl,
        msg=ml,
        progBg=progBg,
        prog=prog,
        timer=0,
        duration=dur,
        alpha=0,
        pos=NOTIFY_PAD_Y
    }
    table.insert(_notifyStates,st)
    return card
end

-- ─────────────────────────────────────────────────────
-- HydrosolUI
-- ─────────────────────────────────────────────────────
local HydrosolUI={}
HydrosolUI.__index=HydrosolUI
HydrosolUI.Version="2.1.0"
HydrosolUI.Theme=T
HydrosolUI.Icons=I
HydrosolUI.Notify=Notify

function HydrosolUI:CreateWindow(opts)
    opts=opts or {}
    local title  =opts.Title      or "HydrosolUI"
    local wSize  =opts.Size       or UDim2.new(0,860,0,530)
    local folder =opts.SaveFolder or (title:gsub("%s+","").."Configs")
    local hideKey=opts.ToggleKey  or Enum.KeyCode.RightAlt

    ensureNotify()

    local sg=Instance.new("ScreenGui")
    sg.Name="Hydrosol_"..title:gsub("%s+",""); sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.DisplayOrder=100
    pcall(function() sg.Parent=CoreGui end)
    if not sg.Parent then sg.Parent=Players.LocalPlayer:WaitForChild("PlayerGui") end

    pcall(function()
        local blur=Instance.new("BlurEffect"); blur.Size=0; blur.Parent=game:GetService("Lighting")
        ease(blur,0.5,{Size=10})
        sg.AncestryChanged:Connect(function()
            if not sg.Parent then ease(blur,0.4,{Size=0}); task.delay(0.5,function() blur:Destroy() end) end
        end)
    end)

    -- drop shadow
    local shadow=Instance.new("Frame"); shadow.AnchorPoint=Vector2.new(0.5,0.5)
    shadow.Position=UDim2.new(0.5,0,0.5,6)
    shadow.Size=UDim2.new(0,wSize.X.Offset+40,0,wSize.Y.Offset+40)
    shadow.BackgroundColor3=Color3.new(0,0,0)
    shadow.BackgroundTransparency=1; shadow.ClipsDescendants=true
    mkCorner(shadow,8)
    shadow.Parent=sg

    -- Root
    local root=Instance.new("Frame")
    root.Name="Root"; root.AnchorPoint=Vector2.new(0.5,0.5)
    root.Position=UDim2.new(0.5,0,0.5,0); root.Size=wSize
    -- Use an inner rounded clip to avoid square edges from child layers.
    root.BackgroundTransparency=1
    root.BorderSizePixel=0; root.ClipsDescendants=false
    root.Parent=sg

    local rootClip=Instance.new("Frame")
    rootClip.Name="Clip"
    rootClip.Size=UDim2.new(1,0,1,0)
    rootClip.Position=UDim2.new(0,0,0,0)
    rootClip.BackgroundColor3=T.Win
    rootClip.BackgroundTransparency=1
    rootClip.BorderSizePixel=0
    rootClip.ClipsDescendants=true
    rootClip.Parent=root
    mkCorner(rootClip,8)

    -- ── Topbar ─────────────────────────────────────────
    local topbar=Instance.new("Frame")
    topbar.Name="TopBar"; topbar.Size=UDim2.new(1,0,0,48)
    topbar.BackgroundColor3=T.Bar; topbar.BorderSizePixel=0; topbar.Parent=rootClip
    topbar.ClipsDescendants=true
    mkCorner(topbar,8)

    -- logo pill
    local logoBg=Instance.new("Frame"); logoBg.Size=UDim2.new(0,28,0,28)
    logoBg.Position=UDim2.new(0,14,0.5,-14); logoBg.BackgroundColor3=T.Accent
    logoBg.BackgroundTransparency=0.75; logoBg.BorderSizePixel=0; logoBg.Parent=topbar; mkCorner(logoBg,8)
    local logoI=mkImg(logoBg,I.diamond,14,T.AccentHi); logoI.Position=UDim2.new(0.5,-7,0.5,-7)

    local titleLbl=mkLabel(topbar,title,13,T.Text,Enum.Font.GothamBold)
    titleLbl.Position=UDim2.new(0,50,0,0); titleLbl.Size=UDim2.new(0,200,1,0)
    titleLbl.TextYAlignment=Enum.TextYAlignment.Center

    -- window buttons
    local function wBtn(xOff,bgCol,icoId,txt)
        local b=Instance.new("TextButton"); b.Size=UDim2.new(0,28,0,28)
        b.Position=UDim2.new(1,xOff,0.5,-14); b.BackgroundColor3=bgCol
        b.BackgroundTransparency=0.6; b.Text=""; b.BorderSizePixel=0; b.Parent=topbar; mkCorner(b,8)
        if not icoId then
            b.Text = txt or ""
            b.Font = Enum.Font.GothamBold
            b.TextSize = 14
            b.TextColor3 = T.TextInact
        end

        local ic=mkImg(b,icoId,13,T.TextInact); ic.AnchorPoint=Vector2.new(0.5,0.5); ic.Position=UDim2.new(0.5,0,0.5,0)
        b.MouseEnter:Connect(function() ease(b,0.12,{BackgroundTransparency=0.2}) end)
        b.MouseLeave:Connect(function() ease(b,0.12,{BackgroundTransparency=0.6}) end)
        return b,ic
    end
    local closeBtn,closeIco=wBtn(-14,Color3.fromRGB(80,24,32),I.close,"X")
    closeIco.ImageColor3=T.Error
    local minBtn=wBtn(-50,T.WdgBg,I.minus,"-")

    closeBtn.MouseButton1Click:Connect(function()
        ease(root,0.28,{Size=UDim2.new(0,wSize.X.Offset,0,0)})
        ease(rootClip,0.20,{BackgroundTransparency=1})
        ease(shadow,0.28,{BackgroundTransparency=1})
        task.delay(0.32,function() sg:Destroy() end)
    end)

    local minimized=false
    minBtn.MouseButton1Click:Connect(function()
        minimized=not minimized
        local tgt=minimized and UDim2.new(0,wSize.X.Offset,0,48) or wSize
        ease(root,0.34,{Size=tgt})
        local sh_tgt=minimized and UDim2.new(0,wSize.X.Offset+40,0,88) or UDim2.new(0,wSize.X.Offset+40,0,wSize.Y.Offset+40)
        ease(shadow,0.34,{Size=sh_tgt})
    end)

    -- drag
    local dragging,dragStartMouse,startPos=false,nil,nil
    topbar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            -- Use absolute mouse coordinates to avoid UI scale/anchor warping.
            dragStartMouse=UserInputService:GetMouseLocation()
            startPos=root.Position
        end
    end)
    topbar.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    RunService.RenderStepped:Connect(function()
        if not dragging then return end
        local m=UserInputService:GetMouseLocation()
        local d=m-dragStartMouse
        root.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        -- Shadow follows root position.
        local np=root.Position
        shadow.Position=UDim2.new(0,np.X.Offset+wSize.X.Offset/2,0,np.Y.Offset+wSize.Y.Offset/2+6)
    end)

    UserInputService.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode==hideKey then
            local v=not root.Visible; root.Visible=v; shadow.Visible=v
        end
    end)

    -- topbar bottom divider
    local tdiv=Instance.new("Frame"); tdiv.Size=UDim2.new(1,0,0,1); tdiv.Position=UDim2.new(0,0,1,0)
    tdiv.BackgroundColor3=T.Line; tdiv.BackgroundTransparency=0.5; tdiv.BorderSizePixel=0; tdiv.Parent=topbar

    -- ── Sidebar ────────────────────────────────────────
    local sidebar=Instance.new("Frame")
    sidebar.Name="Sidebar"; sidebar.Size=UDim2.new(0,55,1,-48)
    sidebar.Position=UDim2.new(0,0,0,48); sidebar.BackgroundColor3=T.Bar
    sidebar.BorderSizePixel=0; sidebar.Parent=rootClip
    sidebar.ClipsDescendants=true
    mkCorner(sidebar,8)

    local sideList=Instance.new("UIListLayout"); sideList.SortOrder=Enum.SortOrder.LayoutOrder
    sideList.HorizontalAlignment=Enum.HorizontalAlignment.Center
    sideList.Padding=UDim.new(0,4); sideList.Parent=sidebar
    mkPad(sidebar,10,0,10,0)

    -- sidebar right divider
    local sdiv=Instance.new("Frame"); sdiv.Size=UDim2.new(0,1,1,-48); sdiv.Position=UDim2.new(0,55,0,48)
    sdiv.BackgroundColor3=T.Line; sdiv.BackgroundTransparency=0.4; sdiv.BorderSizePixel=0; sdiv.Parent=rootClip

    -- ── Content ────────────────────────────────────────
    local content=Instance.new("Frame")
    content.Name="Content"; content.Size=UDim2.new(1,-56,1,-48)
    content.Position=UDim2.new(0,56,0,48); content.BackgroundTransparency=1
    content.ClipsDescendants=true; content.Parent=rootClip

    -- entrance animation
    root.Size=UDim2.new(0,wSize.X.Offset,0,0)
    rootClip.BackgroundTransparency=1
    ease(root,0.44,{Size=wSize})
    ease(rootClip,0.44,{BackgroundTransparency=0})
    ease(shadow,0.44,{BackgroundTransparency=0.65})

    local Window={_tabs={},_activeTab=nil,_sg=sg,_sidebar=sidebar,_content=content,_root=root}
    Window.SaveManager=SaveManager.new(folder); Window.Notify=Notify

    -- ── AddTab ─────────────────────────────────────────
    function Window:AddTab(tabOpts)
        tabOpts=tabOpts or {}
        local tabTitle=tabOpts.Title or ("Tab "..#self._tabs+1)
        local tabIcon=tabOpts.Icon or I.layers

        -- sidebar slot
        local slot=Instance.new("Frame")
        slot.Size=UDim2.new(0,38,0,38); slot.BackgroundColor3=T.WdgActive
        slot.BackgroundTransparency=1; slot.BorderSizePixel=0
        slot.LayoutOrder=#self._tabs+1; slot.Parent=self._sidebar; mkCorner(slot,8)

        local slotIco=mkImg(slot,tabIcon,18,T.TextInact)
        slotIco.AnchorPoint=Vector2.new(0.5,0.5); slotIco.Position=UDim2.new(0.5,0,0.5,0)

        local slotBtn=Instance.new("TextButton"); slotBtn.Size=UDim2.new(1,0,1,0)
        slotBtn.BackgroundTransparency=1; slotBtn.Text=""; slotBtn.ZIndex=slot.ZIndex+1; slotBtn.Parent=slot

        -- tooltip
        local tip=Instance.new("Frame"); tip.BackgroundColor3=T.WdgActive
        tip.Size=UDim2.new(0,0,0,26); tip.Position=UDim2.new(1,10,0.5,-13)
        tip.AutomaticSize=Enum.AutomaticSize.X; tip.Visible=false; tip.ZIndex=40; tip.Parent=slot
        mkCorner(tip,4); mkPad(tip,0,10,0,10)
        local tipL=mkLabel(tip,tabTitle,11,T.Text,Enum.Font.GothamMedium)
        tipL.AutomaticSize=Enum.AutomaticSize.XY; tipL.Size=UDim2.new(0,0,0,26)
        tipL.TextYAlignment=Enum.TextYAlignment.Center; tipL.ZIndex=41

        slot.MouseEnter:Connect(function()
            tip.Visible=true
            ease(slot,0.12,{BackgroundTransparency=0.65})
            ease(slotIco,0.12,{ImageColor3=T.Text})
        end)
        slot.MouseLeave:Connect(function()
            tip.Visible=false
            local isActive=self._activeTab and self._activeTab._slot==slot
            ease(slot,0.14,{BackgroundTransparency=isActive and 0.55 or 1})
            ease(slotIco,0.14,{ImageColor3=isActive and T.Accent or T.TextInact})
        end)

        -- page (scrolling)
        local page=Instance.new("ScrollingFrame")
        page.Name="Page_"..tabTitle; page.Size=UDim2.new(1,0,1,0)
        page.BackgroundTransparency=1; page.BorderSizePixel=0
        page.ScrollBarThickness=2; page.ScrollBarImageColor3=T.Accent
        page.ScrollBarImageTransparency=0.6; page.CanvasSize=UDim2.new(0,0,0,0)
        page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.Visible=false; page.Parent=self._content
        mkPad(page,16,16,16,16)

        local pageList=Instance.new("UIListLayout"); pageList.SortOrder=Enum.SortOrder.LayoutOrder
        pageList.Padding=UDim.new(0,0); pageList.Parent=page

        -- 2 columns
        local colRow=Instance.new("Frame"); colRow.Name="Cols"; colRow.Size=UDim2.new(1,0,0,0)
        colRow.AutomaticSize=Enum.AutomaticSize.Y; colRow.BackgroundTransparency=1; colRow.LayoutOrder=1; colRow.Parent=page
        local colLayout=Instance.new("UIListLayout"); colLayout.FillDirection=Enum.FillDirection.Horizontal
        colLayout.SortOrder=Enum.SortOrder.LayoutOrder; colLayout.Padding=UDim.new(0,12); colLayout.Parent=colRow

        local function mkCol(ord)
            local c=Instance.new("Frame"); c.Size=UDim2.new(0.5,-6,0,0)
            c.AutomaticSize=Enum.AutomaticSize.Y; c.BackgroundTransparency=1
            c.LayoutOrder=ord; c.Parent=colRow
            local cl=Instance.new("UIListLayout"); cl.SortOrder=Enum.SortOrder.LayoutOrder; cl.Padding=UDim.new(0,10); cl.Parent=c
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
            local col,order=(side=="auto") and self:_nextCol() or self:_col(side)
            -- Guard against unexpected nils (prevents "nil cannot be converted to a number")
            if not col then col=self._colL or self._colR end
            order=tonumber(order) or 1

            -- section wrapper (no clip so content isn't cut)
            local wrap=Instance.new("Frame"); wrap.Name="SecWrap"
            wrap.Size=UDim2.new(1,0,0,0); wrap.AutomaticSize=Enum.AutomaticSize.Y
            wrap.BackgroundTransparency=1; wrap.LayoutOrder=order; wrap.Parent=col
            local wl=Instance.new("UIListLayout"); wl.SortOrder=Enum.SortOrder.LayoutOrder; wl.Padding=UDim.new(0,0); wl.Parent=wrap

            -- section title label above the card (like ImguiMenu child name)
            if sOpts.Title and sOpts.Title~="" then
                local titleRow=Instance.new("Frame"); titleRow.Size=UDim2.new(1,0,0,22)
                titleRow.BackgroundTransparency=1; titleRow.LayoutOrder=0; titleRow.Parent=wrap
                local xOff=0
                if sOpts.Icon then
                    local si=mkImg(titleRow,sOpts.Icon,12,T.Accent); si.Position=UDim2.new(0,0,0.5,-6); xOff=16
                end
                local hl=mkLabel(titleRow,sOpts.Title,11,T.TextInact,Enum.Font.GothamBold)
                hl.Position=UDim2.new(0,xOff,0,0); hl.Size=UDim2.new(1,-xOff,1,0)
                hl.TextYAlignment=Enum.TextYAlignment.Center
            end

            -- card (the actual box)
            local sec=Instance.new("Frame"); sec.Name="Sec"
            sec.Size=UDim2.new(1,0,0,0); sec.AutomaticSize=Enum.AutomaticSize.Y
            sec.BackgroundColor3=T.Child; sec.BorderSizePixel=0
            sec.LayoutOrder=1; sec.Parent=wrap; sec.ClipsDescendants=true
            mkCorner(sec,8)

            -- outline
            local secOutline=Instance.new("Frame"); secOutline.Name="Outline"
            secOutline.Size=UDim2.new(1,0,0,0); secOutline.AutomaticSize=Enum.AutomaticSize.Y
            secOutline.BackgroundTransparency=1; secOutline.BorderSizePixel=0
            secOutline.LayoutOrder=1; secOutline.Parent=wrap
            secOutline.Position=sec.Position; secOutline.ZIndex=sec.ZIndex+1

            local body=Instance.new("Frame"); body.Name="Body"; body.Size=UDim2.new(1,0,0,0)
            body.AutomaticSize=Enum.AutomaticSize.Y; body.BackgroundTransparency=1
            body.LayoutOrder=0; body.Parent=sec
            local bodyL=Instance.new("UIListLayout"); bodyL.SortOrder=Enum.SortOrder.LayoutOrder
            bodyL.Padding=UDim.new(0,0); bodyL.Parent=body

            local Section={_body=body,_sec=sec,_wrap=wrap,_n=0,_tab=self}

            -- row factory
            local function mkRow(h)
                h=h or 40; Section._n=Section._n+1
                local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,h)
                row.BackgroundTransparency=1; row.BorderSizePixel=0
                row.LayoutOrder=Section._n; row.Parent=body
                mkPad(row,0,14,0,14)
                -- separator (not on first row)
                if Section._n>1 then
                    local sep=Instance.new("Frame"); sep.Size=UDim2.new(1,0,0,1)
                    sep.BackgroundColor3=T.Line; sep.BackgroundTransparency=0.55
                    sep.BorderSizePixel=0; sep.ZIndex=row.ZIndex; sep.Parent=row
                end
                return row
            end

            -- ── AddParagraph ─────────────────────────
            function Section:AddParagraph(o)
                o=o or {}
                local row=mkRow(nil); row.AutomaticSize=Enum.AutomaticSize.Y; row.Size=UDim2.new(1,0,0,0)
                local inner=Instance.new("Frame"); inner.BackgroundTransparency=1
                inner.Size=UDim2.new(1,0,0,0); inner.AutomaticSize=Enum.AutomaticSize.Y; inner.Parent=row
                mkPad(inner,10,0,10,0)
                local il=Instance.new("UIListLayout"); il.SortOrder=Enum.SortOrder.LayoutOrder; il.Padding=UDim.new(0,3); il.Parent=inner
                local tl=mkLabel(inner,o.Title or "",12,T.TextSub,Enum.Font.GothamBold)
                tl.LayoutOrder=1; tl.Size=UDim2.new(1,0,0,14); tl.AutomaticSize=Enum.AutomaticSize.Y; tl.TextWrapped=true
                local bl=mkLabel(inner,o.Content or "",11,T.TextInact,Enum.Font.Gotham)
                bl.LayoutOrder=2; bl.Size=UDim2.new(1,0,0,14); bl.AutomaticSize=Enum.AutomaticSize.Y; bl.TextWrapped=true
                local P={}
                function P:Set(t,c) if t~=nil then tl.Text=t end; if c~=nil then bl.Text=c end end
                function P:SetTitle(t) tl.Text=t end
                function P:SetContent(c) bl.Text=c end
                return P
            end

            -- ── AddButton ────────────────────────────
            function Section:AddButton(o)
                o=o or {}; local row=mkRow(40)
                local off=0
                if o.Icon then
                    local bi=mkImg(row,o.Icon,14,T.TextInact); bi.Position=UDim2.new(0,0,0.5,-7); off=20
                end
                local l=mkLabel(row,o.Title or "Button",13,T.Text,Enum.Font.GothamMedium)
                l.Position=UDim2.new(0,off,0,0); l.Size=UDim2.new(0.6,-off,1,0); l.TextYAlignment=Enum.TextYAlignment.Center

                local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0,68,0,26)
                btn.Position=UDim2.new(1,-68,0.5,-13); btn.BackgroundColor3=T.Accent
                btn.Text=o.BtnText or "Run"; btn.TextColor3=Color3.new(1,1,1)
                btn.TextSize=11; btn.Font=Enum.Font.GothamBold; btn.BorderSizePixel=0; btn.Parent=row; mkCorner(btn,8)
                btn.MouseEnter:Connect(function() ease(btn,0.1,{BackgroundColor3=T.AccentHi}) end)
                btn.MouseLeave:Connect(function() ease(btn,0.1,{BackgroundColor3=T.Accent}) end)
                btn.MouseButton1Click:Connect(function()
                    ease(btn,0.06,{BackgroundColor3=T.AccentDim})
                    task.delay(0.06,function() ease(btn,0.14,{BackgroundColor3=T.Accent}) end)
                    if o.Callback then pcall(o.Callback) end
                end)
                return btn
            end

            -- ── AddToggle ────────────────────────────
            function Section:AddToggle(o)
                o=o or {}; local row=mkRow(40)
                local off=0
                if o.Icon then
                    local ti=mkImg(row,o.Icon,14,T.TextInact); ti.Position=UDim2.new(0,0,0.5,-7); off=20
                end
                local state=o.Default or false
                local l=mkLabel(row,o.Title or "Toggle",13,state and T.Text or T.TextInact,Enum.Font.GothamMedium)
                l.Position=UDim2.new(0,off,0,0); l.Size=UDim2.new(0.72,-off,1,0); l.TextYAlignment=Enum.TextYAlignment.Center

                -- track
                local track=Instance.new("Frame"); track.Size=UDim2.new(0,40,0,22)
                track.Position=UDim2.new(1,-40,0.5,-11); track.BorderSizePixel=0
                track.BackgroundColor3=T.WdgBg; track.Parent=row; mkCorner(track,100)
                -- accent fill overlay
                local fill=Instance.new("Frame"); fill.Size=state and UDim2.new(1,0,1,0) or UDim2.new(0,0,1,0)
                fill.BackgroundColor3=T.Accent; fill.BorderSizePixel=0; fill.Parent=track; mkCorner(fill,100)

                local thumb=Instance.new("Frame"); thumb.Size=UDim2.new(0,16,0,16)
                thumb.Position=state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
                thumb.BackgroundColor3=Color3.new(1,1,1); thumb.BorderSizePixel=0; thumb.Parent=track; mkCorner(thumb,100)
                thumb.ZIndex=fill.ZIndex+1

                local ca=Instance.new("TextButton"); ca.Size=UDim2.new(1,0,1,0)
                ca.BackgroundTransparency=1; ca.Text=""; ca.Parent=row
                local Tgl={Value=state}

                local function setState(v,silent)
                    state=v; Tgl.Value=v
                    ease(fill,0.18,{Size=v and UDim2.new(1,0,1,0) or UDim2.new(0,0,1,0)})
                    ease(thumb,0.18,{Position=v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)})
                    ease(l,0.14,{TextColor3=v and T.Text or T.TextInact})
                    if not silent and o.Callback then pcall(o.Callback,v) end
                end
                ca.MouseButton1Click:Connect(function() setState(not state) end)
                function Tgl:Set(v) setState(v,true) end
                if o.Flag and Tab._window.SaveManager then Tab._window.SaveManager:AddFlag(o.Flag,function() return Tgl.Value end) end
                return Tgl
            end

            -- ── AddSlider ────────────────────────────
            function Section:AddSlider(o)
                o=o or {}; local row=mkRow(48)
                local minV,maxV,dp=o.Min or 0,o.Max or 100,o.Decimals or 0
                local sfx=o.Suffix or ""; local cur=math.clamp(o.Default or minV,minV,maxV)
                local off=0
                if o.Icon then
                    local si=mkImg(row,o.Icon,14,T.TextInact); si.Position=UDim2.new(0,0,0,8); off=20
                end

                local l=mkLabel(row,o.Title or "Slider",13,T.TextInact,Enum.Font.GothamMedium)
                l.Position=UDim2.new(0,off,0,6); l.Size=UDim2.new(0.7,-off,0,16); l.TextYAlignment=Enum.TextYAlignment.Top

                local vl=mkLabel(row,round(cur,dp)..sfx,13,T.Text,Enum.Font.GothamBold,Enum.TextXAlignment.Right)
                vl.Size=UDim2.new(0.3,0,0,16); vl.Position=UDim2.new(0.7,0,0,6)

                -- track bg
                local tf=Instance.new("Frame"); tf.Size=UDim2.new(1,0,0,6); tf.Position=UDim2.new(0,0,1,-14)
                tf.BackgroundColor3=T.WdgBg; tf.BorderSizePixel=0; tf.Parent=row; mkCorner(tf,100)

                local fill=Instance.new("Frame"); fill.Size=UDim2.new((cur-minV)/(maxV-minV),0,1,0)
                fill.BackgroundColor3=T.Accent; fill.BorderSizePixel=0; fill.Parent=tf; mkCorner(fill,100)

                -- knob
                local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,14,0,14)
                knob.AnchorPoint=Vector2.new(0.5,0.5)
                knob.Position=UDim2.new((cur-minV)/(maxV-minV),0,0.5,0)
                knob.BackgroundColor3=Color3.new(1,1,1); knob.BorderSizePixel=0
                knob.ZIndex=tf.ZIndex+2; knob.Parent=tf; mkCorner(knob,100)

                local draggingS=false; local Sld={Value=cur}
                local function setS(v,silent)
                    v=math.clamp(round(v,dp),minV,maxV); cur=v; Sld.Value=v
                    local p=(v-minV)/(maxV-minV)
                    fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,0.5,0)
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
            local function buildDrop(o,multi)
                o=o or {}; local row=mkRow(40)
                local off=0
                if o.Icon then
                    local di=mkImg(row,o.Icon,14,T.TextInact); di.Position=UDim2.new(0,0,0.5,-7); off=20
                end
                local l=mkLabel(row,o.Title or "Dropdown",13,T.TextInact,Enum.Font.GothamMedium)
                l.Position=UDim2.new(0,off,0,0); l.Size=UDim2.new(0.44,-off,1,0); l.TextYAlignment=Enum.TextYAlignment.Center

                local opts=o.Options or {}
                local selected=multi and {} or (o.Default or opts[1] or "None")
                if multi and o.Default then for _,v in ipairs(o.Default) do selected[v]=true end end

                local disp=Instance.new("TextButton"); disp.Size=UDim2.new(0.56,-4,0,28)
                disp.Position=UDim2.new(0.44,4,0.5,-14); disp.BackgroundColor3=T.WdgBg
                disp.BorderSizePixel=0; disp.Font=Enum.Font.GothamMedium; disp.TextSize=11
                disp.TextColor3=T.TextSub; disp.TextXAlignment=Enum.TextXAlignment.Left
                disp.ClipsDescendants=true; disp.Parent=row; mkCorner(disp,8); mkPad(disp,0,28,0,10)

                local chevI=mkImg(disp,I.chevDown,11,T.TextInact)
                chevI.AnchorPoint=Vector2.new(1,0.5); chevI.Position=UDim2.new(1,-6,0.5,0)

                local function refreshDisp()
                    if multi then
                        local s={}; for k,v in pairs(selected) do if v then table.insert(s,k) end end
                        disp.Text=#s==0 and "None" or table.concat(s,", ")
                    else disp.Text=tostring(selected) end
                end
                refreshDisp()

                local open=false
                local panel=Instance.new("Frame"); panel.BackgroundColor3=T.Child
                panel.Size=UDim2.new(0,200,0,0); panel.BackgroundTransparency=0
                panel.Visible=false; panel.ZIndex=80; panel.Parent=sg; mkCorner(panel,8)
                panel.ClipsDescendants=true

                local sRow=Instance.new("Frame"); sRow.Size=UDim2.new(1,-12,0,28); sRow.Position=UDim2.new(0,6,0,6)
                sRow.BackgroundColor3=T.WdgBg; sRow.BorderSizePixel=0; sRow.ZIndex=81; sRow.Parent=panel; mkCorner(sRow,8)
                local sIco=mkImg(sRow,I.search,12,T.TextInact); sIco.Position=UDim2.new(0,7,0.5,-6); sIco.ZIndex=82
                local sBox=Instance.new("TextBox"); sBox.Size=UDim2.new(1,-28,1,0); sBox.Position=UDim2.new(0,26,0,0)
                sBox.BackgroundTransparency=1; sBox.Text=""; sBox.PlaceholderText="Search..."
                sBox.PlaceholderColor3=T.TextInact; sBox.TextColor3=T.Text; sBox.TextSize=11
                sBox.Font=Enum.Font.Gotham; sBox.ClearTextOnFocus=false; sBox.ZIndex=82; sBox.Parent=sRow

                local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-8,0,0)
                scroll.Position=UDim2.new(0,4,0,40); scroll.BackgroundTransparency=1
                scroll.BorderSizePixel=0; scroll.ScrollBarThickness=2; scroll.ScrollBarImageColor3=T.Accent
                scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.new(0,0,0,0)
                scroll.ZIndex=81; scroll.Parent=panel
                local sl=Instance.new("UIListLayout"); sl.SortOrder=Enum.SortOrder.LayoutOrder; sl.Padding=UDim.new(0,1); sl.Parent=scroll

                local Drop={Value=selected}; local itemRefs={}

                local function mkItem(opt)
                    local itm=Instance.new("TextButton"); itm.Size=UDim2.new(1,0,0,28)
                    itm.BackgroundColor3=T.WdgActive; itm.BackgroundTransparency=1
                    itm.Text=tostring(opt); itm.TextColor3=T.TextInact; itm.TextSize=11
                    itm.Font=Enum.Font.GothamMedium; itm.TextXAlignment=Enum.TextXAlignment.Left
                    itm.BorderSizePixel=0; itm.ZIndex=82; itm.Parent=scroll; mkPad(itm,0,0,0,10)
                    local chk=mkImg(itm,I.check,11,T.Accent); chk.AnchorPoint=Vector2.new(1,0.5)
                    chk.Position=UDim2.new(1,-8,0.5,0); chk.ZIndex=83; chk.Visible=false
                    local function refChk()
                        local sel=multi and selected[opt] or (selected==opt)
                        chk.Visible=sel; itm.TextColor3=sel and T.Text or T.TextInact
                        itm.BackgroundTransparency=sel and 0.7 or 1
                    end
                    refChk()
                    itm.MouseButton1Click:Connect(function()
                        if multi then selected[opt]=not selected[opt] else selected=opt end
                        Drop.Value=selected; refChk(); refreshDisp()
                        if o.Callback then pcall(o.Callback,selected) end
                        if not multi then
                            open=false
                            ease(panel,0.14,{Size=UDim2.new(0,panel.AbsoluteSize.X,0,0)})
                            ease(chevI,0.12,{Rotation=0}); task.delay(0.16,function() panel.Visible=false end)
                        end
                    end)
                    itm.MouseEnter:Connect(function() itm.BackgroundTransparency=0.82 end)
                    itm.MouseLeave:Connect(function()
                        local sel=multi and selected[opt] or (selected==opt)
                        itm.BackgroundTransparency=sel and 0.7 or 1
                    end)
                    return itm,refChk
                end

                for _,op in ipairs(opts) do local it,rc=mkItem(op); table.insert(itemRefs,{btn=it,text=tostring(op),refresh=rc}) end

                sBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local q=sBox.Text:lower()
                    for _,r in ipairs(itemRefs) do r.btn.Visible=(q=="" or r.text:lower():find(q,1,true)~=nil) end
                end)

                local function openP()
                    local a=disp.AbsolutePosition; local s=disp.AbsoluteSize
                    local mh=math.min(#opts*29+46,190)
                    panel.Position=UDim2.new(0,a.X,0,a.Y+s.Y+4)
                    panel.Size=UDim2.new(0,s.X,0,0); panel.Visible=true
                    scroll.Size=UDim2.new(1,-8,0,mh-44)
                    ease(panel,0.18,{Size=UDim2.new(0,s.X,0,mh)}); ease(chevI,0.12,{Rotation=180})
                end
                local function closeP()
                    ease(panel,0.14,{Size=UDim2.new(0,panel.AbsoluteSize.X,0,0)})
                    ease(chevI,0.12,{Rotation=0}); task.delay(0.16,function() panel.Visible=false end)
                end

                disp.MouseButton1Click:Connect(function()
                    open=not open
                    if open then openP() else closeP() end
                end)
                UserInputService.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 and open then
                        local m=UserInputService:GetMouseLocation()
                        local pa=panel.AbsolutePosition; local ps=panel.AbsoluteSize
                        local da=disp.AbsolutePosition; local ds=disp.AbsoluteSize
                        local inPanel=m.X>=pa.X and m.X<=pa.X+ps.X and m.Y>=pa.Y and m.Y<=pa.Y+ps.Y
                        local inDisp=m.X>=da.X and m.X<=da.X+ds.X and m.Y>=da.Y and m.Y<=da.Y+ds.Y
                        if not inPanel and not inDisp then open=false; closeP() end
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
                local off=0
                if o.Icon then
                    local ki=mkImg(row,o.Icon,14,T.TextInact); ki.Position=UDim2.new(0,0,0.5,-7); off=20
                end
                local l=mkLabel(row,o.Title or "Keybind",13,T.TextInact,Enum.Font.GothamMedium)
                l.Position=UDim2.new(0,off,0,0); l.Size=UDim2.new(0.55,-off,1,0); l.TextYAlignment=Enum.TextYAlignment.Center

                local key=o.Default or Enum.KeyCode.Unknown; local listening=false
                local kBtn=Instance.new("TextButton"); kBtn.Size=UDim2.new(0,78,0,26)
                kBtn.Position=UDim2.new(1,-78,0.5,-13); kBtn.BackgroundColor3=T.WdgBg
                kBtn.Text=key.Name; kBtn.TextColor3=T.Accent; kBtn.TextSize=11; kBtn.Font=Enum.Font.GothamBold
                kBtn.BorderSizePixel=0; kBtn.Parent=row; mkCorner(kBtn,4); mkPad(kBtn,0,8,0,8)

                local kIco=mkImg(kBtn,I.keyboard,11,T.Accent); kIco.Position=UDim2.new(0,4,0.5,-5)

                local Kb={Value=key}
                kBtn.MouseButton1Click:Connect(function()
                    listening=true; kBtn.Text="  · · ·"; ease(kBtn,0.1,{BackgroundColor3=T.WdgActive})
                end)
                UserInputService.InputBegan:Connect(function(i,gp)
                    if not listening then
                        if i.KeyCode==key and not gp then if o.Callback then pcall(o.Callback,key) end end; return
                    end
                    if i.UserInputType==Enum.UserInputType.Keyboard then
                        listening=false; key=i.KeyCode; Kb.Value=key; kBtn.Text=key.Name
                        ease(kBtn,0.1,{BackgroundColor3=T.WdgBg})
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
                local off=0
                if o.Icon then
                    local ii=mkImg(row,o.Icon,14,T.TextInact); ii.Position=UDim2.new(0,0,0.5,-7); off=20
                end
                local l=mkLabel(row,o.Title or "Input",13,T.TextInact,Enum.Font.GothamMedium)
                l.Position=UDim2.new(0,off,0,0); l.Size=UDim2.new(0.38,-off,1,0); l.TextYAlignment=Enum.TextYAlignment.Center

                local box=Instance.new("TextBox"); box.Size=UDim2.new(0.62,-4,0,28)
                box.Position=UDim2.new(0.38,4,0.5,-14); box.BackgroundColor3=T.WdgBg
                box.BorderSizePixel=0; box.Text=o.Default or ""; box.PlaceholderText=o.Placeholder or "..."
                box.PlaceholderColor3=T.TextInact; box.TextColor3=T.Text; box.TextSize=11; box.Font=Enum.Font.Gotham
                box.ClearTextOnFocus=o.ClearOnFocus~=false; box.Parent=row; mkCorner(box,4); mkPad(box,0,8,0,10)

                box.Focused:Connect(function() ease(box,0.12,{BackgroundColor3=T.WdgActive}) end)
                box.FocusLost:Connect(function(enter)
                    ease(box,0.12,{BackgroundColor3=T.WdgBg})
                    if o.Callback then pcall(o.Callback,box.Text,enter) end
                end)
                local Inp={Value=box.Text}
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    Inp.Value=box.Text
                    if o.Changed then pcall(o.Changed,box.Text) end
                end)
                function Inp:Set(v) box.Text=tostring(v) end
                if o.Flag and Tab._window.SaveManager then Tab._window.SaveManager:AddFlag(o.Flag,function() return Inp.Value end) end
                return Inp
            end

            -- ── AddLabel ─────────────────────────────
            function Section:AddLabel(o)
                o=o or {}; local row=mkRow(32)
                row.AutomaticSize=Enum.AutomaticSize.Y; row.Size=UDim2.new(1,0,0,32)
                local l=mkLabel(row,o.Text or "",11,T.TextInact,Enum.Font.Gotham)
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
            ease(t._slotIco,0.14,{ImageColor3=T.TextInact})
        end
        tab._page.Visible=true; self._activeTab=tab
        ease(tab._slot,0.18,{BackgroundTransparency=0.55})
        ease(tab._slotIco,0.18,{ImageColor3=T.Accent})

        if self._sideInd then self._sideInd:Destroy() end
        local ind=Instance.new("Frame"); ind.Size=UDim2.new(0,3,0,22); ind.AnchorPoint=Vector2.new(0,0.5)
        ind.BackgroundColor3=T.Accent; ind.BorderSizePixel=0; ind.ZIndex=8; ind.Parent=self._sidebar; mkCorner(ind,2)
        self._sideInd=ind
        local _slot,_sb=tab._slot,self._sidebar
        task.defer(function()
            if ind.Parent then
                ind.Position=UDim2.new(0,0,0,_slot.AbsolutePosition.Y-_sb.AbsolutePosition.Y+19)
            end
        end)
    end

    return Window
end

return HydrosolUI
