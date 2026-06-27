-- name: System - Trading
-- description: Allows players to securely trade items and coins.
-- depends: system_inventory, system_ui

_G.Trading = {}

-- State
local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0
local UI_MODE = "select_target" -- "select_target", "type_target", "offer"

local targetPlayerName = ""
local currentTrade = nil -- { partnerId, myOffer = {coin=0, items={}}, partnerOffer = {coin=0, items={}}, state = "offering"|"accepted" }

-- Packets
local PACKET_TRADE_REQ = 200
local PACKET_TRADE_ACC = 201
local PACKET_TRADE_DEC = 202
local PACKET_TRADE_UPDATE = 203
local PACKET_TRADE_CONFIRM = 204

local function get_name(idx)
    return gNetworkPlayers[idx] and gNetworkPlayers[idx].connected and gNetworkPlayers[idx].name or "???"
end

function Trading.reset()
    currentTrade = nil
    UI_VISIBLE = false
end

local function execute_trade(m)
    -- As this is a pure P2P system without an authoritative server for trades,
    -- both clients execute their respective halves of the trade.

    -- Verify my end
    local valid = true
    if m.numCoins < currentTrade.myOffer.coin then valid = false end
    for k,v in pairs(currentTrade.myOffer.items) do
        if _G.Inventory.get_item_count(m, k) < v then valid = false end
    end

    -- In a real authoritative setup, the server would verify the partner's inventory as well.
    -- To mitigate simple spoofing exploits where a malicious client sends a fake PACKET_TRADE_UPDATE
    -- with items/coins they do not possess, we *must* enforce server-side item checks here if we had one.
    -- Because we don't, we are trusting `currentTrade.partnerOffer` to be honest, which is inherently flawed P2P.

    if valid then
        m.numCoins = m.numCoins - currentTrade.myOffer.coin + currentTrade.partnerOffer.coin

        for k,v in pairs(currentTrade.myOffer.items) do
            _G.Inventory.remove_item(m, k, v)
        end
        for k,v in pairs(currentTrade.partnerOffer.items) do
            _G.Inventory.add_item(m, k, v)
        end

        djui_chat_message_create("Trade Successful!")
        play_sound(SOUND_GENERAL_COIN, m.marioObj.header.gfx.cameraToObject)
    else
        djui_chat_message_create("Trade failed: You don't have the offered items.")
        -- Tell the partner the trade failed on our end
        network_send_to(currentTrade.partnerId, true, {type = PACKET_TRADE_DEC, sender = m.playerIndex})
    end

    Trading.reset()
end

-- Network handlers
function on_trade_packet(p)
    local m = gMarioStates[0]

    if p.type == PACKET_TRADE_REQ then
        if not currentTrade then
            djui_chat_message_create(get_name(p.sender) .. " wants to trade! Type /trade accept or /trade decline")
            currentTrade = { partnerId = p.sender, myOffer = {coin=0, items={}}, partnerOffer = {coin=0, items={}}, state = "pending_req" }
            play_sound(SOUND_MENU_MESSAGE_APPEAR, m.marioObj.header.gfx.cameraToObject)
        else
            -- Busy, reply with proper target index
            network_send_to(p.sender, true, {type = PACKET_TRADE_DEC, sender = m.playerIndex})
        end

    elseif p.type == PACKET_TRADE_ACC then
        if currentTrade and currentTrade.state == "request_sent" and currentTrade.partnerId == p.sender then
            currentTrade.state = "offering"
            djui_chat_message_create("Trade accepted by " .. get_name(p.sender))
            -- Open UI for initiator
            UI_VISIBLE = true
            UI_MODE = "offer"
            SELECTION = 1
            SCROLL_OFFSET = 0
            OPEN_TIMER = 5
        end

    elseif p.type == PACKET_TRADE_DEC then
        if currentTrade and (currentTrade.state == "request_sent" or currentTrade.state == "offering") and currentTrade.partnerId == p.sender then
            djui_chat_message_create("Trade declined/cancelled by " .. get_name(p.sender))
            Trading.reset()
        end

    elseif p.type == PACKET_TRADE_UPDATE then
        if currentTrade and currentTrade.state == "offering" and currentTrade.partnerId == p.sender then
            -- VERY STRICT PAYLOAD VALIDATION
            if type(p.offer) ~= "table" then return end

            local safeOffer = { coin = 0, items = {} }

            local pCoin = math.floor(tonumber(p.offer.coin) or 0)
            if pCoin > 0 then safeOffer.coin = pCoin end

            if type(p.offer.items) == "table" then
                for k, v in pairs(p.offer.items) do
                    if type(k) == "string" then
                        local c = math.floor(tonumber(v) or 0)
                        if c > 0 then
                            safeOffer.items[k] = c
                        end
                    end
                end
            end

            currentTrade.partnerOffer = safeOffer

            -- If we were accepted, entering new items revokes accept
            if currentTrade.myState == "accepted" then
                currentTrade.myState = "offering"
            end
        end

    elseif p.type == PACKET_TRADE_CONFIRM then
        if currentTrade and currentTrade.state == "offering" and currentTrade.partnerId == p.sender then
            currentTrade.partnerState = "accepted"

            if currentTrade.myState == "accepted" then
                -- BOTH ACCEPTED! EXECUTE!
                execute_trade(m)
            end
        end
    end
