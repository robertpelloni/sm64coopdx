-- name: System - Help and Manual UI
-- description: Comprehensive in-game Encyclopedia.

_G.SystemHelp = {}

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

SystemHelp.registry = {
    {
        id = "basics",
        name = "1. Game Basics",
        desc = "Welcome to the SM64 MMORPG Project! Use the D-Pad to navigate menus. Press L-Trigger + START to open the Main Menu, which grants access to your Inventory, Quests, Guilds, and more.",
        tooltip = "Core controls and getting started."
    },
    {
        id = "inventory",
        name = "2. Inventory System",
        desc = "The Universal Inventory stores all your items, materials, and equipment. Items stack infinitely. Use the Inventory UI to view your collection. Your inventory is automatically saved.",
        tooltip = "Learn about item management and storage."
    },
    {
        id = "weapons",
        name = "3. Combat & Weapons",
        desc = "Weapons can be equipped from your inventory. They modify your attacks and have durability. When durability reaches 0, the weapon breaks. Mana is used for special abilities and regenerates over time.",
        tooltip = "Understand combat mechanics, weapon durability, and mana."
    },
    {
        id = "classes",
        name = "4. Class System",
        desc = "Choose between Warrior, Mage, and Rogue. Each class has unique abilities that consume Mana. Warriors excel at close combat, Mages cast spells, and Rogues use stealth and agility.",
        tooltip = "Details on the Warrior, Mage, and Rogue classes."
    },
    {
        id = "economy",
        name = "5. Economy & Trading",
        desc = "Coins are the primary currency. You can buy items from Toad NPCs at the Shop, trade with other players using the secure Trading UI, or use the global Auction House to buy and sell goods asynchronously.",
        tooltip = "Information on Shops, Trading, and the Auction House."
    },
    {
        id = "lifeskills",
        name = "6. Life Skills (Fishing/Mining/Crafting)",
        desc = "Gather materials in the world! Use a Fishing Rod near water to catch fish. Break ore nodes to mine stone and iron. Use these materials at Crafting Tables to create furniture, weapons, and tools.",
        tooltip = "Learn how to gather resources and craft items."
    },
    {
        id = "social",
        name = "7. Guilds & Parties",
        desc = "Form a Party to share experience and prevent friendly fire. Create a Guild to get a custom nametag, private chat (/g), and access to a shared Guild Hall via Castle Courtyard.",
        tooltip = "Social features for grouping up with other players."
    },
    {
        id = "housing",
        name = "8. Player Housing",
        desc = "Purchase furniture and decorate your own instanced house! Your house layout is saved persistently. Visit the Castle Courtyard to access the housing district.",
        tooltip = "Details on decorating and managing your personal space."
    },
    {
        id = "mounts",
        name = "9. Mounts & Movement",
        desc = "Unlock mounts like Yoshi and Dorrie to travel faster. You can also use FLUDD nozzles (Hover, Rocket, Turbo) and the Hookshot to navigate complex terrain.",
        tooltip = "Transportation and traversal mechanics."
    },
    {
        id = "dungeons",
        name = "10. Dungeons & Raids",
        desc = "Group up to tackle Dungeons like the Crypt of the Vanished or face Raid Bosses like King Whomp. These encounters require teamwork and strategy to defeat.",
        tooltip = "End-game PvE content and boss encounters."
    }
}

function help_ui_render()
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local m = gMarioStates[0]

    local items = {}
    for _, entry in ipairs(SystemHelp.registry) do
        table.insert(items, {
            id = entry.id,
            name = entry.name,
            right_text = "",
            tooltip = entry.tooltip,
            desc = entry.desc
        })
    end

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(0, 255, 255, 255)
        djui_hud_print_text(selItem.name, x, y, 1.2)

        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(selItem.desc, x, y + 40, 25, 0.9)
    end

    UIToolkit.draw_menu("ENCYCLOPEDIA & HELP", items, SELECTION, SCROLL_OFFSET, renderDetails, "B: Close", "Comprehensive documentation of all game mechanics and systems.")
end

function help_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, #SystemHelp.registry, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, #SystemHelp.registry)

    if close then
        UI_VISIBLE = false
    end
end

function SystemHelp.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

hook_event(HOOK_ON_HUD_RENDER, help_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, help_ui_update)
