# potential TODOs

* in data.lua, what is the shortcut order?
* use script.on_event("character-waypoints-move-up", player_move_input) with a custom input
  ```lua
  {
    type = "custom-input",
    name = "character-waypoints-move-up",
  	key_sequence = "",
  	linked_game_control = "move-up"
  },
  ```
  to stop walking towards the goal if the player presses a movement key
* there are some super small gaps where the player can walk through but not when it walks automatically
