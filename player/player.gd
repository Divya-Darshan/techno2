extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 10.0
const CAMERA_SENSE = 0.001

# camera shake
const BOB_FREQ = 2.0
const BOB_AMP = 0.07
var t_bob = 0.0 
var camera_base_pos: Vector3

# player's sub nodes
@onready var Head: Node3D = $"."
@onready var camera: Camera3D = $Camera3D
@onready var sprite_3d: AnimatedSprite3D = $Sprite3D

func player():
	pass


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_base_pos = camera.transform.origin  # store original position


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
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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
		velocity.x = lerp(velocity.x,direction.x * SPEED, delta * 2.0 )
		velocity.z = lerp(velocity.z,direction.z * SPEED, delta * 2.0 )
		

	# headbob
	t_bob += delta * velocity.length() * float(is_on_floor())
	var bob_offset = _headbob(t_bob)

	# apply bobbing ON TOP of original position
	camera.transform.origin = camera_base_pos + bob_offset
	
	# sprite animation
	if input_dir.length() > 0:
		if sprite_3d.animation != "walk":
			sprite_3d.play("walk")
	else:
		if sprite_3d.animation != "idle":
			sprite_3d.play("idle")

	# flip sprite left/right
	if input_dir.x < 0:
		sprite_3d.flip_h = false
	elif input_dir.x > 0:
		sprite_3d.flip_h = true
		
	update_sprite(input_dir)

	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func update_sprite(input_dir: Vector2):
	if input_dir.length() > 0:
		sprite_3d.play("walk")
	else:
		sprite_3d.play("idle")

	if input_dir.x < 0:
		sprite_3d.flip_h = false
	elif input_dir.x > 0:
		sprite_3d.flip_h = true
