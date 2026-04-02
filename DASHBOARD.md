# Project Dashboard & Directory Structure

## Version Information
**Current Build:** v1.22
**Last Updated:** [Current Session Date]

## Submodule Status
*Currently, there are no external git submodules active in this project.*
*(Note: The previous `bobcoin` submodule was completely scrubbed from the project to reduce bloat and security risks).*

## Directory Structure
The SM64 MMORPG project consists of a C-based engine and a massive Lua-based modding API.

```
/
├── baserom.us.z64           # Required asset ROM (User provided)
├── build/                   # Compilation artifacts
├── src/                     # C Engine Source Code
│   ├── pc/                  # PC Port specific code (Networking, GFX, Audio)
│   │   ├── lua/             # Lua C-Bindings
│   │   └── network/         # Network Synchronization Logic
│   ├── game/                # Original SM64 Game Logic
│   └── engine/              # Math and rendering engine
├── mods/                    # MMORPG Systems (Lua)
│   ├── system_ui/           # Core UIToolkit
│   ├── system_inventory/    # Universal Storage
│   ├── system_classes/      # RPG Classes & Magic
│   ├── system_combat/       # Health, Mana, Damage
│   ├── system_progression/  # XP, Levels, Stats
│   ├── system_economy/      # Shops, Auction House, Trading
│   ├── system_social/       # Guilds, Party, Mailbox
│   ├── system_housing/      # Instanced Player Housing
│   ├── mechanic_*/          # Core gameplay mechanics (Weapons, Mounts, Stealth, etc.)
│   └── content_*/           # Dungeons, Raid Bosses, Tower of Trials
├── AGENTS.md                # AI Agent Instructions
├── README.md                # Comprehensive Game Manual
├── VISION.md                # Project Goals
└── VERSION.md               # Single Source of Truth for Versioning
```
