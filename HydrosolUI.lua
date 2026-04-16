-- ╔══════════════════════════════════════════════════════╗
-- ║              HydrosolUI  ·  v1.0.0                  ║
-- ║   A sleek, smooth exploit UI library for Roblox     ║
-- ╚══════════════════════════════════════════════════════╝

local RunService  = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local cloneref = (cloneref or clonereference or function(i) return i end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local HttpService       = cloneref(game:GetService("HttpService"))

-- ──────────────────────────────────────────────────────
-- 0.  PRIVATE HELPERS
-- ──────────────────────────────────────────────────────
local function tween(obj, info, goals)
    return TweenService:Create(obj, info, goals):Play()
end

local function lerp(a, b, t) return a + (b - a) * t end

local function deepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = (type(v) == "table") and deepCopy(v) or v
    end
    return copy
end

local function round(n, dec)
    dec = dec or 0
    local m = 10 ^ dec
    return math.floor(n * m + 0.5) / m
end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function makePadding(parent, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 6)
    p.PaddingRight  = UDim.new(0, right  or 6)
    p.PaddingBottom = UDim.new(0, bottom or 6)
    p.PaddingLeft   = UDim.new(0, left   or 6)
    p.Parent = parent
    return p
end

local function makeStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color        = color        or Color3.fromRGB(60, 60, 80)
    s.Thickness    = thickness    or 1
    s.Transparency = transparency or 0.6
    s.Parent = parent
    return s
end

local function newLabel(parent, text, size, color, font, xAlign)
    local l = Instance.new("TextLabel")
    l.Parent          = parent
    l.BackgroundTransparency = 1
    l.Text            = text or ""
    l.TextSize        = size or 13
    l.TextColor3      = color or Color3.fromRGB(220, 220, 230)
    l.Font            = font  or Enum.Font.GothamMedium
    l.TextXAlignment  = xAlign or Enum.TextXAlignment.Left
    l.TextWrapped     = true
    l.AutomaticSize   = Enum.AutomaticSize.Y
    l.Size            = UDim2.new(1, 0, 0, 0)
    return l
end

-- ──────────────────────────────────────────────────────
-- 1.  THEME
-- ──────────────────────────────────────────────────────
local Theme = {
    Background   = Color3.fromRGB(12,  12,  18),
    Surface      = Color3.fromRGB(18,  18,  26),
    SurfaceAlt   = Color3.fromRGB(24,  24,  34),
    Elevated     = Color3.fromRGB(30,  30,  44),
    Border       = Color3.fromRGB(50,  50,  72),
    Accent       = Color3.fromRGB(108, 100, 255),   -- purple-blue
    AccentDim    = Color3.fromRGB(70,  65,  180),
    AccentGlow   = Color3.fromRGB(140, 130, 255),
    TextPrimary  = Color3.fromRGB(230, 228, 255),
    TextSecondary= Color3.fromRGB(140, 138, 168),
    TextMuted    = Color3.fromRGB(80,  80,  110),
    Success      = Color3.fromRGB(80,  220, 140),
    Warning      = Color3.fromRGB(255, 200, 80),
    Error        = Color3.fromRGB(255, 90,  90),
    ToggleOff    = Color3.fromRGB(45,  45,  60),
    SliderFill   = Color3.fromRGB(108, 100, 255),
    SliderTrack  = Color3.fromRGB(35,  35,  50),
    Notification = Color3.fromRGB(22,  22,  32),
}

-- ──────────────────────────────────────────────────────
-- 2.  ICON HELPER  (emoji fallbacks – works without CDN)
-- ──────────────────────────────────────────────────────
local Icons = {
    search    = "🔍",
    close     = "✕",
    check     = "✓",
    chevdown  = "▾",
    chevright = "▸",
    settings  = "⚙",
    key       = "⌨",
    plus      = "+",
    minus     = "−",
    info      = "ℹ",
    warning   = "⚠",
    success   = "✓",
    error     = "✕",
    window    = "⊞",
    tab       = "⊟",
}

-- ──────────────────────────────────────────────────────
-- 3.  CONFIG / SAVE MANAGER
-- ──────────────────────────────────────────────────────
local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager.new(folderName)
    local self = setmetatable({}, SaveManager)
    self.folder   = folderName or "HydrosolUI"
    self.autoFile = "autoload"
    self._data    = {}
    self._flags   = {}   -- flag → getter function
    if not isfolder(self.folder) then
        makefolder(self.folder)
    end
    return self
end

function SaveManager:_path(name)
    return self.folder .. "/" .. name .. ".json"
end

function SaveManager:AddFlag(flag, getter)
    self._flags[flag] = getter
end

function SaveManager:_collect()
    local out = {}
    for flag, getter in pairs(self._flags) do
        local ok, val = pcall(getter)
        if ok then out[flag] = val end
    end
    return out
end

function SaveManager:Save(name)
    name = name or "default"
    local data = self._collect and self:_collect() or {}
    local ok, err = pcall(writefile, self:_path(name), HttpService:JSONEncode(data))
    return ok, err
end

function SaveManager:Load(name)
    name = name or "default"
    local path = self:_path(name)
    if not isfile(path) then return false, "file not found" end
    local ok, raw = pcall(readfile, path)
    if not ok then return false, raw end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 then return false, data end
    self._data = data
    return true, data
end

function SaveManager:SetAutoload(name)
    local ok = pcall(writefile, self:_path(self.autoFile), name)
    return ok
end

function SaveManager:LoadAutoloadConfig()
    local path = self:_path(self.autoFile)
    if not isfile(path) then return false end
    local ok, name = pcall(readfile, path)
    if not ok or name == "" then return false end
    return self:Load(name)
end

function SaveManager:GetValue(flag)
    return self._data[flag]
end

function SaveManager:ListConfigs()
    local files = {}
    for _, f in ipairs(listfiles(self.folder)) do
        local n = f:match("[^/\\]+$"):gsub("%.json$", "")
        if n ~= self.autoFile then
            table.insert(files, n)
        end
    end
    return files
end

-- ──────────────────────────────────────────────────────
-- 4.  NOTIFICATION SYSTEM
-- ──────────────────────────────────────────────────────
local NotifyHolder  -- created lazily inside CreateWindow

local function ensureNotifyHolder()
    if NotifyHolder and NotifyHolder.Parent then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "HydrosolNotify"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

    NotifyHolder = Instance.new("Frame")
    NotifyHolder.Name = "NotifyHolder"
    NotifyHolder.BackgroundTransparency = 1
    NotifyHolder.Size = UDim2.new(0, 320, 1, 0)
    NotifyHolder.Position = UDim2.new(1, -330, 0, 0)
    NotifyHolder.Parent = sg

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.VerticalAlignment = Enum.VerticalAlignment.Bottom
    list.Padding = UDim.new(0, 6)
    list.Parent = NotifyHolder

    makePadding(NotifyHolder, 8, 8, 8, 8)
end

local function Notify(opts)
    opts = opts or {}
    local title    = opts.Title    or "HydrosolUI"
    local message  = opts.Message  or ""
    local duration = opts.Duration or 4
    local nType    = opts.Type     or "info"   -- info | success | warning | error

    ensureNotifyHolder()

    local typeColor = ({
        info    = Theme.Accent,
        success = Theme.Success,
        warning = Theme.Warning,
        error   = Theme.Error,
    })[nType] or Theme.Accent

    local icon = ({
        info    = Icons.info,
        success = Icons.success,
        warning = Icons.warning,
        error   = Icons.error,
    })[nType] or Icons.info

    -- outer card
    local card = Instance.new("Frame")
    card.Name = "Notify"
    card.Size = UDim2.new(1, 0, 0, 64)
    card.BackgroundColor3 = Theme.Notification
    card.BackgroundTransparency = 1
    card.ClipsDescendants = true
    card.Parent = NotifyHolder
    makeCorner(card, 10)
    makeStroke(card, typeColor, 1, 0.5)

    -- accent bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = typeColor
    bar.BorderSizePixel = 0
    bar.Parent = card
    makeCorner(bar, 2)

    -- icon
    local ico = Instance.new("TextLabel")
    ico.BackgroundTransparency = 1
    ico.Text = icon
    ico.TextColor3 = typeColor
    ico.TextSize = 16
    ico.Font = Enum.Font.GothamBold
    ico.Size = UDim2.new(0, 24, 1, 0)
    ico.Position = UDim2.new(0, 10, 0, 0)
    ico.Parent = card

    -- title
    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1
    tl.Text = title
    tl.TextColor3 = Theme.TextPrimary
    tl.TextSize = 13
    tl.Font = Enum.Font.GothamBold
    tl.Size = UDim2.new(1, -44, 0, 20)
    tl.Position = UDim2.new(0, 40, 0, 8)
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.Parent = card

    -- message
    local ml = Instance.new("TextLabel")
    ml.BackgroundTransparency = 1
    ml.Text = message
    ml.TextColor3 = Theme.TextSecondary
    ml.TextSize = 12
    ml.Font = Enum.Font.Gotham
    ml.Size = UDim2.new(1, -44, 0, 28)
    ml.Position = UDim2.new(0, 40, 0, 28)
    ml.TextXAlignment = Enum.TextXAlignment.Left
    ml.TextWrapped = true
    ml.Parent = card

    -- progress bar
    local prog = Instance.new("Frame")
    prog.Size = UDim2.new(1, 0, 0, 2)
    prog.Position = UDim2.new(0, 0, 1, -2)
    prog.BackgroundColor3 = typeColor
    prog.BorderSizePixel = 0
    prog.Parent = card

    -- animate in
    tween(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.08,
        Size = UDim2.new(1, 0, 0, 64),
    })

    -- progress countdown
    tween(prog, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2),
    })

    task.delay(duration, function()
        tween(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 20, 0, card.Position.Y.Offset),
        })
        task.delay(0.35, function() card:Destroy() end)
    end)

    return card
