-- name: System - Universal Inventory
-- description: A universal inventory system for MMORPG features.

_G.Inventory = {}
_G.Inventory.items = {}

-- Define an item with properties
function Inventory.define_item(id, name, description, maxStack)
    _G.Inventory.items[id] = {
        name = name,
        description = description,
        maxStack = maxStack or 99
    }
end

-- Helper to get the sync key
local function get_key(id)
    return "inv_" .. id
end

-- Add item to a player's inventory
function Inventory.add_item(m, id, amount)
    if not _G.Inventory.items[id] then
        log_to_console("Error: Item " .. tostring(id) .. " not defined.")
        return false
    end

    local sTable = gPlayerSyncTable[m.playerIndex]
    local key = get_key(id)

    -- Update count
    -- sTable stores values directly. If nil, treat as 0.
    local current = sTable[key] or 0
    local newAmount = current + amount
    local max = _G.Inventory.items[id].maxStack

    if newAmount > max then
        newAmount = max
    end

    sTable[key] = newAmount

    -- Network sync is automatic for gPlayerSyncTable fields
    return true
end

-- Remove item from a player's inventory
function Inventory.remove_item(m, id, amount)
    local sTable = gPlayerSyncTable[m.playerIndex]
    local key = get_key(id)

    local current = sTable[key] or 0
    if current < amount then
        return false
    end

    local newAmount = current - amount
    if newAmount <= 0 then
        sTable[key] = nil -- Setting to nil usually removes the key
    else
        sTable[key] = newAmount
    end

    return true
end

-- Get item count
function Inventory.get_count(m, id)
    local sTable = gPlayerSyncTable[m.playerIndex]
    local key = get_key(id)
    return sTable[key] or 0
end

-- Get all items (Helper for UI)
-- Returns an iterator or table of {id, count}
function Inventory.get_all_items(m)
    local sTable = gPlayerSyncTable[m.playerIndex]
    local list = {}

    -- Since we flattened the table, we need to iterate all keys and find ones starting with "inv_"
    -- Note: gPlayerSyncTable iteration might not be standard in all Lua versions, but usually works for tables.
    -- However, smlua's sync table might restrict iteration.
    -- If iteration is not supported, we must iterate definitions.

    for id, def in pairs(_G.Inventory.items) do
        local key = get_key(id)
        local count = sTable[key]
        if count and count > 0 then
            table.insert(list, {id = id, count = count, name = def.name})
        end
    end

    return list
end
