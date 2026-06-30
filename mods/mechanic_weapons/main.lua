-- name: Mechanic - Weapons
-- description: Equippable weapons with durability and custom hitboxes.
-- depends: system_inventory

_G.Weapons = {}

-- Weapon Definitions
Weapons.registry = {
    ["weap_sword"] = {
        name = "Iron Sword",
        type = "slash",
        damage = 10,
        maxDurability = 100,
        model = smlua_model_util_get_id("wooden_signpost_geo") -- placeholder model
    },
    ["weap_hammer"] = {
        name = "Heavy Hammer",
        type = "blunt",
        damage = 25,
        maxDurability = 50,
        model = smlua_model_util_get_id("hammer_geo") -- placeholder model
    }
}

-- Visual Object Logic
function bhv_weapon_visual_init(obj)
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj.header.gfx.scale.x = 0.5
    obj.header.gfx.scale.y = 0.5
    obj.header.gfx.scale.z = 0.5
end

function bhv_weapon_visual_loop(obj)
    local m = gMarioStates[obj.oBehParams] -- BParam holds player index

    -- If no weapon equipped or player disconnected, destroy
    if not gNetworkPlayers[m.playerIndex].connected or not gPlayerSyncTable[m.playerIndex].equipped_weapon then
        obj_mark_for_deletion(obj)
        return
    end

    local eqWeap = gPlayerSyncTable[m.playerIndex].equipped_weapon
    local wDef = Weapons.registry[eqWeap]

    if wDef then
        obj_set_model_extended(obj, wDef.model)

        -- Attach to Mario's hand
        -- This uses Mario's graphical position and approximates a hand offset based on facing angle
        local handOffsetX = 50 * math.sin(m.faceAngle.y)
        local handOffsetZ = 50 * math.cos(m.faceAngle.y)

        obj.oPosX = m.pos.x + handOffsetX
        obj.oPosY = m.pos.y + 60
        obj.oPosZ = m.pos.z + handOffsetZ

        -- Rotate weapon to match mario
        obj.oFaceAngleYaw = m.faceAngle.y
        obj.oFaceAnglePitch = 0
        obj.oFaceAngleRoll = 0

        -- If punching, swing the weapon
        if m.action == ACT_PUNCHING then
            obj.oFaceAnglePitch = 0x2000 -- swing down
        end
    end
end

id_bhvWeaponVisual = hook_behavior(nil, OBJ_LIST_DEFAULT, false, bhv_weapon_visual_init, bhv_weapon_visual_loop)

function weapons_on_mario_update(m)
    if m.playerIndex ~= 0 then return end

    -- Manage visual object spawning
    if gPlayerSyncTable[0].equipped_weapon and not m.marioBodyState.heldObj then
        -- We only spawn the visual locally if we don't have a held object, but we rely on a global check
        -- In a full implementation, we'd ensure only 1 object spawns per player.
        -- For now, the visual object handles its own deletion if the state changes.
        -- We use a local flag to prevent rapid respawning.
        if not m.weaponVisualSpawned then
            local obj = spawn_non_sync_object(
                id_bhvWeaponVisual,
                Weapons.registry[gPlayerSyncTable[0].equipped_weapon].model,
                m.pos.x, m.pos.y, m.pos.z,
                nil
            )
            obj.oBehParams = m.playerIndex
            m.weaponVisualSpawned = true
        end
    else
        m.weaponVisualSpawned = false
    end

    -- Handle Attack Input (B Button) when a weapon is equipped
    if gPlayerSyncTable[0].equipped_weapon and (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        local wId = gPlayerSyncTable[0].equipped_weapon
        local wDef = Weapons.registry[wId]

        if wDef then
            -- Perform Attack
            set_mario_action(m, ACT_PUNCHING, 0)
            play_sound(SOUND_ACTION_SWISH1, m.marioObj.header.gfx.cameraToObject)

            -- Decrease Durability
            local dur = gPlayerSyncTable[0].weapon_durability or 0
            dur = dur - 1
            gPlayerSyncTable[0].weapon_durability = dur

            -- Check Breakage
            if dur <= 0 then
                djui_chat_message_create("Your " .. wDef.name .. " broke!")
                play_sound(SOUND_GENERAL_BREAK_BOX, m.marioObj.header.gfx.cameraToObject)
                gPlayerSyncTable[0].equipped_weapon = nil
                gPlayerSyncTable[0].weapon_durability = 0
            else
                -- Hitbox Logic
                for i = 0, MAX_PLAYERS - 1 do
                    if i ~= 0 and gNetworkPlayers[i].connected then
                        local otherM = gMarioStates[i]
                        local dist = dist_between_objects(m.marioObj, otherM.marioObj)
                        if dist < 150 then
                             -- In a real PvP scenario, check system_pvp flags
                             -- djui_chat_message_create("Hit player " .. tostring(i) .. " for " .. tostring(wDef.damage))
                        end
                    end
                end
            end
        end
    end
end

-- Function to equip a weapon from inventory
function Weapons.equip(m, itemId)
    if m.playerIndex ~= 0 then return end

    local wDef = Weapons.registry[itemId]
    if wDef then
        gPlayerSyncTable[0].equipped_weapon = itemId
        if not gPlayerSyncTable[0].weapon_durability or gPlayerSyncTable[0].weapon_durability <= 0 then
            gPlayerSyncTable[0].weapon_durability = wDef.maxDurability
        end
        djui_chat_message_create("Equipped " .. wDef.name .. " (" .. tostring(gPlayerSyncTable[0].weapon_durability) .. "/" .. tostring(wDef.maxDurability) .. ")")
        play_sound(SOUND_OBJ_BOWSER_WALK, m.marioObj.header.gfx.cameraToObject)
    else
        djui_chat_message_create("Cannot equip that item.")
    end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, weapons_on_mario_update)
