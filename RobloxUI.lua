-- ============================================================
-- RbxImGui | Lightweight ImGui-style UI Library for Roblox
-- ============================================================

local RbxImGui = {}
RbxImGui.__index = RbxImGui

local TabBuilder = {}
TabBuilder.__index = TabBuilder

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

-- ── Theme ─────────────────────────────────────────────────────
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
	DropdownBg      = Color3.fromRGB(32,  32,  44),
	DropdownBorder  = Color3.fromRGB(65,  65,  95),
	DropdownHover   = Color3.fromRGB(48,  48,  68),
	DropdownItemSel = Color3.fromRGB(82,  130, 255),
	DropdownText    = Color3.fromRGB(210, 210, 225),
	DropdownArrow   = Color3.fromRGB(140, 160, 255),
	PickerBg        = Color3.fromRGB(24,  24,  34),
	PickerBorder    = Color3.fromRGB(65,  65,  95),
}

-- ── Defaults ──────────────────────────────────────────────────
local D = {
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
	SliderHeight    = 46,
	CornerRadius    = 6,
	FontSize        = 13,
	ResizeGripSize  = 14,
	DropdownRowH    = 44,   -- label 14 + gap 2 + header 28
	DropdownHeaderH = 28,
	DropdownItemH   = 28,
	ColorRowH       = 28,
}

-- ── Helpers ───────────────────────────────────────────────────
local function tw(o, p, t)
	TweenService:Create(o, TweenInfo.new(t or 0.1, Enum.EasingStyle.Quad), p):Play()
end

local function make(cls, props)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	return o
end

local function corner(r, p)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p
end

local function stroke(col, th, p)
	local s = Instance.new("UIStroke")
	s.Color = col; s.Thickness = th
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p
end

local R = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular,  Enum.FontStyle.Normal)
local S = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
local B = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold,     Enum.FontStyle.Normal)

-- ════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ════════════════════════════════════════════════════════════════
function RbxImGui.new(title, parent)
	local self       = setmetatable({}, RbxImGui)
	self._title      = title or "Window"
	self._tabs       = {}
	self._tabsByName = {}
	self._activeTab  = nil

	if not parent then
		local sg = Instance.new("ScreenGui")
		sg.Name = "RbxImGui_" .. self._title
		sg.ResetOnSpawn   = false
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.DisplayOrder   = 999
		if not pcall(function() sg.Parent = game:GetService("CoreGui") end) then
			sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
		end
		parent = sg
	end
	self._screenGui = parent

	-- Outer window — ClipsDescendants OFF (clip frame handles it)
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

	-- Inner clip frame — visually clips scrollable content
	self._clip = make("Frame", {
		Name                 = "Clip",
		Size                 = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		ClipsDescendants     = true,
		Parent               = self._window,
	})

	-- Title bar
	local tb = make("Frame", {
		Size             = UDim2.new(1, 0, 0, D.TitleBarHeight),
		BackgroundColor3 = THEME.TitleBarBg,
		BorderSizePixel  = 0,
		Parent           = self._clip,
	})
	make("TextLabel", {
		Size                 = UDim2.new(1, -12, 1, 0),
		Position             = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text                 = self._title,
		TextColor3           = THEME.TitleBarText,
		TextSize             = D.FontSize + 1,
		FontFace             = B,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Parent               = tb,
	})

	-- Drag
	local dragging, ds, sp
	tb.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true; ds = i.Position; sp = self._window.Position
		end
	end)
	tb.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - ds
			self._window.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end)

	-- Tab bar
	self._tabBar = make("Frame", {
		Size             = UDim2.new(1, 0, 0, D.TabBarHeight),
		Position         = UDim2.new(0, 0, 0, D.TitleBarHeight),
		BackgroundColor3 = THEME.TabBarBg,
		BorderSizePixel  = 0,
		Parent           = self._clip,
	})
	make("Frame", {
		Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1),
		BackgroundColor3 = THEME.WindowBorder, BorderSizePixel = 0, Parent = self._tabBar,
	})
	local ti = make("Frame", {
		Size = UDim2.new(1,0,1,-1), BackgroundTransparency=1, BorderSizePixel=0, Parent=self._tabBar,
	})
	local tl = Instance.new("UIListLayout")
	tl.FillDirection = Enum.FillDirection.Horizontal
	tl.SortOrder     = Enum.SortOrder.LayoutOrder
	tl.Padding       = UDim.new(0, 4)
	tl.VerticalAlignment = Enum.VerticalAlignment.Center
	tl.Parent        = ti
	local tp = Instance.new("UIPadding")
	tp.PaddingLeft = UDim.new(0,6); tp.PaddingRight = UDim.new(0,6); tp.Parent = ti
	self._tabInner = ti

	-- Content area
	local ct = D.TitleBarHeight + D.TabBarHeight
	self._contentArea = make("Frame", {
		Size                 = UDim2.new(1, 0, 1, -(ct + D.ResizeGripSize)),
		Position             = UDim2.new(0, 0, 0, ct),
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		ClipsDescendants     = true,
		Parent               = self._clip,
	})

	-- Resize grip
	local grip = make("TextButton", {
		Size             = UDim2.new(0, D.ResizeGripSize, 0, D.ResizeGripSize),
		Position         = UDim2.new(1, -D.ResizeGripSize, 1, -D.ResizeGripSize),
		BackgroundColor3 = THEME.ResizeGrip,
		Text="", BorderSizePixel=0, ZIndex=5, AutoButtonColor=false,
		Parent           = self._clip,
	})
	corner(2, grip)
	grip.MouseEnter:Connect(function() tw(grip,{BackgroundColor3=THEME.ResizeGripHover}) end)
	grip.MouseLeave:Connect(function() tw(grip,{BackgroundColor3=THEME.ResizeGrip}) end)
	local resizing, rs, rss
	grip.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing=true; rs=i.Position; rss=self._window.AbsoluteSize
		end
	end)
	grip.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then resizing=false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - rs
			self._window.Size = UDim2.new(0, math.max(D.WindowMinWidth, rss.X+d.X),
				0, math.max(D.WindowMinHeight, rss.Y+d.Y))
		end
	end)

	UserInputService.InputBegan:Connect(function(i, gp)
		if gp then return end
		if i.KeyCode == Enum.KeyCode.Insert then
			self._window.Visible = not self._window.Visible
		end
	end)

	return self
