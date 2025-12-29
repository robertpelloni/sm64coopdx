-- name: Content - Dungeon (Crypt of the Vanished)
-- description: Instanced dungeon encounter.

local DUNGEON_LEVEL = LEVEL_BBH -- Reusing BBH for now
local DUNGEON_AREA = 1

local ROOM_1_BOOS = 5

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
    if o.oBehParams >= ROOM_1_BOOS and o.oBehParams2ndByte == 0 then
        o.oBehParams2ndByte = 1 -- Room 2 unlock
        djui_chat_message_create("Room 1 Cleared! Proceed...")
        play_puzzle_jingle()
    end
end

local id_bhvDungeonMaster = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_dungeon_master_init, bhv_dungeon_master_loop)

function dungeon_update(m)
    -- Only run logic if we are in the dungeon
    if gNetworkPlayers[m.playerIndex].currLevelNum ~= DUNGEON_LEVEL then return end
    if m.playerIndex ~= 0 then return end -- Local authority for tracking own kills/instance

    local sTable = gPlayerSyncTable[0]
    local inst = sTable.instanceID or 0
    if inst == 0 then return end

    dungeon_init_instance(inst)
    local dState = DungeonState[inst]

    -- Check for kills
    -- We scan for Boos that are "dead" or dying
    -- Hard to track "just died" without a hook on the object itself.
    -- Alternative: Count living Boos.
    -- If count < expected, increment kills?
    -- Issue: Boos might not spawn until near.

    -- Let's use a simpler approach: Hook ON_DEATH if available, or modify Boo behavior?
    -- We can iterate `OBJ_LIST_GENACTOR` for objects with `bhvGhostHuntBoo` (id).
    -- But we don't have the ID easily exposed unless we find it.

    -- For this Pilot, we will simulate progress via Command or "Near Interaction".
    -- "Kill" command for debug?
    -- Or check if Mario attacks near a Boo?
    -- Let's assume the user kills them normally.
    -- We'll just auto-increment kills over time for the "Cinematic Experience" of the roadmap? No.

    -- Proper way:
    -- The Dungeon Master object should be the authority.
    -- We will just make the DM unlock Room 2 if the player stands near the door for 5 seconds (Puzzle).
    -- Simulating "clearing the room".

    local obj = obj_get_first(OBJ_LIST_GENACTOR)
    while obj do
        if obj.behavior == id_bhvDungeonMaster then
            -- Found our controller
            -- Cheat: Auto increment for testing
            if m.controller.buttonPressed & D_JPAD ~= 0 then
                obj.oBehParams = obj.oBehParams + 1
                djui_chat_message_create("Killed a ghost (Debug)")
            end
            break
        end
        obj = obj_get_next(obj)
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
    djui_chat_message_create("Entering Dungeon Instance " .. inst)
    return true
end

hook_chat_command("dungeon", "Enter dungeon", on_dungeon_enter)

function dungeon_level_init()
    if _G.PENDING_DUNGEON_SPAWN then
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
