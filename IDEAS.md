# Project Expansion & Brainstorming Ideas

This document contains creative, out-of-the-box ideas for future pivot points, refactors, and massive feature additions to elevate the MMORPG experience.

## Technical Refactoring & Architecture
1.  **Unified Database Server:** Instead of relying on local `mod_storage` saving to flat files, build a lightweight external Python/Node.js server that the Headless C-Engine communicates with via HTTP/WebSockets to handle all Inventory, Mail, and Auction House transactions. This enables true cross-server persistence.
2.  **Lua Pre-Processor / Bundler:** Create a build script that concatenates and minifies Lua files based on explicit `require` dependency graphs rather than relying on alphabetical loading, completely eliminating nil-reference load crashes.
3.  **Modular UI Definitions:** Move UI layout definitions (text positions, colors) into external JSON/XML config files so non-programmers can redesign menus without touching Lua logic.

## Gameplay Mechanics
1.  **Nemesis System (Shadow of Mordor):** Unique elite enemies that remember the player who killed them (or who they killed), returning stronger with dynamic traits and titles synchronized via the authority server.
2.  **Rhythm Combat (Hi-Fi Rush):** A bard class or specific weapon type that grants massive damage/mana regen multipliers if the attack button is pressed perfectly in time with the BGM tempo.
3.  **Procedural Voxel Destruction (Teardown):** A specific late-game tool (e.g., "Earthquake Hammer") that allows players to permanently deform specific instanced terrain blocks in the housing/mining districts.
4.  **Sailing & Ship Combat (Sea of Thieves):** Expanding the Mount system to multi-crew ships. Players must manage sails, steering, and cannons to fight synchronized sea monsters.

## Social & Economy
1.  **Player-Run Factions:** Allow Guilds to declare war, capture specific level zones (e.g., Bob-omb Battlefield), and collect tax revenue (coins) from all players grinding in that zone.
2.  **Stock Market:** A fluctuating market for raw materials (Wood, Iron) where prices algorithmically adapt based on global player supply and demand.
