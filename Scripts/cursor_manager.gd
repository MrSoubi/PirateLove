extends Node

const CURSOR = preload("res://Textures/Cursors/cursor.png")
const BULLE_CONVERSATION = preload("res://Textures/Cursors/Bulle_Conversation.png")
const LOUPE = preload("res://Textures/Cursors/Loupe.png")
const PORTE = preload("res://Textures/Cursors/Porte.png")

enum Type{
	CHARACTER,
	NONE,
	ITEM,
	DOOR
}

func _ready() -> void:
	set_cursor(Type.NONE)

func set_cursor(type : Type):
	match type:
		Type.NONE:
			Input.set_custom_mouse_cursor(CURSOR, 0)
		Type.CHARACTER:
			Input.set_custom_mouse_cursor(BULLE_CONVERSATION, 0)
		Type.ITEM:
			Input.set_custom_mouse_cursor(LOUPE, 0)
		Type.DOOR:
			Input.set_custom_mouse_cursor(PORTE, 0)
