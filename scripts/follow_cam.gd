extends Camera3D

var car: CharacterBody3D


func _ready() -> void:
	car = get_parent().get_parent()  # Camera3D → CameraArm → Niva


func _physics_process(delta: float) -> void:
	if car == null:
		return
	
	# Камера следует за машиной
	var parent = get_parent()  # CameraArm
	parent.global_position = car.global_position + Vector3(0, 8, 12)
	
	# Фиксированный поворот
	parent.rotation_degrees = Vector3(-30, 0, 0)
