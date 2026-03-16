-- ============================================================
--  RbxImGui  |  Lightweight ImGui-style UI Library for Roblox
--  Usage: local UI = require(path.to.RbxImGui)
--         local win = UI.new("My Window")
--         win:Button("Click Me", function() print("clicked") end)
--         win:Toggle("Show Debug", false, function(v) print(v) end)
--         win:Slider("Speed", 0, 100, 50, function(v) print(v) end)
--         win:Render()
-- ============================================================

local RbxImGui = {}
RbxImGui.__index = RbxImGui

-- ── Theming ──────────────────────────────────────────────────
local THEME = {
	TitleBarBg        = Color3.fromRGB(30, 30, 38),
	TitleBarText      = Color3.fromRGB(220, 220, 220),
	TitleBarAccent    = Color3.fromRGB(82, 130, 255),

	WindowBg          = Color3.fromRGB(22, 22, 28),
	WindowBorder      = Color3.fromRGB(60, 60, 80),

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

	ResizeGrip        = Color3.fromRGB(60, 60, 82),
	ResizeGripHover   = Color3.fromRGB(82, 130, 255),

	ScrollBar         = Color3.fromRGB(45, 45, 60),
	ScrollThumb       = Color3.fromRGB(80, 80, 110),
}

-- ── Defaults ─────────────────────────────────────────────────
local DEFAULTS = {
	WindowWidth      = 300,
	WindowMinWidth   = 180,
	WindowMinHeight  = 100,
	TitleBarHeight   = 28,
	Padding          = 10,
	ItemSpacing      = 6,
	ButtonHeight     = 28,
	ToggleHeight     = 24,
	SliderHeight     = 30,
	CornerRadius     = 4,
	FontSize         = 13,
	ResizeGripSize   = 16,
}

-- ── Helpers ───────────────────────────────────────────────────
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")

local function makeTween(obj, props, t)
	t = t or 0.12
	local info = TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(obj, info, props):Play()
end

local function createBase(className, props)
	local obj = Instance.new(className)
	for k, v in pairs(props) do
		obj[k] = v
	end
	return obj
end

local function makeCorner(radius, parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function makeStroke(color, thickness, parent)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

local function makePadding(p, parent)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, p)
	pad.PaddingRight  = UDim.new(0, p)
	pad.PaddingTop    = UDim.new(0, p)
	pad.PaddingBottom = UDim.new(0, p)
	pad.Parent = parent
	return pad
end

