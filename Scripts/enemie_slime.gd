extends CharacterBody2D

@export var speed := 50
@export var detection_radius := 100
@export var minimum_distance := 20
@export var repel_force := 100
@export var max_health := 3
var health := max_health
var is_dead := false

@onready var anim := $AnimationPlayer
@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D
var player : Node2D = null  # Referenz auf den Player
var is_repelled := false

func _ready():
	# Füge den Slime zur "enemy"-Gruppe hinzu
	add_to_group("enemy")
	
	# Sucht nach allen Player-Knoten in der "player"-Gruppe
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]  # Den ersten Spieler nehmen, falls es mehrere gibt
		print("✅ Player gefunden: " + player.name)
	else:
		print("❌ Kein Player in der Gruppe gefunden!")
	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	if player == null or is_dead:
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	# Wenn der Slime zu nah am Player ist, wird er zurückgestoßen
	if distance <= minimum_distance:
		is_repelled = true
		var repel_dir = -to_player.normalized()
		velocity = repel_dir * repel_force * delta
		anim.play("idle")
	elif distance > minimum_distance + 8:
		is_repelled = false

	# Wenn der Slime den Player im Umkreis erkennt und nicht zurückgestoßen wird
	if distance <= detection_radius and !is_repelled:
		var direction = to_player.normalized()
		velocity = direction * speed
		anim.play("walk")
	elif !is_repelled:
		velocity = Vector2.ZERO
		anim.play("idle")

	move_and_slide()

func take_damage(amount: int):
	if is_dead:
		return

	health -= amount
	print("💥 Slime getroffen! Health: ", health)

	sprite.modulate = Color(1, 0.2, 0.2)  # Trefferfarbe
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)

	if health <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	collision.disabled = true
	anim.play("die")

	# Entferne den Slime aus der Liste im Spawner
	var spawner = get_parent()
	if spawner.has_method("remove_slime"):
		spawner.remove_slime(self)

func _on_animation_finished(anim_name):
	if anim_name == "die":
		queue_free()
