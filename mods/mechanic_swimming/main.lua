-- name: Mechanic - Swimming Overhaul
-- description: Adds an Oxygen meter and faster underwater dashes.

local OXYGEN_MAX = 30 * 30 -- 30 seconds at 30 fps
local OXYGEN_DRAIN = 1
local OXYGEN_REGEN = 5
local DROWN_DAMAGE = 1 -- 1 quarter wedge per second
local DASH_SPEED = 60.0
local DASH_COST = 30 * 2 -- Costs 2 seconds of oxygen to dash

function swimming_update(m)
    if m.playerIndex ~= 0 then return end

    local sTable = gPlayerSyncTable[m.playerIndex]
    if not sTable.oxygen then sTable.oxygen = OXYGEN_MAX end

    -- Detect if fully underwater (head below water level)
    -- m.waterLevel is the surface Y.
    -- Mario's head is approx m.pos.y + 120
    local isUnderwater = (m.pos.y + 120) < m.waterLevel

    -- Drain/Regen Logic
    if isUnderwater then
        sTable.oxygen = sTable.oxygen - OXYGEN_DRAIN
        if sTable.oxygen <= 0 then
            sTable.oxygen = 0
            -- Drowning Damage (every 1 second)
            if gGlobalTimer % 30 == 0 then
                m.health = m.health - 256 -- 1 wedge
                play_sound(SOUND_MARIO_DROWNING, m.marioObj.header.gfx.cameraToObject)

                if m.health <= 255 then
                    -- Trigger death action if out of health
                    -- The engine usually handles this if health drops, but we force it if needed.
                    -- Engine drops health automatically in certain states, but we are overriding.
                end
            end
        end

        -- Dash Logic (Requires some Oxygen)
        -- In water, A button swims. Let's use X for Dash.
        if (m.action & ACT_GROUP_MASK) == ACT_GROUP_SUBMERGED then
            if (m.controller.buttonPressed & X_BUTTON) ~= 0 and sTable.oxygen > DASH_COST then
                sTable.oxygen = sTable.oxygen - DASH_COST
                m.forwardVel = DASH_SPEED
                m.vel.y = m.vel.y + sins(m.faceAngle.x) * DASH_SPEED -- Apply pitch if possible, but basic forward is fine
                play_sound(SOUND_ACTION_SWIM, m.marioObj.header.gfx.cameraToObject)
                -- Spawn bubbles
                m.particleFlags = m.particleFlags | PARTICLE_BUBBLE
            end
        end

    else
        -- Regenerate when head is above water
        if sTable.oxygen < OXYGEN_MAX then
            sTable.oxygen = sTable.oxygen + OXYGEN_REGEN
            if sTable.oxygen > OXYGEN_MAX then sTable.oxygen = OXYGEN_MAX end
        end
    end

    -- Sync Max for UI
    sTable.maxOxygen = OXYGEN_MAX
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, swimming_update)

-- UI
function oxygen_hud()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    if not sTable.oxygen then return end

    -- Only show if not full
    if sTable.oxygen >= OXYGEN_MAX then return end

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()

    local barW = 150
    local barH = 10
    local x = w / 2 - barW / 2
    local y = h - 40 -- Bottom center

    -- Background
    djui_hud_set_color(0, 0, 0, 150)
    djui_hud_render_rect(x, y, barW, barH)

    -- Fill (Light Blue)
    local ratio = sTable.oxygen / OXYGEN_MAX
    djui_hud_set_color(0, 200, 255, 200)
    djui_hud_render_rect(x, y, barW * ratio, barH)

    -- Flash Red if drowning
    if sTable.oxygen == 0 and (gGlobalTimer % 15 < 7) then
        djui_hud_set_color(255, 0, 0, 255)
        djui_hud_print_text("OXYGEN!", x + barW/2 - 30, y - 20, 1)
    else
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text("O2", x + barW/2 - 10, y - 20, 0.8)
    end
end

hook_event(HOOK_ON_HUD_RENDER, oxygen_hud)
