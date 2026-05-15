extends Node2D

@onready var left_panel: ColorRect = $Panels/LeftPanel
@onready var right_panel: ColorRect = $Panels/RightPanel
@onready var detection_zone: Area2D = $DetectionZone

const ANIM_DURATION := 0.4

var _panel_tween: Tween
var _docking_menu: Control
var _docking_menu_layer: CanvasLayer
var _docked_ship: RigidBody2D

const DOCKING_MENU = preload("res://scenes/ui/docking_menu.tscn")


func _ready() -> void:
	detection_zone.body_entered.connect(_on_body_entered)
	detection_zone.body_exited.connect(_on_body_exited)
	left_panel.scale.x = 0.0
	right_panel.scale.x = 0.0


func _on_body_entered(body: Node2D) -> void:
	if _docked_ship or not body is RigidBody2D:
		return
	_docked_ship = body
	_animate_panels(true)
	await _panel_tween.finished
	_open_docking_menu()


func _on_body_exited(body: Node2D) -> void:
	if body != _docked_ship:
		return
	_docked_ship = null
	if _docking_menu:
		_close_docking_menu()
	_animate_panels(false)


func _open_docking_menu() -> void:
	if _docking_menu:
		return
	_docking_menu = DOCKING_MENU.instantiate()
	_docking_menu.closed.connect(_close_docking_menu)
	_docking_menu_layer = CanvasLayer.new()
	_docking_menu_layer.layer = 128
	_docking_menu_layer.add_child(_docking_menu)
	add_child(_docking_menu_layer)
	_docking_menu_layer.process_mode = PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true


func _close_docking_menu() -> void:
	if not _docking_menu:
		return
	get_tree().paused = false
	_docking_menu_layer.queue_free()
	_docking_menu = null
	_docking_menu_layer = null


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
