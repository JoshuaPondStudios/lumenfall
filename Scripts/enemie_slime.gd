extends CharacterBody2D

@export var speed := 50
@export var detection_radius := 100
@export var minimum_distance := 20
@export var repel_force := 100
@export var max_health := 3
@export var damage := 10
@export var damage_interval := 1.0
@export var drop_items: Array[DropItemData] = []

var health := max_health
var is_dead := false
var is_repelled := false
var fade_tween: Tween = null
var player: Node2D = null
var time_since_last_damage := 0.0
var collision_timer_started := false

@onready var anim := $AnimationPlayer
@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D
@onready var health_bar_wrapper := $HealthBarWrapper
@onready var health_bar := $HealthBarWrapper/HealthBar
@onready var hide_timer := $HideTimer
var collision_timer: Timer

func _ready():
	add_to_group("enemy")

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("✅ Player gefunden: " + player.name)
	else:
		print("❌ Kein Player in der Gruppe gefunden!")

	anim.animation_finished.connect(_on_animation_finished)
	health_bar.value = 100
	health_bar_wrapper.modulate.a = 0.0
	hide_timer.wait_time = 2.0
	hide_timer.one_shot = true

	# Timer für Schadensverzögerung initialisieren
	collision_timer = Timer.new()
	collision_timer.wait_time = 0.3
	collision_timer.one_shot = true
	add_child(collision_timer)
	collision_timer.timeout.connect(_on_collision_timer_timeout)

func _physics_process(delta):
	if player == null or is_dead:
		return

	time_since_last_damage += delta
	var to_player = player.global_position - global_position
	var distance = to_player.length()

	# Verzögerter Schaden
	if distance <= minimum_distance:
		if not collision_timer_started:
			collision_timer_started = true
			collision_timer.start()
		elif time_since_last_damage >= damage_interval and not collision_timer.is_stopped():
			pass
		elif time_since_last_damage >= damage_interval:
			if player.has_method("take_damage"):
				var attack_direction = (player.position - position).normalized()
				player.take_damage(damage, attack_direction)
				print("🧪 Slime verursacht ", damage, " Schaden")
				time_since_last_damage = 0.0
	else:
		collision_timer_started = false
		collision_timer.stop()

	# Rückstoß
	if distance <= minimum_distance:
		is_repelled = true
		var repel_dir = -to_player.normalized()
		velocity = repel_dir * repel_force * delta
		anim.play("idle")
	elif distance > minimum_distance + 8:
		is_repelled = false

	# Bewegung
	if distance <= detection_radius and !is_repelled:
		var direction = to_player.normalized()
		velocity = direction * speed
		anim.play("walk")
	elif !is_repelled:
		velocity = Vector2.ZERO
		anim.play("idle")

	move_and_slide()

func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO):
	if is_dead:
		return

	health -= amount
	print("💥 Slime getroffen! Health: ", health)

	var knockback_dir = (global_position - from_position).normalized()
	velocity = knockback_dir * repel_force
	is_repelled = true
	anim.play("hurt")

	sprite.modulate = Color(1, 0.2, 0.2)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)

	await get_tree().create_timer(0.2).timeout
	is_repelled = false

	if fade_tween != null and fade_tween.is_running():
		fade_tween.kill()

	health_bar_wrapper.modulate.a = 1.0
	health_bar.value = float(health) / float(max_health) * 100.0
	hide_timer.stop()
	hide_timer.start()

	if health <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	collision.disabled = true
	anim.play("die")

	# Drop-System mit mehreren Items
	var dropped = false
	for item_data in drop_items:
		if item_data.scene and randf() < item_data.chance:
			var item_instance = item_data.scene.instantiate()
			item_instance.global_position = global_position
			get_tree().current_scene.add_child(item_instance)
			print("🎁 Gedroppt: ", item_data.scene.resource_path)
			dropped = true
			break

	if not dropped:
		print("🙅‍♂️ Kein Item gedroppt.")

	var spawner = get_parent()
	if spawner.has_method("remove_slime"):
		spawner.remove_slime(self)

func _on_animation_finished(anim_name):
	if anim_name == "die":
		queue_free()

func _on_HideTimer_timeout():
	fade_tween = create_tween()
	fade_tween.tween_property(health_bar_wrapper, "modulate:a", 0.0, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_collision_timer_timeout():
	print("🕒 Slime ist bereit zu beißen")
