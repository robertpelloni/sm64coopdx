-- Goomba Transformation Definition

local E_MODEL_GOOMBA = smlua_model_util_get_id("goomba_geo")

Transformation.register("goomba", {
    name = "Goomba",
    modelId = E_MODEL_GOOMBA,
    speed = 15.0, -- Slower
    jumpForce = 25.0, -- Normal jump
    abilities = {}
})

-- Trigger via chat for testing (optional, since we have the item now)
function on_transform_goomba(msg)
    local m = gMarioStates[0]
    if msg == "goomba" then
        Transformation.set(m, "goomba")
    end
    return true
end

hook_chat_command("goomba", "Transform into Goomba", on_transform_goomba)
