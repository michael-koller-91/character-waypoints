local player = nil
local distance_margin = 0.5
local start = nil
local goal = nil
local path = nil
local path_len = nil
local path_index = nil
local pid = nil
local walk = false

local function round(v)
    return math.floor(v + 0.5)
end

-- for debugging
local function print_gps(player, pos)
    player.print("[gps=" .. round(pos.x) .. "," .. round(pos.y) .. ",nauvis]")
end

-- Get the direction pointing from point `s` (start) to point `g` (goal).
-- The available directions are:
-- * defines.direction.north          -- 0
-- * defines.direction.northnortheast -- 1
-- * defines.direction.northeast
-- * defines.direction.eastnortheast
-- * defines.direction.east           -- 4
-- * defines.direction.eastsoutheast
-- * defines.direction.southeast
-- * defines.direction.southsoutheast
-- * defines.direction.south          -- 8
-- * defines.direction.southsouthwest
-- * defines.direction.southwest
-- * defines.direction.westsouthwest
-- * defines.direction.west           -- 12
-- * defines.direction.westnorthwest
-- * defines.direction.northwest
-- * defines.direction.northnorthwest -- 15
local function get_direction(s, g)
    local delta_x = g.x - s.x
    local delta_y = g.y - s.y
    -- * We have:
    -- (delta_y, delta_x) = (1, 0)  <=> south
    -- (delta_y, delta_x) = (-1, 0) <=> north
    -- (delta_y, delta_x) = (0, 1)  <=> east
    -- (delta_y, delta_x) = (0, -1) <=> west

    local angle = math.atan2(delta_y, delta_x) / math.pi
    -- * Converting this into an angle yields:
    -- math.atan(1, 0)  / pi = 0.5  <=>  south (supposed to be 8)
    -- math.atan(-1, 0) / pi = -0.5 <=>  north (supposed to be 0)
    -- math.atan(0, 1)  / pi = 0    <=>  east  (supposed to be 4)
    -- math.atan(0, -1) / pi = 1    <=>  west  (supposed to be 12)

    local angle16 = 8 * (angle + 1)
    -- * We map from (-1, 1] to (0, 16] and have:
    -- 8 * (math.atan(1, 0)  / pi + 1) = 12 (supposed to be 8)
    -- 8 * (math.atan(-1, 0) / pi + 1) = 4  (supposed to be 0)
    -- 8 * (math.atan(0, 1)  / pi + 1) = 8  (supposed to be 4)
    -- 8 * (math.atan(0, -1) / pi + 1) = 16 (supposed to be 12)

    -- * So, we need a rotation to arrive at the target numbers:
    return math.fmod(round(12 + angle16), 16)
end

local function distance(s, g)
    local delta_x = math.abs(g.x - s.x)
    local delta_y = math.abs(g.y - s.y)
    return math.max(delta_x, delta_y)
end

local function player_waypoints_hotkey(event)
    if walk then
        walk = false
        game.players[event.player_index].character.walking_state = {
            walking = false,
            direction = defines.direction.north
        }
        game.players[event.player_index].create_local_flying_text({
            text = "Stop walking.",
            position = game.players[event.player_index].character.position,
            time_to_live = 80
        })
    else
        player = game.players[event.player_index]
        local surface = player.surface
        local char = player.character
        start = player.character.position
        goal = event.cursor_position

        -- rendering.draw_sprite {
        --     sprite = "utility.shoot_cursor_red",
        --     time_to_live = 60,
        --     target = goal,
        --     x_scale = 0.5,
        --     y_scale = 0.5,
        --     surface = player.surface,
        --     players = { LuaPlayer = player }
        -- }

        -- print_gps(player, start)
        -- print_gps(player, goal)

        pid = surface.request_path({
            bounding_box = char.prototype.collision_box,
            collision_mask = char.prototype.collision_mask,
            start = start,
            goal = goal,
            force = player.force,
            can_open_gates = true,
            entity_to_ignore = char
        })
    end
end

local function on_script_path_request_finished(event)
    if event.id == pid then
        if event.path then
            path = event.path
            path_len = #path
            if path_len > 1 then
                walk = true
                path_index = 2

                if player then
                    for i, p in ipairs(path) do
                        if i == path_len then
                            break
                        end
                        rendering.draw_line {
                            color = { r = 1.0, g = 0.2627, b = 0.0, a = 0.5 },
                            width = 5,
                            from = p.position,
                            to = path[i + 1].position,
                            target = goal,
                            surface = player.surface,
                            time_to_live = 60,
                            players = { LuaPlayer = player },
                            draw_on_ground = true
                        }
                    end
                end
            else
                walk = false
            end
        else
            if player then
                player.create_local_flying_text({
                    text = "Did not find a path.",
                    create_at_cursor = true,
                    time_to_live = 80
                })
            end
        end
    end
end

local function on_lua_shortcut(event)
    if event.prototype_name == "player-waypoints-shortcut" then
        walk = false
        game.players[event.player_index].character.walking_state = {
            walking = false,
            direction = defines.direction.north
        }
        game.players[event.player_index].create_local_flying_text({
            text = "Move the cursor to the goal position and use the shortcut key.",
            create_at_cursor = true,
            time_to_live = 160
        })
    end
end

local function on_tick(event)
    if walk then
        if player then
            if path then
                local curr_pos = player.character.position

                if distance(curr_pos, path[path_index].position) < distance_margin then
                    path_index = path_index + 1
                end

                if path_index > path_len then
                    walk = false
                    player.character.walking_state = { walking = false, direction = defines.direction.north }
                    -- print("walk = false at distance " .. distance(curr_pos, path[path_len].position))
                else
                    local dir = get_direction(curr_pos, path[path_index].position)
                    if dir then
                        player.character.walking_state = { walking = true, direction = dir }
                    end
                end
            end
        end
    end
end

script.on_event("player-waypoints-hotkey", player_waypoints_hotkey)
script.on_event(defines.events.on_lua_shortcut, on_lua_shortcut)
script.on_event(defines.events.on_script_path_request_finished, on_script_path_request_finished)
script.on_event(defines.events.on_tick, on_tick)
