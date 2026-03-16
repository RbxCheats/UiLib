# RbxImGui

A lightweight, ImGui-style immediate-mode UI library for Roblox. Create draggable, resizable debug/cheat windows with buttons, toggles, sliders, and labels — all in a few lines of Lua. Renders into `CoreGui` so it survives respawns and sits above all in-game UI.

> **Toggle visibility:** Press `Insert` at any time to show or hide the window.

---

## Table of Contents

- [What It Looks Like](#what-it-looks-like)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [API Reference](#api-reference)
  - [RbxImGui.new()](#rbximguinew)
  - [win:Label()](#winlabel)
  - [win:Separator()](#winseparator)
  - [win:Button()](#winbutton)
  - [win:Toggle()](#wintoggle)
  - [win:Slider()](#winslider)
  - [win:Render()](#winrender)
  - [win:Show() / win:Hide()](#winshow--winhide)
  - [win:Toggle_Window()](#wintoggle_window)
  - [win:Destroy()](#windestroy)
- [Showcase Example](#showcase-example)
- [Feature Deep Dive & Possibilities](#feature-deep-dive--possibilities)
  - [Label Possibilities](#label-possibilities)
  - [Separator Possibilities](#separator-possibilities)
  - [Button Possibilities](#button-possibilities)
  - [Toggle Possibilities](#toggle-possibilities)
  - [Slider Possibilities](#slider-possibilities)
- [Theming](#theming)
- [Defaults](#defaults)
- [Rules & Gotchas](#rules--gotchas)
- [Loading from GitHub](#loading-from-github)

---

## What It Looks Like

Below is a visual map of the default window and every widget type, produced by the showcase code later in this README.

```
┌─────────────────────────────────┐
│▌ Player Mods                    │  ← Title bar (draggable)
├─────────────────────────────────┤
│  Movement                       │  ← Label
│ ──────────────────────────────  │  ← Separator
│  Walk Speed              16     │  ← Slider (label left, value right)
│  [████●──────────────────]      │    filled track + knob
│  Jump Power              50     │
│  [══════════●────────────]      │
│  FOV                     70     │
│  [═════════════════●─────]      │
│                                 │
│  Toggles                        │  ← Label
│ ──────────────────────────────  │  ← Separator
│  Noclip            [ ●   ]      │  ← Toggle OFF (grey track, knob left)
│  God Mode          [   ● ]      │  ← Toggle ON  (blue track, knob right)
│  Infinite Jump     [ ●   ]      │
│                                 │
│  Actions                        │  ← Label
│ ──────────────────────────────  │  ← Separator
│ [ Reset Character             ] │  ← Button (full width)
│ [ Teleport to Spawn           ] │
│ [ Print Player Info           ] │
│                                 │
└─────────────────────────────[◢] ┘  ← Resize grip (drag to resize)
```

The window is:
- **Draggable** — click and hold the title bar to move it anywhere on screen
- **Resizable** — drag the grip in the bottom-right corner to any size
- **Scrollable** — if content overflows the window height a scrollbar appears
- **Togglable** — press `Insert` to show or hide it at any time

---

## Installation

**Option A — ModuleScript (recommended for Studio projects)**

1. In Roblox Studio, create a `ModuleScript` inside `ReplicatedStorage`
2. Name it `RobloxUI`
3. Paste the full contents of `RobloxUI.lua` into it
4. Require it from a `LocalScript` under `StarterPlayer > StarterPlayerScripts`

```
ReplicatedStorage
  └── RobloxUI              ← ModuleScript, paste the library here

StarterPlayer
  └── StarterPlayerScripts
        └── MyScript        ← LocalScript, your code goes here
```

**Option B — loadstring from GitHub (no Studio setup needed)**

```lua
local RbxImGui = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPO/main/RobloxUI.lua"
))()
```

> Requires **Allow HTTP Requests** enabled in Game Settings → Security.

---

## Quick Start

```lua
local RbxImGui = require(game.ReplicatedStorage.RobloxUI)

local win = RbxImGui.new("My Panel")

win:Label("Settings")
win:Separator()
win:Button("Reset Character", function()
    game.Players.LocalPlayer.Character:BreakJoints()
end)
win:Toggle("Noclip", false, function(enabled)
    print("Noclip:", enabled)
end)
win:Slider("Walk Speed", 0, 100, 16, function(value)
    local char = game.Players.LocalPlayer.Character
    if char then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = value
    end
end)

win:Render()
```

Press **Insert** to toggle the window on and off.

---

## How It Works

RbxImGui uses a **deferred build pattern**. Calling widget methods like `:Button()` or `:Slider()` does not immediately create any UI — it queues a builder function. When you call `:Render()`, all queued builders run in order and create the actual Roblox Instances.

```
RbxImGui.new()   →  creates the window shell immediately
:Button()        →  queues a builder  (no UI yet)
:Toggle()        →  queues a builder  (no UI yet)
:Slider()        →  queues a builder  (no UI yet)
:Render()        →  runs all builders, creates all widgets NOW
```

**This means:**
- All widget calls must come **before** `:Render()`
- `:Render()` must be called **exactly once**
- You cannot add new widgets after `:Render()` has been called

**Method chaining** is supported — every widget method returns `self`:

```lua
win:Label("hello"):Separator():Button("go", cb):Render()
```

**CoreGui parenting** — the ScreenGui is placed in `CoreGui` automatically:
- Renders above all in-game UI (health bars, backpack, leaderboard, etc.)
- Survives death and respawn with no extra setup
- Falls back silently to `PlayerGui` when running inside Studio without plugin permissions

---

## API Reference

---

### `RbxImGui.new(title, parent?)`

Creates a new window and returns a window object. This is the only call made on the library itself — all other methods are called on the returned object.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `title` | `string` | Yes | Text shown in the title bar. Also names the ScreenGui `RbxImGui_<title>`. |
| `parent` | `Instance` | No | Override the ScreenGui parent. Leave `nil` to use CoreGui automatically. |

**Returns:** window object

**Creates automatically:**
- `ScreenGui` in `CoreGui` (fallback: `PlayerGui`), `DisplayOrder = 999`
- Draggable `Frame` at position `(80, 80)`, default size `300×300`
- Title bar with a blue left-edge accent stripe and bold title text
- `ScrollingFrame` content area with auto-expanding canvas
- Resize grip in the bottom-right corner
- `Insert` key listener that respects `gameProcessed`

```lua
local win = RbxImGui.new("Debug Panel")
```

---

### `win:Label(text)`

Adds a static, non-interactive text label.

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | `string` | The text to display. |

**Height:** 20px

```lua
win:Label("Movement Settings")
```

---

### `win:Separator()`

Adds a 1px horizontal rule across the full content width. No parameters.

**Height:** 1px

```lua
win:Label("Section A")
win:Separator()
win:Button("Action", cb)
```

---

### `win:Button(label, callback)`

Adds a clickable button spanning the full content width.

| Parameter | Type | Description |
|-----------|------|-------------|
| `label` | `string` | Text shown on the button face. |
| `callback` | `function()` | Called with no arguments on click. Can be `nil` as a placeholder. |

**Height:** 28px

**Interaction states:**
| State | Color |
|-------|-------|
| Default | Dark grey `RGB(52, 52, 68)` |
| Hover | Lighter grey `RGB(72, 72, 100)` |
| Held | Accent blue `RGB(82, 130, 255)` |
| Released | Returns to hover, callback fires |

The callback fires on `MouseButton1Up`. If you hold and drag off the button, the callback does not fire.

```lua
win:Button("Teleport to Spawn", function()
    game.Players.LocalPlayer.Character
        :SetPrimaryPartCFrame(CFrame.new(0, 10, 0))
end)
```

---

### `win:Toggle(label, defaultValue, callback)`

Adds an on/off switch with an animated sliding knob.

| Parameter | Type | Description |
|-----------|------|-------------|
| `label` | `string` | Text shown to the left of the switch. |
| `defaultValue` | `boolean` | Starting state. `true` = on (blue). `false` = off (grey). |
| `callback` | `function(newValue: boolean)` | Fired every time the toggle is clicked. Receives the new boolean state. |

**Height:** 24px | **Track:** 36×18px | **Knob:** 14×14px

**Visual states:**
| State | Track | Knob position |
|-------|-------|---------------|
| Off | Grey | Left side |
| On | Blue | Right side |

Both track color and knob position animate via TweenService (0.15s Quad ease-out).

```lua
win:Toggle("God Mode", false, function(on)
    local hum = game.Players.LocalPlayer.Character
        :FindFirstChildOfClass("Humanoid")
    if hum then
        hum.MaxHealth = on and math.huge or 100
        hum.Health    = hum.MaxHealth
    end
end)
```

---

### `win:Slider(label, min, max, default, callback)`

Adds a horizontal drag slider for selecting a number within a range.

| Parameter | Type | Description |
|-----------|------|-------------|
| `label` | `string` | Text shown above the track on the left. |
| `min` | `number` | Value at the far left of the track. |
| `max` | `number` | Value at the far right of the track. |
| `default` | `number` | Starting value. Clamped to `[min, max]` automatically. |
| `callback` | `function(value: number)` | Fires continuously while dragging. Always a whole integer (`math.floor`). |

**Total height:** 46px (16px label row + 30px track row)

**Layout:**
```
Walk Speed                    16    ← label (left) + value (right, blue)
[████████●──────────────────]       ← filled track + knob
```

The callback fires on every mouse movement while the slider is held — your logic runs in real time as the user drags.

```lua
win:Slider("Walk Speed", 0, 100, 16, function(v)
    local hum = game.Players.LocalPlayer.Character
        :FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end)
```

---

### `win:Render()`

Executes all queued widget builders and inserts them into the window. **Call exactly once, after all widget declarations.**

```lua
win:Label("hello")
win:Button("go", cb)
win:Render()  -- always last
```

---

### `win:Show() / win:Hide()`

Directly control window visibility.

```lua
win:Hide()  -- start hidden, player opens with Insert
win:Show()  -- force visible
```

---

### `win:Toggle_Window()`

Flip window visibility. Same as what `Insert` does.

```lua
win:Toggle_Window()
```

---

### `win:Destroy()`

Destroys the entire ScreenGui. Use for full cleanup when you no longer need the window.

```lua
win:Destroy()
```

---

## Showcase Example

This is the default demo window using every feature. It follows the recommended structure for a real panel. Copy it into a `LocalScript` under `StarterPlayer > StarterPlayerScripts`.

```lua
-- ================================================================
--  RbxImGui Showcase — full demo using every widget type
--  LocalScript → StarterPlayer > StarterPlayerScripts
-- ================================================================
local RbxImGui = require(game.ReplicatedStorage.RobloxUI)
local Players  = game:GetService("Players")
local RS       = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")

local lp = Players.LocalPlayer

-- Helper functions so we never error if the character isn't loaded yet
local function getHum()
    local char = lp.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local char = lp.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ── State ─────────────────────────────────────────────────────────
-- Store toggle/slider values here so loops and other code can read them
local state = {
    noclip       = false,
    godMode      = false,
    infiniteJump = false,
    walkSpeed    = 16,
    jumpPower    = 50,
    fov          = 70,
}

-- ── Window ────────────────────────────────────────────────────────
local win = RbxImGui.new("Player Mods")

-- ════════════════════════════════════════════════════════════════
--  MOVEMENT
-- ════════════════════════════════════════════════════════════════
win:Label("Movement")
win:Separator()

win:Slider("Walk Speed", 0, 100, state.walkSpeed, function(v)
    state.walkSpeed = v
    local hum = getHum()
    if hum then hum.WalkSpeed = v end
end)

win:Slider("Jump Power", 0, 500, state.jumpPower, function(v)
    state.jumpPower = v
    local hum = getHum()
    if hum then hum.JumpPower = v end
end)

win:Slider("FOV", 30, 120, state.fov, function(v)
    state.fov = v
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = v end
end)

-- ════════════════════════════════════════════════════════════════
--  TOGGLES
-- ════════════════════════════════════════════════════════════════
win:Label("Toggles")
win:Separator()

win:Toggle("Noclip", false, function(on)
    state.noclip = on
    if not on then
        -- restore collision on all character parts when turned off
        local char = lp.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end)

win:Toggle("God Mode", false, function(on)
    state.godMode = on
    local hum = getHum()
    if hum then
        hum.MaxHealth = on and math.huge or 100
        hum.Health    = hum.MaxHealth
    end
end)

-- Infinite Jump uses a connection that is created/destroyed with the toggle
local jumpConn
win:Toggle("Infinite Jump", false, function(on)
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

-- ════════════════════════════════════════════════════════════════
--  ACTIONS
-- ════════════════════════════════════════════════════════════════
win:Label("Actions")
win:Separator()

win:Button("Reset Character", function()
    local char = lp.Character
    if char then char:BreakJoints() end
end)

win:Button("Teleport to Spawn", function()
    local root = getRoot()
    if root then root.CFrame = CFrame.new(0, 10, 0) end
end)

win:Button("Print Player Info", function()
    local hum  = getHum()
    local root = getRoot()
    print("=== Player Info ===")
    print("Name     :", lp.Name)
    print("UserId   :", lp.UserId)
    if hum  then
        print("Health   :", hum.Health, "/", hum.MaxHealth)
        print("WalkSpeed:", hum.WalkSpeed)
        print("JumpPower:", hum.JumpPower)
    end
    if root then print("Position :", root.Position) end
    print("===================")
end)

-- ════════════════════════════════════════════════════════════════
--  BUILD — must always be last
-- ════════════════════════════════════════════════════════════════
win:Render()
win:Hide()  -- hidden by default; press Insert to open

-- ════════════════════════════════════════════════════════════════
--  LOOPS — run after Render, use state flags set by callbacks
-- ════════════════════════════════════════════════════════════════

-- Noclip: disable CanCollide every physics step while active
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

**What this produces:**

```
┌──────────────────────────────────┐
│▌ Player Mods                     │
├──────────────────────────────────┤
│  Movement                        │
│ ─────────────────────────────    │
│  Walk Speed               16     │
│  [████●────────────────────]     │
│  Jump Power               50     │
│  [══════════●──────────────]     │
│  FOV                      70     │
│  [═════════════════●───────]     │
│                                  │
│  Toggles                         │
│ ─────────────────────────────    │
│  Noclip            [ ●   ]       │
│  God Mode          [ ●   ]       │
│  Infinite Jump     [ ●   ]       │
│                                  │
│  Actions                         │
│ ─────────────────────────────    │
│ [ Reset Character              ] │
│ [ Teleport to Spawn            ] │
│ [ Print Player Info            ] │
└──────────────────────────────[◢] ┘
```

---

## Feature Deep Dive & Possibilities

---

### Label Possibilities

Labels display any static string. The text is set at build time and cannot be changed after `:Render()`.

**Section header (most common use):**
```lua
win:Label("Movement")
win:Separator()
```

**Version or credit line:**
```lua
win:Label("v1.2.0  |  github.com/you/rbximgui")
```

**Inline instructions:**
```lua
win:Label("Press Insert to hide this panel")
```

**Visual text divider:**
```lua
win:Label("──── Danger Zone ────────────────")
```

**Limitation:** Labels cannot be updated after `:Render()`. If you need a live value displayed (e.g. current health), you would need to store a reference to the underlying `TextLabel` instance and update its `.Text` manually, or rebuild the entire window.

---

### Separator Possibilities

A separator is a purely visual 1px horizontal line. Its only job is to help the eye group widgets together.

**Classic: label + separator = section header:**
```lua
win:Label("Combat")
win:Separator()
win:Toggle("Aimbot", false, cb)
win:Toggle("Silent Aim", false, cb)
```

**Separator between two groups without a label:**
```lua
win:Button("Safe Action", cb)
win:Button("Safe Action 2", cb)
win:Separator()
win:Button("Dangerous Action", cb)  -- visually separated for safety
```

**Double separator for a strong visual break:**
```lua
win:Separator()
win:Label("Admin Only")
win:Separator()
win:Button("Shutdown Server", cb)
```

---

### Button Possibilities

Buttons are the most flexible widget — the callback is a plain Lua function and can do anything a LocalScript is allowed to do.

**Teleportation:**
```lua
win:Button("Go to Player", function()
    local target = game.Players:FindFirstChild("TargetName")
    if target and target.Character then
        getRoot().CFrame = target.Character.HumanoidRootPart.CFrame
    end
end)
```

**Spawning objects into the world:**
```lua
win:Button("Spawn Part", function()
    local part     = Instance.new("Part")
    part.Size      = Vector3.new(4, 4, 4)
    part.Position  = getRoot().Position + Vector3.new(0, 5, 0)
    part.Parent    = workspace
end)
```

**Firing a RemoteEvent to the server:**
```lua
win:Button("Buy Sword", function()
    game.ReplicatedStorage.ShopEvent:FireServer("Sword")
end)
```

**Printing debug info to the output:**
```lua
win:Button("Dump Workspace", function()
    for _, v in ipairs(workspace:GetChildren()) do
        print(v.Name, v.ClassName)
    end
end)
```

**Toggling another module on or off:**
```lua
local esp = require(script.Parent.EspModule)
win:Button("Toggle ESP", function()
    esp.toggle()
end)
```

**Self-hiding the panel:**
```lua
win:Button("Close Panel", function()
    win:Hide()
end)
```

**Clipboard copy (in supported executors):**
```lua
win:Button("Copy UserId", function()
    if setclipboard then
        setclipboard(tostring(lp.UserId))
    end
end)
```

---

### Toggle Possibilities

Toggles are best for any behavior that is either running or not running over time — persistent loops, event listeners, overrides.

**Persistent loop behavior (noclip, effect that runs every frame):**
```lua
local active = false
win:Toggle("Noclip", false, function(on) active = on end)

game:GetService("RunService").Stepped:Connect(function()
    if active then
        for _, p in ipairs(lp.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)
```

**Connecting and disconnecting an event listener:**
```lua
local conn
win:Toggle("Auto-Farm", false, function(on)
    if on then
        conn = workspace.Items.ChildAdded:Connect(function(item)
            -- pick up / interact with item
        end)
    else
        if conn then conn:Disconnect() conn = nil end
    end
end)
```

**Switching between two WalkSpeed modes:**
```lua
win:Toggle("Sprint", false, function(on)
    local hum = getHum()
    if hum then hum.WalkSpeed = on and 50 or 16 end
end)
```

**Starting as ON by default:**
```lua
-- Pass true as the second argument to start in the enabled state
win:Toggle("Show Names", true, function(on)
    -- runs immediately in the ON state when the window opens
end)
```

**Two mutually exclusive toggles:**
```lua
-- Since the library doesn't expose a setter, use flags to enforce exclusivity
local isSilent, isAimbot = false, false

win:Toggle("Aimbot", false, function(on)
    isSilent = false  -- force the other off in your own logic
    isAimbot = on
end)
win:Toggle("Silent Aim", false, function(on)
    isAimbot = false
    isSilent = on
end)
```

---

### Slider Possibilities

Sliders work for any continuous numeric value — speed, size, transparency, color intensity, gravity, delay timers, and more.

**Player movement stats:**
```lua
win:Slider("Walk Speed",  0,   500, 16,  function(v) getHum().WalkSpeed = v end)
win:Slider("Jump Power",  0,   500, 50,  function(v) getHum().JumpPower  = v end)
win:Slider("Hip Height",  0,   10,  2,   function(v) getHum().HipHeight  = v end)
```

**Camera control:**
```lua
win:Slider("FOV", 30, 120, 70, function(v)
    workspace.CurrentCamera.FieldOfView = v
end)
```

**World gravity:**
```lua
win:Slider("Gravity", 0, 200, 196, function(v)
    workspace.Gravity = v
end)
```

**Lighting time of day:**
```lua
win:Slider("Time of Day", 0, 24, 12, function(v)
    game:GetService("Lighting").TimeOfDay = string.format("%02d:00:00", v)
end)
```

**Part transparency (e.g. ESP boxes):**
```lua
win:Slider("Box Opacity", 0, 100, 80, function(v)
    espBox.BackgroundTransparency = v / 100
end)
```

**Auto-action repeat delay:**
```lua
local delay = 1
win:Slider("Auto-Click Delay (s)", 1, 10, 1, function(v) delay = v end)
```

**Reading the value outside the callback** — sliders have no getter, so store the value yourself:
```lua
local speed = 16
win:Slider("Speed", 0, 100, speed, function(v)
    speed = v  -- always up to date
end)

-- Anywhere else in your code, just read `speed` directly
game:GetService("RunService").Heartbeat:Connect(function()
    -- speed is always current here
end)
```

---

## Theming

All colors are defined in the `THEME` table near the top of `RobloxUI.lua`. Every key controls one visual element.

| Key | Affects |
|-----|---------|
| `TitleBarBg` | Title bar background |
| `TitleBarText` | Title text color |
| `TitleBarAccent` | Left-edge blue stripe |
| `WindowBg` | Main window background |
| `WindowBorder` | Window outline |
| `ButtonBg` | Button resting color |
| `ButtonHover` | Button on mouse hover |
| `ButtonActive` | Button while held |
| `ButtonText` | Button label color |
| `ToggleOff` | Toggle track when off |
| `ToggleOn` | Toggle track when on |
| `ToggleKnob` | Toggle knob |
| `ToggleText` | Toggle label color |
| `SliderTrack` | Unfilled track color |
| `SliderFill` | Filled portion of track |
| `SliderKnob` | Slider knob |
| `SliderText` | Slider label color |
| `SliderValue` | Slider number readout |
| `SeparatorColor` | Separator line |
| `TextColor` | Label text |
| `ResizeGrip` | Resize grip background |
| `ResizeGripHover` | Resize grip on hover |
| `ScrollThumb` | Scrollbar thumb |

**Red accent theme:**
```lua
TitleBarAccent  = Color3.fromRGB(220, 60,  60),
ToggleOn        = Color3.fromRGB(220, 60,  60),
ButtonActive    = Color3.fromRGB(220, 60,  60),
SliderFill      = Color3.fromRGB(220, 60,  60),
SliderValue     = Color3.fromRGB(255, 100, 100),
ResizeGripHover = Color3.fromRGB(220, 60,  60),
```

**Green hacker theme:**
```lua
TitleBarBg      = Color3.fromRGB(10,  20,  10),
TitleBarAccent  = Color3.fromRGB(0,   200, 80),
TitleBarText    = Color3.fromRGB(80,  255, 140),
WindowBg        = Color3.fromRGB(8,   14,  8),
WindowBorder    = Color3.fromRGB(0,   80,  30),
ButtonBg        = Color3.fromRGB(15,  40,  20),
ButtonHover     = Color3.fromRGB(20,  60,  30),
ButtonActive    = Color3.fromRGB(0,   200, 80),
ToggleOn        = Color3.fromRGB(0,   200, 80),
SliderFill      = Color3.fromRGB(0,   200, 80),
SliderValue     = Color3.fromRGB(80,  255, 140),
TextColor       = Color3.fromRGB(80,  255, 140),
ToggleText      = Color3.fromRGB(80,  255, 140),
SliderText      = Color3.fromRGB(80,  255, 140),
```

---

## Defaults

Layout constants in the `DEFAULTS` table at the top of `RobloxUI.lua` control sizing and spacing globally.

| Key | Default | Description |
|-----|---------|-------------|
| `WindowWidth` | `300` | Initial window width in pixels |
| `WindowMinWidth` | `180` | Minimum width when resizing |
| `WindowMinHeight` | `100` | Minimum height when resizing |
| `TitleBarHeight` | `28` | Title bar height |
| `Padding` | `10` | Content area inner padding (all sides) |
| `ItemSpacing` | `6` | Vertical gap between widgets |
| `ButtonHeight` | `28` | Button height |
| `ToggleHeight` | `24` | Toggle row height |
| `SliderHeight` | `30` | Slider track row height |
| `CornerRadius` | `4` | Corner rounding on the window and buttons |
| `FontSize` | `13` | Base font size for all text |
| `ResizeGripSize` | `16` | Size of the resize grip square |

---

## Rules & Gotchas

**Always call `:Render()` last.** Widget methods only queue work — nothing is visible until `:Render()` runs.

**Call `:Render()` exactly once.** Calling it again duplicates every widget with no way to undo it.

**LocalScript only.** The library uses `UserInputService` and creates GUI Instances. It cannot run in a server `Script`.

**Sliders return integers.** The callback always receives `math.floor(value)`. If you need decimals you will need to modify the slider internals.

**Widget state is internal.** There is no getter for a toggle's current state or a slider's current value from outside the window. Store state in your own variables via the callback:

```lua
local mySpeed = 16
win:Slider("Speed", 0, 100, mySpeed, function(v)
    mySpeed = v  -- keep your own copy, readable anywhere
end)
```

**Insert won't fire while chatting.** The listener checks `gameProcessed` so pressing `Insert` in Roblox's chat box does nothing.

**HTTP must be on for loadstring.** Enable it under Game Settings → Security → Allow HTTP Requests before using `game:HttpGet`.

---

## Loading from GitHub

Host `RobloxUI.lua` in a public repo and load it at runtime with no Studio setup required:

```lua
-- LocalScript
local RbxImGui = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/RobloxUI.lua"
))()

local win = RbxImGui.new("My Panel")
win:Button("Test", function() print("works") end)
win:Render()
```

**Requirements:**
- Game Settings → Security → **Allow HTTP Requests** must be ON
- Repository must be **public**
- URL must start with `https://raw.githubusercontent.com/` — not the regular GitHub page URL

**Getting the raw URL:**
1. Open your file on GitHub
2. Click **Raw** in the top-right of the file viewer
3. Copy the URL from your browser address bar
