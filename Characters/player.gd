extends CharacterBody2D

class_name Player

signal dying
signal finished_dying
signal winning
signal finished_winning

# Normal walking speed
const SPEED: float = 300.0
# How much to multiply by when running (Shift key)
const RUN_MULTIPLIER: float = 2.0
# Initial upwards velocity when we jump
const JUMP_VELOCITY: float = -700.0

# "dying" -> "dead" state while the sound and animation plays
# "winning" -> "won" state while the sound and animation plays
enum LIFE_CYCLE {Alive, Dying, Dead, Winning, Won}

# Get the gravity from the project settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
# Track the current animation
var animation: String
# Which way facing? Used to mirror character and adjust position of sprite
var facing_right: bool = true
# Different things happen when we are jumping
var jumping: bool = false
# Initial state of life
var life_cycle: LIFE_CYCLE = LIFE_CYCLE.Alive

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Just standing there
	set_animation("idle")

	# Get the main scene and connect signals
	var main: Node = get_tree().root.get_node_or_null("Main")
	assert(main, "Main scene not found or not ready")
	main.connect("health_changed", _on_health_changed)
	main.connect("level_complete", _on_level_complete)

# Change the current animation
func set_animation(value: String) -> void:
	if animation != value:
		animation = value
		$Sprite.play(animation)
	update_sprite()

# Update the sprite appearance
func update_sprite() -> void:
	# Flip horizontally when we are going left
	$Sprite.flip_h = !facing_right
	# Adjust the sprite position depending on which animation
	# This is needed because the sprites are not well centred in their frame
	match animation:
		"idle":
			$Sprite.position.x = 32 if facing_right else -32
		"run":
			$Sprite.position.x = 20 if facing_right else -20
		"walk":
			$Sprite.position.x = 32 if facing_right else -32
		_:
			$Sprite.position.x = 32 if facing_right else -32			
	
func stop_and_signal(signal_name: StringName) -> void:
	# Stop processes
	set_process(false)  
	set_physics_process(false)
	
	emit_signal(signal_name)

# This is where we continually manage our character's state
func _physics_process(delta: float) -> void:
	# Are we standing on something?
	var airborne: bool = not is_on_floor()
	
	# If we are in the air...
	if airborne:
		# Apply gravity
		velocity.y += gravity * delta
		# If we are in the air, but NOT because of the jump key, do the jump animation
		if !jumping:
			set_animation("jump_start")
			jumping = true # Set jumping to true, so we don't repeat this

	# If we are dying or dead, or winning or won, stop forward motion but continue general movement
	if life_cycle != LIFE_CYCLE.Alive:
		if airborne:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			move_and_slide()
		elif life_cycle == LIFE_CYCLE.Dead:
			stop_and_signal("finished_dying")
		elif life_cycle == LIFE_CYCLE.Won:
			emit_signal("finished_winning")
		return # Don't go past here
		
	# If we aren't in the air, but we were previously, play the landing animation
	# TODO This currently only lasts one frame, need to handle timing
	if !airborne && jumping:
		set_animation("jump_land")
		jumping = false # No longer jumping
		
	# Handle jump action
	if Input.is_action_just_pressed("ui_accept") and !airborne:
		velocity.y = JUMP_VELOCITY
		set_animation("jump_start")
		$Sounds.playTrack(Sounds.Tracks.Jump)
		jumping = true

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction: float = Input.get_axis("go_left", "go_right")
	# When the shift key is pressed we power up from walking to running
	var running: bool = Input.is_action_pressed("power")
	var mult: float = RUN_MULTIPLIER if running else 1.0

	if direction:
		# For non-zero values we set the velocity
		velocity.x = direction * SPEED * mult
	else:
		# For zero value we slow to 0
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# if we're in the air, facing left/right is determined by our velocity.
	if jumping:
		facing_right = velocity.x > 0
	# Otherwise, if we have no velocity we are idle
	elif velocity.x == 0:
		set_animation("idle")
	# Or, if we have velocity then we are walking or running, and facing left/right is also determined by velocity
	else:
		set_animation("run" if running else "walk")
		facing_right = velocity.x > 0

	# Update the sprite's appearance
	update_sprite()
	
	# Process movement
	move_and_slide()
	
	# Check for collisions after moving
	for i in range(get_slide_collision_count()):
		var collider: Object = get_slide_collision(i).get_collider()
		if (collider is TileMap) && (collider.name == "DeadlyGround"):
			die()
		elif !(collider is TileMap):
			print(collider.name)
		# TODO Do something with the collider

# Die! Set to "dying", play "dead" animation and emit signal
func die() -> void:
	life_cycle = LIFE_CYCLE.Dying
	emit_signal("dying")
	set_animation("dead")

# Main tells us when our health changes
func _on_health_changed(value: int) -> void:
	# If health is 0, we are dying
	if (life_cycle == LIFE_CYCLE.Alive) && (value <= 0):
		die()

func _on_level_complete() -> void:
	life_cycle = LIFE_CYCLE.Winning
	emit_signal("winning")
	set_animation("win")

# Handle changes that occur at end of animations
func _on_sprite_animation_finished() -> void:
	if animation == "jump_start" && jumping:
		set_animation("jump_middle")
		
	if animation == "dead" && life_cycle == LIFE_CYCLE.Dying:
		life_cycle = LIFE_CYCLE.Dead

	if animation == "win" && life_cycle == LIFE_CYCLE.Winning:
		life_cycle = LIFE_CYCLE.Won
		
# Die! Set to "dying", play "dead" animation and emit signal
