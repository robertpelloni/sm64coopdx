-- name: System - Guilds UI
-- description: Visual menu for managing Guild membership.
-- depends: system_ui, system_guilds

_G.Guilds = {}

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0
local UI_MODE = "main" -- "main" or "type_guild"

local targetGuildName = ""

function guilds_ui_render()
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]
    local inGuild = (sTable.guildName ~= nil and sTable.guildName ~= "")

    local items = {}
    local title = ""
    local footer = ""

    if UI_MODE == "main" then
        title = inGuild and "GUILD - " .. string.upper(sTable.guildName) or "GUILD MANAGEMENT"
        footer = "A: Select  B: Close"

        if inGuild then
            table.insert(items, { id = "bank", name = "Guild Bank", tooltip = "Access the shared guild storage." })
            table.insert(items, { id = "leave", name = "Leave Guild", tooltip = "Leave your current guild." })
        else
            table.insert(items, { id = "join", name = "Join/Create Guild", tooltip = "Type a guild name to join or create it." })
        end

        local renderDetails = function(x, y, selItem)
            djui_hud_set_color(255, 255, 255, 255)
            djui_hud_print_text(selItem.name, x, y, 1)
            djui_hud_set_color(200, 200, 200, 255)
            UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 40, 22, 0.8)
        end

        UIToolkit.draw_menu(title, items, SELECTION, SCROLL_OFFSET, renderDetails, footer, "Manage your guild membership.")

    elseif UI_MODE == "type_guild" then
        title = "GUILD - ENTER NAME"
        footer = "A: Confirm  B: Cancel  Y: Delete Char  D-Pad: Type"
        UIToolkit.draw_text_input(title, targetGuildName, footer, "Type the exact name of the guild you wish to join or create.")
    end
end

function guilds_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local sTable = gPlayerSyncTable[0]
    local inGuild = (sTable.guildName ~= nil and sTable.guildName ~= "")

    if UI_MODE == "type_guild" then
        local newText, submitted, cancelled, newTimer = UIToolkit.handle_text_input(m, targetGuildName, OPEN_TIMER)
        targetGuildName = newText
        OPEN_TIMER = newTimer

        if submitted then
            -- Note: We rely on the main command logic or replicate it safely here.
            -- Using a simplified string cleanup to prevent delimiters if escape_str isn't global yet
            local safeName = string.gsub(targetGuildName, "[^%w_]", "")
            if safeName ~= "" then
                sTable.guildName = safeName
                djui_chat_message_create("Joined guild: " .. safeName)
                if _G.SaveManager then SaveManager.request_save() end -- Assume safe request if exists
            else
                djui_chat_message_create("Invalid guild name.")
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

    local maxItems = inGuild and 2 or 1
    local list = {}
    if inGuild then
        table.insert(list, {id="bank"})
        table.insert(list, {id="leave"})
    else
        table.insert(list, {id="join"})
    end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act and #list > 0 then
        local item = list[SELECTION]
        if item.id == "leave" then
            sTable.guildName = nil
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
            djui_chat_message_create("Left the guild.")
            SELECTION = 1
            if _G.SaveManager then SaveManager.request_save() end
        elseif item.id == "join" then
            targetGuildName = "Guild"
            UI_MODE = "type_guild"
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        elseif item.id == "bank" then
            UI_VISIBLE = false
            set_mario_action(m, ACT_IDLE, 0)
            if _G.GuildBankUI then GuildBankUI.toggle_ui() else djui_chat_message_create("Guild bank UI not found.") end
        end
    end

    if close then
        UI_VISIBLE = false
        set_mario_action(m, ACT_IDLE, 0)
    end
end

function Guilds.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
        UI_MODE = "main"
    end
end

hook_event(HOOK_ON_HUD_RENDER, guilds_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, guilds_ui_update)
