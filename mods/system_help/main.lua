-- name: System - Help
-- description: Centralized Help Command.

local HELP_TOPICS = {
    general = "Welcome to sm64coopdx MMORPG! Use /help [topic] for more info.\nTopics: controls, commands, classes, guilds, economy",
    controls = "Controls:\nL+START: Menu\nX: Boost (Ground)\nL+A: Glide (Air)\nR: FLUDD/Throw\nY: Hookshot\nZ: Crouch/Drop",
    commands = "Commands:\n/config - Settings\n/class - Change Class\n/guild - Guilds\n/trade - Trade\n/quest - Quests",
    classes = "Classes:\nWarrior: Melee (Bash, Rage)\nMage: Magic (Fireball, Teleport)\nRogue: Stealth (Dash, Invisibility)",
    guilds = "Guilds:\n/guild create [name]\n/guild join [name]\n/g [msg] - Guild Chat",
    economy = "Economy:\nCollect coins to buy items from Shopkeepers (Toads).\nPress B near Toad to open Shop."
}

function on_help_command(msg)
    if msg == "" then msg = "general" end

    local text = HELP_TOPICS[msg]
    if text then
        djui_chat_message_create(text)
    else
        djui_chat_message_create("Topic not found. Try /help for list.")
    end
    return true
end

hook_chat_command("help", "Show help topics", on_help_command)
