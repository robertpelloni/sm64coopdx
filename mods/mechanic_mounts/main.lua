-- name: Mechanic - Mounts
-- description: Rideable creatures with visual models and custom physics.
-- depends: system_inventory

_G.Mounts = {}

-- Mount Definitions
Mounts.registry = {
    ["mount_yoshi"] = {
        name = "Yoshi",
        model = smlua_model_util_get_id("yoshi_geo"),
        speedMult = 1.5,
        jumpMult = 1.2
    },
    ["mount_dorrie"] = {
        name = "Dorrie",
        model = smlua_model_util_get_id("dorrie_geo"),
        speedMult = 1.2,
        jumpMult = 0.8
    }
}

-- Visual Object Logic
function bhv_mount_visual_init(obj)
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
end

function bhv_mount_visual_loop(obj)
    local m = gMarioStates[obj.oBehParams]

    if not gNetworkPlayers[m.playerIndex].connected or not gPlayerSyncTable[m.playerIndex].active_mount then
        obj_mark_for_deletion(obj)
        return
    end

    local mountId = gPlayerSyncTable[m.playerIndex].active_mount
    local mDef = Mounts.registry[mountId]

    if mDef then
        obj_set_model_extended(obj, mDef.model)

        -- Follow Mario
        obj.oPosX = m.pos.x
        obj.oPosY = m.pos.y
        obj.oPosZ = m.pos.z

        obj.oFaceAngleYaw = m.faceAngle.y
        obj.oFaceAnglePitch = 0
        obj.oFaceAngleRoll = 0

        -- Hide Mario visually or set him to riding animation
        -- We use riding hoot as a fallback if hiding doesn't look right,
        -- but attaching Mario directly is complex without modifying Mario's render graph.
        -- For now, we scale Mario down and let the mount model take over visually.
        if m.playerIndex == 0 then
            m.marioObj.header.gfx.scale.x = 0.5
            m.marioObj.header.gfx.scale.y = 0.5
            m.marioObj.header.gfx.scale.z = 0.5
            m.marioObj.header.gfx.pos.y = m.marioObj.header.gfx.pos.y + 50
        end
    end
end

id_bhvMountVisual = hook_behavior(nil, OBJ_LIST_DEFAULT, false, bhv_mount_visual_init, bhv_mount_visual_loop)

function mounts_on_mario_update(m)
    if m.playerIndex ~= 0 then return end

    if gPlayerSyncTable[0].active_mount then
        local mDef = Mounts.registry[gPlayerSyncTable[0].active_mount]

        -- Spawn Visual
        if not m.mountVisualSpawned then
            local obj = spawn_non_sync_object(
                id_bhvMountVisual,
                mDef.model,
                m.pos.x, m.pos.y, m.pos.z,
                nil
            )
            obj.oBehParams = m.playerIndex
            m.mountVisualSpawned = true
        end

        -- Apply Physics
        if mDef then
            if m.action == ACT_WALKING or m.action == ACT_RUNNING then
                m.forwardVel = m.forwardVel * mDef.speedMult
            end

            -- Press Z to dismount
            if (m.controller.buttonPressed & Z_TRIG) ~= 0 then
                gPlayerSyncTable[0].active_mount = nil
                m.marioObj.header.gfx.scale.x = 1.0
                m.marioObj.header.gfx.scale.y = 1.0
                m.marioObj.header.gfx.scale.z = 1.0
                play_sound(SOUND_OBJ_YOSHI_MEOW, m.marioObj.header.gfx.cameraToObject)
                djui_chat_message_create("Dismounted.")
            end
        end
    else
        m.mountVisualSpawned = false
        m.marioObj.header.gfx.scale.x = 1.0
        m.marioObj.header.gfx.scale.y = 1.0
        m.marioObj.header.gfx.scale.z = 1.0
    end
end

function Mounts.toggle(m, mountId)
    if m.playerIndex ~= 0 then return end

    if gPlayerSyncTable[0].active_mount == mountId then
        gPlayerSyncTable[0].active_mount = nil
        djui_chat_message_create("Dismounted.")
    else
        if Mounts.registry[mountId] then
            gPlayerSyncTable[0].active_mount = mountId
            djui_chat_message_create("Summoned " .. Mounts.registry[mountId].name)
            play_sound(SOUND_GENERAL_YOSHI_WALK, m.marioObj.header.gfx.cameraToObject)
        end
    end
end

-- Hook into inventory usage
function on_inventory_use(m, itemId)
    if string.match(itemId, "^mount_") then
        Mounts.toggle(m, itemId)
        return true -- handled
    end
    return false
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, mounts_on_mario_update)
