extends CharacterBody2D

class_name Player

signal finished_dying

# Normal walking speed
const SPEED = 300.0
# How much to multiply by when running (Shift key)
const RUN_MULTIPLIER = 2.0
# Initial upwards velocity when we jump
const JUMP_VELOCITY = -700.0

# Used to allow a "dying" state while the animation plays
enum LIFE_CYCLE {Alive, Dying, Dead}

# Get the gravity from the project settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
# Track the current animation
var animation: String
# Which way facing? Used to mirror character and adjust position of sprite
var facing_right: bool = true
# Different things happen when we are jumping
var jumping: bool = false
# Initial state of life
var deadness: LIFE_CYCLE = LIFE_CYCLE.Alive

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Just standing there
	set_animation("idle")

	# Get the main scene and connect signals
	var main: Node = get_tree().root.get_node_or_null("Main")
	assert(main, "Main scene not found or not ready")
	main.connect("health_changed", _on_health_changed)

# Change the current animation
func set_animation(value) -> void:
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
	
# This is where we continually manage our character's state
func _physics_process(delta) -> void:
	# Are we standing on something?
	var airborne = not is_on_floor()
	
	# If we are in the air...
	if airborne:
		# Apply gravity
		velocity.y += gravity * delta
		# If we are in the air, but NOT because of the jump key, do the jump animation
		if !jumping:
			set_animation("jump_start")
			jumping = true # Set jumping to true, so we don't repeat this

	# If we are dying or dead, stop forward motion but continue general movement
	if deadness > LIFE_CYCLE.Alive:
		if airborne:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			move_and_slide()
		elif deadness == LIFE_CYCLE.Dead:
			emit_signal("finished_dying")
			set_process(false)  # Stop processing once the player is dead
		return # Don't process any more
		
	# If we aren't in the air, but we were previously, play the landing animation
	# TODO This currently only lasts one frame, need to handle timing
	if !airborne && jumping:
		set_animation("jump_land")
		jumping = false # No longer jumping
		
	# Handle jump action
	if Input.is_action_just_pressed("ui_accept") and !airborne:
		velocity.y = JUMP_VELOCITY
		set_animation("jump_start")
		$JumpSound.play()
		jumping = true

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("go_left", "go_right")
	# When the shift key is pressed we power up from walking to running
	var running = Input.is_action_pressed("power")
	var mult = RUN_MULTIPLIER if running else 1.0

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
		var collider = get_slide_collision(i).get_collider()
		if (collider is TileMap) && (collider.name == "DeadlyGround"):
			deadness = LIFE_CYCLE.Dying
			set_animation("dead")
		elif !(collider is TileMap):
			print(collider.name)
		# TODO Do something with the collider

# Main tells us when our health changes
func _on_health_changed(value) -> void:
	# If health is 0, we are dying
	if value <= 0:
		deadness = LIFE_CYCLE.Dying
		set_animation("dead")

# Handle changes that occur at end of animations
func _on_sprite_animation_finished() -> void:
	if animation == "jump_start" && jumping:
		set_animation("jump_middle")
		
	if animation == "dead" && deadness == LIFE_CYCLE.Dying:
		deadness = LIFE_CYCLE.Dead
