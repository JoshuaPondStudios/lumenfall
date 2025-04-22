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

@onready var anim := $AnimationPlayer
@onready var sprite := $Sprite2D
@onready var camera := $Camera2D
@onready var attack_area := $AttackArea

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

func _ready():
	add_to_group("player")
	anim.animation_finished.connect(_on_attack_animation_finished)
	original_camera_position = camera.position  # Ursprüngliche Kamera-Position
	sprite.scale = Vector2(1, 1)  # Sicherstellen, dass die Skalierung nicht verzerrt

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

		dash_effect_timer = dash_effect_time
		sprite.modulate.a = 0.5
		sprite.scale = Vector2(dash_scale_factor, 1)
		camera.position = original_camera_position + dash_direction * camera_swing_amount

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
			if !anim.is_playing() or not anim.current_animation.begins_with("walk"):
				anim.play("walk_" + direction_string)

			last_direction = direction_string
		else:
			velocity = Vector2.ZERO
			anim.play("idle_" + last_direction)

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

# Methode zum Schadennehmen
func take_damage(amount: int):
	health -= amount
	print("Player Health: ", health)
	if health <= 0:
		die()  # Tod des Spielers

# Methode zum Tod des Spielers
func die():
	queue_free()  # Löscht den Spieler
