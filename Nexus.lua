--[[
    ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗    ██╗   ██╗██╗
    ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝    ██║   ██║██║
    ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗    ██║   ██║██║
    ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║    ██║   ██║██║
    ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║    ╚██████╔╝██║
    ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝     ╚═════╝ ╚═╝
    
    NexusUI — Lua UI Library
    Version : 1.0.0
    Author  : NexusUI
    Theme   : Dark Editor (Gold Accent)
    
    ─────────────────────────────────────────────────────────────
    USAGE EXAMPLE:
    
        local Nexus = loadstring(game:HttpGet("..."))()
        
        local Window = Nexus:CreateWindow({
            Title   = "My Script",
            SubTitle = "v1.0",
            Theme   = "Default",  -- "Default" | "Ocean" | "Rose"
        })
        
        local Tab = Window:AddTab({ Name = "Main", Icon = "⚡" })
        local Section = Tab:AddSection({ Name = "Combat" })
        
        Section:AddButton({ Name = "Kill All", Callback = function() end })
        Section:AddToggle({ Name = "God Mode", Default = false, Callback = function(v) end })
        Section:AddSlider({ Name = "Speed", Min = 0, Max = 100, Default = 16, Callback = function(v) end })
    ─────────────────────────────────────────────────────────────
]]

-- ══════════════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ══════════════════════════════════════════════════════════════
--  UTILITY
-- ══════════════════════════════════════════════════════════════
local function Tween(obj, props, duration, style, dir)
    style    = style or Enum.EasingStyle.Quart
    dir      = dir   or Enum.EasingDirection.Out
    duration = duration or 0.25
    local info = TweenInfo.new(duration, style, dir)
    local tw   = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function Color(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber("0x"..hex:sub(1,2)),
        tonumber("0x"..hex:sub(3,4)),
        tonumber("0x"..hex:sub(5,6))
    )
end

