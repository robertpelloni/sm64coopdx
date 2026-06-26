-- name: System - Classes UI
-- description: UI for selecting classes and viewing abilities/talents.
-- depends: system_ui, system_classes

_G.ClassesUI = {}
_G.Classes = _G.Classes or {}

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function ClassesUI.render()
    if not UI_VISIBLE then return end
    if not _G.UIToolkit or not _G.Classes then return end

    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[0]
    local currentClass = sTable.classType or Classes.TYPE_NONE

    local items = {}

    table.insert(items, { id = Classes.TYPE_WARRIOR, name = "Warrior", right_text = (currentClass == Classes.TYPE_WARRIOR and "Active" or ""), tooltip = Classes.defs[Classes.TYPE_WARRIOR] and Classes.defs[Classes.TYPE_WARRIOR].desc or "" })
    table.insert(items, { id = Classes.TYPE_MAGE, name = "Mage", right_text = (currentClass == Classes.TYPE_MAGE and "Active" or ""), tooltip = Classes.defs[Classes.TYPE_MAGE] and Classes.defs[Classes.TYPE_MAGE].desc or "" })
    table.insert(items, { id = Classes.TYPE_ROGUE, name = "Rogue", right_text = (currentClass == Classes.TYPE_ROGUE and "Active" or ""), tooltip = Classes.defs[Classes.TYPE_ROGUE] and Classes.defs[Classes.TYPE_ROGUE].desc or "" })

    local renderDetails = function(x, y, selItem)
        local def = Classes.defs[selItem.id]
        if not def then return end

        djui_hud_set_color(0, 255, 255, 255)
        djui_hud_print_text(def.name, x, y, 1.2)

        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(def.desc, x, y + 40, 25, 0.9)

        djui_hud_set_color(255, 255, 0, 255)
        djui_hud_print_text("Ability L: " .. (def.ability_1 or "None"), x, y + 100, 0.8)
        djui_hud_print_text("Ability R: " .. (def.ability_2 or "None"), x, y + 120, 0.8)

        if currentClass ~= selItem.id then
            djui_hud_set_color(150, 255, 150, 255)
            djui_hud_print_text("Press A to select this class.", x, y + 160, 0.8)
        end
    end

    UIToolkit.draw_menu("CLASS SELECT", items, SELECTION, SCROLL_OFFSET, renderDetails, "A: Select Class  B: Close", "Choose your path and master unique abilities.")
end

function ClassesUI.update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local maxItems = 3
    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act then
        local targetType = nil
        if SELECTION == 1 then targetType = Classes.TYPE_WARRIOR
        elseif SELECTION == 2 then targetType = Classes.TYPE_MAGE
        elseif SELECTION == 3 then targetType = Classes.TYPE_ROGUE
        end

        if targetType and gPlayerSyncTable[0].classType ~= targetType then
            Classes.set_class(m, targetType)

            -- Initial inventory management based on class selection
            if _G.Inventory and not gPlayerSyncTable[0].class_items_granted then
                if targetType == Classes.TYPE_WARRIOR then
                    Inventory.add_item(m, "weap_hammer", 1)
                elseif targetType == Classes.TYPE_MAGE then
                    Inventory.add_item(m, "potion_mana", 5)
                elseif targetType == Classes.TYPE_ROGUE then
                    Inventory.add_item(m, "weap_sword", 1)
                end
                gPlayerSyncTable[0].class_items_granted = true
            end

            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
            UI_VISIBLE = false
            set_mario_action(m, ACT_IDLE, 0)
        else
            play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
        end
    end

    if close then
        UI_VISIBLE = false
    end
end

function Classes.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

hook_event(HOOK_ON_HUD_RENDER, ClassesUI.render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, ClassesUI.update)
