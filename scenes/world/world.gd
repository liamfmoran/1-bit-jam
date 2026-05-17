extends Node2D

const FETCH_MARKER = preload("res://scenes/world/fetch_marker.tscn")

@export var sun_direction: Vector3 = Vector3(0.0, -1.0, 0.4)

static var _param_added := false

var _fetch_markers: Dictionary = {}  # FetchJobData -> FetchMarker


func _ready() -> void:
	if not _param_added:
		RenderingServer.global_shader_parameter_add("sun_direction", RenderingServer.GLOBAL_VAR_TYPE_VEC3, sun_direction)
		_param_added = true
	RenderingServer.global_shader_parameter_set("sun_direction", sun_direction)
	GameState.jobs_changed.connect(_sync_fetch_markers)


func _exit_tree() -> void:
	_param_added = false


func _sync_fetch_markers() -> void:
	for job: JobData in GameState.active_jobs:
		if not (job is FetchJobData):
			continue
		var fetch := job as FetchJobData
		if not fetch.is_fetched and not _fetch_markers.has(fetch):
			var marker := FETCH_MARKER.instantiate()
			marker.job = fetch
			marker.global_position = fetch.fetch_coordinate
			add_child(marker)
			_fetch_markers[fetch] = marker

	for job: Variant in _fetch_markers.keys():
		if job not in GameState.active_jobs:
			var marker: Variant = _fetch_markers[job]
			if is_instance_valid(marker):
				marker.queue_free()
			_fetch_markers.erase(job)
