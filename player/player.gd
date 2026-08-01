extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 4.5
const CAMERA_SENSE = 0.10

# Camera shake
const BOB_FREQ = 2.0
const BOB_AMP = 0.07
var t_bob = 0.0
var camera_base_pos: Vector3
var press_count := 0

# Player nodes
@onready var sprite: AnimatedSprite3D = $sprite
@onready var Head: Node3D = $"."
@onready var camera: Camera3D = $Camera3D
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

	camera.rotation.x = clamp(
		camera.rotation.x,
		deg_to_rad(-60),
		deg_to_rad(80)
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Head.rotate_y(-event.relative.x * CAMERA_SENSE)
		camera.rotate_x(-event.relative.y * CAMERA_SENSE)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(100))


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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
		press_count += 1

		if press_count == 3:
			touch_debug.visible = true

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

	# Animation priority
	if Input.is_action_pressed("dash"):
		current_state = "dash"

	elif not is_on_floor():
		current_state = "jump"

	elif input_dir.length() > 0:
		current_state = "walk"

	else:
		current_state = "idle"

	var animation_name = current_state + "_" + last_direction

	if sprite.animation != animation_name:
		sprite.play(animation_name)
