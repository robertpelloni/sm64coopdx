-- name: Mechanic - Mining
-- description: Mine ore nodes for crafting materials.

local ORE_RESPAWN_TIME = 30 * 60 -- 60 seconds
local E_MODEL_ORE = E_MODEL_BOWLING_BALL -- Using Bowling Ball as a better placeholder for a rock

-- Ore Nodes List
local OreNodes = {} -- {obj=obj, type="iron", active=true, timer=0}

function bhv_ore_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_BREAKABLE
    o.oCollisionDistance = 300
    o.oIntangibleTimer = 0
    obj_set_hitbox(o, {
        interactType = INTERACT_BREAKABLE,
        downOffset = 0,
        damageOrCoinValue = 0,
        health = 1,
        numLootCoins = 0,
        radius = 80,
        height = 80,
        hurtboxRadius = 80,
        hurtboxHeight = 80
    })
end

function bhv_ore_loop(o)
    -- Check interaction
    if o.oInteractStatus & INT_STATUS_WAS_ATTACKED ~= 0 then
        -- Mined!
        local p = nearest_mario_state_to_object(o)
        if p and p.playerIndex == 0 then
            -- Give loot
            if _G.Inventory then
                Inventory.add_item(p, "stone", math.random(1, 3))
                if math.random() > 0.5 then
                    Inventory.add_item(p, "iron_ore", 1)
                end
                djui_chat_message_create("Mined Ore!")
                play_sound(SOUND_GENERAL_BREAK_BOX, p.marioObj.header.gfx.cameraToObject)
            end
        end

        -- Hide/Disable
        o.oInteractStatus = 0
        o.activeFlags = 0 -- Despawn
        spawn_triangle_break_particles(20, 138, 3.0, 4)
        obj_mark_for_deletion(o)
    end
end

local id_bhvOreNode = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_ore_init, bhv_ore_loop)

-- Spawner
function spawn_ore_nodes()
    -- Randomly spawn some nodes around start
    if network_is_server() then
        for i=1, 5 do
            local x = math.random(-2000, 2000)
            local z = math.random(-2000, 2000)
            local y = find_floor(x, 1000, z)
            if y > -10000 then
                spawn_sync_object(
                    id_bhvOreNode,
                    E_MODEL_ORE,
                    x, y, z,
                    nil
                )
            end
        end
    end
end

-- Hook into level load?
hook_event(HOOK_ON_LEVEL_INIT, spawn_ore_nodes)

-- Manual command
hook_chat_command("ore", "Spawn ore node", function()
    local m = gMarioStates[0]
    spawn_sync_object(
        id_bhvOreNode,
        E_MODEL_ORE,
        m.pos.x + 200 * sins(m.faceAngle.y),
        m.pos.y,
        m.pos.z + 200 * coss(m.faceAngle.y),
        nil
    )
    return true
end)
