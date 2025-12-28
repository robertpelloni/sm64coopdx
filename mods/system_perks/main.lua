-- name: System - Perks (Badges)
-- description: Applies passive effects based on Inventory items.

function perks_update(m)
    -- We assume Inventory is loaded
    if not Inventory then return end

    -- Speed Badge
    if Inventory.get_count(m, "badge_speed") > 0 then
        -- Safe Speed Boost: Only apply if below a threshold to prevent exponential runaway
        -- Standard running speed is around 32-48.
        if (m.action & ACT_FLAG_MOVING) ~= 0 then
            if m.forwardVel < 50.0 then
                m.forwardVel = m.forwardVel * 1.1
            end
        end
    end

    -- Feather Badge (Low Gravity)
    if Inventory.get_count(m, "badge_feather") > 0 then
        if (m.action & ACT_FLAG_AIR) ~= 0 and m.vel.y < 0 then
            m.vel.y = m.vel.y * 0.8 -- Fall slower
        end
    end

    -- Health Badge (Regen)
    if Inventory.get_count(m, "badge_health") > 0 then
        -- Use global gGlobalTimer, not m.globalTimer
        if m.health < 0x880 and gGlobalTimer % 300 == 0 then -- Every 10 seconds
             m.health = m.health + 0x100
        end
    end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, perks_update)
