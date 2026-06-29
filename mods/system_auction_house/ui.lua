-- name: System - Auction House UI
-- description: Visual UI for the global asynchronous marketplace.
-- depends: system_ui, system_auction_house

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0
local UI_MODE = "browse" -- "browse", "sell", "sell_price"

-- Dynamic Pricing State
local current_price = "100"

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
                name = name,
                right_text = tostring(listing.price) .. "c",
                tooltip = "Seller: " .. listing.seller .. "\nQuantity: " .. tostring(listing.count)
            })
        end

        if #items == 0 then
            table.insert(items, { id = "none", name = "No listings.", right_text = "", tooltip = "The market is empty." })
        end

    elseif UI_MODE == "sell" then
        title = "AUCTION HOUSE - SELL"
        footer = "A: Set Price  X: Browse Mode  B: Close"

        local inv = _G.Inventory and _G.Inventory.get_all_items(m) or {}
        for _, it in ipairs(inv) do
            table.insert(items, {
                id = it.id,
                name = it.name,
                right_text = "x" .. tostring(it.count),
                tooltip = "Select to list 1x for sale."
            })
        end

        if #items == 0 then
            table.insert(items, { id = "none", name = "Inventory empty.", right_text = "", tooltip = "You have nothing to sell." })
        end

    elseif UI_MODE == "sell_price" then
        title = "AUCTION HOUSE - SET PRICE"
        footer = "Up/Dn/L/R/Y: Type | A: Confirm | B: Cancel"
        table.insert(items, { id = "price", name = "Price: " .. current_price .. "c", tooltip = "Use D-Pad to set the price for your item." })
    end

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(selItem.name, x, y, 1.2)
        djui_hud_set_color(200, 200, 200, 255)

        if UI_MODE == "browse" then
            local l = nil
            for _, ls in ipairs(AuctionHouse.listings) do if ls.id == selItem.id then l = ls break end end
            if l then
                UIToolkit.draw_wrapped_text("Seller: " .. l.seller, x, y + 40, 25, 0.9)
                UIToolkit.draw_wrapped_text("Count: " .. tostring(l.count), x, y + 60, 25, 0.9)
                UIToolkit.draw_wrapped_text("Price: " .. tostring(l.price) .. "c", x, y + 80, 25, 0.9)
            else
                UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 40, 25, 0.9)
            end
        elseif UI_MODE == "sell" then
            UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 40, 25, 0.9)
            djui_hud_set_color(255, 255, 0, 255)
            djui_hud_print_text("Sell 1x at Market Value", x, y + 100, 0.8)
        elseif UI_MODE == "sell_price" then
            UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 40, 25, 0.9)
            djui_hud_set_color(255, 255, 0, 255)
            djui_hud_print_text("Enter price using D-Pad", x, y + 100, 0.8)
        end
    end

    UIToolkit.draw_menu(title, items, SELECTION, SCROLL_OFFSET, renderDetails, footer)
end

function ah_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    if (m.controller.buttonPressed & X_BUTTON) ~= 0 and OPEN_TIMER <= 0 then
        if UI_MODE == "browse" then UI_MODE = "sell"
        elseif UI_MODE == "sell" then UI_MODE = "browse" end
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
        play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        return
    end

    if UI_MODE == "sell_price" then
        local newText, submitted, cancelled, newTimer = UIToolkit.handle_text_input(m, current_price, OPEN_TIMER)
        current_price = newText
        OPEN_TIMER = newTimer

        if cancelled then
            UI_MODE = "sell"
            OPEN_TIMER = 5
            return
        end

        if submitted then
            local priceInt = math.floor(tonumber(current_price) or 0)
            if priceInt <= 0 then
                djui_chat_message_create("Price must be greater than 0.")
                play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
                OPEN_TIMER = 5
                return
            end

            -- Find the item we were selling
            local inv = _G.Inventory and _G.Inventory.get_all_items(m) or {}
            local item = inv[SELECTION]

            if item then
                local count = 1
                if _G.Inventory and Inventory.remove_item(m, item.id, count) then
                    local listingId = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
                    table.insert(AuctionHouse.listings, {
                        id = listingId,
                        seller = network_get_player_text_color_string(m.playerIndex) .. "Player",
                        itemId = item.id,
                        count = count,
                        price = priceInt
                    })
                    if _G.SaveManager then SaveManager.request_save() else SafeSave("AuctionHouse") end
                    play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
                    djui_chat_message_create("Listed 1x " .. item.id .. " for " .. tostring(priceInt) .. "c")
                else
                    play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
                    djui_chat_message_create("Error listing item.")
                end
            end

            UI_MODE = "sell"
            OPEN_TIMER = 5
            return
        end
        return
    end

    local list = {}
    if UI_MODE == "browse" then
        list = AuctionHouse.listings
    elseif UI_MODE == "sell" then
        list = _G.Inventory and _G.Inventory.get_all_items(m) or {}
    end

    local maxItems = #list
    if maxItems == 0 then
        if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
            UI_VISIBLE = false
            set_mario_action(m, ACT_IDLE, 0)
        end
        return
    end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act then
        if UI_MODE == "browse" and #list > 0 then
            local l = list[SELECTION]
            if l then
                if m.numCoins >= l.price then
                     m.numCoins = m.numCoins - l.price
                     if _G.Inventory then Inventory.add_item(m, l.itemId, l.count) end

                     if _G.Mail then
                         Mail.send("SYSTEM", l.seller, "AH Sold: " .. l.itemId, "Your item sold for " .. l.price .. "c", {id="coin_bag", count=l.price})
                     end

                     table.remove(AuctionHouse.listings, SELECTION)
                     if _G.SaveManager then SaveManager.request_save() else SafeSave("AuctionHouse") end
                     play_sound(SOUND_GENERAL_COIN, m.marioObj.header.gfx.cameraToObject)
                     djui_chat_message_create("Bought " .. l.itemId)

                     if SELECTION > #AuctionHouse.listings then SELECTION = math.max(1, #AuctionHouse.listings) end
                else
                     play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
                     djui_chat_message_create("Not enough coins!")
                end
            end
        elseif UI_MODE == "sell" and #list > 0 then
            UI_MODE = "sell_price"
            current_price = "100"
            OPEN_TIMER = 5
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
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
        current_price = "100"
    end
end

hook_event(HOOK_ON_HUD_RENDER, ah_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, ah_ui_update)
