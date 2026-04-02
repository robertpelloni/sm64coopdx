-- name: Content - Tower of Trials
-- description: A multi-floor gauntlet mode. Clear a floor to spawn the portal to the next.

_G.Tower = {}
_G.Tower.active = false
_G.Tower.currentFloor = 1
_G.Tower.maxFloor = 10
_G.Tower.enemiesRemaining = 0

-- Using existing levels as floors.
-- Bob-omb Battlefield (9), Whomp's Fortress (24), Jolly Roger Bay (12), etc.
local TOWER_FLOORS = {
    {level = LEVEL_BOB_OMB_BATTLEFIELD, bgm = SEQ_LEVEL_GRASS},
    {level = LEVEL_WHOMPS_FORTRESS, bgm = SEQ_LEVEL_GRASS},
    {level = LEVEL_JOLLY_ROGER_BAY, bgm = SEQ_LEVEL_WATER},
    {level = LEVEL_COOL_COOL_MOUNTAIN, bgm = SEQ_LEVEL_SNOW},
    {level = LEVEL_BIG_BOO_HAUNT, bgm = SEQ_LEVEL_SPOOKY},
    {level = LEVEL_HAZY_MAZE_CAVE, bgm = SEQ_LEVEL_UNDERGROUND},
    {level = LEVEL_LETHAL_LAVA_LAND, bgm = SEQ_LEVEL_HOT},
    {level = LEVEL_SHIFTING_SAND_LAND, bgm = SEQ_LEVEL_HOT},
    {level = LEVEL_DIRE_DIRE_DOCKS, bgm = SEQ_LEVEL_WATER},
    {level = LEVEL_SNOWMANS_LAND, bgm = SEQ_LEVEL_SNOW}
}

-- Spawner for Tower portal
local E_MODEL_TOWER_PORTAL = E_MODEL_STAR -- Placeholder for a warp pipe or portal

function bhv_tower_portal_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_POLE -- Using pole interact to "grab" it?
    -- Actually INTERACT_WARP is better if it works without parameters.
    -- Or just distance check in loop.
    o.oInteractType = INTERACT_NONE

    obj_scale(o, 2.0)
end

function bhv_tower_portal_loop(o)
    o.oFaceAngleYaw = o.oFaceAngleYaw + 0x400

    local m = gMarioStates[0]
    if dist_between_objects(o, m.marioObj) < 150 then
        -- Proceed to next floor
        if _G.Tower.active then
            Tower.next_floor()
            obj_mark_for_deletion(o)
        end
    end
end

local id_bhvTowerPortal = hook_behavior(nil, OBJ_LIST_GENACTOR, false, bhv_tower_portal_init, bhv_tower_portal_loop)

-- Spawner for custom enemies (to track them easily)
local ENEMY_TYPES = {E_MODEL_GOOMBA, E_MODEL_BLACK_BOBOMB, E_MODEL_SCUTTLEBUG}

