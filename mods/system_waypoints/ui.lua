-- Fast Travel UI

local WaypointsUI = {
    isOpen = false,
    openTimer = 0,
    selectedIndex = 1,
    scrollOffset = 0
}

local function draw_waypoints_ui()
    if not WaypointsUI.isOpen then return end
    if not _G.UIToolkit then return end
    if not _G.Waypoints then return end

    local unlocked = _G.Waypoints.get_unlocked()
    local items = {}

    for _, wp in ipairs(_G.Waypoints.locations) do
        if unlocked[wp.id] then
            table.insert(items, {
                id = wp.id,
                name = wp.name,
                tooltip = "Travel to " .. wp.name .. "."
            })
        else
            table.insert(items, {
                id = "locked",
                name = "???",
                tooltip = "This waypoint has not been discovered yet."
            })
        end
    end

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(255, 255, 255, 255)
        _G.UIToolkit.draw_wrapped_text(selItem.tooltip, x, y, 200, 1.0)
    end

    _G.UIToolkit.draw_menu(
        "Fast Travel",
        items,
        WaypointsUI.selectedIndex,
        WaypointsUI.scrollOffset,
        renderDetails,
        "[A] Travel  [B] Close",
        "Select a discovered location to travel to instantly."
    )
end

local function handle_waypoints_input(m)
    if m.playerIndex ~= 0 then return end
    if not WaypointsUI.isOpen then return end

    local unlocked = _G.Waypoints.get_unlocked()
    local itemsCount = #_G.Waypoints.locations

    local sel, timer, act, close = _G.UIToolkit.handle_input(m, WaypointsUI.selectedIndex, itemsCount, WaypointsUI.openTimer)
    WaypointsUI.selectedIndex = sel
    WaypointsUI.openTimer = timer
    WaypointsUI.scrollOffset = _G.UIToolkit.calculate_scroll(WaypointsUI.selectedIndex, WaypointsUI.scrollOffset, itemsCount)

    if act then
        local wp = _G.Waypoints.locations[WaypointsUI.selectedIndex]
        if wp and unlocked[wp.id] then
            _G.Waypoints.fast_travel(m, wp.id)
            WaypointsUI.isOpen = false
            set_mario_action(m, ACT_IDLE, 0)
        else
            play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
        end
    end

    if close then
        WaypointsUI.isOpen = false
        set_mario_action(m, ACT_IDLE, 0)
    end
end

function WaypointsUI.toggle()
    local m = gMarioStates[0]
    if WaypointsUI.isOpen then
        WaypointsUI.isOpen = false
        set_mario_action(m, ACT_IDLE, 0)
    else
        WaypointsUI.isOpen = true
        WaypointsUI.openTimer = 15
        WaypointsUI.selectedIndex = 1
        WaypointsUI.scrollOffset = 0
        set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
    end
end

hook_event(HOOK_ON_HUD_RENDER, draw_waypoints_ui)
hook_event(HOOK_MARIO_UPDATE, handle_waypoints_input)

_G.WaypointsUI = WaypointsUI
