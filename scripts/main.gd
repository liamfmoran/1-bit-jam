extends Node2D

@export var asteroid_spawn_interval: float = 0.7
@export var asteroid_speed_min: float = 40.0
@export var asteroid_speed_max: float = 120.0
@export var asteroid_fast_chance: float = 0.15
@export var asteroid_fast_multiplier: float = 4.0
@export var asteroid_size_min: float = 20.0
@export var asteroid_size_max: float = 60.0
@export var asteroid_mass: float = 8.0

const ASTEROID_SCENE := preload("res://scenes/asteroid.tscn")

var _viewport_size: Vector2
@onready var _truck: Node2D = $Truck


func _ready() -> void:
	_viewport_size = get_viewport_rect().size
	_setup_asteroid_timer()


func _setup_asteroid_timer() -> void:
	var timer := Timer.new()
	timer.wait_time = asteroid_spawn_interval
	timer.autostart = true
	timer.timeout.connect(_spawn_asteroid)
	add_child(timer)


func _spawn_asteroid() -> void:
	var asteroid: RigidBody2D = ASTEROID_SCENE.instantiate()

	var size := randf_range(asteroid_size_min, asteroid_size_max)
	var half := size / 2.0

	var body: ColorRect = asteroid.get_node("AsteroidBody")
	body.size = Vector2(size, size)
	body.position = Vector2(-half, -half)

	var col: CollisionShape2D = asteroid.get_node("CollisionShape2D")
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size, size)
	col.shape = rect

	asteroid.mass = asteroid_mass * (size / asteroid_size_max)
	asteroid.asteroid_size = size

	# Spawn in a wide ring around the player, well beyond visible area
	var center := _truck.global_position
	var spawn_radius := 1400.0
	var angle := randf_range(0, TAU)
	var spawn_pos := center + Vector2(cos(angle), sin(angle)) * spawn_radius

	# Aim generally toward the player with some randomness
	var aim_offset := Vector2(randf_range(-400, 400), randf_range(-400, 400))
	var target := center + aim_offset

	asteroid.global_position = spawn_pos
	asteroid.rotation = randf_range(0, TAU)

	var direction := (target - spawn_pos).normalized()
	var speed := randf_range(asteroid_speed_min, asteroid_speed_max)
	if randf() < asteroid_fast_chance:
		speed *= randf_range(2.0, asteroid_fast_multiplier)
	asteroid.linear_velocity = direction * speed
	asteroid.angular_velocity = randf_range(-1.5, 1.5)

	add_child(asteroid)
