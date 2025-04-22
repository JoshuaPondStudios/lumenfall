extends CharacterBody2D

@export var speed := 50
@export var detection_radius := 150
@export var attack_radius := 30
@export var damage := 10
@export var jump_height := 50
@export var jump_interval := 3.0

@onready var anim := $AnimationPlayer
@onready var slime_sprite := $Sprite2D

# Hier referenzieren wir direkt den Player-Knoten in der Szene
@onready var player = get_parent().get_node("player")  # "player" ist der Name des Knoten in der Szene

var movement_velocity := Vector2.ZERO
var is_attacking := false
var attack_cooldown := 1.0
var attack_cooldown_timer := 0.0
var last_jump_time := 0.0

func _ready():
	# Überprüfe, ob der Player korrekt referenziert wurde
	if player == null:
		print("Player konnte nicht gefunden werden!")
	else:
		print("Player gefunden: " + player.name)

func _process(delta):
	# Überprüfe, ob der Player existiert, bevor wir die Position verwenden
	if player != null:
		# Berechne die Entfernung zum Spieler
		var distance_to_player = global_position.distance_to(player.global_position)
		print("Entfernung zum Spieler: " + str(distance_to_player))  # Debug-Ausgabe für Entfernung

		if distance_to_player <= detection_radius:
			# Der Slime verfolgt den Spieler
			var direction = (player.global_position - global_position).normalized()
			movement_velocity = direction * speed
			anim.play("walk")  # Animation abspielen

			# Überprüfe, ob der Slime den Spieler angreifen kann
			if distance_to_player <= attack_radius and attack_cooldown_timer <= 0:
				attack_player()
			# Springen, falls der Slime auf dem Boden ist und der Sprungzeitraum abgelaufen ist
			elif is_on_floor() and (Time.get_ticks_msec() - last_jump_time > jump_interval * 1000):
				jump()
		else:
			# Der Slime steht still und spielt die Idle-Animation ab, wenn er den Spieler nicht mehr sieht
			movement_velocity = Vector2.ZERO
			anim.play("idle")  # Idle-Animation abspielen

		move_and_slide()  # Bewegung ausführen

	# Abklingzeit des Angriffs
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

# Angriff-Logik: Spieler bekommt Schaden
func attack_player():
	if !is_attacking:
		is_attacking = true
		attack_cooldown_timer = attack_cooldown
		anim.play("attack")  # Angriff-Animation abspielen
		player.take_damage(damage)  # Hier wird angenommen, dass der Player eine `take_damage()`-Funktion hat
		await anim.animation_finished  # Warten auf das Ende der Animation
		is_attacking = false

# Springen
func jump():
	movement_velocity.y = -jump_height  # Setze die Sprungkraft
	anim.play("jump")  # Sprung-Animation abspielen
	last_jump_time = Time.get_ticks_msec()
