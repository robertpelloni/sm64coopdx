-- Equipment Manager Core API

_G.Equipment = {}

local m = gMarioStates[0]

function Equipment.get_equipped_weapon()
    local s = gPlayerSyncTable[0]
    return s.equipped_weapon or "none"
end

function Equipment.get_equipped_badge(slot)
    local s = gPlayerSyncTable[0]
    local key = "eq_badge_" .. tostring(slot)
    return s[key] or "none"
end

function Equipment.equip_item(itemId, type, slot)
    local s = gPlayerSyncTable[0]
    if not _G.Inventory or _G.Inventory.get_item_count(m, itemId) <= 0 then
        return false, "You do not own this item."
    end

    if type == "weapon" then
        if s.equipped_weapon and s.equipped_weapon ~= "none" then
            Equipment.unequip_item("weapon", 1)
        end
        _G.Inventory.remove_item(m, itemId, 1)
        s.equipped_weapon = itemId
        return true, "Weapon equipped."
    elseif type == "badge" then
        local key = "eq_badge_" .. tostring(slot)
        if s[key] and s[key] ~= "none" then
            Equipment.unequip_item("badge", slot)
        end
        _G.Inventory.remove_item(m, itemId, 1)
        s[key] = itemId
        return true, "Badge equipped."
    end

    return false, "Invalid equipment type."
end

function Equipment.unequip_item(type, slot)
    local s = gPlayerSyncTable[0]
    if type == "weapon" then
        if s.equipped_weapon and s.equipped_weapon ~= "none" then
            _G.Inventory.add_item(m, s.equipped_weapon, 1)
            s.equipped_weapon = "none"
            return true, "Weapon unequipped."
        end
    elseif type == "badge" then
        local key = "eq_badge_" .. tostring(slot)
        if s[key] and s[key] ~= "none" then
            _G.Inventory.add_item(m, s[key], 1)
            s[key] = "none"
            return true, "Badge unequipped."
        end
    end
    return false, "Nothing to unequip."
end

function Equipment.toggle_ui()
    if _G.EquipmentUI then
        _G.EquipmentUI.toggle()
    else
        djui_chat_message_create("Equipment UI not loaded.")
    end
end
