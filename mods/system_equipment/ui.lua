-- Equipment Manager UI

local EquipmentUI = {
    isOpen = false,
    openTimer = 0,
    selectedIndex = 1,
    scrollOffset = 0,
    mode = "main"
}

local function handle_equipment_input(m)
    if m.playerIndex ~= 0 then return end
    if not EquipmentUI.isOpen then return end

    if EquipmentUI.openTimer > 0 then
        EquipmentUI.openTimer = EquipmentUI.openTimer - 1
        return
    end

    local input = m.controller.buttonPressed

    if EquipmentUI.mode == "main" then
        if (input & D_JPAD) ~= 0 then
            EquipmentUI.selectedIndex = EquipmentUI.selectedIndex + 1
            if EquipmentUI.selectedIndex > 4 then EquipmentUI.selectedIndex = 1 end
        elseif (input & U_JPAD) ~= 0 then
            EquipmentUI.selectedIndex = EquipmentUI.selectedIndex - 1
            if EquipmentUI.selectedIndex < 1 then EquipmentUI.selectedIndex = 4 end
        elseif (input & A_BUTTON) ~= 0 then
            if EquipmentUI.selectedIndex == 1 then
                local success, msg = _G.Equipment.unequip_item("weapon", 1)
                djui_chat_message_create(msg)
            else
                local badgeSlot = EquipmentUI.selectedIndex - 1
                local success, msg = _G.Equipment.unequip_item("badge", badgeSlot)
                djui_chat_message_create(msg)
            end
            EquipmentUI.openTimer = 15
        elseif (input & B_BUTTON) ~= 0 then
            EquipmentUI.isOpen = false
            set_mario_action(m, ACT_IDLE, 0)
        end
    end
end

local function draw_equipment_ui()
    if not EquipmentUI.isOpen then return end
    if not _G.UIToolkit then return end

    local s = gPlayerSyncTable[0]
    local weapon = s.equipped_weapon or "none"
    local badge1 = s.eq_badge_1 or "none"
    local badge2 = s.eq_badge_2 or "none"
    local badge3 = s.eq_badge_3 or "none"

    local items = {
        { name = "Weapon: " .. weapon, tooltip = "Your primary attack weapon." },
        { name = "Badge 1: " .. badge1, tooltip = "Passive perk slot 1." },
        { name = "Badge 2: " .. badge2, tooltip = "Passive perk slot 2." },
        { name = "Badge 3: " .. badge3, tooltip = "Passive perk slot 3." },
    }

    local renderDetails = function(x, y, selItem)
        _G.UIToolkit.draw_wrapped_text("\\#FFFFFF\\" .. selItem.tooltip, x, y, 200, 1.0)
    end

    _G.UIToolkit.draw_menu(
        "Equipment Manager",
        items,
        EquipmentUI.selectedIndex,
        EquipmentUI.scrollOffset,
        renderDetails,
        "[A] Unequip  [B] Close",
        "Manage your equipped weapons and badges here."
    )
end

function EquipmentUI.toggle()
    local m = gMarioStates[0]
    if EquipmentUI.isOpen then
        EquipmentUI.isOpen = false
        set_mario_action(m, ACT_IDLE, 0)
    else
        EquipmentUI.isOpen = true
        EquipmentUI.openTimer = 15
        EquipmentUI.selectedIndex = 1
        EquipmentUI.mode = "main"
        set_mario_action(m, ACT_WAITING_FOR_DIALOG, 0)
    end
end

hook_event(HOOK_ON_HUD_RENDER, draw_equipment_ui)
hook_event(HOOK_MARIO_UPDATE, handle_equipment_input)

-- Register chat command
hook_chat_command("equip", "- Opens the Equipment Manager.", function(msg)
    EquipmentUI.toggle()
    return true
end)

-- Expose UI for main API
_G.EquipmentUI = EquipmentUI
