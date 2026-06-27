-- name: System - Classes UI
-- description: UI for Class Selection and Talents using UIToolkit.

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function classes_ui_render()
    if not UI_VISIBLE then return end
    if not _G.Classes or not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]
    local currentClass = sTable.classType or 0

    local classList = {}
    for id, def in pairs(_G.Classes.defs) do
        table.insert(classList, {
            id=id,
            def=def,
            name=def.name,
            right_text = (id == currentClass and "Active" or "")
        })
    end
    table.sort(classList, function(a,b) return a.id < b.id end)

    local renderDetails = function(x, y, selItem)
        local def = selItem.def

        djui_hud_set_color(0, 255, 255, 255)
        djui_hud_print_text(def.name, x, y, 1)

        -- Description
        djui_hud_set_color(200, 200, 200, 255)
        local currY = UIToolkit.draw_wrapped_text(def.desc or "", x, y + 30, 22, 0.8)

        -- Abilities
        djui_hud_set_color(255, 215, 0, 255)
        djui_hud_print_text("Abilities:", x, currY, 1)
        djui_hud_set_color(200, 200, 255, 255)
        djui_hud_print_text("1: " .. (def.ability_1 or "None"), x, currY + 20, 0.8)
        djui_hud_print_text("2: " .. (def.ability_2 or "None"), x, currY + 35, 0.8)

        -- Talents
        currY = currY + 60
        djui_hud_set_color(255, 215, 0, 255)
        djui_hud_print_text("Talents (X to Unlock):", x, currY, 1)
        currY = currY + 20

        for _, t in ipairs(def.talents) do
            local unlocked = Classes.has_talent(m, t.id)
            if unlocked then
                djui_hud_set_color(0, 255, 0, 255)
                djui_hud_print_text("[X] " .. t.name, x, currY, 0.8)
            else
                djui_hud_set_color(150, 150, 150, 255)
                djui_hud_print_text("[ ] " .. t.name, x, currY, 0.8)
            end
            currY = currY + 15
        end

        -- Bonuses
        currY = currY + 10
        djui_hud_set_color(0, 255, 0, 255)
        if def.hp_bonus ~= 0 then
            djui_hud_print_text("HP: " .. (def.hp_bonus > 0 and "+" or "") .. def.hp_bonus, x, currY, 0.8)
            currY = currY + 15
        end
        if def.speed_mult ~= 1.0 then
            djui_hud_print_text("Speed: x" .. def.speed_mult, x, currY, 0.8)
        end
    end

    UIToolkit.draw_menu("CLASSES & TALENTS", classList, SELECTION, SCROLL_OFFSET, renderDetails, "A: Equip Class  X: Unlock Talent  B: Close")
end

function classes_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.Classes or not _G.UIToolkit then return end

    local classList = {}
    for id, def in pairs(_G.Classes.defs) do
        table.insert(classList, {id=id, def=def})
    end
    table.sort(classList, function(a,b) return a.id < b.id end)

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, #classList, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, #classList)

    if act then
        local selItem = classList[SELECTION]
        if selItem then
            Classes.set_class(m, selItem.id)
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        end
    end

    -- X to unlock talent (Prototype logic: unlock first locked talent for now)
    if (m.controller.buttonPressed & X_BUTTON) ~= 0 and OPEN_TIMER <= 0 then
        local selItem = classList[SELECTION]
        if selItem then
            local unlockedSomething = false
            for _, t in ipairs(selItem.def.talents) do
                if not Classes.has_talent(m, t.id) then
                    Classes.unlock_talent(m, t.id)
                    djui_chat_message_create("Unlocked Talent: " .. t.name)
                    play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject)
                    unlockedSomething = true
                    break
                end
            end
            if not unlockedSomething then
                play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
            end
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

function Classes.close_ui()
    UI_VISIBLE = false
end

hook_event(HOOK_ON_HUD_RENDER, classes_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, classes_ui_update)
