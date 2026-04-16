-- name: System - Achievements UI
-- description: Menu-driven UI for Achievements using UIToolkit.

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function achievements_ui_render()
    if not UI_VISIBLE then return end
    if not _G.Achievements or not _G.UIToolkit then return end

    local m = gMarioStates[0]

    local items = {}
    for id, def in pairs(Achievements.registry) do
        local unlocked = Achievements.has_achievement(m, id)
        local status = unlocked and "[Unlocked]" or "[Locked]"
        table.insert(items, {
            id = id,
            name = def.name,
            right_text = status,
            tooltip = def.desc,
            def = def,
            unlocked = unlocked
        })
    end

    -- Sort: Unlocked first
    table.sort(items, function(a, b)
        if a.unlocked == b.unlocked then return a.name < b.name end
        return a.unlocked and not b.unlocked
    end)

    local renderDetails = function(x, y, selItem)
        local def = selItem.def
        if def then
            if selItem.unlocked then
                djui_hud_set_color(0, 255, 0, 255)
            else
                djui_hud_set_color(100, 100, 100, 255)
            end
            djui_hud_print_text(def.name, x, y, 1.2)

            djui_hud_set_color(200, 200, 200, 255)
            UIToolkit.draw_wrapped_text(def.desc, x, y + 40, 25, 0.9)

            if def.title_reward then
                djui_hud_set_color(255, 215, 0, 255)
                djui_hud_print_text("Reward: Title '" .. def.title_reward .. "'", x, y + 100, 0.8)
            end
        end
    end

    UIToolkit.draw_menu("ACHIEVEMENTS", items, SELECTION, SCROLL_OFFSET, renderDetails, "B: Close", "Track your milestones and unlocked titles here.")
end

function achievements_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local count = 0
    for k,v in pairs(_G.Achievements.registry) do count = count + 1 end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, count, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, count)

    if close then
        UI_VISIBLE = false
    end
end

function Achievements.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

hook_event(HOOK_ON_HUD_RENDER, achievements_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, achievements_ui_update)
