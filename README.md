# RbxImGui

RbxImGui is a lightweight, ImGui-style Roblox UI library that gives you a draggable, resizable window with tabs and common menu widgets like labels, separators, buttons, toggles, sliders, dropdowns, and color pickers.

This library is designed to be loaded with a `loadstring` setup, then used through a simple builder-style API.

---

## Features

- Draggable window.
- Resizable window.
- Tab system with scrolling tab bar.
- Scrollable content area for each tab.
- Labels.
- Separators.
- Buttons.
- Toggles.
- Sliders.
- Dropdowns.
- HSV color picker.
- Overlay-based dropdown rendering.
- Hover and press animations.
- Built-in theming.
- Insert key show/hide toggle.

---

## Loading the library

The library is meant to be loaded from a raw URL using `loadstring`.

### Example
```lua
local RbxImGui = loadstring(game:HttpGet("YOUR_RAW_GITHUB_URL_HERE"))()
```

After loading it, create the UI window:

```lua
local ui = RbxImGui.new("My Menu")
```

If you do not pass a parent, the library will try to create its own `ScreenGui` and attach it to `CoreGui`, with a fallback to `PlayerGui` if needed.

---

## Creating a window

### Syntax
```lua
local ui = RbxImGui.new(title, parent)
```

### Parameters
- `title` — The title shown in the window’s title bar.
- `parent` — Optional parent GUI object.

### What it creates
- Main window frame.
- Title bar.
- Tab bar.
- Content area.
- Overlay layer for dropdowns.
- Resize grip in the bottom-right corner.

---

## Tab system

Tabs are used to organize your widgets.

### Add a tab
```lua
ui:AddTab("Main")
ui:AddTab("Settings")
```

The first tab added becomes the active tab automatically.

### Get a tab builder
```lua
local tab = ui:Tab("Main")
```

This returns a tab builder object that you use to add widgets.

---

## Widget usage

Widgets are added to tabs through the builder API.

### General pattern
```lua
local tab = ui:Tab("Main")
tab:Label("Hello")
tab:Button("Click Me", function()
    print("Button clicked")
end)
```

After you finish adding widgets, call:

```lua
ui:Render()
```

This creates all widgets in the actual UI.

---

## Labels

Labels are simple text displays.

### Syntax
```lua
tab:Label("Some text")
```

### Behavior
- Shows static text.
- No interaction.
- Useful for titles, descriptions, or status text.

### Example
```lua
tab:Label("Welcome to the menu")
```

---

## Separators

Separators are thin divider lines.

### Syntax
```lua
tab:Separator()
```

### Behavior
- Adds a visual break between sections.
- No interaction.

### Example
```lua
tab:Separator()
```

---

## Buttons

Buttons trigger actions when clicked.

### Syntax
```lua
tab:Button("Label", function()
    -- action
end)
```

### Behavior
- Changes color on hover.
- Changes color while pressed.
- Calls the callback when released after clicking.

### Example
```lua
tab:Button("Print Hello", function()
    print("Hello")
end)
```

---

## Toggles

Toggles are on/off switches.

### Syntax
```lua
tab:Toggle("Label", defaultState, function(state)
    -- state is true or false
end)
```

### Parameters
- `Label` — Text shown on the left.
- `defaultState` — Initial value, `true` or `false`.
- `callback` — Called when the toggle changes.

### Behavior
- Uses a pill-shaped track on the right.
- The knob moves left and right based on state.
- The callback receives the new boolean state.

### Example
```lua
tab:Toggle("Auto Farm", false, function(state)
    print("Auto Farm:", state)
end)
```

---

## Sliders

Sliders let the user choose a numeric value.

### Syntax
```lua
tab:Slider("Label", min, max, defaultValue, function(value)
    -- value is a number
end)
```

### Parameters
- `Label` — Text shown on the left.
- `min` — Minimum value.
- `max` — Maximum value.
- `defaultValue` — Starting value.
- `callback` — Called when the value changes.

### Behavior
- Shows the label and current value.
- Dragging the slider updates the fill bar.
- The knob moves with the cursor.
- Values are clamped between minimum and maximum.
- The callback receives the rounded value.

### Example
```lua
tab:Slider("Speed", 0, 100, 50, function(value)
    print("Speed:", value)
end)
```

---

## Dropdowns

Dropdowns let the user choose one option from a list.

### Syntax
```lua
tab:Dropdown("Label", options, function(option, index)
    -- option is the selected string
    -- index is the selected position
end)
```

### Parameters
- `Label` — Text shown above the dropdown.
- `options` — Array of strings.
- `callback` — Called when an item is selected.

