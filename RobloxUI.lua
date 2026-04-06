-- ============================================================
-- RbxImGui | Lightweight ImGui-style UI Library for Roblox
-- ============================================================
local RbxImGui = {}
RbxImGui.__index = RbxImGui

local TabBuilder = {}
TabBuilder.__index = TabBuilder

-- ── Services ──────────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

-- ── Theming ──────────────────────────────────────────────────
local THEME = {
    TitleBarBg        = Color3.fromRGB(20, 20, 26),
    TitleBarText      = Color3.fromRGB(220, 220, 220),
    TabBarBg          = Color3.fromRGB(18, 18, 24),
    TabBg             = Color3.fromRGB(38, 38, 52),
    TabHover          = Color3.fromRGB(55, 55, 75),
    TabActive         = Color3.fromRGB(82, 130, 255),
    TabText           = Color3.fromRGB(170, 170, 195),
    TabTextActive     = Color3.fromRGB(255, 255, 255),
    WindowBg          = Color3.fromRGB(22, 22, 28),
    WindowBorder      = Color3.fromRGB(55, 55, 75),
    ButtonBg          = Color3.fromRGB(48, 48, 64),
    ButtonHover       = Color3.fromRGB(68, 68, 96),
    ButtonActive      = Color3.fromRGB(82, 130, 255),
    ButtonText        = Color3.fromRGB(210, 210, 220),
    ToggleOff         = Color3.fromRGB(55, 55, 70),
    ToggleOn          = Color3.fromRGB(82, 130, 255),
    ToggleKnob        = Color3.fromRGB(240, 240, 255),
    ToggleText        = Color3.fromRGB(200, 200, 215),
    SliderTrack       = Color3.fromRGB(40, 40, 55),
    SliderFill        = Color3.fromRGB(82, 130, 255),
    SliderKnob        = Color3.fromRGB(230, 230, 255),
    SliderText        = Color3.fromRGB(200, 200, 215),
    SliderValue       = Color3.fromRGB(140, 160, 255),
    SeparatorColor    = Color3.fromRGB(50, 50, 68),
    TextColor         = Color3.fromRGB(200, 200, 215),
    ResizeGrip        = Color3.fromRGB(40, 40, 55),
    ResizeGripHover   = Color3.fromRGB(82, 130, 255),
    ScrollThumb       = Color3.fromRGB(80, 80, 110),
    DropdownBg        = Color3.fromRGB(28, 28, 40),
    DropdownBorder    = Color3.fromRGB(60, 60, 90),
    DropdownItemHover = Color3.fromRGB(45, 55, 85),
    DropdownText      = Color3.fromRGB(200, 200, 215),
    DropdownArrow     = Color3.fromRGB(140, 160, 255),
    SwatchBorder      = Color3.fromRGB(65, 65, 95),
}

-- ── Defaults ─────────────────────────────────────────────────
local D = {
    WindowWidth     = 320,
    WindowMinWidth  = 220,
    WindowMinHeight = 140,
    TitleBarHeight  = 30,
    TabBarHeight    = 32,
    Padding         = 10,
    ItemSpacing     = 5,
    ButtonHeight    = 26,
    ToggleHeight    = 24,
    SliderHeight    = 28,
    CornerRadius    = 6,
    FontSize        = 13,
    ResizeGripSize  = 14,
    DropdownRowH    = 46,
    DropdownBtnH    = 26,
    DropdownItemH   = 26,
    DropdownMaxShow = 5,
    ColorRowH       = 24,
}

-- ── Helpers ───────────────────────────────────────────────────
local function tw(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function make(cls, props)
    local o = Instance.new(cls)
    for k, v in pairs(props) do o[k] = v end
    return o
end

local function corner(r, p)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p
end

local function stroke(col, thick, p)
    -- Remove any existing stroke first so we can replace it
    local existing = p:FindFirstChildOfClass("UIStroke")
    if existing then existing:Destroy() end
    local s = Instance.new("UIStroke")
    s.Color = col; s.Thickness = thick
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local FR  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular,  Enum.FontStyle.Normal)
local FSB = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
local FB  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold,     Enum.FontStyle.Normal)

