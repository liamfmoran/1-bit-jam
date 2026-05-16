extends Node2D

@onready var _area: Area2D = $GravityArea

var pull_strength: float = 800.0

func setup(strength: float) -> void:
	pull_strength = strength

func _physics_process(_delta: float) -> void:
	for body: Variant in _area.get_overlapping_bodies():
		var rb := body as RigidBody2D
		if not rb:
			continue
		var dir := (global_position - rb.global_position).normalized()
		var dist := maxf(global_position.distance_to(rb.global_position), 1.0)
		var force := pull_strength * rb.mass / (dist * 0.01 + 1.0)
		rb.apply_central_force(dir * force)
