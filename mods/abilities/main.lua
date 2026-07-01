-- name: Mechanic - Modular Abilities
-- description: Custom scalable movement abilities (Ground Pound Jump, Enhanced Long Jump, Dive Slide).

_G.Abilities = {}

function abilities_on_mario_update(m)
    if m.playerIndex ~= 0 then return end

    -- Scalable Ground Pound Jump
    if m.action == ACT_GROUND_POUND_LAND then
        if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
            set_mario_action(m, ACT_TRIPLE_JUMP, 0)
            m.vel.y = 80.0 -- Enhanced height
            play_sound(SOUND_MARIO_YAHOO, m.marioObj.header.gfx.cameraToObject)
        end
    end

    -- Enhanced Long Jump
    if m.action == ACT_LONG_JUMP and m.actionState == 0 then
        -- Apply the agility bonus once at the start of the long jump
        if m.forwardVel > 0 then
            local agi = 1.0
            if _G.Progression and _G.Progression.get_stat then
                agi = 1.0 + (_G.Progression.get_stat(m, "agi") * 0.05)
            end
            m.forwardVel = m.forwardVel * agi
            m.actionState = 1 -- Prevent applying multiple times
        end
    end

    -- Dive Slide continuous momentum (capped speed)
    if m.action == ACT_DIVE_SLIDE then
        if (m.controller.buttonDown & B_BUTTON) ~= 0 then
            -- Slowly increase speed, but cap it at a reasonable maximum
            if m.forwardVel < 60.0 then
                m.forwardVel = m.forwardVel + 2.0
            end
        end
    end

    -- Mid-Air Double Jump
    local sTable = gPlayerSyncTable[m.playerIndex]
    if (m.action & ACT_FLAG_AIR) == 0 then
        sTable.has_double_jumped = false
    else
        -- We are in the air
        if (m.action == ACT_FREEFALL or m.action == ACT_JUMP or m.action == ACT_DOUBLE_JUMP) then
            if not sTable.has_double_jumped and (m.controller.buttonPressed & A_BUTTON) ~= 0 then
                m.vel.y = 50.0
                set_mario_action(m, ACT_DOUBLE_JUMP, 0)
                play_sound(SOUND_MARIO_YAHOO, m.marioObj.header.gfx.cameraToObject)
                sTable.has_double_jumped = true

                -- Update Quest
                if _G.Quest then
                    Quest.update_progress(m, "acrobat_training", 1)
                end
            end
        end
    end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, abilities_on_mario_update)
