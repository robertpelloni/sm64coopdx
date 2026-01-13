-- Trade UI
_G.TradeUI = {}

function TradeUI.render()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    if not sTable.tradeStatus or sTable.tradeStatus == Trade.STATE_NONE then return end

    -- If waiting for request, show tooltip
    if sTable.tradeStatus == Trade.STATE_REQUEST_SENT then
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text("Waiting for partner...", 20, 100, 1)
        return
    end

    if sTable.tradeStatus == Trade.STATE_TRADING or sTable.tradeStatus == Trade.STATE_CONFIRMED then
        local partnerIdx = sTable.tradePartner
        if partnerIdx == -1 or not gNetworkPlayers[partnerIdx].connected then
            Trade.cancel()
            return
        end

        local pTable = gPlayerSyncTable[partnerIdx]

        -- Draw Window
        local screenWidth = djui_hud_get_screen_width()
        local screenHeight = djui_hud_get_screen_height()
        local w = 400
        local h = 300
        local x = (screenWidth - w) / 2
        local y = (screenHeight - h) / 2

        djui_hud_set_color(0, 0, 0, 200)
        djui_hud_render_rect(x, y, w, h)

        -- My Side (Left)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text("You", x + 20, y + 20, 1)
        djui_hud_print_text("Coins: " .. (sTable.tradeOfferCoins or 0), x + 20, y + 50, 1)

        if sTable.tradeStatus == Trade.STATE_CONFIRMED then
             djui_hud_set_color(0, 255, 0, 255)
             djui_hud_print_text("READY", x + 20, y + 250, 1)
        else
             djui_hud_set_color(255, 255, 255, 255)
             djui_hud_print_text("Editing...", x + 20, y + 250, 1)
        end

        -- Their Side (Right)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(gNetworkPlayers[partnerIdx].name, x + 220, y + 20, 1)
        djui_hud_print_text("Coins: " .. (pTable.tradeOfferCoins or 0), x + 220, y + 50, 1)

        if pTable.tradeStatus == Trade.STATE_CONFIRMED then
             djui_hud_set_color(0, 255, 0, 255)
             djui_hud_print_text("READY", x + 220, y + 250, 1)
        else
             djui_hud_set_color(255, 0, 0, 255)
             djui_hud_print_text("Waiting", x + 220, y + 250, 1)
        end

        -- Controls
        djui_hud_set_color(200, 200, 200, 255)
        djui_hud_print_text("D-Pad U/D: Coins | A: Confirm | B: Cancel", x + 50, y + h + 10, 1)
    end
end

function TradeUI.input(m)
    local sTable = gPlayerSyncTable[m.playerIndex]

    if sTable.tradeStatus == Trade.STATE_TRADING then
        -- Handle Input
        if m.controller.buttonPressed & D_JPAD ~= 0 then
             local coins = sTable.tradeOfferCoins or 0
             if m.controller.buttonPressed & U_JPAD ~= 0 then
                 coins = coins + 10
             elseif m.controller.buttonPressed & D_JPAD ~= 0 then
                 coins = math.max(0, coins - 10)
             end
             Trade.update_offer(coins, nil)
        end

        if m.controller.buttonPressed & A_BUTTON ~= 0 then
            Trade.confirm()
        end

        if m.controller.buttonPressed & B_BUTTON ~= 0 then
            Trade.cancel()
        end

        -- Lock movement
        m.freeze = 1
    elseif sTable.tradeStatus == Trade.STATE_CONFIRMED then
        -- Check for completion logic here (Input loop instead of Render loop)
        local partnerIdx = sTable.tradePartner
        if partnerIdx ~= -1 and gNetworkPlayers[partnerIdx].connected then
            local pTable = gPlayerSyncTable[partnerIdx]
            if pTable.tradeStatus == Trade.STATE_CONFIRMED then
                Trade.finalize(m.playerIndex, partnerIdx)
                return
            end
        end

        if m.controller.buttonPressed & B_BUTTON ~= 0 then
            sTable.tradeStatus = Trade.STATE_TRADING -- Unconfirm
        end
        m.freeze = 1
    end
end
