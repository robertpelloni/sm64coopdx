-- Termite Transformation Definition

local E_MODEL_TERMITE = smlua_model_util_get_id("scuttlebug_geo") -- Placeholder

Transformation.register("termite", {
    name = "Termite",
    modelId = E_MODEL_TERMITE,
    speed = 20.0, -- Slow on ground?
    jumpForce = 20.0, -- Weak jump
    abilities = {
        wallCling = true -- Flag for logic in main.lua
    }
})

-- Chat command to test
function on_transform(msg)
    local m = gMarioStates[0]
    if msg == "termite" then
        Transformation.set(m, "termite")
    elseif msg == "clear" then
        Transformation.clear(m)
    end
    return true
end

hook_chat_command("transform", "Transform into [termite|clear]", on_transform)
