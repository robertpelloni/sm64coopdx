-- Mock SM64 environment
_G.gMarioStates = {}
_G.gNetworkPlayers = {}
_G.gPlayerSyncTable = {}

for i = 0, 15 do
    _G.gMarioStates[i] = {
        playerIndex = i,
        action = 0,
        marioObj = { oIntangibleTimer = 0, header = { gfx = { node = { flags = 1 }, cameraToObject = {} } } },
        pos = {x=0, y=0, z=0},
        marioBodyState = { action = 1 }
    }
    _G.gNetworkPlayers[i] = { connected = false }
    _G.gPlayerSyncTable[i] = { instanceID = 0 }
end

_G.gNetworkPlayers[0].connected = true
_G.gNetworkPlayers[1].connected = true

_G.MAX_PLAYERS = 16
_G.ACT_FLAG_ACTIVE = 1

-- Mock hooks and functions
local hooks = {}
_G.hook_event = function(h, f) table.insert(hooks, {hook=h, func=f}) end
_G.hook_chat_command = function() end
_G.hook_behavior = function() return 999 end
_G.djui_chat_message_create = function(m) print("Chat: " .. m) end
_G.play_sound = function() end
_G.SOUND_MENU_CLICK_FILE_SELECT = 1
_G.smlua_model_util_get_id = function() return 1 end
_G.cur_obj_scale = function() end
_G.obj_set_hitbox = function() end
_G.network_init_object = function() end
_G.network_is_server = function() return true end

_G.HOOK_MARIO_UPDATE = 1

-- Load modules
dofile("mods/system_instancing/main.lua")
dofile("mods/content_raid_boss/main.lua")

print("Testing Instancing Isolation...")

-- Default: Both in Instance 0
for _, h in ipairs(hooks) do
    if h.hook == _G.HOOK_MARIO_UPDATE and h.func == instancing_render_toggle then
        h.func()
    end
end
assert((_G.gMarioStates[1].marioObj.header.gfx.node.flags & 1) ~= 0, "Player 1 should be visible")
assert(_G.gMarioStates[1].marioObj.oIntangibleTimer == 0, "Player 1 should be tangible")

-- Move Local Player (0) to Instance 1
on_instance("1")
for _, h in ipairs(hooks) do
    if h.hook == _G.HOOK_MARIO_UPDATE and h.func == instancing_render_toggle then
        h.func()
    end
end
assert((_G.gMarioStates[1].marioObj.header.gfx.node.flags & 1) == 0, "Player 1 should be hidden")
assert(_G.gMarioStates[1].marioObj.oIntangibleTimer == -1, "Player 1 should be intangible")

-- Move Player 1 to Instance 1
_G.gPlayerSyncTable[1].instanceID = 1
for _, h in ipairs(hooks) do
    if h.hook == _G.HOOK_MARIO_UPDATE and h.func == instancing_render_toggle then
        h.func()
    end
end
assert((_G.gMarioStates[1].marioObj.header.gfx.node.flags & 1) ~= 0, "Player 1 should be visible again")
assert(_G.gMarioStates[1].marioObj.oIntangibleTimer == 0, "Player 1 should be tangible again")

print("Instancing tests passed.")
