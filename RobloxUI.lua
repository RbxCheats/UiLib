-- ============================================================
--  RbxImGui  |  Lightweight ImGui-style UI Library for Roblox
--
--  Usage:
--    local UI  = require(path.to.RbxImGui)
--    local win = UI.new("My Panel")
--
--    -- Add tabs
--    win:AddTab("Aimbot")
--    win:AddTab("Visuals")
--    win:AddTab("Misc")
--
--    -- Add widgets to a specific tab
--    win:Tab("Aimbot"):Toggle("Silent Aim", false, function(v) end)
--    win:Tab("Visuals"):Slider("FOV", 30, 120, 70, function(v) end)
--    win:Tab("Misc"):Button("Reset", function() end)
--
--    win:Render()
-- ============================================================

local RbxImGui = {}
RbxImGui.__index = RbxImGui

-- Tab builder object — returned by win:Tab()
local TabBuilder = {}
TabBuilder.__index = TabBuilder

-- ── Theming ──────────────────────────────────────────────────
local THEME = {
	TitleBarBg        = Color3.fromRGB(20, 20, 26),
	TitleBarText      = Color3.fromRGB(220, 220, 220),

	TabBarBg          = Color3.fromRGB(26, 26, 34),
	TabBg             = Color3.fromRGB(32, 32, 42),
	TabHover          = Color3.fromRGB(45, 45, 60),
	TabActive         = Color3.fromRGB(82, 130, 255),
	TabText           = Color3.fromRGB(160, 160, 180),
	TabTextActive     = Color3.fromRGB(255, 255, 255),

	WindowBg          = Color3.fromRGB(22, 22, 28),
	WindowBorder      = Color3.fromRGB(55, 55, 75),

	ButtonBg          = Color3.fromRGB(52, 52, 68),
	ButtonHover       = Color3.fromRGB(72, 72, 100),
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
}

