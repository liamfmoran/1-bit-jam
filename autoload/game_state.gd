extends Node

signal money_changed(new_amount: int)
signal cargo_changed()
signal jobs_changed()
signal inventory_changed()
signal docked()
signal undocked()

var money: int = 10000
var placed_items: Array[Dictionary] = []
var equipped_parts: Dictionary = {}
var cab_grid_size: Vector2i = Vector2i(6, 10)
var trailer_grid_sizes: Array[Vector2i] = []
var total_cargo_mass: float = 0.0
var active_jobs: Array[JobData] = []
var owned_parts: Array[ShipPartData] = []

func accept_job(job: Resource) -> void:
	active_jobs.append(job)
	jobs_changed.emit()


func complete_job(job: Resource) -> void:
	active_jobs.erase(job)
	money += job.value
	money_changed.emit(money)
	jobs_changed.emit()


func buy_part(part: Resource) -> void:
	if money >= part.cost:
		money -= part.cost
		owned_parts.append(part)
		money_changed.emit(money)
		inventory_changed.emit()


func sell_part(part: Resource) -> void:
	if part not in owned_parts:
		return
	owned_parts.erase(part)
	money += part.cost
	money_changed.emit(money)
	inventory_changed.emit()


func complete_delivery(dock_name: StringName) -> void:
	var completed := []
	for job in active_jobs:
		if job.destination_dock_name == dock_name:
			completed.append(job)
	for job in completed:
		complete_job(job)
