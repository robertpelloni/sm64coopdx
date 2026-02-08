-- name: System - Inventory UI
-- description: Menu-driven UI for the Universal Inventory.

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local VISIBLE_ITEMS = 8
local OPEN_TIMER = 0

function inventory_ui_render()
    if not UI_VISIBLE then return end
    if not _G.Inventory then return end

    local m = gMarioStates[0]
    local items = Inventory.get_all_items(m) -- List of {id, count, name}

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()
    local cx = w / 2
    local cy = h / 2

    -- Background
    djui_hud_set_color(0, 0, 0, 220)
    djui_hud_render_rect(cx - 200, cy - 150, 400, 300)

    -- Header
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("INVENTORY", cx - 60, cy - 140, 1)

    if #items == 0 then
        djui_hud_print_text("Empty", cx - 30, cy, 1)

        -- Close hint even if empty
        djui_hud_set_color(200, 200, 200, 255)
        djui_hud_print_text("B: Close", cx - 40, cy + 130, 1)
        return
    end

    -- Scroll Logic
    if SELECTION > #items then SELECTION = #items end
    if SELECTION < 1 then SELECTION = 1 end

    if SELECTION > SCROLL_OFFSET + VISIBLE_ITEMS then
        SCROLL_OFFSET = SELECTION - VISIBLE_ITEMS
    elseif SELECTION <= SCROLL_OFFSET then
        SCROLL_OFFSET = SELECTION - 1
    end

    -- List Items (Left Side)
    local listX = cx - 180
    local listY = cy - 100

    for i = 1, VISIBLE_ITEMS do
        local idx = SCROLL_OFFSET + i
        if idx <= #items then
            local item = items[idx]
            local displayName = item.name or item.id
            local displayCount = "x" .. tostring(item.count)

            if idx == SELECTION then
                djui_hud_set_color(255, 255, 0, 255)
                djui_hud_print_text("> " .. displayName, listX, listY + (i-1)*25, 1)
            else
                djui_hud_set_color(200, 200, 200, 255)
                djui_hud_print_text("  " .. displayName, listX, listY + (i-1)*25, 1)
            end

            -- Count
            djui_hud_print_text(displayCount, listX + 150, listY + (i-1)*25, 1)
        end
    end

    -- Separator
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_render_rect(cx, cy - 110, 2, 220)

    -- Details Pane (Right Side)
    local selectedItem = items[SELECTION]
    if selectedItem then
        local def = _G.Inventory.items[selectedItem.id]
        local desc = def.description or "No description."

        local detX = cx + 20
        local detY = cy - 100

        djui_hud_set_color(0, 255, 255, 255)
        djui_hud_print_text(selectedItem.name, detX, detY, 1)

        djui_hud_set_color(200, 200, 200, 255)

        -- Simple Text Wrapping
        local words = {}
        for word in string.gmatch(desc, "%S+") do table.insert(words, word) end

        local line = ""
        local lineY = detY + 40
        local maxLen = 22 -- Approx chars per line

        for _, word in ipairs(words) do
            if string.len(line) + string.len(word) > maxLen then
                djui_hud_print_text(line, detX, lineY, 0.8)
                lineY = lineY + 20
                line = word .. " "
            else
                line = line .. word .. " "
            end
        end
        if line ~= "" then
             djui_hud_print_text(line, detX, lineY, 0.8)
        end

        -- Usage Hint
        djui_hud_set_color(150, 150, 150, 255)
        djui_hud_print_text("A: Equip/Use", detX, cy + 100, 0.8)
    end

    -- Footer
    djui_hud_set_color(200, 200, 200, 255)
    djui_hud_print_text("B: Close", cx - 30, cy + 130, 1)
end

function inventory_ui_update(m)
    if m.playerIndex ~= 0 then return end

    if not UI_VISIBLE then return end

    -- Lock Mario
    if m.action ~= ACT_WAITING_FOR_DIALOG then
        set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
    end

    -- Debounce
    if OPEN_TIMER > 0 then
        OPEN_TIMER = OPEN_TIMER - 1
        return
    end

    -- Navigation
    if (m.controller.buttonPressed & D_JPAD) ~= 0 then
        SELECTION = SELECTION + 1
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
    end
    if (m.controller.buttonPressed & U_JPAD) ~= 0 then
        SELECTION = SELECTION - 1
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
    end

    -- Close
    if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        UI_VISIBLE = false
        set_mario_action(m, ACT_IDLE, 0)
        return
    end

    -- Use
    if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
       play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
       -- Future: Trigger item usage
    end
end

function Inventory.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5 -- 5 frames debounce
    end
end

function Inventory.close_ui()
    UI_VISIBLE = false
end

hook_event(HOOK_ON_HUD_RENDER, inventory_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, inventory_ui_update)