end

-- ════════════════════════════════════════════════════════════════
-- TABS
-- ════════════════════════════════════════════════════════════════
function RbxImGui:AddTab(name)
	local idx = #self._tabs + 1
	local btn = make("TextButton", {
		Size             = UDim2.new(0, math.max(D.TabMinWidth, #name*8+20), 0, 22),
		BackgroundColor3 = THEME.TabBg,
		Text=name, TextColor3=THEME.TabText, TextSize=D.FontSize-1,
		FontFace=S, BorderSizePixel=0, AutoButtonColor=false,
		LayoutOrder=idx, Parent=self._tabInner,
	})
	corner(4, btn)

	local sf = make("ScrollingFrame", {
		Name                 = "SF_"..name,
		Size                 = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		ScrollBarThickness   = 4,
		ScrollBarImageColor3 = THEME.ScrollThumb,
		CanvasSize           = UDim2.new(0,0,0,0),
		AutomaticCanvasSize  = Enum.AutomaticSize.Y,
		Visible              = false,
		Parent               = self._contentArea,
	})
	local ll = Instance.new("UIListLayout")
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Padding   = UDim.new(0, D.ItemSpacing)
	ll.Parent    = sf
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft=UDim.new(0,D.Padding); pad.PaddingRight=UDim.new(0,D.Padding)
	pad.PaddingTop=UDim.new(0,D.Padding); pad.PaddingBottom=UDim.new(0,D.Padding)
	pad.Parent = sf

	local td = {name=name, items={}, scrollFrame=sf, tabBtn=btn}
	self._tabs[idx]        = td
	self._tabsByName[name] = td

	btn.MouseButton1Click:Connect(function() self:_switchTab(name) end)
	btn.MouseEnter:Connect(function()
		if self._activeTab ~= name then tw(btn,{BackgroundColor3=THEME.TabHover}) end
	end)
	btn.MouseLeave:Connect(function()
		if self._activeTab ~= name then tw(btn,{BackgroundColor3=THEME.TabBg}) end
	end)
	if idx == 1 then self:_switchTab(name) end
	return self
end

function RbxImGui:_switchTab(name)
	self._activeTab = name
	for _, td in ipairs(self._tabs) do
		local a = td.name == name
		td.scrollFrame.Visible = a
		tw(td.tabBtn, {
			BackgroundColor3 = a and THEME.TabActive or THEME.TabBg,
			TextColor3       = a and THEME.TabTextActive or THEME.TabText,
		})
	end
end

function RbxImGui:Tab(name)
	assert(self._tabsByName[name], "Tab '"..tostring(name).."' not found.")
	local b = setmetatable({}, TabBuilder)
	b._tabData   = self._tabsByName[name]
	b._screenGui = self._screenGui
	return b
end

-- ════════════════════════════════════════════════════════════════
-- WIDGETS
-- ════════════════════════════════════════════════════════════════

local function addLabel(td, text)
	table.insert(td.items, function(parent, order)
		make("TextLabel", {
			Size=UDim2.new(1,0,0,20), BackgroundTransparency=1,
			Text=text, TextColor3=THEME.TextColor, TextSize=D.FontSize,
			FontFace=R, TextXAlignment=Enum.TextXAlignment.Left,
			LayoutOrder=order, Parent=parent,
		})
	end)
end

local function addSeparator(td)
	table.insert(td.items, function(parent, order)
		make("Frame", {
			Size=UDim2.new(1,0,0,1), BackgroundColor3=THEME.SeparatorColor,
			BorderSizePixel=0, LayoutOrder=order, Parent=parent,
		})
	end)
end

local function addButton(td, label, cb)
	table.insert(td.items, function(parent, order)
		local btn = make("TextButton", {
			Size=UDim2.new(1,0,0,D.ButtonHeight), BackgroundColor3=THEME.ButtonBg,
			Text=label, TextColor3=THEME.ButtonText, TextSize=D.FontSize,
			FontFace=S, BorderSizePixel=0, AutoButtonColor=false,
			LayoutOrder=order, Parent=parent,
		})
		corner(D.CornerRadius-2, btn)
		stroke(Color3.fromRGB(65,65,90), 1, btn)
		btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=THEME.ButtonHover}) end)
		btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=THEME.ButtonBg}) end)
		btn.MouseButton1Down:Connect(function() tw(btn,{BackgroundColor3=THEME.ButtonActive},0.07) end)
		btn.MouseButton1Up:Connect(function()
			tw(btn,{BackgroundColor3=THEME.ButtonHover},0.07)
			if cb then cb() end
		end)
	end)
