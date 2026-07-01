-- name: System - Main Menu
-- description: Centralized hub for accessing all major UIs (Inventory, Quests, Guilds, Classes, Settings).
-- depends: system_ui

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

-- Define Main Menu Layout
local menu_items = {
    { id = "auction_house", name = "Auction House",  action = function() if _G.AuctionHouse then AuctionHouse.toggle_ui() end end, tooltip = "Global asynchronous marketplace." },
    { id = "equipment", name = "Equipment",  action = function() if _G.Equipment then Equipment.toggle_ui() end end, tooltip = "Manage your equipped weapons and badges." },
    { id = "inventory", name = "Inventory",  action = function() if _G.Inventory then Inventory.toggle_ui() end end, tooltip = "View and manage your items." },
    { id = "quests",    name = "Quest Log",  action = function() if _G.Quest then Quest.toggle_ui() end end, tooltip = "Check your ongoing missions." },
    { id = "classes",   name = "Classes",    action = function() if _G.Classes then Classes.toggle_ui() end end, tooltip = "Manage your class and abilities." },
    { id = "guilds",    name = "Guilds",     action = function() if _G.Guilds then Guilds.toggle_ui() end end, tooltip = "Socialize with your guild." },
    { id = "party",     name = "Party",      action = function() if _G.Party then Party.toggle_ui() end end, tooltip = "Manage your current party." },
    { id = "stats",     name = "Stats",      action = function() if _G.Progression then Progression.toggle_ui() end end, tooltip = "View your level and attributes." },
    { id = "achievements", name = "Achievements", action = function() if _G.Achievements then Achievements.toggle_ui() end end, tooltip = "View your unlocked milestones." },
    { id = "dungeons",  name = "Dungeons",   action = function() if _G.DungeonUI then DungeonUI.toggle_ui() end end, tooltip = "Enter instanced dungeon encounters." },
    { id = "waypoints", name = "Fast Travel",action = function() if _G.Waypoints then Waypoints.toggle_ui() end end, tooltip = "Teleport to discovered Waypoints." },
    { id = "mail",      name = "Mailbox",    action = function() if _G.Mail then Mail.toggle_ui() end end, tooltip = "Check your messages and packages." },
    { id = "help",      name = "Help / Guide",action = function() if _G.SystemHelp then SystemHelp.toggle_ui() end end, tooltip = "Comprehensive Game Manual and Info." },
    { id = "config",    name = "Config",     action = function() djui_chat_message_create("Use /config [setting] [value]") end, tooltip = "Change game settings." },
    { id = "admin",     name = "Admin",      action = function() if _G.Admin then Admin.toggle_ui() end end, tooltip = "Server administration tools.", condition = function() return network_is_server() end },
    { id = "close",     name = "Close",      action = function() UI_VISIBLE = false; set_mario_action(gMarioStates[0], ACT_IDLE, 0) end, tooltip = "Close the main menu." }
}

function main_menu_render()
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local visible_items = {}
    for _, item in ipairs(menu_items) do
        if not item.condition or item.condition() then
            table.insert(visible_items, item)
        end
    end

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(selItem.name, x, y, 1)
        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 40, 220, 0.8)
    end

    UIToolkit.draw_menu("MAIN MENU", visible_items, SELECTION, SCROLL_OFFSET, renderDetails, "A: Select  B: Close", "Central Hub for all your character needs.")
end

function main_menu_update(m)
    if m.playerIndex ~= 0 then return end

    -- Toggle Menu
    if (m.controller.buttonDown & L_TRIG) ~= 0 and (m.controller.buttonPressed & START_BUTTON) ~= 0 then
        UI_VISIBLE = not UI_VISIBLE
        if UI_VISIBLE then
            SELECTION = 1
            SCROLL_OFFSET = 0
            OPEN_TIMER = 5
            set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
        else
            set_mario_action(m, ACT_IDLE, 0)
        end
        return
    end

    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    -- Force freeze
    if m.action ~= ACT_WAITING_FOR_DIALOG then
        set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
    end

    local visible_items = {}
    for _, item in ipairs(menu_items) do
        if not item.condition or item.condition() then
            table.insert(visible_items, item)
        end
    end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, #visible_items, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, #visible_items)

    if act then
        play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        local item = visible_items[SELECTION]
        if item and item.action then
            UI_VISIBLE = false
            set_mario_action(m, ACT_IDLE, 0)
            item.action()
        end
    end

    if close then
        UI_VISIBLE = false
        set_mario_action(m, ACT_IDLE, 0)
    end
end

hook_event(HOOK_ON_HUD_RENDER, main_menu_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, main_menu_update)
