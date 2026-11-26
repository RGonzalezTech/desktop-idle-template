class_name ShopInventory
extends Resource

## Collection of shop entries.
## Provides filtered visibility and purchase delegation.

@export var entries: Array[ShopEntry] = []


func get_visible_entries(state: GameState) -> Array[ShopEntry]:
	var visible: Array[ShopEntry] = []
	for entry in entries:
		if entry.is_visible(state):
			visible.append(entry)
	return visible


func purchase(entry_id: StringName, state: GameState) -> bool:
	for entry in entries:
		if entry.entry_id == entry_id:
			return entry.purchase(state)
	return false
