@tool
extends EditorPlugin


func _enable_plugin() -> void:
	pass

func _disable_plugin() -> void:
	pass

func _enter_tree() -> void:
	add_custom_type("MainAppLayer", "Control", preload("main_app_layer.gd"), preload("img/img_Icon_MainAppLayer_32x32px.png"))
func _exit_tree() -> void:
	remove_custom_type("MainAppLayer")
