extends Area2D

@export var item: InvItem
var player = null

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		player.collect(item)
		queue_free()
