extends CharacterBody2D

@export var speed := 75
@export var sprint_speed := 130  # Geschwindigkeit beim Sprinten
@export var dash_speed := 300
@export var dash_duration := 0.2
@export var dash_cooldown := 2.5
@export var dash_effect_time := 0.05
@export var camera_swing_amount := 10
@export var shake_duration := 0.3
@export var shake_intensity := 1

@export var inv: Inv
@export var healing_particles: PackedScene  # Partikel-Effekt

@onready var anim := $AnimationPlayer
@onready var sprite := $Sprite2D
@onready var camera := $Camera2D
@onready var attack_area := $AttackArea
@onready var health_bar := $UI/HealthBar

@onready var heal_sprite := get_node("Sprite2D")  # Dein Spieler-Sprite
var heal_scale := Vector2(1, 1)  # Initiale Skalierung des Spielers

var last_direction := "south"
var is_attacking := false
var is_dashing := false

var attack_cooldown_timer := 0.0
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector2.ZERO
var dash_effect_timer := 0.0

var dash_scale_factor := 1.5
var original_camera_position := Vector2.ZERO

var health := 100

@onready var slime := get_node_or_null("Slime")

var shake_timer := 0.0
var shake_recovery := 0.0

# Knockback-Variablen
var knockback_strength := 100  # Stärke des Knockbacks
var knockback_duration := 0.2  # Dauer des Knockbacks
var knockback_timer := 0.0
var knockback_direction := Vector2.ZERO

func _ready():
	add_to_group("player")
	anim.animation_finished.connect(_on_attack_animation_finished)
	original_camera_position = camera.position  # Ursprüngliche Kamera-Position
	sprite.scale = Vector2(1, 1)  # Sicherstellen, dass die Skalierung nicht verzerrt

func _process(delta: float) -> void:
		if Input.is_action_just_pressed("heal"):
			use_healing_item()

func _physics_process(delta):
	# Timers reduzieren
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if dash_timer > 0:
		dash_timer -= delta
	else:
		is_dashing = false

	if dash_effect_timer > 0:
		dash_effect_timer -= delta
		if dash_effect_timer <= 0:
			sprite.modulate.a = 1.0
			sprite.scale = Vector2(1, 1)
			camera.position = original_camera_position

	if shake_timer > 0:
		shake_timer -= delta
		var shake_offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		camera.position = original_camera_position + shake_offset

		if shake_timer <= 0 and shake_recovery <= 0:
			shake_recovery = 0.1  # Wiederherstellungszeit für den Shake

	elif shake_recovery > 0:
		shake_recovery -= delta
		if shake_recovery <= 0:
			camera.position = original_camera_position

	else:
		camera.position = original_camera_position

	var input_dir := Vector2.ZERO
	var direction_string := ""

	# Dash-Logik
	if Input.is_action_just_pressed("dash") and !is_dashing and dash_cooldown_timer <= 0 and !is_attacking:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown

		dash_direction = Vector2.ZERO
		if Input.is_action_pressed("right"):
			dash_direction.x += 1
		if Input.is_action_pressed("left"):
			dash_direction.x -= 1
		if Input.is_action_pressed("down"):
			dash_direction.y += 1
		if Input.is_action_pressed("up"):
			dash_direction.y -= 1

		if dash_direction == Vector2.ZERO:
			match last_direction:
				"north": dash_direction = Vector2.UP
				"south": dash_direction = Vector2.DOWN
				"east": dash_direction = Vector2.RIGHT
				"west": dash_direction = Vector2.LEFT
		dash_direction = dash_direction.normalized()

		velocity = dash_direction * dash_speed
		move_and_slide()
		anim.play("dash")
		return

	# Sprint-Logik: Wenn Shift gedrückt wird, beschleunigt der Spieler
	var current_speed := speed
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	if Input.is_action_just_pressed("attack") and !is_attacking and attack_cooldown_timer <= 0:
		is_attacking = true
		attack_cooldown_timer = 1.0
		anim.play("attack_" + last_direction)
		velocity = Vector2.ZERO
		_attack()  # Ruft die Angriffslogik auf
		return

	if is_dashing:
		move_and_slide()
		return

	if !is_attacking:
		if Input.is_action_pressed("right"):
			input_dir.x += 1
		if Input.is_action_pressed("left"):
			input_dir.x -= 1
		if Input.is_action_pressed("down"):
			input_dir.y += 1
		if Input.is_action_pressed("up"):
			input_dir.y -= 1

		if input_dir != Vector2.ZERO:
			input_dir = input_dir.normalized()
			velocity = input_dir * current_speed  # Die Geschwindigkeit abhängig von Sprint
			move_and_slide()

			# Richtungswechsel sofort umsetzen und Animation anpassen
			if abs(input_dir.x) > abs(input_dir.y):
				if input_dir.x > 0:
					direction_string = "east"
					sprite.flip_h = false  # Blick nach rechts
				else:
					direction_string = "east"  # Die gleiche Animation für West
					sprite.flip_h = true  # Umgekehrte Blickrichtung
			elif abs(input_dir.x) < abs(input_dir.y):
				if input_dir.y > 0:
					direction_string = "south"
					sprite.flip_h = false
				else:
					direction_string = "north"
					sprite.flip_h = false
			else:
				# Falls beide Achsen gleichzeitig gedrückt sind, überprüfe die Hauptrichtung
				if input_dir.x > 0:
					direction_string = "east"
					sprite.flip_h = false
				elif input_dir.x < 0:
					direction_string = "east"  # Die gleiche Animation für West
					sprite.flip_h = true  # Umgekehrte Blickrichtung
				elif input_dir.y > 0:
					direction_string = "south"
					sprite.flip_h = false
				else:
					direction_string = "north"
					sprite.flip_h = false

			# Animationsgeschwindigkeit anpassen
			var anim_speed := current_speed / speed  # Verhältnis der Geschwindigkeiten
			anim.speed_scale = anim_speed  # Animationsgeschwindigkeit anpassen

			# Animation abspielen und sofortige Richtungsänderung sicherstellen
			if direction_string != last_direction or not anim.current_animation.begins_with("walk"):
				anim.play("walk_" + direction_string)


			last_direction = direction_string
		else:
			velocity = Vector2.ZERO
			anim.play("idle_" + last_direction)

	# Knockback-Logik, wenn der Spieler getroffen wird
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_direction * knockback_strength  # Bewege den Spieler in die entgegengesetzte Richtung des Angriffs
		move_and_slide()
		anim.play("hit")  # Optional eine "hit" Animation abspielen

