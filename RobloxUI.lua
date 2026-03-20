-- ============================================================
-- RbxImGui | Lightweight ImGui-style UI Library for Roblox
--
-- NEW WIDGETS (v2):
--   :Dropdown(label, options, default, callback)
--   :ColorPicker(label, defaultColor, callback)
--   :ColorPicker(label, defaultColor, callback, requireToggle)
--       requireToggle = true  →  a toggle button gates the picker open/closed
--
-- Usage:
-- local UI = require(path.to.RbxImGui)
-- local win = UI.new("My Panel")
--
-- win:AddTab("Aimbot")
-- win:AddTab("Visuals")
-- win:AddTab("Misc")
--
-- win:Tab("Aimbot"):Dropdown("ESP Mode", {"2D", "3D"}, "2D", function(v) end)
-- win:Tab("Aimbot"):Dropdown("Aim Bone", {"Head", "Torso"}, "Head", function(v) end)
-- win:Tab("Visuals"):ColorPicker("ESP Color", Color3.fromRGB(255,50,50), function(c) end)
-- win:Tab("Visuals"):ColorPicker("FOV Color", Color3.fromRGB(255,255,255), function(c) end, true)
--   ↑ requireToggle=true: color picker only opens when the toggle is ON
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
	-- Dropdown
	DropdownBg      = Color3.fromRGB(38,  38,  52),
	DropdownBorder  = Color3.fromRGB(70,  70,  100),
	DropdownItem    = Color3.fromRGB(38,  38,  52),
	DropdownItemHov = Color3.fromRGB(60,  60,  85),
	DropdownItemSel = Color3.fromRGB(82,  130, 255),
	DropdownText    = Color3.fromRGB(210, 210, 225),
	DropdownArrow   = Color3.fromRGB(140, 160, 255),
	-- ColorPicker
	PickerBg        = Color3.fromRGB(28,  28,  38),
	PickerBorder    = Color3.fromRGB(70,  70,  100),
	PickerKnob      = Color3.fromRGB(255, 255, 255),
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
	ColorPickerH    = 160,   -- height of the expanded picker panel
}

-- ── Services ──────────────────────────────────────────────────
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

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

-- Convert HSV (0-1 each) to Color3
local function hsvToColor3(h, s, v)
	return Color3.fromHSV(h, s, v)
end

-- Returns h,s,v each 0-1
local function color3ToHsv(c)
	return Color3.toHSV(c)
end

local FONT_REG  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular,  Enum.FontStyle.Normal)
local FONT_SEMI = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
local FONT_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold,     Enum.FontStyle.Normal)

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

	self._window = make("Frame", {
		Name               = "ImGuiWindow",
		Size               = UDim2.new(0, DEFAULTS.WindowWidth, 0, 340),
		Position           = UDim2.new(0, 80, 0, 80),
		BackgroundColor3   = THEME.WindowBg,
		BorderSizePixel    = 0,
		ClipsDescendants   = true,
		Parent             = parent,
	})
	corner(DEFAULTS.CornerRadius, self._window)
	stroke(THEME.WindowBorder, 1, self._window)

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

	-- Drag
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
			self._window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
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
	tabLayout.FillDirection      = Enum.FillDirection.Horizontal
	tabLayout.SortOrder          = Enum.SortOrder.LayoutOrder
	tabLayout.Padding            = UDim.new(0, 4)
	tabLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
	tabLayout.Parent             = tabInner
	local tabPad = Instance.new("UIPadding")
	tabPad.PaddingLeft  = UDim.new(0, 6)
	tabPad.PaddingRight = UDim.new(0, 6)
	tabPad.Parent       = tabInner

	self._tabInner  = tabInner
	self._tabLayout = tabLayout

	local contentTop = DEFAULTS.TitleBarHeight + DEFAULTS.TabBarHeight
	self._contentArea = make("Frame", {
		Name                 = "ContentArea",
		Size                 = UDim2.new(1, 0, 1, -(contentTop + DEFAULTS.ResizeGripSize)),
		Position             = UDim2.new(0, 0, 0, contentTop),
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		ClipsDescendants     = true,
		Parent               = self._window,
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
		Visible               = false,
		Parent                = self._contentArea,
	})
	local ll = Instance.new("UIListLayout")
	ll.SortOrder  = Enum.SortOrder.LayoutOrder
	ll.Padding    = UDim.new(0, DEFAULTS.ItemSpacing)
	ll.Parent     = sf
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, DEFAULTS.Padding)
	pad.PaddingRight  = UDim.new(0, DEFAULTS.Padding)
	pad.PaddingTop    = UDim.new(0, DEFAULTS.Padding)
	pad.PaddingBottom = UDim.new(0, DEFAULTS.Padding)
	pad.Parent = sf

	local tabData = { name = name, items = {}, scrollFrame = sf, tabBtn = btn }
	self._tabs[tabIndex]      = tabData
	self._tabsByName[name]    = tabData

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
	builder._tabData = self._tabsByName[name]
	return builder
