-- Core Logic for Classes

-- Custom Actions for Abilities
local ACT_CLASS_ABILITY_1 = allocate_mario_action(ACT_GROUP_ATTACKING | ACT_FLAG_ATTACKING | ACT_FLAG_MOVING)
local ACT_CLASS_ABILITY_2 = allocate_mario_action(ACT_GROUP_ATTACKING | ACT_FLAG_ATTACKING)

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

    if (m.controller.buttonPressed & X_BUTTON) ~= 0 then
        if def.ability1 then
            -- Combat Check
            if Combat then
                if Combat.is_on_cooldown(m, "ab1") then
                    play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
                    return
                end
                if not Combat.use_mana(m, 20) then return end
                Combat.start_cooldown(m, "ab1", 60) -- 2 seconds default
            end

            set_mario_action(m, ACT_CLASS_ABILITY_1, 0)
        end
    end

    if (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        if def.ability2 then
            -- Combat Check
            if Combat then
                if Combat.is_on_cooldown(m, "ab2") then
                    play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
                    return
                end
                if not Combat.use_mana(m, 40) then return end
                Combat.start_cooldown(m, "ab2", 150) -- 5 seconds
            end

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
