extends Node2D

@export var dock_name: StringName = &"Dock"
@export var destination_dock_name: StringName = &"Dock"
@export var jobs: Array[JobData] = []
@export var parts_for_sale: Array[ShipPartData] = []

@onready var left_panel: ColorRect = $Panels/LeftPanel
@onready var right_panel: ColorRect = $Panels/RightPanel
@onready var detection_zone: Area2D = $DetectionZone

const ANIM_DURATION := 0.4
const JOBS_MENU = preload("res://scenes/ui/jobs_menu.tscn")
const INVENTORY_MENU = preload("res://scenes/ui/inventory_menu.tscn")

var _panel_tween: Tween
var _docked_ship: RigidBody2D
var _jobs_instance: Control
var _inventory_instance: Control


func _ready() -> void:
	add_to_group("dock")
	detection_zone.body_entered.connect(_on_body_entered)
	detection_zone.body_exited.connect(_on_body_exited)
	left_panel.scale.x = 0.0
	right_panel.scale.x = 0.0


func _on_body_entered(body: Node2D) -> void:
	if _docked_ship or not body is RigidBody2D:
		return
	_docked_ship = body
	GameState.complete_delivery(dock_name)
	GameState.docked.emit()
	_show_menus()
	_animate_panels(true)


func _on_body_exited(body: Node2D) -> void:
	if body != _docked_ship:
		return
	_docked_ship = null
	GameState.undocked.emit()
	_hide_menus()
	_animate_panels(false)


func _show_menus() -> void:
	_jobs_instance = JOBS_MENU.instantiate()
	_jobs_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	left_panel.add_child(_jobs_instance)
	_jobs_instance.set_jobs(jobs)

	_inventory_instance = INVENTORY_MENU.instantiate()
	_inventory_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	right_panel.add_child(_inventory_instance)
	_inventory_instance.set_parts(parts_for_sale)


func _hide_menus() -> void:
	if _jobs_instance:
		_jobs_instance.queue_free()
		_jobs_instance = null
	if _inventory_instance:
		_inventory_instance.queue_free()
		_inventory_instance = null


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
