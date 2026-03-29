-- ============================================================
-- RbxImGui | Lightweight ImGui-style UI Library for Roblox
--
-- Usage:
-- local UI = require(path.to.RbxImGui)
-- local win = UI.new("My Panel")
--
-- -- Add tabs
-- win:AddTab("Aimbot")
-- win:AddTab("Visuals")
-- win:AddTab("Misc")
--
-- -- Add widgets to a specific tab
-- win:Tab("Aimbot"):Toggle("Silent Aim", false, function(v) end)
-- win:Tab("Visuals"):Slider("FOV", 30, 120, 70, function(v) end)
-- win:Tab("Misc"):Button("Reset", function() end)
-- win:Tab("Misc"):Dropdown("Mode", {"Off","Legit","Rage"}, function(v) end)
-- win:Tab("Misc"):ColorPicker("Color", Color3.fromRGB(255,0,0), function(c) end)
--
-- win:Render()
-- ============================================================

local RbxImGui = {}
RbxImGui.__index = RbxImGui

local TabBuilder = {}
TabBuilder.__index = TabBuilder

-- ── Theming ──────────────────────────────────────────────────
local THEME = {
    TitleBarBg      = Color3.fromRGB(20,  20,  26),
    TitleBarText    = Color3.fromRGB(220, 220, 220),
    TabBarBg        = Color3.fromRGB(18,  18,  24),
    TabBg           = Color3.fromRGB(38,  38,  52),
    TabHover        = Color3.fromRGB(55,  55,  75),
    TabActive       = Color3.fromRGB(82,  130, 255),
    TabText         = Color3.fromRGB(170, 170, 195),
    TabTextActive   = Color3.fromRGB(255, 255, 255),
    WindowBg        = Color3.fromRGB(22,  22,  28),
    WindowBorder    = Color3.fromRGB(55,  55,  75),
    ButtonBg        = Color3.fromRGB(52,  52,  68),
    ButtonHover     = Color3.fromRGB(72,  72,  100),
    ButtonActive    = Color3.fromRGB(82,  130, 255),
    ButtonText      = Color3.fromRGB(210, 210, 220),
    ToggleOff       = Color3.fromRGB(55,  55,  70),
    ToggleOn        = Color3.fromRGB(82,  130, 255),
    ToggleKnob      = Color3.fromRGB(240, 240, 255),
    ToggleText      = Color3.fromRGB(200, 200, 215),
    SliderTrack     = Color3.fromRGB(40,  40,  55),
    SliderFill      = Color3.fromRGB(82,  130, 255),
    SliderKnob      = Color3.fromRGB(230, 230, 255),
    SliderText      = Color3.fromRGB(200, 200, 215),
    SliderValue     = Color3.fromRGB(140, 160, 255),
    SeparatorColor  = Color3.fromRGB(50,  50,  68),
    TextColor       = Color3.fromRGB(200, 200, 215),
    ResizeGrip      = Color3.fromRGB(40,  40,  55),
    ResizeGripHover = Color3.fromRGB(82,  130, 255),
    ScrollThumb     = Color3.fromRGB(80,  80,  110),
    DropdownBg      = Color3.fromRGB(28,  28,  40),
    DropdownItem    = Color3.fromRGB(38,  38,  52),
    DropdownHover   = Color3.fromRGB(60,  60,  90),
    DropdownText    = Color3.fromRGB(200, 200, 215),
    DropdownBorder  = Color3.fromRGB(70,  70,  100),
}

-- ── Defaults ─────────────────────────────────────────────────
local DEFAULTS = {
    WindowWidth     = 320,
    WindowMinWidth  = 200,
    WindowMinHeight = 120,
    TitleBarHeight  = 30,
    TabBarHeight    = 30,
    TabMinWidth     = 60,
    TabPadding      = 20,
    Padding         = 10,
    ItemSpacing     = 6,
    ButtonHeight    = 28,
    ToggleHeight    = 24,
    SliderHeight    = 30,
    CornerRadius    = 6,
    FontSize        = 13,
    ResizeGripSize  = 14,
    DropdownItemH   = 26,
}

-- ── Services ──────────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ── Helpers ───────────────────────────────────────────────────
local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function make(className, props)
    local obj = Instance.new(className)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

local function corner(r, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = parent
end

local function stroke(color, thickness, parent)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
end

local function estimateTextWidth(text, fontSize)
    return #text * (fontSize * 0.6)
end

local FONT_REG  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular,  Enum.FontStyle.Normal)
local FONT_SEMI = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
local FONT_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold,     Enum.FontStyle.Normal)

-- ── HSV helpers ───────────────────────────────────────────────
local function hsvToColor3(h, s, v)
    if s == 0 then return Color3.new(v, v, v) end
    local i  = math.floor(h * 6)
    local f  = h * 6 - i
    local p  = v * (1 - s)
    local q  = v * (1 - f * s)
    local t_ = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return Color3.new(v, t_, p)
    elseif i == 1 then return Color3.new(q, v, p)
    elseif i == 2 then return Color3.new(p, v, t_)
    elseif i == 3 then return Color3.new(p, q, v)
    elseif i == 4 then return Color3.new(t_, p, v)
    else return Color3.new(v, p, q)
    end
