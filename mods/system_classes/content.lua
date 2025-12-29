-- Sample Classes

-- 1. Knight
Class.register("knight", {
    name = "Knight",
    description = "Melee specialist.",
    ability1 = function(m) -- Slash
        -- Animation
        set_mario_animation(m, MARIO_ANIM_GROUND_PUNCH)

        -- Movement
        if m.actionTimer == 0 then
            m.forwardVel = 40.0
            play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)
        end
        m.forwardVel = m.forwardVel * 0.9

        -- Hitbox
        -- Simplified: Check nearby enemies
        local hit = obj_check_hitbox_overlap(m.marioObj, m.marioObj) -- Self check? No.
        -- Real damage logic needs hitbox object or iterating nearby.
        -- For prototype, we just lunge.

        local step = perform_ground_step(m)

        m.actionTimer = m.actionTimer + 1
        if m.actionTimer > 15 then
            set_mario_action(m, ACT_IDLE, 0)
            return 1
        end
        return 0
    end,
    ability2 = function(m) -- Shield Bash
        set_mario_animation(m, MARIO_ANIM_STOP_SLIDE)
        m.forwardVel = 0
        -- Block damage?
        m.actionTimer = m.actionTimer + 1
        if m.actionTimer > 30 then
            set_mario_action(m, ACT_IDLE, 0)
            return 1
        end
        return 0
    end
})

-- 2. Mage
Class.register("mage", {
    name = "Mage",
    description = "Ranged caster.",
    ability1 = function(m) -- Fireball
        if m.actionTimer == 0 then
            set_mario_animation(m, MARIO_ANIM_FIRST_PUNCH)
            -- Spawn fireball
            spawn_sync_object(
                id_bhvBowlingBall, -- Placeholder for projectile
                E_MODEL_BOWLING_BALL,
                m.pos.x, m.pos.y + 100, m.pos.z,
                function(o)
                    o.oForwardVel = 60.0
                    o.oMoveAngleYaw = m.faceAngle.y
                    o.oVelY = 0
                end
            )
            play_sound(SOUND_OBJ_FLAME_BLOWN, m.marioObj.header.gfx.cameraToObject)
        end

        m.actionTimer = m.actionTimer + 1
        if m.actionTimer > 10 then
            set_mario_action(m, ACT_IDLE, 0)
            return 1
        end
        return 0
    end,
    ability2 = function(m) -- Heal
        if m.actionTimer == 0 then
            set_mario_animation(m, MARIO_ANIM_STAR_DANCE)
            play_sound(SOUND_GENERAL_HEART_SPIN, m.marioObj.header.gfx.cameraToObject)
            -- Heal
            if m.health < 0x880 then m.health = m.health + 0x200 end
            if m.health > 0x880 then m.health = 0x880 end
        end

        m.actionTimer = m.actionTimer + 1
        if m.actionTimer > 30 then
            set_mario_action(m, ACT_IDLE, 0)
            return 1
        end
        return 0
    end
})

-- 3. Rogue
Class.register("rogue", {
    name = "Rogue",
    description = "Fast and stealthy.",
    ability1 = function(m) -- Dash
        set_mario_animation(m, MARIO_ANIM_DIVE)
        m.forwardVel = 80.0
        m.vel.y = 0
        perform_ground_step(m)

        m.actionTimer = m.actionTimer + 1
        if m.actionTimer > 10 then
            set_mario_action(m, ACT_IDLE, 0)
            return 1
        end
        return 0
    end,
    ability2 = function(m) -- Smoke Bomb
        if m.actionTimer == 0 then
            spawn_mist_particles()
            obj_set_model_extended(m.marioObj, MODEL_NONE) -- Invisible
        end

        m.actionTimer = m.actionTimer + 1
        if m.actionTimer > 60 then
            obj_set_model_extended(m.marioObj, MODEL_MARIO) -- Restore
            set_mario_action(m, ACT_IDLE, 0)
            return 1
        end
        return 0
    end
})
