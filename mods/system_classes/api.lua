-- name: System - Classes
-- description: RPG Class system with unique active abilities.

_G.Class = {}
_G.Class.defs = {}

-- Sync Keys: "classID"

function Class.register(id, data)
    _G.Class.defs[id] = data
end

function Class.set(m, id)
    local sTable = gPlayerSyncTable[m.playerIndex]

    if id and not _G.Class.defs[id] then
        djui_chat_message_create("Invalid Class: " .. id)
        return false
    end

    sTable.classID = id

    if id then
        local def = _G.Class.defs[id]
        djui_chat_message_create("Class set to: " .. def.name)
        play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject)
    else
        djui_chat_message_create("Class cleared.")
    end

    return true
end

function Class.get(m)
    local sTable = gPlayerSyncTable[m.playerIndex]
    return sTable.classID
end

function Class.get_def(id)
    return _G.Class.defs[id]
end
