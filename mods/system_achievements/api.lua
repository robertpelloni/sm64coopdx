-- name: System - Achievements & Titles
-- description: Achievements that unlock player titles.

_G.Achievement = {}
_G.Achievement.defs = {}
_G.Achievement.active_title = {} -- Local cache for overhead render? Sync via sTable.

function Achievement.register(id, data)
    _G.Achievement.defs[id] = data
end

-- Sync Keys: "ach_ID" = bool, "title" = string

function Achievement.unlock(m, id)
    local sTable = gPlayerSyncTable[m.playerIndex]
    local key = "ach_" .. id

    if not sTable[key] then
        sTable[key] = true
        local def = _G.Achievement.defs[id]
        if def then
            djui_chat_message_create("Achievement Unlocked: " .. def.name)
            play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject)

            if def.title then
                djui_chat_message_create("New Title Available: " .. def.title)
            end
        end
        Achievement.save()
    end
end

function Achievement.has(m, id)
    local sTable = gPlayerSyncTable[m.playerIndex]
    return sTable["ach_" .. id]
end

function Achievement.set_title(m, titleId)
    -- Check if player has achievement for this title
    local valid = false
    if titleId == "None" then
        valid = true
    else
        for id, def in pairs(_G.Achievement.defs) do
            if def.title == titleId and Achievement.has(m, id) then
                valid = true
                break
            end
        end
    end

    if valid then
        local sTable = gPlayerSyncTable[m.playerIndex]
        sTable.currentTitle = (titleId ~= "None") and titleId or nil
        return true
    end
    return false
end

function Achievement.save()
    if gMarioStates[0].playerIndex ~= 0 then return end

    local sTable = gPlayerSyncTable[0]
    local str = ""

    -- Save unlocked achievements
    for id, _ in pairs(_G.Achievement.defs) do
        if sTable["ach_" .. id] then
            str = str .. id .. ";"
        end
    end

    -- Save current title
    if sTable.currentTitle then
        str = str .. "|title=" .. sTable.currentTitle
    end

    mod_storage_save("achievements", str)
end

function Achievement.load()
    if gMarioStates[0].playerIndex ~= 0 then return end

    local str = mod_storage_load("achievements")
    if not str then return end

    local sTable = gPlayerSyncTable[0]

    -- Split achievements vs title
    local achPart = str
    local titlePart = nil

    local pipePos = string.find(str, "|")
    if pipePos then
        achPart = string.sub(str, 1, pipePos - 1)
        titlePart = string.sub(str, pipePos + 1)
    end

    for id in string.gmatch(achPart, "([^;]+)") do
        if _G.Achievement.defs[id] then
            sTable["ach_" .. id] = true
        end
    end

    if titlePart then
        local t = string.match(titlePart, "title=(.+)")
        if t then sTable.currentTitle = t end
    end
end
