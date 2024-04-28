extends AudioStreamPlayer
class_name Sounds

enum Tracks {
	Collect, 
	CollectFlower,
	GameOver,
	YouWin,
	Jump,
	Music
}

var Streams: Array[AudioStream] = [
	preload("res://Sounds/collect.wav"),
	preload("res://Sounds/collect-flower.wav"),
	preload("res://Sounds/game-over.mp3"),
	preload("res://Sounds/you-win.wav"),
	preload("res://Sounds/jump.wav"),
	preload("res://Sounds/music.mp3")
]

func playTrack(track: Tracks) -> void:
	stream = Streams[track]
	play()

# Function to fade from the current volume to a target volume over a specified duration
func fade_to(target_volume_db: float, duration: float) -> void:
	var start_volume: float = volume_db
	var elapsed: float = 0.0
	var timer: Timer = Timer.new()  # Create a new Timer node
	add_child(timer)  # Add Timer to the tree
	
	while playing && (elapsed < duration):
		timer.start(0.05)  # Start timer and wait for 0.05 seconds
		await timer.timeout  # Await the timeout signal
		elapsed += 0.05
		volume_db = lerp(start_volume, target_volume_db, elapsed / duration)

	volume_db = target_volume_db  # Ensure it ends at the exact target volume
	remove_child(timer)  # Clean up the timer node
	timer.queue_free()

