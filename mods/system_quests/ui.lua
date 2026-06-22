-- name: System - Quest UI
-- description: Menu-driven UI for Quests using UIToolkit.

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function quests_ui_render()
    if not UI_VISIBLE then return end
    if not _G.Quest or not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local active_quests = Quest.get_active(m)

    local items = {}
    for _, q in ipairs(active_quests) do
        local def = q.def
        if def then
            local p = q.progress
            local status = (p >= def.target) and "Complete" or tostring(p) .. "/" .. tostring(def.target)
            local name = def.name

            -- Color-code Daily Quests
            if string.sub(q.id, 1, 6) == "daily_" then
                name = "\\#ffff00\\" .. name .. "\\#ffffff\\"
            end

            table.insert(items, {
                id = q.id,
                name = name,
                right_text = status,
                tooltip = "Objective: " .. def.description
            })
        end
    end

    if #items == 0 then
        table.insert(items, { id = "none", name = "No Active Quests", right_text = "" })
    end

    local renderDetails = function(x, y, selItem)
        local active_quest = nil
        for _, q in ipairs(active_quests) do
            if q.id == selItem.id then
                active_quest = q
                break
            end
        end

        if active_quest and active_quest.def then
            local def = active_quest.def
            djui_hud_set_color(0, 255, 255, 255)
            djui_hud_print_text(def.name, x, y, 1)

            djui_hud_set_color(200, 200, 200, 255)
            UIToolkit.draw_wrapped_text(def.description, x, y + 40, 22, 0.8)

            local p = active_quest.progress
            djui_hud_set_color(150, 255, 150, 255)
            djui_hud_print_text("Progress: " .. tostring(p) .. " / " .. tostring(def.target), x, y + 100, 0.8)

            -- Rewards
            local rewY = y + 130
            if def.reward then
                 djui_hud_set_color(0, 255, 0, 255)
                 djui_hud_print_text("Reward: " .. tostring(def.reward.amount) .. "x " .. (def.reward.item or "Coins"), x, rewY, 0.8)
            end
        else
            djui_hud_set_color(200, 200, 200, 255)
            djui_hud_print_text("Explore the world to find quests.", x, y, 0.8)
        end
    end

    UIToolkit.draw_menu("QUEST LOG", items, SELECTION, SCROLL_OFFSET, renderDetails, "B: Close", "Track your ongoing missions and objectives here.")
end

function quests_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local active_quests = _G.Quest.get_active(m)
    local maxItems = #active_quests > 0 and #active_quests or 1

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

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

function Quest.close_ui()
    UI_VISIBLE = false
end

hook_event(HOOK_ON_HUD_RENDER, quests_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, quests_ui_update)
