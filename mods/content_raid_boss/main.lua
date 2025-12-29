-- name: Content - Raid Boss (King Whomp)
-- description: A multi-phase boss fight showcasing MMORPG mechanics.

local BOSS_HP_MAX = 5000
local E_MODEL_KING_WHOMP = smlua_model_util_get_id("whomp_geo")

local HITBOX_KING_WHOMP = {
    interactType = INTERACT_DAMAGE,
    downOffset = 0,
    damageOrCoinValue = 1,
    health = 0,
    numLootCoins = 0,
    radius = 500,
    height = 2000,
    hurtboxRadius = 500,
    hurtboxHeight = 2000,
}

-- Sync Fields
-- oHealth: HP
-- oAction: Phase (0=Idle, 1=Stomp, 2=Minions, 3=Flying)
-- oTimer: Attack timer

function bhv_king_whomp_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oHealth = BOSS_HP_MAX
    o.oAction = 0 -- Idle
    o.oGravity = -4.0
    o.oFriction = 0.8
    o.oBuoyancy = 1.0
    o.oOpacity = 255

    -- Resize
    cur_obj_scale(4.0)
    obj_set_hitbox(o, HITBOX_KING_WHOMP)

    -- Sync: standardSync=true handles pos/vel/angle automatically
    network_init_object(o, true, {
        "oHealth",
        "oAction",
        "oTimer"
    })
end

function bhv_king_whomp_loop(o)
    object_step(o)

    -- Hitbox Maintenance
    obj_set_hitbox(o, HITBOX_KING_WHOMP)

    -- Death
    if o.oHealth <= 0 then
        obj_mark_for_deletion(o)
        spawn_mist_particles_variable(0, 0, 100.0)
        djui_chat_message_create("King Whomp Defeated!")
        return
    end

    -- Interaction / Damage Logic
    if obj_check_attacks(o, HITBOX_KING_WHOMP) ~= 0 then
        local status = o.oInteractStatus
        local interacted = (status & INT_STATUS_INTERACTED) ~= 0
        local attacked = (status & INT_STATUS_WAS_ATTACKED) ~= 0

        if attacked or interacted then
            -- Take Damage
            -- Standard Mario punch is ~20-50 damage in some mods, but let's assume 50 per hit.
            local dmg = 50
            o.oHealth = o.oHealth - dmg

            -- Visual Feedback
            o.oInteractStatus = 0 -- Reset
            -- Spawn red coins or sparkles?
            spawn_triangle_break_particles(10, 138, 3.0, 4)
        end
    end

    -- Only Authority (Player 0 or Server) drives AI
    if gMarioStates[0].playerIndex ~= 0 then return end

    -- AI Logic
    if o.oAction == 0 then -- Idle / Phase Check
        if o.oTimer > 60 then
            if o.oHealth > 3500 then
                o.oAction = 1 -- Phase 1: Stomp
            elseif o.oHealth > 1500 then
                o.oAction = 2 -- Phase 2: Minions
            else
                o.oAction = 3 -- Phase 3: Fly/Hookshot
            end
            o.oTimer = 0
        end
    elseif o.oAction == 1 then -- Phase 1: Stomp
        -- Chase nearest player
        local target = nearest_player_to_object(o)
        if target then
            local angle = obj_angle_to_object(o, target)
            o.oMoveAngleYaw = approach_s16_symmetric(o.oMoveAngleYaw, angle, 0x200)
            o.oForwardVel = 15.0

            -- Slam
            if o.oTimer > 90 then
                o.oVelY = 40.0
                o.oForwardVel = 0
                -- Fall logic handles slam impact
                o.oTimer = 0
            end
        end

    elseif o.oAction == 2 then -- Phase 2: Minions
        o.oForwardVel = 0
        if o.oTimer % 100 == 0 then
            -- Spawn Minion Stub
            djui_chat_message_create("King Whomp summons minions!")
        end
        if o.oTimer > 600 then o.oAction = 0 end -- Reset

    elseif o.oAction == 3 then -- Phase 3: Flight
        o.oVelY = 10.0
        if o.oPosY > 2000 then o.oVelY = 0 end
    end
end

local id_bhvKingWhomp = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_king_whomp_init, bhv_king_whomp_loop)

-- Spawn
function on_spawn_raid(msg)
    local m = gMarioStates[0]
    spawn_sync_object(
        id_bhvKingWhomp,
        E_MODEL_KING_WHOMP,
        m.pos.x + 500, m.pos.y + 500, m.pos.z,
        nil
    )
    djui_chat_message_create("Raid Boss Spawned: King Whomp!")
    return true
end

hook_chat_command("raid", "Spawn Raid Boss", on_spawn_raid)

-- HUD Render
function boss_hud()
    local obj = obj_get_first(OBJ_LIST_GENACTOR)
    while obj do
        if obj.behavior == id_bhvKingWhomp then
            -- Draw HP Bar
            local w = djui_hud_get_screen_width()
            local h = 20
            local y = 20

            -- Bg
            djui_hud_set_color(0, 0, 0, 200)
            djui_hud_render_rect(w/2 - 150, y, 300, h)

            -- Fill
            local fill = (obj.oHealth / BOSS_HP_MAX) * 300
            if fill < 0 then fill = 0 end
            djui_hud_set_color(255, 0, 0, 255)
            djui_hud_render_rect(w/2 - 150, y, fill, h)

            djui_hud_set_color(255, 255, 255, 255)
            djui_hud_print_text("King Whomp the Eternal", w/2 - 100, y + 25, 1)
            break
        end
        obj = obj_get_next(obj)
    end
end

hook_event(HOOK_ON_HUD_RENDER, boss_hud)
