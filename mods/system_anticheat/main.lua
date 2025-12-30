-- name: System - Anti-Cheat
-- description: Server-side validation for movement and resources with Active Enforcement.

local AC = {}
AC.MAX_SPEED_GROUND = 200
AC.MAX_SPEED_AIR = 250
AC.VIOLATION_THRESHOLD = 30 -- Frames of violation before warning
AC.KICK_THRESHOLD = 5 -- Number of rubberbands before kick

-- Tracking state
local PlayerHistory = {}

function ac_init_player(i)
    if not PlayerHistory[i] then
        PlayerHistory[i] = {
            violations = 0,
            rubberbands = 0,
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

    -- Context Check
    local isHighSpeedAction = (
        m.action == ACT_SHOT_FROM_CANNON or
        m.action == ACT_RIDING_SHELL_GROUND or
        m.action == ACT_RIDING_SHELL_FALL or
        (m.action & ACT_FLAG_RIDING_SHELL) ~= 0 or
        m.action == ACT_BOOST
    )

    local HARD_CAP = 400
    if isHighSpeedAction then HARD_CAP = 800 end

    if hSpeed > HARD_CAP then
        hist.violations = hist.violations + 1
    else
        if hist.violations > 0 then hist.violations = hist.violations - 1 end
    end

    -- Active Enforcement
    if hist.violations > AC.VIOLATION_THRESHOLD then
        -- Action 1: Rubberband
        if hist.rubberbands < AC.KICK_THRESHOLD then
            -- Reset position to last valid
            m.pos.x = hist.lastPos.x
            m.pos.y = hist.lastPos.y
            m.pos.z = hist.lastPos.z
            m.vel.x = 0
            m.vel.y = 0
            m.vel.z = 0

            hist.rubberbands = hist.rubberbands + 1
            hist.violations = 0 -- Reset violation counter, but keep rubberband count

            djui_chat_message_create("Server: " .. gNetworkPlayers[i].name .. " was rubberbanded for speeding.")
            print("AC: Rubberbanded " .. gNetworkPlayers[i].name)
        else
            -- Action 2: Kick
            djui_chat_message_create("Server: Kicking " .. gNetworkPlayers[i].name .. " for persistent cheating.")
            print("AC: Kicking " .. gNetworkPlayers[i].name)

            if network_player_kick then
                network_player_kick(i)
            else
                print("AC Error: network_player_kick not available!")
            end

            -- Reset state in case they rejoin
            hist.rubberbands = 0
            hist.violations = 0
        end
    end

    -- Store valid pos (only if no violation pending)
    if hist.violations == 0 then
        hist.lastPos.x = m.pos.x
        hist.lastPos.y = m.pos.y
        hist.lastPos.z = m.pos.z
    end
end

hook_event(HOOK_MARIO_UPDATE, ac_check_movement)

-- Resource Checks (Coins)
local CoinHistory = {}

function ac_check_coins(m)
    if not network_is_server() then return end
    if m.playerIndex == 0 then return end

    local i = m.playerIndex
    if not CoinHistory[i] then CoinHistory[i] = m.numCoins end

    local diff = m.numCoins - CoinHistory[i]

    if diff > 100 then
        print("AC: Player " .. gNetworkPlayers[i].name .. " gained " .. diff .. " coins instantly.")
        -- Log only for now
    end

    CoinHistory[i] = m.numCoins
end

hook_event(HOOK_MARIO_UPDATE, ac_check_coins)