end

local function color3ToHsv(c)
    local r, g, b = c.R, c.G, c.B
    local mx = math.max(r, g, b)
    local mn = math.min(r, g, b)
    local d  = mx - mn
    local h, s, v = 0, 0, mx
    if mx ~= 0 then s = d / mx end
    if d ~= 0 then
        if mx == r then h = (g - b) / d % 6
        elseif mx == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4
        end
        h = h / 6
    end
    return h, s, v
end

-- ── Constructor ───────────────────────────────────────────────
function RbxImGui.new(title, parent)
    local self        = setmetatable({}, RbxImGui)
    self._title       = title or "Window"
    self._tabs        = {}
    self._tabsByName  = {}
    self._activeTab   = nil
    self._rendered    = false

    -- ── ScreenGui ─────────────────────────────────────────────
    local sg
    if not parent then
        sg = Instance.new("ScreenGui")
        sg.Name           = "RbxImGui_" .. self._title
        sg.ResetOnSpawn   = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder   = 999
        if not pcall(function() sg.Parent = game:GetService("CoreGui") end) then
            sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end
        parent = sg
    end
    self._screenGui = parent

    -- ── Window ────────────────────────────────────────────────
    self._window = make("Frame", {
        Name             = "ImGuiWindow",
        Size             = UDim2.new(0, DEFAULTS.WindowWidth, 0, 340),
        Position         = UDim2.new(0, 80, 0, 80),
        BackgroundColor3 = THEME.WindowBg,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = parent,
    })
    corner(DEFAULTS.CornerRadius, self._window)
    stroke(THEME.WindowBorder, 1, self._window)

    -- ── Dropdown overlay ──────────────────────────────────────
    -- Parented directly to the ScreenGui (same level as the window).
    -- Uses absolute screen coordinates so it is NEVER affected by scroll.
    -- ZIndex 100 keeps it above all window content.
    self._dropdownOverlay = make("Frame", {
        Name                   = "DropdownOverlay",
        Size                   = UDim2.new(1, 0, 1, 0),
        Position               = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 100,
        Parent                 = parent,
    })

    -- ── Title Bar ─────────────────────────────────────────────
    local titleBar = make("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, DEFAULTS.TitleBarHeight),
        BackgroundColor3 = THEME.TitleBarBg,
        BorderSizePixel  = 0,
        Parent           = self._window,
    })
    make("TextLabel", {
        Name                   = "Title",
        Size                   = UDim2.new(1, -12, 1, 0),
        Position               = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text                   = self._title,
        TextColor3             = THEME.TitleBarText,
        TextSize               = DEFAULTS.FontSize + 1,
        FontFace               = FONT_BOLD,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = titleBar,
    })

    -- ── Drag ──────────────────────────────────────────────────
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = self._window.Position
        end
    end)
    titleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            self._window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    -- ── Tab Bar ───────────────────────────────────────────────
    self._tabBar = make("Frame", {
        Name             = "TabBar",
        Size             = UDim2.new(1, 0, 0, DEFAULTS.TabBarHeight),
        Position         = UDim2.new(0, 0, 0, DEFAULTS.TitleBarHeight),
        BackgroundColor3 = THEME.TabBarBg,
        BorderSizePixel  = 0,
        Parent           = self._window,
    })
    make("Frame", {
        Name             = "TabSep",
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = THEME.WindowBorder,
        BorderSizePixel  = 0,
        Parent           = self._tabBar,
    })
    local tabInner = make("Frame", {
        Name                   = "TabInner",
        Size                   = UDim2.new(1, 0, 1, -1),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Parent                 = self._tabBar,
    })
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection     = Enum.FillDirection.Horizontal
    tabLayout.SortOrder         = Enum.SortOrder.LayoutOrder
    tabLayout.Padding           = UDim.new(0, 4)
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.Parent            = tabInner
    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft  = UDim.new(0, 6)
    tabPad.PaddingRight = UDim.new(0, 6)
    tabPad.Parent       = tabInner
    self._tabInner  = tabInner
    self._tabLayout = tabLayout

    -- ── Content Area ──────────────────────────────────────────
    local contentTop = DEFAULTS.TitleBarHeight + DEFAULTS.TabBarHeight
    self._contentArea = make("Frame", {
        Name                   = "ContentArea",
        Size                   = UDim2.new(1, 0, 1, -(contentTop + DEFAULTS.ResizeGripSize)),
        Position               = UDim2.new(0, 0, 0, contentTop),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
        Parent                 = self._window,
    })

    -- ── Resize Grip ───────────────────────────────────────────
    local grip = make("TextButton", {
        Name             = "ResizeGrip",
        Size             = UDim2.new(0, DEFAULTS.ResizeGripSize, 0, DEFAULTS.ResizeGripSize),
        Position         = UDim2.new(1, -DEFAULTS.ResizeGripSize, 1, -DEFAULTS.ResizeGripSize),
        BackgroundColor3 = THEME.ResizeGrip,
        Text             = "",
        BorderSizePixel  = 0,
        ZIndex           = 5,
        Parent           = self._window,
    })
    corner(2, grip)
    for i = 1, 3 do
        make("Frame", {
            Size             = UDim2.new(0, 2, 0, 2),
            Position         = UDim2.new(0, 2 + (i-1)*4, 0, 8 - (i-1)*3),
            BackgroundColor3 = Color3.fromRGB(120, 130, 170),
            BorderSizePixel  = 0,
            Parent           = grip,
        })
    end
    grip.MouseEnter:Connect(function() tween(grip, {BackgroundColor3 = THEME.ResizeGripHover}) end)
    grip.MouseLeave:Connect(function() tween(grip, {BackgroundColor3 = THEME.ResizeGrip}) end)
    local resizing, resizeStart, resizeStartSize
    grip.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing        = true
            resizeStart     = inp.Position
            resizeStartSize = self._window.AbsoluteSize
        end
    end)
    grip.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d    = inp.Position - resizeStart
            local newW = math.max(DEFAULTS.WindowMinWidth,  resizeStartSize.X + d.X)
            local newH = math.max(DEFAULTS.WindowMinHeight, resizeStartSize.Y + d.Y)
            self._window.Size = UDim2.new(0, newW, 0, newH)
        end
    end)

    -- ── Insert Key ────────────────────────────────────────────
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.Insert then
            self._window.Visible = not self._window.Visible
        end
    end)

    return self
