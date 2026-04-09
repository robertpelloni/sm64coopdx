# Short-Term Feature & Bug Fix Tracker

## High Priority
*   [x] **Equipment UI Manager:** The `mechanic_weapons` and `system_perks` systems allow equipping items, but there is no dedicated "Character Sheet" UI to visually see what is currently equipped, unequip items, or view total stat bonuses from gear.
*   [x] **Daily Quests:** Implement repeatable, randomly generated daily tasks (e.g., "Kill 10 Goombas", "Fish 5 Bass") in `system_quests` to provide ongoing end-game engagement.
*   [x] **Weapon Visuals:** `mechanic_weapons` currently calculates hitboxes but lacks the visual rendering of the weapon model attached to Mario's hand (using `smlua_model_util_get_id`).

## Medium Priority
*   [ ] **Guild Bank / Storage:** Extend the Guild system to allow shared item storage within the Guild Hall. Requires careful transaction locking to prevent duping.
*   [x] **Auction House UI:** The Auction House currently relies on chat commands (`/ah sell`, `/ah buy`). It needs to be fully integrated into `UIToolkit`.
*   [x] **Mail Attachment UI:** Sending items via mail is command-only. Need a UI menu to select inventory items as attachments.
*   [ ] **Refactor Save System:** Consider batching `mod_storage_save` calls across different systems (Inventory, Mail, AH, Housing) into a single unified periodic save manager to reduce disk I/O.

## Low Priority / Polish
*   [ ] **Tooltip Formatting:** Add rich text color codes to the `UIToolkit` hover-tooltips (e.g., making the word "Rare" actually render in blue text).
*   [ ] **Sound Pass:** Ensure every UI interaction (buy, sell, equip, error) has a consistent and satisfying audio cue.
