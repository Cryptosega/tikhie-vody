extends CharacterBody3D

## Нива с фарами (SpotLight + визуальный конус) и камерой
## WASD — газ/тормоз/поворот, пробел — ручник

# === Параметры машины ===
const MAX_SPEED := 25.0
const ACCELERATION := 12.0
const TURN_SPEED := 2.2
const FRICTION := 0.95
const DRIFT_FACTOR := 0.8

# === Параметры фар ===
const HEADLIGHT_COLOR := Color(1.0, 0.85, 0.6, 1.0)
const HEADLIGHT_ENERGY := 40.0
const HEADLIGHT_ANGLE := 35.0
const HEADLIGHT_RANGE := 40.0
const HEADLIGHT_ATTENUATION := 1.2

# === Ввод ===
var steer_input := 0.0
var throttle_input := 0.0
var current_speed := 0.0

# === Ссылки ===
var follow_cam: Camera3D


func _ready() -> void:
	print("🚗 Нива готова к поездке!")
	create_headlights()
	create_camera()


func _physics_process(delta: float) -> void:
	steer_input = -Input.get_axis("ui_left", "ui_right")
	throttle_input = Input.get_axis("ui_down", "ui_up")
	var handbrake := Input.is_action_pressed("ui_select")
	
	if throttle_input != 0.0:
		current_speed += throttle_input * ACCELERATION * delta
	else:
		current_speed *= FRICTION
	
	if handbrake:
		current_speed *= 0.9
	
	current_speed = clamp(current_speed, -MAX_SPEED * 0.4, MAX_SPEED)
	
	if abs(current_speed) > 0.5:
		var turn_direction := steer_input * TURN_SPEED * delta
		if current_speed < 0:
			turn_direction *= -1
		rotate_y(turn_direction)
	
	var direction := -transform.basis.z
	velocity = direction * current_speed
	
	if abs(steer_input) > 0.5 and abs(current_speed) > 6.0:
		var drift := Vector3(-transform.basis.x.x, 0, -transform.basis.x.z) * steer_input * DRIFT_FACTOR
		velocity += drift * delta * 10.0
	
	move_and_slide()
	
	update_camera()


## Создаёт фары с визуальным конусом света
func create_headlights() -> void:
	# === ЛЕВАЯ ФАРА ===
	var hl := SpotLight3D.new()
	hl.name = "Headlight_L"
	hl.position = Vector3(-0.7, 0.4, -2.0)
	# SpotLight3D светит в -Z локально — это вперёд для машины
	hl.rotation = Vector3.ZERO
	hl.light_color = HEADLIGHT_COLOR
	hl.light_energy = HEADLIGHT_ENERGY
	hl.spot_angle = HEADLIGHT_ANGLE
	hl.spot_range = HEADLIGHT_RANGE
	hl.spot_attenuation = HEADLIGHT_ATTENUATION
	hl.shadow_enabled = false
	add_child(hl)
	
	# Визуальный конус света (полупрозрачный)
	var cone_l := MeshInstance3D.new()
	cone_l.name = "Cone_L"
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.3
	cone_mesh.bottom_radius = 4.0
	cone_mesh.height = 15.0
	cone_mesh.radial_segments = 8
	cone_l.mesh = cone_mesh
	
	var cone_mat := StandardMaterial3D.new()
	cone_mat.albedo_color = Color(1.0, 0.9, 0.7, 0.15)  # полупрозрачный
	cone_mat.emission_enabled = true
	cone_mat.emission = Color(1.0, 0.9, 0.7, 0.3)
	cone_mat.emission_energy_multiplier = 2.0
	cone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cone_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	cone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone_l.material_override = cone_mat
	
	# Позиция конуса: спереди машины, повёрнут горизонтально
	cone_l.position = Vector3(-0.7, 0.4, -9.5)  # центр конуса
	cone_l.rotation_degrees = Vector3(90, 0, 0)  # лежит горизонтально
	add_child(cone_l)
	
	# === ПРАВАЯ ФАРА ===
	var hr := SpotLight3D.new()
	hr.name = "Headlight_R"
	hr.position = Vector3(0.7, 0.4, -2.0)
	hr.rotation = Vector3.ZERO
	hr.light_color = HEADLIGHT_COLOR
	hr.light_energy = HEADLIGHT_ENERGY
	hr.spot_angle = HEADLIGHT_ANGLE
	hr.spot_range = HEADLIGHT_RANGE
	hr.spot_attenuation = HEADLIGHT_ATTENUATION
	hr.shadow_enabled = false
	add_child(hr)
	
	# Визуальный конус света
	var cone_r := MeshInstance3D.new()
	cone_r.name = "Cone_R"
	var cone_mesh_r := CylinderMesh.new()
	cone_mesh_r.top_radius = 0.3
	cone_mesh_r.bottom_radius = 4.0
	cone_mesh_r.height = 15.0
	cone_mesh_r.radial_segments = 8
	cone_r.mesh = cone_mesh_r
	cone_r.material_override = cone_mat
	
	cone_r.position = Vector3(0.7, 0.4, -9.5)
	cone_r.rotation_degrees = Vector3(90, 0, 0)
	add_child(cone_r)
	
	# Светящиеся маркеры (лампочки)
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.8, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.7, 1.0)
	mat.emission_energy_multiplier = 5.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var ml := MeshInstance3D.new()
	ml.mesh = sphere
	ml.material_override = mat
	ml.position = Vector3(-0.7, 0.4, -2.0)
	add_child(ml)
	
	var mr := MeshInstance3D.new()
	mr.mesh = sphere
	mr.material_override = mat
	mr.position = Vector3(0.7, 0.4, -2.0)
	add_child(mr)
	
	print("💡 Фары с конусами света созданы!")


## Камера сзади-сверху
func create_camera() -> void:
	follow_cam = Camera3D.new()
	follow_cam.name = "FollowCam"
	follow_cam.current = true
	follow_cam.fov = 60.0
	follow_cam.far = 2000.0
	add_child(follow_cam)
	print("📷 Камера создана!")


func update_camera() -> void:
	if follow_cam == null:
		return
	
	# Камера сзади машины
	var back_dir := global_transform.basis.z
	var up := Vector3(0, 1, 0)
	
	var cam_pos := global_position + back_dir * 12 + up * 8
	follow_cam.global_position = cam_pos
	
	var look_target := global_position + Vector3(0, 1, 0)
	follow_cam.look_at(look_target, up)
