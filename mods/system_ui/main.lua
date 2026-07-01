-- name: System - Shared UI Toolkit
-- description: Reusable UI components to eliminate redundancy.

_G.UIToolkit = {}

-- Standard Window Config
local WIN_WIDTH = 500
local WIN_HEIGHT = 400
local ROW_HEIGHT = 20
local MAX_VISIBLE_ROWS = 12

--- Helper to draw wrapped text with basic color code parsing
--- Format: "\\#RRGGBB\\Text\\#FFFFFF\\"
function UIToolkit.draw_wrapped_text(text, x, y, maxLen, scale)
    if not text then return y end

    -- Keyword Color Replacements
    local formattedText = text
    local modifiedText = string.gsub(formattedText, "Rare", "\\#0088FF\\Rare\\#FFFFFF\\")
    modifiedText = string.gsub(modifiedText, "Common", "\\#AAAAAA\\Common\\#FFFFFF\\")
    modifiedText = string.gsub(modifiedText, "Epic", "\\#8800FF\\Epic\\#FFFFFF\\")
    modifiedText = string.gsub(modifiedText, "Legendary", "\\#FF8800\\Legendary\\#FFFFFF\\")

    local words = {}
    for word in string.gmatch(modifiedText, "%S+") do table.insert(words, word) end

    local currentX = x
    local currentY = y
    local charsOnLine = 0

    for _, word in ipairs(words) do
        -- Basic Color Code Parsing: \#RRGGBB\
        local hexColor = string.match(word, "\\#(%x+)\\")
        local cleanWord = word

        if hexColor then
            if string.len(hexColor) >= 6 then
                local r = tonumber(string.sub(hexColor, 1, 2), 16)
                local g = tonumber(string.sub(hexColor, 3, 4), 16)
                local b = tonumber(string.sub(hexColor, 5, 6), 16)
                djui_hud_set_color(r, g, b, 255)
            end
            cleanWord = string.gsub(word, "\\#%x+\\", "")
        end

        -- Default back to standard color if explicitly requested (e.g. \#FFFFFF\)
        if string.match(word, "\\#FFFFFF\\") then
            djui_hud_set_color(200, 200, 200, 255)
            cleanWord = string.gsub(cleanWord, "\\#%x+\\", "")
        end

        local wordLen = string.len(cleanWord)

        if charsOnLine + wordLen > maxLen then
            currentY = currentY + 20 * scale
            currentX = x
            charsOnLine = 0
        end

        djui_hud_print_text(cleanWord .. " ", currentX, currentY, scale)

        -- Approximate spacing logic (1 character ~ 8 pixels at scale 1)
        currentX = currentX + (wordLen + 1) * 8 * scale
        charsOnLine = charsOnLine + wordLen + 1

        -- Reset color for next word if a code was used, unless we want stateful colors
        -- For simplicity, we make color codes affect only the word they are attached to
        djui_hud_set_color(200, 200, 200, 255)
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
        play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        set_mario_action(m, ACT_IDLE, 0)
    end

    return sel, debounceTimer, act, close
end

-- Text Input Spinner State (Global)
local CHAR_SET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"
local char_index = 1
local cursor_pos = 1

--- Draws a dynamic text input spinner
function UIToolkit.draw_text_input(title, currentText, footer, helpText)
    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()
    local cx = w / 2
    local cy = h / 2

    -- Background
    djui_hud_set_color(0, 0, 50, 240)
    djui_hud_render_rect(cx - WIN_WIDTH/2, cy - 150, WIN_WIDTH, 300)

    -- Title
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(title, cx - WIN_WIDTH/2 + 20, cy - 130, 1.2)

    if helpText then
        djui_hud_set_color(180, 180, 255, 255)
        UIToolkit.draw_wrapped_text("INFO: " .. helpText, cx - WIN_WIDTH/2 + 20, cy - 100, 60, 0.7)
    end

    -- Render the string with the cursor
    local displayStr = currentText

    djui_hud_set_color(200, 200, 200, 255)
    local strX = cx - WIN_WIDTH/2 + 40
    local strY = cy
    djui_hud_print_text(displayStr, strX, strY, 1.5)

    -- Cursor
    local cursorChar = string.sub(CHAR_SET, char_index, char_index)
    local widthBeforeCursor = djui_hud_measure_text(string.sub(displayStr, 1, cursor_pos - 1)) * 1.5

    djui_hud_set_color(255, 255, 0, 255)
    djui_hud_print_text(cursorChar, strX + widthBeforeCursor, strY, 1.5)
    djui_hud_print_text("^", strX + widthBeforeCursor, strY + 25, 1.0)
    djui_hud_print_text("v", strX + widthBeforeCursor, strY - 20, 1.0)

    if footer then
        djui_hud_set_color(200, 200, 200, 255)
        djui_hud_print_text(footer, cx - WIN_WIDTH/2 + 20, cy + 120, 0.8)
    end
end

--- Handles text input utilizing the D-Pad
--- @return string newText, boolean submitted, boolean cancelled
function UIToolkit.handle_text_input(m, currentText, debounceTimer)
    if m.action ~= ACT_WAITING_FOR_DIALOG then
        set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
    end

    if debounceTimer > 0 then
        return currentText, false, false, debounceTimer - 1
    end

    local textLen = string.len(currentText)
    if cursor_pos > textLen + 1 then cursor_pos = textLen + 1 end

    -- Ensure char_index matches current cursor char
    local curChar = string.sub(currentText, cursor_pos, cursor_pos)
    if curChar == "" then curChar = "A" end
    local matchIdx = string.find(CHAR_SET, curChar, 1, true)
    if matchIdx then char_index = matchIdx else char_index = 1 end

    local newTimer = debounceTimer

    if (m.controller.buttonPressed & D_JPAD) ~= 0 then
        char_index = char_index + 1
        if char_index > string.len(CHAR_SET) then char_index = 1 end
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
        newTimer = 5
    elseif (m.controller.buttonPressed & U_JPAD) ~= 0 then
        char_index = char_index - 1
        if char_index < 1 then char_index = string.len(CHAR_SET) end
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
        newTimer = 5
    end

    if (m.controller.buttonPressed & R_JPAD) ~= 0 then
        cursor_pos = cursor_pos + 1
        if cursor_pos > 32 then cursor_pos = 32 end -- Max limit
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
        newTimer = 5
    elseif (m.controller.buttonPressed & L_JPAD) ~= 0 then
        cursor_pos = math.max(1, cursor_pos - 1)
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
        newTimer = 5
    end

    local modifiedText = currentText
    if newTimer == 5 and ((m.controller.buttonPressed & D_JPAD) ~= 0 or (m.controller.buttonPressed & U_JPAD) ~= 0) then
        local leftPart = string.sub(currentText, 1, cursor_pos - 1)
        local rightPart = string.sub(currentText, cursor_pos + 1)
        modifiedText = leftPart .. string.sub(CHAR_SET, char_index, char_index) .. rightPart
    end

    -- Backspace/Delete (Y Button)
    if (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        if cursor_pos <= string.len(modifiedText) then
            local leftPart = string.sub(modifiedText, 1, cursor_pos - 1)
            local rightPart = string.sub(modifiedText, cursor_pos + 1)
            modifiedText = leftPart .. rightPart
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
            newTimer = 5
        end
    end

    local submitted = false
    local cancelled = false

    if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
        submitted = true
        cursor_pos = 1 -- Reset for next usage
        play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
    end

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        cancelled = true
        cursor_pos = 1
        play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        set_mario_action(m, ACT_IDLE, 0)
    end

    return modifiedText, submitted, cancelled, newTimer
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
