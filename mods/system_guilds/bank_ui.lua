-- name: System - Guild Bank UI
-- description: Visual UI for the guild storage system.
-- depends: system_ui, system_guilds

_G.GuildBankUI = {}

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0
local UI_MODE = "withdraw" -- "withdraw" or "deposit"

function GuildBankUI.render()
    if not UI_VISIBLE then return end
    if not _G.GuildBank or not _G.UIToolkit then return end

    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]
    local guildName = sTable.guildName

    if not guildName then
        UI_VISIBLE = false
        return
    end

    local items = {}
    local title = ""
    local footer = ""

    if UI_MODE == "withdraw" then
        title = "GUILD BANK - " .. string.upper(guildName)
        footer = "A: Withdraw  X: Deposit Mode  B: Close"

        local bankItems = GuildBank.get_items(guildName)
        for _, bItem in ipairs(bankItems) do
            local def = _G.Inventory and _G.Inventory.items[bItem.id]
            local name = def and def.name or bItem.id
            table.insert(items, {
                id = bItem.id,
                name = name,
                right_text = "x" .. tostring(bItem.count),
                tooltip = def and def.description or "No description."
            })
        end
        if #items == 0 then
            table.insert(items, { id = "none", name = "Bank empty.", right_text = "", tooltip = "The guild bank has no items." })
        end

    elseif UI_MODE == "deposit" then
        title = "GUILD BANK - DEPOSIT"
        footer = "A: Deposit  X: Withdraw Mode  B: Close"

        local raw_items = _G.Inventory and _G.Inventory.get_all_items(m) or {}
        for _, item in ipairs(raw_items) do
            local def = _G.Inventory.items[item.id]
            table.insert(items, {
                id = item.id,
                name = def and def.name or item.id,
                right_text = "x" .. tostring(item.count),
                tooltip = "Select to deposit 1x into the guild bank."
            })
        end
        if #items == 0 then
            table.insert(items, { id = "none", name = "Inventory empty.", right_text = "", tooltip = "You have nothing to deposit." })
        end
    end

    local renderDetails = function(x, y, selItem)
        if selItem.id == "none" then return end

        local def = _G.Inventory and _G.Inventory.items[selItem.id]
        djui_hud_set_color(0, 255, 255, 255)
        djui_hud_print_text(def and def.name or selItem.id, x, y, 1.2)

        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(def and def.description or "", x, y + 40, 25, 0.9)

        if UI_MODE == "withdraw" then
            djui_hud_set_color(150, 255, 150, 255)
            UIToolkit.draw_wrapped_text("Press A to withdraw 1x", x, y + 100, 25, 0.8)
        elseif UI_MODE == "deposit" then
            djui_hud_set_color(150, 255, 150, 255)
            UIToolkit.draw_wrapped_text("Press A to deposit 1x", x, y + 100, 25, 0.8)
        end
    end

    UIToolkit.draw_menu(title, items, SELECTION, SCROLL_OFFSET, renderDetails, footer, "Shared storage for guild members.")
end

function GuildBankUI.update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local sTable = gPlayerSyncTable[m.playerIndex]
    local guildName = sTable.guildName
    if not guildName then
        UI_VISIBLE = false
        set_mario_action(m, ACT_IDLE, 0)
        return
    end

    if (m.controller.buttonPressed & X_BUTTON) ~= 0 then
        if UI_MODE == "withdraw" then UI_MODE = "deposit" else UI_MODE = "withdraw" end
        SELECTION = 1
        SCROLL_OFFSET = 0
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
        return
    end

    local maxItems = 1
    local list = {}
    if UI_MODE == "withdraw" then
        list = GuildBank.get_items(guildName)
        maxItems = #list > 0 and #list or 1
    else
        list = _G.Inventory and _G.Inventory.get_all_items(m) or {}
        maxItems = #list > 0 and #list or 1
    end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, maxItems, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, maxItems)

    if act and #list > 0 then
        local item = list[SELECTION]
        if item and item.id and item.id ~= "none" then
            if UI_MODE == "withdraw" then
                if GuildBank.withdraw(m, item.id, 1) then
                    play_sound(SOUND_GENERAL_COIN, m.marioObj.header.gfx.cameraToObject)
                else
                    play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
                end
            elseif UI_MODE == "deposit" then
                if _G.Inventory and Inventory.remove_item(m, item.id, 1) then
                    if GuildBank.deposit(m, item.id, 1) then
                        play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
                    else
                        -- Revert if deposit failed to send (e.g., no guild)
                        Inventory.add_item(m, item.id, 1)
                        play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
                    end
                else
                    djui_chat_message_create("Not enough " .. item.id .. " to deposit.")
                    play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
                end
            end

            -- Adjust selection if item is completely removed from list
            local newList = (UI_MODE == "withdraw") and GuildBank.get_items(guildName) or (_G.Inventory and _G.Inventory.get_all_items(m) or {})
            if SELECTION > #newList then SELECTION = math.max(1, #newList) end
        end
    end

    if close then
        UI_VISIBLE = false
    end
end

function GuildBankUI.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
        UI_MODE = "withdraw"
    end
end

hook_event(HOOK_ON_HUD_RENDER, GuildBankUI.render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, GuildBankUI.update)
