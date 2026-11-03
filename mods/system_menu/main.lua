-- name: System - Main Menu / Dashboard
-- description: Consolidated single-page Dashboard Hub for accessing all major MMORPG systems.
-- depends: system_ui

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

-- Consolidated High-Value MMO Dashboard Layout
-- Items are prioritized by value and grouped into logical operational domains:
-- 1. Character & Combat (Equipment, Inventory, Classes, Stats)
-- 2. Economy & Social (Auction House, Mailbox, Guilds, Party, Trading)
-- 3. World & Adventure (Fast Travel, Quests, Dungeons, Achievements, Housing)
-- 4. System & Server (Help/Manual, Config, Admin Tools, Server Status)
local menu_items = {
    -- Top High-Value Character & Combat Systems
    {
        id = "equipment",
        name = "[Gear] Equipment",
        category = "Character",
        action = function() if _G.Equipment then Equipment.toggle_ui() end end,
        tooltip = "\\#0088FF\\[Character Gear]\\#FFFFFF\\ View and manage currently equipped weapons, shields, and passive badges with stat bonus breakdowns.",
        right_text = "Gear"
    },
    {
        id = "inventory",
        name = "[Bag] Inventory",
        category = "Character",
        action = function() if _G.Inventory then Inventory.toggle_ui() end end,
        tooltip = "\\#0088FF\\[Universal Bag]\\#FFFFFF\\ View and manage collected items, consumables, materials, and currency (coins).",
        right_text = "Items"
    },
    {
        id = "classes",
        name = "[RPG] Class & Skills",
        category = "Character",
        action = function() if _G.Classes then Classes.toggle_ui() end end,
        tooltip = "\\#0088FF\\[Class System]\\#FFFFFF\\ Manage Warrior, Mage, and Rogue talent trees, active abilities, and unlockable passives.",
        right_text = "Talents"
    },
    {
        id = "stats",
        name = "[Hero] Stats & Progress",
        category = "Character",
        action = function() if _G.Progression then Progression.toggle_ui() end end,
        tooltip = "\\#0088FF\\[Progression Sheet]\\#FFFFFF\\ Review player level, current EXP, maximum HP/Mana, and base stat modifiers.",
        right_text = "Attributes"
    },

    -- Economy & Social Hub
    {
        id = "auction_house",
        name = "[Market] Auction House",
        category = "Economy",
        action = function() if _G.AuctionHouse then AuctionHouse.toggle_ui() end end,
        tooltip = "\\#FF8800\\[Global Marketplace]\\#FFFFFF\\ Asynchronously buy and sell equipment, rare drops, and materials across the entire server.",
        right_text = "Trade"
    },
    {
        id = "trading",
        name = "[Trade] Direct P2P Trade",
        category = "Economy",
        action = function() if _G.Trading then Trading.toggle_ui() else djui_chat_message_create("Direct trade requires targeting an active player.") end end,
        tooltip = "\\#FF8800\\[Peer-to-Peer Trading]\\#FFFFFF\\ Secure synchronous item and coin trade window with active nearby players.",
        right_text = "P2P"
    },
    {
        id = "mail",
        name = "[Post] Mailbox",
        category = "Social",
        action = function() if _G.Mail then Mail.toggle_ui() end end,
        tooltip = "\\#0088FF\\[Player Messaging]\\#FFFFFF\\ Send and receive messages, auction deliveries, and package attachments with friends.",
        right_text = "Inbox"
    },
    {
        id = "guilds",
        name = "[Guild] Guild Hall & Bank",
        category = "Social",
        action = function() if _G.Guilds then Guilds.toggle_ui() end end,
        tooltip = "\\#8800FF\\[Guild Association]\\#FFFFFF\\ Manage guild roster, synchronized guild chat, access shared Guild Bank storage, and Guild Hall.",
        right_text = "Guild"
    },
    {
        id = "party",
        name = "[Party] Group Manager",
        category = "Social",
        action = function() if _G.Party then Party.toggle_ui() end end,
        tooltip = "\\#0088FF\\[Party Coordination]\\#FFFFFF\\ Form cooperative groups, share EXP/drops, track member HUD health, and enable friendly-fire immunity.",
        right_text = "Group"
    },

    -- World & Adventure
    {
        id = "waypoints",
        name = "[Map] Fast Travel",
        category = "World",
        action = function() if _G.Waypoints then Waypoints.toggle_ui() end end,
        tooltip = "\\#00FF88\\[Global Navigation]\\#FFFFFF\\ Instantly teleport to unlocked waypoints and contiguous interconnected level zones.",
        right_text = "Teleport"
    },
    {
        id = "quests",
        name = "[Quest] Quest Log & Dailies",
        category = "Adventure",
        action = function() if _G.Quest then Quest.toggle_ui() end end,
        tooltip = "\\#00FF88\\[Mission Journal]\\#FFFFFF\\ Review active storyline quests, daily tasks, bounty progress, and class-specific quest objectives.",
        right_text = "Journal"
    },
    {
        id = "dungeons",
        name = "[Gauntlet] Dungeons & Raids",
        category = "Adventure",
        action = function() if _G.DungeonUI then DungeonUI.toggle_ui() end end,
        tooltip = "\\#8800FF\\[Instanced Raids]\\#FFFFFF\\ Enter challenging procedural gauntlets (Tower of Trials, Crypt of the Vanished, King Whomp Raid).",
        right_text = "Instances"
    },
    {
        id = "housing",
        name = "[Home] Housing & Decor",
        category = "World",
        action = function() if _G.HousingUI then HousingUI.toggle_ui() elseif _G.Housing then Housing.enter(gMarioStates[0]) end end,
        tooltip = "\\#00FF88\\[Player Housing]\\#FFFFFF\\ Enter instanced private home, place furniture from inventory, and invite party or guild members.",
        right_text = "Home"
    },
    {
        id = "achievements",
        name = "[Feats] Achievements",
        category = "Adventure",
        action = function() if _G.Achievements then Achievements.toggle_ui() end end,
        tooltip = "\\#FF8800\\[Hero Milestones]\\#FFFFFF\\ View unlocked accomplishment badges, titles, and secret world challenges.",
        right_text = "Feats"
    },

    -- System & Administrative Controls
    {
        id = "help",
        name = "[Guide] In-Game Encyclopedia",
        category = "System",
        action = function() if _G.SystemHelp then SystemHelp.toggle_ui() end end,
        tooltip = "\\#AAAAAA\\[Player Manual]\\#FFFFFF\\ Comprehensive reference documentation on all MMO mechanics, movement abilities, hotkeys, and commands.",
        right_text = "Manual"
    },
    {
        id = "config",
        name = "[Settings] System Config",
        category = "System",
        action = function() djui_chat_message_create("System Config: Use /config [key] [val]. See /help config for detailed settings list.") end,
        tooltip = "\\#AAAAAA\\[Game Settings]\\#FFFFFF\\ Configure graphics interest culling, sound alerts, save intervals, and HUD layouts.",
        right_text = "Config"
    },
    {
        id = "admin",
        name = "[Admin] Server Admin Tools",
        category = "System",
        action = function() if _G.Admin then Admin.toggle_ui() end end,
        tooltip = "\\#FF0000\\[Host Moderation]\\#FFFFFF\\ Server management panel for kick, ban, teleports, weather control, and event hosting.",
        right_text = "Server",
        condition = function() return network_is_server() end
    },
    {
        id = "close",
        name = "[Exit] Close Dashboard",
        category = "System",
        action = function() UI_VISIBLE = false; set_mario_action(gMarioStates[0], ACT_IDLE, 0) end,
        tooltip = "Close the centralized MMO Dashboard and return to active gameplay.",
        right_text = "Exit"
    }
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
        -- Category Header
        if selItem.category then
            djui_hud_set_color(120, 200, 255, 255)
            djui_hud_print_text("[" .. string.upper(selItem.category) .. " DOMAIN]", x, y, 0.7)
            y = y + 20
        end

        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(selItem.name, x, y, 0.95)

        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 35, 220, 0.8)
    end

    UIToolkit.draw_menu(
        "MMO DASHBOARD",
        visible_items,
        SELECTION,
        SCROLL_OFFSET,
        renderDetails,
        "A: Launch View   B: Close Dashboard   L+Start: Toggle",
        "Unified high-value dashboard consolidating all Character, Economy, Adventure & System tools."
    )
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

-- Export API
_G.MainMenu = {
    toggle_ui = function()
        UI_VISIBLE = not UI_VISIBLE
        if UI_VISIBLE then
            SELECTION = 1
            SCROLL_OFFSET = 0
            OPEN_TIMER = 5
            set_mario_action(gMarioStates[0], ACT_WAITING_FOR_DIALOG, 0)
        else
            set_mario_action(gMarioStates[0], ACT_IDLE, 0)
        end
    end,
    is_visible = function() return UI_VISIBLE end
}

hook_event(HOOK_ON_HUD_RENDER, main_menu_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, main_menu_update)
