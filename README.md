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
* add a map tag for the goal? ("utility.shoot_cursor_red")
* is it interesting to save the path so that walking continues when a game is loaded?
* play sound when path request fails?
* clean up storage: are all the variables necessary?
* add more `if not return` checks