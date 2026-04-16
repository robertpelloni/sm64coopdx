-- name: Mechanic - Pets
-- description: Vanity pets that follow the player.

_G.Pets = {}
_G.Pets.active = nil -- Current pet object

-- Pet Definitions
local PET_DEFS = {
    ["pet_bobomb"] = {model = E_MODEL_BLACK_BOBOMB, scale = 0.5},
    ["pet_goomba"] = {model = E_MODEL_GOOMBA, scale = 0.5},
    ["pet_toad"] = {model = smlua_model_util_get_id("toad_geo"), scale = 0.5} -- Using existing model ID from shop
}

-- Behavior
function bhv_pet_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oGravity = -4.0
    o.oFriction = 0.8
    o.oBuoyancy = 1.0
    o.oOpacity = 255
    o.oIntangibleTimer = -1 -- Ghost
end

function bhv_pet_loop(o)
    -- Follow owner
    -- We need to know who owns this pet.
    -- Sync objects don't store "owner" by default unless we put it in a field.
    -- For now, let's assume it follows the player who spawned it (nearest or by syncID mapping).
    -- Better: Store owner global index in oBehParams?

    local ownerIdx = o.oBehParams
    local owner = gMarioStates[ownerIdx]

    if not owner then
        obj_mark_for_deletion(o)
        return
    end

    -- AI: Follow
    local targetX = owner.pos.x - sins(owner.faceAngle.y) * 100
    local targetZ = owner.pos.z - coss(owner.faceAngle.y) * 100
    local targetY = owner.pos.y

    -- Simple movement
    local dx = targetX - o.oPosX
    local dz = targetZ - o.oPosZ
    local dist = math.sqrt(dx*dx + dz*dz)

    if dist > 500 then
        -- Teleport if too far
        o.oPosX = targetX
        o.oPosY = targetY
        o.oPosZ = targetZ
    elseif dist > 50 then
        local speed = 20.0
        local angle = atan2s(dz, dx)
        o.oVelX = sins(angle) * speed -- Wait, atan2s returns angle from Z?
        -- Standard trig: atan2(y, x) -> angle.
        -- Mario coords: Z is "Y", X is "X".
        -- Let's use approach logic.

        o.oPosX = approach_f32(o.oPosX, targetX, speed, speed)
        o.oPosZ = approach_f32(o.oPosZ, targetZ, speed, speed)
        o.oPosY = approach_f32(o.oPosY, targetY, 10.0, 10.0)

        o.oMoveAngleYaw = angle
    end

    -- Ground
    local floorHeight = find_floor(o.oPosX, o.oPosY + 100, o.oPosZ)
    if o.oPosY < floorHeight then o.oPosY = floorHeight end
end

local id_bhvPet = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_pet_init, bhv_pet_loop)

function Pets.summon(m, id)
    if m.playerIndex ~= 0 then return end

    -- Dismiss existing
    if _G.Pets.active then
        obj_mark_for_deletion(_G.Pets.active)
        _G.Pets.active = nil
    end

    local def = PET_DEFS[id]
    if not def then return end

    local obj = spawn_sync_object(
        id_bhvPet,
        def.model,
        m.pos.x, m.pos.y, m.pos.z,
        function(o)
            o.oBehParams = m.playerIndex
            obj_scale(o, def.scale)
        end
    )
    _G.Pets.active = obj
    djui_chat_message_create("Summoned " .. id)
end

function Pets.dismiss()
    if _G.Pets.active then
        obj_mark_for_deletion(_G.Pets.active)
        _G.Pets.active = nil
        djui_chat_message_create("Pet dismissed.")
    end
end

-- Command
hook_chat_command("pet", "Summon pet", function(msg)
    local m = gMarioStates[0]
    if msg == "dismiss" then
        Pets.dismiss()
    elseif PET_DEFS["pet_" .. msg] then
        Pets.summon(m, "pet_" .. msg)
    else
        djui_chat_message_create("Pets: bobomb, goomba, toad")
    end
    return true
end)
