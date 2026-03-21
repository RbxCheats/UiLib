-- ============================================================
-- RbxImGui | Lightweight ImGui-style UI Library for Roblox
--
-- Widgets:
--   :Label(text)
--   :Separator()
--   :Button(label, callback)
--   :Toggle(label, default, callback)
--   :Slider(label, min, max, default, callback)
--   :Dropdown(label, options, default, callback)
--   :ColorPicker(label, defaultColor, callback)
--
-- Usage:
--   local UI = loadstring(game:HttpGet("...raw url..."))()
--   local win = UI.new("My Panel")
--   win:AddTab("Aimbot"):AddTab("Visuals")
--   win:Tab("Aimbot"):Toggle("Silent Aim", false, function(v) end)
--   win:Tab("Aimbot"):Dropdown("Bone", {"Head","Torso"}, "Head", function(v) end)
--   win:Tab("Visuals"):ColorPicker("ESP Color", Color3.fromRGB(255,50,50), function(c) end)
--   win:Render()
-- ============================================================

local RbxImGui = {}
RbxImGui.__index = RbxImGui

local TabBuilder = {}
TabBuilder.__index = TabBuilder

-- ── Services ──────────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ── Theming ───────────────────────────────────────────────────
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
	-- Dropdown
	DropdownBg      = Color3.fromRGB(32,  32,  44),
	DropdownBorder  = Color3.fromRGB(65,  65,  95),
	DropdownHover   = Color3.fromRGB(48,  48,  68),
	DropdownItemSel = Color3.fromRGB(82,  130, 255),
	DropdownText    = Color3.fromRGB(210, 210, 225),
	DropdownArrow   = Color3.fromRGB(140, 160, 255),
	-- ColorPicker
	PickerBg        = Color3.fromRGB(24,  24,  34),
	PickerBorder    = Color3.fromRGB(65,  65,  95),
}

-- ── Defaults ──────────────────────────────────────────────────
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
	-- Dropdown (label 14px + gap 2px + header 28px = 44px total row)
	DropdownRowH    = 44,
	DropdownHeaderH = 28,
	DropdownItemH   = 28,
	-- ColorPicker
	ColorRowH       = 28,
}

-- ── Helpers ───────────────────────────────────────────────────
local function tw(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function make(cls, props)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	return o
end

local function corner(r, p)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = p
end

local function stroke(col, th, p)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = th
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
end

local FONT_REG  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular,  Enum.FontStyle.Normal)
local FONT_SEMI = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
local FONT_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold,     Enum.FontStyle.Normal)

