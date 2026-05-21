-- name: System - Party UI
-- description: Visual menu for managing the Party system.
-- depends: system_ui, system_party

_G.PartyUI = {}

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0
local UI_MODE = "main" -- "main", "type_invite", "type_join"

local targetPlayerName = ""

function PartyUI.render()
    if not UI_VISIBLE then return end
    if not _G.Party or not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[0]
    local inParty = (sTable.partyId and sTable.partyId ~= 0)

    local items = {}
    local title = ""
    local footer = ""

    if UI_MODE == "main" then
        title = inParty and "PARTY MANAGEMENT (ID: " .. tostring(sTable.partyId) .. ")" or "PARTY MANAGEMENT"
        footer = "A: Select  B: Close"

        if inParty then
            table.insert(items, { id = "invite", name = "Invite Player", tooltip = "Type a player's exact name to invite them." })
            table.insert(items, { id = "leave", name = "Leave Party", tooltip = "Leave your current party." })

            -- List Members
            table.insert(items, { id = "member_self", name = gNetworkPlayers[0].name, right_text = "You", tooltip = "This is you." })
            for i = 1, MAX_PLAYERS - 1 do
                if gNetworkPlayers[i].connected then
                    local ts = gPlayerSyncTable[i]
                    if ts and ts.partyId == sTable.partyId then
                        table.insert(items, { id = "member_" .. tostring(i), name = gNetworkPlayers[i].name, tooltip = "Party Member." })
                    end
                end
            end
        else
            table.insert(items, { id = "create", name = "Create Party", tooltip = "Start a new party." })
            table.insert(items, { id = "join", name = "Join Party", tooltip = "Type a player's exact name to join their party." })
        end

        local renderDetails = function(x, y, selItem)
            djui_hud_set_color(255, 255, 255, 255)
            djui_hud_print_text(selItem.name, x, y, 1)
            djui_hud_set_color(200, 200, 200, 255)
            UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 40, 22, 0.8)
        end

        UIToolkit.draw_menu(title, items, SELECTION, SCROLL_OFFSET, renderDetails, footer, "Manage your group to share chat, waypoints, and disable friendly fire.")

    elseif UI_MODE == "type_invite" then
        title = "PARTY - INVITE PLAYER"
        footer = "A: Confirm  B: Cancel  Y: Delete Char  D-Pad: Type"
        UIToolkit.draw_text_input(title, targetPlayerName, footer, "Type the exact name of the player you wish to invite.")

    elseif UI_MODE == "type_join" then
        title = "PARTY - JOIN PLAYER"
        footer = "A: Confirm  B: Cancel  Y: Delete Char  D-Pad: Type"
        UIToolkit.draw_text_input(title, targetPlayerName, footer, "Type the exact name of the player whose party you wish to join.")
    end
end

function PartyUI.update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local sTable = gPlayerSyncTable[0]
    local inParty = (sTable.partyId and sTable.partyId ~= 0)

    if UI_MODE == "type_invite" or UI_MODE == "type_join" then
        local newText, submitted, cancelled, newTimer = UIToolkit.handle_text_input(m, targetPlayerName, OPEN_TIMER)
        targetPlayerName = newText
        OPEN_TIMER = newTimer

        if submitted then
            if UI_MODE == "type_invite" then
                -- Perform Invite
                local targetIdx = -1
                for i = 1, MAX_PLAYERS - 1 do
                    if gNetworkPlayers[i].connected and gNetworkPlayers[i].name == targetPlayerName then
                        targetIdx = i
                        break
                    end
                end

                if targetIdx ~= -1 then
                    network_send(true, {
                        type = 0, -- PACKET_INVITE
                        sender = m.playerIndex,
                        target = targetIdx
                    })
                    djui_chat_message_create("Invited " .. targetPlayerName)
                else
                    djui_chat_message_create("Player not found.")
                end
            elseif UI_MODE == "type_join" then
                -- Perform Join
                local targetIdx = -1
                for i = 1, MAX_PLAYERS - 1 do
                    if gNetworkPlayers[i].connected and gNetworkPlayers[i].name == targetPlayerName then
                        targetIdx = i
                        break
                    end
                end

                if targetIdx ~= -1 then
                    local ts = gPlayerSyncTable[targetIdx]
                    if ts.partyId and ts.partyId ~= 0 then
                        sTable.partyId = ts.partyId
                        djui_chat_message_create("Joined " .. targetPlayerName .. "'s party!")
                    else
                        djui_chat_message_create(targetPlayerName .. " is not in a party.")
                    end
                else
                    djui_chat_message_create("Player not found.")
                end
            end

            UI_MODE = "main"
            SELECTION = 1
            SCROLL_OFFSET = 0
            OPEN_TIMER = 5
        elseif cancelled then
            UI_MODE = "main"
            SELECTION = 1
            SCROLL_OFFSET = 0
            OPEN_TIMER = 5
        end
        return
    end

    local maxItems = inParty and 3 or 2 -- Rough estimation for scrolling, but we need dynamic based on party size
    local list = {}
    if inParty then
        table.insert(list, {id="invite"})
        table.insert(list, {id="leave"})
        table.insert(list, {id="member_self"})
        for i = 1, MAX_PLAYERS - 1 do
            if gNetworkPlayers[i].connected and gPlayerSyncTable[i] and gPlayerSyncTable[i].partyId == sTable.partyId then
                table.insert(list, {id="member_" .. i})
            end
        end
    else
        table.insert(list, {id="create"})
        table.insert(list, {id="join"})
    end
    maxItems = #list > 0 and #list or 1

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act and #list > 0 then
        local item = list[SELECTION]
        if item.id == "create" then
            sTable.partyId = math.random(1, 999999)
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
            djui_chat_message_create("Party created! ID: " .. sTable.partyId)
        elseif item.id == "leave" then
            sTable.partyId = 0
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
            djui_chat_message_create("Left the party.")
            SELECTION = 1
        elseif item.id == "invite" then
            targetPlayerName = "Player"
            UI_MODE = "type_invite"
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        elseif item.id == "join" then
            targetPlayerName = "Player"
            UI_MODE = "type_join"
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        end
    end

    if close then
        UI_VISIBLE = false
    end
end

function Party.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
        UI_MODE = "main"
    end
end

hook_event(HOOK_ON_HUD_RENDER, PartyUI.render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, PartyUI.update)
