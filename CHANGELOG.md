# Changelog

All notable changes to this project will be documented in this file.

## [v1.26] - Latest
### Added
- **Dynamic UI Inputs:** Added D-pad price adjustment to the Auction House and live player target selection to Mail Compose.
- **Visual Mechanics:** Weapons and Mounts now spawn actual models (swords, Yoshis) attached to the player instead of using invisible prototypes.

### Fixed
- Fixed a fatal Lua crash in `system_crafting` and `system_housing` caused by an incorrect inventory API call.
- Fixed `Mail.send` to actually transmit network packets rather than faking local delivery.

## [v1.25] - Previous
### Added
- **Mailbox UI:** Fully implemented the visual Compose mode, allowing players to attach inventory items to outgoing mail.

### Fixed
- Fixed documentation discrepancies in DASHBOARD.md.

## [v1.24] - Previous
### Added
- **Auction House UI:** Replaced the command-line interface with a full `UIToolkit` menu supporting "Browse" and "Sell" modes.

### Fixed
- Addressed missing visual representation for marketplace transactions.

## [v1.23] - Previous
### Added
- **Equipment Manager:** Added `system_equipment` to visually manage and unequip weapons and badges via the Main Menu.
- **Daily Quests:** Added repeatable procedural daily tasks to `system_quests`.

### Fixed
- Fixed Quest namespace reference bug in the Main Menu.

## [v1.22] - Previous
### Added
- **Global `UIToolkit` Overhaul:** All menus now support descriptive labels, text wrapping, and hover-tooltips.
- **In-Game Encyclopedia:** Added `system_help` providing an exhaustive manual directly inside the game.
- **Weapon System:** Implemented `mechanic_weapons` featuring equippable swords and hammers with durability, hitboxes, and inventory UI integration.
- **Documentation Suite:** Rebuilt `VISION.md`, `MEMORY.md`, `DEPLOY.md`, `ROADMAP_MMORPG.md`, `TODO.md`, `HANDOFF.md`, and `DASHBOARD.md`.
- **AI Agent Directives:** Created `AGENTS.md` and model-specific instruction files (`CLAUDE.md`, `GEMINI.md`, etc.).
- **Unified Versioning:** Created `VERSION.md` as the single source of truth, with a python script (`build_version.py`) to inject it into the C engine.

### Fixed
- Fixed fatal Lua load crash in `system_quests` caused by incorrect table initialization.
- Fixed critical integer underflow exploits in `system_auction_house` and `system_mail` commands that allowed infinite coin generation.

## [v1.21] - Previous
- Implemented `system_housing` (Instanced Player Houses & Guild Halls).
- Implemented `system_auction_house` (Global Asynchronous Marketplace).
- Implemented `system_mail` (Persistent Item Transfer).
- Removed the deprecated `bobcoin` submodule entirely.
