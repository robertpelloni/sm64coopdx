-- Initialize System
-- require statements removed as the mod loader handles file execution

-- Test Data
if _G.Inventory then
    -- Basic
    Inventory.define_item("coin_bag", "Coin Bag", "A bag full of coins.", 1000)
    Inventory.define_item("mushroom", "Mushroom", "A weird mushroom.", 5)

    -- Weapons
    Inventory.define_item("blaster", "Blaster", "Standard issue sidearm.", 1)
    Inventory.define_item("wrench", "OmniWrench", "Fixes everything.", 1)
    Inventory.define_item("hookshot", "Hookshot", "Grapple to distant surfaces.", 1)

    -- Badges
    Inventory.define_item("badge_speed", "Badge: Agility", "Run 20% faster.", 1)
    Inventory.define_item("badge_feather", "Badge: Feather", "Fall slower.", 1)
    Inventory.define_item("badge_health", "Badge: Regen", "Regenerate health over time.", 1)
    Inventory.define_item("badge_metal", "Badge: Metal", "Become heavy and indestructible.", 1)
    Inventory.define_item("badge_wing", "Badge: Wing", "Fly high!", 1)

    -- Transformations
    Inventory.define_item("totem_termite", "Totem: Termite", "Transform into a bug.", 1)
    Inventory.define_item("totem_goomba", "Totem: Goomba", "Transform into a Goomba.", 1)
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
    if msg == "metal" then id = "badge_metal" end
    if msg == "wing" then id = "badge_wing" end
    if msg == "totem" then id = "totem_termite" end
    if msg == "goomba" then id = "totem_goomba" end

    if msg == "save" then
        Inventory.save()
        djui_chat_message_create("Saved.")
        return true
    end
    if msg == "load" then
        Inventory.load()
        djui_chat_message_create("Loaded.")
        return true
    end

    if _G.Inventory then
        Inventory.add_item(m, id, amount)
        djui_chat_message_create("Gave " .. amount .. " " .. id)
    else
        djui_chat_message_create("Inventory system not loaded.")
    end
    return true
end

-- Economy Logic
local lastCoinCount = 0

function economy_update(m)
    if m.playerIndex ~= 0 then return end

    -- Load on first frame (simplified init check)
    if not _G.INVENTORY_LOADED then
        Inventory.load()
        _G.INVENTORY_LOADED = true
        lastCoinCount = m.numCoins
    end

    -- Autosave every 30 seconds (30 * 30 frames)
    if gGlobalTimer % 900 == 0 then
        Inventory.save()
    end

    -- Coin Collection
    if m.numCoins > lastCoinCount then
        local diff = m.numCoins - lastCoinCount
        Inventory.add_item(m, "coin_bag", diff)
        lastCoinCount = m.numCoins
    elseif m.numCoins < lastCoinCount then
        lastCoinCount = m.numCoins
    end
end

hook_chat_command("give_item", "Give an item (test)", on_give_item)
hook_event(HOOK_MARIO_UPDATE, economy_update)
