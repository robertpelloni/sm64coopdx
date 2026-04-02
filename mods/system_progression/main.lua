-- name: System - Progression
-- description: Leveling, XP, and Stats.

_G.Progression = {}

local MAX_LEVEL = 100
local XP_BASE = 100
local XP_SCALING = 1.2

function Progression.get_xp_required(level)
    return math.floor(XP_BASE * (level ^ XP_SCALING))
end

function Progression.add_xp(m, amount)
    if m.playerIndex ~= 0 then return end

    local sTable = gPlayerSyncTable[m.playerIndex]

    -- Init
    if not sTable.xp then sTable.xp = 0 end
    if not sTable.level then sTable.level = 1 end
    if sTable.level >= MAX_LEVEL then return end

    sTable.xp = sTable.xp + amount
    djui_chat_message_create("+" .. amount .. " XP")

    -- Level Up Check
    local req = Progression.get_xp_required(sTable.level)
    while sTable.xp >= req do
        sTable.xp = sTable.xp - req
        sTable.level = sTable.level + 1
        sTable.statPoints = (sTable.statPoints or 0) + 5

        djui_chat_message_create("LEVEL UP! You are now level " .. sTable.level)
        play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject)

        req = Progression.get_xp_required(sTable.level)
        if sTable.level >= MAX_LEVEL then break end
    end
end

-- Stats
function Progression.get_stat(m, stat)
    local sTable = gPlayerSyncTable[m.playerIndex]
    if stat == "str" then return sTable.stat_str or 0 end
    if stat == "int" then return sTable.stat_int or 0 end
    if stat == "agi" then return sTable.stat_agi or 0 end
    return 0
end

-- UI
function progression_hud()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    if not sTable.level then return end

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()

    -- XP Bar (Yellow/Gold)
    local barW = w - 40
    local barH = 4
    local x = 20
    local y = h - 20

    djui_hud_set_color(0, 0, 0, 150)
    djui_hud_render_rect(x, y, barW, barH)

    local req = Progression.get_xp_required(sTable.level)
    local fill = (sTable.xp / req) * barW
    djui_hud_set_color(255, 215, 0, 200)
    djui_hud_render_rect(x, y, fill, barH)

    -- Level Text
    djui_hud_print_text("Lv." .. sTable.level, x, y - 20, 1)
end

hook_event(HOOK_ON_HUD_RENDER, progression_hud)

-- Stat Allocation Command
function on_stat_command(msg)
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end

    if #args == 0 then
        djui_chat_message_create("Stats: STR="..(sTable.stat_str or 0)..", INT="..(sTable.stat_int or 0)..", AGI="..(sTable.stat_agi or 0))
        djui_chat_message_create("Points Available: " .. (sTable.statPoints or 0))
        djui_chat_message_create("Usage: /stat [str|int|agi] [amount]")
        return true
    end

    local stat = args[1]
    local amount = tonumber(args[2]) or 1

    if not sTable.statPoints or sTable.statPoints < amount then
        djui_chat_message_create("Not enough points.")
        return true
    end

    if stat == "str" then sTable.stat_str = (sTable.stat_str or 0) + amount
    elseif stat == "int" then sTable.stat_int = (sTable.stat_int or 0) + amount
    elseif stat == "agi" then sTable.stat_agi = (sTable.stat_agi or 0) + amount
    else
        djui_chat_message_create("Unknown stat: str, int, agi")
        return true
    end

    sTable.statPoints = sTable.statPoints - amount
    djui_chat_message_create("Increased " .. stat .. " by " .. amount)

    -- Update Derived Stats
    if _G.Combat then
        -- HP from STR
        -- Mana from INT
        -- For sync safety, maybe update maxMana in update loop
    end

    return true
end

hook_chat_command("stat", "Allocate stats", on_stat_command)

-- Update Derived Stats
function progression_update(m)
    if m.playerIndex ~= 0 then return end
    local sTable = gPlayerSyncTable[m.playerIndex]

    local int = sTable.stat_int or 0
    -- Base 100 + 10 per INT
    sTable.maxMana = 100 + (int * 10)
end

hook_event(HOOK_MARIO_UPDATE, progression_update)
