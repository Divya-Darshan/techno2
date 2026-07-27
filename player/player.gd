extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 4.5
const CAMERA_SENSE = 0.001

# Camera shake
const BOB_FREQ = 2.0
const BOB_AMP = 0.07
var t_bob = 0.0
var camera_base_pos: Vector3

# Player nodes
@onready var idle: AnimatedSprite3D = $Sprite/idle
@onready var walk: AnimatedSprite3D = $Sprite/walk
@onready var Head: Node3D = $"."
@onready var camera: Camera3D = $Camera3D

# Last direction
var last_direction := "front"

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_base_pos = camera.transform.origin

	idle.visible = true
	walk.visible = false
	idle.play("front")


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

	move_and_slide()


func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2.0) * BOB_AMP
	return pos


func show_sprite(sprite: AnimatedSprite3D):
	idle.visible = false
	walk.visible = false
	sprite.visible = true


func update_sprite(input_dir: Vector2):

	# Remember last direction
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

		show_sprite(walk)
		walk.play(last_direction)

	else:
		show_sprite(idle)
		idle.play(last_direction)
