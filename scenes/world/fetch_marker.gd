extends Area2D

var job: FetchJobData


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	job.is_fetched = true
	if job.fetch_item:
		GameState.pickup_item(job.fetch_item)
	queue_free()


func _draw() -> void:
	draw_arc(Vector2.ZERO, 60.0, 0.0, TAU, 48, Color.WHITE, 2.0)
	draw_circle(Vector2.ZERO, 6.0, Color.WHITE)
