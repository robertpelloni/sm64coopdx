-- Daily Quests Logic
-- Automatically assigns a random set of tasks per day.

_G.Quest = _G.Quest or {}

local DAILY_POOL = {
    {
        id = "daily_gather_wood",
        name = "Daily: Lumberjack",
        description = "Gather 5 pieces of Wood from the environment.",
        target = 5,
        reward = {item = "coin_silver", amount = 10}
    },
    {
        id = "daily_defeat_goombas",
        name = "Daily: Pest Control",
        description = "Defeat 10 Goombas to keep the kingdom safe.",
        target = 10,
        reward = {item = "coin_silver", amount = 15}
    },
    {
        id = "daily_complete_dungeon",
        name = "Daily: Delver",
        description = "Complete 1 Dungeon run.",
        target = 1,
        reward = {item = "coin_gold", amount = 1}
    }
}

function _G.Quest.generate_dailies(m)
    if not _G.Quest or not _G.Quest.register then return end

    local today = os.date("%x")
    local lastLoginDate = mod_storage_load("last_login_date")

    if lastLoginDate ~= today then
        -- New day! Assign a random daily quest
        local randIndex = math.random(1, #DAILY_POOL)
        local dailyDef = DAILY_POOL[randIndex]

        -- Register it dynamically in the Quest system
        _G.Quest.register(dailyDef.id, {
            name = "\\#FFFF00\\" .. dailyDef.name,
            description = dailyDef.description,
            target = dailyDef.target,
            reward = dailyDef.reward
        })

        -- Start the quest automatically
        _G.Quest.start(m, dailyDef.id)

        -- Save the date
        mod_storage_save("last_login_date", today)
        djui_chat_message_create("\\#FFFF00\\A new Daily Quest is available in your log!")
    else
        -- If already generated today, ensure it's still registered in memory
        for _, def in ipairs(DAILY_POOL) do
            _G.Quest.register(def.id, {
                name = "\\#FFFF00\\" .. def.name,
                description = def.description,
                target = def.target,
                reward = def.reward
            })
        end
    end
end

-- Hook into player connection to assign dailies
local function on_daily_init(m)
    if m.playerIndex ~= 0 then return end
    -- Hook triggers at the very end of connection initialization,
    -- so main.lua's Quest table will be fully built by then.
    _G.Quest.generate_dailies(m)
end

hook_event(HOOK_ON_PLAYER_CONNECTED, on_daily_init)
