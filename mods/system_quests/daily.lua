-- name: System - Daily Quests
-- description: Assigns random daily quests on login.
-- depends: system_quests

local DAILIES = {
    {
        id = "daily_gather_wood",
        name = "Daily: Lumberjack",
        desc = "Gather 10 pieces of Wood.",
        target = 10,
        reward = { item = "coin_bag", amount = 50 }
    },
    {
        id = "daily_slay_goombas",
        name = "Daily: Pest Control",
        desc = "Defeat 5 Goombas.",
        target = 5,
        reward = { item = "coin_bag", amount = 50 }
    }
}

-- Register dailies into the main quest registry
function init_dailies()
    if not _G.Quest then return end
    for _, dq in ipairs(DAILIES) do
        Quest.register(dq.id, dq)
    end
end

-- Assign one random daily if they don't have one active
function assign_daily(m)
    if m.playerIndex ~= 0 then return end
    if not _G.Quest then return end

    local active = Quest.get_active(m)
    local hasDaily = false

    for _, q in ipairs(active) do
        if string.sub(q.id, 1, 6) == "daily_" then
            hasDaily = true
            break
        end
    end

    if not hasDaily then
        local randIdx = math.random(1, #DAILIES)
        Quest.start(m, DAILIES[randIdx].id)
    end
end

hook_event(HOOK_ON_SYNC_VALID, function()
    init_dailies()
    -- Small delay to let other systems load
    -- Normally we'd use a timer or coroutine, but for simplicity we'll just assign on the first update loop after sync valid
    _G.ASSIGN_DAILY_PENDING = true
end)

hook_event(HOOK_MARIO_UPDATE, function(m)
    if m.playerIndex == 0 and _G.ASSIGN_DAILY_PENDING then
        assign_daily(m)
        _G.ASSIGN_DAILY_PENDING = false
    end
end)
