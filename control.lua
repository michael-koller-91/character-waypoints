local distance_margin = 0.5
local storage = {
    clicked_first_time = false,
    pid = {},
    pid_to_goal = {},
    pid_to_path = {},
    pid_to_path_index = {},
    pid_to_path_len = {},
    pid_to_player_index = {},
    pid_to_walk = {},
    player_to_pid = {},
}

local function remove_from_storage(pid)
    if pid then
        local player_index = storage.pid_to_player_index[pid]
        storage.pid[pid] = nil
        storage.pid_to_goal[pid] = nil
        storage.pid_to_path[pid] = nil
        storage.pid_to_path_index[pid] = nil
        storage.pid_to_path_len[pid] = nil
        storage.pid_to_player_index[pid] = nil
        storage.pid_to_walk[pid] = nil
        storage.player_to_pid[player_index] = nil
    end
end

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
    local pid = storage.player_to_pid[event.player_index]
    local player = game.players[event.player_index]

    if not player then
        return
    end
    if not player.character then
        return
    end

    if pid then -- the player recently requested a path and is currently walking
        remove_from_storage(pid)

        player.character.walking_state = {
            walking = false,
            direction = defines.direction.north
        }
        player.set_shortcut_toggled("character-waypoints-shortcut", false) -- untoggle shortcut
    else                                                                   -- request a path for the player
        local goal = event.cursor_position

        if not player.surface then
            return
        end

        -- print_gps(player, player.character.position)
        -- print_gps(player, goal)

        local pid = player.surface.request_path({
            bounding_box = player.character.prototype.collision_box,
            collision_mask = player.character.prototype.collision_mask,
            start = player.character.position,
            goal = goal,
            force = player.force,
            can_open_gates = true,
            entity_to_ignore = player.character
        })

        storage.pid[pid] = true
        storage.pid_to_goal[pid] = goal
        storage.pid_to_player_index[pid] = event.player_index
        storage.player_to_pid[event.player_index] = pid
    end
end

local function on_script_path_request_finished(event)
    if storage.pid[event.id] then
        local player = game.players[storage.pid_to_player_index[event.id]]

        if not player then
            return
        end

        if event.path then
            local path = event.path
            local path_len = #path

            if path_len > 1 then -- otherwise there is no reason to walk
                -- draw the path
                if player then
                    if not player.surface then
                        return
                    end

                    for i, p in ipairs(path) do
                        if i == path_len then
                            break
                        end

                        rendering.draw_line {
                            color = { r = 1.0, g = 0.2627, b = 0.0, a = 0.5 },
                            width = 5,
                            from = p.position,
                            to = path[i + 1].position,
                            target = storage.pid_to_goal[event.id],
                            surface = player.surface,
                            time_to_live = 60,
                            players = { LuaPlayer = player },
                            draw_on_ground = true
                        }
                    end
                end

                storage.pid_to_path[event.id] = path
                storage.pid_to_path_index[event.id] = 2
                storage.pid_to_path_len[event.id] = path_len
                storage.pid_to_walk[event.id] = true

                player.set_shortcut_toggled("character-waypoints-shortcut", true) -- toggle shortcut
            end
        else                                                                      -- failed to find a path
            if player then
                player.create_local_flying_text({
                    text = { "character-waypoints-path-request-failed" },
                    create_at_cursor = true,
                    time_to_live = 80
                })

                remove_from_storage(event.id)
            end
        end
    end
end

local function on_lua_shortcut(event)
    if event.prototype_name == "character-waypoints-shortcut" then
        local player = game.players[event.player_index]
        if not player then
            return
        end
        local pid = storage.player_to_pid[event.player_index]

        if not storage.clicked_first_time then
            storage.clicked_first_time = true
            player.print({ "character-waypoints-hint" })
        else
            if not player.is_shortcut_toggled("character-waypoints-shortcut") then
                player.create_local_flying_text({
                    text = { "character-waypoints-instructions" },
                    create_at_cursor = true,
                    time_to_live = 160
                })
            end
        end

        if pid then
            remove_from_storage(pid)

            if not player.character then
                return
            end

            player.character.walking_state = {
                walking = false,
                direction = defines.direction.north
            }
            player.set_shortcut_toggled("character-waypoints-shortcut", false) -- untoggle shortcut
            player.create_local_flying_text({
                text = { "character-waypoints-stop" },
                create_at_cursor = true
            })
        end
    end
end

local function on_tick(event)
    for pid, walk in pairs(storage.pid_to_walk) do
        local player = game.players[storage.pid_to_player_index[pid]]
        local path = storage.pid_to_path[pid]
        local path_index = storage.pid_to_path_index[pid]
        local path_len = storage.pid_to_path_len[pid]

        if walk then
            if player then
                if path then
                    if not player.character then
                        return
                    end

                    local curr_pos = player.character.position

                    if distance(curr_pos, path[path_index].position) < distance_margin then
                        path_index = path_index + 1
                        storage.pid_to_path_index[pid] = path_index
                    end

                    if path_index > path_len then
                        player.character.walking_state = { walking = false, direction = defines.direction.north }
                        remove_from_storage(pid)
                        player.set_shortcut_toggled("character-waypoints-shortcut", false) -- untoggle shortcut
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
end

script.on_event("character-waypoints-hotkey", player_waypoints_hotkey)
script.on_event(defines.events.on_lua_shortcut, on_lua_shortcut)
script.on_event(defines.events.on_script_path_request_finished, on_script_path_request_finished)
script.on_event(defines.events.on_tick, on_tick)
