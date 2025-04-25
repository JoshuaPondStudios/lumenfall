extends Control

@onready var inv: Inv = preload("res://Inventory/PlayerInv.tres")
@onready var slots: Array = $NinePatchRect/GridContainer.get_children()

var is_open = false

func _ready():
	inv.update.connect(update_slots)  # Signal von Inv, UI zu aktualisieren
	update_slots()  # Beim Start die Slots laden
	close()

func update_slots():
	# Slots im UI aktualisieren
	for i in range(min(inv.slots.size(), slots.size())):
		# Stelle sicher, dass jeder Slot im UI die aktuelle Item-Daten anzeigt
		slots[i].update(inv.slots[i])

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Inventory"):
		if is_open:
			close()
		else:
			open()

func open():
	visible = true
	is_open = true

func close():
	visible = false
	is_open = false
