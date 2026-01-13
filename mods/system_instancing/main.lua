-- name: System - Instancing
-- description: Allows players to switch between "dimensions" to avoid overcrowding.

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
