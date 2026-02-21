-- name: System - Party
-- description: Group players for shared chat, waypoints, and no friendly fire.

_G.Party = {}
_G.Party.members = {} -- List of global indices in party (client-side view)
_G.Party.leader = nil -- Global index of leader
_G.Party.invites = {} -- List of pending invites (from whom)

-- Packet Types
local PACKET_INVITE = 0
local PACKET_JOIN = 1
local PACKET_LEAVE = 2
local PACKET_KICK = 3
local PACKET_CHAT = 4
local PACKET_UPDATE = 5 -- Sync full list (for late joiners or updates)

-- Helper: Get Name
local function get_name(i)
    if not gNetworkPlayers[i].connected then return "???" end
    return gNetworkPlayers[i].name
end

-- Network Handler
function on_party_packet(p)
    local m = gMarioStates[0]

    if p.type == PACKET_INVITE then
        if p.target == m.playerIndex then
            table.insert(_G.Party.invites, p.sender)
            djui_chat_message_create("Party: Invited by " .. get_name(p.sender))
            djui_chat_message_create("Type /party join " .. get_name(p.sender))
            play_sound(SOUND_MENU_MESSAGE_APPEAR, m.marioObj.header.gfx.cameraToObject)
        end

    elseif p.type == PACKET_JOIN then
        -- Ideally, only leader manages the list and broadcasts updates.
        -- But for simplicity, we can trust the packet if valid.
        -- Let's stick to Leader-Authority model.
        if m.playerIndex == _G.Party.leader then
            -- Add to our list and broadcast update
            -- Validation logic...
        end
        -- For now, purely client-side trust or broadcasted "User Joined" message?
        -- Let's use a simpler "Shared State" approach where updates are broadcasted.

        -- Actually, for robustness, let's just show the message.
        -- The `members` list should be synced via `gPlayerSyncTable`?
        -- `gPlayerSyncTable` is player-specific.
        -- We can put `partyId` in `gPlayerSyncTable`!
        -- If `partyId` matches, we are in the same party.
        -- Leader is the one with the lowest playerIndex in that partyId?
        -- Or just track it locally.

        -- Strategy: `gPlayerSyncTable.partyId`.
        -- 0 = No Party.
        -- >0 = Party ID (e.g., Leader's Global Index + Timestamp or random).

    elseif p.type == PACKET_CHAT then
        -- Check if we are in same party (handled by sender usually, but verify)
        -- packet should contain partyId?
        -- Let's just use the `partyId` sync table approach for membership.
        -- Packet is just for the message.
        local senderState = gPlayerSyncTable[p.sender]
        local myState = gPlayerSyncTable[0]

        if senderState.partyId and senderState.partyId == myState.partyId and myState.partyId ~= 0 then
            djui_chat_message_create("\\#00ffff\\[Party] " .. get_name(p.sender) .. ":\\#ffffff\\ " .. p.msg)
        end
    end
end

hook_event(HOOK_ON_PACKET_RECEIVE, on_party_packet)

-- Sync Table Logic
function party_update(m)
    if m.playerIndex ~= 0 then return end
    local s = gPlayerSyncTable[0]
    if not s.partyId then s.partyId = 0 end
end

hook_event(HOOK_MARIO_UPDATE, party_update)

-- Commands
function on_party_command(msg)
    local m = gMarioStates[0]
    local s = gPlayerSyncTable[0]
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end

    local cmd = args[1]

    if cmd == "create" then
        if s.partyId ~= 0 then
            djui_chat_message_create("You are already in a party.")
            return true
        end
        -- Generate ID: (LocalIndex + 1) * 10000 + Random(1000)?
        -- Or just use random integer.
        s.partyId = math.random(1, 999999)
        djui_chat_message_create("Party created! ID: " .. s.partyId)

    elseif cmd == "invite" then
        if s.partyId == 0 then
            djui_chat_message_create("Create a party first: /party create")
            return true
        end
        local targetName = args[2]
        if not targetName then
            djui_chat_message_create("Usage: /party invite [name]")
            return true
        end

        -- Find target
        local targetIdx = -1
        for i = 1, MAX_PLAYERS - 1 do
            if gNetworkPlayers[i].connected and gNetworkPlayers[i].name == targetName then
                targetIdx = i
                break
            end
        end

        if targetIdx ~= -1 then
            network_send(true, {
                type = PACKET_INVITE,
                sender = m.playerIndex,
                target = targetIdx
            })
            djui_chat_message_create("Invited " .. targetName)
        else
            djui_chat_message_create("Player not found.")
        end

    elseif cmd == "join" then
        if s.partyId ~= 0 then
            djui_chat_message_create("Leave your current party first.")
            return true
        end

        -- Join by Name (find their partyId)
        local targetName = args[2]
        if not targetName then
            djui_chat_message_create("Usage: /party join [name]")
            return true
        end

        local targetIdx = -1
        for i = 1, MAX_PLAYERS - 1 do
            if gNetworkPlayers[i].connected and gNetworkPlayers[i].name == targetName then
                targetIdx = i
                break
            end
        end

        if targetIdx ~= -1 then
            local ts = gPlayerSyncTable[targetIdx]
            if ts.partyId and ts.partyId ~= 0 then
                s.partyId = ts.partyId
                djui_chat_message_create("Joined " .. targetName .. "'s party!")
            else
                djui_chat_message_create(targetName .. " is not in a party.")
            end
        else
            djui_chat_message_create("Player not found.")
        end

    elseif cmd == "leave" then
        if s.partyId == 0 then
            djui_chat_message_create("You are not in a party.")
        else
            s.partyId = 0
            djui_chat_message_create("Left the party.")
        end

    else
        djui_chat_message_create("Party Commands: create, invite, join, leave")
    end
    return true
end

function on_party_chat(msg)
    local s = gPlayerSyncTable[0]
    if s.partyId == 0 then
        djui_chat_message_create("You are not in a party.")
        return true
    end

    network_send(true, {
        type = PACKET_CHAT,
        sender = 0,
        msg = msg
    })

    -- Echo locally
    djui_chat_message_create("\\#00ffff\\[Party] " .. gNetworkPlayers[0].name .. ":\\#ffffff\\ " .. msg)
    return true
end

hook_chat_command("party", "Manage party", on_party_command)
hook_chat_command("p", "Party chat", on_party_chat)

-- HUD Render
function party_hud()
    local s = gPlayerSyncTable[0]
    if not s or not s.partyId or s.partyId == 0 then return end

    local w = djui_hud_get_screen_width()
    local h = djui_hud_get_screen_height()

    local x = 20
    local y = h / 2 - 100

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Party Members:", x, y, 1)
    y = y + 20

    -- Self
    djui_hud_set_color(0, 255, 255, 255)
    djui_hud_print_text(gNetworkPlayers[0].name, x, y, 1)
    y = y + 20

    -- Others
    for i = 1, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected then
            local ts = gPlayerSyncTable[i]
            if ts and ts.partyId == s.partyId then
                -- Name
                djui_hud_set_color(200, 200, 255, 255)
                djui_hud_print_text(gNetworkPlayers[i].name, x, y, 1)

                -- Distance / Direction?
                -- Simple HP bar? (Requires HP sync, usually wedges)
                -- Let's just show health wedges (0-8)
                local tm = gMarioStates[i]
                local hp = math.ceil(tm.health / 256)
                local hpStr = ""
                for k=1, hp do hpStr = hpStr .. "|" end

                djui_hud_print_text(" " .. hpStr, x + 100, y, 1)

                y = y + 20

                -- Waypoint (if far)
                local dist = dist_between_objects(gMarioStates[0].marioObj, tm.marioObj)
                if dist > 2000 then
                    -- Draw arrow at screen edge?
                    -- Complex math, let's skip for prototype, just show name in HUD.
                end
            end
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, party_hud)

-- Friendly Fire Protection
function party_allow_pvp(attacker, victim)
    -- Check if both are in same party
    local as = gPlayerSyncTable[attacker.playerIndex]
    local vs = gPlayerSyncTable[victim.playerIndex]

    if as and vs and as.partyId ~= 0 and as.partyId == vs.partyId then
        return false -- Block damage
    end
    return true
end

hook_event(HOOK_ALLOW_PVP_ATTACK, party_allow_pvp)
