# RbxImGui

A lightweight, ImGui-style immediate-mode UI library for Roblox. Create draggable, resizable debug/cheat windows with buttons, toggles, sliders, and labels — all in a few lines of Lua.

> **Toggle visibility:** Press `Insert` at any time to show or hide the window.

---

## Table of Contents

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
  - [win:Show()](#winshow)
  - [win:Hide()](#winhide)
  - [win:Toggle_Window()](#wintoggle_window)
  - [win:Destroy()](#windestroy)
- [Theming](#theming)
- [Defaults](#defaults)
- [Rules & Gotchas](#rules--gotchas)
- [Full Example](#full-example)
- [Loading from GitHub](#loading-from-github)

---

## Installation

**Option A — ModuleScript (recommended)**

1. In Roblox Studio, create a `ModuleScript` inside `ReplicatedStorage`.
2. Name it `RobloxUI`.
3. Paste the full contents of `RobloxUI.lua` into it.
4. Require it from a `LocalScript`.

**Option B — loadstring from GitHub**

```lua
local RbxImGui = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPO/main/RobloxUI.lua"
))()
```

> Requires **Allow HTTP Requests** to be enabled in Game Settings → Security.

---

## Quick Start

Place this inside a `LocalScript` under `StarterPlayer > StarterPlayerScripts`:

```lua
local RbxImGui = require(game.ReplicatedStorage.RobloxUI)

local win = RbxImGui.new("My Panel")

win:Label("Settings")
win:Separator()
win:Button("Reset Character", function()
    game.Players.LocalPlayer.Character:BreakJoints()
end)
win:Toggle("Noclip", false, function(enabled)
    -- your noclip logic here
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

RbxImGui uses a **deferred build pattern**. When you call methods like `:Button()` or `:Slider()`, they do not immediately create any UI. Instead, they queue up a builder function. When you call `:Render()`, all queued builders run in order and create the actual Roblox Instances.

This means:

- All widget calls must come **before** `:Render()`.
- `:Render()` must be called **exactly once**.
- You cannot add new widgets after `:Render()` has been called.

The window itself (the frame, title bar, scroll area, resize grip) is created immediately when you call `RbxImGui.new()`. Only the content widgets are deferred.

**Method chaining** is supported. Every widget method returns `self`, so you can chain calls:

```lua
win:Label("hello"):Separator():Button("go", cb):Render()
```

---

## API Reference

---

### `RbxImGui.new(title, parent?)`

Creates a new window and returns a window object.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `title` | `string` | Yes | Text shown in the title bar. Also used as the ScreenGui name. |
| `parent` | `Instance` | No | Where to parent the window. If `nil`, automatically creates a `ScreenGui` under `LocalPlayer.PlayerGui`. |

**Returns:** window object (all methods below are called on this)

**What it creates automatically:**
- A `ScreenGui` (if no parent provided), named `RbxImGui_<title>`
- A draggable window `Frame` at position (80, 80), default size 300×300
- A title bar with a blue accent stripe on the left and the title text
- A `ScrollingFrame` content area that auto-expands to fit widgets
- A resize grip in the bottom-right corner (drag to resize)
- An `Insert` key listener that toggles window visibility

**Example:**
```lua
local win = RbxImGui.new("Debug")
```

---

### `win:Label(text)`

Adds a static text label to the window.

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | `string` | The text to display. |

**Height:** 20px

**Example:**
```lua
win:Label("Player Info")
```

---

### `win:Separator()`

Adds a thin horizontal dividing line. Useful for grouping related widgets visually.

**Height:** 1px

**Example:**
```lua
win:Label("Section A")
win:Separator()
win:Button("Do thing", cb)
```

---

### `win:Button(label, callback)`

Adds a clickable button that fills the full width of the window.

| Parameter | Type | Description |
|-----------|------|-------------|
| `label` | `string` | Text shown on the button. |
| `callback` | `function` | Called with no arguments when the button is clicked. Can be `nil` if you don't need a callback yet. |

**Height:** 28px

**Hover/active states:** The button darkens on hover and turns blue on click, then returns to hover color on release. The callback fires on `MouseButton1Up`.

**Example:**
```lua
win:Button("Teleport to Spawn", function()
    game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(
        CFrame.new(0, 10, 0)
    )
end)
```

---

### `win:Toggle(label, defaultValue, callback)`

Adds an on/off toggle switch with an animated sliding knob.

| Parameter | Type | Description |
|-----------|------|-------------|
| `label` | `string` | Text shown to the left of the toggle. |
| `defaultValue` | `boolean` | Starting state. `true` = on, `false` = off. |
| `callback` | `function(newValue: boolean)` | Called every time the toggle is flipped. Receives the new boolean state. |

**Height:** 24px

**Behavior:** The track animates from grey (off) to blue (on). The knob slides left/right. State is tracked internally per-toggle; callbacks receive the new value each time.

**Example:**
```lua
win:Toggle("God Mode", false, function(on)
    local char = game.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.MaxHealth = on and math.huge or 100
        hum.Health = hum.MaxHealth
    end
end)
```

---

### `win:Slider(label, min, max, default, callback)`

Adds a horizontal slider for picking a numeric value in a range.

| Parameter | Type | Description |
|-----------|------|-------------|
| `label` | `string` | Text shown above the slider on the left. |
| `min` | `number` | Minimum value (left end of track). |
| `max` | `number` | Maximum value (right end of track). |
| `default` | `number` | Starting value. Clamped to `[min, max]` automatically. |
| `callback` | `function(value: number)` | Called continuously while dragging. Receives the current value as a **floored integer**. |

**Height:** 46px (16px label row + 30px track row)

**Behavior:** The current value is displayed in blue to the right of the label. The fill bar and knob update in real time as you drag. The callback fires on every mouse movement while the slider is held.

**Note:** Values passed to the callback are always `math.floor(value)` — whole integers. If you need decimal precision, you will need to modify the slider internals.

**Example:**
```lua
win:Slider("Jump Power", 0, 500, 50, function(value)
    local char = game.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = value end
end)
```

---

### `win:Render()`

Builds all queued widgets and inserts them into the scroll frame. **Must be called once, after all widget declarations.**

```lua
win:Label("hello")
win:Button("click", cb)
win:Render()  -- always last
```

Calling `:Render()` a second time will duplicate all widgets. Don't do this.

---

### `win:Show()`

Makes the window visible. Equivalent to setting `window.Visible = true`.

---

### `win:Hide()`

Hides the window. Equivalent to setting `window.Visible = false`.

---

### `win:Toggle_Window()`

Flips window visibility. Same as what the `Insert` key does.

---

### `win:Destroy()`

Destroys the entire `ScreenGui` (or parent frame), removing all UI from the game. Use this for cleanup.

---

## Theming

All colors are defined in the `THEME` table near the top of `RobloxUI.lua`. Edit these values to restyle the entire library.

| Key | What it affects |
|-----|----------------|
| `TitleBarBg` | Title bar background |
| `TitleBarText` | Title bar text color |
| `TitleBarAccent` | The blue stripe on the left of the title bar |
| `WindowBg` | Main window background |
| `WindowBorder` | Window outline/stroke color |
| `ButtonBg` | Button default background |
| `ButtonHover` | Button background when hovered |
| `ButtonActive` | Button background when held down |
| `ButtonText` | Button label color |
| `ToggleOff` | Toggle track color when off |
| `ToggleOn` | Toggle track color when on |
| `ToggleKnob` | Toggle knob color |
| `ToggleText` | Toggle label color |
| `SliderTrack` | Slider unfilled track color |
| `SliderFill` | Slider filled portion color |
| `SliderKnob` | Slider knob color |
| `SliderText` | Slider label color |
| `SliderValue` | Slider value readout color (the number) |
| `SeparatorColor` | Separator line color |
| `TextColor` | Label text color |
| `ResizeGrip` | Resize grip background |
| `ResizeGripHover` | Resize grip background on hover |
| `ScrollThumb` | Scroll bar thumb color |

**Example — change the accent to red:**
```lua
-- Edit in RobloxUI.lua before loading:
TitleBarAccent = Color3.fromRGB(220, 60, 60),
ToggleOn       = Color3.fromRGB(220, 60, 60),
ButtonActive   = Color3.fromRGB(220, 60, 60),
SliderFill     = Color3.fromRGB(220, 60, 60),
SliderValue    = Color3.fromRGB(255, 100, 100),
ResizeGripHover= Color3.fromRGB(220, 60, 60),
```

---

## Defaults

Layout and size constants are in the `DEFAULTS` table. Change these to adjust spacing and sizing globally.

| Key | Default | Description |
|-----|---------|-------------|
| `WindowWidth` | `300` | Initial window width in pixels |
| `WindowMinWidth` | `180` | Minimum width when resizing |
| `WindowMinHeight` | `100` | Minimum height when resizing |
| `TitleBarHeight` | `28` | Height of the title bar |
| `Padding` | `10` | Inner padding on all sides of the content area |
| `ItemSpacing` | `6` | Vertical gap between widgets |
| `ButtonHeight` | `28` | Height of buttons |
| `ToggleHeight` | `24` | Height of toggle rows |
| `SliderHeight` | `30` | Height of the slider track area |
| `CornerRadius` | `4` | Corner rounding on the window and buttons |
| `FontSize` | `13` | Base font size for all text |
| `ResizeGripSize` | `16` | Width and height of the resize grip square |

---

## Rules & Gotchas

**Always call `:Render()` last.** Widget methods only queue builders. Nothing is rendered until `:Render()` is called.

**Only call `:Render()` once.** Calling it again will create duplicate widgets.

**LocalScript only.** This library creates GUI instances and listens to `UserInputService`. It must run in a `LocalScript`, never a `Script` or `ModuleScript` directly.

**HTTP must be enabled for loadstring.** If loading from GitHub via `game:HttpGet`, go to Game Settings → Security → Allow HTTP Requests.

**Insert key won't fire in chat.** The `Insert` key listener checks `gameProcessed` before firing, so typing in Roblox's chat box will not accidentally toggle the window.

**Sliders return integers.** The callback always receives `math.floor(value)`. Fractional slider values are not exposed by default.

**Widget state is internal.** There is no getter for a toggle's current state or a slider's current value from outside the window. If you need to read state, store it yourself in the callback:

```lua
local currentSpeed = 16
win:Slider("Speed", 0, 100, currentSpeed, function(v)
    currentSpeed = v  -- keep your own copy
end)
```

---

## Full Example

```lua
local RbxImGui = require(game.ReplicatedStorage.RobloxUI)

-- State variables
local noclipEnabled = false
local currentSpeed  = 16
local currentJump   = 50

-- Create window
local win = RbxImGui.new("Player Mods")

-- Movement section
win:Label("Movement")
win:Separator()
win:Slider("Walk Speed", 0, 100, currentSpeed, function(v)
    currentSpeed = v
    local hum = game.Players.LocalPlayer.Character
        :FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end)
win:Slider("Jump Power", 0, 500, currentJump, function(v)
    currentJump = v
    local hum = game.Players.LocalPlayer.Character
        :FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v end
end)

-- Toggles section
win:Label("Toggles")
win:Separator()
win:Toggle("Noclip", false, function(on)
    noclipEnabled = on
end)
win:Toggle("Infinite Jump", false, function(on)
    -- your logic here
end)

-- Actions section
win:Label("Actions")
win:Separator()
win:Button("Reset Character", function()
    game.Players.LocalPlayer.Character:BreakJoints()
end)
win:Button("Respawn at Origin", function()
    local char = game.Players.LocalPlayer.Character
    if char then
        char:SetPrimaryPartCFrame(CFrame.new(0, 10, 0))
    end
end)

-- Build UI
win:Render()

-- Noclip loop (example of using toggle state externally)
game:GetService("RunService").Stepped:Connect(function()
    if noclipEnabled then
        local char = game.Players.LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)
```

---

## Loading from GitHub

If you host `RobloxUI.lua` in a public GitHub repository, you can load it at runtime without needing a ModuleScript in your game:

```lua
-- LocalScript
local RbxImGui = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/RobloxUI.lua"
))()

local win = RbxImGui.new("My Panel")
win:Button("Test", function() print("it works") end)
win:Render()
```

**Requirements:**
- Game Settings → Security → **Allow HTTP Requests** must be ON
- Your GitHub repository must be **public**
- Use the `raw.githubusercontent.com` URL — not the regular `github.com` page URL

**Getting the raw URL:**
1. Open your file on GitHub
2. Click the **Raw** button in the top right of the file viewer
3. Copy the URL from your browser — it will start with `https://raw.githubusercontent.com/`
