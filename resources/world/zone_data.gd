class_name ZoneData
extends Resource

@export var id: String
@export var display_name: String
@export var position: Vector2
@export var radius: float
@export var falloff: float
@export var spawners: Array[SpawnerConfig]
# When non-zero, WorldStreamer uses perpendicular distance to this line instead of radial distance.
@export var line_direction: Vector2 = Vector2.ZERO
