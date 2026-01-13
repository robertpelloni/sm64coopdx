-- Initialize
-- require handled by mod loader

Quest.register("coin_collector", {
    name = "Coin Collector",
    target = 10,
    reward = {item = "coin_bag", amount = 50}
})

-- Test Command
function on_start_quest(msg)
    local m = gMarioStates[0]
    if msg == "coin" then
        Quest.start(m, "coin_collector")
    elseif msg == "save" then
        Quest.save()
        djui_chat_message_create("Quests Saved")
    elseif msg == "load" then
        Quest.load()
        djui_chat_message_create("Quests Loaded")
    end
    return true
end

hook_chat_command("quest", "Manage quests", on_start_quest)

-- Hook into coin collection
local lastCoins = 0
function quest_check_coins(m)
    if m.playerIndex ~= 0 then return end

    -- Load on init logic
    if not _G.QUESTS_LOADED then
        Quest.load()
        _G.QUESTS_LOADED = true
        lastCoins = m.numCoins
    end

    -- Save Interval
    if gGlobalTimer % 900 == 0 then
        Quest.save()
    end

    if m.numCoins > lastCoins then
        local diff = m.numCoins - lastCoins
        Quest.update_progress(m, "coin_collector", diff)
        lastCoins = m.numCoins
    elseif m.numCoins < lastCoins then
        lastCoins = m.numCoins
    end
end

hook_event(HOOK_MARIO_UPDATE, quest_check_coins)
