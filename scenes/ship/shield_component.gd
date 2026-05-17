class_name ShieldComponent
extends Node

var max_shield: float = 50.0
var shield: float = 0.0
var recharge_delay: float = 10.0
var recharge_time: float = 2.0

var _time_since_hit: float = INF


func configure_from_part(part: ShieldPartData) -> void:
	max_shield = part.max_shield
	recharge_delay = part.recharge_delay
	recharge_time = part.recharge_time
	shield = max_shield


func _process(delta: float) -> void:
	_time_since_hit += delta
	if _time_since_hit >= recharge_delay and shield < max_shield:
		shield = minf(max_shield, shield + max_shield / recharge_time * delta)


func absorb(amount: float) -> float:
	_time_since_hit = 0.0
	var absorbed := minf(shield, amount)
	shield -= absorbed
	return amount - absorbed
