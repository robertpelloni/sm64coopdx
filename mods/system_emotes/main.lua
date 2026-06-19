-- name: System - Emotes
-- description: Standard MMO character animations.
-- depends: system_ui

_G.Emotes = {}

local active_emote = nil

local emote_map = {
    wave = { action = ACT_PANTING, text = "waves to everyone.", type = "action" },
    sit = { action = ACT_START_CROUCHING, text = "sits down.", type = "action" },
    sleep = { action = ACT_START_SLEEPING, text = "goes to sleep.", type = "action" },
    dance = { action = ACT_DANCE, text = "starts dancing!", type = "action" }
}

function on_emote_command(msg)
    local m = gMarioStates[0]
    local emote = emote_map[msg]
    if emote then
        if emote.type == "action" then
            set_mario_action(m, emote.action, 0)
        elseif emote.type == "anim" then
            set_mario_action(m, ACT_IDLE, 0)
            set_mario_animation(m, emote.anim)
        end
        djui_chat_message_create(network_get_player_text_color_string(m.playerIndex) .. gNetworkPlayers[0].name .. " \\#ffffff\\" .. emote.text)
        return true
    elseif msg == "ui" then
        if _G.EmotesUI then _G.EmotesUI.toggle() end
        return true
    end
    djui_chat_message_create("Usage: /emote [wave|sit|sleep|dance|ui]")
    return true
end

hook_chat_command("emote", "Perform an emote", on_emote_command)

-- Define the UI
_G.EmotesUI = {}
local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

local menu_items = {
    { id = "wave", name = "Wave", tooltip = "Wave to everyone." },
    { id = "sit", name = "Sit", tooltip = "Sit down and relax." },
    { id = "sleep", name = "Sleep", tooltip = "Take a nap." },
    { id = "dance", name = "Dance", tooltip = "Show off your moves!" }
}

function EmotesUI.render()
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(selItem.name, x, y, 1)
        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(selItem.tooltip, x, y + 40, 22, 0.8)
    end

    UIToolkit.draw_menu("EMOTES", menu_items, SELECTION, SCROLL_OFFSET, renderDetails, "A: Use  B: Close", "Express yourself.")
end

function EmotesUI.update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, #menu_items, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, #menu_items)

    -- Handle immediate closure if player moves significantly while menu is open
    if m.forwardVel > 5 or m.action == ACT_JUMP then
         UI_VISIBLE = false
         return
    end

    if act then
        play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        local item = menu_items[SELECTION]
        if item then
            on_emote_command(item.id)
            UI_VISIBLE = false
        end
    end

    if close then
        UI_VISIBLE = false
    end
end

function EmotesUI.toggle()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

hook_event(HOOK_ON_HUD_RENDER, EmotesUI.render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, EmotesUI.update)
