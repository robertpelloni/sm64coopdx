-- name: Mechanic - Climbing
-- description: Breath of the Wild style free-climbing with stamina.

local ACT_CLIMBING = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_MOVING)

-- Stamina Settings
local STAMINA_MAX_BASE = 100
local STAMINA_DRAIN_IDLE = 0.1
local STAMINA_DRAIN_MOVE = 0.5
local STAMINA_DRAIN_JUMP = 20
local STAMINA_REGEN = 1.0

-- Climbing Physics
local CLIMB_SPEED_V = 10.0
local CLIMB_SPEED_H = 8.0

function get_max_stamina(m)
    local base = STAMINA_MAX_BASE
    if _G.Progression then
        -- Agility increases stamina
        local agi = Progression.get_stat(m, "agi")
        base = base + (agi * 5)
    end
    return base
end

function act_climbing(m)
    local sTable = gPlayerSyncTable[m.playerIndex]
    if not sTable.stamina then sTable.stamina = get_max_stamina(m) end

    -- 1. Animation
    -- We don't have a perfect "free climb" animation in SM64 base,
    -- but hanging from a ceiling or climbing a pole can look okay.
    -- MARIO_ANIM_CLIMB_UP_POLE or MARIO_ANIM_HANG_ON_CEILING
    set_mario_animation(m, MARIO_ANIM_CLIMB_UP_POLE)

    -- Face the wall
    if m.wall ~= nil then
        m.faceAngle.y = atan2s(m.wall.normal.z, m.wall.normal.x) + 0x8000
    end

    -- 2. Stamina Drain
    local moving = (m.controller.stickMag > 10)
    if moving then
        sTable.stamina = sTable.stamina - STAMINA_DRAIN_MOVE
    else
        sTable.stamina = sTable.stamina - STAMINA_DRAIN_IDLE
    end

    -- Out of Stamina
    if sTable.stamina <= 0 then
        sTable.stamina = 0
        set_mario_action(m, ACT_FREEFALL, 0)
        play_sound(SOUND_MARIO_PANTING, m.marioObj.header.gfx.cameraToObject)
        return 1
    end

    -- 3. Input & Movement
    m.vel.x = 0
    m.vel.y = 0
    m.vel.z = 0

    if moving then
        -- Map stick to wall movement
        -- Stick Y = Vertical
        -- Stick X = Horizontal along the wall plane

        local sy = m.controller.stickY
        local sx = m.controller.stickX

        -- Vertical
        if sy > 20 then
            m.vel.y = CLIMB_SPEED_V
        elseif sy < -20 then
            m.vel.y = -CLIMB_SPEED_V
        end

        -- Horizontal (cross product of wall normal and UP)
        if m.wall ~= nil and math.abs(sx) > 20 then
            local nx = m.wall.normal.x
            local nz = m.wall.normal.z

            -- Vector perpendicular to wall normal in XZ plane
            local px = nz
            local pz = -nx

            local dir = sx > 0 and 1 or -1
            m.vel.x = px * CLIMB_SPEED_H * dir
            m.vel.z = pz * CLIMB_SPEED_H * dir
        end
    end

    -- Jump off wall
    if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
        if sTable.stamina >= STAMINA_DRAIN_JUMP then
            sTable.stamina = sTable.stamina - STAMINA_DRAIN_JUMP
            m.vel.y = 40.0

            -- Jump backward
            m.faceAngle.y = m.faceAngle.y + 0x8000
            m.forwardVel = 20.0
            set_mario_action(m, ACT_JUMP, 0)
            return 1
        else
            play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
        end
    end

    -- Drop
    if (m.controller.buttonPressed & Z_TRIG) ~= 0 then
        set_mario_action(m, ACT_FREEFALL, 0)
        return 1
    end

    -- Apply Movement
    m.pos.x = m.pos.x + m.vel.x
    m.pos.y = m.pos.y + m.vel.y
    m.pos.z = m.pos.z + m.vel.z

    -- 4. Collision Update
    -- We must ensure we are still touching a wall.
    -- Resolve wall collisions to push Mario out slightly, but we need to know if a wall is still there.
    local wallInfo = resolve_and_return_wall_collisions(m.pos, 50.0, 50.0)

    -- In smlua, `resolve_and_return_wall_collisions` returns the number of walls hit.
    -- But we need the actual wall struct to update m.wall.
    -- A simpler check: if we hit a wall, stay. If not, drop.
    -- We can use `f32_find_wall_collision` to update.

    local hitbox = {x = m.pos.x, y = m.pos.y, z = m.pos.z, radius = 60, offsetY = 50}
    local hit, wall = f32_find_wall_collision(hitbox.x, hitbox.y, hitbox.z, hitbox.offsetY, hitbox.radius)

    if hit then
        m.wall = wall
        -- Align position
        m.pos.x = hitbox.x
        m.pos.y = hitbox.y
        m.pos.z = hitbox.z
    else
        -- Climbed over the top or slipped off the edge
        -- Try to pull forward over the ledge
        m.pos.x = m.pos.x + sins(m.faceAngle.y) * 40
        m.pos.z = m.pos.z + coss(m.faceAngle.y) * 40
        m.pos.y = m.pos.y + 40

        local floorHeight = find_floor(m.pos.x, m.pos.y + 100, m.pos.z)
        if floorHeight > m.pos.y - 100 then
            m.pos.y = floorHeight
            set_mario_action(m, ACT_IDLE, 0)
        else
            set_mario_action(m, ACT_FREEFALL, 0)
        end
        return 1
    end

    -- Check Floor
    local floorHeight = find_floor(m.pos.x, m.pos.y + 100, m.pos.z)
    if m.pos.y <= floorHeight then
        m.pos.y = floorHeight
        set_mario_action(m, ACT_IDLE, 0)
        return 1
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end

