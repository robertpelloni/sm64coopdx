# Changelog

## v1.19 (Current)
- **Mechanics**: Implemented a "Mid-Air Double Jump" ability tracked via `gPlayerSyncTable` (flattened keys). Added a corresponding training quest in `system_quests`.
- **Dungeons**: Fully implemented the `Crypt of the Vanished` instanced procedural dungeon UI. Added a centralized UI selection menu for Normal, Heroic, and Mythic difficulty scaling, accessible directly from the Main Menu.

## v1.18
- **Class System**: Fully implemented class stat blocks (Warrior, Mage, Rogue), dynamic top-left HUD updates, and initial class loadouts (weapons/potions) strictly protected from farming via a granted flag. Added `/class` role chat command for direct selection.
- **Quest System Integration**: Quests now natively support `classReq` attributes, preventing players from accepting quests outside their chosen discipline.
- **Movement Abilities**: Formalized custom platformer actions in the UI and documentation.

## v1.17
- **Abilities Framework**: Integrated scalable Double Jump, Ground Pound Jump, Dive Slide momentum capping, and Enhanced Long Jump.
- **Bug Fixes**: Cleared up formatting string regex issues in UI Tooltips and replaced outdated weapon placeholders with actual engine-supported meshes.

## v1.16
- **Party UI**: Added a comprehensive visual menu for managing parties (create, join, invite, leave) directly tied into `UIToolkit`.

## v1.15
- **Sound Pass**: Audited UI sounds and replaced all hallucinated or jarring audio cues with consistent native menu clicking sounds.

## v1.14
- **Visuals**: Updated weapon placeholders to use better thematic models (shells for blades, bobombs for blunts) while awaiting full custom 3D model support.

## v1.13
- **UI Tooltips**: Added automatic inline color coding for Item Rarity keywords (Common, Rare, Epic, Legendary).

## v1.12
- **UI Enhancements**: Added an on-screen D-Pad alphabetical spinner allowing custom text input for systems without a native keyboard. Mail now supports dynamic target inputs via D-pad, and Auction House supports fast price scrolling.

## v1.11
- **Save System Refactor**: Integrated remaining gameplay systems (Guild Bank, Achievements, Config, Quests) into the unified SaveManager to reduce disk I/O stutter.

## v1.10
- **New Feature: Guild Bank**: Shared storage for guild members via `/bank`.

## v1.9
- **New Feature: Party System**: Group up with `/party`. Includes Party Chat (`/p`), HUD Health Bars, and Friendly Fire protection.
- **New Feature: Admin System**: Host-only tools for Kicking, Banning, and Teleporting players via command (`/admin`) or UI.
- **Main Menu**: Added Party and Admin options.
- **Documentation**: Updated Manual with Party and Admin details.

## v1.8
- **UI Overhaul**: Converted Inventory, Quest, and Shop UIs to fully interactive menus.
- **New Systems**: Added Config and Help systems.
- **Documentation**: Comprehensive Game Manual in README.md.
- **Cleanup**: Removed bobcoin submodule.

## v1.7
- **Feature Parity Complete**: Implemented FLUDD, Gravity, and final mechanics.
