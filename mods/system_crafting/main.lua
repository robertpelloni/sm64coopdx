-- name: System - Crafting
-- description: Crafting system for creating items from resources using UIToolkit.

_G.Crafting = {}
_G.Crafting.recipes = {}

-- Define Recipe
function Crafting.define_recipe(id, resultId, amount, ingredients)
    _G.Crafting.recipes[id] = {
        result = resultId,
        amount = amount,
        ingredients = ingredients -- Table of {id=itemId, count=num}
    }
end

-- Craft Logic
function Crafting.craft(m, recipeId)
    local recipe = _G.Crafting.recipes[recipeId]
    if not recipe then return false end

    -- Check Ingredients
    for _, ing in ipairs(recipe.ingredients) do
        local count = Inventory.get_count(m, ing.id)
        if count < ing.count then
            djui_chat_message_create("Missing ingredients: " .. ing.id)
            play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
            return false
        end
    end

    -- Consume Ingredients
    for _, ing in ipairs(recipe.ingredients) do
        Inventory.remove_item(m, ing.id, ing.count)
    end

    -- Add Result
    Inventory.add_item(m, recipe.result, recipe.amount)

    djui_chat_message_create("Crafted " .. recipe.amount .. "x " .. recipe.result)
    play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject)
    return true
end

-- UI
local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function crafting_ui_render()
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local list = {}
    for id, r in pairs(_G.Crafting.recipes) do
        local resName = r.result
        if _G.Inventory and _G.Inventory.items[r.result] then
            resName = _G.Inventory.items[r.result].name
        end
        table.insert(list, {id=id, r=r, name=resName})
    end
    table.sort(list, function(a,b) return a.id < b.id end)

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(0, 255, 255, 255)
        djui_hud_print_text(selItem.name, x, y, 1)

        local r = selItem.r
        local ingY = y + 40
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text("Requires:", x, ingY, 1)
        ingY = ingY + 20

        for _, ing in ipairs(r.ingredients) do
            local has = Inventory.get_count(gMarioStates[0], ing.id)
            local name = ing.id
            if _G.Inventory and _G.Inventory.items[ing.id] then name = _G.Inventory.items[ing.id].name end

            if has >= ing.count then
                djui_hud_set_color(0, 255, 0, 255)
            else
                djui_hud_set_color(255, 0, 0, 255)
            end
            djui_hud_print_text(name .. ": " .. has .. "/" .. ing.count, x, ingY, 0.8)
            ingY = ingY + 15
        end
    end

    UIToolkit.draw_menu("CRAFTING", list, SELECTION, SCROLL_OFFSET, renderDetails, "A: Craft  B: Close")
end

function crafting_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local list = {}
    for id, r in pairs(_G.Crafting.recipes) do
        table.insert(list, {id=id, r=r})
    end
    table.sort(list, function(a,b) return a.id < b.id end)

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, #list, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, #list)

    if act then
        local item = list[SELECTION]
        if item then
            Crafting.craft(m, item.id)
        end
    end

    if close then
        UI_VISIBLE = false
    end
end

function Crafting.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

function Crafting.close_ui()
    UI_VISIBLE = false
end

hook_event(HOOK_ON_HUD_RENDER, crafting_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, crafting_ui_update)

-- Physical Crafting Table Behavior
local E_MODEL_CRAFTING_TABLE = E_MODEL_WOODEN_SIGNPOST -- Placeholder

function bhv_crafting_table_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_TEXT
    o.oInteractionSubtype = INT_SUBTYPE_NPC
    o.oGravity = -4.0
    o.oFriction = 0.8
    o.oBuoyancy = 1.0
    o.oOpacity = 255
    o.oDamageOrCoinValue = 0
end

function bhv_crafting_table_loop(o)
    cur_obj_update_floor_and_walls()
    cur_obj_move_standard(-78)
    local m = gMarioStates[0]
    if dist_between_objects(o, m.marioObj) < 150 then
        -- Optional: Draw "Press B to Craft" hint
        if (m.controller.buttonPressed & B_BUTTON) ~= 0 and not UI_VISIBLE then
            Crafting.toggle_ui()
        end
    end
end

local id_bhvCraftingTable = hook_behavior(nil, OBJ_LIST_GENACTOR, false, bhv_crafting_table_init, bhv_crafting_table_loop)

-- Command to spawn a table (Host/Dev)
hook_chat_command("spawn_crafting_table", "Spawn a physical crafting table", function()
    if network_is_server() then
        local m = gMarioStates[0]
        spawn_sync_object(
            id_bhvCraftingTable,
            E_MODEL_CRAFTING_TABLE,
            m.pos.x + 200 * sins(m.faceAngle.y),
            m.pos.y,
            m.pos.z + 200 * coss(m.faceAngle.y),
            nil
        )
        djui_chat_message_create("Spawned Crafting Table.")
    else
        djui_chat_message_create("Only Host can spawn world objects.")
    end
    return true
end)

-- Open via command for convenience
hook_chat_command("craft", "Open crafting menu", function()
    Crafting.toggle_ui()
    return true
end)
