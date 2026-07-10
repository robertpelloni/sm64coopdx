-- Unit tests for Party and Trading integration
local failures = 0

_G.gMarioStates = {
    [0] = { playerIndex = 0, numCoins = 100 },
    [1] = { playerIndex = 1, numCoins = 50 }
}

_G.gNetworkPlayers = {
    [0] = { connected = true, name = "P1" },
    [1] = { connected = true, name = "P2" }
}

_G.gPlayerSyncTable = {
    [0] = {},
    [1] = {}
}

_G.djui_chat_message_create = function(msg) end
_G.hook_event = function() end
_G.hook_chat_command = function() end
_G.network_send_to = function() end
_G.network_send = function() end
_G.network_register_packet = function() end
_G.get_network_player_from_local_index = function(i) return _G.gNetworkPlayers[i] end
_G.get_network_player_from_global_index = function(i) return _G.gNetworkPlayers[i] end

_G.Inventory = {
    items = {},
    get_item_count = function(m, id) return 5 end,
    remove_item = function(m, id, count) end,
    add_item = function(m, id, count) end,
    get_all_items = function(m) return '{"wood":5}' end
}

dofile("mods/system_party/main.lua")
dofile("mods/system_party/ui.lua")
dofile("mods/system_trading/main.lua")
dofile("mods/system_trading/ui.lua")
dofile("mods/system_trading/api.lua")

print("Party/Trading integration initialized without syntax errors.")
