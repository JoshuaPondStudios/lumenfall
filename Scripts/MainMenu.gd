extends Control

@onready var start_button = $CanvasLayer/Start
@onready var exit_button = $CanvasLayer/Exit

func _ready():
	# Erst Verbindungen trennen (wenn sie schon bestehen), dann sauber verbinden
	if start_button.is_connected("pressed", Callable(self, "_on_start_pressed")):
		start_button.pressed.disconnect(_on_start_pressed)
	if exit_button.is_connected("pressed", Callable(self, "_on_exit_pressed")):
		exit_button.pressed.disconnect(_on_exit_pressed)

	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scenes/level1.tscn")

func _on_exit_pressed():
	get_tree().quit()
