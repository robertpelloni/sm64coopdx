-- name: Mechanic - Entity Possession
-- description: Allows players to possess and control objects (Cappy style).

_G.Possession = {}
_G.Possession.inputs = {} -- Map of obj -> input data

-- Constants
local ACT_POSSESSION = allocate_mario_action(ACT_GROUP_CUTSCENE | ACT_FLAG_IDLE | ACT_FLAG_INVULNERABLE)

function Possession.start(m, obj)
    if not obj then return false end

    local sTable = gPlayerSyncTable[m.playerIndex]

    -- Set sync state
    -- We store the object's sync ID if possible, but Lua objects might not have one easily accessible globally if not synced.
    -- For local logic, we store the object pointer in a local map.
    -- For networking, we would need the SyncID.
    -- Limitation: For this Phase 1, we focus on Local Control + Visual Sync.
    -- Assuming 'obj' is a SyncObject or standard object.

    _G.Possession.set_possessed_obj(m.playerIndex, obj)

    -- Set Mario Action to custom Possession state
    set_mario_action(m, ACT_POSSESSION, 0)

    -- Hide Mario
    -- We can use model state
    m.marioBodyState.modelState = MODEL_STATE_NOISE_ALPHA -- Invisible-ish or custom
    -- Better: Set a flag to skip rendering in a hook?
    -- Actually, ACT_GROUP_CUTSCENE + changing model to MODEL_NONE is safest.
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

    _G.Possession.clear_possessed_obj(m.playerIndex)

    -- Restore Mario
    set_mario_action(m, ACT_IDLE, 0)
    obj_set_model_extended(m.marioObj, MODEL_MARIO) -- Restore model
    m.marioBodyState.modelState = 0

    return true
end

-- Internal State Management
-- We use a local table because object pointers can't be easily synced via SyncTable integers directly without the SyncID system.
-- For local player, it's fine.
local gPossessedObjects = {}

function Possession.set_possessed_obj(playerIndex, obj)
    gPossessedObjects[playerIndex] = obj
end

function Possession.get_possessed(playerIndex)
    return gPossessedObjects[playerIndex]
end

function Possession.clear_possessed_obj(playerIndex)
    gPossessedObjects[playerIndex] = nil
end

function Possession.get_inputs(obj)
    return _G.Possession.inputs[obj]
end

_G.ACT_POSSESSION = ACT_POSSESSION