end
network_register_packet(PACKET_TRADE_REQ, on_trade_packet)
network_register_packet(PACKET_TRADE_ACC, on_trade_packet)
network_register_packet(PACKET_TRADE_DEC, on_trade_packet)
network_register_packet(PACKET_TRADE_UPDATE, on_trade_packet)
network_register_packet(PACKET_TRADE_CONFIRM, on_trade_packet)


function on_trade_cmd(msg)
    local m = gMarioStates[0]
    local args = {}
    for w in msg:gmatch("%S+") do table.insert(args, w) end

    if args[1] == "accept" then
        if currentTrade and currentTrade.state == "pending_req" then
            currentTrade.state = "offering"
            network_send_to(currentTrade.partnerId, true, {type = PACKET_TRADE_ACC, sender=m.playerIndex})
            UI_VISIBLE = true
            UI_MODE = "offer"
            SELECTION = 1
            SCROLL_OFFSET = 0
            OPEN_TIMER = 5
        else
            djui_chat_message_create("No pending trade requests.")
        end
    elseif args[1] == "decline" then
        if currentTrade and currentTrade.state == "pending_req" then
            network_send_to(currentTrade.partnerId, true, {type = PACKET_TRADE_DEC, sender=m.playerIndex})
            Trading.reset()
            djui_chat_message_create("Trade declined.")
        end
    else
        if not UI_VISIBLE then
            UI_VISIBLE = true
            UI_MODE = "type_target"
            SELECTION = 1
            SCROLL_OFFSET = 0
            OPEN_TIMER = 5
        else
            UI_VISIBLE = false
        end
    end
    return true
end
hook_chat_command("trade", "Initiate/Accept Trade", on_trade_cmd)

function trading_render()
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end
    local m = gMarioStates[0]

    local items = {}
    local title = ""
    local footer = ""

    if UI_MODE == "type_target" then
        title = "TRADE - ENTER RECIPIENT NAME"
        footer = "A: Confirm  B: Cancel  Y: Delete Char  D-Pad: Type"
        UIToolkit.draw_text_input(title, targetPlayerName, footer, "Type exact name of player to trade with.")

    elseif UI_MODE == "offer" then
        title = "TRADE with " .. get_name(currentTrade.partnerId)

        if currentTrade.myState == "accepted" and currentTrade.partnerState == "accepted" then
            footer = "Processing..."
        elseif currentTrade.myState == "accepted" then
            footer = "Waiting for partner...  B: Cancel Trade"
        else
            footer = "A: Add Item/Coin  X: Confirm Offer  B: Cancel Trade"
        end

        -- List my inventory to add
        local raw = _G.Inventory.get_all_items(m)
        table.insert(items, { id = "coin", name = "Coins", right_text = tostring(m.numCoins), tooltip = "Offer coins."})
        for _, it in ipairs(raw) do
            local def = _G.Inventory.items[it.id]
            table.insert(items, { id = it.id, name = def and def.name or it.id, right_text = "x"..tostring(it.count), tooltip = "Offer 1x" })
        end

        local renderDetails = function(x, y, selItem)
            djui_hud_set_color(255, 255, 255, 255)
            djui_hud_print_text("Your Offer:", x, y, 1)
            local offerY = y + 20

            djui_hud_set_color(200, 200, 200, 255)
            djui_hud_print_text(tostring(currentTrade.myOffer.coin) .. "c", x+10, offerY, 0.8)
            offerY = offerY + 15
            for k,v in pairs(currentTrade.myOffer.items) do
                local d = _G.Inventory.items[k]
                djui_hud_print_text((d and d.name or k) .. " x" .. tostring(v), x+10, offerY, 0.8)
                offerY = offerY + 15
            end

            djui_hud_set_color(255, 255, 255, 255)
            djui_hud_print_text("Partner's Offer:", x, offerY + 10, 1)
            offerY = offerY + 30

            djui_hud_set_color(200, 200, 200, 255)
            djui_hud_print_text(tostring(currentTrade.partnerOffer.coin) .. "c", x+10, offerY, 0.8)
            offerY = offerY + 15
            for k,v in pairs(currentTrade.partnerOffer.items) do
                local d = _G.Inventory.items[k]
                djui_hud_print_text((d and d.name or k) .. " x" .. tostring(v), x+10, offerY, 0.8)
                offerY = offerY + 15
            end

            if currentTrade.partnerState == "accepted" then
                 djui_hud_set_color(0, 255, 0, 255)
                 djui_hud_print_text("Partner Accepted", x, y + 220, 1)
            end
        end

        UIToolkit.draw_menu(title, items, SELECTION, SCROLL_OFFSET, renderDetails, footer, "Select items to add to your offer.")
    end
