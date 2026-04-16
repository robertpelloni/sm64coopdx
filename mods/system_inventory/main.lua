-- name: System - Universal Inventory
-- description: Core inventory management.

_G.Inventory = {}
Inventory.items = {}

-- Load/Save mechanics
local SAVE_KEY = "player_inventory"

function Inventory.define_item(id, name, description, value)
    Inventory.items[id] = {
        id = id,
        name = name,
        description = description,
        value = value or 0
    }
end

function Inventory.add_item(m, itemId, count)
    if m.playerIndex ~= 0 then return end
    local current = gPlayerSyncTable[0]["inv_" .. itemId] or 0
    gPlayerSyncTable[0]["inv_" .. itemId] = current + count
end

function Inventory.remove_item(m, itemId, count)
    if m.playerIndex ~= 0 then return end
    local current = gPlayerSyncTable[0]["inv_" .. itemId] or 0
    if current >= count then
        gPlayerSyncTable[0]["inv_" .. itemId] = current - count
        return true
    end
    return false
end

function Inventory.get_item_count(m, itemId)
    return gPlayerSyncTable[0]["inv_" .. itemId] or 0
end

function Inventory.get_all_items(m)
    local list = {}
    if m.playerIndex ~= 0 then return list end

    for k, v in pairs(Inventory.items) do
        local count = gPlayerSyncTable[0]["inv_" .. k] or 0
        if count > 0 then
            table.insert(list, {id = k, count = count, name = v.name})
        end
    end
    return list
end

function Inventory.save()
    local m = gMarioStates[0]
    local data = ""
    local items = Inventory.get_all_items(m)
    for _, item in ipairs(items) do
        data = data .. item.id .. ":" .. tostring(item.count) .. ";"
    end
    mod_storage_save(SAVE_KEY, data)
end

function Inventory.load()
    local data = mod_storage_load(SAVE_KEY)
    if data and data ~= "" then
        for str in string.gmatch(data, "([^;]+)") do
            local colon = string.find(str, ":")
            if colon then
                local id = string.sub(str, 1, colon - 1)
                local count = tonumber(string.sub(str, colon + 1))
                if id and count then
                    gPlayerSyncTable[0]["inv_" .. id] = count
                end
            end
        end
    end
end

-- Initialize System Definitions
Inventory.define_item("coin_bag", "Coin Bag", "A bag full of coins.", 1000)
Inventory.define_item("mushroom", "Mushroom", "A weird mushroom.", 5)
Inventory.define_item("potion_mana", "Mana Potion", "Restores 50 Mana.", 10)
Inventory.define_item("potion_health", "Health Potion", "Restores Health.", 10)
Inventory.define_item("wood", "Wood Log", "Gathered from trees.", 99)

-- Weapons Registration
Inventory.define_item("weap_sword", "Iron Sword", "A basic melee weapon. Equip to use. Has durability.", 100)
Inventory.define_item("weap_hammer", "Heavy Hammer", "A slow but powerful blunt weapon. Equip to use. Has durability.", 150)

-- Economy Logic
local lastCoinCount = 0

function economy_update(m)
    if m.playerIndex ~= 0 then return end

    if not _G.INVENTORY_LOADED then
        Inventory.load()
        _G.INVENTORY_LOADED = true
        lastCoinCount = m.numCoins
    end


    if m.numCoins > lastCoinCount then
        local diff = m.numCoins - lastCoinCount
        Inventory.add_item(m, "coin_bag", diff)
        lastCoinCount = m.numCoins
    elseif m.numCoins < lastCoinCount then
        lastCoinCount = m.numCoins
    end
end

hook_event(HOOK_MARIO_UPDATE, economy_update)