end

-- ── Tab Management ────────────────────────────────────────────
function RbxImGui:_recalcWindowWidth()
    local totalW = 24
    for i, td in ipairs(self._tabs) do
        totalW = totalW + td._btnWidth
        if i > 1 then totalW = totalW + 4 end
    end
    local minW = math.max(DEFAULTS.WindowWidth, totalW)
    if minW > self._window.AbsoluteSize.X then
        self._window.Size = UDim2.new(0, minW, 0, self._window.AbsoluteSize.Y)
    end
end

function RbxImGui:AddTab(name)
    local tabIndex = #self._tabs + 1
    local txtW     = estimateTextWidth(name, DEFAULTS.FontSize - 1)
    local btnWidth = math.max(DEFAULTS.TabMinWidth, txtW + DEFAULTS.TabPadding)

    local btn = make("TextButton", {
        Name             = "Tab_" .. name,
        Size             = UDim2.new(0, btnWidth, 0, 22),
        BackgroundColor3 = THEME.TabBg,
        Text             = name,
        TextColor3       = THEME.TabText,
        TextSize         = DEFAULTS.FontSize - 1,
        FontFace         = FONT_SEMI,
        BorderSizePixel  = 0,
        LayoutOrder      = tabIndex,
        Parent           = self._tabInner,
    })
    corner(4, btn)

    local sf = make("ScrollingFrame", {
        Name                  = "TabContent_" .. name,
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency= 1,
        BorderSizePixel       = 0,
        ScrollBarThickness    = 4,
        ScrollBarImageColor3  = THEME.ScrollThumb,
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        Visible               = false,
        Parent                = self._contentArea,
    })
    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding   = UDim.new(0, DEFAULTS.ItemSpacing)
    ll.Parent    = sf
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, DEFAULTS.Padding)
    pad.PaddingRight  = UDim.new(0, DEFAULTS.Padding)
    pad.PaddingTop    = UDim.new(0, DEFAULTS.Padding)
    pad.PaddingBottom = UDim.new(0, DEFAULTS.Padding)
    pad.Parent        = sf

    local tabData = {
        name        = name,
        items       = {},
        scrollFrame = sf,
        tabBtn      = btn,
        _btnWidth   = btnWidth,
    }
    self._tabs[tabIndex]   = tabData
    self._tabsByName[name] = tabData

    btn.MouseButton1Click:Connect(function() self:_switchTab(name) end)
    btn.MouseEnter:Connect(function()
        if self._activeTab ~= name then tween(btn, {BackgroundColor3 = THEME.TabHover}) end
    end)
    btn.MouseLeave:Connect(function()
        if self._activeTab ~= name then tween(btn, {BackgroundColor3 = THEME.TabBg}) end
    end)

    if tabIndex == 1 then self:_switchTab(name) end
    self:_recalcWindowWidth()
    return self
end

function RbxImGui:_switchTab(name)
    self._activeTab = name
    for _, td in ipairs(self._tabs) do
        local isActive = (td.name == name)
        td.scrollFrame.Visible = isActive
        tween(td.tabBtn, {
            BackgroundColor3 = isActive and THEME.TabActive or THEME.TabBg,
            TextColor3       = isActive and THEME.TabTextActive or THEME.TabText,
        })
    end
end

