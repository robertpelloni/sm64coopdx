-- name: System - Unified Save Manager
-- description: Batches mod_storage_save calls across systems to reduce disk I/O.
-- depends: system_inventory, system_mail, system_auction_house, system_housing

_G.SaveManager = {}

-- Flag tracks if a save is pending
local SAVE_PENDING = false

--- Request a save. The actual write will happen periodically.
function SaveManager.request_save()
    SAVE_PENDING = true
end

--- Internal function to actually write all data
local function execute_save()
    if not SAVE_PENDING then return end
    if not network_is_server() and gMarioStates[0].playerIndex ~= 0 then return end -- Only authority or local player saves

    local savedSystems = 0

    if _G.Inventory and Inventory.save then
        Inventory.save()
        savedSystems = savedSystems + 1
    end

    if _G.Mail and Mail.save then
        Mail.save()
        savedSystems = savedSystems + 1
    end

    if _G.AuctionHouse and AuctionHouse.save then
        AuctionHouse.save()
        savedSystems = savedSystems + 1
    end

    if _G.Housing and Housing.save then
        Housing.save()
        savedSystems = savedSystems + 1
    end

    SAVE_PENDING = false
    -- djui_chat_message_create("Autosave complete (" .. tostring(savedSystems) .. " systems).")
end

-- Hook to run every 60 seconds (60 * 30 frames)
function save_manager_update()
    if gGlobalTimer % 1800 == 0 then
        execute_save()
    end
end

-- Also save immediately on level change to prevent data loss
function save_manager_on_level_init()
    execute_save()
end

hook_event(HOOK_UPDATE, save_manager_update)
hook_event(HOOK_ON_LEVEL_INIT, save_manager_on_level_init)
