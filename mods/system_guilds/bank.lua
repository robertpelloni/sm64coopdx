-- name: System - Guild Bank
-- description: Shared storage for guild members.
-- depends: system_inventory

_G.GuildBank = {}

local PACKET_BANK_SYNC = 100
local PACKET_BANK_ACTION = 101

-- Loaded bank data per guild: GuildBank.vaults["GuildName"] = { {id="item_id", count=10}, ... }
GuildBank.vaults = {}
-- Transaction locks to prevent duping
GuildBank.locks = {}

function GuildBank.get_save_key(guildName)
    return "guild_bank_" .. string.gsub(guildName, "[^%w_]", "") -- Sanitize guild name for save key
end

function GuildBank.load(guildName)
    if GuildBank.vaults[guildName] then return end -- Already loaded

    local key = GuildBank.get_save_key(guildName)
    local data = mod_storage_load(key)
    local items = {}

    if data and data ~= "" then
        for str in string.gmatch(data, "([^|]+)") do
            local colon = string.find(str, ":")
            if colon then
                local id = string.sub(str, 1, colon - 1)
                local count = tonumber(string.sub(str, colon + 1))
                if id and count then
                    items[id] = (items[id] or 0) + count
                end
            end
        end
    end
    GuildBank.vaults[guildName] = items
end

function GuildBank.save(guildName)
    local items = GuildBank.vaults[guildName]
    if not items then return end

    local data = ""
    for id, count in pairs(items) do
        if count > 0 then
            data = data .. id .. ":" .. tostring(count) .. "|"
        end
    end
    mod_storage_save(GuildBank.get_save_key(guildName), data)
end

function GuildBank.save_all()
    for guildName, _ in pairs(GuildBank.vaults) do
        GuildBank.save(guildName)
    end
end

function GuildBank.get_items(guildName)
    -- On the client, this returns the locally cached sync'd table
    -- On the host, this loads and returns the real data
    if network_is_server() then
        GuildBank.load(guildName)
    end

    local list = {}
    local items = GuildBank.vaults[guildName]
    if items then
        for id, count in pairs(items) do
            if count > 0 then
                table.insert(list, {id = id, count = count})
            end
        end
    end
    -- Sort to keep UI consistent
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

-- Broadcasts the current bank state to all guild members
function GuildBank.sync(guildName)
    if not network_is_server() then return end
    GuildBank.load(guildName)

    local items = GuildBank.vaults[guildName]
    if not items then return end

    local packet = {
        packetType = PACKET_BANK_SYNC,
        guildName = guildName,
        items = items
    }
    network_send(false, packet)
end

-- Client initiates an action
function GuildBank.request_action(actionType, itemId, count)
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]
    local guildName = sTable.guildName
    if not guildName then
        djui_chat_message_create("You are not in a guild.")
        return false
    end

    if count <= 0 then return false end

    -- `m.playerIndex` is a local index which does not uniquely map the player to the server.
    -- We need to retrieve and send the global index so the server routes back appropriately.
    local globalIndex = network_global_index_from_local(m.playerIndex)
    local packet = {
        packetType = PACKET_BANK_ACTION,
        action = actionType, -- "deposit" or "withdraw"
        guildName = guildName,
        itemId = itemId,
        count = count,
        senderId = globalIndex
    }
    network_send(true, packet)
    return true
end

function GuildBank.deposit(m, itemId, count)
    return GuildBank.request_action("deposit", itemId, count)
end

function GuildBank.withdraw(m, itemId, count)
    return GuildBank.request_action("withdraw", itemId, count)
end