function RbxImGui:Tab(name)
    assert(self._tabsByName[name], "Tab '" .. tostring(name) .. "' does not exist. Call :AddTab() first.")
    local builder                = setmetatable({}, TabBuilder)
    builder._tabData             = self._tabsByName[name]
    builder._dropdownOverlay     = self._dropdownOverlay
    builder._window              = self._window
    return builder
end

-- ── Widget helpers ────────────────────────────────────────────

local function addLabel(tabData, text)
    table.insert(tabData.items, function(parent, order)
        make("TextLabel", {
            Name                   = "Label_" .. order,
            Size                   = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text                   = text,
            TextColor3             = THEME.TextColor,
            TextSize               = DEFAULTS.FontSize,
            FontFace               = FONT_REG,
            TextXAlignment         = Enum.TextXAlignment.Left,
            LayoutOrder            = order,
            Parent                 = parent,
        })
    end)
end

local function addSeparator(tabData)
    table.insert(tabData.items, function(parent, order)
        make("Frame", {
            Name             = "Sep_" .. order,
            Size             = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = THEME.SeparatorColor,
            BorderSizePixel  = 0,
            LayoutOrder      = order,
            Parent           = parent,
        })
    end)
end

local function addButton(tabData, label, callback)
    table.insert(tabData.items, function(parent, order)
        local btn = make("TextButton", {
            Name             = "Btn_" .. order,
            Size             = UDim2.new(1, 0, 0, DEFAULTS.ButtonHeight),
            BackgroundColor3 = THEME.ButtonBg,
            Text             = label,
            TextColor3       = THEME.ButtonText,
            TextSize         = DEFAULTS.FontSize,
            FontFace         = FONT_SEMI,
            BorderSizePixel  = 0,
            LayoutOrder      = order,
            Parent           = parent,
        })
        corner(DEFAULTS.CornerRadius - 2, btn)
        stroke(Color3.fromRGB(65, 65, 90), 1, btn)
        btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = THEME.ButtonHover}) end)
        btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = THEME.ButtonBg}) end)
        btn.MouseButton1Down:Connect(function() tween(btn, {BackgroundColor3 = THEME.ButtonActive}, 0.07) end)
        btn.MouseButton1Up:Connect(function()
            tween(btn, {BackgroundColor3 = THEME.ButtonHover}, 0.07)
            if callback then callback() end
        end)
    end)
end

local function addToggle(tabData, label, default, callback)
    local state = default or false
    table.insert(tabData.items, function(parent, order)
        local row = make("Frame", {
            Name                   = "Toggle_" .. order,
            Size                   = UDim2.new(1, 0, 0, DEFAULTS.ToggleHeight),
            BackgroundTransparency = 1,
            LayoutOrder            = order,
            Parent                 = parent,
        })
        make("TextLabel", {
            Size                   = UDim2.new(1, -50, 1, 0),
            BackgroundTransparency = 1,
            Text                   = label,
            TextColor3             = THEME.ToggleText,
            TextSize               = DEFAULTS.FontSize,
            FontFace               = FONT_REG,
            TextXAlignment         = Enum.TextXAlignment.Left,
            Parent                 = row,
        })
        local tW, tH = 36, 18
        local track = make("Frame", {
            Size             = UDim2.new(0, tW, 0, tH),
            Position         = UDim2.new(1, -tW, 0.5, -tH/2),
            BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff,
            BorderSizePixel  = 0,
            Parent           = row,
        })
        corner(tH/2, track)
        local kS   = tH - 4
        local knob = make("Frame", {
            Size             = UDim2.new(0, kS, 0, kS),
            Position         = state and UDim2.new(0, tW-kS-2, 0.5, -kS/2) or UDim2.new(0, 2, 0.5, -kS/2),
            BackgroundColor3 = THEME.ToggleKnob,
            BorderSizePixel  = 0,
            Parent           = track,
        })
        corner(kS/2, knob)
        local clickBtn = make("TextButton", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "",
            Parent                 = row,
        })
        clickBtn.MouseButton1Click:Connect(function()
            state = not state
            tween(track, {BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff})
            tween(knob, {Position = state and UDim2.new(0, tW-kS-2, 0.5, -kS/2) or UDim2.new(0, 2, 0.5, -kS/2)})
            if callback then callback(state) end
        end)
    end)
end