end

-- ──────────────────────────────────────────────────────
-- 5.  MAIN LIBRARY TABLE
-- ──────────────────────────────────────────────────────
local HydrosolUI = {}
HydrosolUI.__index = HydrosolUI
HydrosolUI.Version = "1.0.0"
HydrosolUI.Theme   = Theme
HydrosolUI.Notify  = Notify

-- ──────────────────────────────────────────────────────
-- 6.  WINDOW
-- ──────────────────────────────────────────────────────
function HydrosolUI:CreateWindow(opts)
    opts = opts or {}
    local winTitle   = opts.Title   or "HydrosolUI"
    local winSize    = opts.Size    or UDim2.new(0, 780, 0, 480)
    local saveFolder = opts.SaveFolder or (winTitle:gsub("%s+", "") .. "Configs")
    local hideKey    = opts.ToggleKey or Enum.KeyCode.RightAlt

    -- ensure notify holder exists
    ensureNotifyHolder()

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "HydrosolUI_" .. winTitle:gsub("%s+", "")
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 100
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

    -- Blur (decorative — only if supported)
    pcall(function()
        local blur = Instance.new("BlurEffect")
        blur.Size = 0
        blur.Parent = game:GetService("Lighting")
        tween(blur, TweenInfo.new(0.4), { Size = 8 })
        sg:GetPropertyChangedSignal("Parent"):Connect(function()
            if not sg.Parent then
                tween(blur, TweenInfo.new(0.4), { Size = 0 })
                task.delay(0.5, function() blur:Destroy() end)
            end
        end)
    end)

    -- Root frame (drop shadow illusion via darker outer)
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 4, 0.5, 6)
    shadow.Size = winSize
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.5
    shadow.BorderSizePixel = 0
    shadow.Parent = sg
    makeCorner(shadow, 14)

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.Position = UDim2.new(0.5, 0, 0.5, 0)
    root.Size = winSize
    root.BackgroundColor3 = Theme.Background
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.Parent = sg
    makeCorner(root, 12)
    makeStroke(root, Theme.Border, 1, 0.4)

    -- subtle gradient overlay
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(30, 28, 50)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 12, 18)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(12, 12, 18)),
    })
    grad.Rotation = 135
    grad.Parent = root

    -- ── Title bar ──────────────────────────────────────
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 44)
    titleBar.BackgroundColor3 = Theme.Surface
    titleBar.BorderSizePixel = 0
    titleBar.Parent = root

    local tbGrad = Instance.new("UIGradient")
    tbGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 26, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 26)),
    })
    tbGrad.Rotation = 90
    tbGrad.Parent = titleBar

    -- logo dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0, 14, 0.5, -5)
    dot.BackgroundColor3 = Theme.Accent
    dot.BorderSizePixel = 0
    dot.Parent = titleBar
    makeCorner(dot, 5)

    local dot2 = Instance.new("Frame")
    dot2.Size = UDim2.new(0, 6, 0, 6)
    dot2.Position = UDim2.new(0, 20, 0.5, -1)
    dot2.BackgroundColor3 = Theme.AccentGlow
    dot2.BackgroundTransparency = 0.5
    dot2.BorderSizePixel = 0
    dot2.Parent = titleBar
    makeCorner(dot2, 3)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = winTitle
    titleLbl.TextColor3 = Theme.TextPrimary
    titleLbl.TextSize = 14
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Position = UDim2.new(0, 36, 0, 0)
    titleLbl.Size = UDim2.new(0.5, 0, 1, 0)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = titleBar

    -- version badge
    local vBadge = Instance.new("TextLabel")
    vBadge.BackgroundColor3 = Theme.Elevated
    vBadge.TextColor3 = Theme.TextMuted
    vBadge.Text = "v" .. HydrosolUI.Version
    vBadge.TextSize = 10
    vBadge.Font = Enum.Font.GothamMedium
    vBadge.Size = UDim2.new(0, 40, 0, 18)
    vBadge.Position = UDim2.new(0, 130, 0.5, -9)
    vBadge.Parent = titleBar
    makeCorner(vBadge, 4)

    -- close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
    closeBtn.BackgroundTransparency = 0.4
    closeBtn.Text = Icons.close
    closeBtn.TextColor3 = Theme.Error
    closeBtn.TextSize = 13
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    makeCorner(closeBtn, 7)

    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0, TextColor3 = Color3.fromRGB(255, 100, 100) })
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.4, TextColor3 = Theme.Error })
    end)
    closeBtn.MouseButton1Click:Connect(function()
        tween(root,   TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Size = UDim2.new(0, winSize.X.Offset, 0, 0) })
        tween(shadow, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Size = UDim2.new(0, winSize.X.Offset, 0, 0) })
        task.delay(0.35, function() sg:Destroy() end)
    end)

    -- minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -72, 0.5, -14)
    minBtn.BackgroundColor3 = Theme.Elevated
    minBtn.BackgroundTransparency = 0.4
    minBtn.Text = Icons.minus
    minBtn.TextColor3 = Theme.TextSecondary
    minBtn.TextSize = 15
    minBtn.Font = Enum.Font.GothamBold
    minBtn.BorderSizePixel = 0
    minBtn.Parent = titleBar
    makeCorner(minBtn, 7)

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tween(root,   TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Size = UDim2.new(0, winSize.X.Offset, 0, 44) })
            tween(shadow, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Size = UDim2.new(0, winSize.X.Offset, 0, 44) })
        else
            tween(root,   TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Size = winSize })
            tween(shadow, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Size = winSize })
        end
    end)

    -- dragging
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = inp.Position
            startPos  = root.Position
        end
    end)
    titleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and dragStart then
            local delta = UserInputService:GetMouseLocation() - Vector2.new(dragStart.X, dragStart.Y)
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            root.Position   = newPos
            shadow.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset + 4, newPos.Y.Scale, newPos.Y.Offset + 6)
        end
    end)

    -- toggle key
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == hideKey then
            local vis = not root.Visible
            root.Visible   = vis
            shadow.Visible = vis
        end
    end)

    -- ── Sidebar (tab icons) ────────────────────────────
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 44, 1, -44)
    sidebar.Position = UDim2.new(0, 0, 0, 44)
    sidebar.BackgroundColor3 = Theme.Surface
    sidebar.BorderSizePixel = 0
    sidebar.Parent = root

    local sideList = Instance.new("UIListLayout")
    sideList.SortOrder = Enum.SortOrder.LayoutOrder
    sideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sideList.Padding = UDim.new(0, 4)
    sideList.Parent = sidebar
    makePadding(sidebar, 8, 0, 8, 0)

    -- side divider
    local sdiv = Instance.new("Frame")
    sdiv.Name = "SideDivider"
    sdiv.Size = UDim2.new(0, 1, 1, -44)
    sdiv.Position = UDim2.new(0, 44, 0, 44)
    sdiv.BackgroundColor3 = Theme.Border
    sdiv.BackgroundTransparency = 0.5
    sdiv.BorderSizePixel = 0
    sdiv.Parent = root

    -- ── Content area ───────────────────────────────────
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -44, 1, -44)
    content.Position = UDim2.new(0, 44, 0, 44)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = root

    -- ── Entrance animation ─────────────────────────────
    root.Size = UDim2.new(0, winSize.X.Offset, 0, 0)
    root.BackgroundTransparency = 1
    tween(root, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = winSize,
        BackgroundTransparency = 0,
    })
    shadow.Size = UDim2.new(0, winSize.X.Offset, 0, 0)
    tween(shadow, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = winSize,
    })

    -- ── Window object ─────────────────────────────────
    local Window = {}
    Window._tabs       = {}
    Window._activeTab  = nil
    Window._sidebar    = sidebar
    Window._content    = content
    Window._root       = root
    Window._sg         = sg
    Window.SaveManager = SaveManager.new(saveFolder)
    Window.Notify      = Notify

    -- ── AddTab ─────────────────────────────────────────
    function Window:AddTab(tabOpts)
        tabOpts = tabOpts or {}
        local tabName = tabOpts.Title or ("Tab " .. (#self._tabs + 1))
        local tabIcon = tabOpts.Icon  or Icons.tab

        -- sidebar icon button
        local sBtn = Instance.new("TextButton")
        sBtn.Size = UDim2.new(0, 32, 0, 32)
        sBtn.BackgroundColor3 = Theme.Elevated
        sBtn.BackgroundTransparency = 1
        sBtn.Text = tabIcon
        sBtn.TextColor3 = Theme.TextMuted
        sBtn.TextSize = 16
        sBtn.Font = Enum.Font.GothamBold
        sBtn.BorderSizePixel = 0
        sBtn.LayoutOrder = #self._tabs + 1
        sBtn.Parent = self._sidebar
        makeCorner(sBtn, 8)

        -- tooltip
        local tooltip = Instance.new("TextLabel")
        tooltip.BackgroundColor3 = Theme.Elevated
        tooltip.TextColor3 = Theme.TextPrimary
        tooltip.Text = tabName
        tooltip.TextSize = 11
        tooltip.Font = Enum.Font.GothamMedium
        tooltip.Size = UDim2.new(0, 90, 0, 22)
        tooltip.Position = UDim2.new(1, 8, 0.5, -11)
        tooltip.BackgroundTransparency = 0
        tooltip.Visible = false
        tooltip.ZIndex = 20
        tooltip.Parent = sBtn
        makeCorner(tooltip, 5)
        makePadding(tooltip, 3, 6, 3, 6)

        sBtn.MouseEnter:Connect(function()
            tooltip.Visible = true
            tween(sBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.6, TextColor3 = Theme.TextPrimary })
        end)
        sBtn.MouseLeave:Connect(function()
            tooltip.Visible = false
        end)

        -- page frame
        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_" .. tabName
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Theme.Accent
        page.ScrollBarImageTransparency = 0.4
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = self._content

        local pageList = Instance.new("UIListLayout")
        pageList.SortOrder = Enum.SortOrder.LayoutOrder
        pageList.Padding = UDim.new(0, 0)
        pageList.Parent = page

        makePadding(page, 10, 10, 10, 10)

        -- two-column layout helper
        local colRow = Instance.new("Frame")
        colRow.Name = "ColRow"
        colRow.Size = UDim2.new(1, 0, 0, 0)
        colRow.AutomaticSize = Enum.AutomaticSize.Y
        colRow.BackgroundTransparency = 1
        colRow.LayoutOrder = 1
        colRow.Parent = page

        local colLayout = Instance.new("UIListLayout")
        colLayout.FillDirection = Enum.FillDirection.Horizontal
        colLayout.SortOrder = Enum.SortOrder.LayoutOrder
        colLayout.Padding = UDim.new(0, 8)
        colLayout.Parent = colRow

        -- left column
        local colLeft = Instance.new("Frame")
        colLeft.Name = "ColLeft"
        colLeft.Size = UDim2.new(0.5, -4, 0, 0)
        colLeft.AutomaticSize = Enum.AutomaticSize.Y
        colLeft.BackgroundTransparency = 1
        colLeft.LayoutOrder = 1
        colLeft.Parent = colRow

        local leftList = Instance.new("UIListLayout")
        leftList.SortOrder = Enum.SortOrder.LayoutOrder
        leftList.Padding = UDim.new(0, 6)
        leftList.Parent = colLeft

        -- right column
        local colRight = Instance.new("Frame")
        colRight.Name = "ColRight"
        colRight.Size = UDim2.new(0.5, -4, 0, 0)
        colRight.AutomaticSize = Enum.AutomaticSize.Y
        colRight.BackgroundTransparency = 1
        colRight.LayoutOrder = 2
        colRight.Parent = colRow

        local rightList = Instance.new("UIListLayout")
        rightList.SortOrder = Enum.SortOrder.LayoutOrder
        rightList.Padding = UDim.new(0, 6)
        rightList.Parent = colRight

        -- Tab object
        local Tab = {}
        Tab._page     = page
        Tab._colLeft  = colLeft
        Tab._colRight = colRight
        Tab._colRow   = colRow
        Tab._counter  = { left = 0, right = 0 }
        Tab._sBtn     = sBtn
        Tab._window   = self

        -- pick which column gets next widget (alternating)
        function Tab:_nextCol()
            if self._counter.left <= self._counter.right then
                self._counter.left = self._counter.left + 1
                return self._colLeft, self._counter.left
            else
                self._counter.right = self._counter.right + 1
                return self._colRight, self._counter.right
            end
        end

        -- Force specific column
        function Tab:_col(side)
            if side == "right" then
                self._counter.right = self._counter.right + 1
                return self._colRight, self._counter.right
            else
                self._counter.left = self._counter.left + 1
                return self._colLeft, self._counter.left
            end
        end

        -- ── section card helper ────────────────────────
        local function makeSection(parent, order, title)
            local sec = Instance.new("Frame")
            sec.Name = "Section_" .. (title or "")
            sec.Size = UDim2.new(1, 0, 0, 0)
            sec.AutomaticSize = Enum.AutomaticSize.Y
            sec.BackgroundColor3 = Theme.Surface
            sec.BackgroundTransparency = 0.2
            sec.BorderSizePixel = 0
            sec.LayoutOrder = order
            sec.Parent = parent
            makeCorner(sec, 10)
            makeStroke(sec, Theme.Border, 1, 0.55)

            local secList = Instance.new("UIListLayout")
            secList.SortOrder = Enum.SortOrder.LayoutOrder
            secList.Padding = UDim.new(0, 0)
            secList.Parent = sec

            if title and title ~= "" then
                local header = Instance.new("Frame")
                header.Size = UDim2.new(1, 0, 0, 28)
                header.BackgroundColor3 = Theme.Elevated
                header.BackgroundTransparency = 0.3
                header.BorderSizePixel = 0
                header.LayoutOrder = 0
                header.Parent = sec

                local uic = Instance.new("UICorner")
                uic.CornerRadius = UDim.new(0, 10)
                uic.Parent = header

                -- flatten bottom corners
                local bot = Instance.new("Frame")
                bot.Size = UDim2.new(1, 0, 0.5, 0)
                bot.Position = UDim2.new(0, 0, 0.5, 0)
                bot.BackgroundColor3 = Theme.Elevated
                bot.BackgroundTransparency = 0.3
                bot.BorderSizePixel = 0
                bot.Parent = header

                local hl = newLabel(header, title, 11, Theme.TextSecondary, Enum.Font.GothamBold)
                hl.Size = UDim2.new(1, -12, 1, 0)
                hl.Position = UDim2.new(0, 10, 0, 0)
                hl.AutomaticSize = Enum.AutomaticSize.None
                hl.TextYAlignment = Enum.TextYAlignment.Center
            end

            local body = Instance.new("Frame")
            body.Name = "Body"
            body.Size = UDim2.new(1, 0, 0, 0)
            body.AutomaticSize = Enum.AutomaticSize.Y
            body.BackgroundTransparency = 1
            body.LayoutOrder = 1
            body.Parent = sec

            local bodyList = Instance.new("UIListLayout")
            bodyList.SortOrder = Enum.SortOrder.LayoutOrder
            bodyList.Padding = UDim.new(0, 0)
            bodyList.Parent = body

            return body, sec
        end

        -- ── widget row template ────────────────────────
        local function widgetRow(parent, order, height)
            height = height or 38
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, height)
            row.BackgroundColor3 = Theme.SurfaceAlt
            row.BackgroundTransparency = 0.6
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            row.Parent = parent
            makePadding(row, 0, 10, 0, 10)

            -- thin divider above
            local div = Instance.new("Frame")
            div.Size = UDim2.new(1, 0, 0, 1)
            div.BackgroundColor3 = Theme.Border
            div.BackgroundTransparency = 0.8
            div.BorderSizePixel = 0
            div.ZIndex = row.ZIndex
            div.Parent = row

            row.MouseEnter:Connect(function()
                tween(row, TweenInfo.new(0.12), { BackgroundTransparency = 0.3 })
            end)
            row.MouseLeave:Connect(function()
                tween(row, TweenInfo.new(0.12), { BackgroundTransparency = 0.6 })
            end)

            return row
        end

        -- ── AddSection ────────────────────────────────
        function Tab:AddSection(secOpts)
            secOpts = secOpts or {}
            local side = secOpts.Side or "auto"
            local col, order
            if side == "auto" then
                col, order = self:_nextCol()
            else
                col, order = self:_col(side)
            end
            local body, sec = makeSection(col, order, secOpts.Title)

            local Section = {}
            Section._body   = body
            Section._sec    = sec
            Section._count  = 0
            Section._tab    = self

            -- ── AddParagraph ──────────────────────────
            function Section:AddParagraph(pOpts)
                pOpts = pOpts or {}
                self._count = self._count + 1
                local row = widgetRow(self._body, self._count, nil)
                row.AutomaticSize = Enum.AutomaticSize.Y
                row.Size = UDim2.new(1, 0, 0, 0)

                local inner = Instance.new("Frame")
                inner.BackgroundTransparency = 1
                inner.Size = UDim2.new(1, 0, 0, 0)
                inner.AutomaticSize = Enum.AutomaticSize.Y
                inner.Parent = row
                makePadding(inner, 6, 0, 6, 0)

                local titleLab = newLabel(inner, pOpts.Title or "", 12, Theme.TextSecondary, Enum.Font.GothamBold)
                titleLab.LayoutOrder = 1

                local bodyLab = newLabel(inner, pOpts.Content or "", 11, Theme.TextMuted, Enum.Font.Gotham)
                bodyLab.LayoutOrder = 2

                local innerList = Instance.new("UIListLayout")
                innerList.SortOrder = Enum.SortOrder.LayoutOrder
                innerList.Padding = UDim.new(0, 2)
                innerList.Parent = inner

                local Para = {}

                function Para:Set(newTitle, newContent)
                    if newTitle  ~= nil then titleLab.Text = newTitle  end
                    if newContent ~= nil then bodyLab.Text  = newContent end
                end

                function Para:SetContent(newContent)
                    bodyLab.Text = newContent
                end

                function Para:SetTitle(newTitle)
                    titleLab.Text = newTitle
                end

                return Para
            end

            -- ── AddButton ─────────────────────────────
            function Section:AddButton(bOpts)
                bOpts = bOpts or {}
                self._count = self._count + 1
                local row = widgetRow(self._body, self._count, 38)

                local lbl = newLabel(row, bOpts.Title or "Button", 12, Theme.TextPrimary)
                lbl.Position = UDim2.new(0, 0, 0, 0)
                lbl.Size = UDim2.new(0.6, 0, 1, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.None
                lbl.TextYAlignment = Enum.TextYAlignment.Center

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 72, 0, 24)
                btn.Position = UDim2.new(1, -72, 0.5, -12)
                btn.BackgroundColor3 = Theme.Accent
                btn.Text = bOpts.BtnText or "Run"
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextSize = 11
                btn.Font = Enum.Font.GothamBold
                btn.BorderSizePixel = 0
                btn.Parent = row
                makeCorner(btn, 6)

                local function ripple()
                    tween(btn, TweenInfo.new(0.08), { BackgroundColor3 = Theme.AccentGlow })
                    task.delay(0.08, function()
                        tween(btn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Accent })
                    end)
                end

                btn.MouseButton1Click:Connect(function()
                    ripple()
                    if bOpts.Callback then pcall(bOpts.Callback) end
                end)

                btn.MouseEnter:Connect(function()
                    tween(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.AccentDim })
                end)
                btn.MouseLeave:Connect(function()
                    tween(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Accent })
                end)

                return btn
            end

            -- ── AddToggle ─────────────────────────────
            function Section:AddToggle(tOpts)
                tOpts = tOpts or {}
                self._count = self._count + 1
                local row = widgetRow(self._body, self._count, 38)

                local lbl = newLabel(row, tOpts.Title or "Toggle", 12, Theme.TextPrimary)
                lbl.Position = UDim2.new(0, 0, 0, 0)
                lbl.Size = UDim2.new(0.7, 0, 1, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.None
                lbl.TextYAlignment = Enum.TextYAlignment.Center

                local state = tOpts.Default or false

                -- track
                local track = Instance.new("Frame")
                track.Size = UDim2.new(0, 42, 0, 22)
                track.Position = UDim2.new(1, -42, 0.5, -11)
                track.BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff
                track.BorderSizePixel = 0
                track.Parent = row
                makeCorner(track, 11)

                -- thumb
                local thumb = Instance.new("Frame")
                thumb.Size = UDim2.new(0, 16, 0, 16)
                thumb.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                thumb.BorderSizePixel = 0
                thumb.Parent = track
                makeCorner(thumb, 8)

                -- click area (covers row)
                local clickArea = Instance.new("TextButton")
                clickArea.Size = UDim2.new(1, 0, 1, 0)
                clickArea.BackgroundTransparency = 1
                clickArea.Text = ""
                clickArea.Parent = row

                local Toggle = { Value = state }

                local function setState(v, silent)
                    state = v
                    Toggle.Value = v
                    tween(track, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = v and Theme.Accent or Theme.ToggleOff
                    })
                    tween(thumb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                        Position = v and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                    })
                    if not silent and tOpts.Callback then pcall(tOpts.Callback, v) end
                    if tOpts.Flag and self._tab._window.SaveManager then
                        -- auto-register getter
                    end
                end

                clickArea.MouseButton1Click:Connect(function()
                    setState(not state)
                end)

                function Toggle:Set(v)
                    setState(v, true)
                end

                if tOpts.Flag and Tab._window.SaveManager then
                    Tab._window.SaveManager:AddFlag(tOpts.Flag, function() return Toggle.Value end)
                end

                return Toggle
            end

            -- ── AddSlider ─────────────────────────────
            function Section:AddSlider(sOpts)
                sOpts = sOpts or {}
                self._count = self._count + 1
                local row = widgetRow(self._body, self._count, 46)

                local minV = sOpts.Min     or 0
                local maxV = sOpts.Max     or 100
                local defV = sOpts.Default or minV
                local suffix = sOpts.Suffix or ""
                local dp   = sOpts.Decimals or 0

                local current = math.clamp(defV, minV, maxV)

                local lbl = newLabel(row, sOpts.Title or "Slider", 12, Theme.TextPrimary)
                lbl.Position = UDim2.new(0, 0, 0, 4)
                lbl.Size = UDim2.new(0.65, 0, 0, 18)
                lbl.AutomaticSize = Enum.AutomaticSize.None

                local valLbl = Instance.new("TextLabel")
                valLbl.BackgroundTransparency = 1
                valLbl.Text = round(current, dp) .. suffix
                valLbl.TextColor3 = Theme.Accent
                valLbl.TextSize = 12
                valLbl.Font = Enum.Font.GothamBold
                valLbl.Size = UDim2.new(0.35, 0, 0, 18)
                valLbl.Position = UDim2.new(0.65, 0, 0, 4)
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.Parent = row

                -- track
                local trackFrame = Instance.new("Frame")
                trackFrame.Size = UDim2.new(1, 0, 0, 5)
                trackFrame.Position = UDim2.new(0, 0, 1, -13)
                trackFrame.BackgroundColor3 = Theme.SliderTrack
                trackFrame.BorderSizePixel = 0
                trackFrame.Parent = row
                makeCorner(trackFrame, 3)

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new((current - minV) / (maxV - minV), 0, 1, 0)
                fill.BackgroundColor3 = Theme.SliderFill
                fill.BorderSizePixel = 0
                fill.Parent = trackFrame
                makeCorner(fill, 3)

                -- fill gradient
                local fGrad = Instance.new("UIGradient")
                fGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Theme.AccentDim),
                    ColorSequenceKeypoint.new(1, Theme.AccentGlow),
                })
                fGrad.Parent = fill

                -- thumb
                local thumbS = Instance.new("Frame")
                thumbS.Size = UDim2.new(0, 12, 0, 12)
                thumbS.AnchorPoint = Vector2.new(0.5, 0.5)
                thumbS.Position = UDim2.new((current - minV) / (maxV - minV), 0, 0.5, 0)
                thumbS.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                thumbS.BorderSizePixel = 0
                thumbS.ZIndex = trackFrame.ZIndex + 1
                thumbS.Parent = trackFrame
                makeCorner(thumbS, 6)

                local draggingSlider = false
                local Slider = { Value = current }

                local function setSlider(v, silent)
                    v = math.clamp(round(v, dp), minV, maxV)
                    current = v
                    Slider.Value = v
                    local pct = (v - minV) / (maxV - minV)
                    tween(fill, TweenInfo.new(0.05), { Size = UDim2.new(pct, 0, 1, 0) })
                    tween(thumbS, TweenInfo.new(0.05), { Position = UDim2.new(pct, 0, 0.5, 0) })
                    valLbl.Text = round(v, dp) .. suffix
                    if not silent and sOpts.Callback then pcall(sOpts.Callback, v) end
                end

                local function calcFromMouse()
                    local mPos  = UserInputService:GetMouseLocation()
                    local tAbs  = trackFrame.AbsolutePosition
                    local tSize = trackFrame.AbsoluteSize
                    local pct   = math.clamp((mPos.X - tAbs.X) / tSize.X, 0, 1)
                    setSlider(minV + pct * (maxV - minV))
                end

                trackFrame.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                        calcFromMouse()
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if draggingSlider and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        calcFromMouse()
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = false
                    end
                end)

                function Slider:Set(v)
                    setSlider(v, true)
                end

                if sOpts.Flag and Tab._window.SaveManager then
                    Tab._window.SaveManager:AddFlag(sOpts.Flag, function() return Slider.Value end)
                end

                return Slider
            end

            -- ── AddDropdown ───────────────────────────
            local function buildDropdown(dOpts, multi)
                dOpts = dOpts or {}
                self._count = self._count + 1
                local row = widgetRow(self._body, self._count, 38)

                local lbl = newLabel(row, dOpts.Title or "Dropdown", 12, Theme.TextPrimary)
                lbl.Position = UDim2.new(0, 0, 0, 0)
                lbl.Size = UDim2.new(0.45, 0, 1, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.None
                lbl.TextYAlignment = Enum.TextYAlignment.Center

                local opts = dOpts.Options or {}
                local selected = multi and {} or (dOpts.Default or (opts[1] or "None"))
                if multi and dOpts.Default then
                    for _, v in ipairs(dOpts.Default) do selected[v] = true end
                end

                -- value display
                local display = Instance.new("TextButton")
                display.Size = UDim2.new(0.55, -4, 0, 26)
                display.Position = UDim2.new(0.45, 4, 0.5, -13)
                display.BackgroundColor3 = Theme.Elevated
                display.BorderSizePixel = 0
                display.Font = Enum.Font.GothamMedium
                display.TextSize = 11
                display.TextColor3 = Theme.TextSecondary
                display.TextXAlignment = Enum.TextXAlignment.Left
                display.ClipsDescendants = true
                display.Parent = row
                makeCorner(display, 6)
                makePadding(display, 0, 24, 0, 8)
                makeStroke(display, Theme.Border, 1, 0.5)

                local chevron = newLabel(display, Icons.chevdown, 12, Theme.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
                chevron.Size = UDim2.new(1, -4, 1, 0)
                chevron.Position = UDim2.new(0, 0, 0, 0)
                chevron.AutomaticSize = Enum.AutomaticSize.None
                chevron.TextYAlignment = Enum.TextYAlignment.Center

                local function refreshDisplay()
                    if multi then
                        local sel = {}
                        for k, v in pairs(selected) do if v then table.insert(sel, k) end end
                        display.Text = #sel == 0 and "None" or table.concat(sel, ", ")
                    else
                        display.Text = tostring(selected)
                    end
                end
                refreshDisplay()

                -- dropdown panel (placed in sg so it floats above everything)
                local open = false
                local panel = Instance.new("Frame")
                panel.Name = "DropPanel"
                panel.BackgroundColor3 = Theme.Elevated
                panel.Size = UDim2.new(0, 200, 0, 0)
                panel.BackgroundTransparency = 0.05
                panel.Visible = false
                panel.ZIndex = 50
                panel.Parent = sg
                makeCorner(panel, 8)
                makeStroke(panel, Theme.Border, 1, 0.4)

                -- search bar
                local searchBox = Instance.new("TextBox")
                searchBox.Size = UDim2.new(1, -16, 0, 26)
                searchBox.Position = UDim2.new(0, 8, 0, 6)
                searchBox.BackgroundColor3 = Theme.Surface
                searchBox.BorderSizePixel = 0
                searchBox.Text = ""
                searchBox.PlaceholderText = Icons.search .. " Search..."
                searchBox.PlaceholderColor3 = Theme.TextMuted
                searchBox.TextColor3 = Theme.TextPrimary
                searchBox.TextSize = 11
                searchBox.Font = Enum.Font.Gotham
                searchBox.ClearTextOnFocus = false
                searchBox.ZIndex = 51
                searchBox.Parent = panel
                makeCorner(searchBox, 5)
                makePadding(searchBox, 0, 6, 0, 6)

                local scroll = Instance.new("ScrollingFrame")
                scroll.Size = UDim2.new(1, -8, 0, 0)
                scroll.Position = UDim2.new(0, 4, 0, 38)
                scroll.BackgroundTransparency = 1
                scroll.BorderSizePixel = 0
                scroll.ScrollBarThickness = 2
                scroll.ScrollBarImageColor3 = Theme.Accent
                scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                scroll.ZIndex = 51
                scroll.Parent = panel

                local scrollList = Instance.new("UIListLayout")
                scrollList.SortOrder = Enum.SortOrder.LayoutOrder
                scrollList.Padding = UDim.new(0, 2)
                scrollList.Parent = scroll

                local Dropdown = { Value = selected }
                local optButtons = {}

                local function makeItem(opt)
                    local itm = Instance.new("TextButton")
                    itm.Size = UDim2.new(1, 0, 0, 28)
                    itm.BackgroundColor3 = Theme.SurfaceAlt
                    itm.BackgroundTransparency = 0.6
                    itm.Text = tostring(opt)
                    itm.TextColor3 = Theme.TextSecondary
                    itm.TextSize = 11
                    itm.Font = Enum.Font.GothamMedium
                    itm.TextXAlignment = Enum.TextXAlignment.Left
                    itm.BorderSizePixel = 0
                    itm.ZIndex = 52
                    itm.Parent = scroll
                    makeCorner(itm, 5)
                    makePadding(itm, 0, 0, 0, 8)

                    local chk = newLabel(itm, "", 11, Theme.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
                    chk.Size = UDim2.new(1, -4, 1, 0)
                    chk.AutomaticSize = Enum.AutomaticSize.None
                    chk.TextYAlignment = Enum.TextYAlignment.Center
                    chk.ZIndex = 53

                    local function refreshCheck()
                        if multi then
                            chk.Text = selected[opt] and Icons.check or ""
                            itm.TextColor3 = selected[opt] and Theme.TextPrimary or Theme.TextSecondary
                        else
                            chk.Text = (selected == opt) and Icons.check or ""
                            itm.TextColor3 = (selected == opt) and Theme.TextPrimary or Theme.TextSecondary
                        end
                    end
                    refreshCheck()

                    itm.MouseButton1Click:Connect(function()
                        if multi then
                            selected[opt] = not selected[opt]
                        else
                            selected = opt
                        end
                        Dropdown.Value = selected
                        refreshCheck()
                        refreshDisplay()
                        if dOpts.Callback then pcall(dOpts.Callback, selected) end
                        if not multi then
                            open = false
                            tween(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 200, 0, 0) })
                            task.delay(0.22, function() panel.Visible = false end)
                        end
                    end)

                    itm.MouseEnter:Connect(function()
                        tween(itm, TweenInfo.new(0.1), { BackgroundTransparency = 0.3 })
                    end)
                    itm.MouseLeave:Connect(function()
                        tween(itm, TweenInfo.new(0.1), { BackgroundTransparency = 0.6 })
                    end)

                    return itm, refreshCheck
                end

                local itemRefs = {}
                for _, opt in ipairs(opts) do
                    local itm, rc = makeItem(opt)
                    table.insert(itemRefs, { btn = itm, text = tostring(opt), refresh = rc })
                end

                -- filter
                searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local q = searchBox.Text:lower()
                    for _, ref in ipairs(itemRefs) do
                        ref.btn.Visible = (q == "" or ref.text:lower():find(q, 1, true) ~= nil)
                    end
                end)

                local function openPanel()
                    local abs = display.AbsolutePosition
                    local sz  = display.AbsoluteSize
                    local maxH = math.min(#opts * 30 + 50, 200)
                    panel.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
                    panel.Size = UDim2.new(0, sz.X, 0, 0)
                    scroll.Size = UDim2.new(1, -8, 0, maxH - 48)
                    panel.Visible = true
                    tween(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, sz.X, 0, maxH),
                    })
                    tween(chevron, TweenInfo.new(0.15), { Rotation = 180 })
                end

                local function closePanel()
                    tween(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                        Size = UDim2.new(0, panel.AbsoluteSize.X, 0, 0),
                    })
                    tween(chevron, TweenInfo.new(0.15), { Rotation = 0 })
                    task.delay(0.22, function() panel.Visible = false end)
                end

                display.MouseButton1Click:Connect(function()
                    open = not open
                    if open then openPanel() else closePanel() end
                end)

                -- close on outside click
                UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        if open then
                            local mPos = UserInputService:GetMouseLocation()
                            local pAbs = panel.AbsolutePosition
                            local pSz  = panel.AbsoluteSize
                            if mPos.X < pAbs.X or mPos.X > pAbs.X + pSz.X or
                               mPos.Y < pAbs.Y or mPos.Y > pAbs.Y + pSz.Y then
                                open = false
                                closePanel()
                            end
                        end
                    end
                end)

                function Dropdown:Set(v)
                    if multi then
                        selected = {}
                        if type(v) == "table" then
                            for _, k in ipairs(v) do selected[k] = true end
                        end
                    else
                        selected = v
                    end
                    Dropdown.Value = selected
                    for _, ref in ipairs(itemRefs) do ref.refresh() end
                    refreshDisplay()
                end

                function Dropdown:SetOptions(newOpts)
                    -- clear old
                    for _, ref in ipairs(itemRefs) do ref.btn:Destroy() end
                    itemRefs = {}
                    for _, opt in ipairs(newOpts) do
                        local itm, rc = makeItem(opt)
                        table.insert(itemRefs, { btn = itm, text = tostring(opt), refresh = rc })
                    end
                end

                if dOpts.Flag and Tab._window.SaveManager then
                    Tab._window.SaveManager:AddFlag(dOpts.Flag, function() return Dropdown.Value end)
                end

                return Dropdown
            end

            function Section:AddDropdown(dOpts)
                return buildDropdown(dOpts, false)
            end

            function Section:AddMultiDropdown(dOpts)
                return buildDropdown(dOpts, true)
            end

            -- ── AddKeybind ────────────────────────────
            function Section:AddKeybind(kOpts)
                kOpts = kOpts or {}
                self._count = self._count + 1
                local row = widgetRow(self._body, self._count, 38)

                local lbl = newLabel(row, kOpts.Title or "Keybind", 12, Theme.TextPrimary)
                lbl.Position = UDim2.new(0, 0, 0, 0)
                lbl.Size = UDim2.new(0.55, 0, 1, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.None
                lbl.TextYAlignment = Enum.TextYAlignment.Center

                local key = kOpts.Default or Enum.KeyCode.Unknown
                local listening = false

                local keyBtn = Instance.new("TextButton")
                keyBtn.Size = UDim2.new(0, 80, 0, 24)
                keyBtn.Position = UDim2.new(1, -80, 0.5, -12)
                keyBtn.BackgroundColor3 = Theme.Elevated
                keyBtn.Text = key.Name
                keyBtn.TextColor3 = Theme.Accent
                keyBtn.TextSize = 11
                keyBtn.Font = Enum.Font.GothamBold
                keyBtn.BorderSizePixel = 0
                keyBtn.Parent = row
                makeCorner(keyBtn, 6)
                makeStroke(keyBtn, Theme.Accent, 1, 0.6)
                makePadding(keyBtn, 0, 6, 0, 6)

                local Keybind = { Value = key }

                keyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    keyBtn.Text = "..."
                    tween(keyBtn, TweenInfo.new(0.1), { BackgroundColor3 = Theme.AccentDim })
                end)

                UserInputService.InputBegan:Connect(function(inp, gp)
                    if not listening then
                        -- fire callback if key matches
                        if inp.KeyCode == key and not gp then
                            if kOpts.Callback then pcall(kOpts.Callback, key) end
                        end
                        return
                    end
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        key = inp.KeyCode
                        Keybind.Value = key
                        keyBtn.Text = key.Name
                        tween(keyBtn, TweenInfo.new(0.1), { BackgroundColor3 = Theme.Elevated })
                        if kOpts.Changed then pcall(kOpts.Changed, key) end
                    end
                end)

                function Keybind:Set(k)
                    key = k
                    Keybind.Value = k
                    keyBtn.Text = k.Name
                end

                if kOpts.Flag and Tab._window.SaveManager then
                    Tab._window.SaveManager:AddFlag(kOpts.Flag, function() return Keybind.Value.Name end)
                end

                return Keybind
            end

            -- ── AddInput ──────────────────────────────
            function Section:AddInput(iOpts)
                iOpts = iOpts or {}
                self._count = self._count + 1
                local row = widgetRow(self._body, self._count, 38)

                local lbl = newLabel(row, iOpts.Title or "Input", 12, Theme.TextPrimary)
                lbl.Position = UDim2.new(0, 0, 0, 0)
                lbl.Size = UDim2.new(0.4, 0, 1, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.None
                lbl.TextYAlignment = Enum.TextYAlignment.Center

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.6, -4, 0, 26)
                box.Position = UDim2.new(0.4, 4, 0.5, -13)
                box.BackgroundColor3 = Theme.Elevated
                box.BorderSizePixel = 0
                box.Text = iOpts.Default or ""
                box.PlaceholderText = iOpts.Placeholder or "..."
                box.PlaceholderColor3 = Theme.TextMuted
                box.TextColor3 = Theme.TextPrimary
                box.TextSize = 11
                box.Font = Enum.Font.Gotham
                box.ClearTextOnFocus = iOpts.ClearOnFocus ~= false
                box.Parent = row
                makeCorner(box, 6)
                makePadding(box, 0, 6, 0, 6)
                makeStroke(box, Theme.Border, 1, 0.5)

                box.Focused:Connect(function()
                    tween(box, TweenInfo.new(0.15), { BackgroundColor3 = Theme.SurfaceAlt })
                    tween(box, TweenInfo.new(0.15), {})
                    -- stroke highlight via re-parent trick not needed; just recolor
                end)
                box.FocusLost:Connect(function(enterPressed)
                    tween(box, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Elevated })
                    if iOpts.Callback then pcall(iOpts.Callback, box.Text, enterPressed) end
                end)

                local Input = { Value = box.Text }
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    Input.Value = box.Text
                    if iOpts.Changed then pcall(iOpts.Changed, box.Text) end
                end)

                function Input:Set(v)
                    box.Text = tostring(v)
                end

                if iOpts.Flag and Tab._window.SaveManager then
                    Tab._window.SaveManager:AddFlag(iOpts.Flag, function() return Input.Value end)
                end

                return Input
            end

            -- ── AddColorPicker (bonus) ─────────────────
            -- kept minimal for now; returns a table with :Set()
            function Section:AddLabel(lOpts)
                lOpts = lOpts or {}
                self._count = self._count + 1
                local row = widgetRow(self._body, self._count, 32)
                row.AutomaticSize = Enum.AutomaticSize.Y
                row.Size = UDim2.new(1, 0, 0, 32)

                local lbl = newLabel(row, lOpts.Text or "", 11, Theme.TextSecondary, Enum.Font.Gotham)
                lbl.Position = UDim2.new(0, 0, 0, 0)
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.None
                lbl.TextYAlignment = Enum.TextYAlignment.Center

                local Label = {}
                function Label:Set(t)
                    lbl.Text = t
                end
                return Label
            end

            return Section
        end

        -- activate tab on click
        sBtn.MouseButton1Click:Connect(function()
            self:_setActive(Tab)
        end)

        table.insert(self._tabs, Tab)

        if #self._tabs == 1 then
            self:_setActive(Tab)
        end

        return Tab
    end

    function Window:_setActive(tab)
        for _, t in ipairs(self._tabs) do
            t._page.Visible = false
            tween(t._sBtn, TweenInfo.new(0.15), {
                BackgroundTransparency = 1,
                TextColor3 = Theme.TextMuted,
            })
        end
        tab._page.Visible = true
        self._activeTab = tab
        tween(tab._sBtn, TweenInfo.new(0.15), {
            BackgroundTransparency = 0.5,
            TextColor3 = Theme.AccentGlow,
        })

        -- accent bar indicator on sidebar
        if self._sideIndicator then self._sideIndicator:Destroy() end
        local ind = Instance.new("Frame")
        ind.Size = UDim2.new(0, 3, 0, 24)
        ind.AnchorPoint = Vector2.new(0, 0.5)
        ind.Position = UDim2.new(0, 0, 0, tab._sBtn.AbsolutePosition.Y - self._sidebar.AbsolutePosition.Y + 16)
        ind.BackgroundColor3 = Theme.Accent
        ind.BorderSizePixel = 0
        ind.ZIndex = 5
        ind.Parent = self._sidebar
        makeCorner(ind, 2)
        self._sideIndicator = ind
    end

    return Window
end

-- ──────────────────────────────────────────────────────
-- 7.  EXPORT
-- ──────────────────────────────────────────────────────
return HydrosolUI
