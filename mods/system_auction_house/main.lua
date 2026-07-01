-- name: System - Auction House
-- description: Global asynchronous marketplace.
-- depends: system_inventory, system_mail

_G.AuctionHouse = {}
AuctionHouse.listings = {}

local SAVE_KEY = "ah_listings"

local function escape_str(s)
    if not s then return "" end
    s = string.gsub(s, ";", ",")
    s = string.gsub(s, "|", "/")
    return s
end

function AuctionHouse.load()
    local data = mod_storage_load(SAVE_KEY)
    if data and data ~= "" then
        for entry in string.gmatch(data, "([^|]+)") do
            local parts = {}
            for p in string.gmatch(entry, "([^;]+)") do table.insert(parts, p) end
            if #parts >= 5 then
                table.insert(AuctionHouse.listings, {
                    id = parts[1],
                    seller = parts[2],
                    itemId = parts[3],
                    count = tonumber(parts[4]),
                    price = tonumber(parts[5])
                })
            end
        end
    end
end

function AuctionHouse.save()
    local data = ""
    for _, l in ipairs(AuctionHouse.listings) do
        data = data .. l.id .. ";" .. escape_str(l.seller) .. ";" .. l.itemId .. ";" .. l.count .. ";" .. l.price .. "|"
    end
    mod_storage_save(SAVE_KEY, data)
end

function on_ah_command(msg)
    local m = gMarioStates[0]
    local args = {}
    for w in string.gmatch(msg, "%S+") do table.insert(args, w) end

    if args[1] == "sell" then
        if #args < 4 then
            djui_chat_message_create("Usage: /ah sell <itemId> <count> <price>")
            return true
        end
        local itemId = args[2]
        local count = math.floor(tonumber(args[3]) or 0)
        local price = math.floor(tonumber(args[4]) or 0)

        if not _G.Inventory or not _G.Inventory.items[itemId] then
            djui_chat_message_create("Invalid item.")
            return true
        end

        if count <= 0 then
            djui_chat_message_create("Count must be a positive number.")
            return true
        end

        if not price or price <= 0 then
            djui_chat_message_create("Price must be a positive number.")
            return true
        end

        if price <= 0 then
            djui_chat_message_create("Price must be a positive number.")
            return true
        end

        if _G.Inventory and Inventory.remove_item(m, itemId, count) then
            local listingId = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
            table.insert(AuctionHouse.listings, {
                id = listingId,
                seller = network_get_player_text_color_string(m.playerIndex) .. "Player", -- simplified
                itemId = itemId,
                count = count,
                price = price
            })
            if _G.SaveManager then SaveManager.request_save() else SafeSave("AuctionHouse") end
            djui_chat_message_create("Listed " .. count .. "x " .. itemId .. " for " .. price .. "c")
        else
            djui_chat_message_create("Not enough " .. itemId)
        end
        return true
    end

    if args[1] == "buy" then
         -- Buying is best done via UI, but for command testing:
         local listingId = args[2]
         if not listingId then return true end

         for i, l in ipairs(AuctionHouse.listings) do
             if l.id == listingId then
                 if m.numCoins >= l.price then
                     m.numCoins = m.numCoins - l.price
                     if _G.Inventory then
                         Inventory.add_item(m, l.itemId, l.count)
                     end

                     -- Send coins to seller via mail
                     if _G.Mail then
                         Mail.send("SYSTEM", l.seller, "AH Sold: " .. l.itemId, "Your item sold for " .. l.price .. "c", {id="coin_bag", count=l.price})
                     end

                     table.remove(AuctionHouse.listings, i)
                     if _G.SaveManager then SaveManager.request_save() else SafeSave("AuctionHouse") end
                     djui_chat_message_create("Bought " .. l.itemId)
                     return true
                 else
                     djui_chat_message_create("Not enough coins!")
                     return true
                 end
             end
         end
         djui_chat_message_create("Listing not found.")
         return true
    end

    return true
end

-- Init
function ah_init()
    if network_is_server() then
        AuctionHouse.load()
    end
end

hook_chat_command("ah", "Auction House (sell <id> <count> <price> | buy <id>)", on_ah_command)
hook_event(HOOK_ON_LEVEL_INIT, ah_init)
