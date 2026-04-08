extends Resource
class_name CombineRecipe

const ITEM: Resource = preload("res://Scripts/Items/Item.gd")

@export var ingredients: Dictionary = {}
@export var result_item: Item
@export var result_quantity: int = 1

func matches(selection_counts: Dictionary) -> bool:
	if ingredients.size() != selection_counts.size():
		return false
	
	for item_name: Variant in ingredients.keys():
		if not selection_counts.has(item_name):
			return false
		if int(selection_counts[item_name]) != int(ingredients[item_name]):
			return false
	
	return true
