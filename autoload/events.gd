extends Node
## Global signal bus. Systems emit here so UI, audio and progression stay decoupled.

@warning_ignore_start("unused_signal")

## A puzzle step inside the current level was solved (step_id from the level data).
signal step_solved(step_id: String, solved_count: int, total_steps: int)
## An item was added to the inventory.
signal item_added(item_id: String)
## An item left the inventory (used up or combined).
signal item_removed(item_id: String)
## A clue became known (its carrier is visible or in the inventory).
signal clue_found(clue_id: String)
## The balcony door opened: the level is complete.
signal level_completed(result: Dictionary)
## A hidden postcard was picked up.
signal postcard_found(postcard_id: String)
## Seashell balance changed.
signal seashells_changed(total: int)
## Decor was bought, placed, moved or stored.
signal decor_changed()
## Settings were changed (volumes, text size, reduce motion...).
signal settings_changed()
## The sunrise progress of the current room changed (0..1).
signal sunrise_changed(sunrise_t: float)

@warning_ignore_restore("unused_signal")
