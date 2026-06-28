-- name: System - Seamless Connections
-- description: Allows walking between levels without the castle hub, enabling a persistent world feel.

local connections = {
    -- Bob-omb Battlefield <-> Whomp's Fortress
    {
        from = LEVEL_BOB, area = 1,
        trigger = { x = 6000, y = 0, z = 6000, size = 1000 },
        to = LEVEL_WF, to_area = 1,
        spawn = { x = -2500, y = 300, z = -1000 } -- Near the entrance of WF
    },
    {
        from = LEVEL_WF, area = 1,
        trigger = { x = -2800, y = 200, z = -1200, size = 1000 },
        to = LEVEL_BOB, to_area = 1,
        spawn = { x = 5500, y = 0, z = 5500 } -- Back in BOB
    },
    -- Whomp's Fortress <-> Cool, Cool Mountain
    {
        from = LEVEL_WF, area = 1,
        trigger = { x = 4000, y = 3500, z = -3000, size = 1000 }, -- Top of fortress
        to = LEVEL_CCM, to_area = 1,
        spawn = { x = 100, y = 6000, z = 3000 } -- Top of mountain
    },
    {
        from = LEVEL_CCM, area = 1,
        trigger = { x = 500, y = 5800, z = 3500, size = 1000 },
        to = LEVEL_WF, to_area = 1,
        spawn = { x = 3800, y = 3500, z = -2500 }
    }
}

-- Add a warp hook to handle exact spawning positions for these connections
local pending_spawn = nil

local function check_connections(m)
    if m.playerIndex ~= 0 then return end

    local cLevel = gNetworkPlayers[0].currLevelNum
    local cArea = gNetworkPlayers[0].currAreaIndex

    for _, conn in ipairs(connections) do
        if cLevel == conn.from and cArea == conn.area then
            local distSq = (m.pos.x - conn.trigger.x)^2 + (m.pos.z - conn.trigger.z)^2
            if distSq < conn.trigger.size^2 and math.abs(m.pos.y - conn.trigger.y) < 1500 then

                -- Ensure we are moving into the zone (basic cooldown/check could go here)
                -- Trigger warp
                pending_spawn = conn.spawn
                warp_to_level(conn.to, conn.to_area, 0)
                djui_chat_message_create("Traveling to new zone...")
            end
        end
    end
end

local function apply_spawn(m)
    if m.playerIndex ~= 0 then return end
    if pending_spawn then
        m.pos.x = pending_spawn.x
        m.pos.y = pending_spawn.y
        m.pos.z = pending_spawn.z
        pending_spawn = nil
    end
end

hook_event(HOOK_MARIO_UPDATE, check_connections)
hook_event(HOOK_ON_LEVEL_INIT, apply_spawn)