end

-- ═══════════════════════════════════════════════════════════════
--  WIDGET IMPLEMENTATIONS
-- ═══════════════════════════════════════════════════════════════

-- ── Label ────────────────────────────────────────────────────
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

-- ── Separator ────────────────────────────────────────────────
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

-- ── Button ────────────────────────────────────────────────────
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

-- ── Toggle ───────────────────────────────────────────────────
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

-- ── Slider ───────────────────────────────────────────────────
local function addSlider(tabData, label, min, max, default, callback)
	min     = min     or 0
	max     = max     or 100
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
			Parent               = col,
		})
		local function update(x)
			local p    = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			value      = min + p * (max - min)
			valLbl.Text = tostring(math.floor(value))
			fill.Size   = UDim2.new(p, 0, 1, 0)
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

-- ══════════════════════════════════════════════════════════════
--  NEW WIDGET: Dropdown
--
--  :Dropdown(label, options, default, callback)
--
--  options  = array of strings, e.g. {"2D", "3D"} or {"Head", "Torso"}
--  default  = the initially selected option string (or nil → first item)
--  callback = function(selectedString)
--
--  The dropdown opens downward inside the ScrollingFrame.
--  It raises its ZIndex so it visually overlaps items below it.
-- ══════════════════════════════════════════════════════════════
local function addDropdown(tabData, label, options, default, callback)
	assert(type(options) == "table" and #options > 0, "Dropdown: options must be a non-empty table")
	local selected = default or options[1]

	table.insert(tabData.items, function(parent, order)
		-- Outer container — collapsed height only; expands via the menu frame
		local container = make("Frame", {
			Name                 = "Dropdown_" .. order,
			Size                 = UDim2.new(1, 0, 0, DEFAULTS.DropdownHeight + 6),
			BackgroundTransparency = 1,
			ClipsDescendants     = false,  -- allow menu to overflow below
			LayoutOrder          = order,
			Parent               = parent,
		})

		-- Label above the control
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

		-- The clickable "header" bar showing current selection
		local header = make("TextButton", {
			Name             = "Header",
			Size             = UDim2.new(1, 0, 0, DEFAULTS.DropdownHeight),
			Position         = UDim2.new(0, 0, 0, 16),
			BackgroundColor3 = THEME.DropdownBg,
			Text             = "",
			BorderSizePixel  = 0,
			ZIndex           = 3,
			Parent           = container,
		})
		corner(DEFAULTS.CornerRadius - 2, header)
		stroke(THEME.DropdownBorder, 1, header)

		local selLabel = make("TextLabel", {
			Size                 = UDim2.new(1, -30, 1, 0),
			Position             = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text                 = selected,
			TextColor3           = THEME.DropdownText,
			TextSize             = DEFAULTS.FontSize,
			FontFace             = FONT_SEMI,
			TextXAlignment       = Enum.TextXAlignment.Left,
			ZIndex               = 4,
			Parent               = header,
		})

		-- Arrow indicator (▾ / ▴)
		local arrow = make("TextLabel", {
			Size                 = UDim2.new(0, 22, 1, 0),
			Position             = UDim2.new(1, -24, 0, 0),
			BackgroundTransparency = 1,
			Text                 = "▾",
			TextColor3           = THEME.DropdownArrow,
			TextSize             = DEFAULTS.FontSize + 2,
			FontFace             = FONT_BOLD,
			TextXAlignment       = Enum.TextXAlignment.Center,
			ZIndex               = 4,
			Parent               = header,
		})

		-- The dropdown menu (hidden by default)
		local menuH   = #options * DEFAULTS.DropdownItemH + 4
		local menu    = make("Frame", {
			Name             = "Menu",
			Size             = UDim2.new(1, 0, 0, menuH),
			Position         = UDim2.new(0, 0, 0, 16 + DEFAULTS.DropdownHeight + 2),
			BackgroundColor3 = THEME.DropdownBg,
			BorderSizePixel  = 0,
			Visible          = false,
			ZIndex           = 10,
			Parent           = container,
		})
		corner(DEFAULTS.CornerRadius - 2, menu)
		stroke(THEME.DropdownBorder, 1, menu)

		local menuLayout = Instance.new("UIListLayout")
		menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
		menuLayout.Padding   = UDim.new(0, 0)
		menuLayout.Parent    = menu

		local menuPad = Instance.new("UIPadding")
		menuPad.PaddingTop    = UDim.new(0, 2)
		menuPad.PaddingBottom = UDim.new(0, 2)
		menuPad.PaddingLeft   = UDim.new(0, 2)
		menuPad.PaddingRight  = UDim.new(0, 2)
		menuPad.Parent        = menu

		-- Build menu items
		for i, opt in ipairs(options) do
			local isSelected = (opt == selected)
			local item = make("TextButton", {
				Name             = "Item_" .. i,
				Size             = UDim2.new(1, 0, 0, DEFAULTS.DropdownItemH),
				BackgroundColor3 = isSelected and THEME.DropdownItemSel or THEME.DropdownItem,
				Text             = "",
				BorderSizePixel  = 0,
				LayoutOrder      = i,
				ZIndex           = 11,
				Parent           = menu,
			})
			corner(3, item)
			local itemLabel = make("TextLabel", {
				Size                 = UDim2.new(1, -10, 1, 0),
				Position             = UDim2.new(0, 8, 0, 0),
				BackgroundTransparency = 1,
				Text                 = opt,
				TextColor3           = isSelected and Color3.fromRGB(255,255,255) or THEME.DropdownText,
				TextSize             = DEFAULTS.FontSize,
				FontFace             = isSelected and FONT_SEMI or FONT_REG,
				TextXAlignment       = Enum.TextXAlignment.Left,
				ZIndex               = 12,
				Parent               = item,
			})

			item.MouseEnter:Connect(function()
				if opt ~= selected then
					tween(item, {BackgroundColor3 = THEME.DropdownItemHov})
				end
			end)
			item.MouseLeave:Connect(function()
				if opt ~= selected then
					tween(item, {BackgroundColor3 = THEME.DropdownItem})
				end
			end)
			item.MouseButton1Click:Connect(function()
				-- Deselect previous items visually
				for _, child in ipairs(menu:GetChildren()) do
					if child:IsA("TextButton") then
						tween(child, {BackgroundColor3 = THEME.DropdownItem})
						local lbl = child:FindFirstChildOfClass("TextLabel")
						if lbl then
							lbl.TextColor3 = THEME.DropdownText
							lbl.FontFace   = FONT_REG
						end
					end
				end
				-- Select this item
				tween(item, {BackgroundColor3 = THEME.DropdownItemSel})
				itemLabel.TextColor3 = Color3.fromRGB(255,255,255)
				itemLabel.FontFace   = FONT_SEMI
				selected             = opt
				selLabel.Text        = opt
				menu.Visible         = false
				arrow.Text           = "▾"
				if callback then callback(opt) end
			end)
		end

		-- Toggle menu open/closed
		local open = false
		header.MouseButton1Click:Connect(function()
			open         = not open
			menu.Visible = open
			arrow.Text   = open and "▴" or "▾"
		end)
		-- Hover tint on header
		header.MouseEnter:Connect(function()
			tween(header, {BackgroundColor3 = THEME.DropdownItemHov})
		end)
		header.MouseLeave:Connect(function()
			tween(header, {BackgroundColor3 = THEME.DropdownBg})
		end)
	end)
end

-- ══════════════════════════════════════════════════════════════
--  NEW WIDGET: ColorPicker
--
--  :ColorPicker(label, defaultColor, callback, requireToggle?)
--
--  defaultColor  = Color3 initial value
--  callback      = function(Color3)  called whenever color changes
--  requireToggle = (optional) boolean.
--      false / nil → picker is always accessible, toggle button just expands/collapses UI
--      true        → a labeled enable-toggle must be ON before the picker can be opened.
--                    callback is ONLY fired while the toggle is enabled.
--                    Useful for "Custom ESP Color (enable to use)" patterns.
--
--  The picker shows:
--    • An SV (saturation/value) 2-D gradient square
--    • A hue bar
--    • An alpha bar
--    • A live preview swatch
-- ══════════════════════════════════════════════════════════════
local function addColorPicker(tabData, label, defaultColor, callback, requireToggle)
	defaultColor = defaultColor or Color3.fromRGB(255, 50, 50)
	local h, s, v = color3ToHsv(defaultColor)
	local alpha    = 1   -- 0-1 (not exposed via Color3 but tracked for UI)
	local enabled  = not requireToggle  -- if requireToggle, start disabled

	table.insert(tabData.items, function(parent, order)
		-- Root container (dynamic height)
		local root = make("Frame", {
			Name                 = "ColorPicker_" .. order,
			Size                 = UDim2.new(1, 0, 0, DEFAULTS.ToggleHeight + 4),
			BackgroundTransparency = 1,
			ClipsDescendants     = false,
			LayoutOrder          = order,
			Parent               = parent,
		})

		-- ── Header row (label + optional enable-toggle + expand button) ──
		local headerRow = make("Frame", {
			Size                 = UDim2.new(1, 0, 0, DEFAULTS.ToggleHeight),
			BackgroundTransparency = 1,
			Parent               = root,
		})

		-- Color preview swatch (left of label)
		local swatch = make("Frame", {
			Size             = UDim2.new(0, 16, 0, 16),
			Position         = UDim2.new(0, 0, 0.5, -8),
			BackgroundColor3 = defaultColor,
			BorderSizePixel  = 0,
			Parent           = headerRow,
		})
		corner(3, swatch)
		stroke(THEME.DropdownBorder, 1, swatch)

		-- Label
		make("TextLabel", {
			Size                 = UDim2.new(1, requireToggle and -100 or -66, 1, 0),
			Position             = UDim2.new(0, 22, 0, 0),
			BackgroundTransparency = 1,
			Text                 = label,
			TextColor3           = THEME.ToggleText,
			TextSize             = DEFAULTS.FontSize,
			FontFace             = FONT_REG,
			TextXAlignment       = Enum.TextXAlignment.Left,
			Parent               = headerRow,
		})

		-- Optional "Enable" mini-toggle (only if requireToggle)
		local tW2, tH2 = 30, 16
		local enableTrack, enableKnob
		if requireToggle then
			enableTrack = make("Frame", {
				Size             = UDim2.new(0, tW2, 0, tH2),
				Position         = UDim2.new(1, -(tW2 + 40), 0.5, -tH2/2),
				BackgroundColor3 = enabled and THEME.ToggleOn or THEME.ToggleOff,
				BorderSizePixel  = 0,
				Parent           = headerRow,
			})
			corner(tH2/2, enableTrack)
			local kS2 = tH2 - 4
			enableKnob = make("Frame", {
				Size             = UDim2.new(0, kS2, 0, kS2),
				Position         = enabled and UDim2.new(0, tW2-kS2-2, 0.5, -kS2/2) or UDim2.new(0, 2, 0.5, -kS2/2),
				BackgroundColor3 = THEME.ToggleKnob,
				BorderSizePixel  = 0,
				Parent           = enableTrack,
			})
			corner(kS2/2, enableKnob)
		end

		-- Expand/collapse chevron button
		local expandBtn = make("TextButton", {
			Size                 = UDim2.new(0, 32, 0, 22),
			Position             = UDim2.new(1, -32, 0.5, -11),
			BackgroundColor3     = THEME.DropdownBg,
			Text                 = "▾",
			TextColor3           = THEME.DropdownArrow,
			TextSize             = DEFAULTS.FontSize + 2,
			FontFace             = FONT_BOLD,
			BorderSizePixel      = 0,
			Parent               = headerRow,
		})
		corner(4, expandBtn)
		stroke(THEME.DropdownBorder, 1, expandBtn)

		-- ── Picker panel (hidden by default) ─────────────────────
		local panelH  = DEFAULTS.ColorPickerH
		local panel   = make("Frame", {
			Name             = "PickerPanel",
			Size             = UDim2.new(1, 0, 0, panelH),
			Position         = UDim2.new(0, 0, 0, DEFAULTS.ToggleHeight + 6),
			BackgroundColor3 = THEME.PickerBg,
			BorderSizePixel  = 0,
			Visible          = false,
			ZIndex           = 8,
			Parent           = root,
		})
		corner(DEFAULTS.CornerRadius - 2, panel)
		stroke(THEME.PickerBorder, 1, panel)

		-- Internal layout padding
		local pp = Instance.new("UIPadding")
		pp.PaddingTop    = UDim.new(0, 8)
		pp.PaddingBottom = UDim.new(0, 8)
		pp.PaddingLeft   = UDim.new(0, 8)
		pp.PaddingRight  = UDim.new(0, 8)
		pp.Parent = panel

		-- ── SV Square ────────────────────────────────────────────
		-- Base hue layer
		local sqSize    = panelH - 90   -- leave room for bars + swatch
		local svSquare  = make("Frame", {
			Name             = "SVSquare",
			Size             = UDim2.new(0, sqSize, 0, sqSize),
			Position         = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = hsvToColor3(h, 1, 1),
			BorderSizePixel  = 0,
			ZIndex           = 9,
			Parent           = panel,
		})
		corner(4, svSquare)

		-- White → transparent overlay (saturation)
		local satOverlay = make("Frame", {
			Size             = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(255,255,255),
			BorderSizePixel  = 0,
			ZIndex           = 10,
			Parent           = svSquare,
		})
		corner(4, satOverlay)
		local satGrad = Instance.new("UIGradient")
		satGrad.Color      = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
		})
		satGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		satGrad.Rotation = 0
		satGrad.Parent   = satOverlay

		-- Black → transparent overlay (value)
		local valOverlay = make("Frame", {
			Size             = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(0,0,0),
			BorderSizePixel  = 0,
			ZIndex           = 11,
			Parent           = svSquare,
		})
		corner(4, valOverlay)
		local valGrad = Instance.new("UIGradient")
		valGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		valGrad.Rotation = 90
		valGrad.Parent   = valOverlay

		-- SV knob
		local svKnob = make("Frame", {
			Size             = UDim2.new(0, 10, 0, 10),
			Position         = UDim2.new(s, -5, 1-v, -5),
			BackgroundColor3 = Color3.fromRGB(255,255,255),
			BorderSizePixel  = 0,
			ZIndex           = 13,
			Parent           = svSquare,
		})
		corner(5, svKnob)
		stroke(Color3.fromRGB(0,0,0), 1, svKnob)

		-- SV drag
		local svDrag = make("TextButton", {
			Size                 = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text                 = "",
			ZIndex               = 14,
			Parent               = svSquare,
		})

		local function updateSVKnob()
			svKnob.Position = UDim2.new(s, -5, 1-v, -5)
		end
		local function updateColor()
			local newColor  = hsvToColor3(h, s, v)
			swatch.BackgroundColor3 = newColor
			if enabled and callback then callback(newColor) end
		end

		local svDragging = false
		local function updateSV(inp)
			local rx = math.clamp((inp.Position.X - svSquare.AbsolutePosition.X) / svSquare.AbsoluteSize.X, 0, 1)
			local ry = math.clamp((inp.Position.Y - svSquare.AbsolutePosition.Y) / svSquare.AbsoluteSize.Y, 0, 1)
			s = rx
			v = 1 - ry
			updateSVKnob()
			updateColor()
		end
		svDrag.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				svDragging = true; updateSV(inp)
			end
		end)
		svDrag.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if svDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
				updateSV(inp)
			end
		end)

		-- ── Hue Bar ──────────────────────────────────────────────
		local hueBarW  = math.max(1, panelH - 90 - sqSize - 8)  -- remaining width
		-- Place hue bar to the right of sv square
		local hueBar  = make("Frame", {
			Name             = "HueBar",
			Size             = UDim2.new(1, -(sqSize + 10), 0, sqSize),
			Position         = UDim2.new(0, sqSize + 10, 0, 0),
			BackgroundColor3 = Color3.fromRGB(255,0,0),
			BorderSizePixel  = 0,
			ZIndex           = 9,
			Parent           = panel,
		})
		corner(4, hueBar)
		local hueGrad = Instance.new("UIGradient")
		hueGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0/6,  Color3.fromRGB(255,0,0)),
			ColorSequenceKeypoint.new(1/6,  Color3.fromRGB(255,255,0)),
			ColorSequenceKeypoint.new(2/6,  Color3.fromRGB(0,255,0)),
			ColorSequenceKeypoint.new(3/6,  Color3.fromRGB(0,255,255)),
			ColorSequenceKeypoint.new(4/6,  Color3.fromRGB(0,0,255)),
			ColorSequenceKeypoint.new(5/6,  Color3.fromRGB(255,0,255)),
			ColorSequenceKeypoint.new(6/6,  Color3.fromRGB(255,0,0)),
		})
		hueGrad.Rotation = 90
		hueGrad.Parent   = hueBar

		local hueKnob = make("Frame", {
			Size             = UDim2.new(1, 2, 0, 4),
			Position         = UDim2.new(0, -1, h, -2),
			BackgroundColor3 = Color3.fromRGB(255,255,255),
			BorderSizePixel  = 0,
			ZIndex           = 13,
			Parent           = hueBar,
		})
		corner(2, hueKnob)
		stroke(Color3.fromRGB(0,0,0), 1, hueKnob)

		local hueDrag = make("TextButton", {
			Size                 = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text                 = "",
			ZIndex               = 14,
			Parent               = hueBar,
		})

		local function updateHue(inp)
			h = math.clamp((inp.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
			hueKnob.Position        = UDim2.new(0, -1, h, -2)
			svSquare.BackgroundColor3 = hsvToColor3(h, 1, 1)
			updateColor()
		end
		local hueDragging = false
		hueDrag.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				hueDragging = true; updateHue(inp)
			end
		end)
		hueDrag.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if hueDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
				updateHue(inp)
			end
		end)

		-- ── Alpha Bar ─────────────────────────────────────────────
		local alphaY = sqSize + 12
		local alphaBar = make("Frame", {
			Name             = "AlphaBar",
			Size             = UDim2.new(1, 0, 0, 14),
			Position         = UDim2.new(0, 0, 0, alphaY),
			BackgroundColor3 = Color3.fromRGB(255,255,255),
			BorderSizePixel  = 0,
			ZIndex           = 9,
			Parent           = panel,
		})
		corner(4, alphaBar)
		-- Checkerboard visual hint (just a flat gradient — real transparency isn't easy in Roblox UI)
		local alphaGrad = Instance.new("UIGradient")
		alphaGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(200,200,200)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
		})
		alphaGrad.Parent = alphaBar

		local alphaKnob = make("Frame", {
			Size             = UDim2.new(0, 4, 1, 2),
			Position         = UDim2.new(alpha, -2, 0, -1),
			BackgroundColor3 = Color3.fromRGB(255,255,255),
			BorderSizePixel  = 0,
			ZIndex           = 13,
			Parent           = alphaBar,
		})
		corner(2, alphaKnob)
		stroke(Color3.fromRGB(0,0,0), 1, alphaKnob)

		local alphaDrag = make("TextButton", {
			Size                 = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text                 = "",
			ZIndex               = 14,
			Parent               = alphaBar,
		})
		make("TextLabel", {
			Size                 = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text                 = "Alpha",
			TextColor3           = Color3.fromRGB(80,80,80),
			TextSize             = 10,
			FontFace             = FONT_REG,
			TextXAlignment       = Enum.TextXAlignment.Center,
			ZIndex               = 12,
			Parent               = alphaBar,
		})

		local function updateAlpha(inp)
			alpha = math.clamp((inp.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
			alphaKnob.Position = UDim2.new(alpha, -2, 0, -1)
			-- Alpha is available via the callback as 4th arg if needed
			if enabled and callback then callback(hsvToColor3(h, s, v)) end
		end
		local alphaDragging = false
		alphaDrag.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				alphaDragging = true; updateAlpha(inp)
			end
		end)
		alphaDrag.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then alphaDragging = false end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if alphaDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
				updateAlpha(inp)
			end
		end)

		-- ── Hex / preview row ─────────────────────────────────────
		local previewY = alphaY + 20
		local bigSwatch = make("Frame", {
			Size             = UDim2.new(1, 0, 0, 20),
			Position         = UDim2.new(0, 0, 0, previewY),
			BackgroundColor3 = hsvToColor3(h, s, v),
			BorderSizePixel  = 0,
			ZIndex           = 9,
			Parent           = panel,
		})
		corner(4, bigSwatch)
		stroke(THEME.PickerBorder, 1, bigSwatch)
		-- Keep big swatch synced
		local origUpdateColor = updateColor
		updateColor = function()
			local newColor = hsvToColor3(h, s, v)
			swatch.BackgroundColor3   = newColor
			bigSwatch.BackgroundColor3 = newColor
			if enabled and callback then callback(newColor) end
		end

		-- ── Enable toggle logic ───────────────────────────────────
		if requireToggle and enableTrack then
			local kS2 = tH2 - 4
			local clickZone = make("TextButton", {
				Size                 = UDim2.new(0, tW2 + 4, 1, 0),
				Position             = UDim2.new(1, -(tW2 + 42), 0, 0),
				BackgroundTransparency = 1,
				Text                 = "",
				ZIndex               = 5,
				Parent               = headerRow,
			})
			clickZone.MouseButton1Click:Connect(function()
				enabled = not enabled
				tween(enableTrack, {BackgroundColor3 = enabled and THEME.ToggleOn or THEME.ToggleOff})
				tween(enableKnob, {Position = enabled and UDim2.new(0, tW2-kS2-2, 0.5, -kS2/2) or UDim2.new(0, 2, 0.5, -kS2/2)})
				if not enabled then
					-- close picker when disabled
					panel.Visible = false
					expandBtn.Text = "▾"
					root.Size = UDim2.new(1, 0, 0, DEFAULTS.ToggleHeight + 4)
				end
			end)
		end

		-- ── Expand/collapse ──────────────────────────────────────
		local isOpen = false
		expandBtn.MouseButton1Click:Connect(function()
			if requireToggle and not enabled then return end  -- blocked if not enabled
			isOpen = not isOpen
			panel.Visible  = isOpen
			expandBtn.Text = isOpen and "▴" or "▾"
			root.Size = UDim2.new(1, 0, 0, isOpen and (DEFAULTS.ToggleHeight + 4 + panelH + 6) or (DEFAULTS.ToggleHeight + 4))
		end)
		expandBtn.MouseEnter:Connect(function() tween(expandBtn, {BackgroundColor3 = THEME.DropdownItemHov}) end)
		expandBtn.MouseLeave:Connect(function() tween(expandBtn, {BackgroundColor3 = THEME.DropdownBg}) end)
	end)
