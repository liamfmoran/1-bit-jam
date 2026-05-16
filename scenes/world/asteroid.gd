extends RigidBody2D

const MAX_DIST: float = 4500.0

var radius: float = 16.0
var _ship: Node2D
var _mat: ShaderMaterial

const DENSITY: float = 0.05
const SPIN_RESPONSE: float = 0.3
const ASTEROID_SHADER := preload("res://shaders/asteroid.gdshader")

static var _shared_tex: ImageTexture

func setup(r: float, ship: Node2D) -> void:
	radius = r
	_ship = ship

	var shape := CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape
	mass = PI * radius * radius * DENSITY

	if not _shared_tex:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_shared_tex = ImageTexture.create_from_image(img)
	var tex := _shared_tex

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(radius * 2.0, radius * 2.0)

	var mat := ShaderMaterial.new()
	mat.shader = ASTEROID_SHADER
	mat.set_shader_parameter("spin_offset", randf() * TAU)
	sprite.material = mat
	_mat = mat
	add_child(sprite)

	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body is Node2D:
		return
	var body2d := body as Node2D
	var other_vel := (body2d as RigidBody2D).linear_velocity if body2d is RigidBody2D else Vector2.ZERO
	var to_body := (body2d.global_position - global_position).normalized()
	var rel_vel: Vector2 = other_vel - linear_velocity
	apply_torque_impulse(to_body.cross(rel_vel) * SPIN_RESPONSE)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_ship):
		return
	if global_position.distance_to(_ship.global_position) > MAX_DIST:
		queue_free()
	_mat.set_shader_parameter("asteroid_rotation", rotation)
