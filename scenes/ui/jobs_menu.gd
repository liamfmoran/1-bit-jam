extends Control

const JOB_ITEM_SCENE = preload("res://scenes/ui/job_item.tscn")

@onready var job_list: VBoxContainer = $VBoxContainer/ScrollContainer/JobList
@onready var accept_button: Button = $VBoxContainer/AcceptButton
@onready var carrying_list: VBoxContainer = $VBoxContainer/CarryingScroll/CarryingList

var _job_group: ButtonGroup
var _selected_item: Button
var _available_jobs: Array = []


func _ready() -> void:
	_job_group = ButtonGroup.new()
	accept_button.pressed.connect(_on_accept_pressed)
	accept_button.disabled = true
	GameState.jobs_changed.connect(_refresh_carrying)


func set_jobs(jobs: Array) -> void:
	_available_jobs = jobs
	_populate_list()
	_refresh_carrying()


func _populate_list() -> void:
	for child in job_list.get_children():
		child.queue_free()

	_selected_item = null
	accept_button.disabled = true

	for job in _available_jobs:
		var item := JOB_ITEM_SCENE.instantiate()
		item.text = "%s → %s ($%d)" % [job.job_name, job.destination_dock_name, job.value]
		item.job_data = job
		item.button_group = _job_group
		item.toggled.connect(_on_job_toggled.bind(item))
		job_list.add_child(item)


func _on_job_toggled(toggled_on: bool, item: Button) -> void:
	if toggled_on:
		_selected_item = item
		accept_button.disabled = false
	else:
		_selected_item = null
		accept_button.disabled = true


func _on_accept_pressed() -> void:
	if not _selected_item:
		return
	var job = _selected_item.job_data
	_available_jobs.erase(job)
	GameState.accept_job(job)
	_populate_list()


func _refresh_carrying() -> void:
	for child in carrying_list.get_children():
		child.queue_free()

	for job in GameState.active_jobs:
		var label := Label.new()
		label.text = "%s → %s" % [job.job_name, job.destination_dock_name]
		label.add_theme_color_override("font_color", Color.BLACK)
		carrying_list.add_child(label)
