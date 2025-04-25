extends Panel

@onready var item_visual: Sprite2D = $CenterContainer/Panel/ItemDisplay
@onready var amount_text: Label = $CenterContainer/Panel/Label

func update(slot: InvSlot):
	# Wenn der Slot leer oder das Item null ist
	if slot == null or slot.item == null:
		item_visual.visible = false
		amount_text.visible = false
		return
	
	# Das Item sichtbar machen und die Textur des Sprites setzen
	item_visual.visible = true
	item_visual.texture = slot.item.texture

	# Wenn die Menge > 1 ist, die Menge anzeigen
	if slot.amount > 1:
		amount_text.visible = true
		amount_text.text = str(slot.amount)
	else:
		# Wenn die Menge 1 oder weniger ist, das Textlabel ausblenden
		amount_text.visible = false
