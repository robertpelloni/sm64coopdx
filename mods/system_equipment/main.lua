-- name: System - Equipment UI
-- description: UI to manage active weapons and badges.

_G.Equipment = {}

local m = gMarioStates[0]

-- Equipment Manager Core API

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

function equipment_ui_render()
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local sync = gPlayerSyncTable[0]
    local items = {}

    -- 1. Weapon Slot
    local wId = sync.equipped_weapon
    if wId and _G.Inventory and _G.Inventory.items[wId] then
        local def = _G.Inventory.items[wId]
        table.insert(items, {
            slot = "Weapon",
            id = wId,
            name = "[Weapon] " .. def.name,
            right_text = "Dur: " .. tostring(sync.weapon_durability or 0) .. "/" .. "100",
            tooltip = "Damage: " .. tostring(def.value) .. ". " .. "Melee" .. " type."
        })
    else
        table.insert(items, { slot = "Weapon", id = "none", name = "[Weapon] Empty", right_text = "", tooltip = "No weapon equipped." })
    end

    -- 2. Badge Slots (1 to 3)
    for i = 1, 3 do
        local bId = sync["eq_badge_" .. i]
        if bId and _G.Inventory and _G.Inventory.items[bId] then
            local def = _G.Inventory.items[bId]
            table.insert(items, {
                slot = "Badge " .. i,
                id = bId,
                name = "[Badge " .. i .. "] " .. def.name,
                right_text = "",
                tooltip = def.description or "A mystical badge."
            })
        else
            table.insert(items, { slot = "Badge " .. i, id = "none", name = "[Badge " .. i .. "] Empty", right_text = "", tooltip = "No badge equipped in this slot." })
        end
    end

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(0, 255, 255, 255)
        djui_hud_print_text(selItem.name, x, y, 1.2)

        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 40, 25, 0.9)

        if selItem.id ~= "none" then
             djui_hud_set_color(255, 100, 100, 255)
             djui_hud_print_text("Press A to Unequip", x, y + 100, 0.8)
        end
    end

    UIToolkit.draw_menu("EQUIPMENT", items, SELECTION, SCROLL_OFFSET, renderDetails, "A: Unequip  B: Close", "Manage your active weapons and badges.")
end
