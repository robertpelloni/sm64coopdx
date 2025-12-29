-- Core Logic for Classes

-- Custom Actions for Abilities
local ACT_CLASS_ABILITY_1 = allocate_mario_action(ACT_GROUP_ATTACKING | ACT_FLAG_ATTACKING | ACT_FLAG_MOVING)
local ACT_CLASS_ABILITY_2 = allocate_mario_action(ACT_GROUP_ATTACKING | ACT_FLAG_ATTACKING) -- Stationary? Or Moving? Let's make it flexible.

-- Helper to get active class def
local function get_active_def(m)
    local id = Class.get(m)
    if not id then return nil end
    return Class.get_def(id)
end

function act_class_ability_1(m)
    local def = get_active_def(m)
    if not def or not def.ability1 then
        set_mario_action(m, ACT_IDLE, 0)
        return 1
    end

    -- Delegate to class specific function
    -- The function should return 1 if action is finished, 0 if continuing.
    -- If it returns nothing, we assume it's ongoing until we manually switch?
    -- Safe pattern: Pass `m` and `step` info.
    return def.ability1(m)
end

function act_class_ability_2(m)
    local def = get_active_def(m)
    if not def or not def.ability2 then
        set_mario_action(m, ACT_IDLE, 0)
        return 1
    end
    return def.ability2(m)
end

hook_mario_action(ACT_CLASS_ABILITY_1, act_class_ability_1)
hook_mario_action(ACT_CLASS_ABILITY_2, act_class_ability_2)

-- Input Hook
function class_input_update(m)
    if m.playerIndex ~= 0 then return end

    local def = get_active_def(m)
    if not def then return end

    -- Check Inputs
    -- Ability 1: X Button (Replaces Boost if Class active? Or maybe another button?)
    -- Let's use X for Ability 1. If Class is set, Boost mechanic might conflict.
    -- We should check if Boost allows it.
    -- Ideally, "Class" overrides "Boost".

    if (m.controller.buttonPressed & X_BUTTON) ~= 0 then
        -- Check cooldown? (Not implemented yet, but good for future)
        if def.ability1 then
            set_mario_action(m, ACT_CLASS_ABILITY_1, 0)
        end
    end

    -- Ability 2: Y Button (Replaces Hookshot?)
    -- Y is used for Hookshot.
    -- Conflict resolution: If Hookshot item equipped?
    -- Maybe classes use D-Pad? Or L/R?
    -- Let's use R_TRIG (Telekinesis conflict) or L_TRIG (Weapon Wheel conflict).
    -- Actually, simpler: Button combos? Z + A?
    -- Let's stick to X and Y for now. If you have a Class, it takes priority over generic tools like Hookshot/Boost?
    -- Or we allow Hookshot if Ability 2 is nil.

    if (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        if def.ability2 then
            set_mario_action(m, ACT_CLASS_ABILITY_2, 0)
        end
    end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, class_input_update)

-- Integration: Chat Command
function on_class_command(msg)
    local m = gMarioStates[0]
    if msg == "clear" then
        Class.set(m, nil)
    else
        Class.set(m, msg)
    end
    return true
end

hook_chat_command("class", "Set class [name|clear]", on_class_command)
