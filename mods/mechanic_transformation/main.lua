-- Core Logic

function act_transformation(m)
    local id = Transformation.get_current(m)
    if not id then
        set_mario_action(m, ACT_IDLE, 0)
        return 1
    end

    local def = Transformation.get_def(id)
    if not def then
        set_mario_action(m, ACT_IDLE, 0)
        return 1
    end

    -- 1. Physics Override
    -- Standard ground movement but modified
    local speed = def.speed or 30.0

    -- Inputs
    local intendedMag = m.intendedMag
    local intendedYaw = m.intendedYaw

    if intendedMag > 0 then
        m.forwardVel = approach_f32(m.forwardVel, speed, 2.0, 2.0)
        m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, intendedYaw, 0x800)
        m.moveAngle.y = m.faceAngle.y
    else
        m.forwardVel = approach_f32(m.forwardVel, 0, 2.0, 2.0)
    end

    m.vel.x = sins(m.faceAngle.y) * m.forwardVel
    m.vel.z = coss(m.faceAngle.y) * m.forwardVel

    -- Gravity
    -- def.gravity?

    -- Animation
    -- def.anim?
    if m.forwardVel > 1 then
        set_mario_animation(m, MARIO_ANIM_RUNNING) -- Placeholder
    else
        set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_LEFT) -- Placeholder
    end

    -- Collision
    local step = perform_ground_step(m)
    if step == GROUND_STEP_LEFT_GROUND then
        -- Handle Air?
        -- For now, simple jump land logic or fall
        -- If we want custom air logic, we need ACT_TRANSFORMATION_AIR
        -- Let's just fall for now
        -- set_mario_action(m, ACT_FREEFALL, 0) -- This would break transform state!
        -- We must handle air in this action or separate one.
        -- Let's add gravity logic here for simplicity of "One Action"

        -- Fall logic
        m.vel.y = m.vel.y - 4.0
        m.pos.x = m.pos.x + m.vel.x
        m.pos.z = m.pos.z + m.vel.z
        m.pos.y = m.pos.y + m.vel.y

        local floorHeight = find_floor(m.pos.x, m.pos.y, m.pos.z)
        if m.pos.y < floorHeight then
            m.pos.y = floorHeight
            m.vel.y = 0
        end
    end

    if step == GROUND_STEP_HIT_WALL then
        m.forwardVel = 0
        -- Wall Cling Ability?
        if def.abilities and def.abilities.wallCling then
            -- Logic: Stick to wall
            -- Not implemented fully in prototype
        end
    end

    -- Jump
    if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
        m.vel.y = def.jumpForce or 40.0
        -- Start air sub-state?
    end

    -- Exit (Z + B?)
    if (m.controller.buttonDown & Z_TRIG) ~= 0 and (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        Transformation.clear(m)
        return 1
    end

    return 0
end

hook_mario_action(ACT_TRANSFORMATION, act_transformation)

-- Ensure Model Sync on Update (for remote players)
function transformation_update(m)
    local id = Transformation.get_current(m)
    if id and m.playerIndex ~= 0 then
        -- Remote player is transformed
        local def = Transformation.get_def(id)
        if def and def.modelId then
            obj_set_model_extended(m.marioObj, def.modelId)
        end
    end
end

hook_event(HOOK_MARIO_UPDATE, transformation_update)
