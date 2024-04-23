extends Area2D

# Applying a class name is required so we can subclass.
# It can also be useful if we need to identify a node.
class_name Obstacle

# Signal when I do damage
signal damage_done

# So we can give obstacles different amounts of damage
@export var damage: int = 1

func _ready() -> void:
	# Note: This could be done directly on the node, but having it in code makes it easier to follow 
	add_to_group("obstacle")

func _on_body_entered(body: Node) -> void:
	if body is Player:
		emit_signal("damage_done", damage) # We can give obstacles different damage
