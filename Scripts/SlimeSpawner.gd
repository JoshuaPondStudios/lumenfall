extends Node2D

@export var spawn_interval := 2.0
@export var spawn_radius := 200
@export var slime_scene: PackedScene = preload("res://Scenes/enemie_slime.tscn")
@export var max_slimes := 4
@export var tilemap: TileMap

# ✅ Diese Tile-IDs sind verboten – im Inspector editierbar!
@export var forbidden_tile_ids: Array[int] = [6]

var timer: Timer
@onready var player := get_node("Player")
var slimes: Array = []

func _ready():
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = spawn_interval
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	timer.start()

func _on_timer_timeout():
	if slimes.size() < max_slimes:
		var spawn_position = get_random_spawn_position()
		spawn_slime(spawn_position)

func get_random_spawn_position() -> Vector2:
	var spawn_position = Vector2(randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_radius, spawn_radius)) + global_position

	for slime in slimes:
		if spawn_position.distance_to(slime.global_position) < slime.get_node("CollisionShape2D").shape.radius * 2:
			return get_random_spawn_position()

	if is_invalid_spawn_position(spawn_position):
		return get_random_spawn_position()

	return spawn_position

func is_invalid_spawn_position(position: Vector2) -> bool:
	if tilemap == null:
		print("❌ Tilemap ist nicht zugewiesen!")
		return false

	var local_pos = tilemap.to_local(position)
	var cell = tilemap.local_to_map(local_pos)
	var tile_id = tilemap.get_cell_source_id(0, cell)

	if forbidden_tile_ids.has(tile_id):
		print("🚫 Ungültiger Spawn auf verbotener TileID:", tile_id, "bei Zelle:", cell)
		return true

	return false

func spawn_slime(position: Vector2):
	if slime_scene:
		var slime = slime_scene.instantiate()
		slime.global_position = position
		add_child(slime)

		if slime.has_method("set_player"):
			slime.set_player(player)

		slimes.append(slime)

func remove_slime(slime):
	slimes.erase(slime)
