-- Mock SM64 environment
_G.gMarioStates = {{
    playerIndex = 0,
    action = 0,
    marioObj = { header = { gfx = { scale = {x=1, y=1, z=1}, cameraToObject = {} } } },
    numCoins = 0
}}
_G.gMarioStates[0] = _G.gMarioStates[1]

_G.gNetworkPlayers = {{ connected = true, name = "TestPlayer", currLevelNum = 16 }}
_G.gNetworkPlayers[0] = _G.gNetworkPlayers[1]

_G.gPlayerSyncTable = {{ }}
_G.gPlayerSyncTable[0] = _G.gPlayerSyncTable[1]

_G.MAX_PLAYERS = 16

-- Mock hooks and functions
local hooks = {}
local chat_commands = {}
_G.hook_event = function(h, f) table.insert(hooks, {hook=h, func=f}) end
_G.hook_chat_command = function(cmd, desc, func) chat_commands[cmd] = func end
_G.djui_chat_message_create = function(m) print("Chat: " .. m) end
_G.network_get_player_text_color_string = function() return "" end
_G.network_is_server = function() return true end
_G.network_register_packet = function() end
_G.network_send_to = function() end
_G.play_sound = function() end
_G.mod_storage_load = function() return "" end
_G.mod_storage_save = function() end
_G.SafeSave = function(s) print("SafeSave: " .. s) end
_G.SaveManager = { request_save = function() print("Save requested.") end }

_G.HOOK_ON_LEVEL_INIT = 1
_G.HOOK_MARIO_UPDATE = 2

-- Load modules
dofile("mods/system_inventory/main.lua")
dofile("mods/system_mail/main.lua")
dofile("mods/system_auction_house/main.lua")

print("Testing Inventory Bounds...")
_G.Inventory.add_item(_G.gMarioStates[0], "wood", -50)
assert(_G.gPlayerSyncTable[0]["inv_wood"] == nil or _G.gPlayerSyncTable[0]["inv_wood"] == 0, "Inventory accepted negative addition")

_G.Inventory.add_item(_G.gMarioStates[0], "wood", 100)
assert(_G.gPlayerSyncTable[0]["inv_wood"] == 100, "Inventory failed positive addition")

local success = _G.Inventory.remove_item(_G.gMarioStates[0], "wood", -10)
assert(success == false, "Inventory allowed negative removal (duping)")
assert(_G.gPlayerSyncTable[0]["inv_wood"] == 100, "Inventory value changed after negative removal attempt")

print("Testing Auction House /ah sell...")
-- Try to sell negative items
chat_commands["ah"]("sell wood -50 10")
-- Try to sell for negative price
chat_commands["ah"]("sell wood 10 -500")
-- Try to sell fractional items
chat_commands["ah"]("sell wood 5.5 10")

assert(#_G.AuctionHouse.listings == 1, "Auction House listing count incorrect, should be 1 (fractional count floors to 5)")
assert(_G.AuctionHouse.listings[1].count == 5, "Fractional count did not floor correctly")

print("Testing Mail.send bounds...")
_G.Mail.send("SYSTEM", "Player 0", "Test", "Msg", {id="wood", count=-5})
assert(#_G.Mail.inbox == 0, "Mail system allowed negative attachment count")

print("All Economy & Security tests passed.")
