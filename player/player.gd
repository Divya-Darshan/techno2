extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 5.0
const CAMERA_SENSE = 0.10

# Camera shake
const BOB_FREQ = 2.0
const BOB_AMP = 0.07
var t_bob = 0.0
var camera_base_pos: Vector3
var jump_played := false

#exports please finish is me 😒 next day
@export var cameras : Array[Camera3D]=[]
var current_index=0

# Player nodes
@onready var sprite: AnimatedSprite3D = $sprite
@onready var Head: Node3D = $"."
@onready var camera: Camera3D = $Camera_1
@onready var camera_touch: Control = $CanvasLayer/CameraTouch
@onready var touch_debug: ColorRect = $CanvasLayer/CameraTouch/Touch_debug

# Animation
var last_direction := "front"
var current_state := "idle"

func _ready() -> void:
	camera_touch.look.connect(_on_camera_look)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_base_pos = camera.transform.origin
	sprite.play("idle_front")
	


func _on_camera_look(delta: Vector2):
	print(delta)
	Head.rotate_y(-delta.x * CAMERA_SENSE)

	camera.rotate_x(-delta.y * CAMERA_SENSE)

	# Restrict pitch angle: look down up to -20deg, look up up to 30deg
	camera.rotation.x = clamp(
		camera.rotation.x,
		deg_to_rad(-25),
		deg_to_rad(20)
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Head.rotate_y(-event.relative.x * CAMERA_SENSE)
		camera.rotate_x(-event.relative.y * CAMERA_SENSE)
		# Restrict pitch angle: keep values identical to _on_camera_look
		camera.rotation.x = clamp(
			camera.rotation.x,
			deg_to_rad(-20),
			deg_to_rad(30)
		)

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
	var direction := (Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

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

	# Headbob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = camera_base_pos + _headbob(t_bob)

	# Update animation
	update_sprite(input_dir)
	
	# Debug node
	if Input.is_action_pressed("0"):
			touch_debug.visible = !touch_debug.visible

	move_and_slide()


func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2.0) * BOB_AMP
	return pos

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


	#dash
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
