-- Test Agent (Goomba-like)
-- Uses the Possession API to move when controlled.

local E_MODEL_TEST_AGENT = smlua_model_util_get_id("goomba_geo") -- Re-use Goomba model

function bhv_test_agent_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oGravity = -4.0
    o.oFriction = 0.8
    o.oBuoyancy = 1.0
    o.oOpacity = 255

    -- Network Sync Init
    network_init_object(o, true, {
        "oOpacity",
        "oForwardVel",
        "oMoveAngleYaw",
        "oVelY"
    })
end

function bhv_test_agent_loop(o)
    -- Physics
    object_step(o)

    -- Check for Interaction (Start Possession)
    local m = gMarioStates[0]
    if dist_between_objects(o, m.marioObj) < 100 then
        -- If Mario punches, possess
        if (m.action & ACT_FLAG_ATTACKING) ~= 0 and not Possession.get_possessed(m.playerIndex) then
             Possession.start(m, o)
        end
    end

    -- Check Control
    -- We need to check if ANY player is possessing this object.
    -- Possession API handles the "input" map globally for simplicity in prototype.
    local inputs = Possession.get_inputs(o)

    -- If we are the owner of the object (or authority), we process inputs.
    -- If inputs are present, it means someone is controlling it via the synced input table (if we implemented that).
    -- Wait, our current API `Possession.inputs` is local-only in the previous step.
    -- To fix this fully, we need to read the controlling player's SyncTable.

    -- Alternative: The controlling player sets the object's fields directly if they "own" it?
    -- No, usually the object owner simulates it.
    -- Let's rely on the fact that if a player possesses it, they send inputs via `gPlayerSyncTable` (Phase 2),
    -- OR we just rely on `network_send_object` if the controlling player takes ownership.

    -- For this fix, let's assume the API `get_inputs` now reads from the controlling player's sync data.
    -- BUT, `api.lua` changes are needed for that.
    -- Let's check if `Possession.get_inputs` returns anything.

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
    -- Use spawn_sync_object so it exists for everyone
    local obj = spawn_sync_object(
        id_bhvTestAgent,
        E_MODEL_TEST_AGENT,
        m.pos.x + 200 * sins(m.faceAngle.y),
        m.pos.y + 100,
        m.pos.z + 200 * coss(m.faceAngle.y),
        nil
    )
    djui_chat_message_create("Spawned Synced Test Agent")
    return true
end

hook_chat_command("spawn_agent", "Spawn a possessable agent", on_spawn_agent)
