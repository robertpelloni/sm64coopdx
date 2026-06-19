-- name: System - Inventory UI
-- description: Visual menu for managing the Universal Inventory.
-- depends: system_ui, system_inventory

_G.InventoryUI = {}

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function InventoryUI.render()
    if not UI_VISIBLE then return end
    if not _G.Inventory or not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local itemsList = {}

    -- Build list from inventory data
    for itemId, count in pairs(Inventory.data) do
        if count > 0 then
            local def = Inventory.items[itemId]
            if def then
                table.insert(itemsList, {
                    id = itemId,
                    name = def.name,
                    right_text = "x" .. tostring(count),
                    tooltip = def.description,
                    def = def
                })
            else
                -- Fallback for unregistered items
                table.insert(itemsList, {
                    id = itemId,
                    name = itemId,
                    right_text = "x" .. tostring(count),
                    tooltip = "Unknown Item",
                    def = nil
                })
            end
        end
    end

    -- Sort alphabetically
    table.sort(itemsList, function(a, b) return a.name < b.name end)

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(selItem.name, x, y, 1.2)

        local rColor = "\\#FFFFFF\\"
        if selItem.def and selItem.def.rarity then
            if selItem.def.rarity == "Common" then rColor = "\\#AAAAAA\\"
            elseif selItem.def.rarity == "Rare" then rColor = "\\#0088FF\\"
            elseif selItem.def.rarity == "Epic" then rColor = "\\#8800FF\\"
            elseif selItem.def.rarity == "Legendary" then rColor = "\\#FF8800\\"
            end
            djui_hud_set_color(200, 200, 200, 255)
            UIToolkit.draw_wrapped_text("Rarity: " .. rColor .. selItem.def.rarity .. "\\#FFFFFF\\", x, y + 25, 30, 0.8)
        end

        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 50, 25, 0.9)

        if selItem.def and selItem.def.use then
            djui_hud_set_color(100, 255, 100, 255)
            djui_hud_print_text("Press A to Use", x, y + 120, 0.8)
        end
    end

    UIToolkit.draw_menu("INVENTORY", itemsList, SELECTION, SCROLL_OFFSET, renderDetails, "A: Use/Equip  B: Close", "Manage all your collected items and resources.")
end

function InventoryUI.update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local itemsList = {}
    for itemId, count in pairs(Inventory.data) do
        if count > 0 then table.insert(itemsList, itemId) end
    end
    table.sort(itemsList)
    local maxItems = #itemsList

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act and maxItems > 0 then
        local selId = itemsList[SELECTION]
        local def = Inventory.items[selId]
        if def and def.use then
            local success = def.use(m)
            if success then
                Inventory.remove_item(m, selId, 1)
                play_sound(SOUND_GENERAL_COIN, m.marioObj.header.gfx.cameraToObject)
                -- If we used the last one, adjust selection
                if Inventory.data[selId] == nil or Inventory.data[selId] <= 0 then
                    if SELECTION > maxItems - 1 then SELECTION = math.max(1, maxItems - 1) end
                end
            else
                play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
            end
        else
            play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
            djui_chat_message_create("This item cannot be used directly.")
        end
    end

    if close then
        UI_VISIBLE = false
    end
end

function Inventory.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

hook_event(HOOK_ON_HUD_RENDER, InventoryUI.render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, InventoryUI.update)
