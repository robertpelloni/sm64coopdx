-- name: System - Reputation
-- description: Faction standing and rewards.

_G.Reputation = {}

-- Faction Definitions
_G.Reputation.factions = {
    ["toad"] = {name = "Toad Brigade", desc = "Protectors of the Mushroom Kingdom.", max = 1000},
    ["koopa"] = {name = "Koopa Clan", desc = "The loyal subjects of Bowser.", max = 1000},
    ["bobomb"] = {name = "Bob-omb Resistance", desc = "Explosive rebels seeking freedom.", max = 1000}
}

-- API
function Reputation.add(m, factionId, amount)
    if not _G.Reputation.factions[factionId] then return end

    local sTable = gPlayerSyncTable[m.playerIndex]
    local key = "rep_" .. factionId

    local current = sTable[key] or 0
    local max = _G.Reputation.factions[factionId].max

    local newVal = current + amount
    if newVal > max then newVal = max end
    if newVal < -max then newVal = -max end -- Can have negative rep

    sTable[key] = newVal

    if amount > 0 then
        djui_chat_message_create("+" .. amount .. " Rep (" .. _G.Reputation.factions[factionId].name .. ")")
    else
        djui_chat_message_create(amount .. " Rep (" .. _G.Reputation.factions[factionId].name .. ")")
    end
end

function Reputation.get(m, factionId)
    local sTable = gPlayerSyncTable[m.playerIndex]
    return sTable["rep_" .. factionId] or 0
end

-- Get Rank String
function Reputation.get_rank(rep)
    if rep >= 800 then return "Exalted", {0, 255, 0}
    elseif rep >= 400 then return "Revered", {50, 200, 50}
    elseif rep >= 100 then return "Friendly", {100, 255, 100}
    elseif rep >= -100 then return "Neutral", {200, 200, 200}
    elseif rep >= -400 then return "Unfriendly", {255, 100, 100}
    else return "Hostile", {255, 0, 0} end
end

-- UI
local UI_VISIBLE = false
local SELECTION = 1
local SCROLL_OFFSET = 0
local OPEN_TIMER = 0

function rep_ui_render()
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local m = gMarioStates[0]

    local list = {}
    for id, def in pairs(_G.Reputation.factions) do
        local rep = Reputation.get(m, id)
        local rankName, color = Reputation.get_rank(rep)
        table.insert(list, {
            id = id,
            def = def,
            name = def.name,
            rep = rep,
            rankName = rankName,
            color = color
        })
    end
    table.sort(list, function(a,b) return a.name < b.name end)

    local renderDetails = function(x, y, selItem)
        local def = selItem.def
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(def.name, x, y, 1)

        -- Rank
        local c = selItem.color
        djui_hud_set_color(c[1], c[2], c[3], 255)
        djui_hud_print_text(selItem.rankName .. " (" .. selItem.rep .. ")", x, y + 25, 1)

        -- Description
        djui_hud_set_color(200, 200, 200, 255)
        UIToolkit.draw_wrapped_text(def.desc, x, y + 55, 22, 0.8)
    end

    -- Override the list drawing slightly to show rank color?
    -- UIToolkit doesn't support per-item color yet, so we just use standard.

    -- Format right text to show rank
    for _, item in ipairs(list) do
        item.right_text = item.rankName
    end

    UIToolkit.draw_menu("REPUTATION", list, SELECTION, SCROLL_OFFSET, renderDetails, "B: Close")
end

function rep_ui_update(m)
    if m.playerIndex ~= 0 or not network_is_server() then return end
    if not UI_VISIBLE then return end
    if not _G.UIToolkit then return end

    local list = {}
    for id, _ in pairs(_G.Reputation.factions) do table.insert(list, id) end

    local sel, timer, act, close = UIToolkit.handle_input(m, SELECTION, #list, OPEN_TIMER)
    SELECTION = sel
    OPEN_TIMER = timer
    SCROLL_OFFSET = UIToolkit.calculate_scroll(SELECTION, SCROLL_OFFSET, #list)

    if close then
        UI_VISIBLE = false
    end
end

function Reputation.toggle_ui()
    UI_VISIBLE = not UI_VISIBLE
    if UI_VISIBLE then
        SELECTION = 1
        SCROLL_OFFSET = 0
        OPEN_TIMER = 5
    end
end

function Reputation.close_ui()
    UI_VISIBLE = false
end

hook_event(HOOK_ON_HUD_RENDER, rep_ui_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, rep_ui_update)

-- Test Command
hook_chat_command("rep", "Reputation testing", function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end
    if args[1] == "add" and args[2] and args[3] then
        Reputation.add(gMarioStates[0], args[2], tonumber(args[3]))
        return true
    end
    return false
end)
