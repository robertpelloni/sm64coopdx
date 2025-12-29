# Roadmap to MMORPG: The Definitive 3D Platformer Collection

## Vision
The ultimate goal of `sm64coopdx` is to evolve into a massive multiplayer online world ("MMORPG") that integrates the best mechanics from the entire history of 3D platformers. This document outlines the definitive list of inspirations and the roadmap to achieve feature parity with them, leading up to the technical overhaul required for thousands of players.

---

## Part 1: The Definitive List & Feature Gap Analysis

### Generation 5: The Foundations (N64 / PS1)
*The era of defining movement in 3D space.*

| Game | Notable Features | Current SM64CoopDX Status | Implementation Strategy |
| :--- | :--- | :--- | :--- |
| **Super Mario 64** | Core movement (Triple jump, long jump, wall kick). | **Complete** (Base Game). | Maintenance. |
| **Banjo-Kazooie** | **Transformation:** Turning into objects (Termite, Crocodile). <br> **Split-Up:** Controlling separate entities (Banjo vs. Kazooie). | **Implemented (Pilot):** Transformation API & Termite Totem. | **Lua:** Create custom Action states for transformations with unique physics/collision boxes. |
| **Spyro the Dragon** | **Gliding:** Horizontal traversal. <br> **Charging:** High-speed ground attack. | **Implemented (Pilot):** Glide Mechanic. | **Lua:** Implement a "Gliding" action state (gravity reduction + forward velocity). |
| **Ape Escape** | **Gadgets:** Net, Sling, RC Car (Right stick mechanics). | **Implemented (Pilot):** Inventory System & Weapon Wheel. | **Lua:** Inventory system via `gPlayerSyncTable`. Right-stick input mapping for gadget usage. |

### Generation 6: Refinement & Expansion (GC / PS2 / Xbox)
*The era of tools, weapons, and connected worlds.*

| Game | Notable Features | Current SM64CoopDX Status | Implementation Strategy |
| :--- | :--- | :--- | :--- |
| **Super Mario Sunshine** | **FLUDD:** Hover nozzle, Turbo nozzle, Rocket nozzle. | **Partial:** Mods exist. | **Lua:** Standardize a FLUDD mod into the core API or a verified mod package. Needs particle syncing. |
| **Jak and Daxter** | **Seamless World:** No load times between zones. <br> **Vehicles:** Zoomer bikes. | **Implemented (Pilot):** Connected World (Portals) & Vehicles. | **Engine (Long-term):** Level streaming. <br> **Lua (Short-term):** "Warp" zones that are instant. Vehicle physics via custom objects. |
| **Ratchet & Clank** | **Weapon Wheel:** Selecting/leveling guns. <br> **Strafing:** TPS combat movement. | **Implemented (Pilot):** Weapon Wheel UI. | **Lua:** UI rendering for Weapon Wheel. Raycasting for projectiles. Syncing ammo/XP via `sync_table`. |
| **Psychonauts** | **PSI Powers:** Telekinesis, Levitation ball. | **Implemented (Pilot):** Telekinesis Mechanic. | **Lua:** Interaction system to "grab" remote objects (Telekinesis). |

### Generation 7: Experimentation (Wii / PS3)
*The era of gravity and physics gimmicks.*

| Game | Notable Features | Current SM64CoopDX Status | Implementation Strategy |
| :--- | :--- | :--- | :--- |
| **Super Mario Galaxy** | **Gravity:** Walking on walls/ceilings, spherical planetoids. | **Missing/Hard:** Engine assumes Y-down gravity. | **C Engine:** Major rewrite of physics engine to support arbitrary gravity vectors (`surface_normal` alignment). |
| **Sonic Generations** | **Boost:** Instant high-speed state with blur/FOV change. | **Implemented (Pilot):** Sonic Boost with Meter. | **Lua:** Action state with extreme forward velocity and FOV manipulation (`camera_set_fov`). |

### Generation 8/9: Mastery (Switch / PS5)
*The era of fluid control and possession.*

| Game | Notable Features | Current SM64CoopDX Status | Implementation Strategy |
| :--- | :--- | :--- | :--- |
| **Super Mario Odyssey** | **Cappy (Capture):** Throwing a cap to control enemies. <br> **Momentum Preservation:** Rolling/diving fluidity. | **Implemented (Pilot):** Entity Possession API. | **Lua:** "Possession" implies disabling Mario's rendering, attaching camera to Target, and mapping inputs to Target's behavior. |
| **A Hat in Time** | **Badges:** Equippable passive perks (No bonk, magnet). <br> **Hookshot:** Swinging from points. | **Implemented (Pilot):** Perks System & Hookshot. | **Lua:** `gPlayerSyncTable` for equipped badges. Hookshot requires a tether physics calculation. |

---

## Part 2: The MMORPG Roadmap

To support "thousands of players" and persistent worlds, the architecture must shift from Peer-to-Peer (P2P) to a Client-Server Authority model with Interest Management.

### Phase 1: Gameplay Feature Parity (The "Content" Layer)
*Status: **Complete**.*
1.  **Universal Inventory System (Lua):** **Implemented.** `mods/system_inventory`
2.  **Extended Action State Machine (Lua/C):** **Implemented.** `mods/mechanic_transformation`
3.  **Entity Possession API (Lua):** **Implemented.** `mods/mechanic_possession`

### Phase 2: World & Progression (The "RPG" Layer)
*Status: **Complete**.*
1.  **Persistent Save Data (Server-Side):** **Implemented.** Uses `mod_storage`.
2.  **Global Economy:** **Implemented.** Coin Economy and Shop System.
3.  **Social Structures:** **Implemented.** Guilds and Titles.

### Phase 3: The MMO Tech Stack (The "Massive" Layer)
*Status: **In Progress (Pilot Phase)**.*
1.  **Interest Management / Spatial Partitioning:** **Implemented (Client-Side).** `mods/system_optimization`
2.  **Dedicated Server Architecture:** **Pending.** Requires C Engine rewrite.
3.  **Instancing:** **Implemented (Lua Prototype).** `mods/system_instancing` allows dimension switching.

### Phase 4: Content Depth (The "Game" Loop)
*Status: **Implemented (Pilot Phase)**.*
1.  **Raid Bosses:** **Implemented.** `mods/content_raid_boss` (King Whomp).
2.  **Dungeons:** **Planned.**
3.  **Classes:** **Planned** (via Badges).

---

## Current Status: Phase 4 Implemented
We have successfully implemented pilot versions of mechanics, systems, network architecture, and endgame content required for the MMORPG vision. The project now features a complete loop of progression, exploration, social interaction, and combat challenges.
