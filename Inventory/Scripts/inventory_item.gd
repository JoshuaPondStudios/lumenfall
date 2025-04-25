extends Resource

class_name InvItem

@export var name: String = ""  # Name des Items
@export var texture: Texture2D  # Textur des Items
@export var can_heal: bool = false  # Gibt an, ob das Item heilen kann
@export var heal_amount: int = 0  # Heilwert des Items (nur relevant, wenn can_heal == true)
@export var amount: int = 1  # Menge des Items

# Optional: Du könntest noch weitere Eigenschaften hinzufügen, z.B. für Verbrauch oder Verwendung.
@export var is_consumable: bool = true  # Gibt an, ob das Item nach Verwendung verbraucht wird

func _ready():
	# Hier könnten wir die Initialisierung vornehmen, falls nötig
	pass
