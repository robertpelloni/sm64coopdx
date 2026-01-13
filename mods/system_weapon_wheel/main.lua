-- name: System - Weapon Wheel
-- description: Ratchet & Clank style weapon selection wheel.

local WHEEL_OPEN = false
local SELECTION_INDEX = 0
local SCREEN_WIDTH = djui_hud_get_screen_width()
local SCREEN_HEIGHT = djui_hud_get_screen_height()

function weapon_wheel_render()
    if not WHEEL_OPEN then return end
    if not _G.Inventory then return end

    local m = gMarioStates[0]
    local items = Inventory.get_all_items(m)
    local count = #items
    if count == 0 then return end

    local cx = djui_hud_get_screen_width() / 2
    local cy = djui_hud_get_screen_height() / 2
    local radius = 100

    -- Draw Background
    djui_hud_set_color(0, 0, 0, 150)
    djui_hud_render_rect(cx - 150, cy - 150, 300, 300)

    -- Draw Items
    for i, item in ipairs(items) do
        local angle = (i - 1) * (360 / count) * (math.pi / 180) - (math.pi / 2)
        local ix = cx + math.cos(angle) * radius
        local iy = cy + math.sin(angle) * radius

        if i == SELECTION_INDEX then
            djui_hud_set_color(255, 255, 0, 255) -- Highlight Yellow
            djui_hud_render_rect(ix - 25, iy - 25, 50, 50)
        else
            djui_hud_set_color(200, 200, 200, 200)
            djui_hud_render_rect(ix - 20, iy - 20, 40, 40)
        end

        -- Draw Text (Simplified, ideally icons)
        djui_hud_set_color(255, 255, 255, 255)
        local name = item.name or item.id
        local tw = djui_hud_measure_text(name)
        djui_hud_print_text(name, ix - tw/2, iy, 1)
    end
end

function weapon_wheel_update(m)
    if m.playerIndex ~= 0 then return end

    -- Toggle Wheel with L Trigger
    if (m.controller.buttonDown & L_TRIG) ~= 0 then
        WHEEL_OPEN = true

        -- Selection Logic
        local sx = m.controller.stickX
        local sy = m.controller.stickY
        local mag = math.sqrt(sx*sx + sy*sy)

        if mag > 20 then
            local items = Inventory.get_all_items(m)
            local count = #items
            if count > 0 then
                -- Atan2 returns angle in radians.
                -- We offset by 90 deg (pi/2) because our index 1 is at -90 deg (Top)
                local angle = math.atan(sy, sx) -- Note: check if Lua 5.3 atan handles x,y or use atan2
                -- sm64coopdx Lua usually has math.atan2
                if math.atan2 then angle = math.atan2(sy, sx) end

                -- Convert to degrees 0-360 starting from top
                local deg = (angle * 180 / math.pi) + 90
                if deg < 0 then deg = deg + 360 end

                -- Map to index
                local sectorSize = 360 / count
                -- Round to nearest sector
                local idx = math.floor((deg + (sectorSize/2)) / sectorSize) + 1
                if idx > count then idx = 1 end

                SELECTION_INDEX = idx
            end
        end

        -- Lock Controls?
        -- m.freeze = 1 -- Not a standard field?
        -- We can just zero out intendedYaw/Mag to stop movement
        m.intendedMag = 0
    else
        if WHEEL_OPEN then
            -- On Release
            WHEEL_OPEN = false
            local items = Inventory.get_all_items(m)
            if SELECTION_INDEX > 0 and SELECTION_INDEX <= #items then
                local item = items[SELECTION_INDEX]
                djui_chat_message_create("Equipped: " .. item.name)
                -- Trigger equip logic here
            end
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, weapon_wheel_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, weapon_wheel_update)