end

local function addToggle(td, label, default, cb)
	local state = default or false
	table.insert(td.items, function(parent, order)
		local row = make("Frame", {
			Size=UDim2.new(1,0,0,D.ToggleHeight), BackgroundTransparency=1,
			LayoutOrder=order, Parent=parent,
		})
		make("TextLabel", {
			Size=UDim2.new(1,-50,1,0), BackgroundTransparency=1,
			Text=label, TextColor3=THEME.ToggleText, TextSize=D.FontSize,
			FontFace=R, TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
		})
		local tW,tH = 36,18
		local track = make("Frame", {
			Size=UDim2.new(0,tW,0,tH), Position=UDim2.new(1,-tW,0.5,-tH/2),
			BackgroundColor3=state and THEME.ToggleOn or THEME.ToggleOff,
			BorderSizePixel=0, Parent=row,
		})
		corner(tH/2, track)
		local kS = tH-4
		local knob = make("Frame", {
			Size=UDim2.new(0,kS,0,kS),
			Position=state and UDim2.new(0,tW-kS-2,0.5,-kS/2) or UDim2.new(0,2,0.5,-kS/2),
			BackgroundColor3=THEME.ToggleKnob, BorderSizePixel=0, Parent=track,
		})
		corner(kS/2, knob)
		local click = make("TextButton", {
			Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
			Text="", AutoButtonColor=false, Parent=row,
		})
		click.MouseButton1Click:Connect(function()
			state = not state
			tw(track,{BackgroundColor3=state and THEME.ToggleOn or THEME.ToggleOff})
			tw(knob,{Position=state and UDim2.new(0,tW-kS-2,0.5,-kS/2) or UDim2.new(0,2,0.5,-kS/2)})
			if cb then cb(state) end
		end)
	end)
end

