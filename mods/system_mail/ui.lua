-- name: System - Mailbox UI
-- description: Visual UI for reading and managing mail.
-- depends: system_ui, system_mail

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0
local UI_MODE = "inbox" -- "inbox", "compose_target", "compose_attach"

-- State for Compose Mode
local composeTargetIdx = 1
local composeTargetName = "Player"
local composeSubject = "Hello!"
local composeBody = "Here is a message."

function mail_ui_render()
    if not UI_VISIBLE then return end
    if not _G.Mail or not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local items = {}
    local title = ""
    local footer = ""

    if UI_MODE == "inbox" then
        title = "MAILBOX - INBOX"
        footer = "A: Claim/Delete  X: Compose Mode  B: Close"

        for i, mail in ipairs(Mail.inbox) do
            local attachment_text = mail.attachment and "[Item Attached]" or ""
            table.insert(items, {
                id = i,
                mail = mail,
                name = mail.subject,
                right_text = "From: " .. mail.sender,
                tooltip = "Sender: " .. mail.sender .. "\n" .. attachment_text
            })
        end

        if #items == 0 then
            table.insert(items, { id = "none", name = "Inbox Empty", right_text = "", tooltip = "You have no new messages." })
        end

        local renderDetails = function(x, y, selItem)
            if selItem.id == "none" then return end

            local mail = selItem.mail
            djui_hud_set_color(0, 255, 255, 255)
            djui_hud_print_text(mail.subject, x, y, 1.2)

            djui_hud_set_color(200, 200, 200, 255)
            UIToolkit.draw_wrapped_text("From: " .. mail.sender, x, y + 40, 25, 0.9)
            UIToolkit.draw_wrapped_text(mail.body, x, y + 80, 25, 0.9)

            if mail.attachment then
                local def = _G.Inventory and _G.Inventory.items[mail.attachment.id]
                local itemName = def and def.name or mail.attachment.id
                djui_hud_set_color(255, 255, 0, 255)
                djui_hud_print_text("Attachment: " .. tostring(mail.attachment.count) .. "x " .. itemName, x, y + 160, 0.8)
                djui_hud_set_color(150, 255, 150, 255)
                djui_hud_print_text("Press A to claim item & delete mail", x, y + 180, 0.8)
            else
                djui_hud_set_color(255, 100, 100, 255)
                djui_hud_print_text("Press A to delete mail", x, y + 160, 0.8)
            end
        end

        UIToolkit.draw_menu(title, items, SELECTION, SCROLL_OFFSET, renderDetails, footer, "Read messages and claim attached items.")

    elseif UI_MODE == "compose_target" then
        title = "MAILBOX - ENTER RECIPIENT NAME"
        footer = "A: Confirm  B: Cancel  Y: Delete Char  D-Pad: Type"
        UIToolkit.draw_text_input(title, composeTargetName, footer, "Type the exact name of the player you wish to mail.")

    elseif UI_MODE == "compose_attach" then
        title = "MAILBOX - COMPOSE (SELECT ATTACHMENT)"
        footer = "A: Send Mail  X: Inbox Mode  B: Close"

        local raw_items = _G.Inventory.get_all_items(m)
        table.insert(items, { id = "no_attachment", name = "[Send Without Attachment]", right_text = "", tooltip = "Send a text-only message." })

        for _, item in ipairs(raw_items) do
            local def = _G.Inventory.items[item.id]
            table.insert(items, {
                id = item.id,
                name = def and def.name or item.id,
                right_text = "x" .. tostring(item.count),
                tooltip = "Select to attach 1x to the mail."
            })
        end

        local renderDetails = function(x, y, selItem)
            djui_hud_set_color(0, 255, 255, 255)
            djui_hud_print_text("Draft Message", x, y, 1.2)

            djui_hud_set_color(200, 200, 200, 255)
            UIToolkit.draw_wrapped_text("To: " .. composeTargetName, x, y + 40, 25, 0.9)
            UIToolkit.draw_wrapped_text("Subject: " .. composeSubject, x, y + 60, 25, 0.9)

            if selItem.id ~= "no_attachment" then
                local def = _G.Inventory and _G.Inventory.items[selItem.id]
                djui_hud_set_color(255, 255, 0, 255)
                djui_hud_print_text("Attachment: 1x " .. (def and def.name or selItem.id), x, y + 120, 0.8)
                djui_hud_set_color(150, 255, 150, 255)
                djui_hud_print_text("Press A to send mail and item.", x, y + 140, 0.8)
            else
                djui_hud_set_color(150, 255, 150, 255)
                djui_hud_print_text("Press A to send text-only mail.", x, y + 140, 0.8)
            end
        end

        UIToolkit.draw_menu(title, items, SELECTION, SCROLL_OFFSET, renderDetails, footer, "Select an item to attach and send the mail.")
    end
