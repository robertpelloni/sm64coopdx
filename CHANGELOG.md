# Changelog

## v1.17 (Current)
- **Server Spatial Interest Culling**: Integrated Euclidean distance filtering into `src/pc/network/packets/packet.c` for server-side `PACKET_PLAYER` rebroadcasts, eliminating redundant 30Hz movement transmissions to distant clients beyond active interest radius (15,000 units).
- **Mod Storage Disk I/O Optimization**: Streamlined `src/pc/mods/mod_storage.cpp` by removing extraneous duplicate file serialization (`file.write`) calls immediately preceding `file.generate`, cutting mod storage disk write overhead and I/O latency in half.
- **Network Performance**: Added adaptive packet compression to `src/pc/network/packets/packet.c`. Automatically selects `Z_BEST_SPEED` for high-frequency player movement packets (`PACKET_PLAYER`), significantly reducing CPU compression latency under concurrent multiplayer loads while retaining full decompression compatibility.
- **Consolidated Dashboard UI**: Completely redesigned `mods/system_menu/main.lua` into a high-value single-page MMO Dashboard. Grouped items cleanly into Character, Economy, Adventure, and System domains with rich tooltip descriptions and intuitive controls.
- **Server Tray & Supervisor**: Added `developer/server_tray.py` providing a desktop system tray icon (with Start/Stop/Restart/Quit actions) and an automated headless/CLI fallback for server process management and log monitoring.
- **Documentation & Governance**: Updated `DASHBOARD.md`, `DEPLOY.md`, `TODO.md`, `HANDOFF.md`, and version injection to `v1.17`.

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