-- ── Constructor ───────────────────────────────────────────────
--  parent: ScreenGui or Frame to parent the window to.
--  If nil, parents to CoreGui (falls back to PlayerGui in Studio).
function RbxImGui.new(title, parent)
	local self = setmetatable({}, RbxImGui)

	self._title    = title or "Window"
	self._items    = {}        -- ordered list of widget builders
	self._widgets  = {}        -- live widget frames for state reads
	self._rendered = false

	-- resolve parent — prefer CoreGui so the window survives death/respawn
	-- and sits above all in-game UI. Falls back to PlayerGui if CoreGui
	-- is not accessible (e.g. running in Studio without plugin permissions).
	if not parent then
		local sg = Instance.new("ScreenGui")
		sg.Name           = "RbxImGui_" .. self._title
		sg.ResetOnSpawn   = false
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.DisplayOrder   = 999  -- render on top of everything

		local ok = pcall(function()
			sg.Parent = game:GetService("CoreGui")
		end)

		if not ok then
			-- CoreGui blocked (Studio without plugin perms) — use PlayerGui
			local lp = game:GetService("Players").LocalPlayer
			sg.Parent = lp:WaitForChild("PlayerGui")
		end

		parent = sg
	end
	self._screenGui = parent

	-- ── Window Frame ──────────────────────────────────────────
	self._window = createBase("Frame", {
		Name            = "ImGuiWindow",
		Size            = UDim2.new(0, DEFAULTS.WindowWidth, 0, 300),
		Position        = UDim2.new(0, 80, 0, 80),
		BackgroundColor3= THEME.WindowBg,
		BorderSizePixel = 0,
		ClipsDescendants= true,
		Parent          = parent,
	})
	makeCorner(DEFAULTS.CornerRadius + 1, self._window)
	makeStroke(THEME.WindowBorder, 1, self._window)

	-- ── Title Bar ─────────────────────────────────────────────
	local titleBar = createBase("Frame", {
		Name             = "TitleBar",
		Size             = UDim2.new(1, 0, 0, DEFAULTS.TitleBarHeight),
		BackgroundColor3 = THEME.TitleBarBg,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		Parent           = self._window,
	})
	-- Round only top corners of title bar to match window rounding
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, DEFAULTS.CornerRadius + 1)
	titleCorner.Parent = titleBar
	-- accent stripe on left edge (tall enough to bleed past bottom corners)
	createBase("Frame", {
		Name            = "Accent",
		Size            = UDim2.new(0, 3, 1, 8),
		BackgroundColor3= THEME.TitleBarAccent,
		BorderSizePixel = 0,
		Parent          = titleBar,
	})
	createBase("TextLabel", {
		Name            = "Title",
		Size            = UDim2.new(1, -10, 1, 0),
		Position        = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text            = self._title,
		TextColor3      = THEME.TitleBarText,
		TextSize        = DEFAULTS.FontSize + 1,
		FontFace        = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		TextXAlignment  = Enum.TextXAlignment.Left,
		Parent          = titleBar,
	})

	-- ── Drag Logic ────────────────────────────────────────────
	local dragging, dragInput, dragStart, startPos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = input.Position
			startPos  = self._window.Position
		end
	end)
	titleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			self._window.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	-- ── Scroll Frame (content area) ───────────────────────────
	self._scrollFrame = createBase("ScrollingFrame", {
		Name                  = "Content",
		Size                  = UDim2.new(1, 0, 1, -(DEFAULTS.TitleBarHeight + DEFAULTS.ResizeGripSize)),
		Position              = UDim2.new(0, 0, 0, DEFAULTS.TitleBarHeight),
		BackgroundTransparency= 1,
		BorderSizePixel       = 0,
		ScrollBarThickness    = 4,
		ScrollBarImageColor3  = THEME.ScrollThumb,
		CanvasSize            = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize   = Enum.AutomaticSize.Y,
		Parent                = self._window,
	})

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder    = Enum.SortOrder.LayoutOrder
	listLayout.Padding      = UDim.new(0, DEFAULTS.ItemSpacing)
	listLayout.Parent       = self._scrollFrame

	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingLeft   = UDim.new(0, DEFAULTS.Padding)
	contentPad.PaddingRight  = UDim.new(0, DEFAULTS.Padding)
	contentPad.PaddingTop    = UDim.new(0, DEFAULTS.Padding)
	contentPad.PaddingBottom = UDim.new(0, DEFAULTS.Padding)
	contentPad.Parent        = self._scrollFrame

	self._listLayout = listLayout

	-- ── Resize Grip ───────────────────────────────────────────
	local grip = createBase("TextButton", {
		Name            = "ResizeGrip",
		Size            = UDim2.new(0, DEFAULTS.ResizeGripSize, 0, DEFAULTS.ResizeGripSize),
		Position        = UDim2.new(1, -DEFAULTS.ResizeGripSize, 1, -DEFAULTS.ResizeGripSize),
		BackgroundColor3= THEME.ResizeGrip,
		Text            = "",
		BorderSizePixel = 0,
		Parent          = self._window,
	})
	makeCorner(2, grip)
	-- Resize grip dots (3 diagonal dots, no unicode needed)
	for i = 1, 3 do
		createBase("Frame", {
			Size            = UDim2.new(0, 2, 0, 2),
			Position        = UDim2.new(0, 3 + (i-1)*4, 0, 11 - (i-1)*4),
			BackgroundColor3= Color3.fromRGB(130, 140, 180),
			BorderSizePixel = 0,
			Parent          = grip,
		})
	end

	grip.MouseEnter:Connect(function()
		makeTween(grip, {BackgroundColor3 = THEME.ResizeGripHover})
	end)
	grip.MouseLeave:Connect(function()
		makeTween(grip, {BackgroundColor3 = THEME.ResizeGrip})
	end)

	local resizing, resizeStart, resizeStartSize
	grip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing         = true
			resizeStart      = input.Position
			resizeStartSize  = self._window.AbsoluteSize
		end
	end)
	grip.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - resizeStart
			local newW  = math.max(DEFAULTS.WindowMinWidth,  resizeStartSize.X + delta.X)
			local newH  = math.max(DEFAULTS.WindowMinHeight, resizeStartSize.Y + delta.Y)
			self._window.Size = UDim2.new(0, newW, 0, newH)
		end
	end)

	-- ── Insert Key Toggle ───────────────────────────────────
	-- Press Insert to show/hide the window.
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Insert then
			self._window.Visible = not self._window.Visible
		end
	end)

	return self
end

-- ── Public API ────────────────────────────────────────────────

