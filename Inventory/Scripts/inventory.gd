extends Resource

class_name Inv
signal update

@export var slots: Array[InvSlot]

func insert(item: InvItem) -> void:
	# Filter Slots, die nicht null sind und das gleiche Item enthalten
	var itemslots = slots.filter(func(slot):
		return slot != null and slot.item == item
	)

	# Falls ein solcher Slot existiert, einfach die Menge erhöhen
	if !itemslots.is_empty():
		itemslots[0].amount += 1
	else:
		# Ansonsten suchen wir einen leeren Slot (slot != null UND item == null)
		var emptyslots = slots.filter(func(slot):
			return slot != null and slot.item == null
		)

		# Wenn ein leerer Slot existiert, Item rein und Menge auf 1 setzen
		if !emptyslots.is_empty():
			emptyslots[0].item = item
			emptyslots[0].amount = 1
		else:
			push_warning("Kein leerer Slot verfügbar zum Einfügen von %s" % item.name)

	# Signal aussenden, um UI oder andere Listener zu benachrichtigen
	update.emit()

# Neue Funktion zum Entfernen eines Items
func remove_item(item: InvItem) -> void:
	# Suche den Slot, der das Item enthält
	var itemslots = slots.filter(func(slot):
		return slot != null and slot.item == item
	)

	# Wenn ein Slot mit dem Item gefunden wurde
	if !itemslots.is_empty():
		var slot = itemslots[0]
		# Wenn die Menge > 1, verringere die Menge
		if slot.amount > 1:
			slot.amount -= 1
		else:
			# Ansonsten das Item vollständig entfernen (Menge 0)
			slot.item = null
			slot.amount = 0
		# Signal aussenden, um UI zu aktualisieren
		update.emit()
	else:
		print("Item nicht im Inventar gefunden!")
