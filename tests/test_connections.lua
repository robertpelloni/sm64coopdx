-- Unit tests for seamless connections
local failures = 0
local warped_level = nil
local warped_area = nil

_G.LEVEL_BOB = 9
_G.LEVEL_WF = 24
_G.LEVEL_CCM = 5

local mock_mario = {
    playerIndex = 0,
    pos = { x = 6000, y = 0, z = 6000 }
}

_G.gMarioStates = { [0] = mock_mario }
_G.gNetworkPlayers = { [0] = { currLevelNum = LEVEL_BOB, currAreaIndex = 1 } }
_G.djui_chat_message_create = function(msg) end
_G.warp_to_level = function(level, area, node)
    warped_level = level
    warped_area = area
end

local hooks = {}
_G.hook_event = function(eventType, func)
    hooks[eventType] = func
end

_G.HOOK_MARIO_UPDATE = 1
_G.HOOK_ON_LEVEL_INIT = 2

dofile("mods/system_waypoints/connections.lua")

-- Test 1: Moving into trigger zone from BOB to WF
hooks[HOOK_MARIO_UPDATE](mock_mario)

if warped_level ~= LEVEL_WF then
    print("FAIL: Mario should have warped to LEVEL_WF")
    failures = failures + 1
end

-- Test 2: Apply spawn post-warp
hooks[HOOK_ON_LEVEL_INIT](mock_mario)
if mock_mario.pos.x ~= -2500 or mock_mario.pos.z ~= -1000 then
    print("FAIL: Mario did not spawn at the correct WF entry coordinate")
    failures = failures + 1
end

if failures == 0 then
    print("All connection tests passed.")
else
    print("Tests failed: " .. failures)
end
