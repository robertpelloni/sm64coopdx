-- name: System - Main Menu
-- description: Centralized UI for accessing MMORPG features.

local MENU_OPEN = false
local SELECTION = 1

local OPTIONS = {
    {
        name = "Resume",
        description = "Return to the game.",
        action = function() MENU_OPEN = false end
    },
    {
        name = "Inventory",
        description = "View items, equipment, and resources.",
        action = function() if _G.Inventory and _G.Inventory.toggle_ui then _G.Inventory.toggle_ui() end end
    },
    {
        name = "Quests",
        description = "Track active quests and objectives.",
        action = function() if _G.Quest and _G.Quest.toggle_ui then _G.Quest.toggle_ui() end end
    },
    {
        name = "Classes",
        description = "View class abilities. (Use /class [name])",
        action = function() djui_chat_message_create("Use /class [warrior|mage|rogue]") end
    },
    {
        name = "Guild",
        description = "Manage guild membership. (Use /guild)",
        action = function() djui_chat_message_create("Use /guild [join|leave] [name]") end
    },
    {
        name = "Close",
        description = "Close the menu.",
        action = function() MENU_OPEN = false end
    }
}

function menu_render()
    if not MENU_OPEN then return end

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()
    local cx = w / 2
    local cy = h / 2

    -- Background
    djui_hud_set_color(0, 0, 50, 240)
    djui_hud_render_rect(cx - 150, cy - 120, 300, 240)

    -- Title
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("MAIN MENU", cx - 45, cy - 100, 1)

    -- Options
    local y = cy - 60
    for i, opt in ipairs(OPTIONS) do
        if i == SELECTION then
            djui_hud_set_color(255, 255, 0, 255)
            djui_hud_print_text("> " .. opt.name, cx - 100, y, 1)
        else
            djui_hud_set_color(200, 200, 200, 255)
            djui_hud_print_text("  " .. opt.name, cx - 100, y, 1)
        end
        y = y + 30
    end

    -- Description Footer
    local selOpt = OPTIONS[SELECTION]
    if selOpt and selOpt.description then
        djui_hud_set_color(150, 150, 150, 255)
        local descW = djui_hud_measure_text(selOpt.description)
        -- Center it roughly
        djui_hud_print_text(selOpt.description, cx - descW/2, cy + 90, 1)
    end
end

function menu_update(m)
    if m.playerIndex ~= 0 then return end

    -- Toggle: L + START
    if (m.controller.buttonDown & L_TRIG) ~= 0 and (m.controller.buttonPressed & START_BUTTON) ~= 0 then
        MENU_OPEN = not MENU_OPEN
        if MENU_OPEN then
            -- Close overlapping UIs
            if _G.Inventory and _G.Inventory.close_ui then _G.Inventory.close_ui() end
            if _G.Quest and _G.Quest.close_ui then _G.Quest.close_ui() end

            set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
        else
            set_mario_action(m, ACT_IDLE, 0)
        end
        return
    end

    if not MENU_OPEN then return end

    -- Force freeze
    if m.action ~= ACT_WAITING_FOR_DIALOG then
        set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
    end

    -- Navigation
    if (m.controller.buttonPressed & D_JPAD) ~= 0 then
        SELECTION = SELECTION + 1
        if SELECTION > #OPTIONS then SELECTION = 1 end
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
    end
    if (m.controller.buttonPressed & U_JPAD) ~= 0 then
        SELECTION = SELECTION - 1
        if SELECTION < 1 then SELECTION = #OPTIONS end
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
    end

    -- Select
    if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
        local opt = OPTIONS[SELECTION]
        if opt and opt.action then
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
            opt.action()

            -- Close Main Menu if opening a subsystem UI
            if opt.name == "Inventory" or opt.name == "Quests" or opt.name == "Resume" or opt.name == "Close" then
                MENU_OPEN = false
                if opt.name == "Resume" or opt.name == "Close" then
                    set_mario_action(m, ACT_IDLE, 0)
                end
            end
        end
    end

    -- Back
    if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        MENU_OPEN = false
        set_mario_action(m, ACT_IDLE, 0)
    end
end

hook_event(HOOK_ON_HUD_RENDER, menu_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, menu_update)
