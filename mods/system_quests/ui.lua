function quest_ui_render()
    if not Quest then return end

    local m = gMarioStates[0]
    local active = Quest.get_active(m)

    if #active == 0 then return end

    local w = djui_hud_get_screen_width()
    local x = w - 150
    local y = 50

    for _, q in ipairs(active) do
        djui_hud_set_color(255, 255, 0, 255)
        djui_hud_print_text(q.def.name, x, y, 1)

        djui_hud_set_color(255, 255, 255, 200)
        local progText = tostring(q.progress) .. "/" .. tostring(q.def.target)
        djui_hud_print_text(progText, x, y + 20, 1)

        y = y + 50
    end
end

hook_event(HOOK_ON_HUD_RENDER, quest_ui_render)
