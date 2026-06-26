-- name: System - Classes
-- description: RPG Class system with active abilities and talent paths.

_G.Classes = {}

-- Enum
Classes.TYPE_NONE = 0
Classes.TYPE_WARRIOR = 1
Classes.TYPE_MAGE = 2
Classes.TYPE_ROGUE = 3

-- State
local COOLDOWN_ABILITY_1 = 30 * 5 -- 5 seconds
local COOLDOWN_ABILITY_2 = 30 * 10 -- 10 seconds

-- Costs
local MANA_COST_LOW = 10
local MANA_COST_HIGH = 30

-- Local state for cooldowns
local ClassState = {}

local function get_class_state(playerIndex)
    if not ClassState[playerIndex] then
        ClassState[playerIndex] = {cd1 = 0, cd2 = 0}
    end
    return ClassState[playerIndex]
end

-- Define Classes & Talents
Classes.defs = {
    [Classes.TYPE_WARRIOR] = {
        name = "Warrior",
        desc = "High health, strong melee.",
        hp_bonus = 2,
        speed_mult = 0.9,
        ability_1 = "Bash (Stun)",
        ability_2 = "Rage (Invulnerability)",
        talents = {
            {id = "war_t1", name = "Deep Strikes", desc = "Increases Bash damage."},
            {id = "war_t2", name = "Endless Rage", desc = "Increases Rage duration."}
        }
    },
    [Classes.TYPE_MAGE] = {
        name = "Mage",
        desc = "Ranged magic, glass cannon.",
        hp_bonus = -1,
        speed_mult = 1.0,
        ability_1 = "Fireball",
        ability_2 = "Teleport",
        talents = {
            {id = "mag_t1", name = "Pyromaniac", desc = "Increases Fireball speed."},
            {id = "mag_t2", name = "Wormhole", desc = "Increases Teleport distance."}
        }
    },
    [Classes.TYPE_ROGUE] = {
        name = "Rogue",
        desc = "Fast, stealthy.",
        hp_bonus = 0,
        speed_mult = 1.2,
        ability_1 = "Dash",
        ability_2 = "Invisibility",
        talents = {
            {id = "rog_t1", name = "Fleet Foot", desc = "Increases Dash distance."},
            {id = "rog_t2", name = "Shadows", desc = "Reduces Invisibility mana cost."}
        }
    }
}

function Classes.set_class(m, type)
    local sTable = gPlayerSyncTable[m.playerIndex]
    sTable.classType = type

    local def = Classes.defs[type]
    if def then
        djui_chat_message_create("Class set to: " .. def.name)
    end
end

-- Helper to check talent
function Classes.has_talent(m, talentId)
    local sTable = gPlayerSyncTable[m.playerIndex]
    if not sTable.talents then return false end
    -- Simple comma separated string for sync
    return string.find(sTable.talents, talentId) ~= nil
end

function Classes.unlock_talent(m, talentId)
    local sTable = gPlayerSyncTable[m.playerIndex]
    if not sTable.talents then sTable.talents = "" end
    if not string.find(sTable.talents, talentId) then
        sTable.talents = sTable.talents .. talentId .. ","
        return true
    end
    return false
end

function classes_update(m)
    if m.playerIndex ~= 0 then return end

    if _G.MENU_OPEN or (_G.Trade and gPlayerSyncTable[0].tradeStatus ~= 0) then return end

    local sTable = gPlayerSyncTable[m.playerIndex]
    local cType = sTable.classType or 0
    if cType == 0 then return end

    local cs = get_class_state(m.playerIndex)
    if cs.cd1 > 0 then cs.cd1 = cs.cd1 - 1 end
    if cs.cd2 > 0 then cs.cd2 = cs.cd2 - 1 end

    if m.controller.buttonPressed & L_JPAD ~= 0 and cs.cd1 == 0 then
        perform_ability_1(m, cType, cs)
    end

    if m.controller.buttonPressed & R_JPAD ~= 0 and cs.cd2 == 0 then
        perform_ability_2(m, cType, cs)
    end
end

