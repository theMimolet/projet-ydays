extends Resource
class_name CombineRecipes

@export var recipes: Array[Resource] = []

func find_matching_recipe(selection_counts: Dictionary) -> Resource:
	for recipe: Resource in recipes:
		if recipe == null:
			continue
		if recipe.matches(selection_counts):
			return recipe
	return null
