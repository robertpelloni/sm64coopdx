-- name: System - Instancing
-- description: Allows players to switch between "dimensions" to avoid overcrowding.

function instancing_update(m)
    -- Run mainly on local player to hide others?
    -- Or run on every player to hide themselves if local player is different?
    -- Easiest: Local player iterates others and hides them locally.

    if m.playerIndex ~= 0 then return end

    local localState = gPlayerSyncTable[0]
    local localInst = localState.instanceID or 0

    for i = 1, MAX_PLAYERS - 1 do
        local remoteM = gMarioStates[i]
        if remoteM.marioBodyState.action & ACT_FLAG_ACTIVE ~= 0 then
            local remoteState = gPlayerSyncTable[i]
            local remoteInst = remoteState and remoteState.instanceID or 0

            if localInst ~= remoteInst then
                -- Hide
                obj_set_model_extended(remoteM.marioObj, MODEL_NONE)
            else
                -- Show (Restore default if hidden)
                -- We need to know what character they are playing.
                -- `remoteM.character` struct?
                -- `obj_set_model_extended` overrides the model ID.
                -- If we set it to MODEL_NONE, we need to restore it to... what?
                -- Usually `remoteM.character.modelId` or similar.
                -- sm64coopdx character API might handle this automatically if we stop overriding?
                -- Or we just set it to `MODEL_MARIO` as placeholder if we can't detect.
                -- Better approach: Use `o.header.gfx.node.flags` to hide!
                -- GRAPH_RENDER_ACTIVE = 1 (active)

                -- Hiding via Graph Node flags is cleaner and preserves model ID.
            end
        end
    end
end

function instancing_render_toggle()
    local localState = gPlayerSyncTable[0]
    local localInst = localState.instanceID or 0

    for i = 1, MAX_PLAYERS - 1 do
        local remoteM = gMarioStates[i]
        if remoteM.marioBodyState.action & ACT_FLAG_ACTIVE ~= 0 then
            local remoteState = gPlayerSyncTable[i]
            local remoteInst = remoteState and remoteState.instanceID or 0

            local node = remoteM.marioObj.header.gfx.node

            if localInst ~= remoteInst then
                -- Disable Render
                node.flags = node.flags & ~GRAPH_RENDER_ACTIVE
            else
                -- Enable Render
                node.flags = node.flags | GRAPH_RENDER_ACTIVE
            end
        end
    end
end

-- Command
function on_instance(msg)
    local id = tonumber(msg)
    if id then
        local sTable = gPlayerSyncTable[0]
        sTable.instanceID = id
        djui_chat_message_create("Switched to Instance " .. id)
    else
        djui_chat_message_create("Usage: /instance [id]")
    end
    return true
end

hook_chat_command("instance", "Switch instance", on_instance)
hook_event(HOOK_MARIO_UPDATE, instancing_render_toggle) -- Run every frame to ensure flags stay set
