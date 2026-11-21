extends SpringArm3D

## Скрипт камеры, которая следует за машиной, но не вращается вместе с ней

var target: Node3D  # ссылка на машину (родитель)


func _ready() -> void:
	# Получаем ссылку на родительский узел (Niva)
	target = get_parent()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	
	# Компенсируем вращение машины
	# Камера всегда смотрит в одном направлении, независимо от поворота машины
	rotation = Vector3(-25, 0, 0)  # фиксированный наклон вниз
