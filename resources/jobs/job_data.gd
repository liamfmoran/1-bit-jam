class_name JobData
extends Resource

enum QuestType {
	FETCH,
	DELIVERY
}

@export var display_name: String
@export var description: String
@export var type: QuestType

@export var money_reward: int = 100
@export var faction_reward: int = 1

@export var origin: WorldData.Stations
@export var destination: WorldData.Stations
@export var fetch_coordinate_override: Vector2 = Vector2(0,0)

@export var cargo: Array[ItemData]
@export var conditions: Array