function perform_ability_1(m, type, cs)
    local cost = MANA_COST_LOW

    if _G.Combat then
        if not Combat.use_mana(m, cost) then return end
    end

    cs.cd1 = COOLDOWN_ABILITY_1

    if type == Classes.TYPE_MAGE then
        local speed = 50
        if Classes.has_talent(m, "mag_t1") then speed = 80 end

        local obj = spawn_sync_object(
            id_bhvFlameMovingForwardGrowing,
            E_MODEL_RED_FLAME,
            m.pos.x, m.pos.y + 100, m.pos.z,
            function(o) o.oMoveAngleYaw = m.faceAngle.y end
        )
        set_mario_action(m, ACT_PUNCHING, 0)

    elseif type == Classes.TYPE_WARRIOR then
        set_mario_action(m, ACT_GROUND_POUND_LANDING, 0)
        -- Talent logic (war_t1) would increase damage calculation in Combat hook

    elseif type == Classes.TYPE_ROGUE then
        local speed = 80
        if Classes.has_talent(m, "rog_t1") then speed = 120 end

        set_mario_action(m, ACT_DIVE, 0)
        m.forwardVel = speed
    end
end

function perform_ability_2(m, type, cs)
    local cost = MANA_COST_HIGH

    if type == Classes.TYPE_ROGUE and Classes.has_talent(m, "rog_t2") then
        cost = MANA_COST_LOW -- Talent: Reduced cost
    end

    if _G.Combat then
        if not Combat.use_mana(m, cost) then return end
    end

    cs.cd2 = COOLDOWN_ABILITY_2

    if type == Classes.TYPE_MAGE then
        local dist = 500
        if Classes.has_talent(m, "mag_t2") then dist = 1000 end -- Talent: Longer blink

        local oldX = m.pos.x
        local oldZ = m.pos.z

        m.pos.x = m.pos.x + dist * math.sin(m.faceAngle.y / 0x8000 * math.pi)
        m.pos.z = m.pos.z + dist * math.cos(m.faceAngle.y / 0x8000 * math.pi)

        local floorHeight = find_floor_height(m.pos.x, m.pos.y + 100, m.pos.z)
        if floorHeight < -10000 then
            m.pos.x = oldX
            m.pos.z = oldZ
            djui_chat_message_create("Cannot teleport there!")
            cs.cd2 = 0
            return
        end

        if m.pos.y < floorHeight then m.pos.y = floorHeight end
        m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE

    elseif type == Classes.TYPE_WARRIOR then
        local duration = 5
        if Classes.has_talent(m, "war_t2") then duration = 8 end -- Talent: Longer rage

        m.capTimer = 30 * duration
        m.flags = m.flags | MARIO_METAL_CAP

    elseif type == Classes.TYPE_ROGUE then
        m.marioBodyState.modelState = MODEL_STATE_NOISE_ALPHA
    end
end

hook_event(HOOK_MARIO_UPDATE, classes_update)

function classes_hud()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]
    local cs = get_class_state(m.playerIndex)

    if not sTable.classType or sTable.classType == 0 then return end

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()

    -- Draw slots bottom center
    local x = w / 2 - 60
    local y = h - 60

    -- Slot 1
    djui_hud_set_color(0, 0, 0, 100)
    djui_hud_render_rect(x, y, 40, 40)
    if cs.cd1 > 0 then
        djui_hud_set_color(255, 0, 0, 200)
        local ratio = cs.cd1 / COOLDOWN_ABILITY_1
        djui_hud_render_rect(x, y + 40 * (1-ratio), 40, 40 * ratio)
    end
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("L", x + 12, y + 12, 1)

    -- Slot 2
    x = x + 60
    djui_hud_set_color(0, 0, 0, 100)
    djui_hud_render_rect(x, y, 40, 40)
    if cs.cd2 > 0 then
        djui_hud_set_color(255, 0, 0, 200)
        local ratio = cs.cd2 / COOLDOWN_ABILITY_2
        djui_hud_render_rect(x, y + 40 * (1-ratio), 40, 40 * ratio)
    end
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("R", x + 12, y + 12, 1)
end

hook_event(HOOK_ON_HUD_RENDER, classes_hud)

-- Hook UI to command
function on_class_command(msg)
    if _G.ClassesUI and _G.Classes.toggle_ui then
        _G.Classes.toggle_ui()
    else
        djui_chat_message_create("Class UI not available.")
    end
    return true
end

hook_chat_command("class", "Open class selection menu", on_class_command)
