-- name: System - Config
-- description: Configuration system for MMORPG features.

_G.Config = {}

-- Default Settings
_G.Config.settings = {
    show_hud = true,
    auto_save_interval = 30, -- Seconds
    sound_effects = true,
    music_volume = 100,
    show_nametags = true
}

-- Apply settings hook
function apply_config()
    -- Logic to apply settings
    -- e.g., if not show_hud then prevent HUD render
    -- This requires hooking into other systems or checking this table
end

-- Command to toggle settings
function on_config_command(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end

    if #args == 0 then
        djui_chat_message_create("Config: show_hud, auto_save_interval, sound_effects, show_nametags")
        return true
    end

    local key = args[1]
    local value = args[2]

    if _G.Config.settings[key] ~= nil then
        if value == "true" then _G.Config.settings[key] = true
        elseif value == "false" then _G.Config.settings[key] = false
        elseif tonumber(value) then _G.Config.settings[key] = tonumber(value)
        else
            djui_chat_message_create("Invalid value. Use true/false or number.")
            return true
        end
        djui_chat_message_create("Set " .. key .. " to " .. tostring(_G.Config.settings[key]))
        apply_config()
        save_config()
    else
        djui_chat_message_create("Unknown setting: " .. key)
    end
    return true
end

function save_config()
    local str = ""
    for k, v in pairs(_G.Config.settings) do
        str = str .. k .. ":" .. tostring(v) .. ";"
    end
    mod_storage_save("config_data", str)
end

function load_config()
    local str = mod_storage_load("config_data")
    if not str then return end

    for pair in string.gmatch(str, "([^;]+)") do
        local k, v = string.match(pair, "([^:]+):([^:]+)")
        if k and v then
            if v == "true" then v = true
            elseif v == "false" then v = false
            elseif tonumber(v) then v = tonumber(v)
            end
            _G.Config.settings[k] = v
        end
    end
    apply_config()
end

hook_chat_command("config", "Modify settings", on_config_command)

-- Init
hook_event(HOOK_ON_MODS_LOADED, load_config)
