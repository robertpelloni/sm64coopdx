-- name: Mechanic - Mounts
-- description: Rideable creatures for fast travel.

_G.Mounts = {}

local ACT_MOUNTED = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING)

-- Mount Definitions
local MOUNT_DEFS = {
    ["mount_yoshi"] = {
        model = E_MODEL_YOSHI,
        speed = 60.0,
        jump = 50.0,
        scale = 1.0,
        sound = SOUND_GENERAL_YOSHI_WALK
    },
    ["mount_dorrie"] = {
        model = E_MODEL_SUSHI, -- Dorrie/Sushi
        speed = 40.0,
        jump = 30.0,
        scale = 0.5,
        sound = SOUND_OBJ_BABY_PENGUIN_WALK
    }
}

function act_mounted(m)
    local sTable = gPlayerSyncTable[m.playerIndex]
    local mountId = sTable.currentMount

    if not mountId or not MOUNT_DEFS[mountId] then
        set_mario_action(m, ACT_IDLE, 0)
        return 1
    end

    local def = MOUNT_DEFS[mountId]

    -- Visuals: Hide Mario's bottom half or just ride animation
    set_mario_animation(m, MARIO_ANIM_RIDING_HOOT)

    -- We need a visual representation of the mount.
    -- For multiplayer sync, `m.marioObj` can't easily have a sub-object attached without custom logic.
    -- We will spawn a non-sync object locally per frame or manage a persistent one.
    -- Managing persistent object per player is complex.
    -- Let's just override Mario's model for the prototype, or spawn a local visual object.

    -- Input & Physics
    local intendedYaw = m.intendedYaw
    local intendedMag = m.intendedMag

    if intendedMag > 0 then
        m.forwardVel = approach_f32(m.forwardVel, def.speed, 2.0, 2.0)
        m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, intendedYaw, 0x800)
        m.moveAngle.y = m.faceAngle.y

        -- Sound
        if m.actionTimer % 10 == 0 then
            play_sound(def.sound, m.marioObj.header.gfx.cameraToObject)
        end
    else
        m.forwardVel = approach_f32(m.forwardVel, 0, 4.0, 4.0)
    end

    m.vel.x = sins(m.faceAngle.y) * m.forwardVel
    m.vel.z = coss(m.faceAngle.y) * m.forwardVel

    -- Ground Step
    local step = perform_ground_step(m)

    if step == GROUND_STEP_LEFT_GROUND then
        set_mario_action(m, ACT_FREEFALL, 0)
        -- Mount un-equips on fall for safety in this prototype
        sTable.currentMount = nil
        return 1
    elseif step == GROUND_STEP_HIT_WALL then
        m.forwardVel = 0
    end

    -- Jump
    if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
        m.vel.y = def.jump
        set_mario_action(m, ACT_JUMP, 0)
        sTable.currentMount = nil -- Dismount on jump
        return 1
    end

    -- Dismount
    if (m.controller.buttonPressed & Z_TRIG) ~= 0 then
        sTable.currentMount = nil
        set_mario_action(m, ACT_IDLE, 0)
        return 1
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end

hook_mario_action(ACT_MOUNTED, act_mounted)

-- Visuals: Draw Mount Object
-- Since Mario actions don't allow easily swapping models without breaking other things,
-- we'll hook rendering to draw the mount at Mario's feet.
function mount_render(o)
    -- This would normally be done in HOOK_ON_OBJECT_RENDER or similar, but
    -- standard smlua doesn't have a direct "draw model" API without spawning objects.
    -- We will spawn a temporary object and move it, or just rely on Mario's animation.
    -- For now, let's just stick to the Riding Hoot animation for simplicity,
    -- as syncing attached models requires complex object management.
end

-- Command
hook_chat_command("mount", "Summon a mount", function(msg)
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[0]

    if msg == "dismiss" then
        sTable.currentMount = nil
        if m.action == ACT_MOUNTED then set_mario_action(m, ACT_IDLE, 0) end
        return true
    end

    local target = "mount_" .. msg
    if MOUNT_DEFS[target] then
        -- Check inventory
        if _G.Inventory and Inventory.get_count(m, target) > 0 then
            sTable.currentMount = target
            set_mario_action(m, ACT_MOUNTED, 0)
            djui_chat_message_create("Mounted " .. msg)
        else
            djui_chat_message_create("You do not own this mount.")
        end
    else
        djui_chat_message_create("Mounts: yoshi, dorrie")
    end
    return true
end)
