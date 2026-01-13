-- Simple UI for Inventory

local UI_VISIBLE = false

function inventory_ui_render()
    if not UI_VISIBLE then return end
    if not _G.Inventory then return end

    local m = gMarioStates[0] -- Local player
    local items = Inventory.get_all_items(m)

    if #items == 0 then
        djui_hud_print_text("Inventory Empty", 10, 10, 1)
        return
    end

    local y = 10
    djui_hud_print_text("Inventory:", 10, y, 1)
    y = y + 20

    for _, item in ipairs(items) do
        local text = item.name .. ": " .. tostring(item.count)
        djui_hud_print_text(text, 10, y, 1)
        y = y + 20
    end
end

function Inventory.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
end

function Inventory.is_open()
    return UI_VISIBLE
end

function Inventory.close_ui()
    UI_VISIBLE = false
end

-- Input handling removed. Toggling is now handled by system_menu.

hook_event(HOOK_ON_HUD_RENDER, inventory_ui_render)
