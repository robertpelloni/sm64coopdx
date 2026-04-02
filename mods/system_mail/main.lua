-- name: System - Mailbox
-- description: Asynchronous messaging and item transfer.

_G.Mail = {}
Mail.inbox = {}

local SAVE_KEY = "player_mail"

function escape_str(s)
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

function Mail.send(senderName, targetPlayerName, subject, body, attachment)
    -- In a real implementation, this would send a reliable packet to the server,
    -- which would append to the target player's offline storage.
    -- For this local test, we just append to our own inbox to simulate receiving.
    table.insert(Mail.inbox, {
        sender = senderName,
        subject = subject,
        body = body,
        attachment = attachment
    })
    Mail.save()
end

function on_mail_command(msg)
    local m = gMarioStates[0]
    local args = {}
    for w in string.gmatch(msg, "%S+") do table.insert(args, w) end

    if args[1] == "send" then
        if #args < 4 then
            djui_chat_message_create("Usage: /mail send <player> <subject> <body> [itemId] [count]")
            return true
        end
        local target = args[2]
        local subj = args[3]
        local body = args[4]

        local att = nil
        if args[5] and args[6] then
            local count = tonumber(args[6])
            if not count or count <= 0 then
                djui_chat_message_create("Attachment count must be a positive number.")
                return true
            end

            if _G.Inventory and Inventory.remove_item(m, args[5], count) then
                att = {id = args[5], count = count}
            else
                djui_chat_message_create("Not enough " .. args[5])
                return true
            end
        end

        Mail.send("Me", target, subj, body, att)
        djui_chat_message_create("Mail sent to " .. target)
        return true
    end
    return true
end

function mail_init()
    Mail.load()
end

hook_chat_command("mail", "Mail system", on_mail_command)
hook_event(HOOK_ON_LEVEL_INIT, mail_init)
