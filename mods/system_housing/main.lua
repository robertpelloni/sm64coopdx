-- name: System - Housing
-- description: Instanced player and guild housing system.

_G.Housing = {}
_G.Housing.active = false
_G.Housing.houseId = nil -- Global Index of owner, or "guild_GuildName"
_G.Housing.furniture = {} -- List of {id, x, y, z, yaw}

-- Packets
local PACKET_REQUEST = 0
local PACKET_DATA = 1
local PACKET_GUILD_REQUEST = 2

-- Using Castle Courtyard (Level 26) as placeholder for now.
local function is_furniture(id)
    return id == "chair" or id == "table" or id == "bed"
end

function Housing.enter(m, targetIdx)
    if m.playerIndex ~= 0 then return end

    _G.Housing.active = true
    _G.Housing.houseId = targetIdx

    warp_to_level(LEVEL_CASTLE_COURTYARD, 1, 0)
    djui_chat_message_create("Entered House")

    if targetIdx == 0 then
        Housing.load()
    else
        network_send(true, {
            type = PACKET_REQUEST,
            target = targetIdx
        })
    end
end

function Housing.enter_guild_hall(m, guildName)
    if m.playerIndex ~= 0 then return end

    _G.Housing.active = true
    _G.Housing.houseId = "guild_" .. guildName

    warp_to_level(LEVEL_CASTLE_COURTYARD, 1, 0)
    djui_chat_message_create("Entered Guild Hall: " .. guildName)

    -- Load Guild Furniture (Host manages this usually, or specific file)
    -- If we are the server, we load. If client, ask server.
    if network_is_server() then
        Housing.load_guild(guildName)
    else
        network_send(true, {
            type = PACKET_GUILD_REQUEST,
            guildName = guildName
        })
    end
end

function Housing.leave(m)
    if m.playerIndex ~= 0 then return end

    _G.Housing.active = false
    _G.Housing.houseId = nil

    warp_to_level(LEVEL_CASTLE_GROUNDS, 1, 0)
    djui_chat_message_create("Left House")
end

-- Network Handler
function on_housing_packet(p)
    local m = gMarioStates[0]

    if p.type == PACKET_REQUEST then
        if p.target == m.playerIndex then
            Housing.load()
            network_send(true, {
                type = PACKET_DATA,
                furniture = _G.Housing.furniture
            })
        end
    elseif p.type == PACKET_GUILD_REQUEST then
        if network_is_server() then
            Housing.load_guild(p.guildName)
            network_send(true, {
                type = PACKET_DATA,
                furniture = _G.Housing.furniture
            })
        end
    elseif p.type == PACKET_DATA then
        if _G.Housing.active then
            _G.Housing.furniture = p.furniture
            for _, f in ipairs(_G.Housing.furniture) do
                spawn_furniture_object(f)
            end
            djui_chat_message_create("Loaded house data.")
        end
    end
end

hook_event(HOOK_ON_PACKET_RECEIVE, on_housing_packet)

