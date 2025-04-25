extends Resource

class_name InvItem

@export var name: String = ""  # Name des Items
@export var texture: Texture2D  # Textur des Items
@export var can_heal: bool = false  # Gibt an, ob das Item heilen kann
@export var heal_amount: int = 0  # Heilwert des Items (nur relevant, wenn can_heal == true)
@export var amount: int = 1  # Menge des Items

@export var is_consumable: bool = true  # Gibt an, ob das Item nach Verwendung verbraucht wird

func _ready():
	# Hier könnten wir die Initialisierung vornehmen, falls nötig
	pass

func use_item(player) -> void:
	if can_heal:
		player.health += heal_amount
		player.health = clamp(player.health, 0, 100)  # Gesundheit darf nicht über 100 gehen
		player.health_bar.value = player.health  # Aktualisiere die Health-Bar
		if is_consumable:
			amount -= 1
			if amount <= 0:
				player.inv.remove_item(self)
