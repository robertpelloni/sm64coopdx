-- name: System - Auction House UI
-- description: Visual UI for the global asynchronous marketplace.
-- depends: system_ui, system_auction_house

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0
local UI_MODE = "browse" -- "browse" or "sell"

function ah_ui_render()
    if not UI_VISIBLE then return end
    if not _G.AuctionHouse or not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local items = {}
    local title = ""
    local footer = ""

    if UI_MODE == "browse" then
        title = "AUCTION HOUSE - BROWSE"
        footer = "A: Buy  X: Sell Mode  B: Close"

        for i, listing in ipairs(AuctionHouse.listings) do
            local def = _G.Inventory and _G.Inventory.items[listing.itemId]
            local name = def and def.name or listing.itemId
            table.insert(items, {
                id = listing.id,
                listing = listing,
                name = name,
                right_text = tostring(listing.price) .. "c",
                tooltip = "Seller: " .. listing.seller .. "\nQuantity: " .. tostring(listing.count)
            })
        end
        if #items == 0 then
            table.insert(items, { id = "none", name = "No listings available.", right_text = "", tooltip = "The market is empty." })
        end

    elseif UI_MODE == "sell" then
        title = "AUCTION HOUSE - SELL (SELECT ITEM)"
        footer = "A: Sell  X: Browse Mode  B: Close"

        local raw_items = _G.Inventory.get_all_items(m)
        for _, item in ipairs(raw_items) do
            local def = _G.Inventory.items[item.id]
            table.insert(items, {
                id = item.id,
                name = def and def.name or item.id,
                right_text = "x" .. tostring(item.count),
                tooltip = "Select to list on the Auction House."
            })
        end
        if #items == 0 then
            table.insert(items, { id = "none", name = "Inventory empty.", right_text = "", tooltip = "You have nothing to sell." })
        end
    end

    local renderDetails = function(x, y, selItem)
        if selItem.id == "none" then return end

        if UI_MODE == "browse" then
            local l = selItem.listing
            local def = _G.Inventory and _G.Inventory.items[l.itemId]
            djui_hud_set_color(0, 255, 255, 255)
            djui_hud_print_text(def and def.name or l.itemId, x, y, 1.2)

            djui_hud_set_color(200, 200, 200, 255)
            UIToolkit.draw_wrapped_text("Seller: " .. l.seller, x, y + 40, 25, 0.9)
            UIToolkit.draw_wrapped_text("Quantity: " .. tostring(l.count), x, y + 60, 25, 0.9)

            djui_hud_set_color(255, 255, 0, 255)
            djui_hud_print_text("Price: " .. tostring(l.price) .. " coins", x, y + 100, 1.0)

            if m.numCoins < l.price then
                djui_hud_set_color(255, 100, 100, 255)
                djui_hud_print_text("Not enough coins!", x, y + 120, 0.8)
            end

        elseif UI_MODE == "sell" then
            local def = _G.Inventory and _G.Inventory.items[selItem.id]
            djui_hud_set_color(0, 255, 255, 255)
            djui_hud_print_text(def and def.name or selItem.id, x, y, 1.2)

            djui_hud_set_color(200, 200, 200, 255)
            UIToolkit.draw_wrapped_text(def and def.description or "", x, y + 40, 25, 0.9)

            djui_hud_set_color(255, 200, 100, 255)
            UIToolkit.draw_wrapped_text("Press A to list 1x for 100c (Placeholder fixed price).", x, y + 100, 25, 0.8)
        end
    end

    UIToolkit.draw_menu(title, items, SELECTION, SCROLL_OFFSET, renderDetails, footer, "Trade goods globally with other players.")
end

function ah_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    -- X Button (Y on Xbox controller) to toggle modes
    if (m.controller.buttonPressed & X_BUTTON) ~= 0 then
        if UI_MODE == "browse" then UI_MODE = "sell" else UI_MODE = "browse" end
        SELECTION = 1
        SCROLL_OFFSET = 0
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
        return
    end

    local maxItems = 1
    local list = {}
    if UI_MODE == "browse" then
        maxItems = #AuctionHouse.listings > 0 and #AuctionHouse.listings or 1
        list = AuctionHouse.listings
    else
        local inv = _G.Inventory.get_all_items(m)
        maxItems = #inv > 0 and #inv or 1
        list = inv
    end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act then
        if UI_MODE == "browse" and #list > 0 then
            local l = list[SELECTION]
            if l then
                -- Perform Buy
                if m.numCoins >= l.price then
                     m.numCoins = m.numCoins - l.price
                     if _G.Inventory then Inventory.add_item(m, l.itemId, l.count) end

                     -- Mail the seller
                     if _G.Mail then
                         Mail.send("SYSTEM", l.seller, "AH Sold: " .. l.itemId, "Your item sold for " .. l.price .. "c", {id="coin_bag", count=l.price})
                     end

                     table.remove(AuctionHouse.listings, SELECTION)
                     AuctionHouse.save()
                     play_sound(SOUND_GENERAL_COIN, m.marioObj.header.gfx.cameraToObject)
                     djui_chat_message_create("Bought " .. l.itemId)

                     -- Adjust selection if we removed the last item
                     if SELECTION > #AuctionHouse.listings then SELECTION = math.max(1, #AuctionHouse.listings) end
                else
                     play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
                     djui_chat_message_create("Not enough coins!")
                end
            end
        elseif UI_MODE == "sell" and #list > 0 then
            local item = list[SELECTION]
            if item then
                -- Hardcoded placeholder sell logic: sell 1 for 100c
                -- A real implementation would require a numeric input sub-menu (like djui_inputbox)
                local count = 1
                local price = 100

                if _G.Inventory and Inventory.remove_item(m, item.id, count) then
                    local listingId = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
                    table.insert(AuctionHouse.listings, {
                        id = listingId,
                        seller = network_get_player_text_color_string(m.playerIndex) .. "Player",
                        itemId = item.id,
                        count = count,
                        price = price
                    })
                    AuctionHouse.save()
                    play_sound(SOUND_OBJ_STOMP_AARON, m.marioObj.header.gfx.cameraToObject)
                    djui_chat_message_create("Listed 1x " .. item.id .. " for 100c")
                end
            end
        end
    end

    if close then
        UI_VISIBLE = false
    end
end

function AuctionHouse.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
        UI_MODE = "browse"
    end
end

hook_event(HOOK_ON_HUD_RENDER, ah_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, ah_ui_update)

-- Add AH to Main Menu
hook_event(HOOK_ON_LEVEL_INIT, function()
    -- We can't directly inject into the local table in system_menu/main.lua easily from here without modifying that file.
    -- But since we control the codebase, we'll patch system_menu/main.lua via bash.
end)
