-- Initialize System
-- require statements removed as the mod loader handles file execution

-- Test Data
if _G.Inventory then
    -- Basic
    Inventory.define_item("coin_bag", "Coin Bag", "A bag full of coins.", 10)
    Inventory.define_item("mushroom", "Mushroom", "A weird mushroom.", 5)

    -- Weapons
    Inventory.define_item("blaster", "Blaster", "Standard issue sidearm.", 1)
    Inventory.define_item("wrench", "OmniWrench", "Fixes everything.", 1)
    Inventory.define_item("hookshot", "Hookshot", "Grapple to distant surfaces.", 1)

    -- Badges
    Inventory.define_item("badge_speed", "Badge: Agility", "Run 20% faster.", 1)
    Inventory.define_item("badge_feather", "Badge: Feather", "Fall slower.", 1)
    Inventory.define_item("badge_health", "Badge: Regen", "Regenerate health over time.", 1)
end

-- Chat Command for testing
function on_give_item(msg)
    local m = gMarioStates[0]
    local id = "coin_bag"
    local amount = 1

    -- Helper to match
    if msg == "mushroom" then id = "mushroom" end
    if msg == "blaster" then id = "blaster" end
    if msg == "wrench" then id = "wrench" end
    if msg == "hookshot" then id = "hookshot" end
    if msg == "speed" then id = "badge_speed" end
    if msg == "feather" then id = "badge_feather" end
    if msg == "health" then id = "badge_health" end

    if _G.Inventory then
        Inventory.add_item(m, id, amount)
        djui_chat_message_create("Gave " .. amount .. " " .. id)
    else
        djui_chat_message_create("Inventory system not loaded.")
    end
    return true
end

hook_chat_command("give_item", "Give an item (test)", on_give_item)
