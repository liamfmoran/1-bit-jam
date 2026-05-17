extends Node

signal money_changed(new_amount: int)
signal cargo_changed()
signal jobs_changed()
signal inventory_changed()
signal equipped_parts_changed()
signal docked()
signal undocked()
signal hp_changed()

var _is_ship_docked = false
var money: int = 9999
var hp: int = 100
var active_jobs: Array[JobData] = []
var inventory: Array[ItemData] = []
var part_inventory: Array[ShipPartData] = []
var equipped_parts: Dictionary = {}  # StringName slot_id -> ShipPartData


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


func buy_ship_part(part: ShipPartData) -> void:
	if money < part.cost:
		return
	money -= part.cost
	part_inventory.append(part)
	money_changed.emit(money)
	equip_part(slot_id_for(part), part)


func equip_part(slot_id: StringName, part: ShipPartData) -> void:
	equipped_parts[slot_id] = part
	equipped_parts_changed.emit()
	inventory_changed.emit()


func unequip_part(slot_id: StringName) -> void:
	equipped_parts.erase(slot_id)
	equipped_parts_changed.emit()
	inventory_changed.emit()


func is_part_equipped(part: ShipPartData) -> bool:
	return part in equipped_parts.values()


static func slot_id_for(part: ShipPartData) -> StringName:
	if part is WeaponPartData: return &"weapon"
	if part is EnginePartData: return &"engine"
	if part is ShieldPartData: return &"shield"
	if part is HullPartData:   return &"hull"
	return &""


func complete_delivery(dock_name: String) -> void:
	var completed := []
	for job in active_jobs:
		var delivery := job as DeliveryJobData
		if delivery and delivery.destination != null and delivery.destination.id == dock_name:
			completed.append(job)
	for job in completed:
		complete_job(job)
