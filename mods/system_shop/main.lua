-- name: System - Shop
-- description: NPC Shopkeeper system.

local SHOP_OPEN = false
local SHOP_ITEMS = {
    {id = "hookshot", price = 50},
    {id = "badge_speed", price = 100},
    {id = "badge_feather", price = 150},
    {id = "badge_health", price = 200},
    {id = "blaster", price = 300},
    {id = "totem_termite", price = 500},
}
local SELECTION = 1

-- Shopkeeper Behavior
local E_MODEL_TOAD = smlua_model_util_get_id("toad_geo")

function bhv_shopkeeper_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_TEXT
    o.oInteractionSubtype = INT_SUBTYPE_NPC
    o.oGravity = -4.0
    o.oFriction = 0.8
    o.oBuoyancy = 1.0
    o.oOpacity = 255
    o.oDamageOrCoinValue = 0 -- No dialog ID

    -- Sync
    network_init_object(o, true, nil)
end

function bhv_shopkeeper_loop(o)
    object_step(o)

    -- Interaction handled via HOOK_ON_INTERACT usually, but standard text interaction is hardcoded.
    -- We'll check distance and input manually for custom UI.
    local m = gMarioStates[0]
    if dist_between_objects(o, m.marioObj) < 150 then
        if (m.controller.buttonPressed & B_BUTTON) ~= 0 and not SHOP_OPEN then
            SHOP_OPEN = true
            SELECTION = 1
            -- Stop Mario
            set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
        end
    end
end

local id_bhvShopkeeper = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_shopkeeper_init, bhv_shopkeeper_loop)

-- Spawn Command
function on_spawn_shop(msg)
    local m = gMarioStates[0]
    local obj = spawn_sync_object(
        id_bhvShopkeeper,
        E_MODEL_TOAD,
        m.pos.x + 200 * sins(m.faceAngle.y),
        m.pos.y,
        m.pos.z + 200 * coss(m.faceAngle.y),
        nil
    )
    djui_chat_message_create("Spawned Shopkeeper")
    return true
end

hook_chat_command("spawn_shop", "Spawn a shopkeeper", on_spawn_shop)

-- UI Render
function shop_ui_render()
    if not SHOP_OPEN then return end

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()
    local cx = w / 2
    local cy = h / 2

    -- Background
    djui_hud_set_color(0, 0, 0, 200)
    djui_hud_render_rect(cx - 150, cy - 100, 300, 200)

    -- Title
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("SHOP", cx - 20, cy - 90, 1)

    -- Coins
    local coins = Inventory.get_count(gMarioStates[0], "coin_bag")
    djui_hud_set_color(255, 215, 0, 255)
    djui_hud_print_text("Coins: " .. coins, cx - 140, cy - 90, 1)

    -- Items
    local y = cy - 60
    for i, itemData in ipairs(SHOP_ITEMS) do
        local def = _G.Inventory.items[itemData.id]
        if def then
            local name = def.name
            local price = itemData.price

            if i == SELECTION then
                djui_hud_set_color(0, 255, 0, 255)
                djui_hud_print_text("> " .. name .. " (" .. price .. ")", cx - 100, y, 1)
            else
                djui_hud_set_color(200, 200, 200, 255)
                djui_hud_print_text("  " .. name .. " (" .. price .. ")", cx - 100, y, 1)
            end
            y = y + 20
        end
    end

    djui_hud_set_color(200, 200, 200, 255)
    djui_hud_print_text("A: Buy  B: Exit", cx - 60, cy + 80, 1)
end

-- UI Input
function shop_update(m)
    if m.playerIndex ~= 0 then return end
    if not SHOP_OPEN then return end

    -- Prevent movement
    if m.action ~= ACT_WAITING_FOR_DIALOG then
        set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
    end

    -- Navigation
    if (m.controller.buttonPressed & D_JPAD) ~= 0 or (m.controller.stickY < -20 and m.controller.stickY > -60) then -- Simple stick check
        -- Debounce handled by buttonPressed usually, stick needs logic. Stick to D-Pad for safety or single press
        SELECTION = SELECTION + 1
        if SELECTION > #SHOP_ITEMS then SELECTION = 1 end
    end
    if (m.controller.buttonPressed & U_JPAD) ~= 0 then
        SELECTION = SELECTION - 1
        if SELECTION < 1 then SELECTION = #SHOP_ITEMS end
    end

    -- Buy
    if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
        local itemData = SHOP_ITEMS[SELECTION]
        local coins = Inventory.get_count(m, "coin_bag")

        if coins >= itemData.price then
            if Inventory.add_item(m, itemData.id, 1) then
                Inventory.remove_item(m, "coin_bag", itemData.price)
                play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject)
                djui_chat_message_create("Bought " .. itemData.id)
            else
                play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
            end
        else
            play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
            djui_chat_message_create("Not enough coins!")
        end
    end

    -- Exit
    if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        SHOP_OPEN = false
        set_mario_action(m, ACT_IDLE, 0)
    end
end

hook_event(HOOK_ON_HUD_RENDER, shop_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, shop_update)
