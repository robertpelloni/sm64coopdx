-- Test Agent (Goomba-like)
-- Uses the Possession API to move when controlled.

local E_MODEL_TEST_AGENT = smlua_model_util_get_id("goomba_geo") -- Re-use Goomba model

function bhv_test_agent_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oGravity = -4.0
    o.oFriction = 0.8
    o.oBuoyancy = 1.0
    o.oOpacity = 255
end

function bhv_test_agent_loop(o)
    -- Physics
    object_step(o)

    -- Check for Interaction (Start Possession)
    -- If Mario interacts, start possession
    -- Simplification: Check distance for test
    local m = gMarioStates[0]
    if dist_between_objects(o, m.marioObj) < 100 then
        -- Check if Mario is punching/interacting
        -- For test, we just use a command, but let's add interaction logic
        -- If Mario punches, possess
        if (m.action & ACT_FLAG_ATTACKING) ~= 0 and not Possession.get_possessed(m.playerIndex) then
             Possession.start(m, o)
        end
    end

    -- Check Control
    local inputs = Possession.get_inputs(o)
    if inputs then
        -- Controlled Movement
        local stickX = inputs.stickX
        local stickY = inputs.stickY
        local camYaw = inputs.camAngle

        if math.abs(stickX) > 10 or math.abs(stickY) > 10 then
            local intendedYaw = atan2s(-stickY, stickX) + camYaw
            o.oMoveAngleYaw = approach_s16_symmetric(o.oMoveAngleYaw, intendedYaw, 0x800)
            o.oForwardVel = 10.0
        else
            o.oForwardVel = approach_f32(o.oForwardVel, 0, 1.0, 1.0)
        end

        -- Jump
        if (inputs.buttonPressed & A_BUTTON) ~= 0 and (o.oMoveFlags & OBJ_MOVE_ON_GROUND) ~= 0 then
            o.oVelY = 30.0
        end

        -- Visual indicator
        o.oOpacity = 150 -- Transparent when possessed
    else
        -- AI Behavior (Idle)
        o.oForwardVel = 0
        o.oOpacity = 255
    end
end

local id_bhvTestAgent = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_test_agent_init, bhv_test_agent_loop)

-- Spawn Command
function on_spawn_agent(msg)
    local m = gMarioStates[0]
    local obj = spawn_non_sync_object(
        id_bhvTestAgent,
        E_MODEL_TEST_AGENT,
        m.pos.x + 200 * sins(m.faceAngle.y),
        m.pos.y + 100,
        m.pos.z + 200 * coss(m.faceAngle.y),
        nil
    )
    djui_chat_message_create("Spawned Test Agent")
    return true
end

hook_chat_command("spawn_agent", "Spawn a possessable agent", on_spawn_agent)