-- ════════════════════════════════════════════════════════════════
--  CONSTRUCTOR
-- ════════════════════════════════════════════════════════════════
function RbxImGui.new(title, parent)
	local self       = setmetatable({}, RbxImGui)
	self._title      = title or "Window"
	self._tabs       = {}
	self._tabsByName = {}
	self._activeTab  = nil
	self._rendered   = false

	-- ScreenGui
	if not parent then
		local sg = Instance.new("ScreenGui")
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

	-- Outer window — ClipsDescendants OFF so nothing clips inside.
	-- A separate clip frame handles visual clipping.
	self._window = make("Frame", {
		Name             = "ImGuiWindow",
		Size             = UDim2.new(0, DEFAULTS.WindowWidth, 0, 340),
		Position         = UDim2.new(0, 80, 0, 80),
		BackgroundColor3 = THEME.WindowBg,
		BorderSizePixel  = 0,
		ClipsDescendants = false,
		Parent           = parent,
	})
	corner(DEFAULTS.CornerRadius, self._window)
	stroke(THEME.WindowBorder, 1, self._window)

	-- Inner clip frame — same size as window, clips all UI content
	self._clipFrame = make("Frame", {
		Name                 = "ClipFrame",
		Size                 = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		ClipsDescendants     = true,
		Parent               = self._window,
	})

	-- Title bar
	local titleBar = make("Frame", {
		Name             = "TitleBar",
		Size             = UDim2.new(1, 0, 0, DEFAULTS.TitleBarHeight),
		BackgroundColor3 = THEME.TitleBarBg,
		BorderSizePixel  = 0,
		Parent           = self._clipFrame,
	})
	make("TextLabel", {
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
			self._window.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

	-- Tab bar
	self._tabBar = make("Frame", {
		Name             = "TabBar",
		Size             = UDim2.new(1, 0, 0, DEFAULTS.TabBarHeight),
		Position         = UDim2.new(0, 0, 0, DEFAULTS.TitleBarHeight),
		BackgroundColor3 = THEME.TabBarBg,
		BorderSizePixel  = 0,
		Parent           = self._clipFrame,
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
	self._tabInner = tabInner

	-- Content area — clips scrolling content, does NOT clip floating menus
	local contentTop = DEFAULTS.TitleBarHeight + DEFAULTS.TabBarHeight
	self._contentArea = make("Frame", {
		Name                 = "ContentArea",
		Size                 = UDim2.new(1, 0, 1, -(contentTop + DEFAULTS.ResizeGripSize)),
		Position             = UDim2.new(0, 0, 0, contentTop),
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		ClipsDescendants     = true,
		Parent               = self._clipFrame,
	})

	-- Resize grip
	local grip = make("TextButton", {
		Name             = "ResizeGrip",
		Size             = UDim2.new(0, DEFAULTS.ResizeGripSize, 0, DEFAULTS.ResizeGripSize),
		Position         = UDim2.new(1, -DEFAULTS.ResizeGripSize, 1, -DEFAULTS.ResizeGripSize),
		BackgroundColor3 = THEME.ResizeGrip,
		Text             = "",
		BorderSizePixel  = 0,
		ZIndex           = 5,
		Parent           = self._clipFrame,
	})
	corner(2, grip)
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
			local d = inp.Position - resizeStart
			self._window.Size = UDim2.new(
				0, math.max(DEFAULTS.WindowMinWidth,  resizeStartSize.X + d.X),
				0, math.max(DEFAULTS.WindowMinHeight, resizeStartSize.Y + d.Y))
		end
	end)

	-- Insert key
	UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == Enum.KeyCode.Insert then
			self._window.Visible = not self._window.Visible
		end
	end)

	return self
end

-- ════════════════════════════════════════════════════════════════
--  TAB MANAGEMENT
-- ════════════════════════════════════════════════════════════════
function RbxImGui:AddTab(name)
	local idx = #self._tabs + 1

	local btn = make("TextButton", {
		Name             = "Tab_" .. name,
		Size             = UDim2.new(0, math.max(DEFAULTS.TabMinWidth, #name * 8 + 20), 0, 22),
		BackgroundColor3 = THEME.TabBg,
		Text             = name,
		TextColor3       = THEME.TabText,
		TextSize         = DEFAULTS.FontSize - 1,
		FontFace         = FONT_SEMI,
		BorderSizePixel  = 0,
		LayoutOrder      = idx,
		Parent           = self._tabInner,
	})
	corner(4, btn)

	local sf = make("ScrollingFrame", {
		Name                 = "TabContent_" .. name,
		Size                 = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		ScrollBarThickness   = 4,
		ScrollBarImageColor3 = THEME.ScrollThumb,
		CanvasSize           = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize  = Enum.AutomaticSize.Y,
		Visible              = false,
		Parent               = self._contentArea,
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
	pad.Parent = sf

	local td = { name = name, items = {}, scrollFrame = sf, tabBtn = btn }
	self._tabs[idx]        = td
	self._tabsByName[name] = td

	btn.MouseButton1Click:Connect(function() self:_switchTab(name) end)
	btn.MouseEnter:Connect(function()
		if self._activeTab ~= name then tw(btn, {BackgroundColor3 = THEME.TabHover}) end
	end)
	btn.MouseLeave:Connect(function()
		if self._activeTab ~= name then tw(btn, {BackgroundColor3 = THEME.TabBg}) end
	end)
	if idx == 1 then self:_switchTab(name) end
	return self
end

function RbxImGui:_switchTab(name)
	self._activeTab = name
	for _, td in ipairs(self._tabs) do
		local a = (td.name == name)
		td.scrollFrame.Visible = a
		tw(td.tabBtn, {
			BackgroundColor3 = a and THEME.TabActive or THEME.TabBg,
			TextColor3       = a and THEME.TabTextActive or THEME.TabText,
		})
	end
end

function RbxImGui:Tab(name)
	assert(self._tabsByName[name], "Tab '" .. tostring(name) .. "' not found. Call AddTab first.")
	local b = setmetatable({}, TabBuilder)
	b._tabData   = self._tabsByName[name]
	b._screenGui = self._screenGui
	return b
end

-- ════════════════════════════════════════════════════════════════
--  WIDGET IMPLEMENTATIONS
-- ════════════════════════════════════════════════════════════════

-- ── Label ─────────────────────────────────────────────────────
local function addLabel(td, text)
	table.insert(td.items, function(parent, order)
		make("TextLabel", {
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

-- ── Separator ─────────────────────────────────────────────────
local function addSeparator(td)
	table.insert(td.items, function(parent, order)
		make("Frame", {
			Size             = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = THEME.SeparatorColor,
			BorderSizePixel  = 0,
			LayoutOrder      = order,
			Parent           = parent,
		})
	end)
end

-- ── Button ────────────────────────────────────────────────────
local function addButton(td, label, cb)
	table.insert(td.items, function(parent, order)
		local btn = make("TextButton", {
			Size             = UDim2.new(1, 0, 0, DEFAULTS.ButtonHeight),
			BackgroundColor3 = THEME.ButtonBg,
			Text             = label,
			TextColor3       = THEME.ButtonText,
			TextSize         = DEFAULTS.FontSize,
			FontFace         = FONT_SEMI,
			BorderSizePixel  = 0,
			AutoButtonColor  = false,
			LayoutOrder      = order,
			Parent           = parent,
		})
		corner(DEFAULTS.CornerRadius - 2, btn)
		stroke(Color3.fromRGB(65, 65, 90), 1, btn)
		btn.MouseEnter:Connect(function() tw(btn, {BackgroundColor3 = THEME.ButtonHover}) end)
		btn.MouseLeave:Connect(function() tw(btn, {BackgroundColor3 = THEME.ButtonBg}) end)
		btn.MouseButton1Down:Connect(function() tw(btn, {BackgroundColor3 = THEME.ButtonActive}, 0.07) end)
		btn.MouseButton1Up:Connect(function()
			tw(btn, {BackgroundColor3 = THEME.ButtonHover}, 0.07)
			if cb then cb() end
		end)
	end)
end

-- ── Toggle ────────────────────────────────────────────────────
local function addToggle(td, label, default, cb)
	local state = default or false
	table.insert(td.items, function(parent, order)
		local row = make("Frame", {
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
		local kS   = tH - 4
		local knob = make("Frame", {
			Size             = UDim2.new(0, kS, 0, kS),
			Position         = state
				and UDim2.new(0, tW - kS - 2, 0.5, -kS/2)
				or  UDim2.new(0, 2,            0.5, -kS/2),
			BackgroundColor3 = THEME.ToggleKnob,
			BorderSizePixel  = 0,
			Parent           = track,
		})
		corner(kS/2, knob)
		local click = make("TextButton", {
			Size                 = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text                 = "",
			AutoButtonColor      = false,
			Parent               = row,
		})
		click.MouseButton1Click:Connect(function()
			state = not state
			tw(track, {BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff})
			tw(knob,  {Position = state
				and UDim2.new(0, tW - kS - 2, 0.5, -kS/2)
				or  UDim2.new(0, 2,            0.5, -kS/2)})
			if cb then cb(state) end
		end)
	end)
end

-- ── Slider ────────────────────────────────────────────────────
local function addSlider(td, label, min, max, default, cb)
	min     = min     or 0
	max     = max     or 100
	default = default or min
	local value = math.clamp(default, min, max)
	table.insert(td.items, function(parent, order)
		local col = make("Frame", {
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
			Size                 = UDim2.new(1, 0, 0, DEFAULTS.SliderHeight),
			Position             = UDim2.new(0, 0, 0, 14),
			BackgroundTransparency = 1,
			Text                 = "",
			ZIndex               = 3,
			AutoButtonColor      = false,
			Parent               = col,
		})
		local function upd(x)
			local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			value = min + p * (max - min)
			valLbl.Text   = tostring(math.floor(value))
			fill.Size     = UDim2.new(p, 0, 1, 0)
			knob.Position = UDim2.new(p, -kS/2, 0.5, -kS/2)
			if cb then cb(math.floor(value)) end
		end
		local sliding = false
		drag.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; upd(inp.Position.X) end
		end)
		drag.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then upd(inp.Position.X) end
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════
--  DROPDOWN  (v2)
--
--  The scroll frame container is a fixed height (label + header).
--  The floating menu is parented directly to the ScreenGui at
--  ZIndex 50 so it is never clipped by ANY scroll frame or window
--  frame and always renders on top of everything else.
--  It is positioned by reading the header's AbsolutePosition the
--  moment the user opens it.
-- ════════════════════════════════════════════════════════════════
local function addDropdown(td, screenGui, label, options, default, cb)
	assert(type(options) == "table" and #options > 0, "Dropdown: options must be a non-empty table")
	local selected = default or options[1]

	table.insert(td.items, function(parent, order)
		local ROW_H = DEFAULTS.DropdownRowH    -- 44
		local HDR_H = DEFAULTS.DropdownHeaderH -- 28
		local ITM_H = DEFAULTS.DropdownItemH   -- 28

		-- Container — fixed height, no clipping
		local container = make("Frame", {
			Name                 = "Dropdown_" .. order,
			Size                 = UDim2.new(1, 0, 0, ROW_H),
			BackgroundTransparency = 1,
			ClipsDescendants     = false,
			LayoutOrder          = order,
			Parent               = parent,
		})

		-- Small label above the box
		make("TextLabel", {
			Size                 = UDim2.new(1, 0, 0, 14),
			Position             = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text                 = label,
			TextColor3           = THEME.ToggleText,
			TextSize             = DEFAULTS.FontSize - 1,
			FontFace             = FONT_REG,
			TextXAlignment       = Enum.TextXAlignment.Left,
			Parent               = container,
		})

		-- Header button
		local header = make("TextButton", {
			Name             = "Header",
			Size             = UDim2.new(1, 0, 0, HDR_H),
			Position         = UDim2.new(0, 0, 0, 16),
			BackgroundColor3 = THEME.DropdownBg,
			Text             = "",
			BorderSizePixel  = 0,
			AutoButtonColor  = false,
			Parent           = container,
		})
		corner(4, header)
		stroke(THEME.DropdownBorder, 1, header)

		-- Selected text inside header
		local selLabel = make("TextLabel", {
			Size                 = UDim2.new(1, -34, 1, 0),
			Position             = UDim2.new(0, 10, 0, 0),
			BackgroundTransparency = 1,
			Text                 = selected,
			TextColor3           = THEME.DropdownText,
			TextSize             = DEFAULTS.FontSize,
			FontFace             = FONT_SEMI,
			TextXAlignment       = Enum.TextXAlignment.Left,
			Parent               = header,
		})

		-- Arrow indicator — plain TextLabel, NO background frame
		local arrow = make("TextLabel", {
			Size                 = UDim2.new(0, 24, 1, 0),
			Position             = UDim2.new(1, -26, 0, 0),
			BackgroundTransparency = 1,
			Text                 = "▾",
			TextColor3           = THEME.DropdownArrow,
			TextSize             = DEFAULTS.FontSize,
			FontFace             = FONT_BOLD,
			TextXAlignment       = Enum.TextXAlignment.Center,
			Parent               = header,
		})

		-- ── Floating menu on the ScreenGui ────────────────────────
		local menuH = #options * ITM_H + 8

		local menu = make("Frame", {
			Name             = "FloatingMenu_" .. order,
			Size             = UDim2.new(0, 200, 0, menuH),  -- width set on open
			Position         = UDim2.new(0, 0, 0, 0),        -- position set on open
			BackgroundColor3 = THEME.DropdownBg,
			BorderSizePixel  = 0,
			Visible          = false,
			ZIndex           = 50,
			Parent           = screenGui,
		})
		corner(6, menu)
		stroke(THEME.DropdownBorder, 1, menu)

		local mPad = Instance.new("UIPadding")
		mPad.PaddingTop    = UDim.new(0, 4)
		mPad.PaddingBottom = UDim.new(0, 4)
		mPad.PaddingLeft   = UDim.new(0, 4)
		mPad.PaddingRight  = UDim.new(0, 4)
		mPad.Parent        = menu

		local mLayout = Instance.new("UIListLayout")
		mLayout.SortOrder = Enum.SortOrder.LayoutOrder
		mLayout.Padding   = UDim.new(0, 2)
		mLayout.Parent    = menu

		-- Build option rows
		for i, opt in ipairs(options) do
			local isSel = (opt == selected)
			local item  = make("TextButton", {
				Name             = "Item_" .. i,
				Size             = UDim2.new(1, 0, 0, ITM_H),
				BackgroundColor3 = isSel and THEME.DropdownItemSel or THEME.DropdownBg,
				Text             = "",
				BorderSizePixel  = 0,
				AutoButtonColor  = false,
				LayoutOrder      = i,
				ZIndex           = 51,
				Parent           = menu,
			})
			corner(4, item)

			local itemLbl = make("TextLabel", {
				Size                 = UDim2.new(1, -10, 1, 0),
				Position             = UDim2.new(0, 8, 0, 0),
				BackgroundTransparency = 1,
				Text                 = opt,
				TextColor3           = isSel and Color3.fromRGB(255,255,255) or THEME.DropdownText,
				TextSize             = DEFAULTS.FontSize,
				FontFace             = isSel and FONT_SEMI or FONT_REG,
				TextXAlignment       = Enum.TextXAlignment.Left,
				ZIndex               = 52,
				Parent               = item,
			})

			item.MouseEnter:Connect(function()
				if opt ~= selected then tw(item, {BackgroundColor3 = THEME.DropdownHover}) end
			end)
			item.MouseLeave:Connect(function()
				if opt ~= selected then tw(item, {BackgroundColor3 = THEME.DropdownBg}) end
			end)
			item.MouseButton1Click:Connect(function()
				-- Reset all items
				for _, child in ipairs(menu:GetChildren()) do
					if child:IsA("TextButton") then
						child.BackgroundColor3 = THEME.DropdownBg
						local l = child:FindFirstChildOfClass("TextLabel")
						if l then l.TextColor3 = THEME.DropdownText; l.FontFace = FONT_REG end
					end
				end
				-- Mark selected
				item.BackgroundColor3 = THEME.DropdownItemSel
				itemLbl.TextColor3    = Color3.fromRGB(255, 255, 255)
				itemLbl.FontFace      = FONT_SEMI
				selected              = opt
				selLabel.Text         = opt
				menu.Visible          = false
				arrow.Text            = "▾"
				if cb then cb(opt) end
			end)
		end

		-- Open/close
		local open = false

		local function openMenu()
			local ap = header.AbsolutePosition
			local as = header.AbsoluteSize
			menu.Size     = UDim2.new(0, as.X, 0, menuH)
			menu.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 2)
			menu.Visible  = true
			arrow.Text    = "▴"
			open          = true
		end

		local function closeMenu()
			menu.Visible = false
			arrow.Text   = "▾"
			open         = false
		end

		header.MouseButton1Click:Connect(function()
			if open then closeMenu() else openMenu() end
		end)
		header.MouseEnter:Connect(function() tw(header, {BackgroundColor3 = THEME.DropdownHover}) end)
		header.MouseLeave:Connect(function() tw(header, {BackgroundColor3 = THEME.DropdownBg}) end)

		-- Click-outside to close
		UserInputService.InputBegan:Connect(function(inp)
			if not open then return end
			if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			local mp = inp.Position
			local function inside(f)
				local p, s = f.AbsolutePosition, f.AbsoluteSize
				return mp.X >= p.X and mp.X <= p.X + s.X and mp.Y >= p.Y and mp.Y <= p.Y + s.Y
			end
			if not inside(menu) and not inside(header) then closeMenu() end
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════
--  COLOR PICKER  (v2)
--
--  Row layout:  [Label ............. ■ color swatch]
--  Clicking the swatch opens/closes the picker inline below the row.
--
--  Picker:
--    • SV square — horizontal saturation, vertical value
--      Uses two stacked UIGradient frames: white→transparent (left→right)
--      over transparent→black (top→bottom), on top of the pure-hue base.
--    • Hue bar  — horizontal rainbow bar, 7-stop UIGradient
--    • Preview  — live color strip at the bottom
-- ════════════════════════════════════════════════════════════════
local function addColorPicker(td, label, defaultColor, cb)
	defaultColor = defaultColor or Color3.fromRGB(255, 50, 50)
	local h, s, v = Color3.toHSV(defaultColor)

	table.insert(td.items, function(parent, order)
		local ROW_H  = DEFAULTS.ColorRowH  -- 28

		-- Root — grows when picker opens
		local root = make("Frame", {
			Name                 = "ColorPicker_" .. order,
			Size                 = UDim2.new(1, 0, 0, ROW_H),
			BackgroundTransparency = 1,
			ClipsDescendants     = false,
			LayoutOrder          = order,
			Parent               = parent,
		})

		-- Label (left side)
		make("TextLabel", {
			Size                 = UDim2.new(1, -40, 1, 0),
			Position             = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text                 = label,
			TextColor3           = THEME.ToggleText,
			TextSize             = DEFAULTS.FontSize,
			FontFace             = FONT_REG,
			TextXAlignment       = Enum.TextXAlignment.Left,
			Parent               = root,
		})

		-- Color swatch (right side) — this is the open/close button
		local swatch = make("TextButton", {
			Name             = "Swatch",
			Size             = UDim2.new(0, 30, 0, 20),
			Position         = UDim2.new(1, -30, 0.5, -10),
			BackgroundColor3 = defaultColor,
			Text             = "",
			BorderSizePixel  = 0,
			AutoButtonColor  = false,
			Parent           = root,
		})
		corner(4, swatch)
		stroke(THEME.DropdownBorder, 1, swatch)

		-- ── Picker panel dimensions ───────────────────────────────
		local PAD    = 8
		local SQ_H   = 120   -- SV square height
		local BAR_H  = 16    -- hue bar height
		local PREV_H = 14    -- preview strip height
		local GAP    = 6
		local panelH = PAD + SQ_H + GAP + BAR_H + GAP + PREV_H + PAD

		local panel = make("Frame", {
			Name             = "PickerPanel",
			Size             = UDim2.new(1, 0, 0, panelH),
			Position         = UDim2.new(0, 0, 0, ROW_H + 4),
			BackgroundColor3 = THEME.PickerBg,
			BorderSizePixel  = 0,
			Visible          = false,
			ZIndex           = 8,
			Parent           = root,
		})
		corner(6, panel)
		stroke(THEME.PickerBorder, 1, panel)

		-- ── SV square ─────────────────────────────────────────────
		local sqY = PAD

		-- Base: shows the pure hue color (full saturation, full value)
		local svBase = make("Frame", {
			Name             = "SVBase",
			Size             = UDim2.new(1, -(PAD * 2), 0, SQ_H),
			Position         = UDim2.new(0, PAD, 0, sqY),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			BorderSizePixel  = 0,
			ClipsDescendants = true,
			ZIndex           = 9,
			Parent           = panel,
		})
		corner(4, svBase)

		-- White overlay: left = opaque white, right = fully transparent
		-- This layer makes the left column of the square pure white,
		-- fading to show the base hue on the right.
		local whiteLayer = make("Frame", {
			Size             = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel  = 0,
			ZIndex           = 10,
			Parent           = svBase,
		})
		local wg = Instance.new("UIGradient")
		wg.Rotation    = 0
		wg.Color       = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
		wg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),  -- left: solid white
			NumberSequenceKeypoint.new(1, 1),  -- right: transparent
		})
		wg.Parent = whiteLayer

		-- Black overlay: top = fully transparent, bottom = opaque black
		-- This layer darkens the bottom, simulating the Value axis.
		local blackLayer = make("Frame", {
			Size             = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel  = 0,
			ZIndex           = 11,
			Parent           = svBase,
		})
		local bg = Instance.new("UIGradient")
		bg.Rotation    = 90  -- rotated so it goes top→bottom
		bg.Color       = ColorSequence.new(Color3.fromRGB(0,0,0), Color3.fromRGB(0,0,0))
		bg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),  -- top: transparent
			NumberSequenceKeypoint.new(1, 0),  -- bottom: solid black
		})
		bg.Parent = blackLayer

		-- SV crosshair knob
		local svKnob = make("Frame", {
			Size             = UDim2.new(0, 12, 0, 12),
			Position         = UDim2.new(s, -6, 1 - v, -6),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel  = 0,
			ZIndex           = 13,
			Parent           = svBase,
		})
		corner(6, svKnob)
		stroke(Color3.fromRGB(0, 0, 0), 1.5, svKnob)

		-- Full-area drag capture for SV square
		local svDrag = make("TextButton", {
			Size                 = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text                 = "",
			AutoButtonColor      = false,
			ZIndex               = 14,
			Parent               = svBase,
		})

		-- ── Hue bar ───────────────────────────────────────────────
		local hueY = sqY + SQ_H + GAP

		local hueBar = make("Frame", {
			Name             = "HueBar",
			Size             = UDim2.new(1, -(PAD * 2), 0, BAR_H),
			Position         = UDim2.new(0, PAD, 0, hueY),
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),  -- will be covered by gradient
			BorderSizePixel  = 0,
			ZIndex           = 9,
			Parent           = panel,
		})
		corner(4, hueBar)

		-- Full spectrum gradient — 7 stops for a proper rainbow
		local hg = Instance.new("UIGradient")
		hg.Rotation = 0  -- left → right
		hg.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0/6, Color3.fromRGB(255,   0,   0)),  -- red
			ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255, 255,   0)),  -- yellow
			ColorSequenceKeypoint.new(2/6, Color3.fromRGB(  0, 255,   0)),  -- green
			ColorSequenceKeypoint.new(3/6, Color3.fromRGB(  0, 255, 255)),  -- cyan
			ColorSequenceKeypoint.new(4/6, Color3.fromRGB(  0,   0, 255)),  -- blue
			ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255,   0, 255)),  -- magenta
			ColorSequenceKeypoint.new(6/6, Color3.fromRGB(255,   0,   0)),  -- red (wrap)
		})
		hg.Parent = hueBar

		-- Hue knob — vertical bar that slides horizontally
		local hueKnob = make("Frame", {
			Size             = UDim2.new(0, 4, 1, 4),
			Position         = UDim2.new(h, -2, 0, -2),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel  = 0,
			ZIndex           = 12,
			Parent           = hueBar,
		})
		corner(2, hueKnob)
		stroke(Color3.fromRGB(0, 0, 0), 1, hueKnob)

		local hueDrag = make("TextButton", {
			Size                 = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text                 = "",
			AutoButtonColor      = false,
			ZIndex               = 13,
			Parent               = hueBar,
		})

		-- ── Preview strip ─────────────────────────────────────────
		local prevY = hueY + BAR_H + GAP

		local preview = make("Frame", {
			Name             = "Preview",
			Size             = UDim2.new(1, -(PAD * 2), 0, PREV_H),
			Position         = UDim2.new(0, PAD, 0, prevY),
			BackgroundColor3 = defaultColor,
			BorderSizePixel  = 0,
			ZIndex           = 9,
			Parent           = panel,
		})
		corner(4, preview)
		stroke(THEME.PickerBorder, 1, preview)

		-- ── Shared color update ───────────────────────────────────
		local function applyColor()
			local c = Color3.fromHSV(h, s, v)
			svBase.BackgroundColor3  = Color3.fromHSV(h, 1, 1)  -- update hue tint
			svKnob.Position          = UDim2.new(s, -6, 1 - v, -6)
			hueKnob.Position         = UDim2.new(h, -2, 0, -2)
			swatch.BackgroundColor3  = c
			preview.BackgroundColor3 = c
			if cb then cb(c) end
		end

		-- SV drag
		local svDragging = false
		local function readSV(inp)
			local rx = math.clamp((inp.Position.X - svBase.AbsolutePosition.X) / svBase.AbsoluteSize.X, 0, 1)
			local ry = math.clamp((inp.Position.Y - svBase.AbsolutePosition.Y) / svBase.AbsoluteSize.Y, 0, 1)
			s = rx
			v = 1 - ry
			applyColor()
		end
		svDrag.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = true; readSV(inp) end
		end)
		svDrag.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if svDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then readSV(inp) end
		end)

		-- Hue drag
		local hueDragging = false
		local function readHue(inp)
			h = math.clamp((inp.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
			applyColor()
		end
		hueDrag.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = true; readHue(inp) end
		end)
		hueDrag.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if hueDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then readHue(inp) end
		end)

		-- ── Open / close ─────────────────────────────────────────
		local isOpen    = false
		local closedH   = ROW_H
		local openH     = ROW_H + 4 + panelH + 4

		swatch.MouseButton1Click:Connect(function()
			isOpen        = not isOpen
			panel.Visible = isOpen
			root.Size     = UDim2.new(1, 0, 0, isOpen and openH or closedH)
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════
--  TAB BUILDER BINDINGS
-- ════════════════════════════════════════════════════════════════
function TabBuilder:Label(text)               addLabel(self._tabData, text);                                         return self end
function TabBuilder:Separator()               addSeparator(self._tabData);                                           return self end
function TabBuilder:Button(l, cb)             addButton(self._tabData, l, cb);                                       return self end
function TabBuilder:Toggle(l, d, cb)          addToggle(self._tabData, l, d, cb);                                    return self end
function TabBuilder:Slider(l, mn, mx, d, cb)  addSlider(self._tabData, l, mn, mx, d, cb);                            return self end
function TabBuilder:Dropdown(l, opts, def, cb) addDropdown(self._tabData, self._screenGui, l, opts, def, cb);        return self end
function TabBuilder:ColorPicker(l, col, cb)   addColorPicker(self._tabData, l, col, cb);                             return self end

-- ── No-tab / single-panel proxy ───────────────────────────────
local function ensureDefault(self)
	if not self._tabsByName["__default"] then
		self:AddTab("__default")
		self._tabsByName["__default"].tabBtn.Visible = false
		self._tabBar.Visible = false
		self._contentArea.Position = UDim2.new(0, 0, 0, DEFAULTS.TitleBarHeight)
		self._contentArea.Size     = UDim2.new(1, 0, 1, -(DEFAULTS.TitleBarHeight + DEFAULTS.ResizeGripSize))
	end
	local td = self._tabsByName["__default"]
	td._screenGui = self._screenGui
	return td
end

function RbxImGui:Label(t)               addLabel(ensureDefault(self), t);                                                    return self end
function RbxImGui:Separator()            addSeparator(ensureDefault(self));                                                    return self end
function RbxImGui:Button(l, cb)          addButton(ensureDefault(self), l, cb);                                                return self end
function RbxImGui:Toggle(l, d, cb)       addToggle(ensureDefault(self), l, d, cb);                                             return self end
function RbxImGui:Slider(l, mn, mx, d, cb) addSlider(ensureDefault(self), l, mn, mx, d, cb);                                  return self end
function RbxImGui:Dropdown(l, opts, def, cb) addDropdown(ensureDefault(self), self._screenGui, l, opts, def, cb);             return self end
function RbxImGui:ColorPicker(l, col, cb) addColorPicker(ensureDefault(self), l, col, cb);                                    return self end

-- ── Render ────────────────────────────────────────────────────
function RbxImGui:Render()
	for _, td in ipairs(self._tabs) do
		td._screenGui = self._screenGui   -- ensure every td has the ref
		for i, builder in ipairs(td.items) do
			builder(td.scrollFrame, i)
		end
	end
	self._rendered = true
end

-- ── Visibility controls ───────────────────────────────────────
function RbxImGui:Show()          self._window.Visible = true  end
function RbxImGui:Hide()          self._window.Visible = false end
function RbxImGui:Toggle_Window() self._window.Visible = not self._window.Visible end
function RbxImGui:Destroy()       if self._screenGui then self._screenGui:Destroy() end end

return RbxImGui
