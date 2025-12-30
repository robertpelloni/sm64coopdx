-- name: Content - Dungeon (Crypt of the Vanished)
-- description: Instanced dungeon encounter.

local DUNGEON_LEVEL = LEVEL_BBH -- Reusing BBH for now
local DUNGEON_AREA = 1

-- Number of Boos required to unlock Room 2
local ROOM_1_BOO_COUNT = 5

-- Instance Data: Keyed by instanceID
local DungeonState = {}

function dungeon_init_instance(id)
    if not DungeonState[id] then
        DungeonState[id] = {
            kills = 0
        }
    end
end

-- Sync Object: Tracks state for the instance
local E_MODEL_DM = smlua_model_util_get_id("star_geo") -- Invisible controller

function bhv_dungeon_master_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oOpacity = 0 -- Invisible
    o.oBehParams = 0 -- Kills
    o.oBehParams2ndByte = 0 -- State
    network_init_object(o, true, {"oBehParams", "oBehParams2ndByte"})
end

function bhv_dungeon_master_loop(o)
    -- Client side effects
    if o.oBehParams >= ROOM_1_BOO_COUNT and o.oBehParams2ndByte == 0 then
        o.oBehParams2ndByte = 1 -- Room 2 unlock
        djui_chat_message_create("Room 1 Cleared! The path opens...")
        play_puzzle_jingle()
    end
end

local id_bhvDungeonMaster = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_dungeon_master_init, bhv_dungeon_master_loop)

-- Helper to count boos
function count_remaining_boos()
    local count = 0
    local obj = obj_get_first(OBJ_LIST_GENACTOR)
    while obj do
        if obj.behavior == get_behavior_from_id(id_bhvGhostHuntBoo) then
            -- Check if alive?
            -- Standard Boos deactivate or unload when dead.
            -- Or they might enter a "dying" state.
            if obj.activeFlags ~= 0 then
                count = count + 1
            end
        end
        obj = obj_get_next(obj)
    end
    return count
end

function dungeon_update(m)
    -- Only run logic if we are in the dungeon
    if gNetworkPlayers[m.playerIndex].currLevelNum ~= DUNGEON_LEVEL then return end
    if m.playerIndex ~= 0 then return end -- Local authority checks logic, but Server (or Host) updates Master Object

    -- We need to find the DM object
    local dmObj = nil
    local obj = obj_get_first(OBJ_LIST_GENACTOR)
    while obj do
        if obj.behavior == id_bhvDungeonMaster then
            dmObj = obj
            break
        end
        obj = obj_get_next(obj)
    end

    if not dmObj then return end

    -- Only the level owner (or server?) should update the DM state?
    -- network_init_object uses `network_send_object` to sync.
    -- If `network_is_server()` or if we are the "dungeon owner".
    -- For pilot, let's assume Host/Server drives the dungeon state.

    if network_is_server() then
        if dmObj.oBehParams2ndByte == 0 then -- Room 1 active
            -- Count how many boos are left in the level
            -- We assume we started with 5.
            -- If count < 5, we have kills.
            -- Actually, we can just set `kills = 5 - current`.

            local currentBoos = count_remaining_boos()
            local kills = ROOM_1_BOO_COUNT - currentBoos

            if kills > dmObj.oBehParams then
                dmObj.oBehParams = kills
                -- Optional: Feedback "Kill 1/5"
            end
        end
    end
end

hook_event(HOOK_MARIO_UPDATE, dungeon_update)

-- Entrance Command
function on_dungeon_enter(msg)
    local m = gMarioStates[0]
    local inst = math.random(1000, 9999)
    local sTable = gPlayerSyncTable[0]
    sTable.instanceID = inst

    if initiate_warp then
        initiate_warp(DUNGEON_LEVEL, DUNGEON_AREA, 1, 0)
    end

    _G.PENDING_DUNGEON_SPAWN = true
    djui_chat_message_create("Entering Crypt of the Vanished...")
    return true
end

hook_chat_command("dungeon", "Enter dungeon", on_dungeon_enter)

function dungeon_level_init()
    if _G.PENDING_DUNGEON_SPAWN then
        -- We spawn the DM object
        -- IMPORTANT: If we are client, we rely on the server to sync it?
        -- No, in `sm64coopdx` synced objects spawned by client usually sync to others if `network_init_object` is called.
        -- But for a dungeon, we want it local-ish or synced to party?
        -- For pilot, we spawn it.

        spawn_sync_object(
            id_bhvDungeonMaster,
            E_MODEL_DM,
            0, 0, 0,
            nil
        )
        _G.PENDING_DUNGEON_SPAWN = false
    end
end

hook_event(HOOK_ON_LEVEL_INIT, dungeon_level_init)