# Callback wenn Animation endet
func _on_attack_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("attack"):
		is_attacking = false
		if velocity != Vector2.ZERO:
			anim.play("walk_" + last_direction)
		else:
			anim.play("idle_" + last_direction)

# Angriffslogik
func _attack():
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy"):
			body.take_damage(1)
			shake_timer = shake_duration  # Shake-Effekt aktivieren
			shake_recovery = 0.2  # Verzögerung für den Nachhall

# Methode zum Schadennehmen und Knockback anwenden
func take_damage(amount: int, attack_direction: Vector2):
	health -= amount
	health = clamp(health, 0, 100)
	health_bar.value = health
	print("Player Health: ", health)
	
	# Setze den Knockback-Effekt
	knockback_direction = attack_direction.normalized()  # Angriff kommt von der Richtung
	knockback_timer = knockback_duration
	
	# Optional: Kamerazittern bei Knockback
	shake_timer = shake_duration  # Shake-Effekt aktivieren
	shake_recovery = 0.2  # Verzögerung für den Nachhall

	# Wenn der Spieler keine Gesundheit mehr hat, stirbt er
	if health <= 0:
		die()

# Methode zum Tod des Spielers
func die():
	queue_free()  # Löscht den Spieler

func collect(item):
	inv.insert(item)

func use_healing_item():
	# Finde den ersten Heiltrank im Inventar
	for slot in inv.slots:
		if slot != null and slot.item != null and slot.item.can_heal:
			var item = slot.item
			item.use_item(self)
			inv.update.emit()  # UI benachrichtigen

			# Spieler-Feedback: Heil-Effekt und Animation
			play_heal_sound()   # Soundeffekt (falls gewünscht)
			start_heal_animation()  # Heil-Animation für den Spieler
			return  # Nur einen Trank verwenden

# Akustischer Heil-Effekt
func play_heal_sound():
	var heal_sound = preload("res://Sounds/healing.mp3")  # Stelle sicher, dass die Datei existiert
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = heal_sound
	add_child(audio_player)
	audio_player.play()  # Heilt, wenn der Sound abgespielt wird

func start_heal_animation():
	# Pulsierende Heil-Animation (Skalierung)
	var scale_up := Vector2(1.1, 1.1)  # Vergrößerte Skalierung
	var scale_down := Vector2(1.0, 1.0)  # Zurück zur normalen Skalierung

	# Spieler skalieren
	heal_sprite.scale = scale_up
	await get_tree().create_timer(0.2).timeout

	heal_sprite.scale = scale_down
	await get_tree().create_timer(0.2).timeout

	# Spieler leuchten lassen (Farbe ändern)
	heal_sprite.modulate = Color(1, 1, 0, 1)  # Spieler wird gelb
	await get_tree().create_timer(0.2).timeout

	heal_sprite.modulate = Color(1, 1, 1, 1)  # Zurück zur normalen Farbe
