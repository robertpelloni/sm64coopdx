-- name: Mechanic - Transformations
-- description: Transformation system (Banjo-Kazooie style).

_G.Transformation = {}
_G.Transformation.defs = {}

-- Constants
local ACT_TRANSFORMATION = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)

function Transformation.register(id, data)
    _G.Transformation.defs[id] = data
end

function Transformation.set(m, id)
    local sTable = gPlayerSyncTable[m.playerIndex]

    if not _G.Transformation.defs[id] then return false end

    sTable.transID = id
    set_mario_action(m, ACT_TRANSFORMATION, 0)

    -- Apply initial props
    -- Model
    local modelId = _G.Transformation.defs[id].modelId
    if modelId then
        obj_set_model_extended(m.marioObj, modelId)
    end

    -- Hitbox?
    -- changing m.marioObj.hitboxRadius implies we must restore it later.

    djui_chat_message_create("Transformed into " .. id)
    return true
end

function Transformation.clear(m)
    local sTable = gPlayerSyncTable[m.playerIndex]
    sTable.transID = nil

    set_mario_action(m, ACT_IDLE, 0)
    obj_set_model_extended(m.marioObj, MODEL_MARIO)
    -- Restore hitbox defaults (handled by engine on action change usually? or standard update)
    return true
end

function Transformation.get_current(m)
    local sTable = gPlayerSyncTable[m.playerIndex]
    return sTable.transID
end

function Transformation.get_def(id)
    return _G.Transformation.defs[id]
end

_G.ACT_TRANSFORMATION = ACT_TRANSFORMATION
