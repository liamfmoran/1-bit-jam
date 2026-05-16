extends Node2D

@export var ship: Node2D
@export var hazard_manager: Node
@export var spawn_interval: float = 1.5
@export var min_spawn_dist: float = 400.0
@export var max_spawn_dist: float = 700.0
@export var max_asteroids: int = 30

const ASTEROID_SCENE := preload("res://scenes/world/asteroid.tscn")
const SIZES: Array[float] = [8.0, 16.0, 28.0]
const MIN_SPEED: float = 80.0
const MAX_SPEED: float = 220.0
const MAX_ANGULAR_VEL: float = 2.0

func _ready() -> void:
	if not ship:
		ship = get_tree().get_first_node_in_group("player") as Node2D
	if not hazard_manager:
		hazard_manager = get_node_or_null("../HazardManager")
	var timer := Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

func _on_timer_timeout() -> void:
	if not ship or not hazard_manager:
		return
	if not hazard_manager.has_event(&"asteroids"):
		return
	if get_tree().get_nodes_in_group("asteroids").size() >= max_asteroids:
		return
	_spawn_asteroid()
	_spawn_asteroid()

func _spawn_asteroid() -> void:
	var angle := randf() * TAU
	var dist := randf_range(min_spawn_dist, max_spawn_dist)
	var spawn_pos := ship.global_position + Vector2(cos(angle), sin(angle)) * dist

	var asteroid: RigidBody2D = ASTEROID_SCENE.instantiate()
	asteroid.add_to_group("asteroids")
	get_parent().add_child(asteroid)
	asteroid.global_position = spawn_pos

	var r: float = SIZES[randi() % SIZES.size()]
	asteroid.setup(r, ship)

	var vel_angle := randf() * TAU
	var speed := randf_range(MIN_SPEED, MAX_SPEED)
	asteroid.linear_velocity = Vector2(cos(vel_angle), sin(vel_angle)) * speed
	asteroid.angular_velocity = randf_range(-MAX_ANGULAR_VEL, MAX_ANGULAR_VEL)
