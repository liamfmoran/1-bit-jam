extends Area2D

var _velocity: Vector2
var _damage: float
var _lifetime: float = 3.0
var _team: StringName = &"enemy"


func launch(direction: Vector2, speed: float, dmg: float, shooter_team: StringName = &"enemy", inherited_velocity: Vector2 = Vector2.ZERO) -> void:
	_velocity = direction * speed + inherited_velocity
	_damage = dmg
	_team = shooter_team
	rotation = direction.angle() + PI / 2.0


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(_team):
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage)
	queue_free()
