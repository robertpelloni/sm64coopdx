-- name: Mechanic - Sonic Boost
-- description: High speed boost mechanic with meter management.

local ACT_BOOST = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)

local BOOST_SPEED = 80.0
local BOOST_DRAIN_RATE = 1.0 -- Per frame
local BOOST_REGEN_RATE = 0.2 -- Per frame
local BOOST_MAX = 100.0

function act_boost(m)
    local sTable = gPlayerSyncTable[m.playerIndex]

    -- Init Meter if missing
    if not sTable.boostMeter then sTable.boostMeter = BOOST_MAX end

    -- 1. Check Meter
    if sTable.boostMeter <= 0 then
        set_mario_action(m, ACT_WALKING, 0)
        return 1
    end

    -- 2. Drain
    -- Only local player drains their own meter to avoid desync fighting
    if m.playerIndex == 0 then
        sTable.boostMeter = sTable.boostMeter - BOOST_DRAIN_RATE
        if sTable.boostMeter < 0 then sTable.boostMeter = 0 end
    end

    -- 3. Physics
    -- Force high speed
    m.forwardVel = BOOST_SPEED
    m.vel.x = sins(m.faceAngle.y) * m.forwardVel
    m.vel.z = coss(m.faceAngle.y) * m.forwardVel

    -- Steering (Stiffer than walking)
    local intendedYaw = m.intendedYaw
    m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, intendedYaw, 0x400)
    m.moveAngle.y = m.faceAngle.y

    -- 4. Visuals
    set_mario_animation(m, MARIO_ANIM_RUNNING)
    m.marioBodyState.handState = MARIO_HAND_OPEN

    -- Particles
    if gGlobalTimer % 3 == 0 then
        spawn_non_sync_object(
            id_bhvSparkleSpawn,
            E_MODEL_SPARKLES,
            m.pos.x, m.pos.y + 10, m.pos.z,
            nil
        )
    end

    -- Sound
    if gGlobalTimer % 10 == 0 then
        play_sound(SOUND_AIR_PEACH_TWINKLE, m.marioObj.header.gfx.cameraToObject)
    end

    -- 5. Collision
    local step = perform_ground_step(m)
    if step == GROUND_STEP_LEFT_GROUND then
        set_mario_action(m, ACT_FREEFALL, 0)
        return 1
    elseif step == GROUND_STEP_HIT_WALL then
        play_sound(SOUND_ACTION_BONK, m.marioObj.header.gfx.cameraToObject)
        set_mario_action(m, ACT_BACKWARD_GROUND_KB, 0)
        return 1
    end

    -- 6. Exit Condition (Release Button)
    if (m.controller.buttonDown & X_BUTTON) == 0 then
        set_mario_action(m, ACT_WALKING, 0)
        return 1
    end

    return 0
end

function boost_update(m)
    if m.playerIndex ~= 0 then return end -- Local Logic Only

    local sTable = gPlayerSyncTable[m.playerIndex]

    -- Init Meter
    if not sTable.boostMeter then sTable.boostMeter = BOOST_MAX end

    -- Passive Regen (Local Only)
    if m.action ~= ACT_BOOST then
        sTable.boostMeter = sTable.boostMeter + BOOST_REGEN_RATE
        if sTable.boostMeter > BOOST_MAX then sTable.boostMeter = BOOST_MAX end
    end

    -- Trigger
    -- Must be moving on ground
    if (m.action & ACT_FLAG_MOVING) ~= 0 and (m.action & ACT_FLAG_AIR) == 0 then
        if (m.controller.buttonPressed & X_BUTTON) ~= 0 and sTable.boostMeter > 10 then
            set_mario_action(m, ACT_BOOST, 0)
        end
    end
end

function boost_hud()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    if not sTable.boostMeter then return end

    -- Draw Meter
    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()

    local barW = 100
    local barH = 10
    local x = w - barW - 20
    local y = h - 40

    -- Background
    djui_hud_set_color(0, 0, 0, 150)
    djui_hud_render_rect(x, y, barW, barH)

    -- Fill
    local fill = (sTable.boostMeter / BOOST_MAX) * barW
    djui_hud_set_color(0, 100, 255, 200) -- Blue
    djui_hud_render_rect(x, y, fill, barH)

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Boost", x, y - 20, 1)
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, boost_update)
hook_event(HOOK_ON_HUD_RENDER, boost_hud)
hook_mario_action(ACT_BOOST, act_boost)
