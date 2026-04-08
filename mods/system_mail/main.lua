-- name: System - Mailbox
-- description: Asynchronous messaging and item transfer.

_G.Mail = {}
Mail.inbox = {}

local SAVE_KEY = "player_mail"

function escape_str(s)
    if not s then return "" end
    s = string.gsub(s, ";", ",")
    s = string.gsub(s, "|", "/")
    return s
end

function Mail.load()
    local data = mod_storage_load(SAVE_KEY)
    if data and data ~= "" then
        for entry in string.gmatch(data, "([^|]+)") do
            local parts = {}
            for p in string.gmatch(entry, "([^;]+)") do table.insert(parts, p) end
            if #parts >= 4 then
                local mail = {
                    sender = parts[1],
                    subject = parts[2],
                    body = parts[3],
                    attachment = nil
                }
                if parts[4] ~= "none" and parts[5] then
                    mail.attachment = {id = parts[4], count = tonumber(parts[5])}
                end
                table.insert(Mail.inbox, mail)
            end
        end
    end
end

function Mail.save()
    local data = ""
    for _, m in ipairs(Mail.inbox) do
        local attId = m.attachment and m.attachment.id or "none"
        local attCount = m.attachment and tostring(m.attachment.count) or "0"
        data = data .. escape_str(m.sender) .. ";" .. escape_str(m.subject) .. ";" .. escape_str(m.body) .. ";" .. attId .. ";" .. attCount .. "|"
    end
    mod_storage_save(SAVE_KEY, data)
end

-- Networking hooks for sending mail to other players
local PACKET_MAIL_SEND = 50

function on_mail_receive(data)
    -- We received a mail packet from another player (or server)
    table.insert(Mail.inbox, {
        sender = data.sender,
        subject = data.subject,
        body = data.body,
        attachment = data.attachment
    })
    Mail.save()
    djui_chat_message_create("You have new mail from " .. data.sender .. "!")
    play_sound(SOUND_GENERAL_COIN, gMarioStates[0].marioObj.header.gfx.cameraToObject)
end

function Mail.send(senderName, targetPlayerName, subject, body, attachment)
    -- Find the target player index
    local targetIndex = -1
    for i = 0, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected and network_get_player_text_color_string(i) .. "Player " .. tostring(i) == targetPlayerName then
            targetIndex = i
            break
        end
    end

    if targetIndex == -1 then
        -- Player offline or not found, fake sending for local testing if it's SYSTEM
        if senderName == "SYSTEM" then
            table.insert(Mail.inbox, {sender=senderName, subject=subject, body=body, attachment=attachment})
            Mail.save()
        else
            djui_chat_message_create("Target player is not online to receive mail.")
        end
        return
    end

    -- Send reliable packet to the target player
    local msg = {
        sender = senderName,
        subject = subject,
        body = body,
        attachment = attachment
    }
    network_send_to(targetIndex, true, msg)
end

function mail_init()
    Mail.load()
    network_register_packet(PACKET_MAIL_SEND, on_mail_receive)
end

hook_event(HOOK_ON_LEVEL_INIT, mail_init)
