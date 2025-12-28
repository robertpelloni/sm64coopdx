-- name: System - Guilds
-- description: Guild system for MMORPG social structure.

function guild_init()
    -- Ensure sync field exists implicitly by usage
end

function on_guild_command(msg)
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end

    if args[1] == "create" or args[1] == "join" then
        if args[2] then
            sTable.guildName = args[2]
            djui_chat_message_create("Joined guild: " .. args[2])
        else
            djui_chat_message_create("Usage: /guild join [name]")
        end
    elseif args[1] == "leave" then
        sTable.guildName = nil
        djui_chat_message_create("Left guild.")
    else
        djui_chat_message_create("Commands: join, leave")
    end
    return true
end

hook_chat_command("guild", "Manage guild", on_guild_command)

function guild_nametags()
    for i = 1, MAX_PLAYERS - 1 do -- Skip local (0)
        local m = gMarioStates[i]
        if m.marioBodyState.action & ACT_FLAG_ACTIVE ~= 0 then -- Connected?
            local sTable = gPlayerSyncTable[i]
            if sTable and sTable.guildName then
                local pos = {x = m.pos.x, y = m.pos.y + 200, z = m.pos.z}
                local out = {x = 0, y = 0, z = 0}

                if djui_hud_world_pos_to_screen_pos(pos, out) then
                    local text = "<" .. sTable.guildName .. ">"
                    local width = djui_hud_measure_text(text)
                    djui_hud_set_color(100, 255, 100, 255) -- Light Green
                    djui_hud_print_text(text, out.x - width/2, out.y, 1)
                end
            end
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, guild_nametags)
