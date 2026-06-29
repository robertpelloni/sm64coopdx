-- name: System - Quests UI
-- description: UI for the Quest Log.
-- depends: system_ui, system_quests

_G.QuestUI = {}

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function quest_ui_render()
    if not UI_VISIBLE then return end
    if not _G.Quest or not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local active_quests = Quest.get_active(m)

    local renderDetails = function(x, y, selItem)
        local def = selItem.def

        djui_hud_set_color(255, 255, 0, 255)
        djui_hud_print_text(def.name, x, y, 1.2)

        djui_hud_set_color(200, 200, 200, 255)
        local currY = UIToolkit.draw_wrapped_text(def.desc, x, y + 40, 25, 0.9)

        -- Progress bar
        currY = currY + 30
        djui_hud_set_color(0, 0, 0, 150)
        djui_hud_render_rect(x, currY, 300, 20)

        local ratio = selItem.progress / def.target
        if ratio > 1 then ratio = 1 end

        djui_hud_set_color(0, 255, 0, 200)
        djui_hud_render_rect(x, currY, 300 * ratio, 20)

        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(tostring(selItem.progress) .. " / " .. tostring(def.target), x + 10, currY + 2, 0.8)

        -- Rewards
        if def.reward then
            currY = currY + 40
            djui_hud_set_color(255, 215, 0, 255)
            djui_hud_print_text("Rewards:", x, currY, 1)
            djui_hud_set_color(200, 255, 200, 255)
            if def.reward.item then
                djui_hud_print_text("- " .. def.reward.amount .. "x " .. def.reward.item, x, currY + 20, 0.8)
            end
        end
    end

    UIToolkit.draw_menu("QUEST LOG", active_quests, SELECTION, SCROLL_OFFSET, renderDetails, "B: Close", "Track your active adventures.")
end

function quest_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.Quest or not _G.UIToolkit then return end

    local active_quests = _G.Quest.get_active(m)
    local maxItems = #active_quests

    if maxItems == 0 then
        if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
            UI_VISIBLE = false
            set_mario_action(m, ACT_IDLE, 0)
        end
        return
    end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if close then
        UI_VISIBLE = false
    end
end

function QuestUI.toggle()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

hook_event(HOOK_ON_HUD_RENDER, quest_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, quest_ui_update)

function on_quest_command(msg)
    QuestUI.toggle()
    return true
end

hook_chat_command("quests", "Open Quest Log", on_quest_command)
hook_chat_command("q", "Open Quest Log", on_quest_command)
