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
-- win:Tab("Misc"):Dropdown("Mode", {"Option A","Option B","Option C"}, function(v) end)
-- win:Tab("Misc"):ColorPicker("Color", Color3.fromRGB(255,100,100), function(c) end)
--
-- win:Render()
-- ============================================================
local RbxImGui = {}
RbxImGui.__index = RbxImGui

-- Tab builder object — returned by win:Tab()
local TabBuilder = {}
TabBuilder.__index = TabBuilder

-- ── Theming ──────────────────────────────────────────────────
local THEME = {
    TitleBarBg      = Color3.fromRGB(20, 20, 26),
    TitleBarText    = Color3.fromRGB(220, 220, 220),
    TabBarBg        = Color3.fromRGB(18, 18, 24),
    TabBg           = Color3.fromRGB(38, 38, 52),
    TabHover        = Color3.fromRGB(55, 55, 75),
    TabActive       = Color3.fromRGB(82, 130, 255),
    TabText         = Color3.fromRGB(170, 170, 195),
    TabTextActive   = Color3.fromRGB(255, 255, 255),
    WindowBg        = Color3.fromRGB(22, 22, 28),
    WindowBorder    = Color3.fromRGB(55, 55, 75),
    ButtonBg        = Color3.fromRGB(52, 52, 68),
    ButtonHover     = Color3.fromRGB(72, 72, 100),
    ButtonActive    = Color3.fromRGB(82, 130, 255),
    ButtonText      = Color3.fromRGB(210, 210, 220),
    ToggleOff       = Color3.fromRGB(55, 55, 70),
    ToggleOn        = Color3.fromRGB(82, 130, 255),
    ToggleKnob      = Color3.fromRGB(240, 240, 255),
    ToggleText      = Color3.fromRGB(200, 200, 215),
    SliderTrack     = Color3.fromRGB(40, 40, 55),
    SliderFill      = Color3.fromRGB(82, 130, 255),
    SliderKnob      = Color3.fromRGB(230, 230, 255),
    SliderText      = Color3.fromRGB(200, 200, 215),
    SliderValue     = Color3.fromRGB(140, 160, 255),
    SeparatorColor  = Color3.fromRGB(50, 50, 68),
    TextColor       = Color3.fromRGB(200, 200, 215),
    ResizeGrip      = Color3.fromRGB(40, 40, 55),
    ResizeGripHover = Color3.fromRGB(82, 130, 255),
    ScrollThumb     = Color3.fromRGB(80, 80, 110),
    -- Dropdown
    DropdownBg      = Color3.fromRGB(30, 30, 42),
    DropdownBorder  = Color3.fromRGB(65, 65, 95),
    DropdownItemHover = Color3.fromRGB(50, 60, 90),
    DropdownText    = Color3.fromRGB(200, 200, 215),
    DropdownArrow   = Color3.fromRGB(140, 160, 255),
    -- ColorPicker
    ColorPickerBg   = Color3.fromRGB(26, 26, 34),
}

-- ── Defaults ─────────────────────────────────────────────────
local DEFAULTS = {
    WindowWidth     = 320,
    WindowMinWidth  = 200,
    WindowMinHeight = 120,
    TitleBarHeight  = 30,
    TabBarHeight    = 30,
    TabMinWidth     = 60,
    Padding         = 10,
    ItemSpacing     = 6,
    ButtonHeight    = 28,
    ToggleHeight    = 24,
    SliderHeight    = 30,
    CornerRadius    = 6,
    FontSize        = 13,
    ResizeGripSize  = 14,
    DropdownHeight  = 28,
    DropdownItemH   = 26,
    DropdownMaxItems= 5,
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

local FONT_REG  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular,  Enum.FontStyle.Normal)
local FONT_SEMI = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
local FONT_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold,     Enum.FontStyle.Normal)

