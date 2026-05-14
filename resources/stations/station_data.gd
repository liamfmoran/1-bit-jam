class_name StationData
extends Resource

@export var station_name: StringName
@export var buy_items: Array[PackageData] = []
@export var sell_price_modifier: float = 1.0
@export var buy_price_modifier: float = 1.0
@export var parts_for_sale: Array[ShipPartData] = []
