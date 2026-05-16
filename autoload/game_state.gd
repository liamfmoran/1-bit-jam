extends Node

signal money_changed(new_amount: int)
signal cargo_changed()
signal jobs_changed()
signal inventory_changed()
signal docked()
signal undocked()
signal hp_changed()

var _is_ship_docked = false
var money: int = 9999
var hp: int = 100
var active_jobs: Array[JobData] = []
var inventory: Array[ItemData] = []

func accept_job(job: JobData) -> void:
	active_jobs.append(job)
	jobs_changed.emit()


func complete_job(job: JobData) -> void:
	active_jobs.erase(job)
	money += job.money_reward
	money_changed.emit(money)
	jobs_changed.emit()


func dock() -> void:
	_is_ship_docked = true
	docked.emit()


func undock() -> void:
	_is_ship_docked = false
	undocked.emit()

func update_hp(val:int) -> void:
	hp = clamp(hp + val,0,100)
	hp_changed.emit()

func buy_part(part: ItemData) -> void:
	if money >= part.cost:
		money -= part.cost
		inventory.append(part)
		money_changed.emit(money)
		inventory_changed.emit()


func sell_part(part: ItemData) -> void:
	if part not in inventory:
		return
	inventory.erase(part)
	money += part.cost
	money_changed.emit(money)
	inventory_changed.emit()


func complete_delivery(dock_name: WorldData.Stations) -> void:
	var completed := []
	for job in active_jobs:
		if job.destination == dock_name:
			completed.append(job)
	for job in completed:
		complete_job(job)
