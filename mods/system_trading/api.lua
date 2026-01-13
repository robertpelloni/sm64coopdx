-- Trade System API
_G.Trade = {}

-- Enum
Trade.STATE_NONE = 0
Trade.STATE_REQUEST_SENT = 1
Trade.STATE_REQUEST_RECEIVED = 2
Trade.STATE_TRADING = 3
Trade.STATE_CONFIRMED = 4

-- Constants
local TRADE_PACKET = 100 -- Arbitrary distinct ID

-- Helper: Get trade partner index
function Trade.get_partner_index(pIndex)
    local sTable = gPlayerSyncTable[pIndex]
    return sTable.tradePartner or -1
end

-- Networking
function Trade.send_packet(type, data)
    local packet = {
        packetType = type,
        data = data
    }
    network_send(true, packet)
end

function Trade.request(targetIndex)
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    if sTable.tradeStatus and sTable.tradeStatus ~= Trade.STATE_NONE then
        djui_chat_message_create("You are already busy.")
        return
    end

    sTable.tradePartner = targetIndex
    sTable.tradeStatus = Trade.STATE_REQUEST_SENT

    djui_chat_message_create("Trade request sent to " .. gNetworkPlayers[targetIndex].name)

    -- We wait for them to reciprocate by typing /trade [us]
end

function Trade.accept(targetIndex)
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    sTable.tradePartner = targetIndex
    sTable.tradeStatus = Trade.STATE_TRADING

    djui_chat_message_create("Trade started with " .. gNetworkPlayers[targetIndex].name)
end

function Trade.update_offer(coins, items)
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    if sTable.tradeStatus ~= Trade.STATE_TRADING and sTable.tradeStatus ~= Trade.STATE_CONFIRMED then return end

    -- Validate coins against actual inventory
    local actualCoins = Inventory.get_count(m, "coin_bag")
    if coins > actualCoins then
        coins = actualCoins
    end

    sTable.tradeOfferCoins = coins
    -- Future: Items list
    sTable.tradeStatus = Trade.STATE_TRADING -- Reset confirm if offer changes
end

function Trade.confirm()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    if sTable.tradeStatus == Trade.STATE_TRADING then
        sTable.tradeStatus = Trade.STATE_CONFIRMED
    end
end

function Trade.cancel()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    sTable.tradeStatus = Trade.STATE_NONE
    sTable.tradePartner = -1
    sTable.tradeOfferCoins = 0
    sTable.tradeOfferItems = nil
end

function Trade.finalize(myIndex, partnerIndex)
    -- Both confirmed. Swap items.
    local myState = gPlayerSyncTable[myIndex]
    local partnerState = gPlayerSyncTable[partnerIndex]

    local myCoins = myState.tradeOfferCoins or 0
    local theirCoins = partnerState.tradeOfferCoins or 0

    local m = gMarioStates[myIndex]

    -- Deduct my offer
    if myCoins > 0 then
        Inventory.remove_item(m, "coin_bag", myCoins)
    end

    -- Add their offer
    if theirCoins > 0 then
        Inventory.add_item(m, "coin_bag", theirCoins)
    end

    djui_chat_message_create("Trade complete! Sent " .. myCoins .. ", Received " .. theirCoins)

    -- Reset
    Trade.cancel()

    -- Force save to prevent data loss on crash
    if Inventory.save then Inventory.save() end
end
