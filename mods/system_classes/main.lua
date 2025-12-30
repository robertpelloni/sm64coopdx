-- name: System - Classes
-- description: RPG Class system with active abilities.

_G.Classes = {}

-- Enum
Classes.TYPE_NONE = 0
Classes.TYPE_WARRIOR = 1
Classes.TYPE_MAGE = 2
Classes.TYPE_ROGUE = 3

-- State
local COOLDOWN_ABILITY_1 = 30 * 5 -- 5 seconds
local COOLDOWN_ABILITY_2 = 30 * 10 -- 10 seconds

-- Define Classes
Classes.defs = {
    [Classes.TYPE_WARRIOR] = {
        name = "Warrior",
        desc = "High health, strong melee.",
        hp_bonus = 2, -- +2 wedges
        speed_mult = 0.9,
        ability_1 = "Bash (Stun)",
        ability_2 = "Rage (Invulnerability)"
    },
    [Classes.TYPE_MAGE] = {
        name = "Mage",
        desc = "Ranged magic, glass cannon.",
        hp_bonus = -1,
        speed_mult = 1.0,
        ability_1 = "Fireball",
        ability_2 = "Teleport"
    },
    [Classes.TYPE_ROGUE] = {
        name = "Rogue",
        desc = "Fast, stealthy.",
        hp_bonus = 0,
        speed_mult = 1.2,
        ability_1 = "Dash",
        ability_2 = "Invisibility"
    }
}

-- Actions
local ACT_CLASS_ABILITY_1 = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_ATTACKING)
local ACT_CLASS_ABILITY_2 = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_INTANGIBLE)

function Classes.set_class(m, type)
    local sTable = gPlayerSyncTable[m.playerIndex]
    sTable.classType = type

    local def = Classes.defs[type]
    if def then
        djui_chat_message_create("Class set to: " .. def.name)
    end
end

-- Hook into Physics (Perks system already handles generic speed/hp, but let's override here for specificity)
-- Actually, let's keep it simple and just handle Abilities for this pilot.

function classes_update(m)
    if m.playerIndex ~= 0 then return end

    local sTable = gPlayerSyncTable[m.playerIndex]
    local cType = sTable.classType or 0

    if cType == 0 then return end

    -- Inputs for Abilities
    -- Let's map Ability 1 to X and Ability 2 to Y (if available) or D-Pad
    -- SM64 buttons: A, B, Z, Start, L, R, C-Buttons.
    -- B is Attack/Interact.
    -- Z is Crouch/Ground Pound.
    -- L is Camera/Menu.
    -- R is Camera/Menu.
    -- X/Y are usually mapped to B/A or not present.

    -- Let's use D-Pad Left/Right for abilities since we use Up/Down for Weapon Wheel/Inventory.

    -- Cooldown Management (Local)
    if not m.classCooldown1 then m.classCooldown1 = 0 end
    if not m.classCooldown2 then m.classCooldown2 = 0 end

    if m.classCooldown1 > 0 then m.classCooldown1 = m.classCooldown1 - 1 end
    if m.classCooldown2 > 0 then m.classCooldown2 = m.classCooldown2 - 1 end

    -- Ability 1 Input
    if m.controller.buttonPressed & L_JPAD ~= 0 and m.classCooldown1 == 0 then
        -- Trigger Ability 1
        perform_ability_1(m, cType)
    end

    -- Ability 2 Input
    if m.controller.buttonPressed & R_JPAD ~= 0 and m.classCooldown2 == 0 then
        -- Trigger Ability 2
        perform_ability_2(m, cType)
    end
end

function perform_ability_1(m, type)
    m.classCooldown1 = COOLDOWN_ABILITY_1

    if type == Classes.TYPE_MAGE then
        -- Fireball
        spawn_sync_object(
            id_bhvFlameMovingForwardGrowing,
            E_MODEL_RED_FLAME,
            m.pos.x, m.pos.y + 100, m.pos.z,
            function(o) o.oMoveAngleYaw = m.faceAngle.y end
        )
        set_mario_action(m, ACT_PUNCHING, 0)

    elseif type == Classes.TYPE_WARRIOR then
        -- Bash / Ground Pound impact
        set_mario_action(m, ACT_GROUND_POUND_LANDING, 0)

    elseif type == Classes.TYPE_ROGUE then
        -- Dash
        set_mario_action(m, ACT_DIVE, 0)
        m.forwardVel = 80
    end
end

function perform_ability_2(m, type)
    m.classCooldown2 = COOLDOWN_ABILITY_2

    if type == Classes.TYPE_MAGE then
        -- Teleport (Blink forward)
        local dist = 500
        m.pos.x = m.pos.x + dist * math.sin(m.faceAngle.y / 0x8000 * math.pi)
        m.pos.z = m.pos.z + dist * math.cos(m.faceAngle.y / 0x8000 * math.pi)
        m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE

    elseif type == Classes.TYPE_WARRIOR then
        -- Rage (Metal for short time)
        m.capTimer = 30 * 5 -- 5 seconds metal
        m.flags = m.flags | MARIO_METAL_CAP

    elseif type == Classes.TYPE_ROGUE then
        -- Invisibility
        m.marioBodyState.modelState = MODEL_STATE_NOISE_ALPHA
    end
end

hook_event(HOOK_MARIO_UPDATE, classes_update)

-- Command to switch class
function on_class_command(msg)
    local m = gMarioStates[0]
    if msg == "warrior" then Classes.set_class(m, Classes.TYPE_WARRIOR)
    elseif msg == "mage" then Classes.set_class(m, Classes.TYPE_MAGE)
    elseif msg == "rogue" then Classes.set_class(m, Classes.TYPE_ROGUE)
    else djui_chat_message_create("Classes: warrior, mage, rogue") end
    return true
end

hook_chat_command("class", "Set class", on_class_command)

-- HUD for Cooldowns
function classes_hud()
    local m = gMarioStates[0]
    local sTable = gPlayerSyncTable[m.playerIndex]

    if not sTable.classType or sTable.classType == 0 then return end

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()

    -- Draw slots bottom center
    local x = w / 2 - 60
    local y = h - 60

    -- Slot 1
    djui_hud_set_color(0, 0, 0, 100)
    djui_hud_render_rect(x, y, 40, 40)
    if m.classCooldown1 and m.classCooldown1 > 0 then
        djui_hud_set_color(255, 0, 0, 200)
        local ratio = m.classCooldown1 / COOLDOWN_ABILITY_1
        djui_hud_render_rect(x, y + 40 * (1-ratio), 40, 40 * ratio)
    end
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("L", x + 12, y + 12, 1)

    -- Slot 2
    x = x + 60
    djui_hud_set_color(0, 0, 0, 100)
    djui_hud_render_rect(x, y, 40, 40)
    if m.classCooldown2 and m.classCooldown2 > 0 then
        djui_hud_set_color(255, 0, 0, 200)
        local ratio = m.classCooldown2 / COOLDOWN_ABILITY_2
        djui_hud_render_rect(x, y + 40 * (1-ratio), 40, 40 * ratio)
    end
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("R", x + 12, y + 12, 1)
end

hook_event(HOOK_ON_HUD_RENDER, classes_hud)
