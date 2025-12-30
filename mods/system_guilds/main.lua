-- name: System - Guilds
-- description: Guild system for MMORPG social structure.

-- Packet Types
local PACKET_GUILD_CHAT = 0

-- Guild Data Management
function guild_get_name(playerIndex)
    local sTable = gPlayerSyncTable[playerIndex]
    return sTable.guildName
end

-- Networking
function guild_send_chat(msg)
    local m = gMarioStates[0]
    local myGuild = guild_get_name(0)
    if not myGuild then
        djui_chat_message_create("You are not in a guild.")
        return
    end

    local packet = {
        packetType = PACKET_GUILD_CHAT,
        senderName = m.character.name or "Player", -- Fallback, usually network name is handled elsewhere
        guildName = myGuild,
        message = msg
    }

    -- Using network_player_get_name(0) is better
    local np = gNetworkPlayers[0]
    packet.senderName = np.name

    network_send(true, packet)
end

function on_guild_packet(p)
    if p.packetType == PACKET_GUILD_CHAT then
        local myGuild = guild_get_name(0)
        if myGuild and myGuild == p.guildName then
            -- Format: [Guild] <Name>: Message
            local text = "\\#00ff00\\[Guild] " .. p.senderName .. ":\\#ffffff\\ " .. p.message
            djui_chat_message_create(text)
        end
    end
end

hook_event(HOOK_ON_PACKET_RECEIVE, on_guild_packet)

-- Commands
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

function on_guild_chat_command(msg)
    guild_send_chat(msg)
    return true
end

hook_chat_command("guild", "Manage guild", on_guild_command)
hook_chat_command("g", "Guild chat", on_guild_chat_command)

-- Rendering (Nametags)
function guild_nametags()
    for i = 1, MAX_PLAYERS - 1 do -- Skip local (0)
        local m = gMarioStates[i]
        local np = gNetworkPlayers[i]
        if np.connected and m.marioBodyState.action & ACT_FLAG_ACTIVE ~= 0 then
            local sTable = gPlayerSyncTable[i]
            if sTable then
                local pos = {x = m.pos.x, y = m.pos.y + 200, z = m.pos.z}
                local out = {x = 0, y = 0, z = 0}

                if djui_hud_world_pos_to_screen_pos(pos, out) then
                    local y = out.y

                    -- Guild Name
                    if sTable.guildName then
                        local text = "<" .. sTable.guildName .. ">"
                        local width = djui_hud_measure_text(text)
                        djui_hud_set_color(100, 255, 100, 255) -- Light Green
                        djui_hud_print_text(text, out.x - width/2, y, 1)
                        y = y - 20
                    end

                    -- Title
                    if sTable.currentTitle then
                        local text = sTable.currentTitle
                        local width = djui_hud_measure_text(text)
                        djui_hud_set_color(255, 215, 0, 255) -- Gold
                        djui_hud_print_text(text, out.x - width/2, y, 1)
                    end
                end
            end
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, guild_nametags)
