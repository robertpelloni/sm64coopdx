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

    for id, def in pairs(_G.Inventory.items) do
        local key = get_key(id)
        local count = sTable[key]
        if count and count > 0 then
            table.insert(list, {id = id, count = count, name = def.name})
        end
    end

    return list
end

--------------------------------------------------------------------------------
-- Persistence
--------------------------------------------------------------------------------

-- Simple serialization: "id:count;id2:count2;"
function Inventory.save()
    local m = gMarioStates[0] -- Local save
    local sTable = gPlayerSyncTable[m.playerIndex]

    local saveStr = ""
    for id, _ in pairs(_G.Inventory.items) do
        local key = get_key(id)
        local count = sTable[key]
        if count and count > 0 then
            saveStr = saveStr .. id .. ":" .. tostring(count) .. ";"
        end
    end

    mod_storage_save("inventory_data", saveStr)
    -- log_to_console("Saved Inventory: " .. saveStr)
end

function Inventory.load()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    if not mod_storage_exists("inventory_data") then return end

    local saveStr = mod_storage_load("inventory_data")
    if not saveStr then return end

    -- Parse "id:count;"
    for pair in string.gmatch(saveStr, "([^;]+)") do
        local id, countStr = string.match(pair, "([^:]+):(%d+)")
        if id and countStr then
            local count = tonumber(countStr)
            if _G.Inventory.items[id] then
                local key = get_key(id)
                sTable[key] = count
            end
        end
    end
    -- log_to_console("Loaded Inventory")
end