-- ── HSV helpers ───────────────────────────────────────────────
local function hsv2c(h, s, v)
    h = h % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p, q, t2 = v*(1-s), v*(1-f*s), v*(1-(1-f)*s)
    local seg = i % 6
    if seg==0 then return Color3.new(v,t2,p)
    elseif seg==1 then return Color3.new(q,v,p)
    elseif seg==2 then return Color3.new(p,v,t2)
    elseif seg==3 then return Color3.new(p,q,v)
    elseif seg==4 then return Color3.new(t2,p,v)
    else return Color3.new(v,p,q) end
end

local function c2hsv(c)
    local r,g,b = c.R,c.G,c.B
    local mx,mn = math.max(r,g,b), math.min(r,g,b)
    local d = mx-mn
    local h = 0
    local s = mx==0 and 0 or d/mx
    local v = mx
    if d ~= 0 then
        if mx==r then h=(((g-b)/d)%6)/6
        elseif mx==g then h=((b-r)/d+2)/6
        else h=((r-g)/d+4)/6 end
    end
    return h, s, v
end

-- ── Constructor ───────────────────────────────────────────────
function RbxImGui.new(title, parent)
    local self = setmetatable({}, RbxImGui)
    self._title      = title or "Window"
    self._tabs       = {}
    self._tabsByName = {}
    self._activeTab  = nil
    self._rendered   = false

    if not parent then
        local sg = Instance.new("ScreenGui")
        sg.Name = "RbxImGui_" .. self._title
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder = 999
        if not pcall(function() sg.Parent = game:GetService("CoreGui") end) then
            sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end
        parent = sg
    end
    self._screenGui = parent

    -- Window
    self._window = make("Frame", {
        Name             = "ImGuiWindow",
        Size             = UDim2.new(0, D.WindowWidth, 0, 340),
        Position         = UDim2.new(0, 80, 0, 80),
        BackgroundColor3 = THEME.WindowBg,
        BorderSizePixel  = 0,
        ClipsDescendants = false,
        Parent           = parent,
    })
    corner(D.CornerRadius, self._window)
    stroke(THEME.WindowBorder, 1, self._window)

    -- Title bar
    local titleBar = make("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, D.TitleBarHeight),
        BackgroundColor3 = THEME.TitleBarBg,
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = self._window,
    })
    make("TextLabel", {
        Size                 = UDim2.new(1, -12, 1, 0),
        Position             = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text                 = self._title,
        TextColor3           = THEME.TitleBarText,
        TextSize             = D.FontSize + 1,
        FontFace             = FB,
        TextXAlignment       = Enum.TextXAlignment.Left,
        ZIndex               = 2,
        Parent               = titleBar,
    })

    -- Drag
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
    -- FIX: Wrap tab buttons in a horizontal ScrollingFrame with no visible
    -- scrollbar. Tabs will never overflow and get clipped — they just become
    -- scrollable when too many exist for the current window width.
    self._tabBar = make("Frame", {
        Name             = "TabBarOuter",
        Size             = UDim2.new(1, 0, 0, D.TabBarHeight),
        Position         = UDim2.new(0, 0, 0, D.TitleBarHeight),
        BackgroundColor3 = THEME.TabBarBg,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        ZIndex           = 2,
        Parent           = self._window,
    })

    make("Frame", {
        Name             = "TabSep",
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = THEME.WindowBorder,
        BorderSizePixel  = 0,
        ZIndex           = 3,
        Parent           = self._tabBar,
    })

    local tabScroll = make("ScrollingFrame", {
        Name                  = "TabScroll",
        Size                  = UDim2.new(1, 0, 1, -1),
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        ScrollBarThickness    = 0,
        ScrollingDirection    = Enum.ScrollingDirection.X,
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.X,
        ZIndex                = 2,
        Parent                = self._tabBar,
    })

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection     = Enum.FillDirection.Horizontal
    tabLayout.SortOrder         = Enum.SortOrder.LayoutOrder
    tabLayout.Padding           = UDim.new(0, 4)
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.Parent            = tabScroll

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft  = UDim.new(0, 6)
    tabPad.PaddingRight = UDim.new(0, 6)
    tabPad.Parent       = tabScroll

    self._tabInner  = tabScroll
    self._tabLayout = tabLayout

    -- ── Content area ──────────────────────────────────────────
    local contentTop = D.TitleBarHeight + D.TabBarHeight

    local clipFrame = make("Frame", {
        Name                 = "ContentClip",
        Size                 = UDim2.new(1, 0, 1, -(contentTop + D.ResizeGripSize)),
        Position             = UDim2.new(0, 0, 0, contentTop),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ClipsDescendants     = true,
        Parent               = self._window,
    })
    self._clipFrame = clipFrame

    self._contentArea = make("Frame", {
        Name                 = "ContentArea",
        Size                 = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Parent               = clipFrame,
    })

    -- Overlay layer — full ScreenGui size, high ZIndex, NOT inside the window.
    -- Dropdowns render here. Completely unaffected by any clipping or scrolling.
    self._overlayLayer = make("Frame", {
        Name                 = "Overlay",
        Size                 = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ZIndex               = 200,
        Parent               = parent,
    })

    -- Resize grip
    local grip = make("TextButton", {
        Name             = "ResizeGrip",
        Size             = UDim2.new(0, D.ResizeGripSize, 0, D.ResizeGripSize),
        Position         = UDim2.new(1, -D.ResizeGripSize, 1, -D.ResizeGripSize),
        BackgroundColor3 = THEME.ResizeGrip,
        Text             = "",
        BorderSizePixel  = 0,
        ZIndex           = 5,
        Parent           = self._window,
    })
    corner(2, grip)
    for row = 0, 1 do
        for col2 = 0, 1 do
            make("Frame", {
                Size             = UDim2.new(0, 2, 0, 2),
                Position         = UDim2.new(0, 3 + col2*5, 0, 3 + row*5),
                BackgroundColor3 = Color3.fromRGB(120, 130, 170),
                BorderSizePixel  = 0,
                Parent           = grip,
            })
        end
    end
    grip.MouseEnter:Connect(function() tw(grip, {BackgroundColor3 = THEME.ResizeGripHover}) end)
    grip.MouseLeave:Connect(function() tw(grip, {BackgroundColor3 = THEME.ResizeGrip}) end)

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
            local delta = inp.Position - resizeStart
            local nW = math.max(D.WindowMinWidth,  resizeStartSize.X + delta.X)
            local nH = math.max(D.WindowMinHeight, resizeStartSize.Y + delta.Y)
            self._window.Size = UDim2.new(0, nW, 0, nH)
        end
    end)

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
    local btnW = math.max(52, #name * 7 + 18)

    local btn = make("TextButton", {
        Name             = "Tab_" .. name,
        Size             = UDim2.new(0, btnW, 0, 24),
        BackgroundColor3 = THEME.TabBg,
        Text             = name,
        TextColor3       = THEME.TabText,
        TextSize         = D.FontSize - 1,
        FontFace         = FSB,
        BorderSizePixel  = 0,
        LayoutOrder      = tabIndex,
        ZIndex           = 2,
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
        ScrollingEnabled      = true,
        Visible               = false,
        Parent                = self._contentArea,
    })

    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding   = UDim.new(0, D.ItemSpacing)
    ll.Parent    = sf

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, D.Padding)
    pad.PaddingRight  = UDim.new(0, D.Padding + 4)
    pad.PaddingTop    = UDim.new(0, D.Padding)
    pad.PaddingBottom = UDim.new(0, D.Padding)
    pad.Parent        = sf

    local tabData = { name=name, items={}, scrollFrame=sf, tabBtn=btn }
    self._tabs[tabIndex]   = tabData
    self._tabsByName[name] = tabData

    btn.MouseButton1Click:Connect(function() self:_switchTab(name) end)
    btn.MouseEnter:Connect(function()
        if self._activeTab ~= name then tw(btn, {BackgroundColor3 = THEME.TabHover}) end
    end)
    btn.MouseLeave:Connect(function()
        if self._activeTab ~= name then tw(btn, {BackgroundColor3 = THEME.TabBg}) end
    end)

    if tabIndex == 1 then self:_switchTab(name) end
    return self
