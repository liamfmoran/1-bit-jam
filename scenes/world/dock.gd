extends Node2D

@onready var panels: Node2D = $Panels
@onready var left_panel: ColorRect = $Panels/LeftPanel
@onready var right_panel: ColorRect = $Panels/RightPanel
@onready var top_panel: ColorRect = $Panels/TopPanel
@onready var detection_zone: Area2D = $DetectionZone

const ANIM_DURATION := 0.4
const APPROACH_DURATION := 1.0
const JOBS_MENU: PackedScene = preload("res://scenes/ui/jobs_menu.tscn")
const INVENTORY_MENU: PackedScene = preload("res://scenes/ui/inventory_menu.tscn")

var _panel_tween: Tween
var _docked_ship: RigidBody2D
var _jobs_instance: Control
var _inventory_instance: Control
var _station: StationData
var _camera: CameraManager


func setup(station: StationData) -> void:
	_station = station
	%StationLabel.text = "Station: " + station.display_name


func _ready() -> void:
	add_to_group("dock")
	detection_zone.body_entered.connect(_on_body_entered)
	detection_zone.body_exited.connect(_on_body_exited)
	left_panel.scale.x = 0.0
	right_panel.scale.x = 0.0
	top_panel.scale.x = 0.0


func _process(delta: float) -> void:
	if _docked_ship:
		panels.global_rotation = _docked_ship.global_rotation

func _on_body_entered(body: Node2D) -> void:
	if _docked_ship or not body.is_in_group("player"):
		return
	_docked_ship = body
	if not _camera:
		_camera = get_viewport().get_camera_2d() as CameraManager
	_camera.start_docking(APPROACH_DURATION, detection_zone)

	body.freeze = true
	var tween_pos : Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween_pos.tween_property(body, "global_position", detection_zone.global_position, APPROACH_DURATION)
	# var tween_rot : Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	# tween_rot.tween_property(body, "global_rotation", detection_zone.global_rotation,APPROACH_DURATION)
	tween_pos.finished.connect(func():
		body.freeze=false
		GameState.dock()
		body.linear_velocity = Vector2.ZERO
		body.angular_velocity = 0
	)
	if _station:
		GameState.complete_delivery(_station.id)
	_show_menus()
	_animate_panels(true)


	


func _on_body_exited(body: Node2D) -> void:
	if body != _docked_ship:
		return
	_docked_ship = null
	GameState.undock()
	_hide_menus()
	_animate_panels(false)


func _show_menus() -> void:
	_jobs_instance = JOBS_MENU.instantiate()
	_jobs_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	left_panel.add_child(_jobs_instance)
	if _station:
		_jobs_instance.set_jobs(_station.jobs)

	_inventory_instance = INVENTORY_MENU.instantiate()
	_inventory_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	right_panel.add_child(_inventory_instance)
	if _station:
		_inventory_instance.set_parts(_station.items_for_sale)


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
	_panel_tween.tween_property(top_panel, "scale:x", target_scale, ANIM_DURATION)
