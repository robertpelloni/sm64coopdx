-- name: Mechanic - Gravity (Launch Star)
-- description: Super Mario Galaxy style Launch Stars.

-- Constants
local ACT_LAUNCH_STAR = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_INVULNERABLE)
local LAUNCH_SPEED = 100
local LAUNCH_GRAVITY = -4

-- Sync Object
local E_MODEL_LAUNCH_STAR = smlua_model_util_get_id("star_geo") -- Placeholder model (Star)

function bhv_launch_star_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oGravity = 0
    o.oFriction = 0
    o.oBuoyancy = 0

    -- Target position (relative or absolute?)
    -- Let's store target in oPosX/Y/Z of a hidden child or just BehParams?
    -- oBehParams2ndByte could be an index to a "path" definition.
    -- For pilot, let's just launch UP and FORWARD based on Yaw.

    network_init_object(o, true, nil)
end

function bhv_launch_star_loop(o)
    -- Rotate
    o.oFaceAngleYaw = o.oFaceAngleYaw + 0x200

    -- Check collision
    local m = gMarioStates[0]
    local dist = dist_between_objects(o, m.marioObj)

    if dist < 150 then
        if m.action ~= ACT_LAUNCH_STAR then
            -- Trigger Launch
            m.faceAngle.y = o.oFaceAngleYaw
            set_mario_action(m, ACT_LAUNCH_STAR, 0)

            -- Set velocity
            m.forwardVel = LAUNCH_SPEED
            m.vel.y = 80

            play_sound(SOUND_GENERAL_BREAK_BOX, m.marioObj.header.gfx.cameraToObject) -- Placeholder sound
            -- Galaxy Spin Sound would be better
        end
    end
end

local id_bhvLaunchStar = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_launch_star_init, bhv_launch_star_loop)

-- Action State
function act_launch_star(m)
    -- Spin animation
    set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)

    -- Physics
    -- Simple arc
    m.vel.y = m.vel.y + LAUNCH_GRAVITY

    local step = perform_air_step(m, 0)

    if step == AIR_STEP_LANDED then
        play_sound(SOUND_ACTION_TERRAIN_LANDING, m.marioObj.header.gfx.cameraToObject)
        return set_mario_action(m, ACT_FREEFALL_LAND, 0)
    elseif step == AIR_STEP_HIT_WALL then
        m.forwardVel = 0
        return set_mario_action(m, ACT_FREEFALL, 0)
    end

    m.particleFlags = m.particleFlags | PARTICLE_SPARKLES

    return false
end

hook_mario_action(ACT_LAUNCH_STAR, act_launch_star)

-- Spawn Command for testing
function on_spawn_star(msg)
    local m = gMarioStates[0]
    spawn_sync_object(
        id_bhvLaunchStar,
        E_MODEL_LAUNCH_STAR,
        m.pos.x, m.pos.y + 200, m.pos.z,
        nil
    )
    djui_chat_message_create("Spawned Launch Star")
    return true
end

hook_chat_command("launch_star", "Spawn Launch Star", on_spawn_star)