function spawn_tower_enemies(floorNum)
    if not network_is_server() then return end

    local numEnemies = floorNum * 2 + 3
    _G.Tower.enemiesRemaining = numEnemies

    -- We'll spawn them randomly around the center of the level.
    -- Finding the center is tricky, we'll use Mario's spawn position.
    local cx = gMarioStates[0].pos.x
    local cy = gMarioStates[0].pos.y
    local cz = gMarioStates[0].pos.z

    for i=1, numEnemies do
        local angle = math.random(0, 0xFFFF)
        local dist = math.random(500, 1500)
        local ex = cx + sins(angle) * dist
        local ez = cz + coss(angle) * dist
        local ey = find_floor(ex, cy + 1000, ez)

        if ey > -10000 then
            local model = ENEMY_TYPES[math.random(1, #ENEMY_TYPES)]

            -- We need a custom behavior to track deaths easily,
            -- or hook into generic combat interactions.
            -- Since we added `system_combat` which gives XP on kill, we can hook that!
            -- Let's define a custom behavior that wraps a generic enemy but tracks death.
            -- To keep it simple, we spawn a custom generic enemy object.

            local e = spawn_sync_object(
                id_bhvTowerEnemy,
                model,
                ex, ey, ez,
                nil
            )
            e.oBehParams2ndByte = floorNum -- Difficulty scaling
        else
            -- If we can't find a floor, just reduce count to avoid softlock
            _G.Tower.enemiesRemaining = _G.Tower.enemiesRemaining - 1
        end
    end
end

-- Custom Tower Enemy
function bhv_tower_enemy_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_BOUNCE_TOP
    o.oCollisionDistance = 500
    o.oIntangibleTimer = 0
    o.oGravity = -4.0
    o.oFriction = 0.8
    o.oBuoyancy = 1.0

    local floor = o.oBehParams2ndByte or 1

    obj_set_hitbox(o, {
        interactType = INTERACT_BOUNCE_TOP,
        downOffset = 0,
        damageOrCoinValue = floor, -- More damage on higher floors
        health = floor * 2, -- Scaling health
        numLootCoins = 1,
        radius = 80,
        height = 80,
        hurtboxRadius = 80,
        hurtboxHeight = 80
    })
end

function bhv_tower_enemy_loop(o)
    object_step(o)

    -- AI: Chase nearest player
    local p = nearest_mario_state_to_object(o)
    if p then
        -- Integrate Stealth!
        local vis = 1.0
        if _G.Stealth then vis = Stealth.get_visibility(p) end

        local dist = dist_between_objects(o, p.marioObj)
        if dist < (1500 * vis) then
            local angleTo = obj_angle_to_object(o, p.marioObj)
            o.oMoveAngleYaw = approach_s16_symmetric(o.oMoveAngleYaw, angleTo, 0x800)
            o.oForwardVel = 10.0 + (o.oBehParams2ndByte or 1) -- Scaling speed
        else
            o.oForwardVel = 0
        end
    end

    -- Death check
    if o.oInteractStatus & INT_STATUS_WAS_ATTACKED ~= 0 or o.oInteractStatus & INT_STATUS_INTERACTED ~= 0 then
        -- Took damage (simplified: one hit kill for prototype unless health tracked manually via combat system)
        -- We'll assume a single hit kills for this basic enemy

        if network_is_server() then
            _G.Tower.enemiesRemaining = _G.Tower.enemiesRemaining - 1
            djui_chat_message_create("Tower: " .. _G.Tower.enemiesRemaining .. " enemies left.")

            if _G.Tower.enemiesRemaining <= 0 then
                djui_chat_message_create("Floor Cleared! A portal has spawned.")
                spawn_sync_object(
                    id_bhvTowerPortal,
                    E_MODEL_TOWER_PORTAL,
                    gMarioStates[0].pos.x,
                    gMarioStates[0].pos.y,
                    gMarioStates[0].pos.z,
                    nil
                )
            end
        end

        spawn_triangle_break_particles(20, 138, 3.0, 4)
        obj_mark_for_deletion(o)
    end
end

local id_bhvTowerEnemy = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_tower_enemy_init, bhv_tower_enemy_loop)

function Tower.enter(m)
    if m.playerIndex ~= 0 then return end

    _G.Tower.active = true
    _G.Tower.currentFloor = 1

    djui_chat_message_create("Entering Tower of Trials...")
    warp_to_level(TOWER_FLOORS[1].level, 1, 0)

    -- Server triggers spawn after level load
end

function Tower.next_floor()
    local m = gMarioStates[0]
    _G.Tower.currentFloor = _G.Tower.currentFloor + 1

    if _G.Tower.currentFloor > _G.Tower.maxFloor then
        djui_chat_message_create("TOWER COMPLETED! You are a champion!")
        _G.Tower.active = false
        -- Give massive reward
        if _G.Inventory then Inventory.add_item(m, "coin_bag", 5000) end
        if _G.Achievement then Achievement.unlock(m, "tower_champ") end
        warp_to_level(LEVEL_CASTLE_GROUNDS, 1, 0)
        return
    end

    local floorData = TOWER_FLOORS[_G.Tower.currentFloor]
    djui_chat_message_create("Ascending to Floor " .. _G.Tower.currentFloor)
    warp_to_level(floorData.level, 1, 0)
end

function tower_level_init()
    if _G.Tower.active and network_is_server() then
        -- Small delay to let players settle
        djui_chat_message_create("Tower: Spawning enemies for floor " .. _G.Tower.currentFloor .. "...")
        spawn_tower_enemies(_G.Tower.currentFloor)
    end
end

hook_event(HOOK_ON_LEVEL_INIT, tower_level_init)

hook_chat_command("tower", "Tower of Trials mode", function(msg)
    local m = gMarioStates[0]
    if msg == "enter" then
        Tower.enter(m)
    elseif msg == "leave" then
        _G.Tower.active = false
        warp_to_level(LEVEL_CASTLE_GROUNDS, 1, 0)
        djui_chat_message_create("Left Tower.")
    else
        djui_chat_message_create("Usage: /tower [enter|leave]")
    end
    return true
end)

-- UI
function tower_hud()
    if not _G.Tower.active then return end

    local w = djui_hud_get_screen_width()

    djui_hud_set_color(0, 0, 0, 150)
    djui_hud_render_rect(w/2 - 100, 10, 200, 40)

    djui_hud_set_color(255, 215, 0, 255)
    djui_hud_print_text("Floor: " .. _G.Tower.currentFloor .. "/" .. _G.Tower.maxFloor, w/2 - 50, 15, 1)

    djui_hud_set_color(255, 100, 100, 255)
    djui_hud_print_text("Enemies: " .. _G.Tower.enemiesRemaining, w/2 - 60, 30, 1)
end

hook_event(HOOK_ON_HUD_RENDER, tower_hud)
