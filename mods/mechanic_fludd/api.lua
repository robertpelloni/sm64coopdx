-- name: Mechanic - FLUDD
-- description: Adds Water Pack mechanics (Hover, Rocket, Turbo) from Super Mario Sunshine.

_G.FLUDD = {}

-- Constants
FLUDD.MAX_WATER = 1000
FLUDD.REGEN_RATE = 2 -- Water regen when in water

-- Nozzle Types
FLUDD.NOZZLE_NONE = 0
FLUDD.NOZZLE_HOVER = 1
FLUDD.NOZZLE_ROCKET = 2
FLUDD.NOZZLE_TURBO = 3

-- State Management
function FLUDD.get_state(m)
    local sTable = gPlayerSyncTable[m.playerIndex]
    if not sTable.fluddWater then
        sTable.fluddWater = FLUDD.MAX_WATER
        sTable.fluddNozzle = FLUDD.NOZZLE_NONE
        sTable.fluddActive = false
    end
    return sTable
end

function FLUDD.use_water(m, amount)
    local s = FLUDD.get_state(m)
    if s.fluddWater >= amount then
        s.fluddWater = s.fluddWater - amount
        return true
    end
    return false
end

function FLUDD.refill(m)
    local s = FLUDD.get_state(m)
    s.fluddWater = FLUDD.MAX_WATER
end

-- Integration with Inventory
function FLUDD.has_nozzle(m, type)
    if not _G.Inventory then return true end -- Fallback if inventory system missing

    local item = "nozzle_hover"
    if type == FLUDD.NOZZLE_ROCKET then item = "nozzle_rocket" end
    if type == FLUDD.NOZZLE_TURBO then item = "nozzle_turbo" end

    return Inventory.get_count(m, item) > 0
end
