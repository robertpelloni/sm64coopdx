-- name: System - Connected World
-- description: Links levels together for a seamless open-world feel.

local WorldLinks = {
    -- Example: Castle Grounds -> Bob-omb Battlefield (Skip painting)
    {
        src = {level = LEVEL_CASTLE_GROUNDS, area = 1, x = -200, y = 0, z = 1500}, -- Arbitrary spot near start
        dest = {level = LEVEL_BOB, area = 1, nodeId = 1},
        name = "Bob-omb Battlefield"
    },
    -- Bob-omb Battlefield -> Castle Grounds
    {
        src = {level = LEVEL_BOB, area = 1, x = 0, y = 0, z = 0}, -- Start point
        dest = {level = LEVEL_CASTLE_GROUNDS, area = 1, nodeId = 1},
        name = "Castle Grounds"
    }
}

local E_MODEL_PORTAL = smlua_model_util_get_id("sparkles_animation_geo") -- Visual placeholder

function bhv_portal_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oGravity = 0
    o.oBounciness = 0
    o.oOpacity = 200
end

function bhv_portal_loop(o)
    -- Visual effect: Rotate
    o.oFaceAngleYaw = o.oFaceAngleYaw + 0x200

    -- Interaction
    local m = gMarioStates[0]
    if dist_between_objects(o, m.marioObj) < 100 then
        -- Warp!
        -- o.oBehParams stores index in WorldLinks?
        -- We can store index in oBehParams2ndByte
        local idx = o.oBehParams2ndByte
        local link = WorldLinks[idx]

        if link then
            djui_chat_message_create("Warping to " .. link.name)
            -- warp_to_level(level, area, actId) -> actId?
            -- smlua warp_to_level takes (level, area, act)
            -- We want to go to a warp NODE usually.
            -- warp_to_warpnode(level, area, act, warpNode)

            -- Let's use initiate_warp(level, area, warpNode, 0)
            initiate_warp(link.dest.level, link.dest.area, link.dest.nodeId, 0)
        end
    end
end

local id_bhvPortal = hook_behavior(nil, OBJ_LIST_LEVEL, false, bhv_portal_init, bhv_portal_loop)

function world_init()
    -- Spawn portals for current level
    local m = gMarioStates[0]
    local currLvl = gNetworkPlayers[m.playerIndex].currLevelNum
    local currArea = gNetworkPlayers[m.playerIndex].currAreaIndex

    -- Clear existing? Engine handles cleanup on level change.

    for i, link in ipairs(WorldLinks) do
        if link.src.level == currLvl and link.src.area == currArea then
            spawn_non_sync_object(
                id_bhvPortal,
                E_MODEL_PORTAL,
                link.src.x, link.src.y, link.src.z,
                function(o)
                    o.oBehParams2ndByte = i
                end
            )
        end
    end
end

hook_event(HOOK_ON_LEVEL_INIT, world_init)
-- Also run once on load if already in level
world_init()
