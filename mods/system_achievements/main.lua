-- Achievement Definitions & Logic

-- 1. Travel
Achievement.register("marathon", {
    name = "Marathon Runner",
    description = "Travel a long distance.",
    title = "The Swift"
})

-- 2. Wealth
Achievement.register("rich", {
    name = "Deep Pockets",
    description = "Have 1000 coins in inventory.",
    title = "Tycoon"
})

-- 3. Social
Achievement.register("social", {
    name = "Socialite",
    description = "Join a guild.",
    title = "Guildsman"
})

-- Tracking Variables
local distTraveled = 0

function achievement_update(m)
    if m.playerIndex ~= 0 then return end

    -- Load on start
    if not _G.ACHIEVEMENTS_LOADED then
        Achievement.load()
        _G.ACHIEVEMENTS_LOADED = true
    end

    -- Track Distance
    if (m.action & ACT_FLAG_MOVING) ~= 0 then
        distTraveled = distTraveled + m.forwardVel
        if distTraveled > 100000 and not Achievement.has(m, "marathon") then
            Achievement.unlock(m, "marathon")
        end
    end

    -- Track Wealth
    if _G.Inventory then
        local coins = Inventory.get_count(m, "coin_bag")
        if coins >= 1000 and not Achievement.has(m, "rich") then
            Achievement.unlock(m, "rich")
        end
    end

    -- Track Guild
    local sTable = gPlayerSyncTable[m.playerIndex]
    if sTable.guildName and not Achievement.has(m, "social") then
        Achievement.unlock(m, "social")
    end

    -- Autosave
    if gGlobalTimer % 1800 == 0 then
        Achievement.save()
    end
end

-- Command
function on_title(msg)
    local m = gMarioStates[0]
    if msg == "" then
        djui_chat_message_create("Usage: /title [name] or /title list")
        return true
    end

    if msg == "list" then
        djui_chat_message_create("Unlocked Titles:")
        for id, def in pairs(_G.Achievement.defs) do
            if Achievement.has(m, id) and def.title then
                djui_chat_message_create("- " .. def.title)
            end
        end
        return true
    end

    if Achievement.set_title(m, msg) then
        djui_chat_message_create("Title set to: " .. msg)
    else
        djui_chat_message_create("Title locked or invalid.")
    end
    return true
end

hook_chat_command("title", "Set player title", on_title)
hook_event(HOOK_MARIO_UPDATE, achievement_update)