end

function trading_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    if UI_MODE == "type_target" then
        local newText, submitted, cancelled, newTimer = UIToolkit.handle_text_input(m, targetPlayerName, OPEN_TIMER)
        targetPlayerName = newText
        OPEN_TIMER = newTimer

        if submitted then
            local tId = -1
            for i=1, MAX_PLAYERS-1 do
                if gNetworkPlayers[i].connected and gNetworkPlayers[i].name == targetPlayerName then
                    tId = i; break
                end
            end
            if tId ~= -1 then
                network_send_to(tId, true, {type = PACKET_TRADE_REQ, sender=m.playerIndex})
                currentTrade = { partnerId = tId, state = "request_sent" }
                djui_chat_message_create("Trade request sent to " .. targetPlayerName)
                UI_VISIBLE = false
            else
                djui_chat_message_create("Player not found.")
                UI_VISIBLE = false
            end
        elseif cancelled then
            UI_VISIBLE = false
        end
        return
    end

    if UI_MODE == "offer" then
        if currentTrade.myState == "accepted" then
            -- Wait for packet
            if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
                network_send_to(currentTrade.partnerId, true, {type = PACKET_TRADE_DEC, sender=m.playerIndex})
                Trading.reset()
            end
            return
        end

        -- Offer interaction
        if (m.controller.buttonPressed & X_BUTTON) ~= 0 then
            currentTrade.myState = "accepted"
            network_send_to(currentTrade.partnerId, true, {type = PACKET_TRADE_CONFIRM, sender=m.playerIndex})
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)

            -- If partner already accepted, then executing confirm means we are the second to accept.
            -- We must execute locally too.
            if currentTrade.partnerState == "accepted" then
                execute_trade(m)
            end

            return
        end

        local raw = _G.Inventory.get_all_items(m)
        local max = #raw + 1
        local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, max, OPEN_TIMER)
        SELECTION = sel; OPEN_TIMER = timer; SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, max)

        if act then
            if SELECTION == 1 then -- coin
                if m.numCoins - currentTrade.myOffer.coin >= 10 then
                    currentTrade.myOffer.coin = currentTrade.myOffer.coin + 10
                    network_send_to(currentTrade.partnerId, true, {type = PACKET_TRADE_UPDATE, sender=m.playerIndex, offer=currentTrade.myOffer})
                    play_sound(SOUND_GENERAL_COIN, m.marioObj.header.gfx.cameraToObject)
                end
            else
                local it = raw[SELECTION - 1]
                if it then
                    local cur = currentTrade.myOffer.items[it.id] or 0
                    if it.count > cur then
                        currentTrade.myOffer.items[it.id] = cur + 1
                        network_send_to(currentTrade.partnerId, true, {type = PACKET_TRADE_UPDATE, sender=m.playerIndex, offer=currentTrade.myOffer})
                        play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
                    end
                end
            end
        end

        if close then
            network_send_to(currentTrade.partnerId, true, {type = PACKET_TRADE_DEC, sender=m.playerIndex})
            Trading.reset()
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, trading_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, trading_update)