-- ── HSV ↔ RGB helpers (correct axis mapping) ─────────────────
-- H: 0–1 (hue), S: 0–1 (saturation), V: 0–1 (value/brightness)
-- Returns Color3
local function hsvToColor3(h, s, v)
    -- Standard HSV → RGB formula; no axis swap.
    h = h % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    local r, g, b
    local seg = i % 6
    if seg == 0 then r,g,b = v,t,p
    elseif seg == 1 then r,g,b = q,v,p
    elseif seg == 2 then r,g,b = p,v,t
    elseif seg == 3 then r,g,b = p,q,v
    elseif seg == 4 then r,g,b = t,p,v
    else              r,g,b = v,p,q
    end
    return Color3.new(r, g, b)
end

-- Color3 → {h, s, v}  (all 0–1)
local function color3ToHsv(c)
    local r, g, b = c.R, c.G, c.B
    local mx = math.max(r, g, b)
    local mn = math.min(r, g, b)
    local d  = mx - mn
    local h, s, v
    v = mx
    s = mx == 0 and 0 or d / mx
    if d == 0 then
        h = 0
    elseif mx == r then
        h = ((g - b) / d) % 6
        h = h / 6
    elseif mx == g then
        h = ((b - r) / d + 2) / 6
    else
        h = ((r - g) / d + 4) / 6
    end
    return h, s, v
end

