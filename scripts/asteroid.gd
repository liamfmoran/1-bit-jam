extends RigidBody2D

var asteroid_size: float = 40.0
var break_impulse_threshold: float = 400.0
var min_break_size: float = 15.0

var _viewport_size: Vector2
var _margin: float = 600.0
var _broken := false

const ASTEROID_SCENE := preload("res://scenes/asteroid.tscn")


func hit(_at_position: Vector2) -> void:
	if _broken:
		return
	_broken = true
	_break_apart.call_deferred()


func _ready() -> void:
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.0
	collision_layer = 4
	collision_mask = 5
	contact_monitor = true
	max_contacts_reported = 4
	_viewport_size = get_viewport_rect().size


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _broken:
		return
	for i in state.get_contact_count():
		var impulse := state.get_contact_impulse(i)
		if impulse.length() > break_impulse_threshold:
			_broken = true
			_break_apart.call_deferred()
			return


func _physics_process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return
	var cam_pos := camera.global_position
	var dist := global_position.distance_to(cam_pos)
	if dist > _margin + _viewport_size.x:
		queue_free()


func _break_apart() -> void:
	if asteroid_size < min_break_size:
		queue_free()
		return

	var fragment_size := asteroid_size / 2.0
	var fragment_mass := mass / 4.0
	var half := fragment_size / 2.0
	var spread := asteroid_size / 3.0

	var offsets := [
		Vector2(-spread, -spread),
		Vector2(spread, -spread),
		Vector2(-spread, spread),
		Vector2(spread, spread),
	]

	for offset in offsets:
		var fragment: RigidBody2D = ASTEROID_SCENE.instantiate()
		fragment.asteroid_size = fragment_size
		fragment.mass = fragment_mass

		var body: ColorRect = fragment.get_node("AsteroidBody")
		body.size = Vector2(fragment_size, fragment_size)
		body.position = Vector2(-half, -half)

		var col: CollisionShape2D = fragment.get_node("CollisionShape2D")
		var rect := RectangleShape2D.new()
		rect.size = Vector2(fragment_size, fragment_size)
		col.shape = rect

		fragment.global_position = global_position + offset
		fragment.rotation = randf_range(0, TAU)
		fragment.linear_velocity = linear_velocity + offset.normalized() * randf_range(30.0, 80.0)
		fragment.angular_velocity = randf_range(-3.0, 3.0)

		get_parent().add_child(fragment)

	queue_free()
