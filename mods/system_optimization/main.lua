-- name: System - Optimization (Interest Management)
-- description: Client-side optimization to hide distant objects.

local CULL_DIST = 8000

function opt_update(m)
    -- Only run periodically? Every frame is fine for simple distance check.
    if m.playerIndex ~= 0 then return end

    -- Iterate generic actors (Test Agent, Shopkeeper, etc)
    local obj = obj_get_first(OBJ_LIST_GENACTOR)

    while obj do
        local dist = dist_between_objects(m.marioObj, obj)

        if dist > CULL_DIST then
            -- Hide
            if (obj.header.gfx.node.flags & GRAPH_RENDER_ACTIVE) ~= 0 then
                obj.header.gfx.node.flags = obj.header.gfx.node.flags & ~GRAPH_RENDER_ACTIVE
            end
        else
            -- Show
            if (obj.header.gfx.node.flags & GRAPH_RENDER_ACTIVE) == 0 then
                obj.header.gfx.node.flags = obj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
            end
        end

        obj = obj_get_next(obj)
    end
end

hook_event(HOOK_MARIO_UPDATE, opt_update)
