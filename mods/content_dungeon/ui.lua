-- name: Content - Dungeon UI
-- description: UI for selecting Dungeon difficulties and tracking runs.
-- depends: system_ui, content_dungeon

_G.Dungeon = {}
_G.DungeonUI = {}

local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function DungeonUI.render()
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local items = {
        { id = "normal", name = "Normal Mode", desc = "Standard difficulty. Base rewards." },
        { id = "heroic", name = "Heroic Mode", desc = "Tougher enemies. Better loot." },
        { id = "mythic", name = "Mythic Mode", desc = "Ultimate challenge. Exclusive titles." }
    }

    local renderDetails = function(x, y, selItem)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(selItem.name, x, y, 1.2)
        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(selItem.desc, x, y + 40, 25, 0.9)

        djui_hud_set_color(150, 255, 150, 255)
        djui_hud_print_text("Press A to Enter", x, y + 100, 0.8)
    end

    UIToolkit.draw_menu("CRYPT OF THE VANISHED", items, SELECTION, SCROLL_OFFSET, renderDetails, "A: Enter  B: Close", "Select a difficulty to begin the dungeon instance.")
end

function DungeonUI.update(m)
    if m.playerIndex ~= 0 then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local items = {"normal", "heroic", "mythic"}
    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, #items, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, #items)

    if act then
        local diff = items[SELECTION]
        local inst = math.random(1000, 9999)
        local sTable = gPlayerSyncTable[0]
        sTable.instanceID = inst

        -- We can store difficulty in the sync table for the dungeon master to read
        sTable.dungeonDifficulty = diff

        if initiate_warp then
            -- DUNGEON_LEVEL = LEVEL_BBH, DUNGEON_AREA = 1
            initiate_warp(LEVEL_BBH, 1, 1, 0)
        end

        _G.PENDING_DUNGEON_SPAWN = true
        djui_chat_message_create("Entering Crypt of the Vanished (" .. diff .. ")...")

        UI_VISIBLE = false
        set_mario_action(m, ACT_IDLE, 0)
    end

    if close then
        UI_VISIBLE = false
        set_mario_action(m, ACT_IDLE, 0)
    end
end

function DungeonUI.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

hook_event(HOOK_ON_HUD_RENDER, DungeonUI.render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, DungeonUI.update)
