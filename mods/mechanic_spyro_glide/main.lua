-- name: Mechanic - Spyro Glide
-- description: Allows the player to glide like Spyro when holding A in the air.
-- depends: system_classes, system_progression

-- Define the action
local ACT_GLIDE = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)

local GLIDE_SPEED = 30.0
local GLIDE_FALL_SPEED = -5.0
local GLIDE_TURN_SPEED = 0x400 -- About 5.6 degrees per frame

local function get_glide_state(m)
    return gPlayerSyncTable[m.playerIndex].is_gliding or false
end

local function set_glide_state(m, state)
    gPlayerSyncTable[m.playerIndex].is_gliding = state
end

local function act_glide(m)
    -- Check if we should stop gliding
    if (m.controller.buttonDown & A_BUTTON) == 0 then
        set_glide_state(m, false)
        return set_mario_action(m, ACT_FREEFALL, 0)
    end

    -- Consume Stamina/Mana if applicable
    if _G.Combat and _G.Classes then
        -- Only Rogue can glide natively in this MMO design, or just costs mana
        local cType = Classes.get_class(m)
        if cType ~= Classes.TYPE_ROGUE then
            set_glide_state(m, false)
            return set_mario_action(m, ACT_FREEFALL, 0)
        end
        if m.actionTimer % 30 == 0 then
             if not Combat.use_mana(m, 2) then
                 set_glide_state(m, false)
                 return set_mario_action(m, ACT_FREEFALL, 0)
             end
        end
    end

    -- Play animation (using dive animation as a placeholder for gliding)
    set_mario_animation(m, MARIO_ANIM_DIVE)

    -- Handle turning
    local targetYaw = m.intendedYaw
    local yawDiff = targetYaw - m.faceAngle.y
    -- Normalize yawDiff
    while yawDiff > 32767 do yawDiff = yawDiff - 65536 end
    while yawDiff < -32768 do yawDiff = yawDiff + 65536 end

    if m.intendedMag > 0 then
        if yawDiff > 0 then
            m.faceAngle.y = m.faceAngle.y + math.min(yawDiff, GLIDE_TURN_SPEED)
        else
            m.faceAngle.y = m.faceAngle.y + math.max(yawDiff, -GLIDE_TURN_SPEED)
        end
    end

    -- Set velocity
    m.forwardVel = GLIDE_SPEED
    m.vel.y = GLIDE_FALL_SPEED

    -- Move Mario
    perform_air_step(m, 0)

    -- Particles
    m.particleFlags = m.particleFlags | PARTICLE_SPARKLES

    m.actionTimer = m.actionTimer + 1
    return false
end

local function check_glide_start(m)
    -- Only start gliding if we are falling, pressing A, not already gliding, and have Rogue class
    if (m.action == ACT_FREEFALL or m.action == ACT_JUMP or m.action == ACT_DOUBLE_JUMP or m.action == ACT_TRIPLE_JUMP) then
        if (m.controller.buttonPressed & A_BUTTON) ~= 0 and m.vel.y < 0 then
            if _G.Classes and Classes.get_class(m) == Classes.TYPE_ROGUE then
                set_glide_state(m, true)
                set_mario_action(m, ACT_GLIDE, 0)
            end
        end
    end
end

local function glide_hook(m)
    if m.playerIndex ~= 0 then return end

    if m.action == ACT_GLIDE then
        act_glide(m)
    else
        check_glide_start(m)
    end
end

hook_event(HOOK_MARIO_UPDATE, glide_hook)
