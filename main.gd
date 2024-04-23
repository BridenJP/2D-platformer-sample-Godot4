extends Node2D

signal state_changed # The game state has changed
signal score_changed # The score has changed
signal health_changed # The player's health has changed
signal level_complete # The level has been finished (in some way)

const Common = preload("res://common.gd")
var state: Common.GAME_STATE
var score: int
var health: int
var n_collectibles: int
var level_node: Node # Our placeholder node where we will put the level scene
var current_level: Node2D # The currently loaded level scene

const MUSIC_VOL_DB: float = -30.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_node = get_node("Level")
	
# Start playing the game
func play() -> void:
	set_state(Common.GAME_STATE.Playing)
	set_score(0)
	set_health(1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# change _delta back to delta if used
	pass
	
# Called when an input event occurs
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if state == Common.GAME_STATE.Playing:
			end_level()
		else:
			get_tree().quit()

# The level is over. Clear it and return to the Start state.
func end_level() -> void:
	if current_level:
		current_level.queue_free()
	current_level = null
	set_state(Common.GAME_STATE.Start)

# Connect to a signal from any member of the specified group
func connect_to_group_signal(group_name: String, signal_name: String, target_function: Callable) -> int:
	var group_nodes: Array[Node] = get_tree().get_nodes_in_group(group_name)
	for node in group_nodes:
		node.connect(signal_name, target_function)
	return group_nodes.size()

# Connect to signals from collectibles
func connect_collectibles() -> void:
	# Find all the collectibles in the tree, and connect to the "collected" signal
	n_collectibles = connect_to_group_signal("collectible", "collected", _on_collectible_collected)

# Connect to signals from obstacles
func connect_obstacles() -> void:
	# Find all the obstacles in the tree, and connect to the "damage_done" signal
	connect_to_group_signal("obstacle", "damage_done", _on_obstacle_damage_done)

# Connect to signals from the player
func connect_player() -> void:
	var player: Player = current_level.get_node_or_null("Player")
	assert(player, "Player node not found or not ready")
	player.connect("dying", _on_player_dying)
	player.connect("finished_dying", _on_player_finished_dying)
	player.connect("winning", _on_player_winning)
	player.connect("finished_winning", _on_player_finished_winning)

# When the HUD tells us to start the game
func _on_hud_game_started():
	# If we don't have the current level load it and add it to our placeholder
	if !current_level:
		current_level = load("res://Levels/level_1.tscn").instantiate()
		level_node.add_child(current_level)

	# Connect to signals
	connect_player()
	connect_collectibles()
	connect_obstacles()

	# Play!
	play()

# A collectible has been collected
func _on_collectible_collected(value: int):
	set_score(score + value)
	n_collectibles -= 1
	
	if n_collectibles == 0:
		emit_signal("level_complete")

# An obstacle has been hit
func _on_obstacle_damage_done(damage: int):
	set_health(health - damage)
	
func _on_player_dying() -> void:
	$Sounds.playTrack(Sounds.Tracks.GameOver)
	$Music.fade_to(-100.0, 1.0)

func _on_player_finished_dying() -> void:
	set_state(Common.GAME_STATE.GameOver)
	await get_tree().create_timer(3.0).timeout # Pause a moment before exiting	
	end_level()

func _on_player_winning() -> void:
	$Sounds.playTrack(Sounds.Tracks.YouWin)
	$Music.fade_to(-100.0, 1.0)

func _on_player_finished_winning() -> void:
	set_state(Common.GAME_STATE.YouWin)
	await get_tree().create_timer(3.0).timeout # Pause a moment before exiting	
	end_level()

# Setter for state (emits signal)
func set_state(value: Common.GAME_STATE):
	state = value
	if state == Common.GAME_STATE.Playing:
		$Music.playTrack(Sounds.Tracks.Music)
		$Music.volume_db = MUSIC_VOL_DB
	else:
		$Music.stop()
	emit_signal("state_changed", state)
	
# Setter for score (emits signal)
func set_score(value: int):
	score = value
	emit_signal("score_changed", score)
	
# Setter for health (emits signal)
func set_health(value: int):
	health = value
	if health <= 0:
		health = 0 # No need to be negative
	emit_signal("health_changed", health)
