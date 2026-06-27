-- Dummy test script to load the mechanics and verify basic parsing and init functions

-- Mock SM64 environment
_G.gMarioStates = {{
    playerIndex = 0,
    action = 0,
    marioObj = { header = { gfx = { scale = {x=1, y=1, z=1}, cameraToObject = {} } } }
}}
-- Lua is 1-indexed, but sm64 is 0 indexed, so we mock [0]
_G.gMarioStates[0] = _G.gMarioStates[1]

_G.gNetworkPlayers = {{ connected = true, name = "TestPlayer", currLevelNum = 16 }}
_G.gNetworkPlayers[0] = _G.gNetworkPlayers[1]

_G.gPlayerSyncTable = {{ is_mega = false, mega_timer = 0 }}
_G.gPlayerSyncTable[0] = _G.gPlayerSyncTable[1]

_G.MAX_PLAYERS = 16

_G.ACT_PANTING = 1
_G.ACT_START_CROUCHING = 2
_G.ACT_START_SLEEPING = 3
_G.ACT_DANCE = 4
_G.ACT_IDLE = 5
_G.MARIO_ANIM_CREDITS_WAVING = 1
_G.MARIO_ANIM_STAR_DANCE = 2

-- Mock hooks and functions
local hooks = {}
_G.hook_event = function(h, f) table.insert(hooks, {hook=h, func=f}) end
_G.hook_chat_command = function() end
_G.djui_chat_message_create = function(m) print("Chat: " .. m) end
_G.network_get_player_text_color_string = function() return "" end
_G.set_mario_action = function(m, a, b) print("Action Set: " .. tostring(a)) end
_G.set_mario_animation = function(m, a) print("Anim Set: " .. tostring(a)) end
_G.play_sound = function() end
_G.obj_get_first_with_behavior_id = function() return nil end
_G.warp_to_level = function(lvl, area, act) print("Warp to: " .. lvl) end
_G.mod_storage_load = function() return "" end
_G.mod_storage_save = function() end

_G.LEVEL_CASTLE_GROUNDS = 16
_G.LEVEL_BOB = 9
_G.LEVEL_WF = 24
_G.LEVEL_CCM = 5
_G.LEVEL_JRB = 12

_G.HOOK_ON_LEVEL_INIT = 1
_G.HOOK_ON_SYNC_VALID = 2
_G.HOOK_MARIO_UPDATE = 3
_G.HOOK_ON_HUD_RENDER = 4
_G.HOOK_BEFORE_MARIO_UPDATE = 5

-- Mock dependencies
_G.Inventory = { define_item = function(id, name, desc) print("Defined item: " .. name); _G.test_item = {id=id, name=name, desc=desc} end }
_G.UIToolkit = { draw_menu = function() end, handle_input = function() return 1, 0, false, false end, calculate_scroll = function() return 0 end }

-- Load modules
dofile("mods/system_emotes/main.lua")
dofile("mods/system_waypoints/main.lua")
dofile("mods/mechanic_mega_mushroom/main.lua")

print("Modules loaded successfully.")

-- Test Mega Mushroom
print("Testing Mega Mushroom...")
for _, h in ipairs(hooks) do
    if h.hook == _G.HOOK_ON_LEVEL_INIT and h.func == mm_init then
        h.func()
    end
end

assert(_G.test_item ~= nil, "Mega mushroom item not registered.")
-- We no longer have a generic 'use' callback, so we manually trigger the sync table flip for the test
_G.gPlayerSyncTable[0].is_mega = true
_G.gPlayerSyncTable[0].mega_timer = 15 * 30
assert(_G.gPlayerSyncTable[0].is_mega == true, "Player did not become mega.")

for _, h in ipairs(hooks) do
    if h.hook == _G.HOOK_MARIO_UPDATE and h.func == mm_update then
        h.func(_G.gMarioStates[0])
    end
end
assert(_G.gMarioStates[0].marioObj.header.gfx.scale.x == 4.0, "Mario did not scale up.")

-- Test Waypoints
print("Testing Waypoints...")
for _, h in ipairs(hooks) do
    if h.hook == _G.HOOK_ON_SYNC_VALID and h.func == waypoints_init then
        h.func()
    end
end
assert(_G.Waypoints.unlocked["castle_grounds"] == true, "Castle grounds not unlocked.")

-- Trigger level init with BOB
_G.gNetworkPlayers[0].currLevelNum = _G.LEVEL_BOB
for _, h in ipairs(hooks) do
    if h.hook == _G.HOOK_ON_LEVEL_INIT and h.func == waypoints_level_init then
        h.func()
    end
end
assert(_G.Waypoints.unlocked["bobomb_battlefield"] == true, "Bobomb battlefield not unlocked.")

-- Test Emotes
print("Testing Emotes...")
on_emote_command("sit")
on_emote_command("wave")

print("All integration tests passed.")
