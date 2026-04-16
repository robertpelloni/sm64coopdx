-- name: System - UI Manager
-- description: Unifies UI closing logic to prevent overlaps.

_G.UIManager = {}

-- List of registered close functions
local close_funcs = {}

function UIManager.register_close_func(func)
    table.insert(close_funcs, func)
end

function UIManager.close_all()
    for _, func in ipairs(close_funcs) do
        if type(func) == "function" then
            func()
        end
    end
end

-- Fallback check for global UIs if not registered
function UIManager.force_close_all()
    UIManager.close_all()

    if _G.Inventory and _G.Inventory.close_ui then _G.Inventory.close_ui() end
    if _G.Quest and _G.Quest.close_ui then _G.Quest.close_ui() end
    if _G.Achievement and _G.Achievement.close_ui then _G.Achievement.close_ui() end
    if _G.Classes and _G.Classes.close_ui then _G.Classes.close_ui() end
    if _G.Progression and _G.Progression.close_ui then _G.Progression.close_ui() end
    if _G.Mail and _G.Mail.close_ui then _G.Mail.close_ui() end

    -- Some UIs like Shop and Crafting don't have explicit close APIs yet,
    -- or are handled locally. In a full refactor, we would add them.
end
