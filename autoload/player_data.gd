extends Node


var gold: int:
	set(value):
		gold = clamp(value,0,9999) #max gold is 9999 for now
		#put animations and sfx relate to gold here? 


var health:int = 100:
	set(value):
		health = clamp(value,0,100) #max health is %?
		#put animations related to health here


var inventory: Array[Node] = []

# Item reference is a node that we are matching on. If
# we want to do count of items of a specific type, 
# we can maybe store those
# locally on the node itself? OR each item is it's own
# node and we go from there.

func add_item_to_inventory(item_reference:Node):
	inventory.append(item_reference)

func remove_item_from_inventory(item_reference:Node):
	inventory.erase(item_reference)

func get_item_index(item_reference:Node):
	return inventory.find(item_reference) #-1 is false, else is the first?


# reputation per station unlocks new upgrades?
# var reputation = 0