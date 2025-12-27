-- Initialize System
-- require statements removed as the mod loader handles file execution

-- Test Data
-- We wrap this in a check or function to ensure api.lua has run,
-- but typically global definitions in api.lua run first if files are alphabetical or loaded sequentially.
-- However, safe programming: ensure Inventory exists.

if _G.Inventory then
    Inventory.define_item("coin_bag", "Coin Bag", "A bag full of coins.", 10)
    Inventory.define_item("mushroom", "Mushroom", "A weird mushroom.", 5)
end

-- Chat Command for testing
function on_give_item(msg)
    local m = gMarioStates[0]
    local id = "coin_bag"
    local amount = 1

    if msg == "mushroom" then id = "mushroom" end

    if _G.Inventory then
        Inventory.add_item(m, id, amount)
        djui_chat_message_create("Gave " .. amount .. " " .. id)
    else
        djui_chat_message_create("Inventory system not loaded.")
    end
    return true
end

hook_chat_command("give_item", "Give an item (test)", on_give_item)