local function New(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Lerp(a, b, t) return a + (b - a) * t end

local function Round(n, dec)
    local m = 10^(dec or 0)
    return math.floor(n * m + 0.5) / m
end

-- ══════════════════════════════════════════════════════════════
--  THEME SYSTEM
-- ══════════════════════════════════════════════════════════════
local Themes = {
    Default = {
        -- Backgrounds
        BG          = Color("0e0e10"),
        BG2         = Color("131315"),
        BG3         = Color("1a1a1d"),
        BG4         = Color("202024"),
        -- Borders
        Border      = Color("2a2a2f"),
        Border2     = Color("38383f"),
        -- Text
        Text        = Color("e8e8ec"),
        Muted       = Color("6b6b75"),
        Faint       = Color("3d3d45"),
        -- Accents
        Accent      = Color("d4a853"),  -- Gold
        Accent2     = Color("5b8fd4"),  -- Blue
        -- Status
        Green       = Color("5ec47a"),
        Red         = Color("e06c75"),
        Cyan        = Color("56b6c2"),
        Purple      = Color("c678dd"),
        Orange      = Color("d19a66"),
    },
    Ocean = {
        BG          = Color("0a0f1e"),
        BG2         = Color("0d1526"),
        BG3         = Color("111c30"),
        BG4         = Color("162138"),
        Border      = Color("1e2d47"),
        Border2     = Color("2a3d5e"),
        Text        = Color("dde8f5"),
        Muted       = Color("5a7a99"),
        Faint       = Color("2a3d5e"),
        Accent      = Color("56b6c2"),  -- Cyan
        Accent2     = Color("5b8fd4"),  -- Blue
        Green       = Color("5ec47a"),
        Red         = Color("e06c75"),
        Cyan        = Color("56b6c2"),
        Purple      = Color("c678dd"),
        Orange      = Color("d19a66"),
    },
    Rose = {
        BG          = Color("120e0e"),
        BG2         = Color("171111"),
        BG3         = Color("1d1515"),
        BG4         = Color("221818"),
        Border      = Color("2f2020"),
        Border2     = Color("3d2a2a"),
        Text        = Color("f0e0e0"),
        Muted       = Color("7a5555"),
        Faint       = Color("3d2525"),
        Accent      = Color("e06c75"),  -- Red/Rose
        Accent2     = Color("c678dd"),  -- Purple
        Green       = Color("5ec47a"),
        Red         = Color("e06c75"),
        Cyan        = Color("56b6c2"),
        Purple      = Color("c678dd"),
        Orange      = Color("d19a66"),
    },
}

-- ══════════════════════════════════════════════════════════════
--  NOTIFICATION QUEUE
-- ══════════════════════════════════════════════════════════════
local NotifyHolder -- assigned after GUI creation

-- ══════════════════════════════════════════════════════════════
--  MAIN LIBRARY
-- ══════════════════════════════════════════════════════════════
local NexusUI = {}
NexusUI.__index = NexusUI
NexusUI._Flags  = {}  -- global flag storage for SaveManager

-- ──────────────────────────────────────────────
--  NOTIFICATION
-- ──────────────────────────────────────────────
--[[
    NexusUI:Notify({
        Title    = "Info",
        Message  = "Hello World",
        Type     = "success",  -- "success"|"error"|"warning"|"info"
        Duration = 3,
    })
]]
function NexusUI:Notify(cfg)
    cfg = cfg or {}
    local T      = self._Theme or Themes.Default
    local nType  = cfg.Type or "info"
    local dur    = cfg.Duration or 3

    local typeColor = {
        success = T.Green,
        error   = T.Red,
        warning = T.Orange,
        info    = T.Accent2,
    }
    local typeIcon = {
        success = "✓",
        error   = "✕",
        warning = "⚠",
        info    = "ℹ",
    }

    local accentCol = typeColor[nType] or T.Accent

    -- Container
    local Frame = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = T.BG3,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        AutomaticSize   = Enum.AutomaticSize.Y,
    })
    New("UICorner",   { CornerRadius = UDim.new(0,7) }, {}).Parent = Frame
    New("UIStroke",   { Color = T.Border2, Thickness = 1 }, {}).Parent = Frame

    -- Left accent bar
    local Bar = New("Frame", {
        Size            = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentCol,
        BorderSizePixel = 0,
    })
    New("UICorner", { CornerRadius = UDim.new(0,3) }).Parent = Bar
    Bar.Parent = Frame

    -- Icon
    local Icon = New("TextLabel", {
        Size            = UDim2.new(0, 28, 0, 28),
        Position        = UDim2.new(0, 12, 0, 10),
        BackgroundColor3 = accentCol,
        Text            = typeIcon[nType] or "ℹ",
        TextColor3      = Color3.fromRGB(14,14,16),
        TextSize        = 13,
        Font            = Enum.Font.GothamBold,
        BorderSizePixel = 0,
    })
    New("UICorner", { CornerRadius = UDim.new(0,6) }).Parent = Icon
    Icon.Parent = Frame

    -- Title
    New("TextLabel", {
        Size            = UDim2.new(1, -60, 0, 18),
        Position        = UDim2.new(0, 48, 0, 8),
        BackgroundTransparency = 1,
        Text            = cfg.Title or "Notification",
        TextColor3      = T.Text,
        TextSize        = 12,
        Font            = Enum.Font.GothamBold,
        TextXAlignment  = Enum.TextXAlignment.Left,
    }).Parent = Frame

    -- Message
    local Msg = New("TextLabel", {
        Size            = UDim2.new(1, -60, 0, 0),
        Position        = UDim2.new(0, 48, 0, 28),
        BackgroundTransparency = 1,
        Text            = cfg.Message or "",
        TextColor3      = T.Muted,
        TextSize        = 11,
        Font            = Enum.Font.Gotham,
        TextXAlignment  = Enum.TextXAlignment.Left,
        TextWrapped     = true,
        AutomaticSize   = Enum.AutomaticSize.Y,
    })
    Msg.Parent = Frame

    -- Progress bar
    local ProgBG = New("Frame", {
        Size            = UDim2.new(1, -16, 0, 2),
        Position        = UDim2.new(0, 8, 1, -6),
        BackgroundColor3 = T.Border,
        BorderSizePixel = 0,
    })
    New("UICorner", { CornerRadius = UDim.new(1,0) }).Parent = ProgBG
    ProgBG.Parent = Frame

    local ProgFill = New("Frame", {
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = accentCol,
        BorderSizePixel = 0,
    })
    New("UICorner", { CornerRadius = UDim.new(1,0) }).Parent = ProgFill
    ProgFill.Parent = ProgBG

    Frame.Parent = NotifyHolder

    -- Padding inside frame
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 10),
    }).Parent = Frame

    -- Slide in
    Frame.Position = UDim2.new(1, 10, 0, 0)
    Tween(Frame, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Back)

    -- Progress countdown
    Tween(ProgFill, { Size = UDim2.new(0, 0, 1, 0) }, dur, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

    task.delay(dur, function()
        Tween(Frame, { Position = UDim2.new(1, 10, 0, 0) }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.35, function()
            Frame:Destroy()
        end)
    end)
end

-- Alias
NexusUI.Notification = NexusUI.Notify

-- ══════════════════════════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════════════════════════
--[[
    local Window = NexusUI:CreateWindow({
        Title   = "My Script",
        SubTitle = "Executor Hub",
        Theme   = "Default",
        Size    = UDim2.new(0, 580, 0, 420),
        Position = UDim2.new(0.5, -290, 0.5, -210),
        CanDrag  = true,
    })
]]
function NexusUI:CreateWindow(cfg)
    cfg = cfg or {}
    local T    = Themes[cfg.Theme or "Default"] or Themes.Default
    self._Theme = T

    -- ── Root ScreenGui ─────────────────────────────────────────
    local ScreenGui = New("ScreenGui", {
        Name            = "NexusUI",
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset  = true,
    })
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer.PlayerGui
    end

    -- Notification holder (top-right)
    NotifyHolder = New("Frame", {
        Name             = "NotifyHolder",
        Size             = UDim2.new(0, 280, 1, 0),
        Position         = UDim2.new(1, -290, 0, 10),
        BackgroundTransparency = 1,
        ZIndex           = 100,
    })
    New("UIListLayout", {
        Padding         = UDim.new(0, 8),
        SortOrder       = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
    }).Parent = NotifyHolder
    NotifyHolder.Parent = ScreenGui

    -- ── Main Window Frame ───────────────────────────────────────
    local WinSize = cfg.Size or UDim2.new(0, 600, 0, 440)
    local WinPos  = cfg.Position or UDim2.new(0.5, -300, 0.5, -220)

    local WindowFrame = New("Frame", {
        Name             = "Window",
        Size             = WinSize,
        Position         = WinPos,
        BackgroundColor3 = T.BG,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    })
    New("UICorner", { CornerRadius = UDim.new(0,10) }).Parent = WindowFrame
    New("UIStroke", { Color = T.Border2, Thickness = 1 }).Parent = WindowFrame
    WindowFrame.Parent = ScreenGui

    -- Drop shadow (visual depth)
    local Shadow = New("ImageLabel", {
        Name             = "Shadow",
        Size             = UDim2.new(1, 40, 1, 40),
        Position         = UDim2.new(0, -20, 0, -10),
        BackgroundTransparency = 1,
        Image            = "rbxassetid://5554236805",
        ImageColor3      = Color3.fromRGB(0,0,0),
        ImageTransparency = 0.6,
        ZIndex           = -1,
        ScaleType        = Enum.ScaleType.Slice,
        SliceCenter      = Rect.new(23,23,277,277),
    })
    Shadow.Parent = WindowFrame

    -- Intro animation
    WindowFrame.Size = UDim2.new(0, 0, 0, 0)
    WindowFrame.BackgroundTransparency = 1
    Tween(WindowFrame, {
        Size = WinSize,
        BackgroundTransparency = 0,
    }, 0.4, Enum.EasingStyle.Back)

    -- ── Title Bar ──────────────────────────────────────────────
    local TitleBar = New("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = T.BG2,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    })
    TitleBar.Parent = WindowFrame

    -- Gold accent line under titlebar
    New("Frame", {
        Size            = UDim2.new(1, 0, 0, 1),
        Position        = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        BackgroundTransparency = 0.6,
    }).Parent = TitleBar

    -- Window controls
    local CtrlFrame = New("Frame", {
        Size            = UDim2.new(0, 70, 0, 38),
        BackgroundTransparency = 1,
    })
    New("UIListLayout", {
        FillDirection   = Enum.FillDirection.Horizontal,
        Padding         = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    }).Parent = CtrlFrame
    New("UIPadding", { PaddingLeft = UDim.new(0, 12) }).Parent = CtrlFrame
    CtrlFrame.Parent = TitleBar

    local function MakeDot(col)
        local d = New("Frame", {
            Size            = UDim2.new(0, 11, 0, 11),
            BackgroundColor3 = col,
            BorderSizePixel = 0,
        })
        New("UICorner", { CornerRadius = UDim.new(1,0) }).Parent = d
        return d
    end
    local CloseBtn = MakeDot(Color("f4605c"))
    local MinBtn   = MakeDot(Color("fdbc40"))
    local MaxBtn   = MakeDot(Color("34c84a"))
    CloseBtn.Parent = CtrlFrame
    MinBtn.Parent   = CtrlFrame
    MaxBtn.Parent   = CtrlFrame

    -- Title text (centered)
    local TitleLabel = New("TextLabel", {
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text            = (cfg.Title or "NexusUI").." · "..(cfg.SubTitle or ""),
        TextColor3      = T.Text,
        TextSize        = 12,
        Font            = Enum.Font.GothamBold,
        LetterSpacing   = 1,
    })
    TitleLabel.Parent = TitleBar

    -- Ping dot
    local PingDot = New("Frame", {
        Size            = UDim2.new(0, 5, 0, 5),
        Position        = UDim2.new(0.5, 60, 0.5, -2),
        BackgroundColor3 = T.Green,
        BorderSizePixel = 0,
    })
    New("UICorner", { CornerRadius = UDim.new(1,0) }).Parent = PingDot
    PingDot.Parent = TitleBar

    -- Ping animation
    task.spawn(function()
        local t = 0
        while PingDot.Parent do
            t = t + task.wait(0.05)
            local alpha = (math.sin(t * 1.5) + 1) / 2
            PingDot.BackgroundTransparency = Lerp(0, 0.8, alpha)
        end
    end)

    -- ── Close / Minimize Behavior ───────────────────────────────
    local Visible = true
    CloseBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            Tween(WindowFrame, { Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1 }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            task.delay(0.35, function() ScreenGui:Destroy() end)
        end
    end)
    MinBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            Visible = not Visible
            if not Visible then
                Tween(WindowFrame, { Size = UDim2.new(0, WinSize.X.Offset, 0, 38) }, 0.3, Enum.EasingStyle.Quart)
            else
                Tween(WindowFrame, { Size = WinSize }, 0.3, Enum.EasingStyle.Back)
            end
        end
    end)

    -- ── Drag ────────────────────────────────────────────────────
    if cfg.CanDrag ~= false then
        local dragging, dragStart, startPos
        TitleBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging  = true
                dragStart = inp.Position
                startPos  = WindowFrame.Position
            end
        end)
        TitleBar.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = inp.Position - dragStart
                WindowFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- ── Left Tab Nav ────────────────────────────────────────────
    local TabNav = New("Frame", {
        Name             = "TabNav",
        Size             = UDim2.new(0, 130, 1, -38),
        Position         = UDim2.new(0, 0, 0, 38),
        BackgroundColor3 = T.BG2,
        BorderSizePixel  = 0,
    })
    -- Right border
    New("Frame", {
        Size            = UDim2.new(0, 1, 1, 0),
        Position        = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = T.Border,
        BorderSizePixel = 0,
    }).Parent = TabNav
    TabNav.Parent = WindowFrame

    local TabList = New("ScrollingFrame", {
        Size             = UDim2.new(1, 0, 1, -8),
        Position         = UDim2.new(0, 0, 0, 8),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.Border2,
        BorderSizePixel  = 0,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    New("UIListLayout", {
        Padding      = UDim.new(0, 2),
        SortOrder    = Enum.SortOrder.LayoutOrder,
    }).Parent = TabList
    New("UIPadding", {
        PaddingLeft  = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop   = UDim.new(0, 4),
    }).Parent = TabList
    TabList.Parent = TabNav

    -- ── Content Area ────────────────────────────────────────────
    local ContentArea = New("Frame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1, -130, 1, -38),
        Position         = UDim2.new(0, 130, 0, 38),
        BackgroundColor3 = T.BG,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    })
    ContentArea.Parent = WindowFrame

    -- ── Window Object ────────────────────────────────────────────
    local Window = {
        _Theme       = T,
        _ScreenGui   = ScreenGui,
        _Frame       = WindowFrame,
        _ContentArea = ContentArea,
        _TabList     = TabList,
        _Tabs        = {},
        _ActiveTab   = nil,
    }

    -- ──────────────────────────────────────────────
    --  ADD TAB
    -- ──────────────────────────────────────────────
    --[[
        local Tab = Window:AddTab({ Name = "Main", Icon = "⚡" })
    ]]
    function Window:AddTab(tabCfg)
        tabCfg = tabCfg or {}
        local T2 = self._Theme

        -- Tab button
        local TabBtn = New("Frame", {
            Size             = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = T2.BG3,
            BorderSizePixel  = 0,
            BackgroundTransparency = 1,
        })
        New("UICorner", { CornerRadius = UDim.new(0,6) }).Parent = TabBtn

        -- Left indicator
        local Indicator = New("Frame", {
            Size            = UDim2.new(0, 3, 0, 16),
            Position        = UDim2.new(0, 0, 0.5, -8),
            BackgroundColor3 = T2.Accent,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
        })
        New("UICorner", { CornerRadius = UDim.new(0,3) }).Parent = Indicator
        Indicator.Parent = TabBtn

        -- Icon + Label
        New("TextLabel", {
            Size            = UDim2.new(1, -8, 1, 0),
            Position        = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text            = (tabCfg.Icon or "") .. "  " .. (tabCfg.Name or "Tab"),
            TextColor3      = T2.Muted,
            TextSize        = 11,
            Font            = Enum.Font.Gotham,
            TextXAlignment  = Enum.TextXAlignment.Left,
        }).Parent = TabBtn
        TabBtn.Parent = self._TabList

        -- Content Frame for this tab
        local TabContent = New("ScrollingFrame", {
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T2.Border2,
            BorderSizePixel  = 0,
            CanvasSize       = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible          = false,
        })
        New("UIListLayout", {
            Padding   = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }).Parent = TabContent
        New("UIPadding", {
            PaddingLeft   = UDim.new(0, 12),
            PaddingRight  = UDim.new(0, 12),
            PaddingTop    = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
        }).Parent = TabContent
        TabContent.Parent = self._ContentArea

        -- Activate this tab
        local function Activate()
            -- Deactivate others
            for _, t in ipairs(self._Tabs) do
                t._Content.Visible = false
                Tween(t._Btn, { BackgroundTransparency = 1 }, 0.18)
                Tween(t._Indicator, { BackgroundTransparency = 1 }, 0.18)
                -- Text color
                for _, child in ipairs(t._Btn:GetChildren()) do
                    if child:IsA("TextLabel") then
                        Tween(child, { TextColor3 = T2.Muted }, 0.18)
                    end
                end
            end
            -- Activate this
            TabContent.Visible = true
            Tween(TabBtn, { BackgroundTransparency = 0.85 }, 0.2)
            Tween(Indicator, { BackgroundTransparency = 0 }, 0.2)
            for _, child in ipairs(TabBtn:GetChildren()) do
                if child:IsA("TextLabel") then
                    Tween(child, { TextColor3 = T2.Accent }, 0.2)
                    child.Font = Enum.Font.GothamBold
                end
            end
            self._ActiveTab = TabContent
        end

        -- Click
        TabBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                Activate()
            end
        end)
        -- Hover
        TabBtn.MouseEnter:Connect(function()
            if self._ActiveTab ~= TabContent then
                Tween(TabBtn, { BackgroundTransparency = 0.93 }, 0.15)
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if self._ActiveTab ~= TabContent then
                Tween(TabBtn, { BackgroundTransparency = 1 }, 0.15)
            end
        end)

        local TabObj = {
            _Theme     = T2,
            _Content   = TabContent,
            _Btn       = TabBtn,
            _Indicator = Indicator,
        }
        table.insert(self._Tabs, TabObj)

        -- Activate first tab automatically
        if #self._Tabs == 1 then
            Activate()
        end

        -- ──────────────────────────────────────────────
        --  ADD SECTION
        -- ──────────────────────────────────────────────
        --[[
            local Section = Tab:AddSection({ Name = "Combat" })
        ]]
        function TabObj:AddSection(secCfg)
            secCfg = secCfg or {}
            local T3 = self._Theme

            local SectionFrame = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = T3.BG3,
                BorderSizePixel  = 0,
                AutomaticSize    = Enum.AutomaticSize.Y,
            })
            New("UICorner", { CornerRadius = UDim.new(0,8) }).Parent = SectionFrame
            New("UIStroke", { Color = T3.Border, Thickness = 1 }).Parent = SectionFrame

            -- Section header
            if secCfg.Name and secCfg.Name ~= "" then
                local Header = New("Frame", {
                    Size            = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })
                -- Section name
                New("TextLabel", {
                    Size            = UDim2.new(1, -16, 1, 0),
                    Position        = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    Text            = secCfg.Name,
                    TextColor3      = T3.Accent,
                    TextSize        = 10,
                    Font            = Enum.Font.GothamBold,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                    LetterSpacing   = 2,
                }).Parent = Header
                -- Separator line
                New("Frame", {
                    Size            = UDim2.new(1, -24, 0, 1),
                    Position        = UDim2.new(0, 12, 1, -1),
                    BackgroundColor3 = T3.Border,
                    BorderSizePixel = 0,
                }).Parent = Header
                Header.Parent = SectionFrame
            end

            -- Item list inside section
            local ItemList = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize    = Enum.AutomaticSize.Y,
            })
            New("UIListLayout", {
                Padding   = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }).Parent = ItemList
            New("UIPadding", {
                PaddingLeft   = UDim.new(0, 10),
                PaddingRight  = UDim.new(0, 10),
                PaddingTop    = UDim.new(0, secCfg.Name and 6 or 8),
                PaddingBottom = UDim.new(0, 10),
            }).Parent = ItemList
            ItemList.Parent = SectionFrame
            SectionFrame.Parent = self._Content

            local Section = { _Theme = T3, _List = ItemList }

            -- ─────────────────────────────────────────
            --  HELPER: item base frame
            -- ─────────────────────────────────────────
            local function MakeItemBase(height)
                local f = New("Frame", {
                    Size             = UDim2.new(1, 0, 0, height or 34),
                    BackgroundColor3 = T3.BG4,
                    BorderSizePixel  = 0,
                })
                New("UICorner", { CornerRadius = UDim.new(0,6) }).Parent = f
                return f
            end

            local function MakeLabel(parent, text, xOff)
                return New("TextLabel", {
                    Size            = UDim2.new(0.6, 0, 1, 0),
                    Position        = UDim2.new(0, xOff or 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text            = text,
                    TextColor3      = T3.Text,
                    TextSize        = 11,
                    Font            = Enum.Font.Gotham,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                    Parent          = parent,
                })
            end

            -- ─────────────────────────────────────────
            --  ADD PARAGRAPH
            -- ─────────────────────────────────────────
            --[[
                Section:AddParagraph({
                    Title = "About",
                    Content = "This is a description paragraph.",
                })
            ]]
            function Section:AddParagraph(pCfg)
                pCfg = pCfg or {}
                local f = New("Frame", {
                    Size             = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = T3.BG4,
                    BorderSizePixel  = 0,
                    AutomaticSize    = Enum.AutomaticSize.Y,
                })
                New("UICorner",  { CornerRadius = UDim.new(0,6) }).Parent = f
                New("UIPadding", {
                    PaddingLeft   = UDim.new(0,12),
                    PaddingRight  = UDim.new(0,12),
                    PaddingTop    = UDim.new(0,8),
                    PaddingBottom = UDim.new(0,10),
                }).Parent = f

                if pCfg.Title and pCfg.Title ~= "" then
                    New("TextLabel", {
                        Size            = UDim2.new(1, 0, 0, 16),
                        BackgroundTransparency = 1,
                        Text            = pCfg.Title,
                        TextColor3      = T3.Accent,
                        TextSize        = 11,
                        Font            = Enum.Font.GothamBold,
                        TextXAlignment  = Enum.TextXAlignment.Left,
                    }).Parent = f
                end

                New("TextLabel", {
                    Size            = UDim2.new(1, 0, 0, 0),
                    Position        = UDim2.new(0, 0, 0, pCfg.Title and 20 or 0),
                    BackgroundTransparency = 1,
                    Text            = pCfg.Content or "",
                    TextColor3      = T3.Muted,
                    TextSize        = 11,
                    Font            = Enum.Font.Gotham,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                    TextWrapped     = true,
                    AutomaticSize   = Enum.AutomaticSize.Y,
                }).Parent = f

                f.Parent = self._List
            end

            -- ─────────────────────────────────────────
            --  ADD BUTTON
            -- ─────────────────────────────────────────
            --[[
                Section:AddButton({
                    Name     = "Kill All",
                    Callback = function() print("pressed") end,
                })
            ]]
            function Section:AddButton(bCfg)
                bCfg = bCfg or {}
                local f = MakeItemBase(34)

                local Lbl = MakeLabel(f, bCfg.Name or "Button")

                -- Right arrow
                local Arrow = New("TextLabel", {
                    Size            = UDim2.new(0, 24, 1, 0),
                    Position        = UDim2.new(1, -28, 0, 0),
                    BackgroundTransparency = 1,
                    Text            = "›",
                    TextColor3      = T3.Muted,
                    TextSize        = 18,
                    Font            = Enum.Font.GothamBold,
                })
                Arrow.Parent = f

                -- Hover / click
                f.MouseEnter:Connect(function()
                    Tween(f, { BackgroundColor3 = T3.BG3 }, 0.15)
                    Tween(Arrow, { TextColor3 = T3.Accent }, 0.15)
                    Tween(Lbl,   { TextColor3 = T3.Accent }, 0.15)
                end)
                f.MouseLeave:Connect(function()
                    Tween(f, { BackgroundColor3 = T3.BG4 }, 0.15)
                    Tween(Arrow, { TextColor3 = T3.Muted }, 0.15)
                    Tween(Lbl,   { TextColor3 = T3.Text  }, 0.15)
                end)
                f.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        Tween(f, { BackgroundColor3 = T3.Border }, 0.08)
                        task.delay(0.12, function()
                            Tween(f, { BackgroundColor3 = T3.BG4 }, 0.15)
                        end)
                        if bCfg.Callback then
                            task.spawn(bCfg.Callback)
                        end
                    end
                end)

                f.Parent = self._List
                f.Active = true
                f.Selectable = true
            end

            -- ─────────────────────────────────────────
            --  ADD TOGGLE
            -- ─────────────────────────────────────────
            --[[
                Section:AddToggle({
                    Name     = "God Mode",
                    Default  = false,
                    Flag     = "GodMode",
                    Callback = function(value) print(value) end,
                })
            ]]
            function Section:AddToggle(tCfg)
                tCfg = tCfg or {}
                local state = tCfg.Default or false
                local f = MakeItemBase(34)
                MakeLabel(f, tCfg.Name or "Toggle")

                -- Toggle pill
                local PillBG = New("Frame", {
                    Size            = UDim2.new(0, 42, 0, 22),
                    Position        = UDim2.new(1, -52, 0.5, -11),
                    BackgroundColor3 = state and T3.Accent or T3.Border2,
                    BorderSizePixel = 0,
                })
                New("UICorner", { CornerRadius = UDim.new(1,0) }).Parent = PillBG
                PillBG.Parent = f

                local Knob = New("Frame", {
                    Size            = UDim2.new(0, 16, 0, 16),
                    Position        = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    BorderSizePixel = 0,
                })
                New("UICorner", { CornerRadius = UDim.new(1,0) }).Parent = Knob
                Knob.Parent = PillBG

                local function SetState(newState)
                    state = newState
                    Tween(PillBG, { BackgroundColor3 = state and T3.Accent or T3.Border2 }, 0.2)
                    Tween(Knob,   { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, 0.2, Enum.EasingStyle.Back)
                    if tCfg.Flag then NexusUI._Flags[tCfg.Flag] = state end
                    if tCfg.Callback then task.spawn(tCfg.Callback, state) end
                end

                f.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        SetState(not state)
                    end
                end)
                f.MouseEnter:Connect(function() Tween(f, { BackgroundColor3 = T3.BG3 }, 0.15) end)
                f.MouseLeave:Connect(function() Tween(f, { BackgroundColor3 = T3.BG4 }, 0.15) end)

                f.Parent = self._List
                f.Active = true

                -- Return toggle ref for external control
                return { SetValue = SetState, GetValue = function() return state end }
            end

            -- ─────────────────────────────────────────
            --  ADD SLIDER
            -- ─────────────────────────────────────────
            --[[
                Section:AddSlider({
                    Name     = "Walk Speed",
                    Min      = 0,
                    Max      = 100,
                    Default  = 16,
                    Decimals = 0,
                    Suffix   = " SPS",
                    Flag     = "WalkSpeed",
                    Callback = function(value) print(value) end,
                })
            ]]
            function Section:AddSlider(sCfg)
                sCfg = sCfg or {}
                local min  = sCfg.Min     or 0
                local max  = sCfg.Max     or 100
                local dec  = sCfg.Decimals or 0
                local val  = math.clamp(sCfg.Default or min, min, max)
                local suf  = sCfg.Suffix  or ""

                local f = MakeItemBase(52)
                -- Label row
                MakeLabel(f, sCfg.Name or "Slider")

                -- Value display
                local ValLbl = New("TextLabel", {
                    Size            = UDim2.new(0, 60, 0, 20),
                    Position        = UDim2.new(1, -68, 0, 7),
                    BackgroundTransparency = 1,
                    Text            = Round(val, dec)..suf,
                    TextColor3      = T3.Accent,
                    TextSize        = 11,
                    Font            = Enum.Font.GothamBold,
                    TextXAlignment  = Enum.TextXAlignment.Right,
                })
                ValLbl.Parent = f

                -- Track
                local Track = New("Frame", {
                    Size            = UDim2.new(1, -20, 0, 6),
                    Position        = UDim2.new(0, 10, 1, -16),
                    BackgroundColor3 = T3.Border2,
                    BorderSizePixel = 0,
                })
                New("UICorner", { CornerRadius = UDim.new(1,0) }).Parent = Track
                Track.Parent = f

                -- Fill
                local pct = (val - min) / (max - min)
                local Fill = New("Frame", {
                    Size            = UDim2.new(pct, 0, 1, 0),
                    BackgroundColor3 = T3.Accent,
                    BorderSizePixel = 0,
                })
                New("UICorner", { CornerRadius = UDim.new(1,0) }).Parent = Fill
                Fill.Parent = Track

                -- Handle
                local Handle = New("Frame", {
                    Size            = UDim2.new(0, 14, 0, 14),
                    Position        = UDim2.new(pct, -7, 0.5, -7),
                    BackgroundColor3 = T3.Accent,
                    BorderSizePixel = 0,
                    ZIndex          = 5,
                })
                New("UICorner", { CornerRadius = UDim.new(1,0) }).Parent = Handle
                -- Inner dot
                New("Frame", {
                    Size            = UDim2.new(0, 6, 0, 6),
                    Position        = UDim2.new(0.5, -3, 0.5, -3),
                    BackgroundColor3 = T3.BG,
                    BorderSizePixel = 0,
                    [New("UICorner", { CornerRadius = UDim.new(1,0) })] = true,
                }).Parent = Handle
                Handle.Parent = Track

                local function UpdateSlider(xPos)
                    local trackAbs = Track.AbsolutePosition.X
                    local trackW   = Track.AbsoluteSize.X
                    local t        = math.clamp((xPos - trackAbs) / trackW, 0, 1)
                    val = Round(min + (max - min) * t, dec)
                    ValLbl.Text = val..suf
                    Tween(Fill,   { Size     = UDim2.new(t, 0, 1, 0) },       0.05, Enum.EasingStyle.Linear)
                    Tween(Handle, { Position = UDim2.new(t, -7, 0.5, -7) },   0.05, Enum.EasingStyle.Linear)
                    if sCfg.Flag then NexusUI._Flags[sCfg.Flag] = val end
                    if sCfg.Callback then task.spawn(sCfg.Callback, val) end
                end

                local dragging = false
                Track.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        UpdateSlider(inp.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSlider(inp.Position.X)
                    end
                end)

                f.MouseEnter:Connect(function() Tween(f, { BackgroundColor3 = T3.BG3 }, 0.15) end)
                f.MouseLeave:Connect(function() Tween(f, { BackgroundColor3 = T3.BG4 }, 0.15) end)
                f.Parent = self._List
                f.Active = true

                return {
                    SetValue = function(v)
                        val = math.clamp(v, min, max)
                        local t = (val - min) / (max - min)
                        ValLbl.Text = val..suf
                        Tween(Fill,   { Size = UDim2.new(t, 0, 1, 0) }, 0.15)
                        Tween(Handle, { Position = UDim2.new(t, -7, 0.5, -7) }, 0.15)
                    end,
                    GetValue = function() return val end
                }
            end

            -- ─────────────────────────────────────────
            --  ADD DROPDOWN
            -- ─────────────────────────────────────────
            --[[
                Section:AddDropdown({
                    Name     = "Team",
                    Options  = { "Red", "Blue", "Green" },
                    Default  = "Red",
                    Flag     = "Team",
                    Callback = function(value) print(value) end,
                })
            ]]
            function Section:AddDropdown(dCfg)
                dCfg = dCfg or {}
                local options = dCfg.Options or {}
                local selected = dCfg.Default or (options[1] or "Select...")
                local open = false

                local Wrap = New("Frame", {
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    AutomaticSize    = Enum.AutomaticSize.Y,
                    ClipsDescendants = false,
                    ZIndex           = 10,
                })

                local Header = New("Frame", {
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = T3.BG4,
                    BorderSizePixel  = 0,
                })
                New("UICorner", { CornerRadius = UDim.new(0,6) }).Parent = Header

                MakeLabel(Header, dCfg.Name or "Dropdown")

                local SelLbl = New("TextLabel", {
                    Size            = UDim2.new(0, 100, 1, 0),
                    Position        = UDim2.new(1, -108, 0, 0),
                    BackgroundTransparency = 1,
                    Text            = selected,
                    TextColor3      = T3.Accent,
                    TextSize        = 11,
                    Font            = Enum.Font.Gotham,
                    TextXAlignment  = Enum.TextXAlignment.Right,
                })
                SelLbl.Parent = Header

                local ChevronLbl = New("TextLabel", {
                    Size            = UDim2.new(0, 18, 1, 0),
                    Position        = UDim2.new(1, -20, 0, 0),
                    BackgroundTransparency = 1,
                    Text            = "⌄",
                    TextColor3      = T3.Muted,
                    TextSize        = 13,
                    Font            = Enum.Font.GothamBold,
                })
                ChevronLbl.Parent = Header
                Header.Parent = Wrap

                -- Dropdown list
                local ListFrame = New("Frame", {
                    Size             = UDim2.new(1, 0, 0, 0),
                    Position         = UDim2.new(0, 0, 1, 4),
                    BackgroundColor3 = T3.BG3,
                    BorderSizePixel  = 0,
                    ClipsDescendants = true,
                    ZIndex           = 20,
                })
                New("UICorner",  { CornerRadius = UDim.new(0,6) }).Parent = ListFrame
                New("UIStroke",  { Color = T3.Border2, Thickness = 1 }).Parent = ListFrame

                local ListLayout = New("UIListLayout", {
                    Padding   = UDim.new(0, 0),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                })
                ListLayout.Parent = ListFrame
                ListFrame.Parent = Wrap

                -- Build options
                local function BuildOptions()
                    for _, child in ipairs(ListFrame:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, opt in ipairs(options) do
                        local OptBtn = New("TextButton", {
                            Size             = UDim2.new(1, 0, 0, 30),
                            BackgroundColor3 = T3.BG3,
                            BorderSizePixel  = 0,
                            Text             = opt,
                            TextColor3       = opt == selected and T3.Accent or T3.Muted,
                            TextSize         = 11,
                            Font             = opt == selected and Enum.Font.GothamBold or Enum.Font.Gotham,
                            ZIndex           = 21,
                        })
                        OptBtn.MouseEnter:Connect(function()
                            Tween(OptBtn, { BackgroundColor3 = T3.BG4, TextColor3 = T3.Text }, 0.12)
                        end)
                        OptBtn.MouseLeave:Connect(function()
                            Tween(OptBtn, { BackgroundColor3 = T3.BG3, TextColor3 = opt == selected and T3.Accent or T3.Muted }, 0.12)
                        end)
                        OptBtn.MouseButton1Click:Connect(function()
                            selected = opt
                            SelLbl.Text = opt
                            if dCfg.Flag then NexusUI._Flags[dCfg.Flag] = opt end
                            if dCfg.Callback then task.spawn(dCfg.Callback, opt) end
                            BuildOptions()
                            -- Close
                            open = false
                            Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                            Tween(ChevronLbl, { Rotation = 0 }, 0.2)
                        end)
                        OptBtn.Parent = ListFrame
                    end
                end
                BuildOptions()

                local function ToggleOpen()
                    open = not open
                    local targetH = open and (#options * 30) or 0
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, targetH) }, 0.22, Enum.EasingStyle.Quart)
                    Tween(ChevronLbl, { Rotation = open and 180 or 0 }, 0.22)
                end

                Header.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then ToggleOpen() end
                end)
                Header.MouseEnter:Connect(function() Tween(Header, { BackgroundColor3 = T3.BG3 }, 0.15) end)
                Header.MouseLeave:Connect(function() Tween(Header, { BackgroundColor3 = T3.BG4 }, 0.15) end)

                Wrap.Parent = self._List
                return {
                    SetOptions  = function(opts) options = opts; BuildOptions() end,
                    SetValue    = function(v) selected = v; SelLbl.Text = v; BuildOptions() end,
                    GetValue    = function() return selected end,
                }
            end

            -- ─────────────────────────────────────────
            --  ADD MULTI-DROPDOWN
            -- ─────────────────────────────────────────
            --[[
                Section:AddMultiDropdown({
                    Name     = "Effects",
                    Options  = { "Blur", "Bloom", "DepthOfField" },
                    Default  = { "Blur" },
                    Flag     = "Effects",
                    Callback = function(values) print(table.concat(values, ", ")) end,
                })
            ]]
            function Section:AddMultiDropdown(mCfg)
                mCfg = mCfg or {}
                local options   = mCfg.Options or {}
                local selected  = {}
                -- Pre-select defaults
                for _, v in ipairs(mCfg.Default or {}) do selected[v] = true end
                local open = false

                local Wrap = New("Frame", {
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    AutomaticSize    = Enum.AutomaticSize.Y,
                    ZIndex           = 9,
                })

                local Header = New("Frame", {
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = T3.BG4,
                    BorderSizePixel  = 0,
                })
                New("UICorner", { CornerRadius = UDim.new(0,6) }).Parent = Header
                MakeLabel(Header, mCfg.Name or "Multi-Select")

                local SelLbl = New("TextLabel", {
                    Size            = UDim2.new(0, 110, 1, 0),
                    Position        = UDim2.new(1, -118, 0, 0),
                    BackgroundTransparency = 1,
                    Text            = "None",
                    TextColor3      = T3.Accent,
                    TextSize        = 10,
                    Font            = Enum.Font.Gotham,
                    TextXAlignment  = Enum.TextXAlignment.Right,
                    TextTruncate    = Enum.TextTruncate.AtEnd,
                })
                SelLbl.Parent = Header

                local ChevronLbl = New("TextLabel", {
                    Size            = UDim2.new(0, 18, 1, 0),
                    Position        = UDim2.new(1, -20, 0, 0),
                    BackgroundTransparency = 1,
                    Text            = "⌄",
                    TextColor3      = T3.Muted,
                    TextSize        = 13,
                    Font            = Enum.Font.GothamBold,
                })
                ChevronLbl.Parent = Header
                Header.Parent = Wrap

                local ListFrame = New("Frame", {
                    Size             = UDim2.new(1, 0, 0, 0),
                    Position         = UDim2.new(0, 0, 1, 4),
                    BackgroundColor3 = T3.BG3,
                    BorderSizePixel  = 0,
                    ClipsDescendants = true,
                    ZIndex           = 19,
                })
                New("UICorner", { CornerRadius = UDim.new(0,6) }).Parent = ListFrame
                New("UIStroke", { Color = T3.Border2, Thickness = 1 }).Parent = ListFrame
                New("UIListLayout", { Padding = UDim.new(0,0), SortOrder = Enum.SortOrder.LayoutOrder }).Parent = ListFrame
                ListFrame.Parent = Wrap

                local function UpdateLabel()
                    local keys = {}
                    for k, v in pairs(selected) do if v then table.insert(keys, k) end end
                    SelLbl.Text = #keys == 0 and "None" or table.concat(keys, ", ")
                    if mCfg.Flag then NexusUI._Flags[mCfg.Flag] = keys end
                    if mCfg.Callback then task.spawn(mCfg.Callback, keys) end
                end

                local function BuildOptions()
                    for _, child in ipairs(ListFrame:GetChildren()) do
                        if child:IsA("Frame") then child:Destroy() end
                    end
                    for _, opt in ipairs(options) do
                        local isSelected = selected[opt] or false
                        local Row = New("Frame", {
                            Size             = UDim2.new(1, 0, 0, 30),
                            BackgroundColor3 = T3.BG3,
                            BorderSizePixel  = 0,
                            ZIndex           = 20,
                        })
                        -- Checkbox
                        local CheckBox = New("Frame", {
                            Size            = UDim2.new(0, 14, 0, 14),
                            Position        = UDim2.new(1, -24, 0.5, -7),
                            BackgroundColor3 = isSelected and T3.Accent or T3.Border2,
                            BorderSizePixel = 0,
                            ZIndex          = 21,
                        })
                        New("UICorner", { CornerRadius = UDim.new(0,3) }).Parent = CheckBox
                        if isSelected then
                            New("TextLabel", {
                                Size            = UDim2.new(1,0,1,0),
                                BackgroundTransparency = 1,
                                Text            = "✓",
                                TextColor3      = T3.BG,
                                TextSize        = 9,
                                Font            = Enum.Font.GothamBold,
                                ZIndex          = 22,
                            }).Parent = CheckBox
                        end
                        CheckBox.Parent = Row

                        New("TextLabel", {
                            Size            = UDim2.new(1, -34, 1, 0),
                            Position        = UDim2.new(0, 10, 0, 0),
                            BackgroundTransparency = 1,
                            Text            = opt,
                            TextColor3      = isSelected and T3.Accent or T3.Muted,
                            TextSize        = 11,
                            Font            = isSelected and Enum.Font.GothamBold or Enum.Font.Gotham,
                            TextXAlignment  = Enum.TextXAlignment.Left,
                            ZIndex          = 21,
                        }).Parent = Row

                        Row.InputBegan:Connect(function(inp)
                            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                                selected[opt] = not selected[opt]
                                UpdateLabel()
                                BuildOptions()
                            end
                        end)
                        Row.MouseEnter:Connect(function() Tween(Row, { BackgroundColor3 = T3.BG4 }, 0.12) end)
                        Row.MouseLeave:Connect(function() Tween(Row, { BackgroundColor3 = T3.BG3 }, 0.12) end)
                        Row.Active = true
                        Row.Parent = ListFrame
                    end
                end
                BuildOptions()
                UpdateLabel()

                Header.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        open = not open
                        Tween(ListFrame, { Size = UDim2.new(1, 0, 0, open and (#options * 30) or 0) }, 0.22)
                        Tween(ChevronLbl, { Rotation = open and 180 or 0 }, 0.22)
                    end
                end)
                Header.MouseEnter:Connect(function() Tween(Header, { BackgroundColor3 = T3.BG3 }, 0.15) end)
                Header.MouseLeave:Connect(function() Tween(Header, { BackgroundColor3 = T3.BG4 }, 0.15) end)

                Wrap.Parent = self._List
                return {
                    GetValue   = function()
                        local k = {}; for v, s in pairs(selected) do if s then table.insert(k, v) end end; return k
                    end,
                    SetValue   = function(vals)
                        selected = {}; for _, v in ipairs(vals) do selected[v] = true end
                        UpdateLabel(); BuildOptions()
                    end,
                }
            end

            -- ─────────────────────────────────────────
            --  ADD KEYBIND
            -- ─────────────────────────────────────────
            --[[
                Section:AddKeybind({
                    Name     = "Toggle Menu",
                    Default  = Enum.KeyCode.RightShift,
                    Flag     = "MenuKey",
                    Callback = function(key) print(key.Name) end,
                })
            ]]
            function Section:AddKeybind(kCfg)
                kCfg = kCfg or {}
                local currentKey = kCfg.Default or Enum.KeyCode.Unknown
                local listening  = false

                local f = MakeItemBase(34)
                MakeLabel(f, kCfg.Name or "Keybind")

                local KeyBtn = New("TextButton", {
                    Size            = UDim2.new(0, 80, 0, 22),
                    Position        = UDim2.new(1, -88, 0.5, -11),
                    BackgroundColor3 = T3.BG3,
                    BorderSizePixel = 0,
                    Text            = "[" .. currentKey.Name .. "]",
                    TextColor3      = T3.Accent,
                    TextSize        = 10,
                    Font            = Enum.Font.GothamBold,
                })
                New("UICorner", { CornerRadius = UDim.new(0,4) }).Parent = KeyBtn
                New("UIStroke", { Color = T3.Border2, Thickness = 1 }).Parent = KeyBtn
                KeyBtn.Parent = f

                KeyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    KeyBtn.Text = "[ ... ]"
                    KeyBtn.TextColor3 = T3.Orange
                    Tween(KeyBtn, { BackgroundColor3 = T3.BG2 }, 0.15)
                end)

                UserInputService.InputBegan:Connect(function(inp, gameProcessed)
                    if listening and inp.UserInputType == Enum.UserInputType.Keyboard then
                        listening   = false
                        currentKey  = inp.KeyCode
                        KeyBtn.Text = "[" .. currentKey.Name .. "]"
                        Tween(KeyBtn, { TextColor3 = T3.Accent, BackgroundColor3 = T3.BG3 }, 0.2)
                        if kCfg.Flag then NexusUI._Flags[kCfg.Flag] = currentKey end
                        if kCfg.Callback then task.spawn(kCfg.Callback, currentKey) end
                    end
                end)

                f.MouseEnter:Connect(function() Tween(f, { BackgroundColor3 = T3.BG3 }, 0.15) end)
                f.MouseLeave:Connect(function() Tween(f, { BackgroundColor3 = T3.BG4 }, 0.15) end)
                f.Parent = self._List
                f.Active = true

                return { GetValue = function() return currentKey end }
            end

            -- ─────────────────────────────────────────
            --  ADD INPUT
            -- ─────────────────────────────────────────
            --[[
                Section:AddInput({
                    Name        = "Player Name",
                    Placeholder = "Enter name...",
                    Flag        = "TargetPlayer",
                    Callback    = function(text) print(text) end,
                })
            ]]
            function Section:AddInput(iCfg)
                iCfg = iCfg or {}

                local f = MakeItemBase(52)
                MakeLabel(f, iCfg.Name or "Input")

                local InputBox = New("TextBox", {
                    Size             = UDim2.new(1, -20, 0, 24),
                    Position         = UDim2.new(0, 10, 1, -30),
                    BackgroundColor3 = T3.BG2,
                    BorderSizePixel  = 0,
                    Text             = iCfg.Default or "",
                    PlaceholderText  = iCfg.Placeholder or "Type here...",
                    PlaceholderColor3 = T3.Faint,
                    TextColor3       = T3.Text,
                    TextSize         = 11,
                    Font             = Enum.Font.Gotham,
                    ClearTextOnFocus = iCfg.ClearOnFocus or false,
                })
                New("UICorner", { CornerRadius = UDim.new(0,5) }).Parent = InputBox
                New("UIStroke", { Color = T3.Border, Thickness = 1 }).Parent = InputBox
                New("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8) }).Parent = InputBox
                InputBox.Parent = f

                InputBox.Focused:Connect(function()
                    Tween(InputBox, { BackgroundColor3 = T3.BG3 }, 0.15)
                    -- stroke highlight
                    for _, c in ipairs(InputBox:GetChildren()) do
                        if c:IsA("UIStroke") then Tween(c, { Color = T3.Accent }, 0.15) end
                    end
                end)
                InputBox.FocusLost:Connect(function(enter)
                    Tween(InputBox, { BackgroundColor3 = T3.BG2 }, 0.15)
                    for _, c in ipairs(InputBox:GetChildren()) do
                        if c:IsA("UIStroke") then Tween(c, { Color = T3.Border }, 0.15) end
                    end
                    local txt = InputBox.Text
                    if iCfg.Flag then NexusUI._Flags[iCfg.Flag] = txt end
                    if iCfg.Callback then task.spawn(iCfg.Callback, txt) end
                end)

                f.MouseEnter:Connect(function() Tween(f, { BackgroundColor3 = T3.BG3 }, 0.15) end)
                f.MouseLeave:Connect(function() Tween(f, { BackgroundColor3 = T3.BG4 }, 0.15) end)
                f.Parent = self._List

                return {
                    GetValue = function() return InputBox.Text end,
                    SetValue = function(v) InputBox.Text = v end,
                }
            end

            -- ─────────────────────────────────────────
            --  ADD COLOR PICKER  (bonus)
            -- ─────────────────────────────────────────
            --[[
                Section:AddColorPicker({
                    Name     = "Highlight Color",
                    Default  = Color3.fromRGB(212, 168, 83),
                    Flag     = "HighlightColor",
                    Callback = function(color) print(color) end,
                })
            ]]
            function Section:AddColorPicker(cpCfg)
                cpCfg = cpCfg or {}
                local color = cpCfg.Default or T3.Accent

                local f = MakeItemBase(34)
                MakeLabel(f, cpCfg.Name or "Color")

                -- Swatch preview
                local Swatch = New("Frame", {
                    Size            = UDim2.new(0, 22, 0, 22),
                    Position        = UDim2.new(1, -30, 0.5, -11),
                    BackgroundColor3 = color,
                    BorderSizePixel = 0,
                })
                New("UICorner",  { CornerRadius = UDim.new(0,5) }).Parent = Swatch
                New("UIStroke",  { Color = T3.Border2, Thickness = 1 }).Parent = Swatch
                Swatch.Parent = f

                -- Color picker popup (simple HSV gradient)
                local PickerOpen = false
                local Popup = New("Frame", {
                    Size             = UDim2.new(1, 0, 0, 0),
                    Position         = UDim2.new(0, 0, 1, 4),
                    BackgroundColor3 = T3.BG3,
                    BorderSizePixel  = 0,
                    ClipsDescendants = true,
                    ZIndex           = 18,
                })
                New("UICorner", { CornerRadius = UDim.new(0,6) }).Parent = Popup
                New("UIStroke", { Color = T3.Border2, Thickness = 1 }).Parent = Popup

                local Gradient = New("ImageLabel", {
                    Size             = UDim2.new(1, -20, 0, 80),
                    Position         = UDim2.new(0, 10, 0, 10),
                    BackgroundColor3 = Color3.fromRGB(255,0,0),
                    BorderSizePixel  = 0,
                    Image            = "rbxassetid://4827052759",
                    ZIndex           = 19,
                })
                New("UICorner", { CornerRadius = UDim.new(0,4) }).Parent = Gradient
                Gradient.Parent = Popup

                -- Hue bar
                local HueBar = New("ImageLabel", {
                    Size             = UDim2.new(1, -20, 0, 14),
                    Position         = UDim2.new(0, 10, 0, 96),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    BorderSizePixel  = 0,
                    Image            = "rbxassetid://2615689005",
                    ZIndex           = 19,
                })
                New("UICorner", { CornerRadius = UDim.new(0,4) }).Parent = HueBar
                HueBar.Parent = Popup

                local Wrapper = New("Frame", {
                    Size            = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    AutomaticSize   = Enum.AutomaticSize.Y,
                    ZIndex          = 18,
                })
                f.Parent = Wrapper

                Popup.Parent = Wrapper
                Wrapper.Parent = self._List

                local hue, sat, val2 = color:ToHSV()

                local function FireColor()
                    color = Color3.fromHSV(hue, sat, val2)
                    Swatch.BackgroundColor3 = color
                    Gradient.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                    if cpCfg.Flag then NexusUI._Flags[cpCfg.Flag] = color end
                    if cpCfg.Callback then task.spawn(cpCfg.Callback, color) end
                end

                -- Gradient click (saturation / value)
                Gradient.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        local rel = (inp.Position - Gradient.AbsolutePosition)
                        sat   = math.clamp(rel.X / Gradient.AbsoluteSize.X, 0, 1)
                        val2  = math.clamp(1 - rel.Y / Gradient.AbsoluteSize.Y, 0, 1)
                        FireColor()
                    end
                end)
                -- Hue bar click
                HueBar.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        hue = math.clamp((inp.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                        FireColor()
                    end
                end)

                Swatch.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        PickerOpen = not PickerOpen
                        Tween(Popup, { Size = UDim2.new(1, 0, 0, PickerOpen and 120 or 0) }, 0.2)
                    end
                end)
                Swatch.Active = true

                return { GetValue = function() return color end }
            end

            -- ─────────────────────────────────────────
            --  ADD SEPARATOR  (bonus)
            -- ─────────────────────────────────────────
            function Section:AddSeparator()
                New("Frame", {
                    Size            = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = T3.Border,
                    BorderSizePixel = 0,
                    Parent          = self._List,
                })
            end

            -- ─────────────────────────────────────────
            --  ADD LABEL  (bonus)
            -- ─────────────────────────────────────────
            --[[
                local lbl = Section:AddLabel("Status: Idle")
                lbl.SetText("Status: Active")
            ]]
            function Section:AddLabel(text)
                local lbl = New("TextLabel", {
                    Size            = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    Text            = text or "",
                    TextColor3      = T3.Muted,
                    TextSize        = 11,
                    Font            = Enum.Font.Gotham,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                })
                New("UIPadding", { PaddingLeft = UDim.new(0,4) }).Parent = lbl
                lbl.Parent = self._List
                return { SetText = function(t) lbl.Text = t end }
            end

            return Section
        end -- AddSection

        return TabObj
    end -- AddTab

    return Window
end

-- ══════════════════════════════════════════════════════════════
--  SAVE MANAGER
-- ══════════════════════════════════════════════════════════════
--[[
    NexusUI.SaveManager:SetFolder("MyScript")
    NexusUI.SaveManager:Save("config1")
    NexusUI.SaveManager:Load("config1")
    NexusUI.SaveManager:List()  --> { "config1", "config2", ... }
]]
NexusUI.SaveManager = {}

local SM = NexusUI.SaveManager
SM._Folder = "NexusUI"

function SM:SetFolder(name)
    self._Folder = name or "NexusUI"
    if not isfolder(self._Folder) then
        makefolder(self._Folder)
    end
end

function SM:Save(name)
    name = name or "default"
    local path = self._Folder .. "/" .. name .. ".json"
    local encoded = HttpService:JSONEncode(NexusUI._Flags)
    if writefile then
        writefile(path, encoded)
        return true
    end
    return false
end

function SM:Load(name)
    name = name or "default"
    local path = self._Folder .. "/" .. name .. ".json"
    if isfile and isfile(path) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if ok and data then
            for k, v in pairs(data) do
                NexusUI._Flags[k] = v
            end
            return NexusUI._Flags
        end
    end
    return nil
end

function SM:List()
    if not isfolder(self._Folder) then return {} end
    local files = listfiles(self._Folder)
    local names = {}
    for _, f in ipairs(files) do
        local n = f:match("([^/\\]+)%.json$")
        if n then table.insert(names, n) end
    end
    return names
end

function SM:Delete(name)
    local path = self._Folder .. "/" .. name .. ".json"
    if isfile and isfile(path) then
        delfile(path)
        return true
    end
    return false
end

-- ══════════════════════════════════════════════════════════════
--  RETURN LIBRARY
-- ══════════════════════════════════════════════════════════════
return NexusUI

--[[
══════════════════════════════════════════════════════════════════
    FULL USAGE EXAMPLE
══════════════════════════════════════════════════════════════════

local Nexus = loadstring(game:HttpGet("YOUR_RAW_URL"))()

-- Create Window
local Win = Nexus:CreateWindow({
    Title   = "NexusHub",
    SubTitle = "v1.0.0",
    Theme   = "Default",  -- "Default" | "Ocean" | "Rose"
})

-- ── TAB 1: Combat ─────────────────────────────────────────────
local CombatTab = Win:AddTab({ Name = "Combat", Icon = "⚔" })

local CombatSection = CombatTab:AddSection({ Name = "GENERAL" })

CombatSection:AddParagraph({
    Title   = "About",
    Content = "Configure combat options below. Changes apply immediately.",
})

CombatSection:AddButton({
    Name     = "Kill All",
    Callback = function()
        for _, v in ipairs(game.Players:GetPlayers()) do
            if v ~= game.Players.LocalPlayer then
                -- your kill logic
            end
        end
    end,
})

CombatSection:AddToggle({
    Name     = "Silent Aim",
    Default  = false,
    Flag     = "SilentAim",
    Callback = function(v)
        -- toggle logic
    end,
})

CombatSection:AddSlider({
    Name     = "FOV",
    Min      = 1,
    Max      = 180,
    Default  = 90,
    Suffix   = "°",
    Flag     = "AimFOV",
    Callback = function(v)
        -- apply FOV
    end,
})

-- ── TAB 2: Player ──────────────────────────────────────────────
local PlayerTab = Win:AddTab({ Name = "Player", Icon = "👤" })

local MoveSection = PlayerTab:AddSection({ Name = "MOVEMENT" })

MoveSection:AddSlider({
    Name     = "Walk Speed",
    Min      = 0, Max = 200, Default = 16,
    Flag     = "WalkSpeed",
    Callback = function(v)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end,
})

MoveSection:AddSlider({
    Name     = "Jump Power",
    Min      = 0, Max = 200, Default = 50,
    Flag     = "JumpPower",
    Callback = function(v)
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = v
    end,
})

MoveSection:AddKeybind({
    Name     = "Fly Toggle",
    Default  = Enum.KeyCode.F,
    Flag     = "FlyKey",
    Callback = function(key) end,
})

-- ── TAB 3: Visual ──────────────────────────────────────────────
local VisualTab = Win:AddTab({ Name = "Visual", Icon = "🎨" })

local ESPSection = VisualTab:AddSection({ Name = "ESP" })

ESPSection:AddToggle({ Name = "Player ESP", Flag = "ESP_Players" })
ESPSection:AddToggle({ Name = "Box ESP",    Flag = "ESP_Box" })
ESPSection:AddToggle({ Name = "Name ESP",   Flag = "ESP_Name" })

ESPSection:AddColorPicker({
    Name     = "ESP Color",
    Default  = Color3.fromRGB(212, 168, 83),
    Flag     = "ESP_Color",
    Callback = function(col) end,
})

-- ── TAB 4: Misc ────────────────────────────────────────────────
local MiscTab = Win:AddTab({ Name = "Misc", Icon = "⚙" })
local MiscSection = MiscTab:AddSection({ Name = "CONFIG" })

MiscSection:AddInput({
    Name        = "Target Player",
    Placeholder = "Enter username...",
    Flag        = "TargetPlayer",
    Callback    = function(txt) end,
})

MiscSection:AddDropdown({
    Name     = "Team",
    Options  = { "Any", "Red Team", "Blue Team" },
    Default  = "Any",
    Flag     = "FilterTeam",
    Callback = function(v) end,
})

MiscSection:AddMultiDropdown({
    Name    = "Effects",
    Options = { "Blur", "Bloom", "DepthOfField", "SunRays" },
    Default = {},
    Flag    = "ActiveEffects",
    Callback = function(vals) print(table.concat(vals, ", ")) end,
})

-- Notifications
Nexus:Notify({
    Title    = "NexusHub",
    Message  = "Script loaded successfully!",
    Type     = "success",  -- success | error | warning | info
    Duration = 4,
})

-- Save Manager
Nexus.SaveManager:SetFolder("NexusHub")
Nexus.SaveManager:Save("profile1")
-- Nexus.SaveManager:Load("profile1")

══════════════════════════════════════════════════════════════════
]]
