-- FLUDD HUD
-- Renders Water Meter

function fludd_hud_render()
    local m = gMarioStates[0]
    local s = FLUDD.get_state(m)

    if s.fluddNozzle == FLUDD.NOZZLE_NONE then return end

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()

    -- Bottom Right
    local x = w - 100
    local y = h - 60
    local width = 80
    local height = 20

    -- Background
    djui_hud_set_color(0, 0, 0, 100)
    djui_hud_render_rect(x, y, width, height)

    -- Fill
    local ratio = s.fluddWater / FLUDD.MAX_WATER
    djui_hud_set_color(0, 150, 255, 200) -- Water Blue
    djui_hud_render_rect(x + 2, y + 2, (width - 4) * ratio, height - 4)

    -- Text
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("WATER", x + 10, y - 20, 1)

    -- Nozzle Icon (Text for now)
    local nText = "H"
    if s.fluddNozzle == FLUDD.NOZZLE_ROCKET then nText = "R" end
    if s.fluddNozzle == FLUDD.NOZZLE_TURBO then nText = "T" end

    djui_hud_print_text("[" .. nText .. "]", x - 30, y, 1)
end

hook_event(HOOK_ON_HUD_RENDER, fludd_hud_render)
