extends Node2D

@onready var save_game_manager := $SaveGameManager
var current_game_data := GameData.new()

# Spieler und Gegner als Beispiel
@onready var player := $Player

func _ready():
	# Laden des Spielstands beim Start
	current_game_data = save_game_manager.load_game()

	# Setze den Spieler und Gegner anhand der geladenen Daten
	player.health = current_game_data.player_health
	player.position = current_game_data.player_position
	player.velocity = current_game_data.player_velocity
	player.last_direction = current_game_data.player_last_direction

func save_game():
	# Speichern des Spielstands
	save_game_manager.save_game(current_game_data)

func _exit_tree():
	# Speicher automatisch beim Verlassen
	save_game()
