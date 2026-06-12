extends Node3D

@onready var marker_3d: Marker3D = $Marker3D

@export var bullet_texture: Texture2D
@export var bullet_speed := 20.0
@export var shoot_interval := 0.2

var timer := 0.0
var bullets = []

func _process(delta):
	timer += delta

	if timer >= shoot_interval:
		timer = 0.0
		spawn_bullet()

	# Move bullets
	for bullet_data in bullets:
		bullet_data.sprite.global_position += bullet_data.velocity * delta

func spawn_bullet():
	var bullet = Sprite3D.new()

	bullet.texture = bullet_texture
	bullet.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bullet.pixel_size = 0.003

	get_tree().current_scene.add_child(bullet)

	bullet.global_position = marker_3d.global_position

	var velocity = Vector3.RIGHT * bullet_speed
	# If you want local X direction instead:
	# var velocity = marker_3d.global_transform.basis.x * bullet_speed

	bullets.append({
		"sprite": bullet,
		"velocity": velocity
	})
