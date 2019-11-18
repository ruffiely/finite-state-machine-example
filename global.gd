extends Node

enum ANIMATIONS {
	IDLE,
	MOVE,
	GATHER,
	STORE
}

class Inventory:
	signal inventory_changed
	
	const slots = 3
	
	var stash = []
	var removes = []
	
	func add(item):
		stash.append(item)
		emit_signal("inventory_changed")
	
	func is_full():
		return stash.size() >= slots
	
	func has_item(item):
		for stash_item in stash:
			if item.name == stash_item.name:
				return true
		return false
	
	func update():
		for remove_item in removes:
			remove(remove_item)
	
	func mark_remove(item):
		removes.append(item)
	
	func remove(item):
		var pos = stash.find(item)
		stash.remove(pos)
		emit_signal("inventory_changed")
	
	func get_stash():
		return stash

class Item:
	var ItemPortrait = preload("res://UI/ItemPortrait.tscn")
	
	var portrait
	var name setget set_name, get_name
	var quantity = 1 setget set_quantity, get_quantity
	
	func set_name(givenname):
		name = givenname
		_set_portrait()
	
	func get_name():
		return name
	
	func set_quantity(add):
		quantity = add
	
	func get_quantity():
		return quantity
	
	func _set_portrait():
		portrait = ItemPortrait.instance()
		portrait.texture = load("res://source_assets/UI/" + name + ".svg")
		portrait.hint_tooltip = name.capitalize()

class RepairItem extends Item:
	var needed_quantity setget set_needed_quantity , get_needed_quantity
	
	func get_needed_quantity():
		return needed_quantity
	
	func set_needed_quantity(needed):
		needed_quantity = needed

class SkillFactory:
	static func create(data):
		var skill = Skill.new()
		skill.set_name(data)
		
		return skill

class SkillTree:
	enum {
		CRAFTING,
		COOKING
	}
	
	var skill_data = {
		CRAFTING: "crafting",
		COOKING: "cooking"
	}
	
	var skills = {}
	
	func _init():
		skills[CRAFTING] = SkillFactory.create(skill_data[CRAFTING])
		skills[COOKING] = SkillFactory.create(skill_data[COOKING])

class Skill:
	var experience
	var name setget set_name, get_name
	
	func set_name(given_name):
		name = given_name
	
	func get_name():
		return name

class Recipe:
	var name setget set_name, get_name
	var materials setget set_materials, get_materials
	var required_experience setget set_required_experience, get_required_experience
	var type setget set_type, get_type
	var texture setget set_texture, get_texture
	
	func set_name(given_name):
		name = given_name
	
	func get_name():
		return name
	
	func set_materials(needed_materials):
		materials = needed_materials
	
	func get_materials():
		return materials
	
	func set_required_experience(required_exp):
		required_experience = required_exp
	
	func get_required_experience():
		return required_experience
	
	func set_type(given_type):
		type = given_type
	
	func get_type():
		return type
	
	func set_texture(given_tex):
		texture = load("res://source_assets/UI/" + given_tex + ".png")
	
	func get_texture():
		return texture

class RecipeFactory:
	static func create(name, materials, required_exp, texture_name):
		var recipe = Recipe.new()
		recipe.set_name(name)
		recipe.set_materials(materials)
		recipe.set_required_experience(required_exp)
		recipe.set_texture(texture_name)
		return recipe

class RecipeList:
	var recipes = {
		SkillTree.CRAFTING: [
			RecipeFactory.create("Knife", [], 0, "knife")
		]
	}

var DIContainer = {
	"RecipeList": RecipeList.new()
}