local function addSlider(td, label, mn, mx, default, cb)
	mn = mn or 0; mx = mx or 100; default = default or mn
	local value = math.clamp(default, mn, mx)
	table.insert(td.items, function(parent, order)
		local col = make("Frame", {
			Size=UDim2.new(1,0,0,D.SliderHeight), BackgroundTransparency=1,
			LayoutOrder=order, Parent=parent,
		})
		local hdr = make("Frame", {Size=UDim2.new(1,0,0,16), BackgroundTransparency=1, Parent=col})
		make("TextLabel", {
			Size=UDim2.new(0.6,0,1,0), BackgroundTransparency=1,
			Text=label, TextColor3=THEME.SliderText, TextSize=D.FontSize,
			FontFace=R, TextXAlignment=Enum.TextXAlignment.Left, Parent=hdr,
		})
		local vl = make("TextLabel", {
			Size=UDim2.new(0.4,0,1,0), Position=UDim2.new(0.6,0,0,0),
			BackgroundTransparency=1, Text=tostring(math.floor(value)),
			TextColor3=THEME.SliderValue, TextSize=D.FontSize, FontFace=B,
			TextXAlignment=Enum.TextXAlignment.Right, Parent=hdr,
		})
		local tH = 6
		local track = make("Frame", {
			Size=UDim2.new(1,0,0,tH),
			Position=UDim2.new(0,0,0,16+(D.SliderHeight-16-tH)/2),
			BackgroundColor3=THEME.SliderTrack, BorderSizePixel=0, Parent=col,
		})
		corner(tH/2, track)
		local pct = (value-mn)/(mx-mn)
		local fill = make("Frame", {
			Size=UDim2.new(pct,0,1,0), BackgroundColor3=THEME.SliderFill,
			BorderSizePixel=0, Parent=track,
		})
		corner(tH/2, fill)
		local kS = 14
		local knob = make("Frame", {
			Size=UDim2.new(0,kS,0,kS), Position=UDim2.new(pct,-kS/2,0.5,-kS/2),
			BackgroundColor3=THEME.SliderKnob, BorderSizePixel=0, ZIndex=2, Parent=track,
		})
		corner(kS/2, knob); stroke(THEME.SliderFill, 2, knob)
		local drag = make("TextButton", {
			Size=UDim2.new(1,0,0,D.SliderHeight-16),
			Position=UDim2.new(0,0,0,16),
			BackgroundTransparency=1, Text="", ZIndex=3, AutoButtonColor=false, Parent=col,
		})
		local function upd(x)
			local p = math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
			value = mn + p*(mx-mn)
			vl.Text=tostring(math.floor(value))
			fill.Size=UDim2.new(p,0,1,0)
			knob.Position=UDim2.new(p,-kS/2,0.5,-kS/2)
			if cb then cb(math.floor(value)) end
		end
		local sliding=false
		drag.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true; upd(i.Position.X) end
		end)
		drag.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- DROPDOWN  (v3)