-- Add a text label
function RbxImGui:Label(text)
	table.insert(self._items, function(parent, order)
		local lbl = createBase("TextLabel", {
			Name               = "Label_" .. order,
			Size               = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text               = text,
			TextColor3         = THEME.TextColor,
			TextSize           = DEFAULTS.FontSize,
			FontFace           = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			TextXAlignment     = Enum.TextXAlignment.Left,
			LayoutOrder        = order,
			Parent             = parent,
		})
	end)
	return self
end

-- Add a separator line
function RbxImGui:Separator()
	table.insert(self._items, function(parent, order)
		createBase("Frame", {
			Name            = "Sep_" .. order,
			Size            = UDim2.new(1, 0, 0, 1),
			BackgroundColor3= THEME.SeparatorColor,
			BorderSizePixel = 0,
			LayoutOrder     = order,
			Parent          = parent,
		})
	end)
	return self
end

-- Add a button
-- callback()
function RbxImGui:Button(label, callback)
	table.insert(self._items, function(parent, order)
		local btn = createBase("TextButton", {
			Name            = "Btn_" .. order,
			Size            = UDim2.new(1, 0, 0, DEFAULTS.ButtonHeight),
			BackgroundColor3= THEME.ButtonBg,
			Text            = label,
			TextColor3      = THEME.ButtonText,
			TextSize        = DEFAULTS.FontSize,
			FontFace        = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
			BorderSizePixel = 0,
			LayoutOrder     = order,
			Parent          = parent,
		})
		makeCorner(DEFAULTS.CornerRadius, btn)
		makeStroke(Color3.fromRGB(70, 70, 95), 1, btn)

		btn.MouseEnter:Connect(function()
			makeTween(btn, {BackgroundColor3 = THEME.ButtonHover})
		end)
		btn.MouseLeave:Connect(function()
			makeTween(btn, {BackgroundColor3 = THEME.ButtonBg})
		end)
		btn.MouseButton1Down:Connect(function()
			makeTween(btn, {BackgroundColor3 = THEME.ButtonActive}, 0.07)
		end)
		btn.MouseButton1Up:Connect(function()
			makeTween(btn, {BackgroundColor3 = THEME.ButtonHover}, 0.07)
			if callback then callback() end
		end)
	end)
	return self
end

-- Add a toggle
-- defaultValue: bool, callback(newValue: bool)
function RbxImGui:Toggle(label, defaultValue, callback)
	local state = defaultValue or false
	table.insert(self._items, function(parent, order)
		local row = createBase("Frame", {
			Name            = "Toggle_" .. order,
			Size            = UDim2.new(1, 0, 0, DEFAULTS.ToggleHeight),
			BackgroundTransparency = 1,
			LayoutOrder     = order,
			Parent          = parent,
		})

		createBase("TextLabel", {
			Size               = UDim2.new(1, -50, 1, 0),
			BackgroundTransparency = 1,
			Text               = label,
			TextColor3         = THEME.ToggleText,
			TextSize           = DEFAULTS.FontSize,
			FontFace           = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			TextXAlignment     = Enum.TextXAlignment.Left,
			Parent             = row,
		})

		local trackW, trackH = 36, 18
		local track = createBase("Frame", {
			Name            = "Track",
			Size            = UDim2.new(0, trackW, 0, trackH),
			Position        = UDim2.new(1, -trackW, 0.5, -trackH/2),
			BackgroundColor3= state and THEME.ToggleOn or THEME.ToggleOff,
			BorderSizePixel = 0,
			Parent          = row,
		})
		makeCorner(trackH/2, track)

		local knobSize = trackH - 4
		local knob = createBase("Frame", {
			Name            = "Knob",
			Size            = UDim2.new(0, knobSize, 0, knobSize),
			Position        = state
				and UDim2.new(0, trackW - knobSize - 2, 0.5, -knobSize/2)
				or  UDim2.new(0, 2, 0.5, -knobSize/2),
			BackgroundColor3= THEME.ToggleKnob,
			BorderSizePixel = 0,
			Parent          = track,
		})
		makeCorner(knobSize/2, knob)

		local btn = createBase("TextButton", {
			Size               = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text               = "",
			Parent             = row,
		})

		btn.MouseButton1Click:Connect(function()
			state = not state
			makeTween(track, {BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff})
			makeTween(knob, {
				Position = state
					and UDim2.new(0, trackW - knobSize - 2, 0.5, -knobSize/2)
					or  UDim2.new(0, 2, 0.5, -knobSize/2)
			})
			if callback then callback(state) end
		end)
	end)
	return self
end