local function addSlider(tabData, label, min, max, default, callback)
    min     = min     or 0
    max     = max     or 100
    default = default or min
    local value = math.clamp(default, min, max)
    table.insert(tabData.items, function(parent, order)
        local col = make("Frame", {
            Name                   = "Slider_" .. order,
            Size                   = UDim2.new(1, 0, 0, DEFAULTS.SliderHeight + 16),
            BackgroundTransparency = 1,
            LayoutOrder            = order,
            Parent                 = parent,
        })
        local hdr = make("Frame", {
            Size                   = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Parent                 = col,
        })
        make("TextLabel", {
            Size                   = UDim2.new(0.6, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = label,
            TextColor3             = THEME.SliderText,
            TextSize               = DEFAULTS.FontSize,
            FontFace               = FONT_REG,
            TextXAlignment         = Enum.TextXAlignment.Left,
            Parent                 = hdr,
        })
        local valLbl = make("TextLabel", {
            Size                   = UDim2.new(0.4, 0, 1, 0),
            Position               = UDim2.new(0.6, 0, 0, 0),
            BackgroundTransparency = 1,
            Text                   = tostring(math.floor(value)),
            TextColor3             = THEME.SliderValue,
            TextSize               = DEFAULTS.FontSize,
            FontFace               = FONT_BOLD,
            TextXAlignment         = Enum.TextXAlignment.Right,
            Parent                 = hdr,
        })
        local trkH  = 6
        local track = make("Frame", {
            Size             = UDim2.new(1, 0, 0, trkH),
            Position         = UDim2.new(0, 0, 0, 16 + (DEFAULTS.SliderHeight - trkH)/2),
            BackgroundColor3 = THEME.SliderTrack,
            BorderSizePixel  = 0,
            Parent           = col,
        })
        corner(trkH/2, track)
        local pct  = (value - min) / (max - min)
        local fill = make("Frame", {
            Size             = UDim2.new(pct, 0, 1, 0),
            BackgroundColor3 = THEME.SliderFill,
            BorderSizePixel  = 0,
            Parent           = track,
        })
        corner(trkH/2, fill)
        local kS   = 14
        local knob = make("Frame", {
            Size             = UDim2.new(0, kS, 0, kS),
            Position         = UDim2.new(pct, -kS/2, 0.5, -kS/2),
            BackgroundColor3 = THEME.SliderKnob,
            BorderSizePixel  = 0,
            ZIndex           = 2,
            Parent           = track,
        })
        corner(kS/2, knob)
        stroke(THEME.SliderFill, 2, knob)
        local drag = make("TextButton", {
            Size                   = UDim2.new(1, 0, 0, DEFAULTS.SliderHeight),
            Position               = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 3,
            Parent                 = col,
        })
        local function update(x)
            local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value         = min + p * (max - min)
            valLbl.Text   = tostring(math.floor(value))
            fill.Size     = UDim2.new(p, 0, 1, 0)
            knob.Position = UDim2.new(p, -kS/2, 0.5, -kS/2)
            if callback then callback(math.floor(value)) end
        end
        local sliding = false
        drag.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = true; update(inp.Position.X)
            end
        end)
        drag.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
                update(inp.Position.X)
            end
        end)
    end)
end

