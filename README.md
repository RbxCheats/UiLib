# RbxImGui

A lightweight, ImGui-style UI library for Roblox. Build draggable, resizable windows with a tabbed navigation bar and a full suite of widgets — buttons, toggles, sliders, dropdowns, and a full HSV color picker. Renders into `CoreGui` so the window survives respawns and always sits above in-game UI.

> **Press `Insert` at any time to show or hide the window.**

---

## Table of Contents

- [What It Looks Like](#what-it-looks-like)
- [Installation](#installation)
- [The Build Order — Read This First](#the-build-order--read-this-first)
- [Creating the Window](#creating-the-window)
- [The Tab System](#the-tab-system)
  - [win:AddTab()](#winaddtab)
  - [win:Tab()](#wintab)
  - [No-Tab Mode](#no-tab-mode)
- [Widgets](#widgets)
  - [Label](#label)
  - [Separator](#separator)
  - [Button](#button)
  - [Toggle](#toggle)
  - [Slider](#slider)
  - [Dropdown](#dropdown)
  - [ColorPicker](#colorpicker)
- [Window Controls](#window-controls)
- [Full Showcase Example](#full-showcase-example)
- [Theming](#theming)
- [Defaults Reference](#defaults-reference)
- [Rules and Common Mistakes](#rules-and-common-mistakes)
- [Loading from GitHub](#loading-from-github)

---

## What It Looks Like

```
┌──────────────────────────────────────┐
│  Player Mods                         │  ← Title bar — drag to move
├──────────────────────────────────────┤
│ [Aimbot] [Visuals] [Misc]            │  ← Tab bar — click to switch tabs
├──────────────────────────────────────┤
│                                      │
│  Combat                              │  ← Label
│ ──────────────────────────────────   │  ← Separator
│  Silent Aim              [   ● ]     │  ← Toggle ON
│  Aimbot                  [ ●   ]     │  ← Toggle OFF
│                                      │
│  Aim Bone                       ▾    │  ← Dropdown (closed)
│  ┌─ Head ──────────────────────┐     │
│  │ ● Head                      │     │  ← Dropdown (open, Head selected)
│  │   Torso                     │     │
│  └─────────────────────────────┘     │
│                                      │
│  FOV Circle                   120    │  ← Slider
│  [████████████●────────────────]     │
│                                      │
│  ESP Color          ■ [▴]            │  ← ColorPicker (expanded)
│  ┌──────────────────────────────┐    │
│  │    [SV Square]   [Hue Bar]   │    │
│  │    [Alpha Bar]               │    │
│  │    [██████████ preview]      │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────[◢] ┘  ← Resize grip
```

The window is:
- **Draggable** — click and hold the title bar, drag it anywhere on screen
- **Resizable** — drag the `◢` grip in the bottom-right corner
- **Scrollable** — each tab independently scrolls if your content is taller than the window
- **Togglable** — press `Insert` to show or hide it at any time

---

## Installation

### Option A — ModuleScript (recommended for Studio or executor injection)

1. In Roblox Studio, create a `ModuleScript` inside `ReplicatedStorage`
2. Name it `RobloxUI`
3. Paste the full contents of `RobloxUI.lua` into it
4. In a `LocalScript` under `StarterPlayer > StarterPlayerScripts`, write:

```lua
local RbxImGui = require(game.ReplicatedStorage.RobloxUI)
```

Your project structure should look like this:

```
ReplicatedStorage
  └── RobloxUI              ← ModuleScript (paste RobloxUI.lua here)

StarterPlayer
  └── StarterPlayerScripts
        └── MyScript        ← LocalScript (your menu code goes here)
```

### Option B — loadstring from GitHub (executor usage)

```lua
local RbxImGui = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/RobloxUI.lua"
))()
```

Requirements for Option B:
- **Allow HTTP Requests** must be ON in Game Settings → Security
- The GitHub repository must be **public**
- You must use the `raw.githubusercontent.com` URL, not the normal GitHub page URL

To get the raw URL: open the file on GitHub, click the **Raw** button in the top-right of the file viewer, then copy the address bar.

---

## The Build Order — Read This First

This library uses a **deferred build pattern**. That means widgets are not drawn immediately when you write the code for them — they are queued up and drawn all at once when you call `:Render()`. Because of this, there is a strict order you must follow:

```
Step 1 → RbxImGui.new()       Create the window
Step 2 → win:AddTab()         Register your tabs
Step 3 → win:Tab():Widget()   Add widgets to each tab
Step 4 → win:Render()         Build everything — call this LAST, only ONCE
```

If you call `:Render()` before adding your widgets, the window will be empty. If you call `:Render()` twice, every widget will be duplicated. Just call it once at the very end.

```lua
local RbxImGui = require(game.ReplicatedStorage.RobloxUI)

local win = RbxImGui.new("My Menu")   -- Step 1

win:AddTab("Aimbot")                  -- Step 2
win:AddTab("Visuals")

win:Tab("Aimbot"):Toggle("Silent Aim", false, function(on)  -- Step 3
    print("Silent Aim:", on)
end)

win:Tab("Visuals"):Slider("FOV", 30, 120, 70, function(v)
    workspace.CurrentCamera.FieldOfView = v
end)

win:Render()   -- Step 4 — always last
```

---

## Creating the Window

### `RbxImGui.new(title, parent?)`

This is always the very first call. It creates the window frame, title bar, tab bar, content area, and resize grip. It also sets up the `Insert` key listener automatically.

| Parameter | Type | Required | What it does |
|-----------|------|----------|--------------|
| `title` | string | Yes | The text shown in the title bar at the top of the window |
| `parent` | Instance | No | Where the ScreenGui is parented. Leave this out and it automatically goes into `CoreGui` (or `PlayerGui` as a fallback) |

```lua
local win = RbxImGui.new("Player Mods")
```

The window starts visible by default. If you want it hidden until the player presses Insert, call `win:Hide()` after `win:Render()`.

---

## The Tab System

Tabs are the buttons at the top of the content area — Aimbot, Visuals, Misc, etc. Each tab has its own independent content area and scroll position. Clicking a tab switches to it instantly.

### `win:AddTab(name)`

Registers a new tab. Creates the tab button in the bar and the scrollable content frame behind it. The first tab you add is automatically made active (visible) when the window opens.

| Parameter | Type | What it does |
|-----------|------|--------------|
| `name` | string | The label shown on the tab button. Also the key you use with `win:Tab()` later |

`AddTab` returns the window itself, so you can chain multiple tabs on one line:

```lua
win:AddTab("Aimbot"):AddTab("Visuals"):AddTab("Misc")

-- Or one per line — same result:
win:AddTab("Aimbot")
win:AddTab("Visuals")
win:AddTab("Misc")
```

Tab button width auto-sizes based on the name length. If you have a lot of tabs with long names and they don't fit, shorten the names.

### `win:Tab(name)`

Returns a **TabBuilder** — an object you call widget methods on to add content to that specific tab. Every widget call you make on a TabBuilder gets added to that tab's content.

| Parameter | Type | What it does |
|-----------|------|--------------|
| `name` | string | Must exactly match a name you already passed to `AddTab`. Throws an error if the tab doesn't exist |

There are three equally valid ways to use this:

```lua
-- Pattern 1: call win:Tab() each time (easy to read, slightly more typing)
win:Tab("Aimbot"):Toggle("Silent Aim", false, cb)
win:Tab("Aimbot"):Slider("FOV", 30, 120, 70, cb)

-- Pattern 2: chain everything on one tab builder (compact)
win:Tab("Aimbot")
    :Toggle("Silent Aim", false, cb)
    :Slider("FOV", 30, 120, 70, cb)
    :Button("Reset", cb)

-- Pattern 3: store the tab builder in a variable (cleanest for long tabs)
local aim = win:Tab("Aimbot")
aim:Toggle("Silent Aim", false, cb)
aim:Slider("FOV", 30, 120, 70, cb)
aim:Button("Reset", cb)
```

All three produce identical results. Pattern 3 is the most readable when a tab has a lot of widgets.

### No-Tab Mode

If you never call `AddTab`, the tab bar is hidden and you can call widget methods directly on the window object. This is useful for a single simple panel.

```lua
local win = RbxImGui.new("Simple Panel")

win:Label("Controls")
win:Separator()
win:Toggle("God Mode", false, function(on) end)
win:Slider("Walk Speed", 0, 500, 16, function(v) end)
win:Button("Reset", function() end)

win:Render()
```

---

## Widgets

All widgets are available on both a TabBuilder (`win:Tab("Name"):Widget(...)`) and directly on the window in no-tab mode (`win:Widget(...)`). Every widget method returns the TabBuilder so you can chain calls.

---

### Label

Displays a line of static text. It cannot be updated after `Render()` is called — it is set once and stays.

```lua
tab:Label(text)
```

| Parameter | Type | What it does |
|-----------|------|--------------|
| `text` | string | The text to display |

Use labels to create section headings, show version info, or leave notes for the user. They are always left-aligned.

```lua
local vis = win:Tab("Visuals")

vis:Label("ESP Settings")
vis:Separator()
vis:Toggle("Player ESP", false, function(on) end)

vis:Label("Camera")
vis:Separator()
vis:Slider("FOV", 30, 120, 70, function(v) end)

-- You can use symbols to make a visual divider label
vis:Label("──── Danger Zone ────")
```

---

### Separator

Draws a thin 1px horizontal line across the content area. Takes no parameters. Used to visually separate sections.

```lua
tab:Separator()
```

The standard pattern is a Label followed immediately by a Separator, which looks like a section header with an underline:

```lua
aim:Label("Combat")
aim:Separator()
aim:Toggle("Silent Aim", false, cb)
aim:Toggle("Aimbot", false, cb)

aim:Label("Settings")
aim:Separator()
aim:Slider("FOV Circle", 10, 500, 120, cb)
```

---

### Button

A full-width clickable button. When clicked, it calls your function. The button animates on hover (lighter) and on press (accent color).

```lua
tab:Button(label, callback)
```

| Parameter | Type | What it does |
|-----------|------|--------------|
| `label` | string | The text shown on the button |
| `callback` | function | Called with no arguments when the button is clicked. Can be `nil` if you don't need it |

The callback fires on mouse button release, not press, so the animation plays cleanly.

```lua
local msc = win:Tab("Misc")

-- Simple action
msc:Button("Reset Character", function()
    local char = game.Players.LocalPlayer.Character
    if char then char:BreakJoints() end
end)

-- Teleport
msc:Button("Go to Spawn", function()
    local root = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(0, 10, 0) end
end)

-- Fire a remote event
msc:Button("Buy Sword", function()
    game.ReplicatedStorage.ShopEvent:FireServer("Sword")
end)

-- Hide the window from a button inside it
msc:Button("Close Menu", function()
    win:Hide()
end)
```

---

### Toggle

An on/off switch with an animated sliding knob. Fires your callback every time the state changes, passing `true` when turned on and `false` when turned off.

```lua
tab:Toggle(label, defaultValue, callback)
```

| Parameter | Type | What it does |
|-----------|------|--------------|
| `label` | string | Text shown to the left of the switch |
| `defaultValue` | boolean | The starting state. `true` = ON, `false` = OFF |
| `callback` | function(boolean) | Called with the new state every time the toggle is clicked |

The toggle does not have a getter — the library doesn't give you a way to ask "is this toggle currently on?" after the fact. Instead, store the value yourself in a variable inside the callback:

```lua
local espEnabled = false

vis:Toggle("Player ESP", false, function(on)
    espEnabled = on  -- store it yourself
end)

-- Now read espEnabled anywhere in your code
```

Common patterns:

```lua
-- Continuous behavior via RunService loop
local noclip = false
plr:Toggle("Noclip", false, function(on) noclip = on end)

game:GetService("RunService").Stepped:Connect(function()
    if noclip then
        for _, p in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- Connect/disconnect an event on toggle
local conn
plr:Toggle("Infinite Jump", false, function(on)
    if on then
        conn = game:GetService("UserInputService").JumpRequest:Connect(function()
            local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if conn then conn:Disconnect(); conn = nil end
    end
end)

-- Start ON by default
aim:Toggle("Show FOV Circle", true, function(on)
    -- fov circle already drawn on startup
end)
```

---

### Slider

A horizontal drag slider for any numeric value. The user clicks and drags to set the value. The current value is displayed as a number to the right of the label. Always returns a whole integer.

```lua
tab:Slider(label, min, max, default, callback)
```

| Parameter | Type | What it does |
|-----------|------|--------------|
| `label` | string | Text shown above the slider track |
| `min` | number | The value at the far left of the slider |
| `max` | number | The value at the far right of the slider |
| `default` | number | The starting value. Automatically clamped between min and max |
| `callback` | function(number) | Called continuously while the user is dragging, with the current integer value |

The callback fires on every mouse movement while dragging, so keep the callback lightweight. If you're doing something expensive (like firing a remote), consider debouncing.

```lua
local plr = win:Tab("Player")

plr:Slider("Walk Speed", 0, 500, 16, function(v)
    local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end)

plr:Slider("Jump Power", 0, 500, 50, function(v)
    local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v end
end)

-- World settings
local wld = win:Tab("World")
wld:Slider("Gravity", 0, 400, 196, function(v)
    workspace.Gravity = v
end)

wld:Slider("Time of Day", 0, 24, 12, function(v)
    game:GetService("Lighting").ClockTime = v
end)

-- Camera FOV
vis:Slider("Camera FOV", 30, 120, 70, function(v)
    workspace.CurrentCamera.FieldOfView = v
end)

-- Store the value externally — there is no getter
local fovRadius = 120
aim:Slider("FOV Circle Radius", 10, 500, 120, function(v)
    fovRadius = v
    -- resize your circle drawing here
end)
```

---

### Dropdown

A clickable selector that shows a list of options when opened. The user picks one option and the list closes. Useful for choosing between mutually exclusive modes — like 2D vs 3D ESP, or Head vs Torso aimbot targeting.

```lua
tab:Dropdown(label, options, default, callback)
```

| Parameter | Type | What it does |
|-----------|------|--------------|
| `label` | string | Small text shown above the dropdown box |
| `options` | table (array of strings) | The list of choices. Must have at least one item |
| `default` | string | The option that is selected on startup. Must match one of the strings in your options table. If `nil`, the first option is used |
| `callback` | function(string) | Called with the selected option string every time the user picks something |

Clicking the dropdown box opens the list below it. The currently selected option is highlighted in blue. Clicking an option selects it, updates the box label, and closes the list. The `▾` arrow flips to `▴` while open.

```lua
local aim = win:Tab("Aimbot")

-- Choose which bone to aim at
aim:Dropdown("Aim Bone", {"Head", "Torso", "HumanoidRootPart"}, "Head", function(selected)
    aimbotBone = selected
    print("Now aiming at:", selected)
end)

-- Switch ESP mode
local vis = win:Tab("Visuals")
vis:Dropdown("ESP Mode", {"2D", "3D"}, "2D", function(selected)
    if selected == "2D" then
        enable2DESP()
    elseif selected == "3D" then
        enable3DESP()
    end
end)

-- Choose prediction style
aim:Dropdown("Prediction", {"None", "Linear", "Velocity"}, "None", function(selected)
    predictionMode = selected
end)

-- Keybind selector
aim:Dropdown("Aim Key", {"RightMouseButton", "CapsLock", "LeftAlt", "E"}, "RightMouseButton", function(selected)
    aimKey = Enum.KeyCode[selected] or Enum.UserInputType[selected]
end)
```

The list can have as many options as you need. There's no hard limit, though very long lists will overflow the window — pair it with the window's scrolling if needed.

---

### ColorPicker

A full HSV color picker with a saturation/value square, a hue bar, an alpha bar, and a live preview swatch. The picker is collapsed by default and expands when the user clicks the `▾` button.

There are two modes, controlled by the optional `requireToggle` parameter.

```lua
tab:ColorPicker(label, defaultColor, callback, requireToggle?)
```

| Parameter | Type | What it does |
|-----------|------|--------------|
| `label` | string | Text shown in the header row next to the color swatch |
| `defaultColor` | Color3 | The starting color. Use `Color3.fromRGB(r, g, b)` |
| `callback` | function(Color3) | Called every time the color changes while the user is dragging inside the picker |
| `requireToggle` | boolean (optional) | If `true`, a small enable toggle appears in the header. The picker cannot be opened until the toggle is ON, and the callback only fires while the toggle is ON |

**Mode 1 — `requireToggle` is `false` or not passed:**

The picker is always available. Click `▾` to expand it. The callback fires as the user drags around the picker.

```lua
vis:ColorPicker("ESP Color", Color3.fromRGB(255, 50, 50), function(color)
    espColor = color
    -- apply color to your ESP boxes, text, etc.
end)
```

**Mode 2 — `requireToggle` is `true`:**

A small toggle switch appears in the header row. The `▾` expand button does nothing until that toggle is turned ON. This is the right pattern for optional features — the user has to explicitly enable custom colors before they can change them.

```lua
vis:ColorPicker("Custom ESP Color", Color3.fromRGB(255, 255, 255), function(color)
    -- This only fires when the toggle is ON
    espColor = color
end, true)

vis:ColorPicker("Custom FOV Color", Color3.fromRGB(255, 255, 255), function(color)
    fovCircleColor = color
end, true)

vis:ColorPicker("Chams Color", Color3.fromRGB(0, 120, 255), function(color)
    chamsColor = color
end, true)
```

If the user turns the toggle OFF while the picker is open, the picker closes automatically and the callback stops firing until they turn it back ON.

**How the picker works:**

The picker has three interactive sections:

- **SV Square** — the large square on the left. Dragging left/right controls saturation (how vivid the color is). Dragging up/down controls value (how bright or dark it is). Bottom-left is black, top-right is the full pure hue.
- **Hue Bar** — the tall narrow bar on the right of the square. Dragging up and down scrolls through the full spectrum of colors (red → yellow → green → cyan → blue → magenta → red).
- **Alpha Bar** — the wide bar below both. Dragging left/right sets the alpha (opacity) from 0 to 1. Note that `Color3` in Roblox does not carry alpha — the alpha value is tracked internally in the picker but the `Color3` passed to your callback will not include it. If you need alpha, read it from a separate slider.
- **Preview swatch** — the wide colored bar at the bottom shows a live preview of the current color as you drag.

---

## Window Controls

These methods let you show, hide, and destroy the window from your code.

### `win:Render()`

Builds all widgets across all tabs. You must call this once after setting everything up. Never call it more than once.

```lua
-- Always the last line before any post-render code
win:Render()
win:Hide()  -- optional: start hidden
```

### `win:Show()`

Makes the window visible.

```lua
win:Show()
```

### `win:Hide()`

Hides the window. The Insert key will still show it again.

```lua
win:Hide()
```

### `win:Toggle_Window()`

Flips visibility — if visible, hides it; if hidden, shows it. This is the same thing the Insert key does internally.

```lua
win:Toggle_Window()
```

### `win:Destroy()`

Completely destroys the ScreenGui and everything in it. Use this if you want to fully remove the UI at runtime.

```lua
win:Destroy()
```

---

## Full Showcase Example

This is a complete working script you can drop into a `LocalScript` under `StarterPlayer > StarterPlayerScripts`. It covers every widget type and demonstrates good patterns for storing state, managing connections, and building a clean menu.

```lua
-- ================================================================
--  RbxImGui Full Showcase
--  LocalScript → StarterPlayer > StarterPlayerScripts
-- ================================================================
local RbxImGui = require(game.ReplicatedStorage.RobloxUI)
local Players  = game:GetService("Players")
local RS       = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local lp = Players.LocalPlayer

local function getHum()
    local c = lp.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ── All state lives here — callbacks just update these values ──
local state = {
    -- Aimbot
    silentAim    = false,
    aimbot       = false,
    aimbotBone   = "Head",
    fovRadius    = 120,
    smoothness   = 5,
    -- Visuals
    esp          = false,
    espMode      = "2D",
    espColor     = Color3.fromRGB(255, 50, 50),
    tracers      = false,
    healthBars   = false,
    fovCircle    = false,
    fovColor     = Color3.fromRGB(255, 255, 255),
    fullbright   = false,
    cameraFov    = 70,
    -- Player
    noclip       = false,
    godMode      = false,
    infiniteJump = false,
    walkSpeed    = 16,
    jumpPower    = 50,
    -- World
    gravity      = 196,
    timeOfDay    = 12,
}

-- ── Create the window ──────────────────────────────────────────
local win = RbxImGui.new("Player Mods")

win:AddTab("Aimbot")
win:AddTab("Visuals")
win:AddTab("Player")
win:AddTab("World")
win:AddTab("Misc")

-- ════════════════════════════════════════════════════════════════
--  AIMBOT TAB
-- ════════════════════════════════════════════════════════════════
local aim = win:Tab("Aimbot")

aim:Label("Combat")
aim:Separator()

aim:Toggle("Silent Aim", false, function(on)
    state.silentAim = on
end)
aim:Toggle("Aimbot", false, function(on)
    state.aimbot = on
end)

aim:Label("Targeting")
aim:Separator()

aim:Dropdown("Aim Bone", {"Head", "Torso", "HumanoidRootPart"}, "Head", function(v)
    state.aimbotBone = v
end)

aim:Label("Settings")
aim:Separator()

aim:Slider("FOV Circle Radius", 10, 500, 120, function(v)
    state.fovRadius = v
    -- resize your circle drawing here
end)
aim:Slider("Smoothness", 1, 20, 5, function(v)
    state.smoothness = v
    -- lower = snappier aim, higher = smoother
end)

-- ════════════════════════════════════════════════════════════════
--  VISUALS TAB
-- ════════════════════════════════════════════════════════════════
local vis = win:Tab("Visuals")

vis:Label("ESP")
vis:Separator()

vis:Toggle("Player ESP", false, function(on)
    state.esp = on
end)
vis:Dropdown("ESP Mode", {"2D", "3D"}, "2D", function(v)
    state.espMode = v
end)
-- Color picker — no toggle required, always accessible
vis:ColorPicker("ESP Color", Color3.fromRGB(255, 50, 50), function(color)
    state.espColor = color
end)

vis:Toggle("Tracer Lines", false, function(on)
    state.tracers = on
end)
vis:Toggle("Health Bars", false, function(on)
    state.healthBars = on
end)

vis:Label("FOV Circle")
vis:Separator()

vis:Toggle("Show FOV Circle", false, function(on)
    state.fovCircle = on
end)
-- Color picker with toggle gate — callback only fires when enabled
vis:ColorPicker("FOV Circle Color", Color3.fromRGB(255, 255, 255), function(color)
    state.fovColor = color
    -- apply to your circle drawing
end, true)

vis:Label("Camera")
vis:Separator()

vis:Slider("Camera FOV", 30, 120, 70, function(v)
    state.cameraFov = v
    workspace.CurrentCamera.FieldOfView = v
end)

vis:Label("World")
vis:Separator()

vis:Toggle("Fullbright", false, function(on)
    state.fullbright = on
    Lighting.Brightness    = on and 10  or 1
    Lighting.ClockTime     = on and 14  or 14
    Lighting.FogEnd        = on and 1e6 or 100000
    Lighting.GlobalShadows = not on
end)

-- ════════════════════════════════════════════════════════════════
--  PLAYER TAB
-- ════════════════════════════════════════════════════════════════
local plr = win:Tab("Player")

plr:Label("Movement")
plr:Separator()

plr:Slider("Walk Speed", 0, 500, 16, function(v)
    state.walkSpeed = v
    local hum = getHum()
    if hum then hum.WalkSpeed = v end
end)
plr:Slider("Jump Power", 0, 500, 50, function(v)
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
        if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
    end
end)

-- ════════════════════════════════════════════════════════════════
--  WORLD TAB
-- ════════════════════════════════════════════════════════════════
local wld = win:Tab("World")

wld:Label("Physics")
wld:Separator()

wld:Slider("Gravity", 0, 400, 196, function(v)
    state.gravity = v
    workspace.Gravity = v
end)

wld:Label("Time")
wld:Separator()

wld:Slider("Time of Day", 0, 24, 12, function(v)
    state.timeOfDay = v
    Lighting.ClockTime = v
end)

-- ════════════════════════════════════════════════════════════════
--  MISC TAB
-- ════════════════════════════════════════════════════════════════
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
msc:Label("Insert — toggle this window")
msc:Label("Drag title bar to move")
msc:Label("Drag bottom-right corner to resize")

-- ════════════════════════════════════════════════════════════════
--  BUILD — must be last
-- ════════════════════════════════════════════════════════════════
win:Render()
win:Hide()  -- hidden by default; press Insert to open

-- ── Runtime loops ──────────────────────────────────────────────
RS.Stepped:Connect(function()
    -- Noclip loop — must run every frame to override collision
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

## Theming

All colors are defined in the `THEME` table at the top of `RobloxUI.lua`. Edit any value there to change the appearance globally. Colors use `Color3.fromRGB(r, g, b)`.

| Key | What it controls |
|-----|-----------------|
| `TitleBarBg` | Background of the title bar |
| `TitleBarText` | Title text color |
| `TabBarBg` | Background behind the tab buttons |
| `TabBg` | Inactive tab button color |
| `TabHover` | Tab button color on hover |
| `TabActive` | Active (selected) tab button color |
| `TabText` | Inactive tab label color |
| `TabTextActive` | Active tab label color |
| `WindowBg` | Main content area background |
| `WindowBorder` | Outline around the whole window |
| `ButtonBg` | Button at rest |
| `ButtonHover` | Button on hover |
| `ButtonActive` | Button while held down |
| `ButtonText` | Button label color |
| `ToggleOff` | Toggle track when OFF |
| `ToggleOn` | Toggle track when ON |
| `ToggleKnob` | The sliding knob on a toggle |
| `ToggleText` | Toggle label color |
| `SliderTrack` | The unfilled part of the slider track |
| `SliderFill` | The filled part of the slider track |
| `SliderKnob` | The draggable knob on a slider |
| `SliderText` | Slider label color |
| `SliderValue` | The number readout on the right |
| `SeparatorColor` | The separator line color |
| `TextColor` | Label text color |
| `ResizeGrip` | Resize grip background |
| `ResizeGripHover` | Resize grip on hover |
| `ScrollThumb` | The scrollbar thumb color |
| `DropdownBg` | Dropdown header and menu background |
| `DropdownBorder` | Dropdown outline |
| `DropdownItem` | Unselected option background |
| `DropdownItemHov` | Option background on hover |
| `DropdownItemSel` | Selected option background |
| `DropdownText` | Option text color |
| `DropdownArrow` | The ▾ / ▴ arrow color |
| `PickerBg` | ColorPicker panel background |
| `PickerBorder` | ColorPicker panel outline |
| `PickerKnob` | ColorPicker knob color |

**Example — Red accent theme:**

```lua
TabActive       = Color3.fromRGB(200, 50,  50),
ButtonActive    = Color3.fromRGB(200, 50,  50),
ToggleOn        = Color3.fromRGB(200, 50,  50),
SliderFill      = Color3.fromRGB(200, 50,  50),
SliderValue     = Color3.fromRGB(255, 100, 100),
ResizeGripHover = Color3.fromRGB(200, 50,  50),
DropdownItemSel = Color3.fromRGB(200, 50,  50),
```

**Example — Green hacker theme:**

```lua
TitleBarBg    = Color3.fromRGB(10,  20,  10),
TitleBarText  = Color3.fromRGB(80,  255, 140),
TabBarBg      = Color3.fromRGB(12,  24,  12),
TabBg         = Color3.fromRGB(15,  35,  15),
TabActive     = Color3.fromRGB(0,   180, 70),
TabText       = Color3.fromRGB(60,  160, 80),
TabTextActive = Color3.fromRGB(200, 255, 200),
WindowBg      = Color3.fromRGB(8,   14,  8),
WindowBorder  = Color3.fromRGB(0,   80,  30),
ButtonBg      = Color3.fromRGB(15,  40,  20),
ButtonHover   = Color3.fromRGB(20,  60,  30),
ButtonActive  = Color3.fromRGB(0,   180, 70),
ToggleOn      = Color3.fromRGB(0,   180, 70),
SliderFill    = Color3.fromRGB(0,   180, 70),
SliderValue   = Color3.fromRGB(80,  255, 140),
TextColor     = Color3.fromRGB(80,  255, 140),
ToggleText    = Color3.fromRGB(80,  255, 140),
SliderText    = Color3.fromRGB(80,  255, 140),
DropdownItemSel = Color3.fromRGB(0, 180, 70),
```

---

## Defaults Reference

These are found in the `DEFAULTS` table at the top of `RobloxUI.lua`. Change them to adjust sizes and spacing.

| Key | Default | What it controls |
|-----|---------|-----------------|
| `WindowWidth` | `320` | Starting width of the window in pixels |
| `WindowMinWidth` | `200` | Minimum width when the user resizes |
| `WindowMinHeight` | `120` | Minimum height when the user resizes |
| `TitleBarHeight` | `30` | Height of the title bar |
| `TabBarHeight` | `30` | Height of the tab button row |
| `TabMinWidth` | `60` | Minimum tab button width in pixels |
| `Padding` | `10` | Space around the content inside each tab |
| `ItemSpacing` | `6` | Gap between each widget |
| `ButtonHeight` | `28` | Height of buttons |
| `ToggleHeight` | `24` | Height of toggle rows |
| `SliderHeight` | `30` | Height of the slider track area |
| `CornerRadius` | `6` | Rounding on the window and widget corners |
| `FontSize` | `13` | Base text size used across all widgets |
| `ResizeGripSize` | `14` | Size of the resize grip square |
| `DropdownHeight` | `28` | Height of the dropdown header box |
| `DropdownItemH` | `26` | Height of each item in the dropdown list |
| `ColorPickerH` | `160` | Height of the expanded color picker panel |

---

## Rules and Common Mistakes

**You must call `:AddTab()` before `:Tab()`.**
`win:Tab("Aimbot")` throws an error if `"Aimbot"` was never registered with `win:AddTab("Aimbot")`. Always add your tabs first.

**You must call `:Render()` last, exactly once.**
All widget code must come before `Render()`. Calling `Render()` twice will duplicate every widget. There is no way to undo this.

**This is a LocalScript only.**
The library uses `UserInputService` and creates GUI instances. It cannot run in a server `Script`.

**Sliders always return whole integers.**
The callback receives `math.floor(value)`. If you need decimal precision, do the math yourself inside the callback — e.g. divide by 10 if your real range is 0.0–10.0.

**There is no getter for widget state.**
Once `Render()` is called you cannot ask the library "what is the current slider value" or "is this toggle on." Store everything you care about in your own variables inside the callbacks.

**The Insert key won't fire while typing in chat.**
The key listener checks `gameProcessed`, so chatting won't accidentally toggle your menu.

**Tabs preserve their scroll position.**
Switching tabs does not reset the scroll. Each tab remembers where the user scrolled to.

**ColorPicker alpha does not affect the Color3.**
`Color3` in Roblox does not carry an alpha channel. The alpha bar in the picker is tracked internally but the color passed to your callback will not include it. If you need transparency, use a Slider set to 0–100 mapped to `0–1` for `BackgroundTransparency` or similar.

**Dropdown lists overlap content below them.**
When a dropdown is open, the list floats over widgets below it. This is intentional. It automatically closes when the user selects an option.

---

## Loading from GitHub

```lua
local RbxImGui = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/RobloxUI.lua"
))()

local win = RbxImGui.new("My Menu")

win:AddTab("Main")
win:Tab("Main"):Button("Test", function()
    print("It works!")
end)

win:Render()
```

Requirements:
- Game Settings → Security → **Allow HTTP Requests** must be ON
- The repository must be **public**
- Use the `raw.githubusercontent.com` URL — the normal `github.com` page URL will not work

To find the raw URL for your file: open the file on GitHub → click the **Raw** button in the top-right of the file viewer → copy the URL from your browser address bar.
