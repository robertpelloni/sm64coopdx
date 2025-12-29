-- name: System - PvP
-- description: Player vs Player flagging.

function on_pvp_toggle(msg)
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[0]

    if sTable.pvpFlag then
        sTable.pvpFlag = false
        djui_chat_message_create("PvP Disabled")
    else
        sTable.pvpFlag = true
        djui_chat_message_create("PvP Enabled")
    end
    return true
end

hook_chat_command("pvp", "Toggle PvP mode", on_pvp_toggle)

function pvp_nametag_render()
    for i = 1, MAX_PLAYERS - 1 do
        local m = gMarioStates[i]
        if m.marioBodyState.action & ACT_FLAG_ACTIVE ~= 0 then
            local sTable = gPlayerSyncTable[i]
            if sTable and sTable.pvpFlag then
                local pos = {x = m.pos.x, y = m.pos.y + 240, z = m.pos.z}
                local out = {x = 0, y = 0, z = 0}

                if djui_hud_world_pos_to_screen_pos(pos, out) then
                    local text = "[PvP]"
                    local width = djui_hud_measure_text(text)
                    djui_hud_set_color(255, 50, 50, 255) -- Red
                    djui_hud_print_text(text, out.x - width/2, out.y, 1)
                end
            end
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, pvp_nametag_render)

-- Hook Interaction to prevent damage if not PvP?
-- sm64coopdx usually has global PVP settings.
-- We can enforce it:
function allow_pvp_attack(m, victim)
    -- This hook might not exist in all versions, but `HOOK_ALLOW_PVP_ATTACK` is standard in some forks.
    -- If it doesn't exist, we can't block it easily without `obj_check_attacks` override in C.
    -- Assuming `HOOK_ALLOW_PVP_ATTACK` exists (mapped to a value, e.g. 25 or similar).
    -- If not, this is just visual flagging.

    local sAttacker = gPlayerSyncTable[m.playerIndex]
    local sVictim = gPlayerSyncTable[victim.playerIndex]

    if sAttacker.pvpFlag and sVictim.pvpFlag then
        return true
    end
    return false
end

-- If hook exists:
if HOOK_ALLOW_PVP_ATTACK then
    hook_event(HOOK_ALLOW_PVP_ATTACK, allow_pvp_attack)
end
