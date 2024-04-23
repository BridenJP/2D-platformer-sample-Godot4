extends CanvasLayer

signal game_started

# Load common script
const Common = preload("res://common.gd") 
# Game State is communicated via signals
var state: Common.GAME_STATE = Common.GAME_STATE.Start

# Called when the node enters the scene tree for the first time.
func _ready():
	# Trigger state changed to false to set initial (non-playing) state
	_on_state_changed(Common.GAME_STATE.Start)
	
	# Get the main scene and connect signals
	var main: Node = get_tree().root.get_node_or_null("Main")
	assert(main, "Main scene not found or not ready")
	main.connect("state_changed", _on_state_changed)
	main.connect("score_changed", _on_score_changed)
	main.connect("health_changed", _on_health_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
		start_game()

func _on_state_changed(value: Common.GAME_STATE) -> void:
	var changed: bool = state != value
	state = value
	$StartButton.visible = state == Common.GAME_STATE.Start
	$ScoreLabel.visible = state != Common.GAME_STATE.Start
	$HealthLabel.visible = state != Common.GAME_STATE.Start
	$GameOverLabel.visible = state == Common.GAME_STATE.GameOver
	$YouWinLabel.visible = state == Common.GAME_STATE.YouWin
	if changed && state == Common.GAME_STATE.Playing:
		$AnimationPlayer.play("fade_out")
	elif changed && state == Common.GAME_STATE.Start:
		$AnimationPlayer.play("fade_in")

func _on_score_changed(value: int) -> void:
	$ScoreLabel.text = str(value)

func _on_health_changed(value: int) -> void:
	$HealthLabel.text = str(value)

# StartButton pressed
func _on_start_button_pressed() -> void:
	start_game()
	
# Start the game (from button press or keyboard)
func start_game() -> void:
	if state == Common.GAME_STATE.Start:
		game_started.emit()