-- ── Defaults ─────────────────────────────────────────────────
local DEFAULTS = {
	WindowWidth      = 320,
	WindowMinWidth   = 200,
	WindowMinHeight  = 120,
	TitleBarHeight   = 30,
	TabBarHeight     = 30,
	TabMinWidth      = 60,
	Padding          = 10,
	ItemSpacing      = 6,
	ButtonHeight     = 28,
	ToggleHeight     = 24,
	SliderHeight     = 30,
	CornerRadius     = 6,
	FontSize         = 13,
	ResizeGripSize   = 14,
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

-- ── Constructor ───────────────────────────────────────────────
function RbxImGui.new(title, parent)
	local self = setmetatable({}, RbxImGui)

	self._title      = title or "Window"
	self._tabs       = {}       -- { name, items[], scrollFrame, tabBtn }
	self._activeTab  = nil
	self._rendered   = false

	-- ── ScreenGui ─────────────────────────────────────────────
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

	-- ── Title Bar ─────────────────────────────────────────────
	-- Plain flat bar — no accent stripe, clean look
	local titleBar = make("Frame", {
		Name             = "TitleBar",
		Size             = UDim2.new(1, 0, 0, DEFAULTS.TitleBarHeight),
		BackgroundColor3 = THEME.TitleBarBg,
		BorderSizePixel  = 0,
		Parent           = self._window,
	})
	-- Top corners match the window, bottom is flat (flush with tab bar)
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, DEFAULTS.CornerRadius)
	tc.Parent = titleBar

	make("TextLabel", {
		Name                  = "Title",
		Size                  = UDim2.new(1, -12, 1, 0),
		Position              = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency= 1,
		Text                  = self._title,
		TextColor3            = THEME.TitleBarText,
		TextSize              = DEFAULTS.FontSize + 1,
		FontFace              = FONT_BOLD,
		TextXAlignment        = Enum.TextXAlignment.Left,
		Parent                = titleBar,
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
	-- thin separator line under tab bar
	make("Frame", {
		Name             = "TabSep",
		Size             = UDim2.new(1, 0, 0, 1),
		Position         = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = THEME.WindowBorder,
		BorderSizePixel  = 0,
		Parent           = self._tabBar,
	})
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection  = Enum.FillDirection.Horizontal
	tabLayout.SortOrder      = Enum.SortOrder.LayoutOrder
	tabLayout.Padding        = UDim.new(0, 1)
	tabLayout.Parent         = self._tabBar

	local tabPad = Instance.new("UIPadding")
	tabPad.PaddingLeft  = UDim.new(0, 4)
	tabPad.PaddingRight = UDim.new(0, 4)
	tabPad.PaddingTop   = UDim.new(0, 4)
	tabPad.Parent       = self._tabBar

	self._tabLayout = tabLayout

	-- ── Content Area ──────────────────────────────────────────
	-- Sits below both the title bar and tab bar
	local contentTop = DEFAULTS.TitleBarHeight + DEFAULTS.TabBarHeight
	self._contentArea = make("Frame", {
		Name             = "ContentArea",
		Size             = UDim2.new(1, 0, 1, -(contentTop + DEFAULTS.ResizeGripSize)),
		Position         = UDim2.new(0, 0, 0, contentTop),
		BackgroundTransparency = 1,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		Parent           = self._window,
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

-- Register a new tab. Returns self for chaining.
function RbxImGui:AddTab(name)
	local tabIndex = #self._tabs + 1

	-- Tab button in the tab bar
	local btn = make("TextButton", {
		Name             = "Tab_" .. name,
		Size             = UDim2.new(0, math.max(DEFAULTS.TabMinWidth, #name * 8 + 20), 1, -4),
		BackgroundColor3 = THEME.TabBg,
		Text             = name,
		TextColor3       = THEME.TabText,
		TextSize         = DEFAULTS.FontSize - 1,
		FontFace         = FONT_SEMI,
		BorderSizePixel  = 0,
		LayoutOrder      = tabIndex,
		Parent           = self._tabBar,
	})
	corner(4, btn)

	-- Scroll frame for this tab's content
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

	local tabData = {
		name        = name,
		items       = {},
		scrollFrame = sf,
		tabBtn      = btn,
	}
	self._tabs[tabIndex] = tabData
	self._tabs[name]     = tabData  -- also index by name for win:Tab("Name")

	-- Click handler — switch to this tab
	btn.MouseButton1Click:Connect(function()
		self:_switchTab(name)
	end)
	btn.MouseEnter:Connect(function()
		if self._activeTab ~= name then
			tween(btn, {BackgroundColor3 = THEME.TabHover})
		end
	end)
	btn.MouseLeave:Connect(function()
		if self._activeTab ~= name then
			tween(btn, {BackgroundColor3 = THEME.TabBg})
		end
	end)

	-- Auto-activate first tab
	if tabIndex == 1 then
		self:_switchTab(name)
	end

	return self
end

-- Internal: switch the visible tab
function RbxImGui:_switchTab(name)
	self._activeTab = name
	for _, td in pairs(self._tabs) do
		if type(td) == "table" then
			local isActive = (td.name == name)
			td.scrollFrame.Visible = isActive
			tween(td.tabBtn, {
				BackgroundColor3 = isActive and THEME.TabActive or THEME.TabBg,
				TextColor3       = isActive and THEME.TabTextActive or THEME.TabText,
			})
		end
	end
end

-- Returns a TabBuilder scoped to the named tab.
-- win:Tab("Aimbot"):Button("Fire", cb)
function RbxImGui:Tab(name)
	assert(self._tabs[name], "Tab '" .. tostring(name) .. "' does not exist. Call :AddTab() first.")
	local builder  = setmetatable({}, TabBuilder)
	builder._tabData = self._tabs[name]
	return builder
end

-- ── Widget helpers shared by both TabBuilder and RbxImGui ─────
-- All widget-adding methods live on TabBuilder.
-- RbxImGui also proxies them so a window with no tabs still works.

local function addLabel(tabData, text)
	table.insert(tabData.items, function(parent, order)
		make("TextLabel", {
			Name                  = "Label_" .. order,
			Size                  = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency= 1,
			Text                  = text,
			TextColor3            = THEME.TextColor,
			TextSize              = DEFAULTS.FontSize,
			FontFace              = FONT_REG,
			TextXAlignment        = Enum.TextXAlignment.Left,
			LayoutOrder           = order,
			Parent                = parent,
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

		btn.MouseEnter:Connect(function()    tween(btn, {BackgroundColor3 = THEME.ButtonHover}) end)
		btn.MouseLeave:Connect(function()    tween(btn, {BackgroundColor3 = THEME.ButtonBg})    end)
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
			Name                  = "Toggle_" .. order,
			Size                  = UDim2.new(1, 0, 0, DEFAULTS.ToggleHeight),
			BackgroundTransparency= 1,
			LayoutOrder           = order,
			Parent                = parent,
		})
		make("TextLabel", {
			Size                  = UDim2.new(1, -50, 1, 0),
			BackgroundTransparency= 1,
			Text                  = label,
			TextColor3            = THEME.ToggleText,
			TextSize              = DEFAULTS.FontSize,
			FontFace              = FONT_REG,
			TextXAlignment        = Enum.TextXAlignment.Left,
			Parent                = row,
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
			Size                  = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency= 1,
			Text                  = "",
			Parent                = row,
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
	min     = min     or 0
	max     = max     or 100
	default = default or min
	local value = math.clamp(default, min, max)
	table.insert(tabData.items, function(parent, order)
		local col = make("Frame", {
			Name                  = "Slider_" .. order,
			Size                  = UDim2.new(1, 0, 0, DEFAULTS.SliderHeight + 16),
			BackgroundTransparency= 1,
			LayoutOrder           = order,
			Parent                = parent,
		})
		local hdr = make("Frame", {
			Size                  = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency= 1,
			Parent                = col,
		})
		make("TextLabel", {
			Size                  = UDim2.new(0.6, 0, 1, 0),
			BackgroundTransparency= 1,
			Text                  = label,
			TextColor3            = THEME.SliderText,
			TextSize              = DEFAULTS.FontSize,
			FontFace              = FONT_REG,
			TextXAlignment        = Enum.TextXAlignment.Left,
			Parent                = hdr,
		})
		local valLbl = make("TextLabel", {
			Size                  = UDim2.new(0.4, 0, 1, 0),
			Position              = UDim2.new(0.6, 0, 0, 0),
			BackgroundTransparency= 1,
			Text                  = tostring(math.floor(value)),
			TextColor3            = THEME.SliderValue,
			TextSize              = DEFAULTS.FontSize,
			FontFace              = FONT_BOLD,
			TextXAlignment        = Enum.TextXAlignment.Right,
			Parent                = hdr,
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
			Size                  = UDim2.new(1, 0, 0, DEFAULTS.SliderHeight),
			Position              = UDim2.new(0, 0, 0, 14),
			BackgroundTransparency= 1,
			Text                  = "",
			ZIndex                = 3,
			Parent                = col,
		})
		local function update(x)
			local p   = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			value     = min + p * (max - min)
			valLbl.Text  = tostring(math.floor(value))
			fill.Size    = UDim2.new(p, 0, 1, 0)
			knob.Position= UDim2.new(p, -kS/2, 0.5, -kS/2)
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

-- ── TabBuilder methods ────────────────────────────────────────
function TabBuilder:Label(text)       addLabel(self._tabData, text);                    return self end
function TabBuilder:Separator()       addSeparator(self._tabData);                      return self end
function TabBuilder:Button(l, cb)     addButton(self._tabData, l, cb);                  return self end
function TabBuilder:Toggle(l, d, cb)  addToggle(self._tabData, l, d, cb);               return self end
function TabBuilder:Slider(l,mn,mx,d,cb) addSlider(self._tabData, l, mn, mx, d, cb);   return self end

-- ── RbxImGui proxy methods (single-tab / no-tab usage) ────────
-- These add widgets to a hidden default tab called "__default"
local function ensureDefault(self)
	if not self._tabs["__default"] then
		self:AddTab("__default")
		-- hide the tab button since it's a single-tab window
		self._tabs["__default"].tabBtn.Visible = false
		self._tabBar.Visible = false
		-- shift content area up since there's no tab bar
		self._contentArea.Position = UDim2.new(0, 0, 0, DEFAULTS.TitleBarHeight)
		self._contentArea.Size     = UDim2.new(1, 0, 1, -(DEFAULTS.TitleBarHeight + DEFAULTS.ResizeGripSize))
	end
	return self._tabs["__default"]
end

function RbxImGui:Label(text)          addLabel(ensureDefault(self), text);                   return self end
function RbxImGui:Separator()          addSeparator(ensureDefault(self));                     return self end
function RbxImGui:Button(l, cb)        addButton(ensureDefault(self), l, cb);                 return self end
function RbxImGui:Toggle(l, d, cb)     addToggle(ensureDefault(self), l, d, cb);              return self end
function RbxImGui:Slider(l,mn,mx,d,cb) addSlider(ensureDefault(self), l, mn, mx, d, cb);     return self end

-- ── Render ────────────────────────────────────────────────────
function RbxImGui:Render()
	for _, td in pairs(self._tabs) do
		if type(td) == "table" then
			for i, builder in ipairs(td.items) do
				builder(td.scrollFrame, i)
			end
		end
	end
	self._rendered = true
end

-- ── Visibility ────────────────────────────────────────────────
function RbxImGui:Show()         self._window.Visible = true  end
function RbxImGui:Hide()         self._window.Visible = false end
function RbxImGui:Toggle_Window() self._window.Visible = not self._window.Visible end
function RbxImGui:Destroy()      if self._screenGui then self._screenGui:Destroy() end end

return RbxImGui
