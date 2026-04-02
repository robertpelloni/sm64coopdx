# Roadmap to MMORPG: The Definitive 3D Platformer Collection

## Vision
The ultimate goal of `sm64coopdx` is to evolve into a massive multiplayer online world ("MMORPG") that integrates the best mechanics from the entire history of 3D platformers.

---

## Part 1: The Definitive List & Feature Gap Analysis

| Game | Notable Features | Current SM64CoopDX Status |
| :--- | :--- | :--- |
| **Super Mario 64** | Core movement. | **Complete** (Base Game). |
| **Banjo-Kazooie** | **Transformation:** Turning into objects. | **Complete** (`mods/mechanic_transformation`). |
| **Spyro the Dragon** | **Gliding:** Horizontal traversal. | **Complete** (`mods/mechanic_glide`). |
| **Ape Escape** | **Gadgets:** Net, Sling, RC Car. | **Complete** (`mods/system_weapon_wheel`). |
| **Super Mario Sunshine** | **FLUDD:** Hover, Turbo, Rocket nozzles. | **Complete** (`mods/mechanic_fludd`). |
| **Jak and Daxter** | **Vehicles:** Zoomer bikes. | **Complete** (`mods/mechanic_vehicle`). |
| **Ratchet & Clank** | **Weapon Wheel & Upgrades.** | **Complete** (`mods/system_weapon_wheel`, `mods/mechanic_weapons`). |
| **Psychonauts** | **PSI Powers:** Telekinesis. | **Complete** (`mods/mechanic_telekinesis`). |
| **Super Mario Galaxy** | **Gravity:** Launch Stars. | **Complete** (`mods/mechanic_gravity`). |
| **Sonic Generations** | **Boost:** Instant high-speed state. | **Complete** (`mods/mechanic_boost`). |
| **Super Mario Odyssey** | **Possession:** Controlling enemies. | **Complete** (`mods/mechanic_possession`). |
| **A Hat in Time** | **Badges & Hookshot.** | **Complete** (`mods/system_perks`, `mods/mechanic_hookshot`). |
| **Breath of the Wild** | **Free Climbing & Stamina.** | **Complete** (`mods/mechanic_climbing`). |

---

## Part 2: The MMORPG Roadmap

### Phase 1: Gameplay Feature Parity
*Status: **Complete**.*
All core traversal and combat mechanics from the target inspirations have been implemented as Lua modules.

### Phase 2: World, Economy, & Progression
*Status: **Complete**.*
Universal Inventory, Guilds, Parties, Trading, Mail, Housing, Fishing, Mining, Crafting, Leveling (1-100), and Stat distribution are fully active and integrated with the UI.

### Phase 3: The MMO Tech Stack
*Status: **Active / In Progress**.*
1.  **Headless Server:** **Complete.** C engine supports `--headless`.
2.  **Anti-Cheat:** **Complete.** Server-side validation, rubber-banding, and auto-kicks.
3.  **UI Standardization:** **Complete.** Centralized `UIToolkit` manages all menus with comprehensive tooltips.
4.  **Database/Persistence:** **Active.** Utilizing `mod_storage` with string sanitization. Needs optimization for scale.
5.  **Dedicated Server Rewrite:** **Pending.** Deep C engine refactor to support thousands of concurrent players cleanly.

### Phase 4: Content Depth
*Status: **Active**.*
1.  **Dungeons:** Crypt of the Vanished (Complete).
2.  **Raids:** King Whomp (Complete).
3.  **Endless Modes:** Tower of Trials (Complete).
4.  **Daily Quests:** **Pending.**
5.  **Equipment Manager UI:** **Pending.**

## Summary
The project is structurally robust and feature-rich. Immediate next steps involve UI hookups for the Auction House, Mail attachments, an Equipment Manager, and generating Daily Quests.
