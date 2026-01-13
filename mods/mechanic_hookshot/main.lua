-- name: Mechanic - Hookshot
-- description: A grappling hook mechanic.\n\nRequires 'Hookshot' item.\nPress Y to fire.

local ACT_HOOKSHOT_FLYING = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING)

local HOOK_RANGE = 2000
local HOOK_SPEED = 60.0

function act_hookshot_flying(m)
    local sTable = gPlayerSyncTable[m.playerIndex]

    -- Sync Check
    if not sTable.hookTargetX then
        set_mario_action(m, ACT_JUMP_LAND, 0)
        return 1
    end

    local targetX = sTable.hookTargetX
    local targetY = sTable.hookTargetY
    local targetZ = sTable.hookTargetZ

    -- 1. Visuals: Render Chain
    -- We need to draw from Mario (hand) to Target.
    -- Ideally HOOK_ON_OBJECT_RENDER for 3D lines, but spawning particles is easier/standard in Lua mods.
    -- Spawn particles along the line.

    local dx = targetX - m.pos.x
    local dy = targetY - m.pos.y
    local dz = targetZ - m.pos.z
    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

    -- Spawn particles every 100 units
    if m.playerIndex == 0 or dist > 200 then -- Optimization: Only render detail for local or if far? No, render all.
        local steps = math.floor(dist / 100)
        for i = 1, steps do
            local t = i / steps
            local px = m.pos.x + dx * t
            local py = m.pos.y + dy * t + 60 -- Chest height
            local pz = m.pos.z + dz * t

            -- Spawn Sparkle (Non-synced, visual only)
            spawn_non_sync_object(
                id_bhvSparkleSpawn,
                E_MODEL_SPARKLES,
                px, py, pz,
                nil
            )
        end
    end

    set_mario_animation(m, MARIO_ANIM_FORWARD_SCROLLING)

    -- 2. Physics
    if dist < 100 then
        m.vel.y = 30
        set_mario_action(m, ACT_JUMP_LAND, 0)
        return 1
    end

    m.vel.x = (dx / dist) * HOOK_SPEED
    m.vel.y = (dy / dist) * HOOK_SPEED
    m.vel.z = (dz / dist) * HOOK_SPEED

    m.forwardVel = HOOK_SPEED
    m.faceAngle.y = atan2s(dz, dx)

    -- 3. Collision
    local step = perform_air_step(m, 0)
    if step == AIR_STEP_LANDED then
        set_mario_action(m, ACT_JUMP_LAND, 0)
        return 1
    elseif step == AIR_STEP_HIT_WALL then
        set_mario_action(m, ACT_JUMP_LAND, 0)
        return 1
    end

    return 0
end

function hookshot_update(m)
    if m.playerIndex ~= 0 then return end

    if (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        if not Inventory or Inventory.get_count(m, "hookshot") <= 0 then
            return
        end

        local startPos = {x = m.pos.x, y = m.pos.y + 150, z = m.pos.z}

        local cam = m.area.camera
        local dx = cam.focus.x - cam.pos.x
        local dy = cam.focus.y - cam.pos.y
        local dz = cam.focus.z - cam.pos.z
        local mag = math.sqrt(dx*dx + dy*dy + dz*dz)

        local dirX = dx / mag
        local dirY = dy / mag
        local dirZ = dz / mag

        local hitInfo = collision_find_surface_on_ray(
            startPos.x, startPos.y, startPos.z,
            dirX * HOOK_RANGE, dirY * HOOK_RANGE, dirZ * HOOK_RANGE
        )

        if hitInfo.surface then
            local sTable = gPlayerSyncTable[m.playerIndex]
            sTable.hookTargetX = hitInfo.hitPos.x
            sTable.hookTargetY = hitInfo.hitPos.y
            sTable.hookTargetZ = hitInfo.hitPos.z

            set_mario_action(m, ACT_HOOKSHOT_FLYING, 0)
            play_sound(SOUND_GENERAL_SWISH_AIR, m.marioObj.header.gfx.cameraToObject)
        else
            play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
        end
    end
end

function hookshot_hud()
    if not Inventory or Inventory.get_count(gMarioStates[0], "hookshot") <= 0 then return end

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()

    djui_hud_set_color(255, 0, 0, 150)
    djui_hud_render_rect(w/2 - 2, h/2 - 2, 4, 4)
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, hookshot_update)
hook_event(HOOK_ON_HUD_RENDER, hookshot_hud)
hook_mario_action(ACT_HOOKSHOT_FLYING, act_hookshot_flying)
