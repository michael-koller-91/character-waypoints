local input = {
    type = "custom-input",
    name = "character-waypoints-hotkey",
    key_sequence = "ALT + W"
}

local shortcut = {
    type = "shortcut",
    name = "character-waypoints-shortcut",
    action = "lua",
    associated_control_input = "character-waypoints-hotkey",
    order = "m[character-waypoints-shortcut]",
    style = "default",
    icon = "__character-waypoints__/graphics/icon-shortcut-x56.png",
    icon_size = 56,
    small_icon = "__character-waypoints__/graphics/icon-shortcut-x24.png",
    small_icon_size = 24
}

data:extend { input, shortcut }