end

function RbxImGui:_switchTab(name)
    self._activeTab = name
    for _, td in ipairs(self._tabs) do
        local active = td.name == name
        td.scrollFrame.Visible = active
        tw(td.tabBtn, {
            BackgroundColor3 = active and THEME.TabActive or THEME.TabBg,
            TextColor3       = active and THEME.TabTextActive or THEME.TabText,
        })
    end
end

function RbxImGui:Tab(name)
    assert(self._tabsByName[name], "Tab '"..tostring(name).."' not found. Call :AddTab() first.")
    local b = setmetatable({}, TabBuilder)
    b._tabData      = self._tabsByName[name]
    b._overlayLayer = self._overlayLayer
    return b
end

-- ── Widgets ───────────────────────────────────────────────────

local function addLabel(td, text)
    table.insert(td.items, function(parent, order)
        make("TextLabel", {
            Name                 = "Lbl_"..order,
            Size                 = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text                 = text,
            TextColor3           = THEME.TextColor,
            TextSize             = D.FontSize,
            FontFace             = FR,
            TextXAlignment       = Enum.TextXAlignment.Left,
            LayoutOrder          = order,
            Parent               = parent,
        })
    end)
end

local function addSeparator(td)
    table.insert(td.items, function(parent, order)
        make("Frame", {
            Name             = "Sep_"..order,
            Size             = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = THEME.SeparatorColor,
            BorderSizePixel  = 0,
            LayoutOrder      = order,
            Parent           = parent,
        })
    end)