--
-- FIX: The floating menu position is updated every RenderStepped
-- frame while it is open, so it tracks the header perfectly when
-- the user scrolls the tab content.
-- ════════════════════════════════════════════════════════════════
local function addDropdown(td, screenGui, label, options, default, cb)
	assert(type(options)=="table" and #options>0, "Dropdown: options must be non-empty")
	local selected = default or options[1]

	table.insert(td.items, function(parent, order)
		local ROW_H = D.DropdownRowH    -- 44
		local HDR_H = D.DropdownHeaderH -- 28
		local ITM_H = D.DropdownItemH   -- 28

		local container = make("Frame", {
			Name="DD_"..order, Size=UDim2.new(1,0,0,ROW_H),
			BackgroundTransparency=1, ClipsDescendants=false,
			LayoutOrder=order, Parent=parent,
		})

		make("TextLabel", {
			Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,0),
			BackgroundTransparency=1, Text=label,
			TextColor3=THEME.ToggleText, TextSize=D.FontSize-1,
			FontFace=R, TextXAlignment=Enum.TextXAlignment.Left,
			Parent=container,
		})

		local header = make("TextButton", {
			Size=UDim2.new(1,0,0,HDR_H), Position=UDim2.new(0,0,0,16),
			BackgroundColor3=THEME.DropdownBg, Text="",
			BorderSizePixel=0, AutoButtonColor=false, Parent=container,
		})
		corner(4, header)
		stroke(THEME.DropdownBorder, 1, header)

		local selLabel = make("TextLabel", {
			Size=UDim2.new(1,-34,1,0), Position=UDim2.new(0,10,0,0),
			BackgroundTransparency=1, Text=selected,
			TextColor3=THEME.DropdownText, TextSize=D.FontSize,
			FontFace=S, TextXAlignment=Enum.TextXAlignment.Left,
			Parent=header,
		})

		-- Arrow: plain TextLabel, no background at all
		local arrow = make("TextLabel", {
			Size=UDim2.new(0,24,1,0), Position=UDim2.new(1,-26,0,0),
			BackgroundTransparency=1, Text="▾",
			TextColor3=THEME.DropdownArrow, TextSize=D.FontSize,
			FontFace=B, TextXAlignment=Enum.TextXAlignment.Center,
			Parent=header,
		})

		-- Floating menu parented to ScreenGui so it's never clipped
		local menuH = #options * ITM_H + 8
		local menu = make("Frame", {
			Name="DDMenu_"..order,
			Size=UDim2.new(0,200,0,menuH),
			Position=UDim2.new(0,0,0,0),
			BackgroundColor3=THEME.DropdownBg,
			BorderSizePixel=0, Visible=false, ZIndex=50,
			Parent=screenGui,
		})
		corner(6, menu)
		stroke(THEME.DropdownBorder, 1, menu)

		local mPad = Instance.new("UIPadding")
		mPad.PaddingTop=UDim.new(0,4); mPad.PaddingBottom=UDim.new(0,4)
		mPad.PaddingLeft=UDim.new(0,4); mPad.PaddingRight=UDim.new(0,4)
		mPad.Parent = menu

		local mLayout = Instance.new("UIListLayout")
		mLayout.SortOrder = Enum.SortOrder.LayoutOrder
		mLayout.Padding   = UDim.new(0,2)
		mLayout.Parent    = menu

		for i, opt in ipairs(options) do
			local isSel = (opt == selected)
			local item = make("TextButton", {
				Name="Item_"..i,
				Size=UDim2.new(1,0,0,ITM_H),
				BackgroundColor3=isSel and THEME.DropdownItemSel or THEME.DropdownBg,
				Text="", BorderSizePixel=0, AutoButtonColor=false,
				LayoutOrder=i, ZIndex=51, Parent=menu,
			})
			corner(4, item)
			local iLbl = make("TextLabel", {
				Size=UDim2.new(1,-10,1,0), Position=UDim2.new(0,8,0,0),
				BackgroundTransparency=1, Text=opt,
				TextColor3=isSel and Color3.fromRGB(255,255,255) or THEME.DropdownText,
				TextSize=D.FontSize, FontFace=isSel and S or R,
				TextXAlignment=Enum.TextXAlignment.Left,
				ZIndex=52, Parent=item,
			})
			item.MouseEnter:Connect(function()
				if opt ~= selected then tw(item,{BackgroundColor3=THEME.DropdownHover}) end
			end)
			item.MouseLeave:Connect(function()
				if opt ~= selected then tw(item,{BackgroundColor3=THEME.DropdownBg}) end
			end)
			item.MouseButton1Click:Connect(function()
				for _, ch in ipairs(menu:GetChildren()) do
					if ch:IsA("TextButton") then
						ch.BackgroundColor3 = THEME.DropdownBg
						local l = ch:FindFirstChildOfClass("TextLabel")
						if l then l.TextColor3=THEME.DropdownText; l.FontFace=R end
					end
				end
				item.BackgroundColor3 = THEME.DropdownItemSel
				iLbl.TextColor3 = Color3.fromRGB(255,255,255); iLbl.FontFace = S
				selected       = opt
				selLabel.Text  = opt
				menu.Visible   = false
				arrow.Text     = "▾"
				if cb then cb(opt) end
			end)
		end

		local open = false

		-- Reposition the menu to match the header's current screen position.
		-- Called every frame while open so scrolling keeps it in sync.
		local function updateMenuPos()
			local ap = header.AbsolutePosition
			local as = header.AbsoluteSize
			menu.Size     = UDim2.new(0, as.X, 0, menuH)
			menu.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 2)
		end

		local trackConn = nil

		local function openMenu()
			updateMenuPos()
			menu.Visible = true
			arrow.Text   = "▴"
			open         = true
			-- Update position each frame so scrolling keeps menu attached
			trackConn = RunService.RenderStepped:Connect(function()
				if open and menu.Visible then
					updateMenuPos()
				end
			end)
		end

		local function closeMenu()
			menu.Visible = false
			arrow.Text   = "▾"
			open         = false
			if trackConn then trackConn:Disconnect(); trackConn = nil end
		end

		header.MouseButton1Click:Connect(function()
			if open then closeMenu() else openMenu() end
		end)
		header.MouseEnter:Connect(function() tw(header,{BackgroundColor3=THEME.DropdownHover}) end)
		header.MouseLeave:Connect(function() tw(header,{BackgroundColor3=THEME.DropdownBg}) end)

		-- Click outside to close
		UserInputService.InputBegan:Connect(function(inp)
			if not open then return end
			if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			local mp = inp.Position
			local function inside(f)
				local p,sz = f.AbsolutePosition, f.AbsoluteSize
				return mp.X>=p.X and mp.X<=p.X+sz.X and mp.Y>=p.Y and mp.Y<=p.Y+sz.Y
			end
			if not inside(menu) and not inside(header) then closeMenu() end
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- COLOR PICKER  (v3)
--
-- FIX 1 — Toggle: the picker is an inline frame whose height
-- is controlled by a wrapping Frame that the UIListLayout sees.
-- The outer wrapper has a FIXED height that we swap between
-- collapsed (28px) and expanded (28+gap+panelH). The inner
-- content never fights the layout engine.
--
-- FIX 2 — SV gradient: the white and black overlays must NOT
-- both sit at ZIndex 10/11 fighting each other.  Instead we use
-- a single flat Frame per axis:
--   • White layer:  ZIndex 10, white color, left→right transparency
--   • Black layer:  ZIndex 11, black color, top→bottom transparency
-- The key insight is that both layers must have ClipsDescendants=false
-- on their parent so the gradients render correctly, and the black
-- layer must genuinely be transparent at the top — meaning its
-- BackgroundTransparency drives nothing; only the UIGradient does.
-- The SV base has ClipsDescendants=true to keep the knob inside.
-- ════════════════════════════════════════════════════════════════
local function addColorPicker(td, label, defaultColor, cb)
	defaultColor = defaultColor or Color3.fromRGB(255, 50, 50)
	local h, s, v = Color3.toHSV(defaultColor)

	-- Picker layout constants
	local PAD    = 8
	local SQ_H   = 120
	local BAR_H  = 16
	local PREV_H = 14
	local GAP    = 6
	local panelH = PAD + SQ_H + GAP + BAR_H + GAP + PREV_H + PAD

	local ROW_H      = D.ColorRowH  -- 28  (the header row)
	local CLOSED_H   = ROW_H
	local OPEN_H     = ROW_H + GAP + panelH

	table.insert(td.items, function(parent, order)

		-- Wrapper: this is what the UIListLayout measures.
		-- Its height is swapped between CLOSED_H and OPEN_H.
		local wrapper = make("Frame", {
			Name             = "CP_"..order,
			Size             = UDim2.new(1, 0, 0, CLOSED_H),
			BackgroundTransparency = 1,
			ClipsDescendants = false,
			LayoutOrder      = order,
			Parent           = parent,
		})

		-- ── Header row ────────────────────────────────────────────
		local headerRow = make("Frame", {
			Size             = UDim2.new(1,0,0,ROW_H),
			BackgroundTransparency = 1,
			Parent           = wrapper,
		})

		make("TextLabel", {
			Size=UDim2.new(1,-40,1,0), Position=UDim2.new(0,0,0,0),
			BackgroundTransparency=1, Text=label,
			TextColor3=THEME.ToggleText, TextSize=D.FontSize,
			FontFace=R, TextXAlignment=Enum.TextXAlignment.Left,
			Parent=headerRow,
		})

		-- Swatch button (right side of header row)
		local swatch = make("TextButton", {
			Size=UDim2.new(0,30,0,20), Position=UDim2.new(1,-30,0.5,-10),
			BackgroundColor3=defaultColor, Text="",
			BorderSizePixel=0, AutoButtonColor=false,
			Parent=headerRow,
		})
		corner(4, swatch)
		stroke(THEME.DropdownBorder, 1, swatch)

		-- ── Picker panel ──────────────────────────────────────────
		local panel = make("Frame", {
			Name             = "Panel",
			Size             = UDim2.new(1,0,0,panelH),
			Position         = UDim2.new(0,0,0,ROW_H + GAP),
			BackgroundColor3 = THEME.PickerBg,
			BorderSizePixel  = 0,
			Visible          = false,
			ZIndex           = 8,
			Parent           = wrapper,
		})
		corner(6, panel)
		stroke(THEME.PickerBorder, 1, panel)

		-- ── SV square ─────────────────────────────────────────────
		-- Pure-hue background. ClipsDescendants=true keeps the knob inside.
		local svBase = make("Frame", {
			Size=UDim2.new(1,-(PAD*2),0,SQ_H),
			Position=UDim2.new(0,PAD,0,PAD),
			BackgroundColor3=Color3.fromHSV(h,1,1),
			BorderSizePixel=0, ClipsDescendants=true,
			ZIndex=9, Parent=panel,
		})
		corner(4, svBase)

		-- White→transparent overlay  (left = white opaque, right = transparent)
		-- Simulates the saturation axis.
		local wLayer = make("Frame", {
			Size=UDim2.new(1,0,1,0),
			BackgroundColor3=Color3.fromRGB(255,255,255),
			BorderSizePixel=0, ZIndex=10, Parent=svBase,
		})
		do
			local g = Instance.new("UIGradient")
			g.Rotation = 0
			g.Color    = ColorSequence.new(
				Color3.fromRGB(255,255,255),
				Color3.fromRGB(255,255,255))
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),  -- left: fully opaque white
				NumberSequenceKeypoint.new(1, 1),  -- right: fully transparent
			})
			g.Parent = wLayer
		end

		-- Transparent→black overlay  (top = transparent, bottom = black)
		-- Simulates the value axis.
		-- IMPORTANT: BackgroundTransparency=1 here so the Frame itself
		-- contributes nothing — only the UIGradient draws the gradient.
		local bLayer = make("Frame", {
			Size=UDim2.new(1,0,1,0),
			BackgroundColor3=Color3.fromRGB(0,0,0),
			BackgroundTransparency=1,   -- frame is invisible; gradient draws it
			BorderSizePixel=0, ZIndex=11, Parent=svBase,
		})
		do
			local g = Instance.new("UIGradient")
			g.Rotation = 90  -- rotated: keypoint 0 = left (top after rotation)
			g.Color    = ColorSequence.new(
				Color3.fromRGB(0,0,0),
				Color3.fromRGB(0,0,0))
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),  -- top: transparent
				NumberSequenceKeypoint.new(1, 0),  -- bottom: fully opaque black
			})
			g.Parent = bLayer
		end

		-- SV crosshair knob
		local svKnob = make("Frame", {
			Size=UDim2.new(0,12,0,12),
			Position=UDim2.new(s,-6,1-v,-6),
			BackgroundColor3=Color3.fromRGB(255,255,255),
			BorderSizePixel=0, ZIndex=13, Parent=svBase,
		})
		corner(6, svKnob)
		stroke(Color3.fromRGB(0,0,0), 1.5, svKnob)

		local svDrag = make("TextButton", {
			Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
			Text="", AutoButtonColor=false, ZIndex=14, Parent=svBase,
		})

		-- ── Hue bar ───────────────────────────────────────────────
		local hueY = PAD + SQ_H + GAP

		local hueBar = make("Frame", {
			Size=UDim2.new(1,-(PAD*2),0,BAR_H),
			Position=UDim2.new(0,PAD,0,hueY),
			BackgroundColor3=Color3.fromRGB(255,0,0),
			BorderSizePixel=0, ZIndex=9, Parent=panel,
		})
		corner(4, hueBar)

		do
			local g = Instance.new("UIGradient")
			g.Rotation = 0
			g.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0/6, Color3.fromRGB(255,  0,  0)),
				ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255,255,  0)),
				ColorSequenceKeypoint.new(2/6, Color3.fromRGB(  0,255,  0)),
				ColorSequenceKeypoint.new(3/6, Color3.fromRGB(  0,255,255)),
				ColorSequenceKeypoint.new(4/6, Color3.fromRGB(  0,  0,255)),
				ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255,  0,255)),
				ColorSequenceKeypoint.new(6/6, Color3.fromRGB(255,  0,  0)),
			})
			g.Parent = hueBar
		end

		local hueKnob = make("Frame", {
			Size=UDim2.new(0,4,1,4),
			Position=UDim2.new(h,-2,0,-2),
			BackgroundColor3=Color3.fromRGB(255,255,255),
			BorderSizePixel=0, ZIndex=12, Parent=hueBar,
		})
		corner(2, hueKnob)
		stroke(Color3.fromRGB(0,0,0), 1, hueKnob)

		local hueDrag = make("TextButton", {
			Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
			Text="", AutoButtonColor=false, ZIndex=13, Parent=hueBar,
		})

		-- ── Preview strip ─────────────────────────────────────────
		local prevY = hueY + BAR_H + GAP

		local preview = make("Frame", {
			Size=UDim2.new(1,-(PAD*2),0,PREV_H),
			Position=UDim2.new(0,PAD,0,prevY),
			BackgroundColor3=defaultColor,
			BorderSizePixel=0, ZIndex=9, Parent=panel,
		})
		corner(4, preview)
		stroke(THEME.PickerBorder, 1, preview)

		-- ── Shared color apply ────────────────────────────────────
		local function apply()
			local c = Color3.fromHSV(h, s, v)
			svBase.BackgroundColor3  = Color3.fromHSV(h, 1, 1)
			svKnob.Position          = UDim2.new(s, -6, 1-v, -6)
			hueKnob.Position         = UDim2.new(h, -2, 0, -2)
			swatch.BackgroundColor3  = c
			preview.BackgroundColor3 = c
			if cb then cb(c) end
		end

		-- SV drag
		local svDragging = false
		local function readSV(inp)
			s = math.clamp((inp.Position.X-svBase.AbsolutePosition.X)/svBase.AbsoluteSize.X, 0,1)
			v = 1 - math.clamp((inp.Position.Y-svBase.AbsolutePosition.Y)/svBase.AbsoluteSize.Y, 0,1)
			apply()
		end
		svDrag.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 then svDragging=true; readSV(i) end
		end)
		svDrag.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 then svDragging=false end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if svDragging and i.UserInputType==Enum.UserInputType.MouseMovement then readSV(i) end
		end)

		-- Hue drag
		local hueDragging = false
		local function readHue(inp)
			h = math.clamp((inp.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X, 0,1)
			apply()
		end
		hueDrag.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 then hueDragging=true; readHue(i) end
		end)
		hueDrag.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 then hueDragging=false end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if hueDragging and i.UserInputType==Enum.UserInputType.MouseMovement then readHue(i) end
		end)

		-- ── Open / close ─────────────────────────────────────────
		-- We resize the WRAPPER (what the layout sees) and toggle
		-- panel visibility. The layout engine sees a height change
		-- on the wrapper and reflows accordingly. Nothing fights it.
		local isOpen = false

		swatch.MouseButton1Click:Connect(function()
			isOpen        = not isOpen
			panel.Visible = isOpen
			wrapper.Size  = UDim2.new(1, 0, 0, isOpen and OPEN_H or CLOSED_H)
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- BINDINGS
-- ════════════════════════════════════════════════════════════════
function TabBuilder:Label(t)                addLabel(self._tabData,t);                                              return self end
function TabBuilder:Separator()             addSeparator(self._tabData);                                            return self end
function TabBuilder:Button(l,cb)            addButton(self._tabData,l,cb);                                          return self end
function TabBuilder:Toggle(l,d,cb)          addToggle(self._tabData,l,d,cb);                                        return self end
function TabBuilder:Slider(l,mn,mx,d,cb)    addSlider(self._tabData,l,mn,mx,d,cb);                                  return self end
function TabBuilder:Dropdown(l,opts,def,cb) addDropdown(self._tabData,self._screenGui,l,opts,def,cb);               return self end
function TabBuilder:ColorPicker(l,col,cb)   addColorPicker(self._tabData,l,col,cb);                                 return self end

local function ensureDefault(self)
	if not self._tabsByName["__default"] then
		self:AddTab("__default")
		self._tabsByName["__default"].tabBtn.Visible = false
		self._tabBar.Visible = false
		self._contentArea.Position = UDim2.new(0,0,0,D.TitleBarHeight)
		self._contentArea.Size     = UDim2.new(1,0,1,-(D.TitleBarHeight+D.ResizeGripSize))
	end
	local t = self._tabsByName["__default"]
	t._screenGui = self._screenGui
	return t
end

function RbxImGui:Label(t)                addLabel(ensureDefault(self),t);                                                  return self end
function RbxImGui:Separator()             addSeparator(ensureDefault(self));                                                return self end
function RbxImGui:Button(l,cb)            addButton(ensureDefault(self),l,cb);                                              return self end
function RbxImGui:Toggle(l,d,cb)          addToggle(ensureDefault(self),l,d,cb);                                            return self end
function RbxImGui:Slider(l,mn,mx,d,cb)    addSlider(ensureDefault(self),l,mn,mx,d,cb);                                      return self end
function RbxImGui:Dropdown(l,opts,def,cb) addDropdown(ensureDefault(self),self._screenGui,l,opts,def,cb);                   return self end
function RbxImGui:ColorPicker(l,col,cb)   addColorPicker(ensureDefault(self),l,col,cb);                                     return self end

function RbxImGui:Render()
	for _, td in ipairs(self._tabs) do
		td._screenGui = self._screenGui
		for i, builder in ipairs(td.items) do
			builder(td.scrollFrame, i)
		end
	end
end

function RbxImGui:Show()          self._window.Visible = true  end
function RbxImGui:Hide()          self._window.Visible = false end
function RbxImGui:Toggle_Window() self._window.Visible = not self._window.Visible end
function RbxImGui:Destroy()       if self._screenGui then self._screenGui:Destroy() end end

return RbxImGui