-- Placing Furniture
function on_housing_command(msg)
    local m = gMarioStates[0]
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end

    local cmd = args[1]

    if cmd == "enter" then
        Housing.enter(m, 0)

    elseif cmd == "visit" then
        local targetName = args[2]
        local targetIdx = -1
        for i = 1, MAX_PLAYERS - 1 do
            if gNetworkPlayers[i].connected and gNetworkPlayers[i].name == targetName then
                targetIdx = i
                break
            end
        end
        if targetIdx ~= -1 then
            Housing.enter(m, targetIdx)
        else
            djui_chat_message_create("Player not found.")
        end

    elseif cmd == "guild" then
        local sTable = gPlayerSyncTable[0]
        if sTable.guildName then
            Housing.enter_guild_hall(m, sTable.guildName)
        else
            djui_chat_message_create("You are not in a guild.")
        end

    elseif cmd == "leave" then
        Housing.leave(m)

    elseif cmd == "place" then
        if not _G.Housing.active then
            djui_chat_message_create("You must be in a house.")
            return true
        end

        -- Permissions check
        local isGuildHouse = (type(_G.Housing.houseId) == "string" and string.sub(_G.Housing.houseId, 1, 6) == "guild_")
        if not isGuildHouse and _G.Housing.houseId ~= 0 then
            djui_chat_message_create("You cannot place items in someone else's house.")
            return true
        end
        -- In Guild house, any member can place for now (or restrict to leader)

        local item = args[2]
        if not item then
            djui_chat_message_create("Usage: /house place [item]")
            return true
        end
        if not Inventory.get_count(m, item) or Inventory.get_count(m, item) <= 0 then
            djui_chat_message_create("You don't have a " .. item)
            return true
        end

        local f = {
            id = item,
            x = m.pos.x,
            y = m.pos.y,
            z = m.pos.z,
            yaw = m.faceAngle.y
        }
        table.insert(_G.Housing.furniture, f)

        if isGuildHouse then
            local gName = string.sub(_G.Housing.houseId, 7)
            if network_is_server() then Housing.save_guild(gName)
            else djui_chat_message_create("Only Server Host can save Guild Hall changes in prototype.") end
        else
            Housing.save()
        end

        djui_chat_message_create("Placed " .. item)
        spawn_furniture_object(f)

    elseif cmd == "clear" then
        if not _G.Housing.active or _G.Housing.houseId ~= 0 then return true end
        _G.Housing.furniture = {}
        Housing.save()
        warp_to_level(LEVEL_CASTLE_COURTYARD, 1, 0)
        djui_chat_message_create("Cleared house.")

    else
        djui_chat_message_create("Housing: enter, visit, guild, leave, place, clear")
    end
    return true
end

-- Save/Load
function Housing.save()
    local str = ""
    for _, f in ipairs(_G.Housing.furniture) do
        str = str .. f.id .. "," .. math.floor(f.x) .. "," .. math.floor(f.y) .. "," .. math.floor(f.z) .. "," .. f.yaw .. ";"
    end
    mod_storage_save("housing_data", str)
end

function Housing.load()
    _G.Housing.furniture = {}
    local str = mod_storage_load("housing_data")
    if not str then return end

    for chunk in string.gmatch(str, "([^;]+)") do
        local id, x, y, z, yaw = string.match(chunk, "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        if id then
            local f = {id=id, x=tonumber(x), y=tonumber(y), z=tonumber(z), yaw=tonumber(yaw)}
            table.insert(_G.Housing.furniture, f)
            if _G.Housing.active and _G.Housing.houseId == 0 then
                spawn_furniture_object(f)
            end
        end
    end
end

function Housing.save_guild(guildName)
    local str = ""
    for _, f in ipairs(_G.Housing.furniture) do
        str = str .. f.id .. "," .. math.floor(f.x) .. "," .. math.floor(f.y) .. "," .. math.floor(f.z) .. "," .. f.yaw .. ";"
    end
    mod_storage_save("guild_housing_" .. guildName, str)
end

function Housing.load_guild(guildName)
    _G.Housing.furniture = {}
    local str = mod_storage_load("guild_housing_" .. guildName)
    if not str then return end
    for chunk in string.gmatch(str, "([^;]+)") do
        local id, x, y, z, yaw = string.match(chunk, "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        if id then
            local f = {id=id, x=tonumber(x), y=tonumber(y), z=tonumber(z), yaw=tonumber(yaw)}
            table.insert(_G.Housing.furniture, f)
        end
    end
end

-- Visuals
function spawn_furniture_object(f)
    local model = E_MODEL_STAR
    local bhv = id_bhvMessagePanel

    if f.id == "chair" then model = E_MODEL_WOODEN_SIGNPOST end
    if f.id == "table" then model = E_MODEL_SIGNPOST_INSIDE end

    spawn_non_sync_object(
        bhv,
        model,
        f.x, f.y, f.z,
        function(o) o.oMoveAngleYaw = f.yaw end
    )
end

hook_chat_command("house", "Housing commands", on_housing_command)
