extends Area2D

@export var item: InvItem
@export var pickup_sound: AudioStream

var player = null
var collected = false
var timer := 0.0
var collect_time := 0.4 # bisschen knackiger

var spin_speed := 20.0  # schneller drehen (vorher 8)
var rise_speed := 60.0  # weniger hoch steigen (vorher 120)

@onready var sprite = $Shadow/ItemSprite
@onready var audio = AudioStreamPlayer.new()

func _ready() -> void:
	add_child(audio)

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	if body.is_in_group("player"):
		player = body
		player.collect(item)
		collected = true
		$CollisionShape2D.disabled = true
		set_process(true)
		
		# SOUND
		audio.stream = pickup_sound
		audio.play()
		
		# GLÜHEN
		sprite.modulate = Color(1, 1, 1, 1) * 2.0 # Überhellen

func _process(delta: float) -> void:
	if collected:
		timer += delta
		position.y -= rise_speed * delta

		# Glühen abklingen lassen
		sprite.modulate = sprite.modulate.lerp(Color(1, 1, 1, 0), delta * 5)

		# Fake-3D Spin
		sprite.scale.x = sin(timer * spin_speed) * 1.1

		# Weiches Pulsieren
		sprite.scale.y = 1.0 + sin(timer * 24.0) * 0.08
		
		if timer >= collect_time:
			queue_free()
