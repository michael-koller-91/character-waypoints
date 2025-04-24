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

local function print_gps(player, pos)
    player.print("[gps=" .. round(pos.x) .. "," .. round(pos.y) .. ",nauvis]")
end

local function get_direction(s, t)
    -- * The available directions are:
    -- defines.direction.north          -- 0
    -- defines.direction.northnortheast -- 1
    -- defines.direction.northeast
    -- defines.direction.eastnortheast
    -- defines.direction.east           -- 4
    -- defines.direction.eastsoutheast
    -- defines.direction.southeast
    -- defines.direction.southsoutheast
    -- defines.direction.south          -- 8
    -- defines.direction.southsouthwest
    -- defines.direction.southwest
    -- defines.direction.westsouthwest
    -- defines.direction.west           -- 12
    -- defines.direction.westnorthwest
    -- defines.direction.northwest
    -- defines.direction.northnorthwest -- 15

    local delta_x = t.x - s.x
    local delta_y = t.y - s.y
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
    return math.fmod(round(16 + angle16 - 4), 16)
end

local function distance(s, t)
    local delta_x = math.abs(t.x - s.x)
    local delta_y = math.abs(t.y - s.y)
    return math.max(delta_x, delta_y)
end

local function player_waypoints_hotkey(event)
    if walk then
        walk = false
    else
        player = game.players[event.player_index]
        local surface = player.surface
        local char = player.character
        start = player.character.position
        goal = event.cursor_position

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
            if player then
                player.create_local_flying_text({
                    text = tostring(path_len),
                    create_at_cursor = true,
                    time_to_live = 80
                })
            end
            if path_len > 1 then
                walk = true
                path_index = 2
            else
                walk = false
            end
        else
            if player then
                player.create_local_flying_text({
                    text = "Did not find a path. Try again.",
                    create_at_cursor = true,
                    time_to_live = 80
                })
            end
        end
    end
end

local function on_lua_shortcut(event)
    walk = false
    game.players[event.player_index].character.walking_state = { walking = false, direction = defines.direction.north }
    game.players[event.player_index].create_local_flying_text({
        text = "Move the cursor to the goal position and use the shortcut key.",
        create_at_cursor = true,
        time_to_live = 160
    })
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