end

local function addButton(td, label, cb)
    table.insert(td.items, function(parent, order)
        local btn = make("TextButton", {
            Name             = "Btn_"..order,
            Size             = UDim2.new(1, 0, 0, D.ButtonHeight),
            BackgroundColor3 = THEME.ButtonBg,
            Text             = label,
            TextColor3       = THEME.ButtonText,
            TextSize         = D.FontSize,
            FontFace         = FSB,
            BorderSizePixel  = 0,
            LayoutOrder      = order,
            Parent           = parent,
        })
        corner(D.CornerRadius - 2, btn)
        stroke(Color3.fromRGB(60, 60, 88), 1, btn)
        btn.MouseEnter:Connect(function() tw(btn, {BackgroundColor3 = THEME.ButtonHover}) end)
        btn.MouseLeave:Connect(function() tw(btn, {BackgroundColor3 = THEME.ButtonBg}) end)
        btn.MouseButton1Down:Connect(function() tw(btn, {BackgroundColor3 = THEME.ButtonActive}, 0.07) end)
        btn.MouseButton1Up:Connect(function()
            tw(btn, {BackgroundColor3 = THEME.ButtonHover}, 0.07)
            if cb then cb() end
        end)
    end)
end

local function addToggle(td, label, default, cb)
    local state = default or false
    table.insert(td.items, function(parent, order)
        local row = make("Frame", {
            Name                 = "Toggle_"..order,
            Size                 = UDim2.new(1, 0, 0, D.ToggleHeight),
            BackgroundTransparency = 1,
            LayoutOrder          = order,
            Parent               = parent,
        })
        make("TextLabel", {
            Size                 = UDim2.new(1, -50, 1, 0),
            BackgroundTransparency = 1,
            Text                 = label,
            TextColor3           = THEME.ToggleText,
            TextSize             = D.FontSize,
            FontFace             = FR,
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
            tw(track, {BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff})
            tw(knob, {Position = state and UDim2.new(0, tW-kS-2, 0.5, -kS/2) or UDim2.new(0, 2, 0.5, -kS/2)})
            if cb then cb(state) end
        end)
    end)
end

local function addSlider(td, label, mn, mx, default, cb)
    mn = mn or 0; mx = mx or 100; default = default or mn
    local value = math.clamp(default, mn, mx)
    table.insert(td.items, function(parent, order)
        local totalH = 16 + 4 + D.SliderHeight
        local col = make("Frame", {
            Name                 = "Slider_"..order,
            Size                 = UDim2.new(1, 0, 0, totalH),
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
            Size                 = UDim2.new(0.65, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                 = label,
            TextColor3           = THEME.SliderText,
            TextSize             = D.FontSize,
            FontFace             = FR,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Parent               = hdr,
        })
        local valLbl = make("TextLabel", {
            Size                 = UDim2.new(0.35, 0, 1, 0),
            Position             = UDim2.new(0.65, 0, 0, 0),
            BackgroundTransparency = 1,
            Text                 = tostring(math.floor(value)),
            TextColor3           = THEME.SliderValue,
            TextSize             = D.FontSize,
            FontFace             = FB,
            TextXAlignment       = Enum.TextXAlignment.Right,
            Parent               = hdr,
        })
        local trkH = 5
        local track = make("Frame", {
            Size             = UDim2.new(1, 0, 0, trkH),
            Position         = UDim2.new(0, 0, 0, 16 + 4 + (D.SliderHeight - trkH)/2),
            BackgroundColor3 = THEME.SliderTrack,
            BorderSizePixel  = 0,
            Parent           = col,
        })
        corner(trkH/2, track)
        local pct = (value - mn) / (mx - mn)
        local fill = make("Frame", {
            Size             = UDim2.new(pct, 0, 1, 0),
            BackgroundColor3 = THEME.SliderFill,
            BorderSizePixel  = 0,
            Parent           = track,
        })
        corner(trkH/2, fill)
        local kS = 12
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
            Size                 = UDim2.new(1, 0, 0, D.SliderHeight + 4),
            Position             = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            Text                 = "",
            ZIndex               = 3,
            Parent               = col,
        })
        local function update(x)
            local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value = mn + p * (mx - mn)
            valLbl.Text   = tostring(math.floor(value))
            fill.Size     = UDim2.new(p, 0, 1, 0)
            knob.Position = UDim2.new(p, -kS/2, 0.5, -kS/2)
            if cb then cb(math.floor(value)) end
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

-- ── DROPDOWN ──────────────────────────────────────────────────
-- Menu lives in overlayLayer (child of ScreenGui, ZIndex 200+).
-- FIX: A RenderStepped connection updates the menu position every frame
-- while it is open, tracking the button's AbsolutePosition. This keeps it
-- pinned even when the user scrolls the tab's ScrollingFrame.
local function addDropdown(td, overlayLayer, label, options, cb)
    options = options or {}
    local selIdx    = 1
    local isOpen    = false
    local menuFrame = nil
    local trackConn = nil

    table.insert(td.items, function(parent, order)
        local row = make("Frame", {
            Name                 = "DD_"..order,
            Size                 = UDim2.new(1, 0, 0, D.DropdownRowH),
            BackgroundTransparency = 1,
            LayoutOrder          = order,
            Parent               = parent,
        })

        make("TextLabel", {
            Size                 = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text                 = label,
            TextColor3           = THEME.DropdownText,
            TextSize             = D.FontSize,
            FontFace             = FR,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Parent               = row,
        })

        local btn = make("TextButton", {
            Name             = "DDBtn",
            Size             = UDim2.new(1, 0, 0, D.DropdownBtnH),
            Position         = UDim2.new(0, 0, 0, 20),
            BackgroundColor3 = THEME.DropdownBg,
            Text             = "",
            BorderSizePixel  = 0,
            Parent           = row,
        })
        corner(4, btn)
        stroke(THEME.DropdownBorder, 1, btn)

        local selLbl = make("TextLabel", {
            Size                 = UDim2.new(1, -28, 1, 0),
            Position             = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text                 = options[selIdx] or "Select...",
            TextColor3           = THEME.DropdownText,
            TextSize             = D.FontSize,
            FontFace             = FSB,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Parent               = btn,
        })

        local arrow = make("TextLabel", {
            Size                 = UDim2.new(0, 20, 1, 0),
            Position             = UDim2.new(1, -22, 0, 0),
            BackgroundTransparency = 1,
            Text                 = "▾",
            TextColor3           = THEME.DropdownArrow,
            TextSize             = D.FontSize + 5,
            FontFace             = FB,
            TextXAlignment       = Enum.TextXAlignment.Center,
            TextYAlignment       = Enum.TextYAlignment.Center,
            Parent               = btn,
        })

        local function closeMenu()
            if trackConn then trackConn:Disconnect(); trackConn = nil end
            if menuFrame then menuFrame:Destroy(); menuFrame = nil end
            tw(arrow, {Rotation = 0})
            isOpen = false
        end

        local function openMenu()
            if menuFrame then closeMenu(); return end
            isOpen = true
            tw(arrow, {Rotation = 180})

            local itemH    = D.DropdownItemH
            local visCount = math.min(#options, D.DropdownMaxShow)
            local menuH    = visCount * itemH + 4

            local function computePos()
                local ap = btn.AbsolutePosition
                local as = btn.AbsoluteSize
                return UDim2.new(0, ap.X, 0, ap.Y + as.Y + 2),
                       UDim2.new(0, as.X, 0, menuH)
            end

            local initPos, initSz = computePos()
            menuFrame = make("Frame", {
                Name             = "DDMenu",
                Size             = initSz,
                Position         = initPos,
                BackgroundColor3 = THEME.DropdownBg,
                BorderSizePixel  = 0,
                ZIndex           = 210,
                ClipsDescendants = true,
                Parent           = overlayLayer,
            })
            corner(4, menuFrame)
            stroke(THEME.DropdownBorder, 1, menuFrame)

            -- FIX: track button position every frame so menu follows scrolling
            trackConn = RunService.RenderStepped:Connect(function()
                if menuFrame and menuFrame.Parent then
                    local p, sz = computePos()
                    menuFrame.Position = p
                    menuFrame.Size     = sz
                else
                    if trackConn then trackConn:Disconnect(); trackConn = nil end
                end
            end)

            local msf = make("ScrollingFrame", {
                Size                  = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel       = 0,
                ScrollBarThickness    = 3,
                ScrollBarImageColor3  = THEME.ScrollThumb,
                CanvasSize            = UDim2.new(0, 0, 0, #options * itemH),
                ZIndex                = 211,
                Parent                = menuFrame,
            })
            local mll = Instance.new("UIListLayout")
            mll.SortOrder = Enum.SortOrder.LayoutOrder
            mll.Parent    = msf

            for i, opt in ipairs(options) do
                local isSel = i == selIdx
                local item  = make("TextButton", {
                    Name             = "Item_"..i,
                    Size             = UDim2.new(1, 0, 0, itemH),
                    BackgroundColor3 = isSel and THEME.DropdownItemHover or THEME.DropdownBg,
                    Text             = opt,
                    TextColor3       = THEME.DropdownText,
                    TextSize         = D.FontSize,
                    FontFace         = isSel and FSB or FR,
                    BorderSizePixel  = 0,
                    LayoutOrder      = i,
                    ZIndex           = 212,
                    Parent           = msf,
                })
                local ip = Instance.new("UIPadding")
                ip.PaddingLeft = UDim.new(0, 10); ip.Parent = item

                item.MouseEnter:Connect(function()
                    if i ~= selIdx then tw(item, {BackgroundColor3 = THEME.DropdownItemHover}) end
                end)
                item.MouseLeave:Connect(function()
                    if i ~= selIdx then tw(item, {BackgroundColor3 = THEME.DropdownBg}) end
                end)
                item.MouseButton1Click:Connect(function()
                    selIdx      = i
                    selLbl.Text = opt
                    closeMenu()
                    if cb then cb(opt, i) end
                end)
            end

            local closeConn
            closeConn = UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                local mx2, my2 = inp.Position.X, inp.Position.Y
                local function inside(frame)
                    if not frame or not frame.Parent then return false end
                    local ap = frame.AbsolutePosition
                    local as = frame.AbsoluteSize
                    return mx2 >= ap.X and mx2 <= ap.X+as.X and my2 >= ap.Y and my2 <= ap.Y+as.Y
                end
                if not inside(menuFrame) and not inside(btn) then
                    closeMenu()
                    closeConn:Disconnect()
                end
            end)
        end

        btn.MouseButton1Click:Connect(function()
            if isOpen then closeMenu() else openMenu() end
        end)
        btn.MouseEnter:Connect(function()
            if not isOpen then tw(btn, {BackgroundColor3 = Color3.fromRGB(36, 36, 52)}) end
        end)
        btn.MouseLeave:Connect(function()
            if not isOpen then tw(btn, {BackgroundColor3 = THEME.DropdownBg}) end
        end)
    end)
end

-- ── COLOR PICKER ──────────────────────────────────────────────
-- Collapsed: a single row identical in height to a Toggle.
-- Label on left, colored swatch box on right (like a toggle switch visual).
-- Click swatch/row to expand the full HSV picker inline in the scroll frame.
-- No overlay — the picker just grows the widget row in place.
local function addColorPicker(td, label, defaultColor, cb)
    defaultColor = defaultColor or Color3.fromRGB(255, 100, 100)
    local h, s, v = c2hsv(defaultColor)
    local isExpanded = false

    table.insert(td.items, function(parent, order)
        local SWATCH_W  = 28
        local SWATCH_H  = 16
        local PICKER_H  = 110
        local HUE_H     = 12
        local EXPANDED_EXTRA = 6 + PICKER_H + 6 + HUE_H + 4

        -- Outer container — height tweens to grow/shrink
        local col = make("Frame", {
            Name                 = "CP_"..order,
            Size                 = UDim2.new(1, 0, 0, D.ColorRowH),
            BackgroundTransparency = 1,
            ClipsDescendants     = true,
            LayoutOrder          = order,
            Parent               = parent,
        })

        -- Header row (always visible)
        local hrow = make("Frame", {
            Size                 = UDim2.new(1, 0, 0, D.ColorRowH),
            BackgroundTransparency = 1,
            Parent               = col,
        })

        make("TextLabel", {
            Size                 = UDim2.new(1, -(SWATCH_W + 10), 1, 0),
            BackgroundTransparency = 1,
            Text                 = label,
            TextColor3           = THEME.ToggleText,
            TextSize             = D.FontSize,
            FontFace             = FR,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Parent               = hrow,
        })

        -- Swatch — shows current color, same right-aligned style as toggle
        local swatch = make("Frame", {
            Size             = UDim2.new(0, SWATCH_W, 0, SWATCH_H),
            Position         = UDim2.new(1, -SWATCH_W, 0.5, -SWATCH_H/2),
            BackgroundColor3 = hsv2c(h, s, v),
            BorderSizePixel  = 0,
            Parent           = hrow,
        })
        corner(4, swatch)
        stroke(THEME.SwatchBorder, 1, swatch)

        local hBtn = make("TextButton", {
            Size                 = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                 = "",
            Parent               = hrow,
        })

        -- Picker area (revealed when expanded)
        local pickerArea = make("Frame", {
            Size                 = UDim2.new(1, 0, 0, EXPANDED_EXTRA),
            Position             = UDim2.new(0, 0, 0, D.ColorRowH + 4),
            BackgroundTransparency = 1,
            Parent               = col,
        })

        -- SV area
        local svArea = make("Frame", {
            Size             = UDim2.new(1, 0, 0, PICKER_H),
            BackgroundColor3 = hsv2c(h, 1, 1),
            BorderSizePixel  = 0,
            ClipsDescendants = true,
            Parent           = pickerArea,
        })
        corner(4, svArea)

        local wGrad = make("Frame", {
            Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Parent = svArea
        })
        local wGI = Instance.new("UIGradient")
        wGI.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
        wGI.Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1))
        wGI.Parent = wGrad

        local bGrad = make("Frame", {
            Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(0,0,0), BorderSizePixel = 0, Parent = svArea
        })
        local bGI = Instance.new("UIGradient")
        bGI.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)})
        bGI.Rotation = 90
        bGI.Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0))
        bGI.Parent = bGrad

        local svCursor = make("Frame", {
            Size = UDim2.new(0,10,0,10), Position = UDim2.new(s,-5,1-v,-5),
            BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 3, Parent = svArea
        })
        corner(5, svCursor); stroke(Color3.new(0,0,0), 1, svCursor)

        -- Hue bar
        local hueBar = make("Frame", {
            Size             = UDim2.new(1, 0, 0, HUE_H),
            Position         = UDim2.new(0, 0, 0, PICKER_H + 6),
            BackgroundColor3 = Color3.new(1,1,1),
            BorderSizePixel  = 0,
            ClipsDescendants = true,
            Parent           = pickerArea,
        })
        corner(4, hueBar)
        local hKps = {}
        for i = 0, 6 do hKps[i+1] = ColorSequenceKeypoint.new(i/6, hsv2c(i/6, 1, 1)) end
        local hGrad = Instance.new("UIGradient")
        hGrad.Color = ColorSequence.new(hKps); hGrad.Parent = hueBar

        local hueCursor = make("Frame", {
            Size = UDim2.new(0,3,1,4), Position = UDim2.new(h,-1,0,-2),
            BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 3, Parent = hueBar
        })
        corner(2, hueCursor); stroke(Color3.new(0,0,0), 1, hueCursor)

        -- Apply
        local function applyColor()
            local c = hsv2c(h, s, v)
            swatch.BackgroundColor3 = c
            svArea.BackgroundColor3 = hsv2c(h, 1, 1)
            if cb then cb(c) end
        end

        -- Expand/collapse
        local function setExpanded(open)
            isExpanded = open
            local targetH = D.ColorRowH + (open and (4 + EXPANDED_EXTRA) or 0)
            tw(col, {Size = UDim2.new(1, 0, 0, targetH)}, 0.15)
        end
        hBtn.MouseButton1Click:Connect(function() setExpanded(not isExpanded) end)

        -- SV drag
        local svBtn = make("TextButton", {
            Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 4, Parent = svArea
        })
        local svDrag = false
        local function updateSV(x, y)
            local ap = svArea.AbsolutePosition; local as = svArea.AbsoluteSize
            s = math.clamp((x-ap.X)/as.X, 0, 1)
            v = math.clamp(1-(y-ap.Y)/as.Y, 0, 1)
            svCursor.Position = UDim2.new(s,-5,1-v,-5); applyColor()
        end
        svBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDrag=true; updateSV(inp.Position.X, inp.Position.Y) end
        end)
        svBtn.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDrag=false end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if svDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then updateSV(inp.Position.X, inp.Position.Y) end
        end)

        -- Hue drag
        local hueBtn = make("TextButton", {
            Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 4, Parent = hueBar
        })
        local hueDrag = false
        local function updateHue(x)
            local ap = hueBar.AbsolutePosition; local as = hueBar.AbsoluteSize
            h = math.clamp((x-ap.X)/as.X, 0, 1)
            hueCursor.Position = UDim2.new(h,-1,0,-2); applyColor()
        end
        hueBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag=true; updateHue(inp.Position.X) end
        end)
        hueBtn.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag=false end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if hueDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then updateHue(inp.Position.X) end
        end)
    end)
