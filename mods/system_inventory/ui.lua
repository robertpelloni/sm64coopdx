-- name: System - Inventory UI
-- description: Menu-driven UI for the Universal Inventory using UIToolkit.

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function inventory_ui_render()
    if not UI_VISIBLE then return end
    if not _G.Inventory or not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local raw_items = Inventory.get_all_items(m)

    -- Format for UIToolkit
    local items = {}
    for _, item in ipairs(raw_items) do
        local def = _G.Inventory.items[item.id]
        table.insert(items, {
            id = item.id,
            name = item.name or item.id,
            right_text = "x" .. tostring(item.count),
            tooltip = def and (def.name .. " (Value: " .. tostring(def.value) .. ")") or "Unknown item."
        })
    end

    local renderDetails = function(x, y, selItem)
        local def = _G.Inventory.items[selItem.id]
        if def then
            djui_hud_set_color(0, 255, 255, 255)
            djui_hud_print_text(def.name, x, y, 1)

            djui_hud_set_color(200, 200, 200, 255)
            local desc = def.description or "No description."
            UIToolkit.draw_wrapped_text(desc, x, y + 40, 22, 0.8)

            -- Weapon Durability Display
            if string.match(selItem.id, "^weap_") and gPlayerSyncTable[0].equipped_weapon == selItem.id then
                local dur = gPlayerSyncTable[0].weapon_durability or 0
                djui_hud_set_color(255, 100, 100, 255)
                djui_hud_print_text("[EQUIPPED] Durability: " .. tostring(dur), x, y + 100, 0.8)
            end

            -- Badge Equipped Display
            if string.match(selItem.id, "^badge_") then
                local is_equipped = false
                for i = 1, 3 do
                    if gPlayerSyncTable[0]["eq_badge_" .. i] == selItem.id then
                        is_equipped = true
                        djui_hud_set_color(255, 100, 100, 255)
                        djui_hud_print_text("[EQUIPPED in Slot " .. i .. "]", x, y + 100, 0.8)
                        break
                    end
                end
            end
        end
    end

    UIToolkit.draw_menu("INVENTORY", items, SELECTION, SCROLL_OFFSET, renderDetails, "A: Equip/Use  B: Close", "Your universal inventory storing all items, equipment, and crafting materials.")
end

function inventory_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.Inventory or not _G.UIToolkit then return end

    local raw_items = Inventory.get_all_items(m)
    local maxItems = #raw_items > 0 and #raw_items or 1

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act and #raw_items > 0 then
       play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
       local selItem = raw_items[SELECTION]
       if selItem then
           if string.match(selItem.id, "^weap_") then
               if _G.Weapons then
                   Weapons.equip(m, selItem.id)
               end
           elseif string.match(selItem.id, "^badge_") then
               -- Simple logic: equip in first empty slot, or replace slot 1
               local sync = gPlayerSyncTable[0]
               local equipped = false
               for i = 1, 3 do
                   if sync["eq_badge_" .. i] == nil then
                       sync["eq_badge_" .. i] = selItem.id
                       equipped = true
                       djui_chat_message_create("Equipped " .. selItem.id .. " in Slot " .. i)
                       break
                   end
               end
               if not equipped then
                   sync.eq_badge_1 = selItem.id
                   djui_chat_message_create("Replaced Slot 1 with " .. selItem.id)
               end
           end
       end
    end

    if close then
        UI_VISIBLE = false
    end
end

function Inventory.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

function Inventory.close_ui()
    UI_VISIBLE = false
end

hook_event(HOOK_ON_HUD_RENDER, inventory_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, inventory_ui_update)
