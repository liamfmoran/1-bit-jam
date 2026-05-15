extends Node2D

@onready var left_panel: ColorRect = $Panels/LeftPanel
@onready var right_panel: ColorRect = $Panels/RightPanel
@onready var detection_zone: Area2D = $DetectionZone

const ANIM_DURATION := 0.4

var _panel_tween: Tween


func _ready() -> void:
	detection_zone.body_entered.connect(_on_body_entered)
	detection_zone.body_exited.connect(_on_body_exited)
	left_panel.scale.x = 0.0
	right_panel.scale.x = 0.0


func _on_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		_animate_panels(true)


func _on_body_exited(body: Node2D) -> void:
	if body is RigidBody2D:
		_animate_panels(false)


func _animate_panels(opening: bool) -> void:
	if _panel_tween:
		_panel_tween.kill()

	_panel_tween = create_tween()
	_panel_tween.set_parallel(true)
	_panel_tween.set_ease(Tween.EASE_OUT if opening else Tween.EASE_IN)
	_panel_tween.set_trans(Tween.TRANS_CUBIC)

	var target_scale := 1.0 if opening else 0.0

	_panel_tween.tween_property(left_panel, "scale:x", target_scale, ANIM_DURATION)
	_panel_tween.tween_property(right_panel, "scale:x", target_scale, ANIM_DURATION)
