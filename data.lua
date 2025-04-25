local input = {
    type = "custom-input",
    name = "player-waypoints-hotkey",
    key_sequence = "ALT + W"
}

local shortcut = {
    type = "shortcut",
    name = "player-waypoints-shortcut",
    action = "lua",
    associated_control_input = "player-waypoints-hotkey",
    order = "m[player-waypoints-shortcut]",
    style = "default",
    icon = "__player-waypoints__/icon-shortcut-x56.png",
    icon_size = 56,
    small_icon = "__player-waypoints__/icon-shortcut-x24.png",
    small_icon_size = 24
}

data:extend { input, shortcut }
