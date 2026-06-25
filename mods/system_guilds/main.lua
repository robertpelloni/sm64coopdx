-- name: System - Guilds
-- description: Guild system for MMORPG social structure.

_G.Guilds = {}
_G.Guilds.registry = {}

local SAVE_KEY = "guilds_data"

function escape_str(s)
    if not s then return "" end
    s = string.gsub(s, ";", ",")
    s = string.gsub(s, "|", "/")
    s = string.gsub(s, ":", "-")
    return s
end

-- Packet Types
local PACKET_GUILD_CHAT = 0
local PACKET_GUILD_CREATE = 1
local PACKET_GUILD_SYNC = 2

function Guilds.load()
    local data = mod_storage_load(SAVE_KEY)
    if data and data ~= "" then
        for entry in string.gmatch(data, "([^|]+)") do
            local parts = {}
            for p in string.gmatch(entry, "([^;]+)") do table.insert(parts, p) end
            if #parts >= 2 then
                local guildName = parts[1]
                local ownerName = parts[2]
                Guilds.registry[guildName] = { owner = ownerName }
            end
        end
    end
end

function Guilds.save()
    if not network_is_server() then return end
    local data = ""
    for name, info in pairs(Guilds.registry) do
        data = data .. escape_str(name) .. ";" .. escape_str(info.owner) .. "|"
    end
    mod_storage_save(SAVE_KEY, data)
end

function guild_get_name(playerIndex)
    local sTable = gPlayerSyncTable[playerIndex]
    return sTable.guildName
end

-- Networking
function guild_send_chat(msg)
    local myGuild = guild_get_name(0)
    if not myGuild then
        djui_chat_message_create("You are not in a guild.")
        return
    end

    local packet = {
        packetType = PACKET_GUILD_CHAT,
        senderName = gNetworkPlayers[0].name,
        guildName = myGuild,
        message = msg
    }

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
    elseif p.packetType == PACKET_GUILD_CREATE and network_is_server() then
        -- Client wants to create a guild
        if not Guilds.registry[p.guildName] then
            Guilds.registry[p.guildName] = { owner = p.senderName }
            if _G.SaveManager then SaveManager.request_save() else Guilds.save() end

            -- Sync the new registry back to all
            network_send(true, {
                packetType = PACKET_GUILD_SYNC,
                registry = Guilds.registry
            })
        end
    elseif p.packetType == PACKET_GUILD_SYNC and not network_is_server() then
        -- Client receives the updated registry list
        Guilds.registry = p.registry
    end
end

hook_event(HOOK_ON_PACKET_RECEIVE, on_guild_packet)

-- Commands
function on_guild_command(msg)
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end

    if args[1] == "create" then
        if args[2] then
            sTable.guildName = args[2]
            if network_is_server() then
                Guilds.registry[args[2]] = { owner = gNetworkPlayers[0].name }
                if _G.SaveManager then SaveManager.request_save() else Guilds.save() end
                network_send(true, { packetType = PACKET_GUILD_SYNC, registry = Guilds.registry })
            else
                -- Request server to register
                network_send(true, { packetType = PACKET_GUILD_CREATE, guildName = args[2], senderName = gNetworkPlayers[0].name })
            end
            djui_chat_message_create("Created/Joined guild: " .. args[2])
        else
            djui_chat_message_create("Usage: /guild create [name]")
        end
    elseif args[1] == "join" then
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
        if _G.GuildsUI and GuildsUI.toggle_ui then
            GuildsUI.toggle_ui()
        else
            djui_chat_message_create("Commands: create, join, leave")
        end
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
        if np and np.connected and m and m.marioBodyState and (m.marioBodyState.action & ACT_FLAG_ACTIVE ~= 0) then
            local sTable = gPlayerSyncTable[i]
            if sTable then
                local pos = {x = m.pos.x, y = m.pos.y + 200, z = m.pos.z}
                local out = {x = 0, y = 0, z = 0}

                if djui_hud_world_pos_to_screen_pos(pos, out) then
                    local y = out.y

                    -- Guild Name
                    if sTable.guildName and sTable.guildName ~= "" then
                        local text = "<" .. sTable.guildName .. ">"
                        local width = djui_hud_measure_text(text)
                        djui_hud_set_color(100, 255, 100, 255) -- Light Green
                        djui_hud_print_text(text, out.x - width/2, y, 1)
                        y = y - 20
                    end

                    -- Title
                    if sTable.currentTitle and sTable.currentTitle ~= "" then
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

function guilds_init()
    if network_is_server() then
        Guilds.load()
    end
end

hook_event(HOOK_ON_LEVEL_INIT, guilds_init)
