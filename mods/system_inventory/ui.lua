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
    local raw_items = Inventory.get_all_items(m) -- List of {id, count}

    local items = {}
    for _, item in ipairs(raw_items) do
        local def = _G.Inventory.items[item.id]
        table.insert(items, {
            id = item.id,
            name = def and def.name or item.id,
            right_text = "x" .. tostring(item.count),
            tooltip = def and def.description or "No description."
        })
    end

    if #items == 0 then
        table.insert(items, { id = "none", name = "Empty", right_text = "" })
    end

    local renderDetails = function(x, y, selItem)
        if selItem.id == "none" then return end
        djui_hud_set_color(255, 255, 255, 255)
        _G.UIToolkit.draw_wrapped_text(selItem.tooltip, x, y, 200, 1.0)
    end

    _G.UIToolkit.draw_menu("INVENTORY", items, SELECTION, SCROLL_OFFSET, renderDetails, "A: Equip/Use  B: Close", "Manage your collected items and equipment.")
end

function inventory_ui_update(m)
    if m.playerIndex ~= 0 then return end

    if not UI_VISIBLE then return end
    if not _G.Inventory or not _G.UIToolkit then return end

    -- Force freeze
    if m.action ~= ACT_WAITING_FOR_DIALOG then
        set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
    end

    local raw_items = Inventory.get_all_items(m)
    if #raw_items == 0 then
         raw_items = {{id="none"}}
    end

    local sel, timer, act, close = _G.UIToolkit.handle_input(m, SELECTION, #raw_items, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = _G.UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, #raw_items)

    if act then
       play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
       local selItem = raw_items[SELECTION]
       if selItem and selItem.id ~= "none" then
           if string.match(selItem.id, "^weap_") then
               if _G.Equipment then
                   _G.Equipment.equip_item(selItem.id, "weapon", 1)
               end
           elseif string.match(selItem.id, "^badge_") then
               if _G.Equipment then
                   _G.Equipment.equip_item(selItem.id, "badge", 1)
               end
           end
       end
    end

    if close then
        UI_VISIBLE = false
        set_mario_action(m, ACT_IDLE, 0)
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
