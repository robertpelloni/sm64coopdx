-- name: System - Combat (Balance)
-- description: Mana and Cooldown management for abilities.

_G.Combat = {}
_G.Combat.cooldowns = {} -- Local tracking: {abilityId = frames}

local MANA_MAX = 100
local MANA_REGEN = 0.5 -- Per frame

function Combat.use_mana(m, amount)
    if m.playerIndex ~= 0 then return false end -- Local only logic for resource consumption

    local sTable = gPlayerSyncTable[0]
    if not sTable.mana then sTable.mana = MANA_MAX end

    if sTable.mana >= amount then
        sTable.mana = sTable.mana - amount
        return true
    end

    play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
    return false
end

function Combat.start_cooldown(m, abilityId, frames)
    if m.playerIndex ~= 0 then return end
    _G.Combat.cooldowns[abilityId] = frames
end

function Combat.is_on_cooldown(m, abilityId)
    if m.playerIndex ~= 0 then return false end
    local cd = _G.Combat.cooldowns[abilityId]
    return (cd and cd > 0)
end

function combat_update(m)
    if m.playerIndex ~= 0 then return end

    local sTable = gPlayerSyncTable[0]
    if not sTable.mana then sTable.mana = MANA_MAX end

    -- Regen Mana
    if sTable.mana < MANA_MAX then
        sTable.mana = sTable.mana + MANA_REGEN
        if sTable.mana > MANA_MAX then sTable.mana = MANA_MAX end
    end

    -- Update Cooldowns
    for id, timer in pairs(_G.Combat.cooldowns) do
        if timer > 0 then
            _G.Combat.cooldowns[id] = timer - 1
        end
    end
end

function combat_hud()
    local sTable = gPlayerSyncTable[0]
    if not sTable.mana then return end

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()

    local barW = 100
    local barH = 10
    local x = 20
    local y = h - 40

    -- Bg
    djui_hud_set_color(0, 0, 0, 150)
    djui_hud_render_rect(x, y, barW, barH)

    -- Fill
    local fill = (sTable.mana / MANA_MAX) * barW
    djui_hud_set_color(100, 0, 200, 200) -- Purple for Mana
    djui_hud_render_rect(x, y, fill, barH)

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Mana", x, y - 20, 1)

    -- Draw Cooldowns?
    -- Just text list for now above bar
    local cy = y - 40
    for id, timer in pairs(_G.Combat.cooldowns) do
        if timer > 0 then
            local sec = math.ceil(timer / 30)
            djui_hud_print_text(id .. ": " .. sec, x, cy, 1)
            cy = cy - 20
        end
    end
end

hook_event(HOOK_MARIO_UPDATE, combat_update)
hook_event(HOOK_ON_HUD_RENDER, combat_hud)
