-- name: System - Waypoints
-- description: Fast travel system for the MMORPG world.
-- depends: system_ui

_G.Waypoints = {}

local SAVE_KEY = "unlocked_waypoints"

Waypoints.unlocked = {}

local WAYPOINT_DEFS = {
    { id = "castle_grounds", name = "Castle Grounds", level = LEVEL_CASTLE_GROUNDS, area = 1, desc = "The central hub of the world." },
    { id = "bobomb_battlefield", name = "Bob-omb Battlefield", level = LEVEL_BOB, area = 1, desc = "A grassy battlefield occupied by Bob-ombs." },
    { id = "whomp_fortress", name = "Whomp's Fortress", level = LEVEL_WF, area = 1, desc = "A stone fortress floating in the sky." },
    { id = "cool_cool_mountain", name = "Cool, Cool Mountain", level = LEVEL_CCM, area = 1, desc = "A snowy mountain peak with slippery slopes." },
    { id = "jolly_roger_bay", name = "Jolly Roger Bay", level = LEVEL_JRB, area = 1, desc = "A deep underwater cove with a sunken ship." }
}

function Waypoints.load()
    local data = mod_storage_load(SAVE_KEY)
    if data and data ~= "" then
        for entry in string.gmatch(data, "([^,]+)") do
            Waypoints.unlocked[entry] = true
        end
    end
    -- Always unlock Castle Grounds silently upon load
    Waypoints.unlocked["castle_grounds"] = true
end

function Waypoints.save()
    local data = ""
    for id, _ in pairs(Waypoints.unlocked) do
        data = data .. id .. ","
    end
    mod_storage_save(SAVE_KEY, data)
end

function Waypoints.unlock(id)
    if not Waypoints.unlocked[id] then
        Waypoints.unlocked[id] = true
        if _G.SaveManager then SaveManager.request_save() else Waypoints.save() end

        for _, wp in ipairs(WAYPOINT_DEFS) do
            if wp.id == id then
                djui_chat_message_create("\\#00ff00\\Waypoint Unlocked: " .. wp.name)
                play_sound(SOUND_GENERAL_STAR_APPEARS, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                break
            end
        end
    end
end

-- Check unlocking when entering a level
function waypoints_level_init()
    local levelNum = gNetworkPlayers[0].currLevelNum
    -- Skip checking Castle Grounds since it's already unlocked silently on load, preventing spam
    if levelNum == LEVEL_CASTLE_GROUNDS then return end

    for _, wp in ipairs(WAYPOINT_DEFS) do
        if wp.level == levelNum then
            Waypoints.unlock(wp.id)
            break
        end
    end
end

hook_event(HOOK_ON_LEVEL_INIT, waypoints_level_init)

function waypoints_init()
    Waypoints.load()
end

hook_event(HOOK_ON_SYNC_VALID, waypoints_init)

-- UI
_G.WaypointsUI = {}
local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function WaypointsUI.render()
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local items = {}
    for _, wp in ipairs(WAYPOINT_DEFS) do
        if Waypoints.unlocked[wp.id] then
            table.insert(items, {
                id = wp.id,
                name = wp.name,
                tooltip = wp.desc,
                level = wp.level,
                area = wp.area
            })
        end
    end

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(selItem.name, x, y, 1)
        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 40, 22, 0.8)
    end

    UIToolkit.draw_menu("WAYPOINTS", items, SELECTION, SCROLL_OFFSET, renderDetails, "A: Travel  B: Close", "Fast travel to unlocked locations.")
end

function WaypointsUI.update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local items = {}
    for _, wp in ipairs(WAYPOINT_DEFS) do
        if Waypoints.unlocked[wp.id] then
            table.insert(items, wp)
        end
    end

    local maxItems = #items
    if maxItems == 0 then
        -- Should not happen since Castle Grounds is always unlocked
        if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
            UI_VISIBLE = false
            set_mario_action(m, ACT_IDLE, 0)
        end
        return
    end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act then
        play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        local item = items[SELECTION]
        if item then
            UI_VISIBLE = false
            set_mario_action(m, ACT_IDLE, 0)
            warp_to_level(item.level, item.area, 0)
        end
    end

    if close then
        UI_VISIBLE = false
    end
end

function WaypointsUI.toggle()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

hook_event(HOOK_ON_HUD_RENDER, WaypointsUI.render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, WaypointsUI.update)

function on_waypoint_command(msg)
    WaypointsUI.toggle()
    return true
end

hook_chat_command("waypoints", "Open waypoints menu", on_waypoint_command)
hook_chat_command("wp", "Open waypoints menu", on_waypoint_command)
