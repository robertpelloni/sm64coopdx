-- name: System - Quest UI
-- description: Visual menu for managing quests.
-- depends: system_ui, system_quests

_G.QuestUI = {}

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function QuestUI.render()
    if not UI_VISIBLE then return end
    if not _G.Quest or not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local active = Quest.get_active_quests(m)
    local completed = Quest.get_completed_quests(m)

    local items = {}

    -- Group active quests
    if #active > 0 then
        for _, qId in ipairs(active) do
            local def = Quest.registry[qId]
            if def then
                local prog = Quest.get_progress(m, qId)
                table.insert(items, {
                    id = qId,
                    name = "[Active] " .. def.name,
                    right_text = tostring(prog) .. "/" .. tostring(def.goal),
                    tooltip = def.desc,
                    state = "active",
                    prog = prog,
                    goal = def.goal
                })
            end
        end
    end

    -- Group completed quests
    if #completed > 0 then
        for _, qId in ipairs(completed) do
            local def = Quest.registry[qId]
            if def then
                table.insert(items, {
                    id = qId,
                    name = "[Done] " .. def.name,
                    right_text = "Complete",
                    tooltip = def.desc,
                    state = "completed",
                    prog = def.goal,
                    goal = def.goal
                })
            end
        end
    end

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(255, 255, 0, 255)
        djui_hud_print_text(selItem.name, x, y, 1.2)

        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 40, 25, 0.9)

        -- Progress bar
        djui_hud_set_color(100, 100, 100, 255)
        djui_hud_render_rect(x, y + 100, 200, 20)

        local pct = selItem.prog / selItem.goal
        if pct > 1 then pct = 1 end
        if pct < 0 then pct = 0 end

        if selItem.state == "completed" then
            djui_hud_set_color(0, 255, 0, 255)
        else
            djui_hud_set_color(0, 150, 255, 255)
        end
        djui_hud_render_rect(x, y + 100, 200 * pct, 20)

        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(tostring(selItem.prog) .. " / " .. tostring(selItem.goal), x + 80, y + 102, 0.8)
    end

    UIToolkit.draw_menu("QUEST LOG", items, SELECTION, SCROLL_OFFSET, renderDetails, "B: Close", "Track your ongoing and completed missions.")
end

function QuestUI.update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local activeCount = #Quest.get_active_quests(m)
    local compCount = #Quest.get_completed_quests(m)
    local totalItems = activeCount + compCount

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, totalItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, totalItems)

    if close then
        UI_VISIBLE = false
    end
end

function Quest.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

hook_event(HOOK_ON_HUD_RENDER, QuestUI.render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, QuestUI.update)
