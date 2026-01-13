-- name: Mechanic - Vehicle (Zoomer)
-- description: Hover bike mechanic (Jak & Daxter style).

local ACT_VEHICLE = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR) -- Airborne for smooth physics

local HOVER_HEIGHT = 50.0
local HOVER_SPRING = 5.0
local HOVER_DAMP = 0.5
local MAX_SPEED = 70.0
local ACCEL = 2.0

function act_vehicle(m)
    -- 1. Visuals
    set_mario_animation(m, MARIO_ANIM_SIT_IN_SPINNER) -- Sitting pose
    -- Attach shell model if not present?
    -- Ideally we'd have a separate object, but let's assume Mario IS the vehicle or riding one.
    -- Simple: Spawn a shell at Mario's pos visually

    -- 2. Input / Steering
    local intendedYaw = m.intendedYaw
    if m.input & INPUT_NONZERO_ANALOG ~= 0 then
        m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, intendedYaw, 0x500)
    end
    m.moveAngle.y = m.faceAngle.y

    -- Acceleration
    if (m.controller.buttonDown & A_BUTTON) ~= 0 then
        m.forwardVel = approach_f32(m.forwardVel, MAX_SPEED, ACCEL, ACCEL)
    else
        m.forwardVel = approach_f32(m.forwardVel, 0, 1.0, 1.0)
    end

    m.vel.x = sins(m.faceAngle.y) * m.forwardVel
    m.vel.z = coss(m.faceAngle.y) * m.forwardVel

    -- 3. Hover Physics
    local floorHeight = find_floor(m.pos.x, m.pos.y, m.pos.z)
    local desiredY = floorHeight + HOVER_HEIGHT

    local diff = desiredY - m.pos.y
    local force = diff * HOVER_SPRING - m.vel.y * HOVER_DAMP

    m.vel.y = m.vel.y + force

    -- Cap gravity effect
    if m.pos.y > floorHeight + 200 then
        m.vel.y = m.vel.y - 2.0 -- Gravity
    end

    -- 4. Movement
    m.pos.x = m.pos.x + m.vel.x
    m.pos.y = m.pos.y + m.vel.y
    m.pos.z = m.pos.z + m.vel.z

    -- Wall collision
    local step = resolve_and_return_wall_collisions(m.pos, 60.0, 50.0)
    if step > 0 then
        m.forwardVel = m.forwardVel * 0.8 -- Bonk slow down
    end

    -- 5. Exit
    if (m.controller.buttonPressed & Z_TRIG) ~= 0 then
        set_mario_action(m, ACT_JUMP_LAND, 0)
        return 1
    end

    return 0
end

hook_mario_action(ACT_VEHICLE, act_vehicle)

-- Spawn command
function on_vehicle(msg)
    local m = gMarioStates[0]
    set_mario_action(m, ACT_VEHICLE, 0)
    djui_chat_message_create("Vehicle mode activated!")
    return true
end

hook_chat_command("vehicle", "Enter vehicle mode", on_vehicle)
