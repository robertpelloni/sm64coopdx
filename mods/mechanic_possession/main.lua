-- Core Logic for Possession

function act_possession(m)
    local obj = Possession.get_possessed(m.playerIndex)

    if not obj then
        -- Error state, exit
        set_mario_action(m, ACT_IDLE, 0)
        return 0
    end

    -- 1. Sync Mario to Object
    -- We keep Mario exactly at the object so the camera follows it.
    m.pos.x = obj.oPosX
    m.pos.y = obj.oPosY
    m.pos.z = obj.oPosZ

    -- 2. Pass Inputs
    -- We store the controller data in a global table keyed by the object
    -- The object's behavior script should read this.
    Possession.inputs[obj] = {
        stickX = m.controller.stickX,
        stickY = m.controller.stickY,
        buttonPressed = m.controller.buttonPressed,
        buttonDown = m.controller.buttonDown,
        camAngle = m.area.camera.yaw
    }

    -- 3. Visuals
    -- Ensure Mario is hidden (redundant safety)
    obj_set_model_extended(m.marioObj, MODEL_NONE)

    -- 4. Exit Condition (Z Press)
    if (m.controller.buttonPressed & Z_TRIG) ~= 0 then
        Possession.stop(m)
        return 1
    end

    return 0
end

hook_mario_action(ACT_POSSESSION, act_possession)
