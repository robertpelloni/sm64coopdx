-- name: System - Combat
-- description: Health, Mana, and Damage calculation.

_G.Combat = {}

local HP_MAX_DEFAULT = 8 * 4 -- 8 wedges * 4 quarters = 32
local MANA_MAX_DEFAULT = 100
local MANA_REGEN = 0.5 -- Per frame

function Combat.use_mana(m, amount)
    local sTable = gPlayerSyncTable[m.playerIndex]
    local current = sTable.mana or MANA_MAX_DEFAULT

    if current >= amount then
        sTable.mana = current - amount
        return true
    else
        djui_chat_message_create("Not enough Mana!")
        play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
        return false
    end
end

function combat_update(m)
    if m.playerIndex ~= 0 then return end
    local sTable = gPlayerSyncTable[m.playerIndex]

    -- Init
    if not sTable.mana then sTable.mana = MANA_MAX_DEFAULT end
    if not sTable.maxMana then sTable.maxMana = MANA_MAX_DEFAULT end

    -- Regen
    if sTable.mana < sTable.maxMana then
        sTable.mana = sTable.mana + MANA_REGEN
        if sTable.mana > sTable.maxMana then sTable.mana = sTable.maxMana end
    end

    -- Interaction / Damage Logic
    -- In standard SM64, damage is handled by interact_player.
    -- We can hook HOOK_ON_PVP_ATTACK (custom hook usually) or similar.
    -- For Mob kills, we need to detect when an object dies.
    -- Typically involves checking obj.oInteractStatus or obj.oAction in a loop.

    -- Simple Mob Kill Detection
    -- Check nearest object? No, too expensive.
    -- Ideally, we hook `obj_update`? Not available.
    -- We can check `m.interactObj` in `HOOK_MARIO_UPDATE`?

    if m.interactObj then
        local o = m.interactObj
        -- Check if enemy and dead
        if (o.oInteractStatus & INT_STATUS_INTERACTED) ~= 0 then
            if (o.oInteractStatus & INT_STATUS_WAS_ATTACKED) ~= 0 then
                -- Check if dead (generic check)
                if o.oHealth <= 0 and (o.oInteractType & INTERACT_COMBAT) ~= 0 then
                    -- Grant XP (if Progression loaded)
                    if _G.Progression then
                        Progression.add_xp(m, 50) -- Flat XP for now
                    end
                end
            end
        end
    end
end

hook_event(HOOK_MARIO_UPDATE, combat_update)

-- HUD
function combat_hud()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    if not sTable.mana then return end

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()

    -- Mana Bar (Blue)
    local barW = 100
    local barH = 10
    local x = w - barW - 20
    local y = h - 60 -- Above Boost meter

    djui_hud_set_color(0, 0, 0, 150)
    djui_hud_render_rect(x, y, barW, barH)

    local fill = (sTable.mana / sTable.maxMana) * barW
    djui_hud_set_color(50, 150, 255, 200)
    djui_hud_render_rect(x, y, fill, barH)

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Mana", x, y - 20, 1)
end

hook_event(HOOK_ON_HUD_RENDER, combat_hud)
