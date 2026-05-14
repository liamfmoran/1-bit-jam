extends Node2D

@export var boundary_thickness: float = 20.0
@export var asteroid_spawn_interval: float = 1.5
@export var asteroid_speed_min: float = 40.0
@export var asteroid_speed_max: float = 120.0
@export var asteroid_fast_chance: float = 0.15
@export var asteroid_fast_multiplier: float = 4.0
@export var asteroid_size_min: float = 20.0
@export var asteroid_size_max: float = 60.0
@export var asteroid_mass: float = 8.0

const ASTEROID_SCENE := preload("res://scenes/asteroid.tscn")

var _viewport_size: Vector2


func _ready() -> void:
	_viewport_size = get_viewport_rect().size
	_setup_boundaries()
	_setup_asteroid_timer()


func _setup_boundaries() -> void:
	var w := _viewport_size.x
	var h := _viewport_size.y

	_position_wall($Boundaries/TopWall,
		Vector2(w / 2.0, -boundary_thickness / 2.0),
		Vector2(w + boundary_thickness * 2, boundary_thickness))

	_position_wall($Boundaries/BottomWall,
		Vector2(w / 2.0, h + boundary_thickness / 2.0),
		Vector2(w + boundary_thickness * 2, boundary_thickness))

	_position_wall($Boundaries/LeftWall,
		Vector2(-boundary_thickness / 2.0, h / 2.0),
		Vector2(boundary_thickness, h + boundary_thickness * 2))

	_position_wall($Boundaries/RightWall,
		Vector2(w + boundary_thickness / 2.0, h / 2.0),
		Vector2(boundary_thickness, h + boundary_thickness * 2))


func _position_wall(wall: StaticBody2D, pos: Vector2, wall_size: Vector2) -> void:
	wall.position = pos
	wall.collision_layer = 2
	wall.collision_mask = 1
	var shape := wall.get_node("CollisionShape2D")
	var rect := RectangleShape2D.new()
	rect.size = wall_size
	shape.shape = rect


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

	var edge := randi() % 4
	var spawn_pos: Vector2
	var target: Vector2
	var margin := 80.0

	match edge:
		0: # top
			spawn_pos = Vector2(randf_range(0, _viewport_size.x), -margin)
			target = Vector2(randf_range(0, _viewport_size.x), _viewport_size.y + margin)
		1: # bottom
			spawn_pos = Vector2(randf_range(0, _viewport_size.x), _viewport_size.y + margin)
			target = Vector2(randf_range(0, _viewport_size.x), -margin)
		2: # left
			spawn_pos = Vector2(-margin, randf_range(0, _viewport_size.y))
			target = Vector2(_viewport_size.x + margin, randf_range(0, _viewport_size.y))
		3: # right
			spawn_pos = Vector2(_viewport_size.x + margin, randf_range(0, _viewport_size.y))
			target = Vector2(-margin, randf_range(0, _viewport_size.y))

	asteroid.global_position = spawn_pos
	asteroid.rotation = randf_range(0, TAU)

	var direction := (target - spawn_pos).normalized()
	var speed := randf_range(asteroid_speed_min, asteroid_speed_max)
	if randf() < asteroid_fast_chance:
		speed *= randf_range(2.0, asteroid_fast_multiplier)
	asteroid.linear_velocity = direction * speed
	asteroid.angular_velocity = randf_range(-1.5, 1.5)

	add_child(asteroid)
