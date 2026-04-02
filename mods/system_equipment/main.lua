-- name: System - Equipment UI
-- description: Manager for equipped weapons and badges.
-- depends: system_ui, system_inventory

_G.Equipment = {}

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function equipment_ui_render()
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local items = {}

    -- Slot: Weapon
    local eqWeap = gPlayerSyncTable[0].equipped_weapon
    if eqWeap and _G.Inventory and _G.Inventory.items[eqWeap] then
        local def = _G.Inventory.items[eqWeap]
        local dur = gPlayerSyncTable[0].weapon_durability or 0
        table.insert(items, {
            slot = "Weapon",
            id = eqWeap,
            name = "[Weapon] " .. def.name,
            right_text = "Dur: " .. tostring(dur),
            tooltip = def.description,
            def = def
        })
    else
        table.insert(items, { slot = "Weapon", id = "none", name = "[Weapon] Empty", right_text = "", tooltip = "No weapon equipped." })
    end

    -- Slot: Badges (Assuming up to 3 slots for system_perks)
    for i = 1, 3 do
        local badgeId = gPlayerSyncTable[0]["eq_badge_" .. i]
        if badgeId and _G.Inventory and _G.Inventory.items[badgeId] then
            local def = _G.Inventory.items[badgeId]
            table.insert(items, {
                slot = "Badge " .. i,
                id = badgeId,
                name = "[Badge " .. i .. "] " .. def.name,
                right_text = "Active",
                tooltip = def.description,
                def = def,
                badgeSlot = i
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

function equipment_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local maxItems = 4 -- 1 weapon, 3 badges
    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act then
        -- Unequip logic based on selection index
        if SELECTION == 1 then
            if gPlayerSyncTable[0].equipped_weapon then
                djui_chat_message_create("Unequipped " .. gPlayerSyncTable[0].equipped_weapon)
                gPlayerSyncTable[0].equipped_weapon = nil
                play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
            end
        elseif SELECTION >= 2 and SELECTION <= 4 then
            local badgeIdx = SELECTION - 1
            local badgeId = gPlayerSyncTable[0]["eq_badge_" .. badgeIdx]
            if badgeId then
                djui_chat_message_create("Unequipped " .. badgeId)
                gPlayerSyncTable[0]["eq_badge_" .. badgeIdx] = nil
                play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)

                -- Force perk update if system_perks exists
                if _G.Perks and Perks.apply_badges then
                     -- Delay apply to next frame usually, but we can call it if exposed
                end
            end
        end
    end

    if close then
        UI_VISIBLE = false
    end
end

function Equipment.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

hook_event(HOOK_ON_HUD_RENDER, equipment_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, equipment_ui_update)
