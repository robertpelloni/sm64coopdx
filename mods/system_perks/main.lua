-- name: System - Perks (Badges)
-- description: Applies passive effects based on Equipped items.

_G.Perks = {}

function perks_update(m)
    if m.playerIndex ~= 0 then return end

    local is_equipped = function(badge_id)
        local sync = gPlayerSyncTable[0]
        return sync.eq_badge_1 == badge_id or sync.eq_badge_2 == badge_id or sync.eq_badge_3 == badge_id
    end

    -- Speed Badge
    if is_equipped("badge_speed") then
        if (m.action & ACT_FLAG_MOVING) ~= 0 then
            if m.forwardVel < 50.0 then
                m.forwardVel = m.forwardVel * 1.1
            end
        end
    end

    -- Feather Badge (Low Gravity)
    if is_equipped("badge_feather") then
        if (m.action & ACT_FLAG_AIR) ~= 0 and m.vel.y < 0 then
            m.vel.y = m.vel.y * 0.8
        end
    end

    -- Health Badge (Regen)
    if is_equipped("badge_health") then
        if m.health < 0x880 and gGlobalTimer % 300 == 0 then
             m.health = m.health + 0x100
        end
    end

    -- Metal Badge (Defense + Visuals)
    if is_equipped("badge_metal") then
        m.flags = m.flags | MARIO_METAL_CAP
        if (m.flags & MARIO_METAL_CAP) ~= 0 then
             m.marioBodyState.modelState = MODEL_STATE_METAL
        end
    end

    -- Wing Badge (Triple Jump + Slow Fall)
    if is_equipped("badge_wing") then
        m.flags = m.flags | MARIO_WING_CAP
    end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, perks_update)
