extends Node2D

signal playing_changed
signal score_changed
signal health_changed
signal player_died

var playing: bool
var score: int
var health: int
var level_node: Node # Our placeholder node where we will put the level scene
var current_level: Node2D # The currently loaded level scene

const MUSIC_VOL_DB: float = -30.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_node = get_node("Level")
# 
func play() -> void:
	set_playing(true)
	set_score(0)
	set_health(1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	# change _delta back to delta if used
	pass
	
func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		if playing:
			end_level()
		else:
			get_tree().quit()

func end_level() -> void:
	set_playing(false)
	current_level.queue_free()
	current_level = null

func connect_to_group_signal(group_name: String, signal_name: String, target_function: Callable) -> void:
	var group_nodes = get_tree().get_nodes_in_group(group_name)
	for node in group_nodes:
		node.connect(signal_name, target_function)
		
func connect_collectibles() -> void:
	# Find all the collectibles in the tree, and connect to the "collected" signal
	connect_to_group_signal("collectible", "collected", _on_collectible_collected)

func connect_obstacles() -> void:
	# Find all the obstacles in the tree, and connect to the "damage_done" signal
	connect_to_group_signal("obstacle", "damage_done", _on_obstacle_damage_done)

func connect_player() -> void:
	var player: Node = current_level.get_node_or_null("Player")
	assert(player, "Player node not found or not ready")
	player.connect("dying", _on_player_dying)
	player.connect("finished_dying", _on_player_finished_dying)

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

# An obstacle has been hit
func _on_obstacle_damage_done(damage: int):
	set_health(health - damage)
	
func _on_player_dying() -> void:
	$Sounds.playTrack(Sounds.Tracks.GameOver)
	$Music.fade_to(-100.0, 1.0)

func _on_player_finished_dying() -> void:
	print("finished dying")
	set_playing(false)
	end_level()

# Setter for playing (emits signal)
func set_playing(value: bool):
	playing = value
	if playing:		
		$Music.playTrack(Sounds.Tracks.Music)
		$Music.volume_db = MUSIC_VOL_DB
	else:
		$Music.stop()
	emit_signal("playing_changed", playing)
	
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
