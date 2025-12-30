-- name: System - Anti-Cheat
-- description: Server-side validation for movement and resources.

local AC = {}
AC.MAX_SPEED_GROUND = 200 -- Standard max is ~48-60, boost is ~120
AC.MAX_SPEED_AIR = 250
AC.VIOLATION_THRESHOLD = 30 -- Frames of violation before action

-- Tracking state
local PlayerHistory = {}

function ac_init_player(i)
    if not PlayerHistory[i] then
        PlayerHistory[i] = {
            violations = 0,
            lastPos = {x=0, y=0, z=0},
            warned = false
        }
    end
end

function ac_check_movement(m)
    -- Only Server runs this
    if not network_is_server() then return end
    if m.playerIndex == 0 then return end -- Trust host/server itself

    local i = m.playerIndex
    ac_init_player(i)
    local hist = PlayerHistory[i]

    -- Calculate horizontal speed
    local hSpeed = math.sqrt(m.vel.x^2 + m.vel.z^2)

    -- Determine Context limit
    local limit = AC.MAX_SPEED_GROUND
    if (m.action & ACT_GROUP_MASK) == ACT_GROUP_AIRBORNE then
        limit = AC.MAX_SPEED_AIR
    end

    -- Exceptions: Cannon, Shell, Boost Mod, FLUDD Turbo
    if m.action == ACT_SHOT_FROM_CANNON or
       m.action == ACT_RIDING_SHELL_GROUND or
       m.action == ACT_RIDING_SHELL_FALL or
       (m.action & ACT_FLAG_RIDING_SHELL) ~= 0 then
        return -- Allow high speed
    end

    -- Check Boost Mod (via sync table check if possible, or just relaxed limit)
    -- If using Sonic Boost, speed can be high.
    -- We'll assume 300 is a safe hard cap for now.
    local HARD_CAP = 400

    if hSpeed > HARD_CAP then
        hist.violations = hist.violations + 1
    else
        if hist.violations > 0 then hist.violations = hist.violations - 1 end
    end

    if hist.violations > AC.VIOLATION_THRESHOLD then
        if not hist.warned then
            print("ANTI-CHEAT: Player " .. gNetworkPlayers[i].name .. " detected speeding! (" .. math.floor(hSpeed) .. ")")
            djui_chat_message_create("Server Warning: Movement anomaly detected for " .. gNetworkPlayers[i].name)
            hist.warned = true
        end

        -- Rubberband?
        -- m.pos.x = hist.lastPos.x
        -- m.pos.y = hist.lastPos.y
        -- m.pos.z = hist.lastPos.z
        -- m.vel.x = 0
        -- m.vel.z = 0

        -- Reset violation to prevent spam
        hist.violations = 0
    end

    -- Store valid pos
    if hist.violations == 0 then
        hist.lastPos.x = m.pos.x
        hist.lastPos.y = m.pos.y
        hist.lastPos.z = m.pos.z
    end
end

hook_event(HOOK_MARIO_UPDATE, ac_check_movement)

-- Resource Checks (Coins)
-- We track the previous coin count. If it jumps by more than X in one frame, flag it.
local CoinHistory = {}

function ac_check_coins(m)
    if not network_is_server() then return end
    if m.playerIndex == 0 then return end

    local i = m.playerIndex
    if not CoinHistory[i] then CoinHistory[i] = m.numCoins end

    local diff = m.numCoins - CoinHistory[i]

    -- Max possible coins in 1 frame?
    -- 1 (Yellow), 2 (Blue/Red?), 5 (Blue).
    -- If they collect a cluster, maybe 10-20?
    -- If they kill a boss, maybe 100?
    -- Let's set a suspicious threshold.

    if diff > 100 then
        print("ANTI-CHEAT: Player " .. gNetworkPlayers[i].name .. " gained " .. diff .. " coins instantly.")
        -- Revert?
        -- m.numCoins = CoinHistory[i]
        -- Hard to revert sync fields reliably without fighting the client.
        -- Just Log for now.
    end

    CoinHistory[i] = m.numCoins
end

hook_event(HOOK_MARIO_UPDATE, ac_check_coins)
