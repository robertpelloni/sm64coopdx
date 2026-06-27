-- name: System - Guilds UI
-- description: Visual UI for creating and joining guilds.
-- depends: system_ui, system_guilds

_G.GuildsUI = {}

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0
local UI_MODE = "main" -- "main", "type_create", "type_join"

local targetGuildName = ""

function GuildsUI.render()
    if not UI_VISIBLE then return end
    if not _G.Guilds or not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[0]
    local myGuild = sTable.guildName
    local inGuild = (myGuild ~= nil and myGuild ~= "")

    local items = {}
    local title = ""
    local footer = ""

    if UI_MODE == "main" then
        title = inGuild and "GUILD: " .. myGuild or "GUILDS DIRECTORY"
        footer = "A: Select  B: Close"

        if inGuild then
            table.insert(items, { id = "leave", name = "Leave Guild", tooltip = "Leave your current guild." })

            -- List Members (only those currently online and in same guild)
            for i = 0, MAX_PLAYERS - 1 do
                if gNetworkPlayers[i].connected then
                    local ts = gPlayerSyncTable[i]
                    if ts and ts.guildName == myGuild then
                        local rightText = (i == 0) and "You" or ""
                        table.insert(items, { id = "member_" .. tostring(i), name = network_get_player_text_color_string(i) .. gNetworkPlayers[i].name, right_text = rightText, tooltip = "Guild Member." })
                    end
                end
            end
        else
            table.insert(items, { id = "create", name = "Create Guild", tooltip = "Found a new guild." })
            table.insert(items, { id = "join", name = "Join Guild", tooltip = "Type the exact name of an existing guild to join." })

            for gName, info in pairs(Guilds.registry) do
                table.insert(items, { id = "reg_" .. gName, name = gName, right_text = "Owner: " .. tostring(info.owner), tooltip = "A registered guild." })
            end
        end

        local renderDetails = function(x, y, selItem)
            djui_hud_set_color(255, 255, 255, 255)
            djui_hud_print_text(selItem.name, x, y, 1)
            djui_hud_set_color(200, 200, 200, 255)
            UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 40, 22, 0.8)
        end

        UIToolkit.draw_menu(title, items, SELECTION, SCROLL_OFFSET, renderDetails, footer, "Manage your guild and socialize with players.")

    elseif UI_MODE == "type_create" then
        title = "GUILDS - CREATE"
        footer = "A: Confirm  B: Cancel  Y: Delete Char  D-Pad: Type"
        UIToolkit.draw_text_input(title, targetGuildName, footer, "Type the exact name for your new guild.")

    elseif UI_MODE == "type_join" then
        title = "GUILDS - JOIN"
        footer = "A: Confirm  B: Cancel  Y: Delete Char  D-Pad: Type"
        UIToolkit.draw_text_input(title, targetGuildName, footer, "Type the exact name of the guild you wish to join.")
    end
end

function GuildsUI.update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local sTable = gPlayerSyncTable[0]
    local inGuild = (sTable.guildName ~= nil and sTable.guildName ~= "")

    if UI_MODE == "type_create" or UI_MODE == "type_join" then
        local newText, submitted, cancelled, newTimer = UIToolkit.handle_text_input(m, targetGuildName, OPEN_TIMER)
        targetGuildName = newText
        OPEN_TIMER = newTimer

        if submitted then
            if targetGuildName == "" then
                djui_chat_message_create("Invalid name.")
            elseif UI_MODE == "type_create" then
                sTable.guildName = targetGuildName
                if network_is_server() then
                    Guilds.registry[targetGuildName] = { owner = gNetworkPlayers[0].name }
                    if _G.SaveManager then SaveManager.request_save() else Guilds.save() end
                    network_send(true, { packetType = 2, registry = Guilds.registry }) -- PACKET_GUILD_SYNC
                else
                    network_send(true, { packetType = 1, guildName = targetGuildName, senderName = gNetworkPlayers[0].name }) -- PACKET_GUILD_CREATE
                end
                djui_chat_message_create("Created/Joined guild: " .. targetGuildName)
                play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
            elseif UI_MODE == "type_join" then
                sTable.guildName = targetGuildName
                djui_chat_message_create("Joined guild: " .. targetGuildName)
                play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
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

    local list = {}
    if inGuild then
        table.insert(list, {id="leave"})
        for i = 0, MAX_PLAYERS - 1 do
            if gNetworkPlayers[i].connected and gPlayerSyncTable[i] and gPlayerSyncTable[i].guildName == sTable.guildName then
                table.insert(list, {id="member_" .. i})
            end
        end
    else
        table.insert(list, {id="create"})
        table.insert(list, {id="join"})
        for gName, _ in pairs(Guilds.registry) do
            table.insert(list, {id="reg_" .. gName})
        end
    end
    local maxItems = #list > 0 and #list or 1

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act and #list > 0 then
        local item = list[SELECTION]
        if item.id == "leave" then
            sTable.guildName = nil
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
            djui_chat_message_create("Left guild.")
            SELECTION = 1
        elseif item.id == "create" then
            targetGuildName = "Guild"
            UI_MODE = "type_create"
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        elseif item.id == "join" then
            targetGuildName = "Guild"
            UI_MODE = "type_join"
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        elseif item.id:sub(1, 4) == "reg_" then
            targetGuildName = item.id:sub(5)
            sTable.guildName = targetGuildName
            djui_chat_message_create("Joined guild: " .. targetGuildName)
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
            SELECTION = 1
        end
    end

    if close then
        UI_VISIBLE = false
    end
end

function GuildsUI.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
        UI_MODE = "main"
    end
end

hook_event(HOOK_ON_HUD_RENDER, GuildsUI.render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, GuildsUI.update)
