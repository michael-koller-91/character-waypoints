# potential TODOs

* can the ping cursor item be shown briefly when the player clicks? or some other indication that the click was registered?
* make the on_lua_shortcut message a language-dependent string
* make the on_path_request_finished message a language-dependent string
* make an icon for the shortcut-toolbar
* in data.lua, what is the shortcut order?
* use script.on_event("player-waypoints-move-up", player_move_input) with a custom input
  ```lua
  {
      type = "custom-input",
      name = "player-waypoints-move-up",
  	key_sequence = "",
  	linked_game_control = "move-up"
  },
  ```
  to stop walking towards the goal if the player presses a movement key
* the player should stop walking of the shortcut is clicked
* can the flying text play a sound (the "invalid" sound)?
* there are some super small gaps where the player can walk through but not when it walks automatically
