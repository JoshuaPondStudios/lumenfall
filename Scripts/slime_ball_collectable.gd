extends StaticBody2D

@export var item: InvItem
var player=null

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		playercollect()
		self.queue_free()

func playercollect():
	player.collect(item)