-- ── Constructor ───────────────────────────────────────────────
function RbxImGui.new(title, parent)
    local self = setmetatable({}, RbxImGui)
    self._title       = title or "Window"
    self._tabs        = {}
    self._tabsByName  = {}
    self._activeTab   = nil
    self._rendered    = false

    -- ── ScreenGui ─────────────────────────────────────────────
    if not parent then
        local sg = Instance.new("ScreenGui")
        sg.Name            = "RbxImGui_" .. self._title
        sg.ResetOnSpawn    = false
        sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder    = 999
        if not pcall(function() sg.Parent = game:GetService("CoreGui") end) then
            sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end
        parent = sg
    end
    self._screenGui = parent

    -- ── Window ────────────────────────────────────────────────
    self._window = make("Frame", {
        Name                = "ImGuiWindow",
        Size                = UDim2.new(0, DEFAULTS.WindowWidth, 0, 340),
        Position            = UDim2.new(0, 80, 0, 80),
        BackgroundColor3    = THEME.WindowBg,
        BorderSizePixel     = 0,
        ClipsDescendants    = false,   -- allow dropdown overlay to escape the frame
        Parent              = parent,
    })
    corner(DEFAULTS.CornerRadius, self._window)
    stroke(THEME.WindowBorder, 1, self._window)

    -- ── Title Bar ─────────────────────────────────────────────
    local titleBar = make("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, DEFAULTS.TitleBarHeight),
        BackgroundColor3 = THEME.TitleBarBg,
        BorderSizePixel  = 0,
        Parent           = self._window,
    })

    make("TextLabel", {
        Name                 = "Title",
        Size                 = UDim2.new(1, -12, 1, 0),
        Position             = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text                 = self._title,
        TextColor3           = THEME.TitleBarText,
        TextSize             = DEFAULTS.FontSize + 1,
        FontFace             = FONT_BOLD,
        TextXAlignment       = Enum.TextXAlignment.Left,
        Parent               = titleBar,
    })

    -- ── Drag ──────────────────────────────────────────────────
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = inp.Position; startPos = self._window.Position
        end
    end)
    titleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            self._window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
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
        Name                 = "TabInner",
        Size                 = UDim2.new(1, 0, 1, -1),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Parent               = self._tabBar,
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

    -- Clip frame: clips the scroll content but is NOT a parent of dropdown overlays
    local clipFrame = make("Frame", {
        Name                = "ContentClip",
        Size                = UDim2.new(1, 0, 1, -(contentTop + DEFAULTS.ResizeGripSize)),
        Position            = UDim2.new(0, 0, 0, contentTop),
        BackgroundTransparency = 1,
        BorderSizePixel     = 0,
        ClipsDescendants    = true,
        Parent              = self._window,
    })
    self._clipFrame = clipFrame

    self._contentArea = make("Frame", {
        Name                = "ContentArea",
        Size                = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel     = 0,
        Parent              = clipFrame,
    })

    -- Overlay layer for dropdowns — child of screenGui so it floats above everything
    -- and is NOT clipped by the scroll frame or window clip.
    self._overlayLayer = make("Frame", {
        Name                = "DropdownOverlay",
        Size                = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel     = 0,
        ZIndex              = 100,
        Parent              = parent,
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
            resizing = true; resizeStart = inp.Position; resizeStartSize = self._window.AbsoluteSize
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
function RbxImGui:AddTab(name)
    local tabIndex = #self._tabs + 1

    local btn = make("TextButton", {
        Name             = "Tab_" .. name,
        Size             = UDim2.new(0, math.max(DEFAULTS.TabMinWidth, #name * 8 + 20), 0, 22),
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
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        ScrollBarThickness    = 4,
        ScrollBarImageColor3  = THEME.ScrollThumb,
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        -- FIX: prevent scroll frame from being scrolled by the window-level scroll
        ScrollingEnabled      = true,
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
    }
    self._tabs[tabIndex]    = tabData
    self._tabsByName[name]  = tabData

    btn.MouseButton1Click:Connect(function() self:_switchTab(name) end)
    btn.MouseEnter:Connect(function()
        if self._activeTab ~= name then tween(btn, {BackgroundColor3 = THEME.TabHover}) end
    end)
    btn.MouseLeave:Connect(function()
        if self._activeTab ~= name then tween(btn, {BackgroundColor3 = THEME.TabBg}) end
    end)

    if tabIndex == 1 then self:_switchTab(name) end
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
    local builder = setmetatable({}, TabBuilder)
    builder._tabData     = self._tabsByName[name]
    builder._overlayLayer = self._overlayLayer
    return builder
end

-- ── Widget Implementations ────────────────────────────────────

local function addLabel(tabData, text)
    table.insert(tabData.items, function(parent, order)
        make("TextLabel", {
            Name                 = "Label_" .. order,
            Size                 = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text                 = text,
            TextColor3           = THEME.TextColor,
            TextSize             = DEFAULTS.FontSize,
            FontFace             = FONT_REG,
            TextXAlignment       = Enum.TextXAlignment.Left,
            LayoutOrder          = order,
            Parent               = parent,
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
            Name                 = "Toggle_" .. order,
            Size                 = UDim2.new(1, 0, 0, DEFAULTS.ToggleHeight),
            BackgroundTransparency = 1,
            LayoutOrder          = order,
            Parent               = parent,
        })
        make("TextLabel", {
            Size                 = UDim2.new(1, -50, 1, 0),
            BackgroundTransparency = 1,
            Text                 = label,
            TextColor3           = THEME.ToggleText,
            TextSize             = DEFAULTS.FontSize,
            FontFace             = FONT_REG,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Parent               = row,
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
        local kS = tH - 4
        local knob = make("Frame", {
            Size             = UDim2.new(0, kS, 0, kS),
            Position         = state and UDim2.new(0, tW-kS-2, 0.5, -kS/2) or UDim2.new(0, 2, 0.5, -kS/2),
            BackgroundColor3 = THEME.ToggleKnob,
            BorderSizePixel  = 0,
            Parent           = track,
        })
        corner(kS/2, knob)
        local clickBtn = make("TextButton", {
            Size                 = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                 = "",
            Parent               = row,
        })
        clickBtn.MouseButton1Click:Connect(function()
            state = not state
            tween(track, {BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff})
            tween(knob,  {Position = state and UDim2.new(0, tW-kS-2, 0.5, -kS/2) or UDim2.new(0, 2, 0.5, -kS/2)})
            if callback then callback(state) end
        end)
    end)
end

local function addSlider(tabData, label, min, max, default, callback)
    min     = min or 0
    max     = max or 100
    default = default or min
    local value = math.clamp(default, min, max)

    table.insert(tabData.items, function(parent, order)
        local col = make("Frame", {
            Name                 = "Slider_" .. order,
            Size                 = UDim2.new(1, 0, 0, DEFAULTS.SliderHeight + 16),
            BackgroundTransparency = 1,
            LayoutOrder          = order,
            Parent               = parent,
        })
        local hdr = make("Frame", {
            Size                 = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Parent               = col,
        })
        make("TextLabel", {
            Size                 = UDim2.new(0.6, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                 = label,
            TextColor3           = THEME.SliderText,
            TextSize             = DEFAULTS.FontSize,
            FontFace             = FONT_REG,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Parent               = hdr,
        })
        local valLbl = make("TextLabel", {
            Size                 = UDim2.new(0.4, 0, 1, 0),
            Position             = UDim2.new(0.6, 0, 0, 0),
            BackgroundTransparency = 1,
            Text                 = tostring(math.floor(value)),
            TextColor3           = THEME.SliderValue,
            TextSize             = DEFAULTS.FontSize,
            FontFace             = FONT_BOLD,
            TextXAlignment       = Enum.TextXAlignment.Right,
            Parent               = hdr,
        })
        local trkH = 6
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
            Size                 = UDim2.new(1, 0, 0, DEFAULTS.SliderHeight),
            Position             = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            Text                 = "",
            ZIndex               = 3,
            Parent               = col,
        })

        local function update(x)
            local p  = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value    = min + p * (max - min)
            valLbl.Text  = tostring(math.floor(value))
            fill.Size    = UDim2.new(p, 0, 1, 0)
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

-- ── DROPDOWN (fixed: overlay parented to screenGui, not scroll frame) ──────
--
-- The dropdown panel is placed in self._overlayLayer (a child of the ScreenGui),
-- positioned in absolute screen coordinates. This means scrolling the tab's
-- ScrollingFrame has zero effect on the dropdown panel's position — it stays
-- pinned exactly where the button is on screen.
local function addDropdown(tabData, overlayLayer, label, options, callback)
    options = options or {}
    local selectedIndex = 1
    local isOpen        = false
    local menuFrame     = nil  -- created lazily, stored here

    table.insert(tabData.items, function(parent, order)
        -- Row container (lives inside the scroll frame, normal flow)
        local rowH = DEFAULTS.DropdownHeight
        local row  = make("Frame", {
            Name                 = "Dropdown_" .. order,
            Size                 = UDim2.new(1, 0, 0, rowH + 4),
            BackgroundTransparency = 1,
            LayoutOrder          = order,
            Parent               = parent,
        })

        -- Label above the button
        make("TextLabel", {
            Size                 = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text                 = label,
            TextColor3           = THEME.DropdownText,
            TextSize             = DEFAULTS.FontSize,
            FontFace             = FONT_REG,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Parent               = row,
        })

        -- The clickable button row
        local btn = make("TextButton", {
            Name             = "DropBtn",
            Size             = UDim2.new(1, 0, 0, rowH),
            Position         = UDim2.new(0, 0, 0, 18),
            BackgroundColor3 = THEME.DropdownBg,
            Text             = "",
            BorderSizePixel  = 0,
            ClipsDescendants = true,
            Parent           = row,
        })
        corner(5, btn)
        stroke(THEME.DropdownBorder, 1, btn)

        -- Selected value text
        local selLabel = make("TextLabel", {
            Size                 = UDim2.new(1, -30, 1, 0),
            Position             = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text                 = options[selectedIndex] or "Select...",
            TextColor3           = THEME.DropdownText,
            TextSize             = DEFAULTS.FontSize,
            FontFace             = FONT_SEMI,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Parent               = btn,
        })

        -- FIX: Arrow icon drawn with Unicode chevron characters, not a blank Frame.
        -- "▾" (U+25BE) is a solid downward-pointing small triangle — clean and modern.
        local arrowLbl = make("TextLabel", {
            Name                 = "DropArrow",
            Size                 = UDim2.new(0, 20, 1, 0),
            Position             = UDim2.new(1, -24, 0, 0),
            BackgroundTransparency = 1,
            Text                 = "▾",
            TextColor3           = THEME.DropdownArrow,
            TextSize             = DEFAULTS.FontSize + 4,
            FontFace             = FONT_BOLD,
            TextXAlignment       = Enum.TextXAlignment.Center,
            TextYAlignment       = Enum.TextYAlignment.Center,
            Parent               = btn,
        })

        local function closeMenu()
            if menuFrame then
                menuFrame:Destroy()
                menuFrame = nil
            end
            -- Animate arrow back to pointing down
            tween(arrowLbl, {Rotation = 0})
            isOpen = false
        end

        local function openMenu()
            if menuFrame then closeMenu(); return end
            isOpen = true

            -- Animate arrow to point up (rotate 180°)
            tween(arrowLbl, {Rotation = 180})

            -- Calculate absolute screen position of the button
            -- We wait one frame to ensure AbsolutePosition is updated
            local absPos  = btn.AbsolutePosition
            local absSize = btn.AbsoluteSize

            local itemH    = DEFAULTS.DropdownItemH
            local maxItems = DEFAULTS.DropdownMaxItems
            local visItems = math.min(#options, maxItems)
            local menuH    = visItems * itemH + 4

            -- FIX: Parent the menu to overlayLayer (child of ScreenGui), NOT to the
            -- scroll frame or the window. Position is set in absolute screen coords.
            -- This means the dropdown panel is completely independent of any scrolling.
            menuFrame = make("Frame", {
                Name             = "DropdownMenu",
                Size             = UDim2.new(0, absSize.X, 0, menuH),
                Position         = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2),
                BackgroundColor3 = THEME.DropdownBg,
                BorderSizePixel  = 0,
                ZIndex           = 110,
                ClipsDescendants = true,
                Parent           = overlayLayer,
            })
            corner(5, menuFrame)
            stroke(THEME.DropdownBorder, 1, menuFrame)

            -- Scrolling frame inside the menu (for many options)
            local msf = make("ScrollingFrame", {
                Size                  = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel       = 0,
                ScrollBarThickness    = 3,
                ScrollBarImageColor3  = THEME.ScrollThumb,
                CanvasSize            = UDim2.new(0, 0, 0, #options * itemH),
                ZIndex                = 111,
                Parent                = menuFrame,
            })

            local mll = Instance.new("UIListLayout")
            mll.SortOrder = Enum.SortOrder.LayoutOrder
            mll.Parent    = msf

            for i, opt in ipairs(options) do
                local item = make("TextButton", {
                    Name             = "Item_" .. i,
                    Size             = UDim2.new(1, 0, 0, itemH),
                    BackgroundColor3 = (i == selectedIndex) and THEME.DropdownItemHover or THEME.DropdownBg,
                    Text             = opt,
                    TextColor3       = THEME.DropdownText,
                    TextSize         = DEFAULTS.FontSize,
                    FontFace         = (i == selectedIndex) and FONT_SEMI or FONT_REG,
                    BorderSizePixel  = 0,
                    LayoutOrder      = i,
                    ZIndex           = 112,
                    Parent           = msf,
                })
                local iPad = Instance.new("UIPadding")
                iPad.PaddingLeft = UDim.new(0, 10)
                iPad.Parent      = item

                item.MouseEnter:Connect(function()
                    if i ~= selectedIndex then
                        tween(item, {BackgroundColor3 = THEME.DropdownItemHover})
                    end
                end)
                item.MouseLeave:Connect(function()
                    if i ~= selectedIndex then
                        tween(item, {BackgroundColor3 = THEME.DropdownBg})
                    end
                end)
                item.MouseButton1Click:Connect(function()
                    selectedIndex    = i
                    selLabel.Text    = opt
                    closeMenu()
                    if callback then callback(opt, i) end
                end)
            end

            -- Close menu when clicking anywhere outside it
            -- Use a single-shot connection
            local closeConn
            closeConn = UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    -- Check if click is inside the menu or button
                    local mx, my = inp.Position.X, inp.Position.Y
                    local mPos   = menuFrame and menuFrame.AbsolutePosition
                    local mSize  = menuFrame and menuFrame.AbsoluteSize
                    local bPos   = btn.AbsolutePosition
                    local bSize  = btn.AbsoluteSize

                    local inMenu  = mPos and (mx >= mPos.X and mx <= mPos.X + mSize.X and my >= mPos.Y and my <= mPos.Y + mSize.Y)
                    local inBtn   = (mx >= bPos.X and mx <= bPos.X + bSize.X and my >= bPos.Y and my <= bPos.Y + bSize.Y)

                    if not inMenu and not inBtn then
                        closeMenu()
                        closeConn:Disconnect()
                    end
                end
            end)
        end

        btn.MouseButton1Click:Connect(function()
            if isOpen then closeMenu() else openMenu() end
        end)

        btn.MouseEnter:Connect(function()
            if not isOpen then tween(btn, {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}) end
        end)
        btn.MouseLeave:Connect(function()
            if not isOpen then tween(btn, {BackgroundColor3 = THEME.DropdownBg}) end
        end)
    end)
end

-- ── COLOR PICKER (correct HSV mapping: H=hue left-right, S/V gradient) ──────
--
-- FIX: Previous implementation swapped the green and blue axes in the HSV→RGB
-- conversion. The correct formula is the standard 6-sector HSV model:
--   hue 0° = red, 120° = green, 240° = blue
-- The hsvToColor3() helper at the top of this file implements this correctly.
-- ColorPicker uses it directly — no extra axis swapping.
local function addColorPicker(tabData, label, defaultColor, callback)
    defaultColor = defaultColor or Color3.fromRGB(255, 100, 100)
    local h, s, v = color3ToHsv(defaultColor)

    table.insert(tabData.items, function(parent, order)
        local PICKER_H  = 120  -- height of the SV gradient square
        local PICKER_W  = 1    -- full width (scale)
        local HUE_H     = 14   -- hue bar height
        local PREVIEW_S = 18   -- color preview square size

        local col = make("Frame", {
            Name                 = "ColorPicker_" .. order,
            Size                 = UDim2.new(1, 0, 0, 16 + PICKER_H + 8 + HUE_H + 8 + PREVIEW_S + 4),
            BackgroundTransparency = 1,
            LayoutOrder          = order,
            Parent               = parent,
        })

        -- Label
        make("TextLabel", {
            Size                 = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text                 = label,
            TextColor3           = THEME.DropdownText,
            TextSize             = DEFAULTS.FontSize,
            FontFace             = FONT_REG,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Parent               = col,
        })

        -- ── SV Gradient Square ────────────────────────────────
        -- Base: pure hue color (S=1, V=1) — updated as hue changes
        local svArea = make("Frame", {
            Name             = "SVArea",
            Size             = UDim2.new(1, 0, 0, PICKER_H),
            Position         = UDim2.new(0, 0, 0, 18),
            BackgroundColor3 = hsvToColor3(h, 1, 1),
            BorderSizePixel  = 0,
            ClipsDescendants = true,
            Parent           = col,
        })
        corner(4, svArea)

        -- White → transparent gradient (left to right = S axis: 0 → 1 is right)
        -- White overlay fades from left (white, S=0) to transparent (S=1)
        local whiteGrad = make("Frame", {
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel  = 0,
            Parent           = svArea,
        })
        local wGradInst = Instance.new("UIGradient")
        wGradInst.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
        })
        wGradInst.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),   -- left = fully white (S=0)
            NumberSequenceKeypoint.new(1, 1),   -- right = transparent (S=1)
        })
        wGradInst.Parent = whiteGrad

        -- Black → transparent gradient (top to bottom = V axis: 1 → 0 is down)
        local blackGrad = make("Frame", {
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(0,0,0),
            BorderSizePixel  = 0,
            Parent           = svArea,
        })
        local bGradInst = Instance.new("UIGradient")
        bGradInst.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
            ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
        })
        bGradInst.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),   -- top = transparent (V=1)
            NumberSequenceKeypoint.new(1, 0),   -- bottom = fully black (V=0)
        })
        bGradInst.Rotation = 90
        bGradInst.Parent   = blackGrad

        -- SV cursor
        local svCursor = make("Frame", {
            Size             = UDim2.new(0, 10, 0, 10),
            Position         = UDim2.new(s, -5, 1-v, -5),
            BackgroundColor3 = Color3.new(1,1,1),
            BorderSizePixel  = 0,
            ZIndex           = 3,
            Parent           = svArea,
        })
        corner(5, svCursor)
        stroke(Color3.new(0,0,0), 1, svCursor)

        -- ── Hue Bar ───────────────────────────────────────────
        -- Horizontal rainbow bar: left=0° (red), right=360° (red again)
        local hueBar = make("Frame", {
            Name             = "HueBar",
            Size             = UDim2.new(1, 0, 0, HUE_H),
            Position         = UDim2.new(0, 0, 0, 18 + PICKER_H + 8),
            BackgroundColor3 = Color3.new(1,1,1),
            BorderSizePixel  = 0,
            ClipsDescendants = true,
            Parent           = col,
        })
        corner(4, hueBar)

        -- Build rainbow gradient across the hue spectrum
        local hueKeypoints = {}
        local steps = 7
        for i = 0, steps do
            local t = i / steps
            hueKeypoints[i+1] = ColorSequenceKeypoint.new(t, hsvToColor3(t, 1, 1))
        end
        local hueGrad = Instance.new("UIGradient")
        hueGrad.Color  = ColorSequence.new(hueKeypoints)
        hueGrad.Parent = hueBar

        -- Hue cursor
        local hueCursor = make("Frame", {
            Size             = UDim2.new(0, 4, 1, 4),
            Position         = UDim2.new(h, -2, 0, -2),
            BackgroundColor3 = Color3.new(1,1,1),
            BorderSizePixel  = 0,
            ZIndex           = 3,
            Parent           = hueBar,
        })
        corner(2, hueCursor)
        stroke(Color3.new(0,0,0), 1, hueCursor)

        -- ── Color Preview + Hex ───────────────────────────────
        local previewRow = make("Frame", {
            Size                 = UDim2.new(1, 0, 0, PREVIEW_S),
            Position             = UDim2.new(0, 0, 0, 18 + PICKER_H + 8 + HUE_H + 8),
            BackgroundTransparency = 1,
            Parent               = col,
        })

        local preview = make("Frame", {
            Size             = UDim2.new(0, PREVIEW_S, 0, PREVIEW_S),
            BackgroundColor3 = hsvToColor3(h, s, v),
            BorderSizePixel  = 0,
            Parent           = previewRow,
        })
        corner(4, preview)
        stroke(THEME.DropdownBorder, 1, preview)

        local function toHex(c)
            return string.format("#%02X%02X%02X",
                math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
        end

        local hexLbl = make("TextLabel", {
            Size                 = UDim2.new(1, -(PREVIEW_S+8), 1, 0),
            Position             = UDim2.new(0, PREVIEW_S+8, 0, 0),
            BackgroundTransparency = 1,
            Text                 = toHex(hsvToColor3(h, s, v)),
            TextColor3           = THEME.SliderValue,
            TextSize             = DEFAULTS.FontSize - 1,
            FontFace             = FONT_SEMI,
            TextXAlignment       = Enum.TextXAlignment.Left,
            TextYAlignment       = Enum.TextYAlignment.Center,
            Parent               = previewRow,
        })

        -- ── Update callback ───────────────────────────────────
        local function applyColor()
            -- FIX: use the correct hsvToColor3 — no axis swap
            local c = hsvToColor3(h, s, v)
            preview.BackgroundColor3 = c
            hexLbl.Text              = toHex(c)
            svArea.BackgroundColor3  = hsvToColor3(h, 1, 1)
            if callback then callback(c) end
        end

        -- ── SV area interaction ───────────────────────────────
        local svBtn = make("TextButton", {
            Size                 = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                 = "",
            ZIndex               = 4,
            Parent               = svArea,
        })

        local function updateSV(x, y)
            local rel = svArea.AbsolutePosition
            local sz  = svArea.AbsoluteSize
            -- S = horizontal (0=left, 1=right), V = vertical (1=top, 0=bottom)
            s = math.clamp((x - rel.X) / sz.X, 0, 1)
            v = math.clamp(1 - (y - rel.Y) / sz.Y, 0, 1)
            svCursor.Position = UDim2.new(s, -5, 1-v, -5)
            applyColor()
        end

        local svDragging = false
        svBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                svDragging = true; updateSV(inp.Position.X, inp.Position.Y)
            end
        end)
        svBtn.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if svDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                updateSV(inp.Position.X, inp.Position.Y)
            end
        end)

        -- ── Hue bar interaction ───────────────────────────────
        local hueBtn = make("TextButton", {
            Size                 = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                 = "",
            ZIndex               = 4,
            Parent               = hueBar,
        })

        local function updateHue(x)
            local rel = hueBar.AbsolutePosition
            local sz  = hueBar.AbsoluteSize
            h = math.clamp((x - rel.X) / sz.X, 0, 1)
            hueCursor.Position = UDim2.new(h, -2, 0, -2)
            applyColor()
        end

        local hueDragging = false
        hueBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                hueDragging = true; updateHue(inp.Position.X)
            end
        end)
        hueBtn.InputEnded:Connect(function(inp)
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
function TabBuilder:Label(text)          addLabel(self._tabData, text);                               return self end
function TabBuilder:Separator()          addSeparator(self._tabData);                                 return self end
function TabBuilder:Button(l, cb)        addButton(self._tabData, l, cb);                             return self end
function TabBuilder:Toggle(l, d, cb)     addToggle(self._tabData, l, d, cb);                          return self end
function TabBuilder:Slider(l,mn,mx,d,cb) addSlider(self._tabData, l, mn, mx, d, cb);                  return self end
function TabBuilder:Dropdown(l, opts, cb) addDropdown(self._tabData, self._overlayLayer, l, opts, cb); return self end
function TabBuilder:ColorPicker(l, def, cb) addColorPicker(self._tabData, l, def, cb);                return self end

-- ── RbxImGui proxy methods (single-tab / no-tab usage) ────────
local function ensureDefault(self)
    if not self._tabsByName["__default"] then
        self:AddTab("__default")
        self._tabsByName["__default"].tabBtn.Visible = false
        self._tabBar.Visible = false
        self._clipFrame.Position = UDim2.new(0, 0, 0, DEFAULTS.TitleBarHeight)
        self._clipFrame.Size     = UDim2.new(1, 0, 1, -(DEFAULTS.TitleBarHeight + DEFAULTS.ResizeGripSize))
    end
    return self._tabsByName["__default"]
end

function RbxImGui:Label(text)            addLabel(ensureDefault(self), text);                                      return self end
function RbxImGui:Separator()            addSeparator(ensureDefault(self));                                        return self end
function RbxImGui:Button(l, cb)          addButton(ensureDefault(self), l, cb);                                    return self end
function RbxImGui:Toggle(l, d, cb)       addToggle(ensureDefault(self), l, d, cb);                                 return self end
function RbxImGui:Slider(l,mn,mx,d,cb)  addSlider(ensureDefault(self), l, mn, mx, d, cb);                         return self end
function RbxImGui:Dropdown(l, opts, cb) addDropdown(ensureDefault(self), self._overlayLayer, l, opts, cb);         return self end
function RbxImGui:ColorPicker(l,def,cb) addColorPicker(ensureDefault(self), l, def, cb);                           return self end

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
function RbxImGui:Show()          self._window.Visible = true end
function RbxImGui:Hide()          self._window.Visible = false end
function RbxImGui:Toggle_Window() self._window.Visible = not self._window.Visible end
function RbxImGui:Destroy()       if self._screenGui then self._screenGui:Destroy() end end

return RbxImGui