end

-- ── TabBuilder API ────────────────────────────────────────────
function TabBuilder:Label(t)              addLabel(self._tabData, t);                                   return self end
function TabBuilder:Separator()           addSeparator(self._tabData);                                  return self end
function TabBuilder:Button(l,cb)          addButton(self._tabData, l, cb);                              return self end
function TabBuilder:Toggle(l,d,cb)        addToggle(self._tabData, l, d, cb);                           return self end
function TabBuilder:Slider(l,mn,mx,d,cb)  addSlider(self._tabData, l, mn, mx, d, cb);                  return self end
function TabBuilder:Dropdown(l,opts,cb)   addDropdown(self._tabData, self._overlayLayer, l, opts, cb);  return self end
function TabBuilder:ColorPicker(l,def,cb) addColorPicker(self._tabData, l, def, cb);                    return self end

-- ── No-tab proxy ──────────────────────────────────────────────
local function ensureDefault(self)
    if not self._tabsByName["__default"] then
        self:AddTab("__default")
        self._tabsByName["__default"].tabBtn.Visible = false
        self._tabBar.Visible = false
        self._clipFrame.Position = UDim2.new(0, 0, 0, D.TitleBarHeight)
        self._clipFrame.Size     = UDim2.new(1, 0, 1, -(D.TitleBarHeight + D.ResizeGripSize))
    end
    return self._tabsByName["__default"]
