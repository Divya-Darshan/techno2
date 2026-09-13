extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 5.0

var jump_played := false

# Player nodes
@onready var sprite: AnimatedSprite3D = $sprite
@onready var head: Node3D = $head
@onready var touch_debug: ColorRect = $CanvasLayer/CameraTouch/Touch_debug

# Animation
var last_direction := "front"
var current_state := "idle"

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	sprite.play("idle_front")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_played = false

	# Movement
	var input_dir := Input.get_vector("a", "d", "w", "s")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if direction != Vector3.ZERO:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 2.0)

	# Update animation
	update_sprite(input_dir)
	
	# Debug node
	if Input.is_action_pressed("0"):
		touch_debug.visible = !touch_debug.visible

	move_and_slide()

	# Head updates headbob independently
	head.update_headbob(delta, velocity.length(), is_on_floor())


func update_sprite(input_dir: Vector2):

	# Remember the last direction
	if input_dir.length() > 0:

		if input_dir.y > 0:
			if input_dir.x < 0:
				last_direction = "back_left"
			elif input_dir.x > 0:
				last_direction = "back_right"
			else:
				last_direction = "back"

		elif input_dir.y < 0:
			if input_dir.x < 0:
				last_direction = "front_left"
			elif input_dir.x > 0:
				last_direction = "front_right"
			else:
				last_direction = "front"

		elif input_dir.x < 0:
			last_direction = "front_left"

		elif input_dir.x > 0:
			last_direction = "front_right"


	# dash
	if Input.is_action_pressed("dash"):

		jump_played = false

		var anim = "dash_" + last_direction

		if sprite.animation != anim:
			sprite.play(anim)

		return

	if not is_on_floor():

		if !jump_played:

			jump_played = true

			var anim = "jump_" + last_direction

			if sprite.animation != anim:
				sprite.play(anim)

		# Jump animation finished?
		elif !sprite.is_playing():

			if input_dir.length() > 0:

				var anim = "walk_" + last_direction

				if sprite.animation != anim:
					sprite.play(anim)

			else:

				var anim = "idle_" + last_direction

				if sprite.animation != anim:
					sprite.play(anim)

		return


	# Reset when landing
	jump_played = false

	if input_dir.length() > 0:
		current_state = "walk"
	else:
		current_state = "idle"

	var anim = current_state + "_" + last_direction

	if sprite.animation != anim:
		sprite.play(anim)
