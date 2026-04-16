-- name: System - Daily Quests
-- description: Procedurally generated daily tasks.

_G.DailyQuests = {}

-- Daily Quest Definitions
local daily_pool = {
    { id = "daily_kill_goombas", type = "kill", target = "goomba", goal = 10, name = "Daily: Goomba Stomper", desc = "Defeat 10 Goombas.", rewardCoins = 100 },
    { id = "daily_fish_bass", type = "fish", target = "fish_bass", goal = 3, name = "Daily: Big Catch", desc = "Catch 3 Big Bass.", rewardCoins = 150 },
    { id = "daily_mine_iron", type = "mine", target = "iron_ore", goal = 5, name = "Daily: Iron Miner", desc = "Mine 5 Iron Ore.", rewardCoins = 120 }
}

-- For simplicity, we assign a random quest on login if one isn't active
function daily_init(m)
    if m.playerIndex ~= 0 then return end
    if not _G.Quest then return end

    -- Register definitions into main Quest system
    for _, dq in ipairs(daily_pool) do
        if not Quest.registry[dq.id] then
            Quest.register(dq.id, dq.name, dq.desc, dq.goal, function(player)
                player.numCoins = player.numCoins + dq.rewardCoins
                djui_chat_message_create("Completed " .. dq.name .. "! Reward: " .. tostring(dq.rewardCoins) .. " coins.")
            end)
        end
    end

    -- Assign a daily if none are active
    local hasDaily = false
    local active = Quest.get_active_quests(m)
    for _, qId in ipairs(active) do
        if string.sub(qId, 1, 6) == "daily_" then
            hasDaily = true
            break
        end
    end

    if not hasDaily then
        local randIndex = math.random(1, #daily_pool)
        local chosen = daily_pool[randIndex]
        Quest.assign(m, chosen.id)
        djui_chat_message_create("New Daily Quest assigned: " .. chosen.name)
    end
end

-- Hooks to track progress (Mockups for integration with other systems)
function on_mob_killed(m, mobType)
    if m.playerIndex ~= 0 then return end
    local p = Quest.get_progress(m, "daily_kill_goombas")
    if mobType == "goomba" and p < 10 then
        Quest.add_progress(m, "daily_kill_goombas", 1)
    end
end

hook_event(HOOK_ON_LEVEL_INIT, daily_init)
