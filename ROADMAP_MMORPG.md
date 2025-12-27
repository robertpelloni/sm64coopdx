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
| **Banjo-Kazooie** | **Transformation:** Turning into objects (Termite, Crocodile). <br> **Split-Up:** Controlling separate entities (Banjo vs. Kazooie). | **Partial:** Model swapping exists. <br> **Missing:** Mechanics for unique physics per form. | **Lua:** Create custom Action states for transformations with unique physics/collision boxes. |
| **Spyro the Dragon** | **Gliding:** Horizontal traversal. <br> **Charging:** High-speed ground attack. | **Missing.** | **Lua:** Implement a "Gliding" action state (gravity reduction + forward velocity). |
| **Ape Escape** | **Gadgets:** Net, Sling, RC Car (Right stick mechanics). | **Missing.** | **Lua:** Inventory system via `gPlayerSyncTable`. Right-stick input mapping for gadget usage. |

### Generation 6: Refinement & Expansion (GC / PS2 / Xbox)
*The era of tools, weapons, and connected worlds.*

| Game | Notable Features | Current SM64CoopDX Status | Implementation Strategy |
| :--- | :--- | :--- | :--- |
| **Super Mario Sunshine** | **FLUDD:** Hover nozzle, Turbo nozzle, Rocket nozzle. | **Partial:** Mods exist. | **Lua:** Standardize a FLUDD mod into the core API or a verified mod package. Needs particle syncing. |
| **Jak and Daxter** | **Seamless World:** No load times between zones. <br> **Vehicles:** Zoomer bikes. | **No:** SM64 uses discrete levels. | **Engine (Long-term):** Level streaming. <br> **Lua (Short-term):** "Warp" zones that are instant. Vehicle physics via custom objects. |
| **Ratchet & Clank** | **Weapon Wheel:** Selecting/leveling guns. <br> **Strafing:** TPS combat movement. | **Missing.** | **Lua:** UI rendering for Weapon Wheel. Raycasting for projectiles. Syncing ammo/XP via `sync_table`. |
| **Psychonauts** | **PSI Powers:** Telekinesis, Levitation ball. | **Missing.** | **Lua:** Interaction system to "grab" remote objects (Telekinesis). |

### Generation 7: Experimentation (Wii / PS3)
*The era of gravity and physics gimmicks.*

| Game | Notable Features | Current SM64CoopDX Status | Implementation Strategy |
| :--- | :--- | :--- | :--- |
| **Super Mario Galaxy** | **Gravity:** Walking on walls/ceilings, spherical planetoids. | **Missing/Hard:** Engine assumes Y-down gravity. | **C Engine:** Major rewrite of physics engine to support arbitrary gravity vectors (`surface_normal` alignment). |
| **Sonic Generations** | **Boost:** Instant high-speed state with blur/FOV change. | **Missing.** | **Lua:** Action state with extreme forward velocity and FOV manipulation (`camera_set_fov`). |

### Generation 8/9: Mastery (Switch / PS5)
*The era of fluid control and possession.*

| Game | Notable Features | Current SM64CoopDX Status | Implementation Strategy |
| :--- | :--- | :--- | :--- |
| **Super Mario Odyssey** | **Cappy (Capture):** Throwing a cap to control enemies. <br> **Momentum Preservation:** Rolling/diving fluidity. | **Partial:** Mods exist. | **Lua:** "Possession" implies disabling Mario's rendering, attaching camera to Target, and mapping inputs to Target's behavior. |
| **A Hat in Time** | **Badges:** Equippable passive perks (No bonk, magnet). <br> **Hookshot:** Swinging from points. | **Missing.** | **Lua:** `gPlayerSyncTable` for equipped badges. Hookshot requires a tether physics calculation. |

---

## Part 2: The MMORPG Roadmap

To support "thousands of players" and persistent worlds, the architecture must shift from Peer-to-Peer (P2P) to a Client-Server Authority model with Interest Management.

### Phase 1: Gameplay Feature Parity (The "Content" Layer)
*Goal: Implement the mechanics to make the game fun.*
1.  **Universal Inventory System (Lua):** Create a standard API for holding items (Weapons, Gadgets, Badges).
2.  **Extended Action State Machine (Lua/C):** Formalize a system for "Transformation" states (Flying, Swimming as Fish, Hovering) that automatically syncs animations and hitboxes.
3.  **Entity Possession API (Lua):** Create a standard `possess_object(obj)` function that handles camera/input transfer.

### Phase 2: World & Progression (The "RPG" Layer)
*Goal: Give players a reason to stay.*
1.  **Persistent Save Data (Server-Side):** Move `save_file` from local disk to a database connected to the server.
2.  **Global Economy:** Sync currency (Coins/Notes) authoritatively.
3.  **Seamless Level Transitions:** Pre-load adjacent levels to simulate an open world (Jak & Daxter style).

### Phase 3: The MMO Tech Stack (The "Massive" Layer)
*Goal: Support 1000+ Players.*
1.  **Interest Management / Spatial Partitioning:**
    *   *Problem:* Currently, every player syncs every object to every other player. O(N^2).
    *   *Solution:* Implement an Octree or Grid system. Only send packets about entities within a radius (e.g., 10,000 units).
2.  **Dedicated Server Architecture:**
    *   Separate the "Server" logic from the "Client" logic completely. Run the game in "Headless Mode" (already partially supported) but optimized for high concurrency.
3.  **Instancing:**
    *   Allow multiple copies of the same level (e.g., "Bob-omb Battlefield Instance 1") to prevent overcrowding.

---

## Immediate Next Steps
1.  **Approve this roadmap.**
2.  **Select a "Pilot Feature"** from the Gen 5 list (e.g., *Spyro's Glide* or *Banjo's Transformation*) to implement as a proof-of-concept for the new extensible system.
