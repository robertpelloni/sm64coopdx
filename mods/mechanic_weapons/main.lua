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
        model = smlua_model_util_get_id("bowling_ball_geo") -- placeholder model
    }
}

-- Player State
-- We store the equipped weapon ID and its current durability in the sync table so others can see it (eventually for rendering)
-- For now, we handle logic locally and sync the visual state.

function weapons_on_mario_update(m)
    if m.playerIndex ~= 0 then return end

    -- Sync equipped weapon for rendering to others
    if m.marioBodyState.heldObj == nil and gPlayerSyncTable[0].equipped_weapon then
        -- This is a simplified visual representation. In a full implementation,
        -- we would spawn a cosmetic object attached to Mario's hand.
    end

    -- Handle Attack Input (B Button) when a weapon is equipped
    if gPlayerSyncTable[0].equipped_weapon and (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        local wId = gPlayerSyncTable[0].equipped_weapon
        local wDef = Weapons.registry[wId]

        if wDef then
            -- Perform Attack
            set_mario_action(m, ACT_PUNCHING, 0) -- Use punch animation as base
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
                -- Remove from inventory (assumes we have a function to remove 1 specific item)
                -- For this simple implementation, we assume the inventory system handles count reduction on equip/break
            else
                -- Hitbox Logic (Simplified radial check)
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

                -- Object Hitbox Logic (interact with mobs/breakables)
                -- (Implementation depends on specific mob systems)
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
        -- Initialize durability if not already set (in a robust system, this is saved per-item instance)
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
