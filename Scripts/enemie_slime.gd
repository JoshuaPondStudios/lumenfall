extends CharacterBody2D

@export var speed := 50
@export var detection_radius := 150
@export var minimum_distance := 20
@export var repel_force := 100  # Wie stark der Slime zurückweicht

@onready var anim := $AnimationPlayer
@onready var player = get_parent().get_node_or_null("Player")

var is_repelled := false

func _ready():
	if player == null:
		print("❌ Player nicht gefunden!")
	else:
		print("✅ Player gefunden: " + player.name)

func _physics_process(delta):
	if player == null:
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	# Sofortige Reaktion bei Kollisionsüberschneidung
	if distance <= minimum_distance:
		is_repelled = true
		var repel_dir = -to_player.normalized()
		velocity = repel_dir * repel_force * delta  # Nutze delta für frame-unabhängige Bewegung
		anim.play("idle")
	elif distance > minimum_distance + 8:
		is_repelled = false

	# Nur verfolgen, wenn nicht zurückgestoßen
	if distance <= detection_radius and !is_repelled:
		var direction = to_player.normalized()
		velocity = direction * speed
		anim.play("walk")
	elif !is_repelled:
		velocity = Vector2.ZERO
		anim.play("idle")

	move_and_slide()
