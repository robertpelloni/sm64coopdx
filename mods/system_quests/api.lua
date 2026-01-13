-- name: System - Quests
-- description: Quest management system for MMORPG progression.

_G.Quest = {}
_G.Quest.defs = {}

-- Status Enum
local STATUS_NOT_STARTED = 0
local STATUS_ACTIVE = 1
local STATUS_COMPLETE = 2

function Quest.register(id, data)
    _G.Quest.defs[id] = data
end

-- Helper: Get sync table key
local function get_q_key(id) return "q_" .. id end
local function get_p_key(id) return "qp_" .. id end -- Progress

function Quest.start(m, id)
    local def = _G.Quest.defs[id]
    if not def then return false end

    local sTable = gPlayerSyncTable[m.playerIndex]
    if sTable[get_q_key(id)] == STATUS_COMPLETE then return false end -- Already done

    sTable[get_q_key(id)] = STATUS_ACTIVE
    sTable[get_p_key(id)] = 0

    djui_chat_message_create("Quest Started: " .. def.name)
    return true
end

function Quest.update_progress(m, questId, amount)
    local sTable = gPlayerSyncTable[m.playerIndex]

    if sTable[get_q_key(questId)] ~= STATUS_ACTIVE then return end

    local current = sTable[get_p_key(questId)] or 0
    local def = _G.Quest.defs[questId]

    current = current + amount
    sTable[get_p_key(questId)] = current

    if current >= def.target then
        Quest.complete(m, questId)
    end
end

function Quest.complete(m, questId)
    local sTable = gPlayerSyncTable[m.playerIndex]
    local def = _G.Quest.defs[questId]

    sTable[get_q_key(questId)] = STATUS_COMPLETE
    djui_chat_message_create("Quest Complete: " .. def.name)

    -- Rewards
    if def.reward and _G.Inventory then
        if def.reward.item then
            Inventory.add_item(m, def.reward.item, def.reward.amount)
            djui_chat_message_create("Received " .. def.reward.amount .. " " .. def.reward.item)
        end
    end
end

-- Persistence
function Quest.save()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]
    local str = ""

    for id, _ in pairs(_G.Quest.defs) do
        local status = sTable[get_q_key(id)] or 0
        local progress = sTable[get_p_key(id)] or 0
        if status ~= 0 then
            str = str .. id .. ":" .. status .. ":" .. progress .. ";"
        end
    end

    mod_storage_save("quest_data", str)
end

function Quest.load()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]
    local str = mod_storage_load("quest_data")
    if not str then return end

    for chunk in string.gmatch(str, "([^;]+)") do
        local id, status, progress = string.match(chunk, "([^:]+):(%d+):(%d+)")
        if id then
            sTable[get_q_key(id)] = tonumber(status)
            sTable[get_p_key(id)] = tonumber(progress)
        end
    end
end

-- Getters for UI
function Quest.get_active(m)
    local sTable = gPlayerSyncTable[m.playerIndex]
    local active = {}
    for id, def in pairs(_G.Quest.defs) do
        if sTable[get_q_key(id)] == STATUS_ACTIVE then
            table.insert(active, {
                id = id,
                def = def,
                progress = sTable[get_p_key(id)] or 0
            })
        end
    end
    return active
end
