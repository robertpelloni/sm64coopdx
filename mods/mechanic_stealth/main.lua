-- name: Mechanic - Stealth
-- description: Reduces enemy detection radius when crouching or crawling.

_G.Stealth = {}

-- Base detection multiplier (1.0 = normal, 0.0 = invisible)
local STEALTH_MULTIPLIER_CROUCH = 0.5
local STEALTH_MULTIPLIER_CRAWL = 0.6
local STEALTH_MULTIPLIER_ROGUE = 0.3 -- Bonus for Rogue class

--- Returns a multiplier (0.0 to 1.0) representing how visible Mario is.
--- Used by custom AI or modified vanilla AI (if hooked).
function Stealth.get_visibility(m)
    local mult = 1.0

    -- Check Rogue Class
    if _G.Classes then
        local sTable = gPlayerSyncTable[m.playerIndex]
        if sTable.classType == Classes.TYPE_ROGUE then
            mult = mult - STEALTH_MULTIPLIER_ROGUE
        end
    end

    -- Check Action
    if m.action == ACT_CROUCHING or m.action == ACT_START_CROUCHING then
        mult = mult * STEALTH_MULTIPLIER_CROUCH
    elseif m.action == ACT_CRAWLING then
        mult = mult * STEALTH_MULTIPLIER_CRAWL
    end

    -- Check Invisibility Ability (from Classes)
    if m.marioBodyState.modelState == MODEL_STATE_NOISE_ALPHA then
        mult = 0.0
    end

    if mult < 0 then mult = 0 end
    return mult
end

--- Hook to apply visual effects to Mario when stealthed
function stealth_update(m)
    if m.playerIndex ~= 0 then return end

    local vis = Stealth.get_visibility(m)

    -- If naturally invisible via ability, let that system handle it
    if m.marioBodyState.modelState == MODEL_STATE_NOISE_ALPHA then return end

    -- Apply transparency based on visibility
    -- Normal Mario alpha is 255.
    -- If visibility is 0.5, alpha is 127.

    -- In smlua, setting Mario's alpha requires modifying the material or using specific model states.
    -- MODEL_STATE_ALPHA is a flag, but we need to set the actual alpha value.
    -- m.marioObj.header.gfx.node.flags & GRAPH_RENDER_TRANSPARENT?
    -- The simplest way in standard smlua without custom models is to toggle MODEL_STATE_ALPHA and rely on the engine's default alpha,
    -- OR use the `obj_set_model_extended` with a transparent model, but we don't have one.
    -- We can use the Metal Cap / Vanish Cap flags visually if we want a strong effect,
    -- but that affects gameplay.

    -- Let's use a subtle particle effect instead to indicate "Sneaking Mode"
    if vis < 1.0 and m.forwardVel > 0 then
        if gGlobalTimer % 15 == 0 then
            spawn_non_sync_object(
                id_bhvSparkleSpawn,
                E_MODEL_NONE, -- Invisible particle spawner
                m.pos.x, m.pos.y, m.pos.z,
                nil
            )
            -- Use dust for footsteps
            m.particleFlags = m.particleFlags | PARTICLE_DUST
        end
    end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, stealth_update)

-- Helper to integrate with enemy AI
-- Example:
-- local dist = dist_between_objects(o, m.marioObj)
-- local vis = Stealth.get_visibility(m)
-- if dist < (AGGRO_RADIUS * vis) then ... aggro ... end

-- We cannot easily override ALL vanilla enemy AI in Lua without replacing every behavior.
-- However, we can hook `HOOK_ALLOW_INTERACT` to prevent damage if fully invisible?
-- No, stealth is about detection, not invulnerability.
-- We will use `Stealth.get_visibility(m)` in custom content (like the Tower or Dungeons).
