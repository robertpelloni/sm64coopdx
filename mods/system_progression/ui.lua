-- name: System - Progression UI
-- description: UI for Stat Allocation using UIToolkit.

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

-- Stats to manage
local STATS_LIST = {
    {id = "str", name = "Strength", desc = "Increases Warrior damage."},
    {id = "int", name = "Intellect", desc = "Increases Max Mana and Mage damage."},
    {id = "agi", name = "Agility", desc = "Increases Max Stamina, Speed, and Rogue damage."}
}

function progression_ui_render()
    if not UI_VISIBLE then return end
    if not _G.Progression or not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]
    local points = sTable.statPoints or 0

    local list = {}
    for i, stat in ipairs(STATS_LIST) do
        table.insert(list, {
            id = stat.id,
            name = stat.name,
            desc = stat.desc,
            right_text = tostring(Progression.get_stat(m, stat.id))
        })
    end

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(0, 255, 255, 255)
        djui_hud_print_text(selItem.name, x, y, 1)

        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(selItem.desc, x, y + 40, 22, 0.8)
    end

    UIToolkit.draw_menu("STATS (Points: " .. points .. ")", list, SELECTION, SCROLL_OFFSET, renderDetails, "A: Increase  B: Close")
end

function progression_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.Progression or not _G.UIToolkit then return end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, #STATS_LIST, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, #STATS_LIST)

    if act then
        local sTable = gPlayerSyncTable[m.playerIndex]
        if sTable.statPoints and sTable.statPoints > 0 then
            local stat = STATS_LIST[SELECTION]
            local key = "stat_" .. stat.id
            sTable[key] = (sTable[key] or 0) + 1
            sTable.statPoints = sTable.statPoints - 1
            play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject)
        else
            play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
        end
    end

    if close then
        UI_VISIBLE = false
    end
end

function Progression.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

function Progression.close_ui()
    UI_VISIBLE = false
end

hook_event(HOOK_ON_HUD_RENDER, progression_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, progression_ui_update)
