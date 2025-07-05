# issue TODOs

* there are some super small gaps where the player can walk through but not when it walks automatically
* if the character is very fast (e.g., mech armor with a lot of legendary legs), the `distance_margin` is too small and the mod bugs out
  * the margin should probably be based on the character's speed

# potential TODOs

* in data.lua, what is the shortcut order?
* add a map tag for the goal? ("utility.shoot_cursor_red")
* is it interesting to save the path so that walking continues when a game is loaded?
* play sound when path request fails?
* clean up storage: are all the variables necessary?
* we don't have to path find if the character wears a mech armor, it can just go in a straight line
* if waypoint request fails, go as close as possible