hook_mario_action(ACT_CLIMBING, act_climbing)

function climbing_update(m)
    if m.playerIndex ~= 0 then return end

    local sTable = gPlayerSyncTable[m.playerIndex]
    local maxStamina = get_max_stamina(m)
    if not sTable.stamina then sTable.stamina = maxStamina end

    -- Regen
    if m.action ~= ACT_CLIMBING then
        if sTable.stamina < maxStamina then
            sTable.stamina = sTable.stamina + STAMINA_REGEN
            if sTable.stamina > maxStamina then sTable.stamina = maxStamina end
        end
    end

    -- Trigger
    -- If jumping/falling into a wall, and holding Forward or A
    if (m.action & ACT_FLAG_AIR) ~= 0 and m.wall ~= nil then
        -- To avoid grabbing immediately upon wallkick, require pushing stick towards wall
        if m.controller.stickMag > 20 then
            -- Are we pushing into the wall?
            local yawDiff = abs_angle_diff(m.intendedYaw, m.faceAngle.y)
            if yawDiff < 0x2000 and sTable.stamina > 0 then
                -- Check if it's a valid wall (not too steep/ceiling)
                -- wall.normal.y should be close to 0
                if math.abs(m.wall.normal.y) < 0.2 then
                    set_mario_action(m, ACT_CLIMBING, 0)
                end
            end
        end
    end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, climbing_update)

-- UI
function stamina_hud()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    if not sTable.stamina then return end
    local maxStamina = get_max_stamina(m)

    -- Only show if not full or actively climbing
    if sTable.stamina >= maxStamina and m.action ~= ACT_CLIMBING then return end

    local out = {x=0, y=0, z=0}
    -- Draw wheel near Mario
    local pos = {x = m.pos.x, y = m.pos.y + 120, z = m.pos.z}
    if djui_hud_world_pos_to_screen_pos(pos, out) then
        local ratio = sTable.stamina / maxStamina

        -- Color shifts from Green -> Yellow -> Red
        local r = 0
        local g = 255
        if ratio < 0.5 then
            r = 255
            g = 255 * (ratio / 0.5)
        else
            r = 255 * (1 - ((ratio - 0.5) / 0.5))
        end

        djui_hud_set_color(0, 0, 0, 150)
        djui_hud_render_rect(out.x - 20, out.y, 40, 6)

        djui_hud_set_color(math.floor(r), math.floor(g), 0, 255)
        djui_hud_render_rect(out.x - 20, out.y, 40 * ratio, 6)
    end
end

hook_event(HOOK_ON_HUD_RENDER, stamina_hud)
