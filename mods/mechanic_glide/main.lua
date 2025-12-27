-- name: Mechanic - Spyro Glide
-- description: A Spyro the Dragon style glide mechanic.\n\nPress A while in the air to glide.\nPress Z or A to cancel.\n\nFeatures:\n- Slow descent\n- Constant forward speed\n- Steering control\n- Bonk on walls

local ACT_GLIDE = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)

local GLIDE_FORWARD_SPEED = 40.0
local GLIDE_VERTICAL_SPEED = -20.0
local GLIDE_GRAVITY = -2.0
local GLIDE_TERMINAL_VELOCITY = -30.0

--- @param m MarioState
function act_glide(m)
    -- 0. Update Timer
    m.actionTimer = m.actionTimer + 1

    -- 1. Animation
    set_mario_animation(m, MARIO_ANIM_WING_FLY)

    -- 2. Audio (Looping sound)
    -- Use the flying sound
    play_sound(SOUND_MOVING_FLYING, m.marioObj.header.gfx.cameraToObject)

    -- 3. Input / Physics

    -- Steering
    -- Adjust face angle based on intended yaw (analog stick)
    if m.input & INPUT_NONZERO_ANALOG ~= 0 then
        local intendedYaw = m.intendedYaw
        local currentYaw = m.faceAngle.y
        -- Smooth turn towards intended direction
        -- Spyro turns relatively quickly
        local turnSpeed = 0x600 -- 1536
        m.faceAngle.y = approach_s16_symmetric(currentYaw, intendedYaw, turnSpeed)
    end
    -- Always move forward in the direction faced
    m.moveAngle.y = m.faceAngle.y

    -- Forward Speed
    -- Spyro glides at a relatively constant speed, maybe slightly affected by pitch if we were doing complex physics
    -- For now, constant speed
    m.vel.x = sins(m.faceAngle.y) * GLIDE_FORWARD_SPEED
    m.vel.z = coss(m.faceAngle.y) * GLIDE_FORWARD_SPEED
    m.forwardVel = GLIDE_FORWARD_SPEED

    -- Vertical Speed (Gravity)
    -- Gliding is a controlled fall.
    if m.vel.y > GLIDE_VERTICAL_SPEED then
        m.vel.y = m.vel.y + GLIDE_GRAVITY
    else
        m.vel.y = approach_f32(m.vel.y, GLIDE_TERMINAL_VELOCITY, 2.0, 2.0)
    end

    -- 4. Collision / Steps
    local stepResult = perform_air_step(m, 0)

    if stepResult == AIR_STEP_LANDED then
        set_mario_action(m, ACT_JUMP_LAND, 0)
        return 1
    elseif stepResult == AIR_STEP_HIT_WALL then
        mario_set_forward_vel(m, -16.0)
        -- Bonk anim/sound?
        play_sound(SOUND_ACTION_BONK, m.marioObj.header.gfx.cameraToObject)
        set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
        return 1
    elseif stepResult == AIR_STEP_HIT_LAVA_WALL then
        lava_boost_on_wall(m)
        return 1
    end

    -- 5. Cancellation
    -- Drop on Z or A pressed again.
    -- IMPORTANT: Check actionTimer to ensure we don't cancel on the same frame we started (due to A being held/pressed).
    if m.actionTimer > 5 and (m.controller.buttonPressed & (Z_TRIG | A_BUTTON)) ~= 0 then
        set_mario_action(m, ACT_FREEFALL, 0)
        return 1
    end

    return 0
end

--- @param m MarioState
function mario_before_phys_step(m)
    -- Check for Glide trigger
    -- Conditions:
    -- 1. In Air (Action flag AIR)
    -- 2. Not already gliding
    -- 3. A button pressed
    -- 4. Not in a state where we shouldn't glide (e.g. damaged, cutscene)
    -- 5. Not holding an object? (Spyro can't glide with objects usually, but maybe Mario can?)
    --    Let's restrict holding for now.

    if m.action == ACT_GLIDE then return end

    if (m.action & ACT_FLAG_AIR) ~= 0 and
       (m.action & ACT_FLAG_INVULNERABLE) == 0 and -- No gliding if hurt
       m.heldObj == nil then

        -- Check specific exclusions (e.g. cannon shot, flying)
        if m.action == ACT_SHOT_FROM_CANNON or
           m.action == ACT_FLYING or
           m.action == ACT_RIDING_SHELL_JUMP or
           m.action == ACT_RIDING_SHELL_FALL then
            return
        end

        -- Check Input
        if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
            -- Transition
            set_mario_action(m, ACT_GLIDE, 0)

            -- Consume input so it doesn't trigger double jump if we are in single jump
            -- (Lua can't easily consume input bits for the engine, but changing action overrides the old action's logic)
        end
    end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, mario_before_phys_step)
hook_mario_action(ACT_GLIDE, act_glide)
