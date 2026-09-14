extends AnimatedSprite3D

@export var rotation_speed: float = 2.0

# Exact transform values copied from your manual placement Inspector
@export var hold_offset: Vector3 = Vector3(0.552, 1.467, -1.11)
@export var hold_rotation_degrees: Vector3 = Vector3(0.0, 94.5, 3.0)
@export var hold_scale: Vector3 = Vector3(2.83, 2.83, 2.83)

@onready var shoot: AnimatedSprite3D = $shoot
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var is_on_main: bool = false
var player_in_range: bool = false
var player_ref: Node3D = null


func _ready() -> void:
	canvas_layer.visible = false
	
	if get_parent() and get_parent().name == "Main":
		is_on_main = true
	else:
		is_on_main = false


func _process(delta: float) -> void:
	# Continuous rotation when sitting on the ground in Main world
	if is_on_main:
		rotate_y(rotation_speed * delta)

	# Firing/shooting animation logic
	if Input.is_action_pressed("inter"):
		play("shoot")
		shoot.visible = true
	else:
		play("default")
		shoot.visible = false

	# Pick up item input check
	if is_on_main and player_in_range and Input.is_action_just_pressed("pick"):
		_pick_up_item()


func _on_area_3d_body_entered(body: Node3D) -> void:
	# Ignore trigger areas once picked up
	if not is_on_main:
		return

	if body.name == "player" or body.is_in_group("player"):
		player_in_range = true
		player_ref = body
		canvas_layer.visible = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if not is_on_main:
		return

	if body.name == "player" or body.is_in_group("player"):
		player_in_range = false
		player_ref = null
		canvas_layer.visible = false


func _pick_up_item() -> void:
	if not player_ref:
		return

	var hold_node = player_ref.get_node_or_null("head/hold")
	if not hold_node:
		return

	# Check if player is already holding a weapon
	if hold_node.get_child_count() > 0:
		for current_weapon in hold_node.get_children():
			# Check if the existing weapon is the same type (by scene path or base name)
			if current_weapon.scene_file_path == scene_file_path or current_weapon.name.begins_with("minigun"):
				print("Player already has a minigun, rm duplicate.")
				queue_free()
				return
			else:
				# Optional: Drop or destroy the old weapon if picking up a completely different gun type
				current_weapon.queue_free()

	# Disable floor mode and hide pickup UI permanently
	canvas_layer.visible = false
	is_on_main = false
	player_in_range = false

	# Reparent to hold node
	reparent(hold_node, false)
	
	# Apply exact transform
	position = hold_offset
	rotation_degrees = hold_rotation_degrees
	scale = hold_scale
	print("equipped minigun")
