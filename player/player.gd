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

	# Update animation based on camera angle relative to body forward direction
	update_sprite(input_dir)
	
	# Debug node
	if Input.is_action_pressed("0"):
		touch_debug.visible = !touch_debug.visible

	move_and_slide()

	# Head updates headbob independently
	head.update_headbob(delta, velocity.length(), is_on_floor())


func update_sprite(input_dir: Vector2) -> void:
	# Calculate which 8-way sprite angle to show based on camera view position
	var active_camera: Camera3D = head.camera
	if active_camera:
		# 1. Body forward vector on XZ plane
		var body_forward := -global_transform.basis.z
		body_forward.y = 0.0
		body_forward = body_forward.normalized()

		# 2. Vector pointing from Player toward Camera on XZ plane
		var dir_to_camera := active_camera.global_position - global_position
		dir_to_camera.y = 0.0
		dir_to_camera = dir_to_camera.normalized()

		# 3. Angle between body facing direction and camera view (-180 to 180 deg)
		var angle_deg := rad_to_deg(body_forward.signed_angle_to(dir_to_camera, Vector3.UP))

		# 4. Determine 8-way suffix matching your sprite animation naming conventions
		if angle_deg >= -22.5 and angle_deg < 22.5:
			last_direction = "back"
		elif angle_deg >= 22.5 and angle_deg < 67.5:
			last_direction = "back_right"
		elif angle_deg >= 67.5 and angle_deg < 112.5:
			last_direction = "front_right" # Viewed from right side
		elif angle_deg >= 112.5 and angle_deg < 157.5:
			last_direction = "front_right"
		elif angle_deg >= 157.5 or angle_deg < -157.5:
			last_direction = "front"
		elif angle_deg >= -157.5 and angle_deg < -112.5:
			last_direction = "front_left"
		elif angle_deg >= -112.5 and angle_deg < -67.5:
			last_direction = "front_left" # Viewed from left side
		elif angle_deg >= -67.5 and angle_deg < -22.5:
			last_direction = "back_left"

	# --- State and Animation Playback ---

	# Dash state
	if Input.is_action_pressed("dash"):
		jump_played = false
		var dash_anim = "dash_" + last_direction
		if sprite.animation != dash_anim and sprite.sprite_frames.has_animation(dash_anim):
			sprite.play(dash_anim)
		return

	# Airborne / Jump state
	if not is_on_floor():
		if not jump_played:
			jump_played = true
			var jump_anim = "jump_" + last_direction
			if sprite.animation != jump_anim and sprite.sprite_frames.has_animation(jump_anim):
				sprite.play(jump_anim)
		elif not sprite.is_playing():
			var airborne_state = "walk" if input_dir.length() > 0 else "idle"
			var air_anim = airborne_state + "_" + last_direction
			if sprite.animation != air_anim and sprite.sprite_frames.has_animation(air_anim):
				sprite.play(air_anim)
		return

	# Grounded landing / Walk / Idle states
	jump_played = false
	current_state = "walk" if input_dir.length() > 0 else "idle"

	var anim = current_state + "_" + last_direction
	if sprite.animation != anim and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
