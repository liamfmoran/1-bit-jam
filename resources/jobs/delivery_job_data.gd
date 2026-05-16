class_name DeliveryJobData
extends JobData

var destination: StationData

func get_target_label() -> String:
	return destination.display_name if destination else "?"
