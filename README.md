# SM64 MMORPG Project - Game Manual & Encyclopedia

Welcome to the SM64 MMORPG Project! This is a massive, ongoing multiplayer modification of Super Mario 64 PC port (sm64coopdx) that transforms the classic platformer into a feature-rich, persistent, and highly interactive MMORPG experience.

## Getting Started

1. **Launch the Game:** Join a server or host your own. The game supports headless server mode via `--headless` for dedicated hosting.
2. **Main Menu:** Press `L-Trigger + START` (or the equivalent mapped buttons) to open the Main Menu. From here, you can access your Inventory, Quest Log, Classes, Guilds, Party, Stats, Achievements, Mailbox, and the in-game Help/Guide.
3. **Navigation:** Use the D-Pad to navigate through all menus and UI elements. Press `A` to interact/select and `B` to go back or close menus.

## Core Systems & Mechanics

### 1. Inventory & Items
*   **Universal Inventory:** Accessed via the Main Menu. All items, weapons, equipment, and crafting materials share a single, unified inventory. Items stack infinitely.
*   **Persistent Storage:** Your inventory is automatically saved and synchronized across sessions using the `mod_storage` backend.
*   **Tooltips & Descriptions:** In the Inventory UI, hover over any item to see detailed descriptions, stats, and tooltips regarding its use.

### 2. Combat & Classes
*   **Stats (STR/INT/AGI):** As you level up (max level 100), you gain points to distribute among Strength (melee damage/health), Intelligence (magic/mana), and Agility (speed/stealth).
*   **Classes:** Choose your path from the Classes menu:
    *   **Warrior:** Excels at close combat, utilizes heavy weapons.
    *   **Mage:** Masters of magic, utilizing powerful spells and staves.
    *   **Rogue:** Agility-based, focuses on stealth, quick strikes, and evasion.
*   **Mana System:** Special abilities and class skills consume Mana. Mana regenerates automatically over time.
*   **Weapons (WIP):** Weapons (swords, hammers) have durability and custom hitboxes. When durability reaches 0, the weapon breaks.

### 3. Economy, Shops & Trading
*   **Coins:** The primary currency. Collect coins in the world or earn them through quests and selling items.
*   **NPC Shops:** Toad NPCs act as shopkeepers. Interact with them to buy potions, materials, and equipment. Some items require specific Faction Reputation.
*   **Player Trading:** Engage in secure, direct peer-to-peer trading to exchange items and coins with other players.
*   **Auction House:** A global, asynchronous market. List items for sale or purchase goods from offline players. Items bought or unsold are delivered via the Mailbox.

### 4. Social Features
*   **Parties:** Form a party with friends. Party members share experience points (XP) and have friendly fire disabled. A custom Party HUD shows member health.
*   **Guilds:** Create or join a Guild. Guild members receive a custom overhead nametag, access to private chat (`/g message`), and entry to an instanced Guild Hall located in the Castle Courtyard.
*   **Mailbox:** Send and receive items and messages asynchronously to other players, even if they are offline.
*   **Achievements:** Track your milestones. Unlocking achievements rewards you with unique Titles displayed on your nametag.

### 5. Life Skills (Gathering & Crafting)
*   **Fishing:** Obtain a Fishing Rod and use the `/fish` command near water. Watch the bobber physics and reel it in for a chance at rare fish or junk.
*   **Mining:** Break ore nodes scattered throughout the world to gather Stone, Iron, and Gold.
*   **Crafting:** Interact with physical Crafting Tables in the world. Combine gathered materials (wood, stone, ores) to craft furniture, weapons, and consumables based on defined recipes.

### 6. Housing & World Exploration
*   **Player Housing:** Visit the housing district via the Castle Courtyard portal. Purchase an instanced home, craft or buy furniture, and decorate your space. Your house layout is persistent.
*   **Connected World:** The traditional level select screen is bypassed. Walk through coordinate-based portals to instantly warp between levels and zones.
*   **Mounts & Traversal:**
    *   Summon and ride mounts like Yoshis and Dorries for increased speed.
    *   Equip FLUDD nozzles (Hover, Rocket, Turbo) for aerial mobility.
    *   Use the Hookshot to grapple to distant surfaces.
    *   Utilize Galaxy-style Launch Stars for long-distance travel.
*   **Stealth & Swimming:** Crouching and crawling reduces enemy aggro radius. Swimming features an Oxygen meter and an underwater dash mechanic.

### 7. End-Game Content
*   **Quests:** Engage with NPCs to receive and complete quests for rewards and reputation.
*   **Tower of Trials:** A 10-floor procedural gauntlet reusing existing levels with scaling custom enemies.
*   **Dungeons:** Instanced cooperative challenges like the "Crypt of the Vanished", managed by a synchronized Dungeon Master.
*   **Raid Bosses:** Face epic, synchronized encounters like "King Whomp" featuring multiple phases and complex attack patterns.

## Technical Details (For Server Hosts & Modders)
*   **Architecture:** Built heavily on `gPlayerSyncTable` for cross-client state synchronization.
*   **Headless Mode:** The C engine supports `--headless` for dedicated server hosting without graphical overhead.
*   **Anti-Cheat:** Active server-side enforcement includes rubber-banding for speed hacks and automatic kicking for repeat offenders.
*   **UI Toolkit:** All menus use a centralized, standardized `UIToolkit` for consistent rendering, scrolling, tooltips, and input debouncing.

---
*Keep exploring, keep leveling, and enjoy the ever-expanding world of the SM64 MMORPG!*
