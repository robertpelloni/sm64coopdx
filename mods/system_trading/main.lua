-- name: System - Trading
-- description: Player-to-Player trading system.

-- Ensure UI is loaded (global _G.TradeUI defined in ui.lua)
-- sm64coopdx auto-loads files alphabetically, so api.lua < main.lua < ui.lua.
-- Wait, 'm' comes before 'u'. So ui.lua is NOT loaded yet when main.lua runs if we rely on global.
-- Actually, the execution order is typically alpha.
-- `api.lua` (Trade global) -> `main.lua` -> `ui.lua` (TradeUI global).
-- This means inside `main.lua`, `TradeUI` might be nil immediately.
-- However, we only access `TradeUI` inside hooks (which run later), so it should be fine.

function on_trade_command(msg)
    if msg == "" then
        djui_chat_message_create("Usage: /trade [PlayerName]")
        return true
    end

    -- Find player by name
    local targetIdx = -1
    for i = 1, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected and gNetworkPlayers[i].name == msg then
            targetIdx = i
            break
        end
    end

    if targetIdx == -1 then
        djui_chat_message_create("Player not found.")
        return true
    end

    -- Check if they already requested us
    local theirState = gPlayerSyncTable[targetIdx]
    if theirState.tradePartner == 0 and theirState.tradeStatus == Trade.STATE_REQUEST_SENT then
        Trade.accept(targetIdx)
    else
        Trade.request(targetIdx)
    end

    return true
end

hook_chat_command("trade", "Trade with a player", on_trade_command)

hook_event(HOOK_ON_HUD_RENDER, function()
    if _G.TradeUI then
        _G.TradeUI.render()
    end
end)

hook_event(HOOK_BEFORE_MARIO_UPDATE, function(m)
    if m.playerIndex == 0 and _G.TradeUI then
        _G.TradeUI.input(m)
    end
end)