end

function mail_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    if (m.controller.buttonPressed & X_BUTTON) ~= 0 then
        if UI_MODE == "inbox" then
            UI_MODE = "compose_target"
        else
            UI_MODE = "inbox"
        end
        SELECTION = 1
        SCROLL_OFFSET = 0
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
        return
    end

    local maxItems = 1
    local list = {}

    if UI_MODE == "inbox" then
        maxItems = #Mail.inbox > 0 and #Mail.inbox or 1
        list = Mail.inbox
    elseif UI_MODE == "compose_attach" then
        local inv = _G.Inventory.get_all_items(m)
        maxItems = #inv + 1
        list = {{id="no_attachment"}}
        for _, item in ipairs(inv) do table.insert(list, item) end
    end

    if UI_MODE == "compose_target" then
        local newText, submitted, cancelled, newTimer = UIToolkit.handle_text_input(m, composeTargetName, OPEN_TIMER)
        composeTargetName = newText
        OPEN_TIMER = newTimer

        if submitted then
            UI_MODE = "compose_attach"
            SELECTION = 1
            SCROLL_OFFSET = 0
            OPEN_TIMER = 5
        elseif cancelled then
            UI_MODE = "inbox"
            SELECTION = 1
            SCROLL_OFFSET = 0
            OPEN_TIMER = 5
        end
        return
    end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act then
        if UI_MODE == "inbox" and #Mail.inbox > 0 then
            local mail = Mail.inbox[SELECTION]
            if mail then
                if mail.attachment and _G.Inventory then
                    Inventory.add_item(m, mail.attachment.id, mail.attachment.count)
                    djui_chat_message_create("Claimed " .. tostring(mail.attachment.count) .. "x " .. mail.attachment.id)
                    play_sound(SOUND_GENERAL_COIN, m.marioObj.header.gfx.cameraToObject)
                end

                table.remove(Mail.inbox, SELECTION)
                if _G.SaveManager then SaveManager.request_save() else SafeSave("Mail") end
                play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)

                if SELECTION > #Mail.inbox then SELECTION = math.max(1, #Mail.inbox) end
            end
        elseif UI_MODE == "compose_attach" then
            local item = list[SELECTION]
            if item then
                local att = nil
                local count = 1

                if item.id ~= "no_attachment" then
                    if _G.Inventory and Inventory.remove_item(m, item.id, count) then
                        att = {id = item.id, count = count}
                    else
                        djui_chat_message_create("Not enough " .. item.id)
                        play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
                        return
                    end
                end

                Mail.send(network_get_player_text_color_string(m.playerIndex) .. "Player", composeTargetName, composeSubject, composeBody, att)
                djui_chat_message_create("Mail sent to " .. composeTargetName)
                play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
                UI_MODE = "inbox"
                SELECTION = 1
                SCROLL_OFFSET = 0
            end
        end
    end

    if close then
        UI_VISIBLE = false
    end
end

function Mail.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
        UI_MODE = "inbox"
    end
end

hook_event(HOOK_ON_HUD_RENDER, mail_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, mail_ui_update)
