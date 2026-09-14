extends Node3D

const CAMERA_SENSE = 0.10

# Camera shake
const BOB_FREQ = 2.0
const BOB_AMP = 0.07
var t_bob = 0.0
var camera_base_pos: Vector3

@export var camera_markers: Array[Marker3D] = []
var current_index = 0
var is_transitioning := false

# Pitch limits in degrees for First Person (Index 0)
@export_group("1st Person Pitch Limits")
@export var fp_min_pitch: float = -15.0
@export var fp_max_pitch: float = 10.0

# Pitch limits in degrees for Third Person (Index 1)
@export_group("3rd Person Pitch Limits")
@export var tp_min_pitch: float = -5.0  # Restricts looking too far down so you don't see under sprites
@export var tp_max_pitch: float = 12.0

# Node references relative to Head
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var camera_touch: Control = $"../CanvasLayer/CameraTouch"
@onready var sprite: AnimatedSprite3D = $"../sprite"


func _ready() -> void:
	if camera_touch:
		camera_touch.look.connect(_on_camera_look)
	camera_base_pos = camera.transform.origin


func _on_camera_look(delta: Vector2) -> void:
	rotate_y(-delta.x * CAMERA_SENSE)
	camera_pivot.rotate_x(-delta.y * CAMERA_SENSE)

	_apply_pitch_clamp()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event.is_action_pressed("cam"):
		_switch_to_next_camera()

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * CAMERA_SENSE)
		camera_pivot.rotate_x(-event.relative.y * CAMERA_SENSE)
		
		_apply_pitch_clamp()


func _apply_pitch_clamp() -> void:
	var min_deg: float
	var max_deg: float

	# Assign different pitch limits depending on the active camera view
	if current_index == 0:
		min_deg = fp_min_pitch
		max_deg = fp_max_pitch
	else:
		min_deg = tp_min_pitch
		max_deg = tp_max_pitch

	camera_pivot.rotation.x = clamp(
		camera_pivot.rotation.x,
		deg_to_rad(min_deg),
		deg_to_rad(max_deg)
	)


func _switch_to_next_camera() -> void:
	if camera_markers.size() < 2 or is_transitioning:
		return

	is_transitioning = true
	current_index = (current_index + 1) % camera_markers.size()
	var target_marker = camera_markers[current_index]

	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Smoothly tween camera position to target marker
	tween.tween_property(camera, "transform", target_marker.transform, 0.45)

	# Wait until the 0.45s camera transition animation is fully finished
	await tween.finished

	is_transitioning = false
	camera_base_pos = camera.transform.origin

	# Toggle sprite visibility once we land in First Person (index 0)
	if current_index == 0:
		sprite.visible = false
	else:
		sprite.visible = true


func _on_button_pressed() -> void:
	_switch_to_next_camera()


func update_headbob(delta: float, speed: float, is_on_floor: bool) -> void:
	if is_transitioning:
		return

	t_bob += delta * speed * float(is_on_floor)
	camera.transform.origin = camera_base_pos + _headbob(t_bob)


func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2.0) * BOB_AMP
	return pos