-- Packet Handlers
function on_bank_packet(p)
    if p.packetType == PACKET_BANK_ACTION and network_is_server() then
        -- Server processes request
        local guildName = p.guildName
        local action = p.action
        local itemId = p.itemId
        local count = p.count
        local senderId = p.senderId

        -- Validate request
        if action ~= "request_sync" and (not count or count <= 0) then return end

        local targetLocalIndex = network_local_index_from_global(senderId)
        local senderTable = gPlayerSyncTable[targetLocalIndex]
        if not senderTable or senderTable.guildName ~= guildName then
            -- Cross-guild theft attempt
            return
        end

        GuildBank.load(guildName)
        local items = GuildBank.vaults[guildName]

        if action == "request_sync" then
            GuildBank.sync(guildName)

        elseif action == "deposit" then
            -- Verify sender actually has the item via a dedicated packet or trust the client for now
            -- (In a true MMORPG, the server tracks all inventories authoritatively, but coopdx mod_storage inventory relies on local saves for clients)
            -- For now, the client removes the item before sending, but we have to accept that due to coopdx structure.
            -- A true secure way is that client sends request, server acks, client removes, server adds.
            -- To keep it aligned with `sm64coopdx` client-authoritative inventory, we just process it.
            items[itemId] = (items[itemId] or 0) + count
            if _G.SaveManager then SaveManager.request_save() else GuildBank.save(guildName) end
            GuildBank.sync(guildName)

        elseif action == "withdraw" then
            local current = items[itemId] or 0
            if current >= count then
                items[itemId] = current - count
                if _G.SaveManager then SaveManager.request_save() else GuildBank.save(guildName) end
                GuildBank.sync(guildName)

                -- Tell the client it was successful so they can add to their inventory
                -- Send the packet specifically back to the correct player using their local index translated from the sent global index.
                local targetLocalIndex = network_local_index_from_global(senderId)
                local res = {
                    packetType = PACKET_BANK_SYNC, -- Reuse sync to indicate success
                    guildName = guildName,
                    items = items,
                    successAction = "withdraw",
                    successItem = itemId,
                    successCount = count
                }
                network_send_to(targetLocalIndex, true, res)
            end
        end
    end
end

-- Extended packet handling on client for successful actions
function on_bank_packet_extended(p)
    if p.packetType == PACKET_BANK_SYNC then
        -- Client receives updated bank state
        local myGuild = gPlayerSyncTable[0].guildName
        if myGuild and myGuild == p.guildName then
            GuildBank.vaults[p.guildName] = p.items

            -- If we were waiting for a withdraw success
            if p.successAction == "withdraw" and _G.Inventory then
                Inventory.add_item(gMarioStates[0], p.successItem, p.successCount)
                djui_chat_message_create("Withdrew " .. tostring(p.successCount) .. "x " .. p.successItem)
                play_sound(SOUND_GENERAL_COIN, gMarioStates[0].marioObj.header.gfx.cameraToObject)
            end
        end
    end
end

network_register_packet(PACKET_BANK_SYNC, on_bank_packet_extended)
network_register_packet(PACKET_BANK_ACTION, on_bank_packet)

function on_bank_command(msg)
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    if not sTable.guildName then
        djui_chat_message_create("You must be in a guild to use the bank.")
        return true
    end

    if _G.GuildBankUI and GuildBankUI.toggle_ui then
        GuildBankUI.toggle_ui()
    else
        djui_chat_message_create("Bank UI is not available.")
    end
    return true
end

hook_chat_command("bank", "Open guild bank", on_bank_command)

-- Sync on join
-- Sync on join / Local loading
function on_mario_update(m)
    if m.playerIndex ~= 0 then return end

    local sTable = gPlayerSyncTable[0]
    if sTable.guildName and not GuildBank.clientSyncRequested then
        -- We just learned our guild name, request bank data from host
        GuildBank.clientSyncRequested = true
        if not network_is_server() then
            -- Send a dummy action or a dedicated sync request to fetch the state
            -- For simplicity, since the server syncs every deposit/withdraw,
            -- we could just ask the server to sync.
            local packet = {
                packetType = PACKET_BANK_ACTION,
                action = "request_sync",
                guildName = sTable.guildName,
                senderId = network_global_index_from_local(0)
            }
            network_send(true, packet)
        else
            GuildBank.load(sTable.guildName)
        end
    end

    if not sTable.guildName then
        GuildBank.clientSyncRequested = false
    end
end

hook_event(HOOK_MARIO_UPDATE, on_mario_update)
