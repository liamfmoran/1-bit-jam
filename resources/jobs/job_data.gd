class_name JobData
extends Resource

@export var display_name: String
@export var description: String

@export var money_reward: int = 100

var origin: StationData

@export var cargo: Array[ItemData]

func get_target_label() -> String:
	return ""
