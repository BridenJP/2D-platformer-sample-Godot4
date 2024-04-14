extends CanvasLayer

signal game_started

var playing = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Trigger playing changed to false to set initial (non-playing) state
	_on_playing_changed(false)
	
	# Get the main scene and connect signals
	var main: Node = get_tree().root.get_node_or_null("Main")
	assert(main, "Main scene not found or not ready")
	main.connect("playing_changed", _on_playing_changed)
	main.connect("score_changed", _on_score_changed)
	main.connect("health_changed", _on_health_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
		start_game()

func _on_playing_changed(value):
	playing = value
	$StartButton.visible = !playing
	$ScoreLabel.visible = playing
	$HealthLabel.visible = playing

func _on_score_changed(value: int):
	$ScoreLabel.text = str(value)

func _on_health_changed(value: int):
	$HealthLabel.text = str(value)

# StartButton pressed
func _on_start_button_pressed():
	start_game()
	
func start_game():
	if !playing:
		game_started.emit()
