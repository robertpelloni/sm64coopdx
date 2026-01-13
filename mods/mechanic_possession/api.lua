-- name: Mechanic - Entity Possession
-- description: Allows players to possess and control objects (Cappy style).

_G.Possession = {}
-- _G.Possession.inputs is deprecated in favor of reading from player sync table directly in loop

-- Constants
local ACT_POSSESSION = allocate_mario_action(ACT_GROUP_CUTSCENE | ACT_FLAG_IDLE | ACT_FLAG_INVULNERABLE)

function Possession.start(m, obj)
    if not obj then return false end

    local sTable = gPlayerSyncTable[m.playerIndex]

    -- Sync ID
    if obj.oSyncID ~= 0 then
        sTable.possessedSyncID = obj.oSyncID
    else
        -- Fallback for non-sync objects (Local only)
        -- We won't set syncID, so other players won't see it?
        -- They will see Mario idle.
    end

    -- Set Mario Action to custom Possession state
    set_mario_action(m, ACT_POSSESSION, 0)

    -- Hide Mario
    obj_set_model_extended(m.marioObj, MODEL_NONE)

    return true
end

function Possession.stop(m)
    local obj = _G.Possession.get_possessed(m.playerIndex)
    if obj then
        -- Teleport Mario to object's current position + offset
        m.pos.x = obj.oPosX
        m.pos.y = obj.oPosY + 100
        m.pos.z = obj.oPosZ
    end

    local sTable = gPlayerSyncTable[m.playerIndex]
    sTable.possessedSyncID = nil

    -- Restore Mario
    set_mario_action(m, ACT_IDLE, 0)
    obj_set_model_extended(m.marioObj, MODEL_MARIO) -- Restore model
    m.marioBodyState.modelState = 0

    return true
end

function Possession.get_possessed(playerIndex)
    local sTable = gPlayerSyncTable[playerIndex]
    if sTable.possessedSyncID then
        local obj = sync_object_get_object(sTable.possessedSyncID)
        return obj
    end
    return nil
end

function Possession.get_inputs(obj)
    -- Find which player possesses this object
    for i = 0, MAX_PLAYERS - 1 do
        local m = gMarioStates[i]
        -- Check if connected?
        local sTable = gPlayerSyncTable[i]
        if sTable and sTable.possessedSyncID == obj.oSyncID then
            -- This player controls this object
            -- Return their input
            -- Note: m.controller is synced automatically!
            return {
                stickX = m.controller.stickX,
                stickY = m.controller.stickY,
                buttonPressed = m.controller.buttonPressed,
                buttonDown = m.controller.buttonDown,
                camAngle = m.area.camera.yaw -- Camera might not be fully synced, but intendedYaw is.
            }
        end
    end
    return nil
end

_G.ACT_POSSESSION = ACT_POSSESSION
