extends CharacterBody2D

@export var speed := 100
@export var dash_speed := 300
@export var dash_duration := 0.2
@export var dash_cooldown := 2.5
@export var dash_effect_time := 0.05  # Effekt für die Transparenz während des Dashens
@export var camera_swing_amount := 10  # Schwung der Kamera in die Dash-Richtung

@onready var anim := $AnimationPlayer
@onready var sprite := $Sprite2D
@onready var camera := $Camera2D  # Verweis auf die Kamera

var last_direction := "south"
var is_attacking := false
var is_dashing := false

var attack_cooldown_timer := 0.0
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector2.ZERO
var dash_effect_timer := 0.0  # Timer für den Dash-Effekt

var dash_scale_factor := 1.5  # Skalierungsfaktor für den Dash-Effekt
var original_camera_position := Vector2.ZERO  # Ursprüngliche Kamera-Position

var health := 100  # Beispiel: Lebenspunkte des Spielers

func _ready():
	anim.animation_finished.connect(_on_attack_animation_finished)
	original_camera_position = camera.position  # Speichere die ursprüngliche Kamera-Position

func _physics_process(delta):
	# Timer runterzählen
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if dash_timer > 0:
		dash_timer -= delta
	else:
		is_dashing = false

	# Dash-Effekt Timer
	if dash_effect_timer > 0:
		dash_effect_timer -= delta
		if dash_effect_timer <= 0:
			# Setze Transparenz zurück nach dem Effekt
			sprite.modulate.a = 1.0
			# Reset Scale nach Dash
			sprite.scale = Vector2(1, 1)
			# Stoppe das Kamera-Schwingen und setze Kamera zurück
			camera.position = original_camera_position

	var input_dir := Vector2.ZERO
	var direction_string := ""

	# Dash-Input
	if Input.is_action_just_pressed("dash") and !is_dashing and dash_cooldown_timer <= 0 and !is_attacking:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown

		# Dash Richtung ist letzte Eingabe
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
			# Wenn keine Taste gedrückt ist -> letzter Bewegungsvektor
			match last_direction:
				"north": dash_direction = Vector2.UP
				"south": dash_direction = Vector2.DOWN
				"east": dash_direction = Vector2.RIGHT
		dash_direction = dash_direction.normalized()

		velocity = dash_direction * dash_speed
		move_and_slide()  # Bewegung mit der Dash-velocity

		# Setze Dash-Effekt (Transparenz und Skalierung)
		dash_effect_timer = dash_effect_time
		sprite.modulate.a = 0.5  # Halbtransparenter Effekt
		sprite.scale = Vector2(dash_scale_factor, 1)  # Skalierung des Sprites

		# Kamera-Schwingen in Dash-Richtung
		camera.position = original_camera_position + dash_direction * camera_swing_amount

		return

	# Angriff
	if Input.is_action_just_pressed("attack") and !is_attacking and attack_cooldown_timer <= 0:
		is_attacking = true
		attack_cooldown_timer = 1.0  # Angriff Cooldown auf 1 Sekunde
		anim.play("attack_" + last_direction)
		velocity = Vector2.ZERO
		return

	# Dash-Bewegung
	if is_dashing:
		move_and_slide()  # Keine Argumente, da "velocity" schon gesetzt ist
		return

	# Normale Bewegung
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
			velocity = input_dir * speed
			move_and_slide()

			if abs(input_dir.x) > abs(input_dir.y):
				if input_dir.x > 0:
					direction_string = "east"
					sprite.flip_h = false
				else:
					direction_string = "east"
					sprite.flip_h = true
			else:
				sprite.flip_h = false
				if input_dir.y > 0:
					direction_string = "south"
				else:
					direction_string = "north"

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

# Methode zum Schadennehmen
func take_damage(amount: int):
	health -= amount
	print("Player Health: ", health)
	if health <= 0:
		die()  # Spieler stirbt oder wird zurückgesetzt

# Methode zum Tod des Spielers
func die():
	queue_free()  # Beispiel: Löscht den Player aus der Szene
	# oder setze den Spieler zurück, je nach Bedarf
