-- name: System - Shop
-- description: NPC Shopkeeper Logic.
-- depends: system_inventory, system_ui

_G.Shop = {}

local active_shop = nil
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

-- Define a basic shop inventory
local TEST_SHOP = {
    name = "Toad's General Store",
    items = {
        { id = "wood", price = 10 },
        { id = "stone", price = 20 },
        { id = "iron_ore", price = 50 },
        { id = "health_potion", price = 100 }
    }
}

function shop_ui_render()
    if not active_shop then return end
    if not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local items = {}

    for _, entry in ipairs(active_shop.items) do
        local def = _G.Inventory and _G.Inventory.items[entry.id]
        local name = def and def.name or entry.id
        local tooltip = def and def.description or "Unknown Item"

        table.insert(items, {
            id = entry.id,
            name = name,
            right_text = tostring(entry.price) .. "c",
            tooltip = tooltip,
            price = entry.price
        })
    end

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(selItem.name, x, y, 1.2)

        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 40, 25, 0.9)

        djui_hud_set_color(255, 255, 0, 255)
        djui_hud_print_text("Cost: " .. tostring(selItem.price) .. " Coins", x, y + 100, 1.0)

        djui_hud_set_color(150, 255, 150, 255)
        djui_hud_print_text("You have: " .. tostring(m.numCoins) .. "c", x, y + 120, 0.8)
    end

    UIToolkit.draw_menu(active_shop.name, items, SELECTION, SCROLL_OFFSET, renderDetails, "A: Buy  B: Close", "Purchase goods using your collected coins.")
end

function shop_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not active_shop then return end
    if not _G.UIToolkit then return end

    local maxItems = #active_shop.items
    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act and maxItems > 0 then
        local entry = active_shop.items[SELECTION]
        if m.numCoins >= entry.price then
            if _G.Inventory then
                m.numCoins = m.numCoins - entry.price
                Inventory.add_item(m, entry.id, 1)
                djui_chat_message_create("Bought 1x " .. entry.id)
                play_sound(SOUND_GENERAL_COIN, m.marioObj.header.gfx.cameraToObject)
            else
                djui_chat_message_create("Inventory system not found.")
                play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
            end
        else
            djui_chat_message_create("Not enough coins!")
            play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
        end
    end

    if close then
        active_shop = nil
    end
end

function Shop.open(shop_def)
    active_shop = shop_def
    SELECTION = 1
    SCROLL_OFFSET = 0
    OPEN_TIMER = 5
end

-- NPC Interaction (Basic Example hooking into Mario Update)
function shop_npc_interact(m)
    if m.playerIndex ~= 0 then return end
    if active_shop then return end -- Don't interact if already open

    -- Find nearest Toad (placeholder for actual shop NPCs)
    local toad = obj_get_first_with_behavior_id(id_bhvToadMessage)
    if toad then
        local dist = dist_between_objects(m.marioObj, toad)
        if dist < 300 and (m.controller.buttonPressed & B_BUTTON) ~= 0 then
            -- Open Shop
            Shop.open(TEST_SHOP)
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, shop_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, shop_ui_update)
hook_event(HOOK_MARIO_UPDATE, shop_npc_interact)