-- ── Dropdown ─────────────────────────────────────────────────
--
-- FIXES applied:
--
-- [1] SCROLL-PROOF: Menu is parented to _dropdownOverlay which is a direct
--     child of the ScreenGui at absolute (0,0) covering the full screen.
--     Position is set in absolute screen pixels using AbsolutePosition at the
--     moment of opening — scrolling the list never moves the menu.
--
-- [2] ITEMS ARE CLICKABLE: Items use MouseButton1Down instead of
--     MouseButton1Click.  The outside-click guard (UserInputService.InputBegan)
--     fires first and would destroy the menu before Click fires.  Down fires
--     simultaneously with InputBegan but on the specific element, so we check
--     whether the mouse is over an item *inside* InputBegan and skip closing.
--     We also set `justOpened` for one frame so the opening click cannot
--     immediately re-close the menu.
--
local function addDropdown(tabData, dropdownOverlay, window, label, options, callback)
    options  = options or {}
    local selected = options[1] or ""

    table.insert(tabData.items, function(parent, order)
        local rowH = 28
        local row  = make("Frame", {
            Name                   = "Dropdown_" .. order,
            Size                   = UDim2.new(1, 0, 0, rowH),
            BackgroundTransparency = 1,
            LayoutOrder            = order,
            Parent                 = parent,
        })

        make("TextLabel", {
            Size                   = UDim2.new(0.45, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = label,
            TextColor3             = THEME.ToggleText,
            TextSize               = DEFAULTS.FontSize,
            FontFace               = FONT_REG,
            TextXAlignment         = Enum.TextXAlignment.Left,
            Parent                 = row,
        })

        local ddBtn = make("TextButton", {
            Name             = "DDBtn",
            Size             = UDim2.new(0.55, 0, 1, -4),
            Position         = UDim2.new(0.45, 0, 0, 2),
            BackgroundColor3 = THEME.DropdownBg,
            Text             = selected .. "  ▾",
            TextColor3       = THEME.DropdownText,
            TextSize         = DEFAULTS.FontSize - 1,
            FontFace         = FONT_REG,
            BorderSizePixel  = 0,
            Parent           = row,
        })
        corner(4, ddBtn)
        stroke(THEME.DropdownBorder, 1, ddBtn)

        local menuFrame  = nil
        local menuOpen   = false
        local justOpened = false  -- blocks the open-click from also closing the menu

        local function closeMenu()
            if menuFrame then
                menuFrame:Destroy()
                menuFrame = nil
            end
            menuOpen   = false
            ddBtn.Text = selected .. "  ▾"
        end

        local function openMenu()
            if menuOpen then closeMenu(); return end

            menuOpen     = true
            justOpened   = true
            ddBtn.Text   = selected .. "  ▴"

            local itemH   = DEFAULTS.DropdownItemH
            local menuH   = itemH * #options + 8
            local menuW   = ddBtn.AbsoluteSize.X

            -- Absolute screen position (never affected by scroll)
            local btnAbs  = ddBtn.AbsolutePosition
            local btnSzY  = ddBtn.AbsoluteSize.Y
            local screenSz = workspace.CurrentCamera.ViewportSize

            local posX = btnAbs.X
            local posY = btnAbs.Y + btnSzY + 2

            -- Flip above the button if it would overflow the screen bottom
            if posY + menuH > screenSz.Y - 4 then
                posY = btnAbs.Y - menuH - 2
            end
            -- Clamp to screen right edge
            if posX + menuW > screenSz.X - 4 then
                posX = screenSz.X - menuW - 4
            end
            posX = math.max(4, posX)
            posY = math.max(4, posY)

            menuFrame = make("Frame", {
                Name             = "DropdownMenu",
                Position         = UDim2.new(0, posX, 0, posY),
                Size             = UDim2.new(0, menuW, 0, menuH),
                BackgroundColor3 = THEME.DropdownBg,
                BorderSizePixel  = 0,
                ZIndex           = 101,
                Parent           = dropdownOverlay,
            })
            corner(5, menuFrame)
            stroke(THEME.DropdownBorder, 1, menuFrame)

            local ll2 = Instance.new("UIListLayout")
            ll2.SortOrder = Enum.SortOrder.LayoutOrder
            ll2.Parent    = menuFrame

            local pad2 = Instance.new("UIPadding")
            pad2.PaddingTop    = UDim.new(0, 4)
            pad2.PaddingBottom = UDim.new(0, 4)
            pad2.PaddingLeft   = UDim.new(0, 2)
            pad2.PaddingRight  = UDim.new(0, 2)
            pad2.Parent        = menuFrame

            for idx, opt in ipairs(options) do
                local item = make("TextButton", {
                    Name             = "Item_" .. idx,
                    Size             = UDim2.new(1, 0, 0, itemH),
                    BackgroundColor3 = THEME.DropdownItem,
                    Text             = opt,
                    TextColor3       = THEME.DropdownText,
                    TextSize         = DEFAULTS.FontSize - 1,
                    FontFace         = FONT_REG,
                    BorderSizePixel  = 0,
                    LayoutOrder      = idx,
                    ZIndex           = 102,
                    Parent           = menuFrame,
                })
                corner(3, item)
                item.MouseEnter:Connect(function()
                    tween(item, {BackgroundColor3 = THEME.DropdownHover})
                end)
                item.MouseLeave:Connect(function()
                    tween(item, {BackgroundColor3 = THEME.DropdownItem})
                end)
                -- MouseButton1Down fires before InputBegan's outside-close handler
                -- destroys the frame, so the selection is always captured.
                item.MouseButton1Down:Connect(function()
                    selected   = opt
                    ddBtn.Text = selected .. "  ▾"
                    closeMenu()
                    if callback then callback(selected) end
                end)
            end

            -- Defer one frame so the click that opened the menu is not also
            -- caught by the InputBegan handler below as an "outside click".
            task.defer(function()
                justOpened = false
            end)
        end

        ddBtn.MouseButton1Click:Connect(openMenu)

        -- Global outside-click handler: close the menu when clicking anywhere
        -- that is not inside the menu frame or on the toggle button.
        UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not menuOpen or justOpened then return end

            local mp = UserInputService:GetMouseLocation()

            -- If the cursor is inside the menu, let MouseButton1Down on the item handle it
            if menuFrame then
                local mfp = menuFrame.AbsolutePosition
                local mfs = menuFrame.AbsoluteSize
                if mp.X >= mfp.X and mp.X <= mfp.X + mfs.X
                and mp.Y >= mfp.Y and mp.Y <= mfp.Y + mfs.Y then
                    return
                end
            end

            -- If the cursor is on the toggle button, openMenu will handle toggling
            local bp = ddBtn.AbsolutePosition
            local bs = ddBtn.AbsoluteSize
            if mp.X >= bp.X and mp.X <= bp.X + bs.X
            and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y then
                return
            end

            closeMenu()
        end)
    end)
end