-- Add a slider
-- min, max, default: numbers, callback(value: number)
function RbxImGui:Slider(label, min, max, default, callback)
	min     = min     or 0
	max     = max     or 100
	default = default or min
	local value = math.clamp(default, min, max)

	table.insert(self._items, function(parent, order)
		local col = createBase("Frame", {
			Name            = "Slider_" .. order,
			Size            = UDim2.new(1, 0, 0, DEFAULTS.SliderHeight + 16),
			BackgroundTransparency = 1,
			LayoutOrder     = order,
			Parent          = parent,
		})

		-- label row
		local labelRow = createBase("Frame", {
			Size               = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Parent             = col,
		})
		createBase("TextLabel", {
			Size               = UDim2.new(0.6, 0, 1, 0),
			BackgroundTransparency = 1,
			Text               = label,
			TextColor3         = THEME.SliderText,
			TextSize           = DEFAULTS.FontSize,
			FontFace           = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			TextXAlignment     = Enum.TextXAlignment.Left,
			Parent             = labelRow,
		})
		local valLabel = createBase("TextLabel", {
			Size               = UDim2.new(0.4, 0, 1, 0),
			Position           = UDim2.new(0.6, 0, 0, 0),
			BackgroundTransparency = 1,
			Text               = tostring(math.floor(value)),
			TextColor3         = THEME.SliderValue,
			TextSize           = DEFAULTS.FontSize,
			FontFace           = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			TextXAlignment     = Enum.TextXAlignment.Right,
			Parent             = labelRow,
		})

		-- track
		local trackHeight = 6
		local track = createBase("Frame", {
			Size            = UDim2.new(1, 0, 0, trackHeight),
			Position        = UDim2.new(0, 0, 0, 16 + (DEFAULTS.SliderHeight - trackHeight)/2),
			BackgroundColor3= THEME.SliderTrack,
			BorderSizePixel = 0,
			Parent          = col,
		})
		makeCorner(trackHeight/2, track)

		local fillPct = (value - min) / (max - min)
		local fill = createBase("Frame", {
			Name            = "Fill",
			Size            = UDim2.new(fillPct, 0, 1, 0),
			BackgroundColor3= THEME.SliderFill,
			BorderSizePixel = 0,
			Parent          = track,
		})
		makeCorner(trackHeight/2, fill)

		local knobSize = 14
		local knob = createBase("Frame", {
			Name            = "Knob",
			Size            = UDim2.new(0, knobSize, 0, knobSize),
			Position        = UDim2.new(fillPct, -knobSize/2, 0.5, -knobSize/2),
			BackgroundColor3= THEME.SliderKnob,
			BorderSizePixel = 0,
			ZIndex          = 2,
			Parent          = track,
		})
		makeCorner(knobSize/2, knob)
		makeStroke(THEME.SliderFill, 2, knob)

		-- invisible drag button over track
		local dragBtn = createBase("TextButton", {
			Size               = UDim2.new(1, 0, 0, DEFAULTS.SliderHeight),
			Position           = UDim2.new(0, 0, 0, 14),
			BackgroundTransparency = 1,
			Text               = "",
			ZIndex             = 3,
			Parent             = col,
		})

		local function updateSlider(inputX)
			local abs     = track.AbsolutePosition.X
			local absW    = track.AbsoluteSize.X
			local pct     = math.clamp((inputX - abs) / absW, 0, 1)
			value         = min + pct * (max - min)
			valLabel.Text = tostring(math.floor(value))
			fill.Size     = UDim2.new(pct, 0, 1, 0)
			knob.Position = UDim2.new(pct, -knobSize/2, 0.5, -knobSize/2)
			if callback then callback(math.floor(value)) end
		end

		local sliding = false
		dragBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				sliding = true
				updateSlider(input.Position.X)
			end
		end)
		dragBtn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				sliding = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
				updateSlider(input.Position.X)
			end
		end)
	end)
	return self
end

-- ── Render ────────────────────────────────────────────────────
-- Call once after adding all widgets; builds the actual UI.
function RbxImGui:Render()
	for i, builder in ipairs(self._items) do
		builder(self._scrollFrame, i)
	end
	self._rendered = true
end

-- ── Visibility Helpers ────────────────────────────────────────
function RbxImGui:Show()
	self._window.Visible = true
end

function RbxImGui:Hide()
	self._window.Visible = false
end

function RbxImGui:Toggle_Window()
	self._window.Visible = not self._window.Visible
end

-- ── Destroy ───────────────────────────────────────────────────
function RbxImGui:Destroy()
	if self._screenGui then
		self._screenGui:Destroy()
	end
end

return RbxImGui
