-- FLUDD Actions

local ACT_FLUDD_HOVER = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_AIR)
local ACT_FLUDD_ROCKET = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_AIR)
local ACT_FLUDD_TURBO = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_BUTT_OR_STOMACH_SLIDE)

-- Helper
local function spawn_water_particles(m)
    m.particleFlags = m.particleFlags | PARTICLE_DUST
end

-- Hover Logic
function act_fludd_hover(m)
    if m.input & INPUT_Z_PRESSED ~= 0 then
        return set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    if m.controller.buttonDown & R_TRIG == 0 then
        return set_mario_action(m, ACT_FREEFALL, 0)
    end

    if not FLUDD.use_water(m, 5) then
        return set_mario_action(m, ACT_FREEFALL, 0)
    end

    m.vel.y = 0
    if m.actionTimer < 10 then
        m.vel.y = 10
    end

    local step = perform_air_step(m, 0)
    if step == AIR_STEP_LANDED then
        return set_mario_action(m, ACT_IDLE, 0)
    end

    if m.controller.stickMag > 10 then
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x1000, 0x1000)
        m.forwardVel = m.intendedMag * 0.5
    else
        m.forwardVel = approach_f32(m.forwardVel, 0, 1.0, 1.0)
    end

    set_mario_animation(m, MARIO_ANIM_SLIDE_DIVE)
    spawn_water_particles(m)
    play_sound(SOUND_AIR_BLOW_WIND, m.marioObj.header.gfx.cameraToObject)

    m.actionTimer = m.actionTimer + 1
    return false
end

-- Rocket Logic
function act_fludd_rocket(m)
    if m.actionTimer == 0 then
        play_sound(SOUND_OBJ_MRI_SHOOT, m.marioObj.header.gfx.cameraToObject)
    end

    if m.actionTimer < 15 then
        if not FLUDD.use_water(m, 20) then
            return set_mario_action(m, ACT_FREEFALL, 0)
        end
        m.vel.y = 60
        m.forwardVel = 0
        spawn_water_particles(m)
    else
        return set_mario_action(m, ACT_FREEFALL, 0)
    end

    perform_air_step(m, 0)
    set_mario_animation(m, MARIO_ANIM_SINGLE_JUMP)

    m.actionTimer = m.actionTimer + 1
    return false
end

-- Turbo Logic
function act_fludd_turbo(m)
    if not FLUDD.use_water(m, 8) then
        return set_mario_action(m, ACT_WALKING, 0)
    end

    if m.controller.buttonDown & R_TRIG == 0 then
        if m.forwardVel > 20 then
            return set_mario_action(m, ACT_WALKING, 0)
        else
            return set_mario_action(m, ACT_IDLE, 0)
        end
    end

    m.forwardVel = math.min(m.forwardVel + 5, 120)
    m.faceAngle.y = m.intendedYaw

    local step = perform_ground_step(m)
    if step == GROUND_STEP_LEFT_GROUND then
        return set_mario_action(m, ACT_FREEFALL, 0)
    end

    set_mario_animation(m, MARIO_ANIM_DIVE)
    spawn_water_particles(m)
    play_sound(SOUND_AIR_BLOW_WIND, m.marioObj.header.gfx.cameraToObject)

    return false
end

hook_mario_action(ACT_FLUDD_HOVER, act_fludd_hover)
hook_mario_action(ACT_FLUDD_ROCKET, act_fludd_rocket)
hook_mario_action(ACT_FLUDD_TURBO, act_fludd_turbo)

-- Input Hook
function fludd_input(m)
    if m.playerIndex ~= 0 then return end
    local s = FLUDD.get_state(m)

    if m.pos.y < m.waterLevel then
        s.fluddWater = math.min(s.fluddWater + FLUDD.REGEN_RATE, FLUDD.MAX_WATER)
    end

    if m.controller.buttonPressed & R_TRIG ~= 0 then
        -- Check if current nozzle is equipped AND valid
        if s.fluddNozzle == FLUDD.NOZZLE_HOVER then
            if (m.action & ACT_GROUP_MASK) == ACT_GROUP_AIRBORNE then
                set_mario_action(m, ACT_FLUDD_HOVER, 0)
            end
        elseif s.fluddNozzle == FLUDD.NOZZLE_ROCKET then
             set_mario_action(m, ACT_FLUDD_ROCKET, 0)
        elseif s.fluddNozzle == FLUDD.NOZZLE_TURBO then
             if (m.action & ACT_GROUP_MASK) == ACT_GROUP_MOVING or (m.action & ACT_GROUP_MASK) == ACT_GROUP_STATIONARY then
                 set_mario_action(m, ACT_FLUDD_TURBO, 0)
             end
        end
    end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, fludd_input)

-- Commands to set nozzle (Now checks inventory!)
function on_fludd_command(msg)
    local m = gMarioStates[0]
    local s = FLUDD.get_state(m)

    -- Map string to ID
    local target = FLUDD.NOZZLE_NONE
    if msg == "hover" then target = FLUDD.NOZZLE_HOVER end
    if msg == "rocket" then target = FLUDD.NOZZLE_ROCKET end
    if msg == "turbo" then target = FLUDD.NOZZLE_TURBO end
    if msg == "none" then target = FLUDD.NOZZLE_NONE end

    if target ~= FLUDD.NOZZLE_NONE then
        if FLUDD.has_nozzle(m, target) then
            s.fluddNozzle = target
            djui_chat_message_create("Equipped: " .. msg)
        else
            djui_chat_message_create("You do not own the " .. msg .. " nozzle!")
        end
    else
        s.fluddNozzle = FLUDD.NOZZLE_NONE
        djui_chat_message_create("Unequipped FLUDD")
    end
    return true
end

hook_chat_command("fludd", "Set FLUDD Nozzle", on_fludd_command)
