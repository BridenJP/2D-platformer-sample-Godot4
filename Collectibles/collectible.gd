extends Area2D

# Applying a class name is required so we can subclass.
# It can also be useful if we need to identify a node.
class_name Collectible

# Signal when I am collected
signal collected

# So we can give collectibles different values (for adding to score etc)
@export var value: int = 1

func _ready() -> void:
	# Note: This could be done directly on the node, but having it
	# in code makes it easier to follow 
	add_to_group("collectible")

func _on_body_entered(body: Node) -> void:
	if body is Player:
		$Sounds.playTrack(get_sound())
		hide() # NOTE: We'll free the collectible when the sound finishes		
		emit_signal("collected", value)

func _on_main_sounds_finished() -> void:
	queue_free() # Remove the object

func get_sound() -> Sounds.Tracks:
	return Sounds.Tracks.Collect