end
function RbxImGui:Label(t)               addLabel(ensureDefault(self), t);                                              return self end
function RbxImGui:Separator()            addSeparator(ensureDefault(self));                                             return self end
function RbxImGui:Button(l,cb)           addButton(ensureDefault(self), l, cb);                                         return self end
function RbxImGui:Toggle(l,d,cb)         addToggle(ensureDefault(self), l, d, cb);                                      return self end
function RbxImGui:Slider(l,mn,mx,d,cb)  addSlider(ensureDefault(self), l, mn, mx, d, cb);                              return self end
function RbxImGui:Dropdown(l,opts,cb)   addDropdown(ensureDefault(self), self._overlayLayer, l, opts, cb);              return self end
function RbxImGui:ColorPicker(l,def,cb) addColorPicker(ensureDefault(self), l, def, cb);                               return self end

-- ── Render & Visibility ───────────────────────────────────────
function RbxImGui:Render()
    for _, td in ipairs(self._tabs) do
        for i, builder in ipairs(td.items) do
            builder(td.scrollFrame, i)
        end
    end
    self._rendered = true
end
function RbxImGui:Show()          self._window.Visible = true end
function RbxImGui:Hide()          self._window.Visible = false end
function RbxImGui:Toggle_Window() self._window.Visible = not self._window.Visible end
function RbxImGui:Destroy()       if self._screenGui then self._screenGui:Destroy() end end

return RbxImGui