end

-- ══════════════════════════════════════════════════════════════
--  TabBuilder method bindings
-- ══════════════════════════════════════════════════════════════
function TabBuilder:Label(text)          addLabel(self._tabData, text);                    return self end
function TabBuilder:Separator()          addSeparator(self._tabData);                      return self end
function TabBuilder:Button(l, cb)        addButton(self._tabData, l, cb);                  return self end
function TabBuilder:Toggle(l, d, cb)     addToggle(self._tabData, l, d, cb);               return self end
function TabBuilder:Slider(l,mn,mx,d,cb) addSlider(self._tabData, l, mn, mx, d, cb);       return self end
function TabBuilder:Dropdown(l, opts, def, cb)      addDropdown(self._tabData, l, opts, def, cb);   return self end
function TabBuilder:ColorPicker(l, col, cb, req)    addColorPicker(self._tabData, l, col, cb, req); return self end

-- ── RbxImGui proxy methods (no-tab / single-panel mode) ───────
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

function RbxImGui:Label(text)          addLabel(ensureDefault(self), text);                    return self end
function RbxImGui:Separator()          addSeparator(ensureDefault(self));                      return self end
function RbxImGui:Button(l, cb)        addButton(ensureDefault(self), l, cb);                  return self end
function RbxImGui:Toggle(l, d, cb)     addToggle(ensureDefault(self), l, d, cb);               return self end
function RbxImGui:Slider(l,mn,mx,d,cb) addSlider(ensureDefault(self), l, mn, mx, d, cb);       return self end
function RbxImGui:Dropdown(l, opts, def, cb)      addDropdown(ensureDefault(self), l, opts, def, cb);   return self end
function RbxImGui:ColorPicker(l, col, cb, req)    addColorPicker(ensureDefault(self), l, col, cb, req); return self end

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