-- ── ColorPicker ──────────────────────────────────────────────
--
-- FIXES applied:
--
-- [1] LAYOUT: Header swatch and the picker body are children of one container
--     Frame with AutomaticSize.Y and a UIListLayout.  Previously the picker
--     used LayoutOrder = order + 0.5 (ignored by Roblox, treated as integer)
--     so it ended up in the wrong position in the scroll list.
--
-- [2] SV BOX: Two UIGradient overlays give the correct 2-axis appearance:
--     - white → transparent horizontally (left = white, right = saturated)
--     - transparent → black vertically   (top = bright, bottom = dark)
--     The background of the box is the pure hue color and is updated when hue
--     changes, so the whole gradient shifts correctly.
--
-- [3] HUE BAR: Uses Roblox's built-in rainbow spectrum image asset so every
--     hue is represented accurately without any colour clipping.
--
local function addColorPicker(tabData, label, defaultColor, callback)
    defaultColor = defaultColor or Color3.fromRGB(255, 80, 80)
    local h, s, v = color3ToHsv(defaultColor)

    table.insert(tabData.items, function(parent, order)
        -- One container holds the header row and the collapsible picker body.
        -- AutomaticSize.Y expands it to fit when the picker is open.
        local container = make("Frame", {
            Name                   = "CPContainer_" .. order,
            Size                   = UDim2.new(1, 0, 0, 0),
            AutomaticSize          = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder            = order,
            Parent                 = parent,
        })
        local contLayout = Instance.new("UIListLayout")
        contLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contLayout.Padding   = UDim.new(0, 4)
        contLayout.Parent    = container

        -- ── Header row ────────────────────────────────────────
        local header = make("Frame", {
            Name                   = "CPHeader",
            Size                   = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            LayoutOrder            = 1,
            Parent                 = container,
        })
        make("TextLabel", {
            Size                   = UDim2.new(1, -52, 1, 0),
            BackgroundTransparency = 1,
            Text                   = label,
            TextColor3             = THEME.ToggleText,
            TextSize               = DEFAULTS.FontSize,
            FontFace               = FONT_REG,
            TextXAlignment         = Enum.TextXAlignment.Left,
            Parent                 = header,
        })
        local swatch = make("TextButton", {
            Size             = UDim2.new(0, 40, 0, 20),
            Position         = UDim2.new(1, -40, 0.5, -10),
            BackgroundColor3 = defaultColor,
            Text             = "",
            BorderSizePixel  = 0,
            Parent           = header,
        })
        corner(4, swatch)
        stroke(THEME.DropdownBorder, 1, swatch)

        -- ── Picker body ───────────────────────────────────────
        local boxH    = 110
        local hueBarH = 14
        local gapH    = 8
        local pickerH = boxH + gapH + hueBarH

        local picker = make("Frame", {
            Name                   = "CPPicker",
            Size                   = UDim2.new(1, 0, 0, pickerH),
            BackgroundTransparency = 1,
            LayoutOrder            = 2,
            Visible                = false,
            Parent                 = container,
        })

        local expanded = false
        swatch.MouseButton1Click:Connect(function()
            expanded       = not expanded
            picker.Visible = expanded
        end)

        -- ── SV box ────────────────────────────────────────────
        local svBox = make("Frame", {
            Name             = "SVBox",
            Size             = UDim2.new(1, 0, 0, boxH),
            Position         = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = hsvToColor3(h, 1, 1),
            BorderSizePixel  = 0,
            ClipsDescendants = true,
            Parent           = picker,
        })
        corner(4, svBox)

        -- White gradient layer: fully white on left, transparent on right
        local whiteOverlay = make("Frame", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel        = 0,
            ZIndex                 = 2,
            Parent                 = svBox,
        })
        do
            local g = Instance.new("UIGradient")
            g.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
                ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
            }
            g.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }
            g.Rotation = 0   -- left→right
            g.Parent   = whiteOverlay
        end

        -- Black gradient layer: transparent at top, black at bottom
        local blackOverlay = make("Frame", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel        = 0,
            ZIndex                 = 3,
            Parent                 = svBox,
        })
        do
            local g = Instance.new("UIGradient")
            g.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
                ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
            }
            g.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }
            g.Rotation = 90  -- top→bottom
            g.Parent   = blackOverlay
        end

        -- SV cursor
        local svKnob = make("Frame", {
            Size             = UDim2.new(0, 12, 0, 12),
            Position         = UDim2.new(s, -6, 1-v, -6),
            BackgroundColor3 = Color3.new(1,1,1),
            BorderSizePixel  = 0,
            ZIndex           = 5,
            Parent           = svBox,
        })
        corner(6, svKnob)
        stroke(Color3.new(0,0,0), 1.5, svKnob)

        -- Drag capture over SV box (above all gradient layers)
        local svDrag = make("TextButton", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 6,
            Parent                 = svBox,
        })

        -- ── Hue bar ───────────────────────────────────────────
        local hueBar = make("ImageLabel", {
            Name             = "HueBar",
            Size             = UDim2.new(1, 0, 0, hueBarH),
            Position         = UDim2.new(0, 0, 0, boxH + gapH),
            BackgroundColor3 = Color3.new(1,1,1),
            BorderSizePixel  = 0,
            Image            = "rbxassetid://698052001",
            ScaleType        = Enum.ScaleType.Stretch,
            Parent           = picker,
        })
        corner(4, hueBar)
        stroke(THEME.DropdownBorder, 1, hueBar)

        local hueKnob = make("Frame", {
            Size             = UDim2.new(0, 5, 1, 4),
            Position         = UDim2.new(h, -2, 0, -2),
            BackgroundColor3 = Color3.new(1,1,1),
            BorderSizePixel  = 0,
            ZIndex           = 3,
            Parent           = hueBar,
        })
        corner(2, hueKnob)
        stroke(Color3.new(0,0,0), 1, hueKnob)

        local hueDrag = make("TextButton", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 4,
            Parent                 = hueBar,
        })

        -- ── Rebuild ───────────────────────────────────────────
        local function rebuild()
            local col               = hsvToColor3(h, s, v)
            swatch.BackgroundColor3 = col
            svBox.BackgroundColor3  = hsvToColor3(h, 1, 1)
            svKnob.Position         = UDim2.new(s, -6, 1-v, -6)
            hueKnob.Position        = UDim2.new(h, -2, 0, -2)
            if callback then callback(col) end
        end

        rebuild()

        -- SV drag
        local svDragging = false
        local function updateSV(x, y)
            local ap = svBox.AbsolutePosition
            local as = svBox.AbsoluteSize
            s = math.clamp((x - ap.X) / as.X, 0, 1)
            v = math.clamp(1 - (y - ap.Y) / as.Y, 0, 1)
            rebuild()
        end
        svDrag.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                svDragging = true
                updateSV(inp.Position.X, inp.Position.Y)
            end
        end)
        svDrag.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if svDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                updateSV(inp.Position.X, inp.Position.Y)
            end
        end)

        -- Hue drag
        local hueDragging = false
        local function updateHue(x)
            local ap = hueBar.AbsolutePosition
            local as = hueBar.AbsoluteSize
            h = math.clamp((x - ap.X) / as.X, 0, 1)
            rebuild()
        end
        hueDrag.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                hueDragging = true
                updateHue(inp.Position.X)
            end
        end)
        hueDrag.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if hueDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                updateHue(inp.Position.X)
            end
        end)
    end)
