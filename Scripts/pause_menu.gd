extends Control

@onready var anim = $AnimationPlayer
@onready var panelContainer = $PanelContainer

func _ready():
	panelContainer.visible = false
	anim.process_mode = Node.PROCESS_MODE_ALWAYS
	anim.play("RESET")

func resume():
	panelContainer.visible = false
	get_tree().paused = false
	anim.play_backwards("blur")
	await anim.animation_finished

func pause():
	panelContainer.visible = true
	anim.play("blur")
	await anim.animation_finished
	get_tree().paused = true

func testEsc():
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused:
			resume()
		else:
			await pause()

func _on_resume_pressed():
	resume()

func _on_main_menu_pressed():
	get_tree().paused = false  # Wichtig! Sonst friert das Menü nach dem Szenenwechsel ein
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _process(delta):
	testEsc()
