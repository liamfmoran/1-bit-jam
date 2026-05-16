class_name WeaponComponent
extends Node2D

@export var fire_rate: float = 1.5
@export var damage: float = 15.0
@export var bullet_speed: float = 600.0
@export var weapon_range: float = 320.0

var team: StringName = &"enemy"

const BULLET_SCENE := preload("res://scenes/world/bullet.tscn")

var _cooldown: float = 0.0


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)


func configure_from_part(part: WeaponPartData) -> void:
	fire_rate    = part.fire_rate
	damage       = part.damage
	bullet_speed = part.bullet_speed
	weapon_range = part.weapon_range


func can_fire() -> bool:
	return _cooldown <= 0.0


func fire(direction: Vector2) -> void:
	if not can_fire():
		return
	_cooldown = 1.0 / fire_rate
	var bullet := BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.launch(direction, bullet_speed, damage, team)
