-- name: System - Shared UI Toolkit
-- description: Reusable UI components to eliminate redundancy.

_G.UIToolkit = {}

-- Standard Window Config
local WIN_WIDTH = 500
local WIN_HEIGHT = 400
local ROW_HEIGHT = 20
local MAX_VISIBLE_ROWS = 12

--- Helper to draw wrapped text
function UIToolkit.draw_wrapped_text(text, x, y, maxLen, scale)
    local words = {}
    for word in string.gmatch(text, "%S+") do table.insert(words, word) end

    local line = ""
    local currentY = y

    for _, word in ipairs(words) do
        if string.len(line) + string.len(word) > maxLen then
            djui_hud_print_text(line, x, currentY, scale)
            currentY = currentY + 20 * scale
            line = word .. " "
        else
            line = line .. word .. " "
        end
    end
    if line ~= "" then
         djui_hud_print_text(line, x, currentY, scale)
    end
    return currentY + 20 * scale -- returns bottom Y
end

--- Draws a standardized menu window with extensive tooltip and documentation support
--- @param title string
--- @param items table List of items to display. Can be strings or tables with a 'name' field.
--- @param selection number Currently selected index
--- @param scrollOffset number Current scroll offset
--- @param renderDetails function Optional callback to render the right-side details pane: renderDetails(cx, cy, selectedItem)
--- @param footer string Optional footer text
--- @param helpText string Optional global help text for the menu
function UIToolkit.draw_menu(title, items, selection, scrollOffset, renderDetails, footer, helpText)
    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()
    local cx = w / 2
    local cy = h / 2

    -- Background
    djui_hud_set_color(0, 0, 50, 240)
    djui_hud_render_rect(cx - WIN_WIDTH/2, cy - WIN_HEIGHT/2, WIN_WIDTH, WIN_HEIGHT)

    -- Title
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(title, cx - WIN_WIDTH/2 + 20, cy - WIN_HEIGHT/2 + 20, 1.2)

    -- Menu Help Text (if provided)
    if helpText then
        djui_hud_set_color(180, 180, 255, 255)
        UIToolkit.draw_wrapped_text("INFO: " .. helpText, cx - WIN_WIDTH/2 + 20, cy - WIN_HEIGHT/2 + 45, 60, 0.7)
    end

    -- Calculate visible range
    if #items == 0 then
        djui_hud_set_color(200, 200, 200, 255)
        djui_hud_print_text("Empty", cx - 30, cy, 1)
        if footer then
            djui_hud_set_color(200, 200, 200, 255)
            djui_hud_print_text(footer, cx - WIN_WIDTH/2 + 20, cy + WIN_HEIGHT/2 - 30, 0.8)
        end
        return
    end

    local listX = cx - WIN_WIDTH/2 + 20
    local listY = cy - WIN_HEIGHT/2 + 80

    -- Left Pane (List)
    for i = 1, MAX_VISIBLE_ROWS do
        local idx = scrollOffset + i
        if idx <= #items then
            local item = items[idx]
            local displayName = type(item) == "table" and (item.name or item.id or "Unknown") or tostring(item)

            if idx == selection then
                djui_hud_set_color(255, 255, 0, 255)
                djui_hud_print_text("> " .. displayName, listX, listY + (i-1)*ROW_HEIGHT, 1)
            else
                djui_hud_set_color(200, 200, 200, 255)
                djui_hud_print_text("  " .. displayName, listX, listY + (i-1)*ROW_HEIGHT, 1)
            end

            if type(item) == "table" and item.right_text then
                djui_hud_set_color(150, 255, 150, 255)
                djui_hud_print_text(item.right_text, cx - 40, listY + (i-1)*ROW_HEIGHT, 0.8)
            end
        end
    end

    -- Separator
    if renderDetails then
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_render_rect(cx, cy - WIN_HEIGHT/2 + 50, 2, WIN_HEIGHT - 100)

        -- Right Pane (Details)
        local selectedItem = items[selection]
        if selectedItem then
            renderDetails(cx + 20, cy - WIN_HEIGHT/2 + 60, selectedItem)

            -- Tooltip support for the selected item
            if type(selectedItem) == "table" and selectedItem.tooltip then
                djui_hud_set_color(255, 200, 100, 255)
                local tX = cx + 20
                local tY = cy + WIN_HEIGHT/2 - 120
                djui_hud_print_text("TOOLTIP:", tX, tY, 0.8)
                djui_hud_set_color(200, 200, 200, 255)
                UIToolkit.draw_wrapped_text(selectedItem.tooltip, tX, tY + 20, 30, 0.7)
            end
        end
    end

    -- Footer
    if footer then
        djui_hud_set_color(200, 200, 200, 255)
        djui_hud_print_text(footer, cx - WIN_WIDTH/2 + 20, cy + WIN_HEIGHT/2 - 30, 0.8)
    end
end

--- Handles standard list navigation input and state locking
--- @param m MarioState
--- @param selection number
--- @param maxItems number
--- @param debounceTimer number
--- @return number newSelection, number newDebounce, boolean actionTriggered, boolean closeTriggered
function UIToolkit.handle_input(m, selection, maxItems, debounceTimer)
    -- Lock Mario
    if m.action ~= ACT_WAITING_FOR_DIALOG then
        set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
    end

    if debounceTimer > 0 then
        return selection, debounceTimer - 1, false, false
    end

    local sel = selection
    local act = false
    local close = false

    if maxItems > 0 then
        if (m.controller.buttonPressed & D_JPAD) ~= 0 then
            sel = sel + 1
            if sel > maxItems then sel = 1 end
            play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
        end
        if (m.controller.buttonPressed & U_JPAD) ~= 0 then
            sel = sel - 1
            if sel < 1 then sel = maxItems end
            play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
        end

        if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
            act = true
            -- Sound handled by caller depending on success
        end
    end

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        close = true
        set_mario_action(m, ACT_IDLE, 0)
    end

    return sel, debounceTimer, act, close
end

--- Calculates scroll offset based on selection and max visible items
function UIToolkit.calculate_scroll(selection, scrollOffset, totalItems)
    if selection > totalItems then selection = totalItems end
    if selection < 1 then selection = 1 end

    local newOffset = scrollOffset
    if selection > scrollOffset + MAX_VISIBLE_ROWS then
        newOffset = selection - MAX_VISIBLE_ROWS
    elseif selection <= scrollOffset then
        newOffset = selection - 1
    end
    return newOffset
end
