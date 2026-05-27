extends RefCounted

var location_container: Node2D

func _init(container: Node2D) -> void:
	location_container = container

func set_location(destination: GlobalScope.Location) -> void:
	var destination_definition := GlobalScope.get_location_definition(destination)
	empty_location_container()
	var new_location := destination_definition.scene.instantiate()
	location_container.add_child(new_location)

func empty_location_container() -> void:
	for child in location_container.get_children():
		location_container.remove_child(child)
		child.queue_free()
