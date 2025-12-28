-- name: System - Perks (Badges)
-- description: Applies passive effects based on Inventory items.

function perks_update(m)
    -- We assume Inventory is loaded
    if not Inventory then return end

    -- Speed Badge
    if Inventory.get_count(m, "badge_speed") > 0 then
        if (m.action & ACT_FLAG_MOVING) ~= 0 then
            if m.forwardVel < 50.0 then
                m.forwardVel = m.forwardVel * 1.1
            end
        end
    end

    -- Feather Badge (Low Gravity)
    if Inventory.get_count(m, "badge_feather") > 0 then
        if (m.action & ACT_FLAG_AIR) ~= 0 and m.vel.y < 0 then
            m.vel.y = m.vel.y * 0.8
        end
    end

    -- Health Badge (Regen)
    if Inventory.get_count(m, "badge_health") > 0 then
        if m.health < 0x880 and gGlobalTimer % 300 == 0 then
             m.health = m.health + 0x100
        end
    end

    -- Metal Badge (Defense + Visuals)
    if Inventory.get_count(m, "badge_metal") > 0 then
        m.flags = m.flags | MARIO_METAL_CAP
        -- m.marioBodyState.modelState = MODEL_STATE_METAL -- Engine handles this flag usually?
        -- Actually, MARIO_METAL_CAP flag handling in C might require the cap timer to be > 0.
        -- Let's force the timer too or just the model state.
        -- Safe bet: Set model state manually if flag isn't enough in this codebase.
        if (m.flags & MARIO_METAL_CAP) ~= 0 then
             m.marioBodyState.modelState = MODEL_STATE_METAL
        end
    end

    -- Wing Badge (Triple Jump + Slow Fall)
    if Inventory.get_count(m, "badge_wing") > 0 then
        m.flags = m.flags | MARIO_WING_CAP
        -- Visuals handled by engine if flag is set? Usually yes.
    end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, perks_update)
