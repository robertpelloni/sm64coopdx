-- name: System - Daily Quests
-- description: Procedurally generated daily tasks.

_G.DailyQuests = {}

-- Daily Quest Definitions
local daily_pool = {
    { id = "daily_kill_goombas", target = 10, name = "Daily: Goomba Stomper", description = "Defeat 10 Goombas.", reward = { item = "coin_bag", amount = 100 } },
    { id = "daily_fish_bass", target = 3, name = "Daily: Big Catch", description = "Catch 3 Big Bass.", reward = { item = "coin_bag", amount = 150 } },
    { id = "daily_mine_iron", target = 5, name = "Daily: Iron Miner", description = "Mine 5 Iron Ore.", reward = { item = "coin_bag", amount = 120 } }
}

-- For simplicity, we assign a random quest on login if one isn't active
function daily_init(m)
    if m.playerIndex ~= 0 then return end
    if not _G.Quest then return end

    -- Register definitions into main Quest system
    for _, dq in ipairs(daily_pool) do
        if not Quest.defs[dq.id] then
            Quest.register(dq.id, {
                name = dq.name,
                description = dq.description,
                target = dq.target,
                reward = dq.reward
            })
        end
    end

    -- Assign a daily if none are active
    local hasDaily = false
    local active = Quest.get_active(m)
    for _, q in ipairs(active) do
        if string.sub(q.id, 1, 6) == "daily_" then
            hasDaily = true
            break
        end
    end

    if not hasDaily then
        local randIndex = math.random(1, #daily_pool)
        local chosen = daily_pool[randIndex]
        Quest.start(m, chosen.id)
    end
end

-- Hooks to track progress (Mockups for integration with other systems)
function on_mob_killed(m, mobType)
    if m.playerIndex ~= 0 then return end
    if not _G.Quest then return end

    if mobType == "goomba" then
        Quest.update_progress(m, "daily_kill_goombas", 1)
    end
end

hook_event(HOOK_ON_LEVEL_INIT, daily_init)