end

-- ── TabBuilder methods ────────────────────────────────────────
function TabBuilder:Label(text)           addLabel(self._tabData, text);                                                        return self end
function TabBuilder:Separator()           addSeparator(self._tabData);                                                          return self end
function TabBuilder:Button(l, cb)         addButton(self._tabData, l, cb);                                                      return self end
function TabBuilder:Toggle(l, d, cb)      addToggle(self._tabData, l, d, cb);                                                   return self end
function TabBuilder:Slider(l,mn,mx,d,cb)  addSlider(self._tabData, l, mn, mx, d, cb);                                          return self end
function TabBuilder:Dropdown(l, opts, cb) addDropdown(self._tabData, self._dropdownOverlay, self._window, l, opts, cb);         return self end
function TabBuilder:ColorPicker(l, c, cb) addColorPicker(self._tabData, l, c, cb);                                              return self end

-- ── RbxImGui proxy methods (no-tab / single-tab usage) ────────
local function ensureDefault(self)
    if not self._tabsByName["__default"] then
        self:AddTab("__default")
        self._tabsByName["__default"].tabBtn.Visible = false
        self._tabBar.Visible = false
        self._contentArea.Position = UDim2.new(0, 0, 0, DEFAULTS.TitleBarHeight)
        self._contentArea.Size     = UDim2.new(1, 0, 1, -(DEFAULTS.TitleBarHeight + DEFAULTS.ResizeGripSize))
    end
    return self._tabsByName["__default"]
end

function RbxImGui:Label(text)           addLabel(ensureDefault(self), text);                                                                         return self end
function RbxImGui:Separator()           addSeparator(ensureDefault(self));                                                                           return self end
function RbxImGui:Button(l, cb)         addButton(ensureDefault(self), l, cb);                                                                       return self end
function RbxImGui:Toggle(l, d, cb)      addToggle(ensureDefault(self), l, d, cb);                                                                    return self end
function RbxImGui:Slider(l,mn,mx,d,cb)  addSlider(ensureDefault(self), l, mn, mx, d, cb);                                                           return self end
function RbxImGui:Dropdown(l, opts, cb) addDropdown(ensureDefault(self), self._dropdownOverlay, self._window, l, opts, cb);                          return self end
function RbxImGui:ColorPicker(l, c, cb) addColorPicker(ensureDefault(self), l, c, cb);                                                               return self end

-- ── Render ────────────────────────────────────────────────────
function RbxImGui:Render()
    for _, td in ipairs(self._tabs) do
        for i, builder in ipairs(td.items) do
            builder(td.scrollFrame, i)
        end
    end
    self._rendered = true
end

-- ── Visibility ────────────────────────────────────────────────
function RbxImGui:Show()          self._window.Visible = true  end
function RbxImGui:Hide()          self._window.Visible = false end
function RbxImGui:Toggle_Window() self._window.Visible = not self._window.Visible end
function RbxImGui:Destroy()       if self._screenGui then self._screenGui:Destroy() end end

return RbxImGui
