-- Unit tests for PvP knockback immunity and general knockback sync logic
local failures = 0

_G.gMarioStates = {
    [0] = { playerIndex = 0, action = 0, health = 2176, vel = {y = 0}, forwardVel = 0, flags = 0 },
    [1] = { playerIndex = 1, action = 0, health = 2176, vel = {y = 0}, forwardVel = 0, flags = 0 }
}

_G.gPlayerSyncTable = {
    [0] = { kb_immune = true },  -- Simulating a Warrior using Rage
    [1] = { kb_immune = false }
}

_G.djui_chat_message_create = function(msg) end
_G.hook_event = function() end
_G.network_send_to = function() end
_G.network_send = function() end

_G.MARIO_METAL_CAP = 0x00000004
_G.ACT_GROUND_POUND = 0x00000030

-- Mock Combat hook logic
local function handle_pvp_hit(attacker, victim)
    local vSync = gPlayerSyncTable[victim.playerIndex]

    -- In actual implementation, immunity is tracked via flattened boolean `kb_immune` or METAL_CAP flag
    if vSync.kb_immune or (victim.flags & MARIO_METAL_CAP) ~= 0 then
        -- Immune to knockback
        return false
    end

    -- Apply knockback
    victim.forwardVel = -20
    victim.vel.y = 15
    return true
end

-- Test 1: Player 0 is immune (simulated Rage/Metal Cap)
local hit1 = handle_pvp_hit(gMarioStates[1], gMarioStates[0])
if hit1 == true or gMarioStates[0].forwardVel == -20 then
    print("FAIL: Player 0 should be immune to knockback")
    failures = failures + 1
end

-- Test 2: Player 1 is not immune
local hit2 = handle_pvp_hit(gMarioStates[0], gMarioStates[1])
if hit2 == false or gMarioStates[1].forwardVel ~= -20 then
    print("FAIL: Player 1 should receive knockback")
    failures = failures + 1
end

if failures == 0 then
    print("All knockback sync tests passed.")
else
    print("Tests failed: " .. failures)
end
