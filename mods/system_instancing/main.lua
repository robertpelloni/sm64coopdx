-- name: System - Instancing
-- description: Allows players to switch between "dimensions" to avoid overcrowding and manage interest.

_G.Instancing = {}

-- Constants for bitwise flags
local GRAPH_RENDER_ACTIVE = 1

function instancing_render_toggle()
    local localState = gPlayerSyncTable[0]
    local localInst = localState.instanceID or 0

    for i = 1, MAX_PLAYERS - 1 do
        local np = gNetworkPlayers[i]
        if np and np.connected then
            local remoteM = gMarioStates[i]
            if remoteM and remoteM.marioObj and remoteM.marioObj.header and remoteM.marioObj.header.gfx and remoteM.marioObj.header.gfx.node then
                local remoteState = gPlayerSyncTable[i]
                local remoteInst = remoteState and remoteState.instanceID or 0

                local node = remoteM.marioObj.header.gfx.node

                if localInst ~= remoteInst then
                    -- Disable Render and Collision (Interest Management)
                    node.flags = node.flags & ~GRAPH_RENDER_ACTIVE
                    remoteM.marioObj.oIntangibleTimer = -1 -- Force intangible
                else
                    -- Enable Render and Collision
                    node.flags = node.flags | GRAPH_RENDER_ACTIVE
                    remoteM.marioObj.oIntangibleTimer = 0 -- Re-enable tangible
                end
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
        play_sound(SOUND_MENU_CLICK_FILE_SELECT, gMarioStates[0].marioObj.header.gfx.cameraToObject)
    else
        djui_chat_message_create("Usage: /instance [id]")
    end
    return true
end

hook_chat_command("instance", "Switch instance", on_instance)
hook_event(HOOK_MARIO_UPDATE, instancing_render_toggle) -- Run every frame to ensure flags stay set
