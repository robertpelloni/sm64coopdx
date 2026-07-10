-- name: System - Shop
-- description: NPC Shops for purchasing items and managing economy.
-- depends: system_ui
-- depends: system_inventory
-- depends: system_reputation

_G.Shop = {}

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0
local CURRENT_SHOP = nil

Shop.registry = {
    ["general"] = {
        name = "General Store",
        items = {
            {id = "potion_health", cost = 50, reqRep = nil},
            {id = "potion_mana", cost = 50, reqRep = nil},
            {id = "mushroom", cost = 10, reqRep = nil},
            {id = "wood", cost = 5, reqRep = nil},
        }
    },
    ["toad_faction"] = {
        name = "Toad Brigade Quartermaster",
        items = {
            {id = "badge_toad_honor", cost = 500, reqRep = {faction="toads", level=100}},
            {id = "mount_yoshi", cost = 1000, reqRep = {faction="toads", level=500}},
        }
    }
}

--- Open Shop UI
function Shop.open(shopId)
    if Shop.registry[shopId] then
        CURRENT_SHOP = Shop.registry[shopId]
        UI_VISIBLE = true
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

function shop_ui_render()
    if not UI_VISIBLE or not CURRENT_SHOP then return end
    if not _G.UIToolkit then return end

    local items = {}
    for _, item in ipairs(CURRENT_SHOP.items) do
        local def = _G.Inventory and _G.Inventory.items[item.id]
        local name = def and def.name or item.id
        local tooltip = def and def.description or "No description."
        if item.reqRep then
            tooltip = tooltip .. " (Req: " .. item.reqRep.faction .. " rep " .. tostring(item.reqRep.level) .. ")"
        end

        table.insert(items, {
            id = item.id,
            name = name,
            cost = item.cost,
            reqRep = item.reqRep,
            right_text = tostring(item.cost) .. "c",
            tooltip = tooltip
        })
    end

    local renderDetails = function(x, y, selItem)
        local def = _G.Inventory and _G.Inventory.items[selItem.id]
        if def then
            djui_hud_set_color(0, 255, 255, 255)
            djui_hud_print_text(def.name, x, y, 1)

            djui_hud_set_color(200, 200, 200, 255)
            local desc = def.description or "No description."
            UIToolkit.draw_wrapped_text(desc, x, y + 40, 22, 0.8)
        end

        djui_hud_set_color(255, 255, 0, 255)
        djui_hud_print_text("Cost: " .. tostring(selItem.cost) .. " coins", x, y + 100, 0.8)

        if selItem.reqRep then
             djui_hud_set_color(255, 100, 100, 255)
             djui_hud_print_text("Requires " .. selItem.reqRep.faction .. ": " .. tostring(selItem.reqRep.level), x, y + 120, 0.8)
        end
    end

    UIToolkit.draw_menu(CURRENT_SHOP.name, items, SELECTION, SCROLL_OFFSET, renderDetails, "A: Buy  B: Close", "Purchase items and equipment with your coins here.")
end

function shop_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE or not CURRENT_SHOP then return end
    if not _G.UIToolkit then return end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, #CURRENT_SHOP.items, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, #CURRENT_SHOP.items)

    if act then
       local item = CURRENT_SHOP.items[SELECTION]
       if item then
           -- Check rep
           local canBuy = true
           if item.reqRep and _G.Reputation then
                local currentRep = Reputation.get(m, item.reqRep.faction)
                if currentRep < item.reqRep.level then
                    djui_chat_message_create("Not enough reputation!")
                    play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
                    canBuy = false
                end
           end

           if canBuy and m.numCoins >= item.cost then
               m.numCoins = m.numCoins - item.cost
               if _G.Inventory then
                   Inventory.add_item(m, item.id, 1)
               end
               play_sound(SOUND_GENERAL_COIN, m.marioObj.header.gfx.cameraToObject)
               djui_chat_message_create("Bought " .. item.id)
           elseif canBuy then
               play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
               djui_chat_message_create("Not enough coins!")
           end
       end
    end

    if close then
        UI_VISIBLE = false
        CURRENT_SHOP = nil
    end
end

-- NPC Behavior
function bhv_shopkeeper_init(obj)
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj.oInteractionSubtype = INT_SUBTYPE_NPC
    obj.hitboxRadius = 150
    obj.hitboxHeight = 150
    obj.oIntangibleTimer = 0
    obj.oGravity = 2.5
    obj.oFriction = 0.8
    obj.oBuoyancy = 1.3

    -- Assign shop ID based on BParam1
    if obj.oBehParams2ndByte == 1 then
        obj.oShopId = "toad_faction"
    else
        obj.oShopId = "general"
    end
end

function bhv_shopkeeper_loop(obj)
    local m = gMarioStates[0]

    -- Basic physics
    obj.oFaceAngleYaw = obj.oFaceAngleYaw + 0x100

    -- Distance check for interaction
    local dist = dist_between_objects(obj, m.marioObj)
    if dist < 300 then
        -- Render interaction prompt
        if not UI_VISIBLE then
            -- Simplified prompt
            -- In a real scenario, use djui to draw text in 3D space or on HUD
        end

        -- D-pad UP to interact (B_BUTTON used for UI close, so we use something else to open)
        if (m.controller.buttonPressed & D_JPAD) ~= 0 and m.action ~= ACT_WAITING_FOR_DIALOG then
             Shop.open(obj.oShopId)
        end
    end
end

-- Spawn test NPC in Castle Grounds
function shop_on_level_init()
    if gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS then
        -- Spawn General Store
        local obj = spawn_non_sync_object(
            id_bhvToadMessage,
            E_MODEL_TOAD_PLAYER,
            -1000, 260, 2000,
            bhv_shopkeeper_init,
            bhv_shopkeeper_loop
        )
        if obj then
             obj.oBehParams2ndByte = 0
             obj.header.gfx.scale.x = 2.0
             obj.header.gfx.scale.y = 2.0
             obj.header.gfx.scale.z = 2.0
        end

        -- Spawn Faction Store
        local obj2 = spawn_non_sync_object(
            id_bhvToadMessage,
            E_MODEL_TOAD_PLAYER,
            1000, 260, 2000,
            bhv_shopkeeper_init,
            bhv_shopkeeper_loop
        )
        if obj2 then
             obj2.oBehParams2ndByte = 1
             obj2.header.gfx.scale.x = 2.0
             obj2.header.gfx.scale.y = 2.0
             obj2.header.gfx.scale.z = 2.0
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, shop_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, shop_ui_update)
hook_event(HOOK_ON_LEVEL_INIT, shop_on_level_init)
