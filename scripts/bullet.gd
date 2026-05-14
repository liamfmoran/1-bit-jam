extends Area2D

var velocity: Vector2


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += velocity * delta

	var cam := get_viewport().get_camera_2d()
	if cam and global_position.distance_squared_to(cam.global_position) > 2000 * 2000:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method(&"hit"):
		body.hit(global_position)
	queue_free()
