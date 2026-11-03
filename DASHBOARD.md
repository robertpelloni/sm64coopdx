# Project Dashboard & Centralized Systems Overview

## 1. Consolidated In-Game MMO Dashboard
The in-game dashboard (`mods/system_menu/main.lua`) consolidates all major gameplay, economy, adventure, and administrative systems into a single-page, intuitively grouped hub accessible in-game via **L-Trigger + START** (or `/menu`).

### High-Value Functional Groupings:
1. **Character & Combat Domain**:
   - **`[Gear] Equipment`**: Interactive gear sheet (`mods/system_equipment/`) for weapons, shields, and passive badges with active stat displays.
   - **`[Bag] Inventory`**: Universal Inventory (`mods/system_inventory/`) managing items, consumables, materials, and coin balances.
   - **`[RPG] Class & Skills`**: Class talent progression (`mods/system_classes/`) for Warrior, Mage, and Rogue with ability hotkeys.
   - **`[Hero] Stats & Progress`**: Progression attributes (`mods/system_progression/`) tracking level, current EXP, HP, Mana, and combat multipliers.

2. **Economy & Social Domain**:
   - **`[Market] Auction House`**: Global asynchronous marketplace (`mods/system_auction_house/`) with D-Pad price spinners and automated mail deliveries.
   - **`[Trade] Direct P2P Trade`**: Real-time peer-to-peer trade system (`mods/system_trading/`) for secure item and currency transactions between adjacent players.
   - **`[Post] Mailbox`**: Persistent messaging and attachment transfer (`mods/system_mail/`) with recipient selector and safe storage.
   - **`[Guild] Guild Hall & Bank`**: Social groups (`mods/system_guilds/`) featuring dedicated guild chat, shared instanced Guild Hall, and authoritative Guild Bank storage (`bank.lua`).
   - **`[Party] Group Manager`**: Cooperative party management (`mods/system_party/`) providing HUD health bars, party chat, and friendly fire protection.

3. **World & Adventure Domain**:
   - **`[Map] Fast Travel`**: Waypoint teleportation (`mods/system_waypoints/`) and seamless contiguous world connections between levels.
   - **`[Quest] Quest Log & Dailies`**: Mission log (`mods/system_quests/`) tracking campaign quests, daily tasks, bounties, and rewards.
   - **`[Gauntlet] Dungeons & Raids`**: Instanced challenges (`mods/content_dungeon/`, `mods/content_tower/`, `mods/content_raid_boss/`).
   - **`[Home] Housing & Decor`**: Instanced player housing (`mods/system_housing/`) with furniture placement and visitor permissions.
   - **`[Feats] Achievements`**: Title and milestone tracking (`mods/system_achievements/`) rewarding gameplay feats.

4. **System & Administrative Controls**:
   - **`[Guide] In-Game Encyclopedia`**: Comprehensive in-game manual (`mods/system_help/`) covering mechanics, abilities, and commands.
   - **`[Settings] System Config`**: Configuration manager (`mods/system_config/`) for client preferences and batch saving (`SaveManager`).
   - **`[Admin] Server Admin Tools`**: Host moderation suite (`mods/system_admin/`) for player management, weather manipulation, and events.
   - **`[Exit] Close Dashboard`**: Instant dismissal returning control directly to Mario (`ACT_IDLE`).

---

## 2. Server Tray & Process Controller
A dedicated process controller is provided in `developer/server_tray.py` allowing developers and hosts to manage the SM64CoopDX server instance:
- **Graphical System Tray**: Displays a tray icon with quick actions:
  - *Start Server*
  - *Stop Server*
  - *Restart Server*
  - *Quit*
- **Headless / CLI Mode**: Fallback for headless environments:
  - `./developer/server_tray.py start` (launches headless server on port 7777)
  - `./developer/server_tray.py stop` (safely terminates server process)
  - `./developer/server_tray.py restart` (restarts running server)
  - `./developer/server_tray.py status` (reports PID and active status)
  - `./developer/server_tray.py logs` (tails last 25 lines of server output)
  - `./developer/server_tray.py interactive` (interactive CLI console)

---

## 3. Project Directory Structure
- **`src/`**: C engine core and platform layer (PC port, networking, rendering, audio).
- **`mods/`**: Mod subsystem directory implementing all MMORPG mechanics.
- **`developer/`**: Developer build, debug, and process supervision tools.
- **`tests/`**: Integration and security test suites executable with `lua5.3`.

## 4. Version Governance
**Current Build:** v1.17
**Source of Truth:** `VERSION.md`
