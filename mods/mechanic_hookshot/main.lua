-- name: Mechanic - Hookshot
-- description: A grappling hook mechanic.\n\nRequires 'Hookshot' item.\nPress Y to fire.

local ACT_HOOKSHOT_FLYING = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING)

local HOOK_RANGE = 2000
local HOOK_SPEED = 60.0

function act_hookshot_flying(m)
    local sTable = gPlayerSyncTable[m.playerIndex]

    -- Sync Check
    if not sTable.hookTargetX then
        -- No target set, abort
        set_mario_action(m, ACT_JUMP_LAND, 0)
        return 1
    end

    local targetX = sTable.hookTargetX
    local targetY = sTable.hookTargetY
    local targetZ = sTable.hookTargetZ

    -- 1. Visuals
    set_mario_animation(m, MARIO_ANIM_FORWARD_SCROLLING) -- Flying pose
    -- TODO: Draw chain/rope

    -- 2. Physics: Move towards target
    local dx = targetX - m.pos.x
    local dy = targetY - m.pos.y
    local dz = targetZ - m.pos.z
    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

    if dist < 100 then
        -- Arrived
        -- Bump up slightly to land
        m.vel.y = 30
        set_mario_action(m, ACT_JUMP_LAND, 0)
        return 1
    end

    -- Normalize and apply speed
    m.vel.x = (dx / dist) * HOOK_SPEED
    m.vel.y = (dy / dist) * HOOK_SPEED
    m.vel.z = (dz / dist) * HOOK_SPEED

    m.forwardVel = HOOK_SPEED -- For consistency
    m.faceAngle.y = atan2s(dz, dx)

    -- 3. Collision
    -- We restrict full physics updates to local player OR we accept the simple linear path
    -- Since we set velocity, perform_air_step will handle movement.
    -- However, lag might cause desync if we rely purely on input.
    -- Since we have a fixed target, both clients calculating the path is generally fine as long as target is synced.

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

    -- Input: Y Button
    if (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        -- Check Inventory
        if not Inventory or Inventory.get_count(m, "hookshot") <= 0 then
            return
        end

        -- Raycast
        -- Start at eye height
        local startPos = {x = m.pos.x, y = m.pos.y + 150, z = m.pos.z}

        local cam = m.area.camera
        local dx = cam.focus.x - cam.pos.x
        local dy = cam.focus.y - cam.pos.y
        local dz = cam.focus.z - cam.pos.z
        local mag = math.sqrt(dx*dx + dy*dy + dz*dz)

        local dirX = dx / mag
        local dirY = dy / mag
        local dirZ = dz / mag

        -- Raycast
        local hitInfo = collision_find_surface_on_ray(
            startPos.x, startPos.y, startPos.z,
            dirX * HOOK_RANGE, dirY * HOOK_RANGE, dirZ * HOOK_RANGE
        )

        if hitInfo.surface then
            -- Hit!
            -- Sync Target
            local sTable = gPlayerSyncTable[m.playerIndex]
            sTable.hookTargetX = hitInfo.hitPos.x
            sTable.hookTargetY = hitInfo.hitPos.y
            sTable.hookTargetZ = hitInfo.hitPos.z

            -- Start Action
            set_mario_action(m, ACT_HOOKSHOT_FLYING, 0)
            play_sound(SOUND_GENERAL_SWISH_AIR, m.marioObj.header.gfx.cameraToObject)
        else
            play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
        end
    end
end

-- Crosshair Render
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
