-- Waypoints System
-- Manages fast travel points discovered by the player.

_G.Waypoints = {}

local WAYPOINT_LOCATIONS = {
    { id = "castle", name = "Castle Grounds", level = LEVEL_CASTLE_GROUNDS, pos = {x=0, y=260, z=0} },
    { id = "bob", name = "Bob-omb Battlefield", level = LEVEL_BOB, pos = {x=0, y=300, z=0} },
    { id = "wf", name = "Whomp's Fortress", level = LEVEL_WF, pos = {x=0, y=300, z=0} },
    { id = "ccm", name = "Cool, Cool Mountain", level = LEVEL_CCM, pos = {x=0, y=300, z=0} }
}

-- Load discovered waypoints from mod_storage
function Waypoints.get_unlocked()
    local saved = mod_storage_load("waypoints_unlocked")
    if not saved or saved == "" then
        -- Default starting waypoint
        return { ["castle"] = true }
    end

    local unlocked = {}
    for id in string.gmatch(saved, "([^|]+)") do
        unlocked[id] = true
    end
    return unlocked
end

function Waypoints.unlock(id)
    local unlocked = Waypoints.get_unlocked()
    if not unlocked[id] then
        unlocked[id] = true
        local str = ""
        for k, _ in pairs(unlocked) do
            str = str .. k .. "|"
        end
        mod_storage_save("waypoints_unlocked", str)
        djui_chat_message_create("\\#00FF00\\Waypoint unlocked: " .. id)
    end
end

-- Hook into discovery logic (e.g. stepping near a region)
local function check_waypoint_discovery(m)
    if m.playerIndex ~= 0 then return end
    local np = gNetworkPlayers[0]

    for _, wp in ipairs(WAYPOINT_LOCATIONS) do
        if np.currLevelNum == wp.level then
            local dist = vec3f_dist(m.pos, wp.pos)
            if dist < 1500 then
                Waypoints.unlock(wp.id)
            end
        end
    end
end

hook_event(HOOK_MARIO_UPDATE, check_waypoint_discovery)

-- Expose locations for UI
Waypoints.locations = WAYPOINT_LOCATIONS

function Waypoints.fast_travel(m, wpId)
    local unlocked = Waypoints.get_unlocked()
    if not unlocked[wpId] then return false end

    for _, wp in ipairs(WAYPOINT_LOCATIONS) do
        if wp.id == wpId then
            warp_to_level(wp.level, 1, 0)
            -- Apply coordinates (usually handled by spawn points, but can be forced)
            return true
        end
    end
    return false
end

function Waypoints.toggle_ui()
    if _G.WaypointsUI then
        _G.WaypointsUI.toggle()
    else
        djui_chat_message_create("Waypoints UI not loaded.")
    end
end
