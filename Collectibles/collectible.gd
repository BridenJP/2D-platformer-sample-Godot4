extends Area2D

# Applying a class name is required so we can subclass.
# It can also be useful if we need to identify a node.
class_name Collectible

# Signal when I am collected
signal collected

# So we can give collectibles different values (for adding to score etc)
@export var value: int = 1

func get_sound() -> Resource:
	return preload("res://Sounds/collect.wav")

func _ready() -> void:
	# Note: This could be done directly on the node, but having it
	# in code makes it easier to follow 
	add_to_group("collectible")
	
	# Load sound
	$CollectSound.stream = get_sound()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		$CollectSound.play()
		hide() # NOTE: We'll free the collectible when the sound finishes		
		emit_signal("collected", value)

func _on_collect_sound_finished():
	queue_free() # Remove the object
