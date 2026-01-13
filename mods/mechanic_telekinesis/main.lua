-- name: Mechanic - Telekinesis
-- description: Grab and throw distant objects (Psychonauts style).

local ACT_TELEKINESIS = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING) -- Allow movement while holding? Or stationary?
-- Psychonauts allows walking. Let's try allowing movement.

local RANGE = 1500
local HOLD_DIST = 200

function act_telekinesis(m)
    local sTable = gPlayerSyncTable[m.playerIndex]

    -- Check held object
    if not sTable.tkObjID then
        set_mario_action(m, ACT_IDLE, 0)
        return 1
    end

    local obj = sync_object_get_object(sTable.tkObjID)
    if not obj then
        set_mario_action(m, ACT_IDLE, 0)
        return 1
    end

    -- 1. Physics (Mario)
    -- Allow walking slowly?
    -- For simplicity, standard walk logic but keep action
    local step = perform_ground_step(m)
    -- update animations...
    set_mario_animation(m, MARIO_ANIM_RUNNING) -- Holding hand out?

    -- 2. Object Physics
    -- Float in front of Mario
    local targetX = m.pos.x + sins(m.faceAngle.y) * HOLD_DIST
    local targetY = m.pos.y + 100
    local targetZ = m.pos.z + coss(m.faceAngle.y) * HOLD_DIST

    -- Smooth lerp
    obj.oPosX = approach_f32(obj.oPosX, targetX, 20.0, 20.0)
    obj.oPosY = approach_f32(obj.oPosY, targetY, 20.0, 20.0)
    obj.oPosZ = approach_f32(obj.oPosZ, targetZ, 20.0, 20.0)

    obj.oVelX = 0
    obj.oVelY = 0
    obj.oVelZ = 0

    -- 3. Throw
    if (m.controller.buttonPressed & R_TRIG) == 0 then -- Released
        -- Launch
        local speed = 60.0
        obj.oVelX = sins(m.faceAngle.y) * speed
        obj.oVelZ = coss(m.faceAngle.y) * speed
        obj.oVelY = 20.0
        obj.oForwardVel = speed

        sTable.tkObjID = nil
        set_mario_action(m, ACT_IDLE, 0)
        return 1
    end

    return 0
end

function tk_update(m)
    if m.playerIndex ~= 0 then return end

    -- Activate on R Trigger
    if (m.controller.buttonPressed & R_TRIG) ~= 0 then
        -- Raycast
        -- Similar to Hookshot logic
        local startPos = {x = m.pos.x, y = m.pos.y + 100, z = m.pos.z}
        -- ... direction calc ...
        -- Simplified: Check objects in front

        local minK = -1
        local target = nil

        -- Iterate nearby objects?
        -- smlua doesn't have a fast "get objects in cone".
        -- We will scan objects with specific interaction types or all sync objects.
        -- For optimization, only checking objects near Mario is handled by engine lists usually.
        -- Let's use `obj_get_first` loop pattern.

        local obj = obj_get_first(OBJ_LIST_GENACTOR) -- Only generic actors for now
        while obj do
            if dist_between_objects(m.marioObj, obj) < RANGE then
                -- Check angle
                local angleToObj = obj_angle_to_object(m.marioObj, obj)
                local diff = abs_angle_diff(m.faceAngle.y, angleToObj)
                if diff < 0x2000 then -- 45 degrees
                    target = obj
                    break -- Take first one
                end
            end
            obj = obj_get_next(obj)
        end

        if target then
            -- Start TK
            -- Must be sync object?
            if target.oSyncID ~= 0 then
                local sTable = gPlayerSyncTable[m.playerIndex]
                sTable.tkObjID = target.oSyncID
                set_mario_action(m, ACT_TELEKINESIS, 0)
                djui_chat_message_create("Grabbed!")
            else
                djui_chat_message_create("Object not synced, cannot grab.")
            end
        end
    end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, tk_update)
hook_mario_action(ACT_TELEKINESIS, act_telekinesis)
