extends Node

const CURSOR = preload("res://Textures/Cursors/cursor.png")
const LONGUE_VUE = preload("res://Textures/Cursors/longue_vue.png")

enum Type{
	CHARACTER,
	NONE,
	ITEM,
	DOOR
}

func _ready() -> void:
	pass
	#Input.set_custom_mouse_cursor(CURSOR, 0)

func set_cursor(type : Type):
	match type:
		Type.NONE:
			Input.set_custom_mouse_cursor(CURSOR, 0)
		Type.CHARACTER:
			Input.set_custom_mouse_cursor(LONGUE_VUE, 0)
		Type.ITEM:
			Input.set_custom_mouse_cursor(CURSOR, 0)
		Type.DOOR:
			Input.set_custom_mouse_cursor(CURSOR, 0)
