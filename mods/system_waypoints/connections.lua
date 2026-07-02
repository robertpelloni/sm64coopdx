-- Persistent World Connections
-- Seamlessly warps players between designated world boundaries.

local LEVEL_BOUNDARIES = {
    -- From Castle Grounds (LEVEL_CASTLE_GROUNDS) to Bob-omb Battlefield (LEVEL_BOB)
    {
        fromLevel = LEVEL_CASTLE_GROUNDS,
        toLevel = LEVEL_BOB,
        xMin = -1500, xMax = 1500,
        yMin = -1000, yMax = 1000,
        zMin = -7500, zMax = -7000,
        targetArea = 1
    },
    -- From Bob-omb Battlefield back to Castle Grounds
    {
        fromLevel = LEVEL_BOB,
        toLevel = LEVEL_CASTLE_GROUNDS,
        xMin = -1000, xMax = 1000,
        yMin = -1000, yMax = 1000,
        zMin = 7000, zMax = 7500,
        targetArea = 1
    }
}

local function check_world_connections(m)
    if m.playerIndex ~= 0 then return end
    if not m.marioObj then return end

    local np = gNetworkPlayers[0]
    local currentLevel = np.currLevelNum

    for _, boundary in ipairs(LEVEL_BOUNDARIES) do
        if currentLevel == boundary.fromLevel then
            if m.pos.x >= boundary.xMin and m.pos.x <= boundary.xMax and
               m.pos.y >= boundary.yMin and m.pos.y <= boundary.yMax and
               m.pos.z >= boundary.zMin and m.pos.z <= boundary.zMax then

                -- Trigger Warp
                play_transition(WARP_TRANSITION_FADE_INTO_COLOR, 20, 0, 0, 0)
                warp_to_level(boundary.toLevel, boundary.targetArea, 0)

                djui_chat_message_create("Entering new region...")

                break
            end
        end
    end
end

hook_event(HOOK_MARIO_UPDATE, check_world_connections)
