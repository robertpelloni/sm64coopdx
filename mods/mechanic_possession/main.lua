-- Core Logic for Possession

function act_possession(m)
    local obj = Possession.get_possessed(m.playerIndex)

    if not obj then
        -- If remote player has synced ID but object not loaded yet?
        -- We wait or show idle.
        -- If local player, we shouldn't be here if logic is correct.

        if m.playerIndex == 0 then
             set_mario_action(m, ACT_IDLE, 0)
        else
             -- Remote: Keep hidden? Or show Idle?
             -- If we don't have the object, we can't sync position.
             -- So we rely on standard Mario position sync.
             -- But ACT_POSSESSION overrides position in this function.
             -- If we don't find obj, we do nothing (let engine handle position).
        end
        return 0
    end

    -- 1. Sync Mario to Object
    m.pos.x = obj.oPosX
    m.pos.y = obj.oPosY
    m.pos.z = obj.oPosZ

    -- 2. Pass Inputs (Handled by get_inputs in object loop)

    -- 3. Visuals
    obj_set_model_extended(m.marioObj, MODEL_NONE)

    -- 4. Exit Condition (Z Press)
    if (m.controller.buttonPressed & Z_TRIG) ~= 0 then
        Possession.stop(m)
        return 1
    end

    return 0
end

hook_mario_action(ACT_POSSESSION, act_possession)
