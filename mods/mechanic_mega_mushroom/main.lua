-- name: Mechanic - Mega Mushroom
-- description: Turn giant and destroy everything.
-- depends: system_inventory

_G.MegaMushroom = {}

local MEGA_DURATION = 30 * 15 -- 15 seconds at 30fps
local SCALE_TARGET = 4.0

-- Ensure inventory dependency is loaded
function mm_init()
    if _G.Inventory and _G.Inventory.define_item then
        _G.Inventory.define_item(
            "mega_mushroom",
            "Mega Mushroom",
            "Grow to massive size and destroy enemies on contact for 15 seconds."
        )
        -- We don't have a direct "use" hook in Inventory API right now,
        -- but if a generic "use item" command gets added, it would reference this.
    end
end

hook_event(HOOK_ON_LEVEL_INIT, mm_init)

function mm_update(m)
    local s = gPlayerSyncTable[m.playerIndex]

    if s.is_mega and s.mega_timer then
        if s.mega_timer > 0 then
            s.mega_timer = s.mega_timer - 1

            -- Visual scaling
            m.marioObj.header.gfx.scale.x = SCALE_TARGET
            m.marioObj.header.gfx.scale.y = SCALE_TARGET
            m.marioObj.header.gfx.scale.z = SCALE_TARGET

            -- Invulnerability (handled partially by overriding interact actions if possible,
            -- or just relying on combat hooks. For now, simple visual scale is primary)

            -- Destroy objects? We can check nearby objects and delete them,
            -- or just enjoy the scale. Let's do a simple radius check for basic enemies.
            if m.playerIndex == 0 and m.action ~= ACT_IDLE then
                -- Basic AoE kill (simplified)
                local npcs = obj_get_first_with_behavior_id(id_bhvGoomba)
                while npcs do
                    if dist_between_objects(m.marioObj, npcs) < 500 then
                        obj_mark_for_deletion(npcs)
                        play_sound(SOUND_OBJ_STOMP_BOMB_OMB, m.marioObj.header.gfx.cameraToObject)
                    end
                    npcs = obj_get_next_with_same_behavior_id(npcs)
                end
            end
        else
            -- Timer ended
            s.is_mega = false
            s.mega_timer = 0

            m.marioObj.header.gfx.scale.x = 1.0
            m.marioObj.header.gfx.scale.y = 1.0
            m.marioObj.header.gfx.scale.z = 1.0

            if m.playerIndex == 0 then
                play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
                djui_chat_message_create("Mega Mushroom faded.")
            end
        end
    end
end

hook_event(HOOK_MARIO_UPDATE, mm_update)
