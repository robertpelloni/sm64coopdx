-- name: System - Admin
-- description: Administration tools for server hosts using UIToolkit.

_G.Admin = {}

-- UI State
local ADMIN_UI_OPEN = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function admin_ui_render()
    if not ADMIN_UI_OPEN then return end
    if not network_is_server() then return end
    if not _G.UIToolkit then return end

    local connectedPlayers = {}
    for i = 1, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected then
            table.insert(connectedPlayers, {
                idx = i,
                name = gNetworkPlayers[i].name,
                tooltip = "Global Index: " .. tostring(gNetworkPlayers[i].globalIndex)
            })
        end
    end

    if #connectedPlayers == 0 then
        table.insert(connectedPlayers, { name = "No players connected.", tooltip = "Wait for others to join.", idx = -1 })
    end

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(255, 255, 255, 255)
        _G.UIToolkit.draw_wrapped_text(selItem.tooltip, x, y, 200, 1.0)

        if selItem.idx ~= -1 then
             djui_hud_set_color(255, 100, 100, 255)
             djui_hud_print_text("A: Kick  X: Ban  Y: Teleport", x, y + 40, 0.8)
        end
    end

    _G.UIToolkit.draw_menu("ADMIN PANEL", connectedPlayers, SELECTION, SCROLL_OFFSET, renderDetails, "A: Kick X: Ban Y: TP B: Close", "Manage connected players.")
end

function admin_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not ADMIN_UI_OPEN or not network_is_server() then return end

    if m.action ~= ACT_WAITING_FOR_DIALOG then
        set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
    end

    local connectedPlayers = {}
    for i = 1, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected then
            table.insert(connectedPlayers, {idx = i, name = gNetworkPlayers[i].name})
        end
    end
    if #connectedPlayers == 0 then
        table.insert(connectedPlayers, { name = "No players connected.", idx = -1 })
    end

    local sel, timer, act, close = _G.UIToolkit.handle_input(m, SELECTION, #connectedPlayers, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = _G.UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, #connectedPlayers)

    if act then
        local p = connectedPlayers[SELECTION]
        if p and p.idx ~= -1 then
             network_player_kick(p.idx)
             djui_chat_message_create("Kicked player " .. p.name)
             play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        end
    end

    if (m.controller.buttonPressed & X_BUTTON) ~= 0 then
        local p = connectedPlayers[SELECTION]
        if p and p.idx ~= -1 then
             if network_player_ban then network_player_ban(p.idx) else network_player_kick(p.idx) end
             djui_chat_message_create("Banned player " .. p.name)
             play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        end
    end

    if (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        local p = connectedPlayers[SELECTION]
        if p and p.idx ~= -1 then
             local tm = gMarioStates[p.idx]
             m.pos.x = tm.pos.x
             m.pos.y = tm.pos.y
             m.pos.z = tm.pos.z
             djui_chat_message_create("Teleported to " .. p.name)
             play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        end
    end

    if close then
        ADMIN_UI_OPEN = false
        set_mario_action(m, ACT_IDLE, 0)
    end
end

function Admin.toggle_ui()
    if not network_is_server() then return end
    ADMIN_UI_OPEN = not ADMIN_UI_OPEN
    if ADMIN_UI_OPEN then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
        set_mario_action(gMarioStates[0], ACT_WAITING_FOR_DIALOG, 0)
    else
        set_mario_action(gMarioStates[0], ACT_IDLE, 0)
    end
end

function on_admin_command(msg)
    if not network_is_server() then
        djui_chat_message_create("Only the host can use admin commands.")
        return true
    end

    local args = {}
    for w in string.gmatch(msg, "%S+") do table.insert(args, w) end

    if args[1] == "ui" or not args[1] then
        Admin.toggle_ui()
        return true
    end

    local cmd = args[1]
    local targetName = args[2]

    if not targetName then
        djui_chat_message_create("Usage: /admin [ui|kick|ban|tp] [name]")
        return true
    end

    local targetIdx = -1
    for i = 1, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected and gNetworkPlayers[i].name == targetName then
            targetIdx = i
            break
        end
    end

    if targetIdx == -1 then
        djui_chat_message_create("Player not found.")
        return true
    end

    if cmd == "kick" then
        network_player_kick(targetIdx)
        djui_chat_message_create("Kicked " .. targetName)
    elseif cmd == "ban" then
        if network_player_ban then network_player_ban(targetIdx) else network_player_kick(targetIdx) end
        djui_chat_message_create("Banned " .. targetName)
    elseif cmd == "tp" then
        local m = gMarioStates[0]
        local tm = gMarioStates[targetIdx]
        m.pos.x = tm.pos.x
        m.pos.y = tm.pos.y
        m.pos.z = tm.pos.z
        djui_chat_message_create("Teleported to " .. targetName)
    end
    return true
end

hook_chat_command("admin", "Admin tools", on_admin_command)
hook_event(HOOK_ON_HUD_RENDER, admin_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, admin_ui_update)
