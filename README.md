# RbxImGui

A lightweight, ImGui-style UI library for Roblox. Create draggable, resizable windows with a **tabbed navigation bar** — Aimbot, Visuals, Misc, or any tabs you want — plus buttons, toggles, sliders, and labels. Renders into `CoreGui` so it survives respawns and sits above all in-game UI.

> **Toggle visibility:** Press `Insert` at any time to show or hide the window.

---
![Image #1](https://i.imgur.com/hZnUQCI.png)
---

## Table of Contents

- [What It Looks Like](#what-it-looks-like)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Tab System](#tab-system)
  - [win:AddTab()](#winaddtab)
  - [win:Tab()](#wintab)
  - [Single-window (no tabs)](#single-window-no-tabs)
- [Widget API](#widget-api)
  - [:Label()](#label)
  - [:Separator()](#separator)
  - [:Button()](#button)
  - [:Toggle()](#toggle)
  - [:Slider()](#slider)
- [Window API](#window-api)
  - [RbxImGui.new()](#rbximguinew)
  - [win:Render()](#winrender)
  - [win:Show() / win:Hide()](#winshow--winhide)
  - [win:Toggle_Window()](#wintoggle_window)
  - [win:Destroy()](#windestroy)
- [Showcase Example](#showcase-example)
- [Feature Deep Dive & Possibilities](#feature-deep-dive--possibilities)
- [Theming](#theming)
- [Defaults](#defaults)
- [Rules & Gotchas](#rules--gotchas)
- [Loading from GitHub](#loading-from-github)

---

## What It Looks Like

```
┌──────────────────────────────────┐
│  Player Mods                     │  ← Title bar (drag to move)
├──────────────────────────────────┤
│ [Aimbot] [Visuals] [Misc]        │  ← Tab bar (click to switch)
├──────────────────────────────────┤
│                                  │
│  Movement                        │  ← Label
│ ─────────────────────────────    │  ← Separator
│  Walk Speed               16     │  ← Slider
│  [████●────────────────────]     │
│  Jump Power               50     │
│  [══════════●──────────────]     │
│                                  │
│  Toggles                         │
│ ─────────────────────────────    │
│  Noclip            [ ●   ]       │  ← Toggle OFF
│  God Mode          [   ● ]       │  ← Toggle ON
│                                  │
│ [ Reset Character              ] │  ← Button
│                                  │
└──────────────────────────────[◢] ┘  ← Resize grip
```

The **active tab button turns blue**. Inactive tabs are dark grey. Clicking a tab instantly swaps the content area — each tab has its own independent scroll position.

The window is:
- **Draggable** — click and hold the title bar
- **Resizable** — drag the bottom-right grip
- **Scrollable** — each tab scrolls independently if content overflows
- **Togglable** — press `Insert` to show/hide

---

## Installation

**Option A — ModuleScript (recommended)**

1. Create a `ModuleScript` in `ReplicatedStorage`, name it `RobloxUI`
2. Paste `RobloxUI.lua` into it
3. Require it from a `LocalScript` under `StarterPlayer > StarterPlayerScripts`

```
ReplicatedStorage
  └── RobloxUI              ← ModuleScript

StarterPlayer
  └── StarterPlayerScripts
        └── MyScript        ← LocalScript
```

**Option B — loadstring from GitHub**

```lua
local RbxImGui = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPO/main/RobloxUI.lua"
))()
```

> Requires **Allow HTTP Requests** in Game Settings → Security.

---

## Quick Start

```lua
local RbxImGui = require(game.ReplicatedStorage.RobloxUI)

local win = RbxImGui.new("Player Mods")

-- Register tabs first
win:AddTab("Aimbot")
win:AddTab("Visuals")
win:AddTab("Misc")

-- Add widgets to each tab using win:Tab("Name"):WidgetMethod(...)
win:Tab("Aimbot"):Toggle("Silent Aim", false, function(on)
    print("Silent Aim:", on)
end)

win:Tab("Visuals"):Slider("FOV", 30, 120, 70, function(v)
    workspace.CurrentCamera.FieldOfView = v
end)

win:Tab("Misc"):Button("Reset Character", function()
    game.Players.LocalPlayer.Character:BreakJoints()
end)

win:Render()
```

---

## How It Works

RbxImGui uses a **deferred build pattern**:

```
RbxImGui.new()      → creates window shell + tab bar immediately
:AddTab("Name")     → registers a tab and its scroll frame
:Tab("Name"):...    → queues widget builders into that tab
:Render()           → runs all builders across all tabs at once
```

Widgets are not created until `:Render()` is called. After `:Render()`, you cannot add new widgets.

**Method chaining** is supported on both the window and on tab builders:

```lua
-- Chain AddTab calls
win:AddTab("A"):AddTab("B"):AddTab("C")

-- Chain widgets on a tab
win:Tab("A"):Label("hello"):Separator():Button("go", cb)

-- Full chain including Render
win:AddTab("A"):AddTab("B")
win:Tab("A"):Toggle("X", false, cb):Slider("Y", 0, 100, 50, cb)
win:Tab("B"):Button("Z", cb)
win:Render()
```

---

## Tab System

---

### `win:AddTab(name)`

Registers a new tab. Creates a tab button in the tab bar and a dedicated `ScrollingFrame` for that tab's content. The first tab added is automatically set as active.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | `string` | The tab label shown in the tab bar. Also used as the key for `win:Tab()`. |

**Returns:** `self` (the window) for chaining

```lua
win:AddTab("Aimbot")
win:AddTab("Visuals")
win:AddTab("Misc")
win:AddTab("Player")
win:AddTab("World")
```

Tab button widths auto-size based on the length of the name (minimum 60px). There is no hard limit on the number of tabs — if there are too many to fit, consider shortening names.

---

### `win:Tab(name)`

Returns a **TabBuilder** scoped to the named tab. All widget methods (`:Label()`, `:Button()`, etc.) are called on this object to add widgets to that specific tab.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | `string` | Must match a name previously passed to `:AddTab()`. Throws an error if the tab doesn't exist. |

**Returns:** TabBuilder object

```lua
-- All three of these are equivalent patterns:

-- Pattern 1: separate lines
win:Tab("Aimbot"):Toggle("Silent Aim", false, cb)
win:Tab("Aimbot"):Slider("FOV", 30, 120, 70, cb)

-- Pattern 2: chain on the tab builder
win:Tab("Aimbot")
    :Toggle("Silent Aim", false, cb)
    :Slider("FOV", 30, 120, 70, cb)
    :Button("Reset", cb)

-- Pattern 3: store the tab builder
local aimTab = win:Tab("Aimbot")
aimTab:Toggle("Silent Aim", false, cb)
aimTab:Slider("FOV", 30, 120, 70, cb)
```

---

### Single-window (no tabs)

If you never call `:AddTab()`, the library works exactly like the old single-panel mode. You can call widget methods directly on the window object. The tab bar is automatically hidden.

```lua
local win = RbxImGui.new("Simple Panel")

win:Label("Controls")
win:Button("Click Me", function() end)
win:Toggle("Enable", false, function(v) end)
win:Slider("Speed", 0, 100, 16, function(v) end)

win:Render()
```

---

## Widget API

All widget methods work identically whether called on `win:Tab("Name")` or directly on `win` (no-tab mode).

---

### `:Label(text)`

Adds a static text label.

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | `string` | The text to display. |

**Height:** 20px

```lua
win:Tab("Misc"):Label("Version 1.0")
```

---

### `:Separator()`

Adds a 1px horizontal dividing line. No parameters.

**Height:** 1px

```lua
win:Tab("Aimbot"):Label("Combat"):Separator()
```

---

### `:Button(label, callback)`

Adds a full-width clickable button.

| Parameter | Type | Description |
|-----------|------|-------------|
| `label` | `string` | Text on the button. |
| `callback` | `function()` | Called with no arguments on click. Can be `nil`. |

**Height:** 28px

Fires on `MouseButton1Up` (release). Hover and hold states animate via TweenService.

```lua
win:Tab("Misc"):Button("Teleport Home", function()
    game.Players.LocalPlayer.Character
        :SetPrimaryPartCFrame(CFrame.new(0, 10, 0))
end)
```

---

### `:Toggle(label, defaultValue, callback)`

Adds an on/off switch with an animated sliding knob.

| Parameter | Type | Description |
|-----------|------|-------------|
| `label` | `string` | Text to the left of the switch. |
| `defaultValue` | `boolean` | Starting state. `true` = on, `false` = off. |
| `callback` | `function(newValue: boolean)` | Fires on every click with the new state. |

**Height:** 24px

```lua
win:Tab("Aimbot"):Toggle("Silent Aim", false, function(on)
    -- on = true when enabled, false when disabled
end)
```

---

### `:Slider(label, min, max, default, callback)`

Adds a horizontal drag slider.

| Parameter | Type | Description |
|-----------|------|-------------|
| `label` | `string` | Text above the track. |
| `min` | `number` | Left-end value. |
| `max` | `number` | Right-end value. |
| `default` | `number` | Starting value. Clamped to `[min, max]`. |
| `callback` | `function(value: number)` | Fires while dragging. Always a whole integer. |

**Height:** 46px

```lua
win:Tab("Visuals"):Slider("FOV", 30, 120, 70, function(v)
    workspace.CurrentCamera.FieldOfView = v
end)
```

---

## Window API

---

### `RbxImGui.new(title, parent?)`

Creates the window. Returns the window object.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `title` | `string` | Yes | Title bar text. Also names the ScreenGui. |
| `parent` | `Instance` | No | Override parent. Leave `nil` for auto CoreGui. |

**Creates automatically:** ScreenGui in CoreGui (fallback: PlayerGui), draggable window frame, title bar, tab bar, content area, resize grip, Insert key listener.

---

### `win:Render()`

Builds all widgets across all tabs. Call **once**, after all `:AddTab()` and widget declarations.

```lua
win:AddTab("A"):AddTab("B")
win:Tab("A"):Button("x", cb)
win:Tab("B"):Toggle("y", false, cb)
win:Render()  -- always last
```

---

### `win:Show() / win:Hide()`

```lua
win:Hide()  -- hidden on startup; player opens with Insert
win:Show()  -- force visible
```

---

### `win:Toggle_Window()`

Flips visibility. Same as the Insert key.

---

### `win:Destroy()`

Destroys the entire ScreenGui and all contents.

---

## Showcase Example

Full demo using tabs and every widget type. Copy into a `LocalScript` under `StarterPlayer > StarterPlayerScripts`.

```lua
-- ================================================================
--  RbxImGui Showcase  |  LocalScript → StarterPlayerScripts
-- ================================================================
local RbxImGui = require(game.ReplicatedStorage.RobloxUI)
local Players  = game:GetService("Players")
local RS       = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")

local lp = Players.LocalPlayer
local function getHum()
    local c = lp.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ── State ─────────────────────────────────────────────────────
local state = {
    silentAim    = false,
    aimbot       = false,
    esp          = false,
    fullbright   = false,
    noclip       = false,
    godMode      = false,
    infiniteJump = false,
    fov          = 70,
    walkSpeed    = 16,
    jumpPower    = 50,
    gravity      = 196,
    timeOfDay    = 12,
}

-- ── Window ────────────────────────────────────────────────────
local win = RbxImGui.new("Player Mods")

win:AddTab("Aimbot")
win:AddTab("Visuals")
win:AddTab("Player")
win:AddTab("World")
win:AddTab("Misc")

-- ════════════════════════════════════════════════════════════
--  AIMBOT TAB
-- ════════════════════════════════════════════════════════════
local aim = win:Tab("Aimbot")

aim:Label("Combat")
aim:Separator()
aim:Toggle("Silent Aim", false, function(on)
    state.silentAim = on
end)
aim:Toggle("Aimbot", false, function(on)
    state.aimbot = on
end)

aim:Label("Settings")
aim:Separator()
aim:Slider("FOV Circle", 10, 500, 120, function(v)
    -- draw/resize your FOV circle here
end)
aim:Slider("Smoothness", 1, 20, 5, function(v)
    -- lower = snappier, higher = smoother
end)

-- ════════════════════════════════════════════════════════════
--  VISUALS TAB
-- ════════════════════════════════════════════════════════════
local vis = win:Tab("Visuals")

vis:Label("ESP")
vis:Separator()
vis:Toggle("Player ESP", false, function(on)
    state.esp = on
end)
vis:Toggle("Tracer Lines", false, function(on)
    -- draw lines to all players
end)
vis:Toggle("Health Bars", false, function(on)
    -- show health above players
end)

vis:Label("Camera")
vis:Separator()
vis:Slider("FOV", 30, 120, state.fov, function(v)
    state.fov = v
    workspace.CurrentCamera.FieldOfView = v
end)

vis:Label("World")
vis:Separator()
vis:Toggle("Fullbright", false, function(on)
    state.fullbright = on
    local lighting = game:GetService("Lighting")
    lighting.Brightness   = on and 10   or 1
    lighting.ClockTime    = on and 14   or 14
    lighting.FogEnd       = on and 1e6  or 100000
    lighting.GlobalShadows= not on
end)

-- ════════════════════════════════════════════════════════════
--  PLAYER TAB
-- ════════════════════════════════════════════════════════════
local plr = win:Tab("Player")

plr:Label("Movement")
plr:Separator()
plr:Slider("Walk Speed", 0, 500, state.walkSpeed, function(v)
    state.walkSpeed = v
    local hum = getHum()
    if hum then hum.WalkSpeed = v end
end)
plr:Slider("Jump Power", 0, 500, state.jumpPower, function(v)
    state.jumpPower = v
    local hum = getHum()
    if hum then hum.JumpPower = v end
end)

plr:Label("Abilities")
plr:Separator()
plr:Toggle("Noclip", false, function(on)
    state.noclip = on
    if not on then
        local char = lp.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end)
plr:Toggle("God Mode", false, function(on)
    state.godMode = on
    local hum = getHum()
    if hum then
        hum.MaxHealth = on and math.huge or 100
        hum.Health    = hum.MaxHealth
    end
end)

local jumpConn
plr:Toggle("Infinite Jump", false, function(on)
    state.infiniteJump = on
    if on then
        jumpConn = UIS.JumpRequest:Connect(function()
            local hum = getHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if jumpConn then jumpConn:Disconnect() jumpConn = nil end
    end
end)

-- ════════════════════════════════════════════════════════════
--  WORLD TAB
-- ════════════════════════════════════════════════════════════
local wld = win:Tab("World")

wld:Label("Physics")
wld:Separator()
wld:Slider("Gravity", 0, 400, state.gravity, function(v)
    state.gravity = v
    workspace.Gravity = v
end)

wld:Label("Time")
wld:Separator()
wld:Slider("Time of Day", 0, 24, state.timeOfDay, function(v)
    state.timeOfDay = v
    game:GetService("Lighting").ClockTime = v
end)

-- ════════════════════════════════════════════════════════════
--  MISC TAB
-- ════════════════════════════════════════════════════════════
local msc = win:Tab("Misc")

msc:Label("Actions")
msc:Separator()
msc:Button("Reset Character", function()
    local char = lp.Character
    if char then char:BreakJoints() end
end)
msc:Button("Teleport to Spawn", function()
    local root = getRoot()
    if root then root.CFrame = CFrame.new(0, 10, 0) end
end)
msc:Button("Print Player Info", function()
    local hum  = getHum()
    local root = getRoot()
    print("=== Player Info ===")
    print("Name     :", lp.Name)
    print("UserId   :", lp.UserId)
    if hum  then print("Health   :", hum.Health, "/", hum.MaxHealth) end
    if root then print("Position :", tostring(root.Position)) end
    print("===================")
end)

msc:Label("Info")
msc:Separator()
msc:Label("Press Insert to toggle this window")
msc:Label("Drag title bar to move")
msc:Label("Drag bottom-right corner to resize")

-- ════════════════════════════════════════════════════════════
--  BUILD
-- ════════════════════════════════════════════════════════════
win:Render()
win:Hide()  -- hidden by default, Insert to open

-- ── Loops ─────────────────────────────────────────────────
RS.Stepped:Connect(function()
    if state.noclip then
        local char = lp.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)
```

---

## Feature Deep Dive & Possibilities

---

### Label Possibilities

Static text. Set at build time, cannot be changed after `:Render()`.

```lua
tab:Label("Section Header")
tab:Label("v1.0.0  |  github.com/you/rbximgui")
tab:Label("Press Insert to hide this panel")
tab:Label("──── Danger Zone ────────────────")
```

---

### Separator Possibilities

A 1px line. Best used after a Label to create a section header, or between groups of controls.

```lua
tab:Label("Combat"):Separator()
tab:Toggle("Aimbot", false, cb)

-- Visual break between safe and dangerous actions
tab:Button("Safe", cb)
tab:Separator()
tab:Button("Dangerous", cb)
```

---

### Button Possibilities

The callback is a plain Lua function — it can do anything a LocalScript can do.

```lua
-- Teleport to a specific player
tab:Button("Go to Player", function()
    local t = game.Players:FindFirstChild("TargetName")
    if t and t.Character then
        getRoot().CFrame = t.Character.HumanoidRootPart.CFrame
    end
end)

-- Spawn a part at your feet
tab:Button("Spawn Part", function()
    local p = Instance.new("Part")
    p.Size = Vector3.new(4,4,4)
    p.Position = getRoot().Position + Vector3.new(0,5,0)
    p.Parent = workspace
end)

-- Fire a RemoteEvent to the server
tab:Button("Buy Sword", function()
    game.ReplicatedStorage.ShopEvent:FireServer("Sword")
end)

-- Close the panel from inside
tab:Button("Close", function() win:Hide() end)

-- Copy text to clipboard (supported executors only)
tab:Button("Copy UserId", function()
    if setclipboard then setclipboard(tostring(lp.UserId)) end
end)
```

---

### Toggle Possibilities

Best for behaviors that run continuously over time — loops, event connections, persistent overrides.

```lua
-- Persistent loop (noclip, speed lock, etc.)
local active = false
tab:Toggle("Speed Lock", false, function(on) active = on end)
RS.Stepped:Connect(function()
    if active then getHum().WalkSpeed = 100 end
end)

-- Connect/disconnect an event listener cleanly
local conn
tab:Toggle("Auto Farm", false, function(on)
    if on then
        conn = workspace.Items.ChildAdded:Connect(function(item)
            -- collect item
        end)
    else
        if conn then conn:Disconnect() conn = nil end
    end
end)

-- Default ON (starts enabled)
tab:Toggle("Show Nametags", true, function(on)
    -- starts in the ON state
end)

-- Two mutually exclusive modes
local modeA, modeB = false, false
tab:Toggle("Mode A", false, function(on) modeA = on; if on then modeB = false end end)
tab:Toggle("Mode B", false, function(on) modeB = on; if on then modeA = false end end)
```

---

### Slider Possibilities

Any continuous numeric value.

```lua
-- Player stats
tab:Slider("Walk Speed",  0,   500, 16,  function(v) getHum().WalkSpeed = v end)
tab:Slider("Jump Power",  0,   500, 50,  function(v) getHum().JumpPower  = v end)
tab:Slider("Hip Height",  0,   10,  2,   function(v) getHum().HipHeight  = v end)

-- World
tab:Slider("Gravity",     0,   400, 196, function(v) workspace.Gravity = v end)
tab:Slider("Time of Day", 0,   24,  12,  function(v) game:GetService("Lighting").ClockTime = v end)

-- Camera
tab:Slider("FOV",         30,  120, 70,  function(v) workspace.CurrentCamera.FieldOfView = v end)

-- Transparency (for ESP boxes etc.)
tab:Slider("Box Alpha",   0,   100, 80,  function(v) espBox.BackgroundTransparency = v / 100 end)

-- Track value externally (no getter — store it yourself)
local mySpeed = 16
tab:Slider("Speed", 0, 100, mySpeed, function(v) mySpeed = v end)
-- read `mySpeed` anywhere in your code
```

---

## Theming

Edit the `THEME` table at the top of `RobloxUI.lua`.

| Key | Affects |
|-----|---------|
| `TitleBarBg` | Title bar background |
| `TitleBarText` | Title text |
| `TabBarBg` | Tab bar background |
| `TabBg` | Inactive tab button background |
| `TabHover` | Tab button on hover |
| `TabActive` | Active (selected) tab background |
| `TabText` | Inactive tab label color |
| `TabTextActive` | Active tab label color |
| `WindowBg` | Main content area background |
| `WindowBorder` | Window outline |
| `ButtonBg` | Button resting color |
| `ButtonHover` | Button on hover |
| `ButtonActive` | Button while held |
| `ButtonText` | Button label |
| `ToggleOff` | Toggle track when off |
| `ToggleOn` | Toggle track when on |
| `ToggleKnob` | Toggle knob |
| `ToggleText` | Toggle label |
| `SliderTrack` | Unfilled slider track |
| `SliderFill` | Filled portion |
| `SliderKnob` | Slider knob |
| `SliderText` | Slider label |
| `SliderValue` | Slider number readout |
| `SeparatorColor` | Separator line |
| `TextColor` | Label text |
| `ResizeGrip` | Resize grip background |
| `ResizeGripHover` | Resize grip on hover |
| `ScrollThumb` | Scrollbar thumb |

**Red accent theme:**
```lua
TabActive       = Color3.fromRGB(200, 50, 50),
ButtonActive    = Color3.fromRGB(200, 50, 50),
ToggleOn        = Color3.fromRGB(200, 50, 50),
SliderFill      = Color3.fromRGB(200, 50, 50),
SliderValue     = Color3.fromRGB(255, 100, 100),
ResizeGripHover = Color3.fromRGB(200, 50, 50),
```

**Green hacker theme:**
```lua
TitleBarBg   = Color3.fromRGB(10,  20,  10),
TitleBarText = Color3.fromRGB(80,  255, 140),
TabBarBg     = Color3.fromRGB(12,  24,  12),
TabBg        = Color3.fromRGB(15,  35,  15),
TabActive    = Color3.fromRGB(0,   180, 70),
TabText      = Color3.fromRGB(60,  160, 80),
TabTextActive= Color3.fromRGB(200, 255, 200),
WindowBg     = Color3.fromRGB(8,   14,  8),
WindowBorder = Color3.fromRGB(0,   80,  30),
ButtonBg     = Color3.fromRGB(15,  40,  20),
ButtonHover  = Color3.fromRGB(20,  60,  30),
ButtonActive = Color3.fromRGB(0,   180, 70),
ToggleOn     = Color3.fromRGB(0,   180, 70),
SliderFill   = Color3.fromRGB(0,   180, 70),
SliderValue  = Color3.fromRGB(80,  255, 140),
TextColor    = Color3.fromRGB(80,  255, 140),
ToggleText   = Color3.fromRGB(80,  255, 140),
SliderText   = Color3.fromRGB(80,  255, 140),
```

---

## Defaults

| Key | Default | Description |
|-----|---------|-------------|
| `WindowWidth` | `320` | Initial window width |
| `WindowMinWidth` | `200` | Minimum width when resizing |
| `WindowMinHeight` | `120` | Minimum height when resizing |
| `TitleBarHeight` | `30` | Title bar height |
| `TabBarHeight` | `30` | Tab bar height |
| `TabMinWidth` | `60` | Minimum tab button width |
| `Padding` | `10` | Content padding (all sides) |
| `ItemSpacing` | `6` | Gap between widgets |
| `ButtonHeight` | `28` | Button height |
| `ToggleHeight` | `24` | Toggle row height |
| `SliderHeight` | `30` | Slider track row height |
| `CornerRadius` | `6` | Window and button corner rounding |
| `FontSize` | `13` | Base font size |
| `ResizeGripSize` | `14` | Resize grip square size |

---

## Rules & Gotchas

**Call `:AddTab()` before `:Tab()`.** `win:Tab("Name")` throws an error if that tab was never registered with `:AddTab("Name")`.

**Call `:Render()` last, exactly once.** Calling it again duplicates every widget across every tab.

**LocalScript only.** Uses `UserInputService` and creates GUI Instances. Cannot run in a server `Script`.

**Sliders return integers.** The callback always receives `math.floor(value)`.

**Widget state is internal.** Store values in your own variables via the callback — there is no getter.

**Insert won't fire while chatting.** The listener checks `gameProcessed`.

**Tabs don't auto-scroll to the top on switch.** Each tab preserves its own scroll position between switches.

---

## Loading from GitHub

```lua
local RbxImGui = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/RobloxUI.lua"
))()

local win = RbxImGui.new("My Panel")
win:AddTab("Main")
win:Tab("Main"):Button("Test", function() print("works") end)
win:Render()
```

**Requirements:**
- Game Settings → Security → **Allow HTTP Requests** ON
- Repository must be **public**
- Use the `raw.githubusercontent.com` URL

**Getting the raw URL:**
1. Open your file on GitHub
2. Click **Raw** in the top-right of the file viewer
3. Copy the address bar URL