### Behavior
- Clicking the button opens a floating menu.
- The menu is rendered in an overlay layer, so it is not clipped by scrolling or window bounds.
- The menu follows the button position while open.
- Clicking an item selects it, updates the button text, closes the menu, and triggers the callback.

### Example
```lua
tab:Dropdown("Mode", {"Easy", "Normal", "Hard"}, function(option, index)
    print(option, index)
end)
```

---

## Color pickers

Color pickers let the user choose a color with HSV controls.

### Syntax
```lua
tab:ColorPicker("Label", defaultColor, function(color)
    -- color is a Color3
end)
```

### Parameters
- `Label` — Name of the color setting.
- `defaultColor` — Starting `Color3`.
- `callback` — Called when the color changes.

### Behavior
- Starts as a compact row with a color swatch on the right.
- Clicking the row expands the picker inline.
- Includes a saturation/value square.
- Includes a hue bar.
- Dragging inside the square changes saturation and brightness.
- Dragging the hue bar changes the base color.
- The swatch updates live.
- The callback receives the current `Color3`.

### Example
```lua
tab:ColorPicker("Accent Color", Color3.fromRGB(82, 130, 255), function(color)
    print(color)
end)
```

---

## Window controls

### Dragging
The window can be dragged by holding the title bar.

### Resizing
The bottom-right corner is a resize grip. Drag it to change the window size.

### Visibility toggle
Press `Insert` to show or hide the window.

---

## Styling

RbxImGui uses a built-in theme for consistent colors across the UI.

### Styled elements
- Title bar.
- Tabs.
- Buttons.
- Toggles.
- Sliders.
- Dropdowns.
- Color picker.
- Window border and resize grip.

The library also uses rounded corners, border strokes, and tween animations to make interactions feel smoother.

---

## Full example

```lua
local RbxImGui = loadstring(game:HttpGet("YOUR_RAW_GITHUB_URL_HERE"))()

local ui = RbxImGui.new("Demo Menu")

ui:AddTab("Main")
ui:AddTab("Settings")

local main = ui:Tab("Main")
main:Label("Welcome to RbxImGui")
main:Separator()
main:Button("Say Hello", function()
    print("Hello from the button")
end)
main:Toggle("Auto Mode", false, function(state)
    print("Auto Mode:", state)
end)

local settings = ui:Tab("Settings")
settings:Slider("Volume", 0, 100, 75, function(value)
    print("Volume:", value)
end)
settings:Dropdown("Quality", {"Low", "Medium", "High"}, function(option, index)
    print("Quality:", option, index)
end)
settings:ColorPicker("Accent Color", Color3.fromRGB(82, 130, 255), function(color)
    print("Accent changed:", color)
end)

ui:Render()
```

---

## API reference

### `RbxImGui.new(title, parent)`
Creates a new UI instance.

### `ui:AddTab(name)`
Adds a tab.

### `ui:Tab(name)`
Returns a tab builder for the tab.

### `tab:Label(text)`
Adds a label.

### `tab:Separator()`
Adds a separator line.

### `tab:Button(label, callback)`
Adds a button.

### `tab:Toggle(label, defaultState, callback)`
Adds a toggle.

### `tab:Slider(label, min, max, defaultValue, callback)`
Adds a slider.

### `tab:Dropdown(label, options, callback)`
Adds a dropdown.

### `tab:ColorPicker(label, defaultColor, callback)`
Adds a color picker.

### `ui:Render()`
Builds all added widgets into the UI.

### `ui:Show()`
Shows the window.

### `ui:Hide()`
Hides the window.

### `ui:ToggleWindow()`
Toggles window visibility.

### `ui:Destroy()`
Destroys the entire UI.

---

## Notes

- Call `:Render()` after adding your widgets.
- Tabs must be created with `:AddTab()` before using `:Tab()`.
- Dropdown menus render in an overlay so they behave correctly even inside scrollable content.
- The color picker expands inline instead of opening as a floating window.

---

## Quick reference

```lua
local ui = RbxImGui.new("Title")
ui:AddTab("Main")

local tab = ui:Tab("Main")
tab:Label("Text")
tab:Separator()
tab:Button("Button", function() end)
tab:Toggle("Toggle", true, function(v) end)
tab:Slider("Slider", 0, 100, 50, function(v) end)
tab:Dropdown("Dropdown", {"A", "B"}, function(choice, index) end)
tab:ColorPicker("Color", Color3.fromRGB(255,255,255), function(color) end)

ui:Render()
```
