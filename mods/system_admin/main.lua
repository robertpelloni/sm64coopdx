-- name: System - Admin
-- description: Administration tools for server hosts.

_G.Admin = {}

-- UI State
local ADMIN_UI_OPEN = false
local SELECTION = 1

function admin_ui_render()
    if not ADMIN_UI_OPEN then return end
    if not network_is_server() then return end

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()
    local cx = w / 2
    local cy = h / 2

    -- Background
    djui_hud_set_color(50, 0, 0, 240)
    djui_hud_render_rect(cx - 200, cy - 150, 400, 300)

    -- Header
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("ADMIN PANEL", cx - 70, cy - 140, 1)

    -- List Players
    local connectedPlayers = {}
    for i = 1, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected then
            table.insert(connectedPlayers, {idx = i, name = gNetworkPlayers[i].name})
        end
    end

    if #connectedPlayers == 0 then
        djui_hud_print_text("No players connected.", cx - 80, cy, 1)
        djui_hud_set_color(200, 200, 200, 255)
        djui_hud_print_text("B: Close", cx - 30, cy + 130, 1)
        return
    end

    -- Scroll Logic
    if SELECTION > #connectedPlayers then SELECTION = 1 end
    if SELECTION < 1 then SELECTION = #connectedPlayers end

    local y = cy - 100
    for i, p in ipairs(connectedPlayers) do
        if i == SELECTION then
            djui_hud_set_color(255, 255, 0, 255)
            djui_hud_print_text("> " .. p.name, cx - 180, y, 1)
        else
            djui_hud_set_color(200, 200, 200, 255)
            djui_hud_print_text("  " .. p.name, cx - 180, y, 1)
        end
        y = y + 25
    end

    -- Action Hint
    djui_hud_set_color(150, 150, 150, 255)
    djui_hud_print_text("A: Kick  X: Ban  Y: Teleport To", cx - 100, cy + 100, 0.8)
    djui_hud_print_text("B: Close", cx - 30, cy + 130, 1)
end

function admin_ui_update(m)
    if m.playerIndex ~= 0 then return end
    if not ADMIN_UI_OPEN then return end

    -- Lock
    if m.action ~= ACT_WAITING_FOR_DIALOG then
        set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
    end

    -- Nav
    local connectedPlayers = {}
    for i = 1, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected then
            table.insert(connectedPlayers, {idx = i, name = gNetworkPlayers[i].name})
        end
    end

    if #connectedPlayers == 0 then
        if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
            ADMIN_UI_OPEN = false
            set_mario_action(m, ACT_IDLE, 0)
        end
        return
    end

    if (m.controller.buttonPressed & D_JPAD) ~= 0 then
        SELECTION = SELECTION + 1
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
    end
    if (m.controller.buttonPressed & U_JPAD) ~= 0 then
        SELECTION = SELECTION - 1
        play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
    end

    local target = connectedPlayers[SELECTION]

    -- Kick (A)
    if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
        if network_player_kick then
            network_player_kick(target.idx)
            djui_chat_message_create("Kicked " .. target.name)
            play_sound(SOUND_OBJ_BOWSER_LAUGH, m.marioObj.header.gfx.cameraToObject)
        else
            djui_chat_message_create("Error: Kick function not available.")
        end
    end

    -- Ban (X)
    if (m.controller.buttonPressed & X_BUTTON) ~= 0 then
        if network_player_ban then
            network_player_ban(target.idx)
            djui_chat_message_create("Banned " .. target.name)
            play_sound(SOUND_OBJ_BOWSER_LAUGH, m.marioObj.header.gfx.cameraToObject)
        else
            -- If ban function missing, just kick
            if network_player_kick then
                network_player_kick(target.idx)
                djui_chat_message_create("Kicked (Ban not avail) " .. target.name)
            end
        end
    end

    -- Teleport To (Y)
    if (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        local tm = gMarioStates[target.idx]
        m.pos.x = tm.pos.x
        m.pos.y = tm.pos.y
        m.pos.z = tm.pos.z
        djui_chat_message_create("Teleported to " .. target.name)
        play_sound(SOUND_MENU_TELEPORT, m.marioObj.header.gfx.cameraToObject)
        ADMIN_UI_OPEN = false
        set_mario_action(m, ACT_IDLE, 0)
    end

    -- Close (B)
    if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        ADMIN_UI_OPEN = false
        set_mario_action(m, ACT_IDLE, 0)
    end
end

function Admin.toggle_ui()
    if not network_is_server() then
        djui_chat_message_create("Only the host can access Admin Panel.")
        return
    end
    ADMIN_UI_OPEN = not ADMIN_UI_OPEN
    SELECTION = 1
end

hook_event(HOOK_ON_HUD_RENDER, admin_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, admin_ui_update)

-- Commands
function on_admin_command(msg)
    if not network_is_server() then return false end

    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end

    local cmd = args[1]
    local targetName = args[2]

    if cmd == "ui" then
        Admin.toggle_ui()
        return true
    end

    if not targetName then
        djui_chat_message_create("Usage: /admin [kick|ban|tp] [name]")
        return true
    end

    -- Find Target
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
