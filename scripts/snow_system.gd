extends Node3D

## Скрипт создаёт снег из множества маленьких кубиков

const SNOW_COUNT := 1000   # количество снежинок (увеличил)
const SNOW_SIZE := 0.25    # размер каждой снежинки (метров)
const AREA_SIZE := 250.0   # размер области
const FALL_SPEED := 6.0    # скорость падения (м/с)
const MIN_HEIGHT := 0.0    # минимальная высота (земля)
const MAX_HEIGHT := 60.0   # максимальная высота

var snowflakes: Array = []
var snowflake_positions: Array = []


func _ready() -> void:
	print("❄️ Создаю снег из кубиков...")
	create_snow_cubes()


func create_snow_cubes() -> void:
	# Создаём материал для снега (белый, не зависит от света, БЕЗ ТЕНЕЙ)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 1.0)  # белый
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Создаём геометрию (маленький кубик)
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(SNOW_SIZE, SNOW_SIZE, SNOW_SIZE)
	
	# Создаём снежинки
	for i in range(SNOW_COUNT):
		var snowflake := MeshInstance3D.new()
		snowflake.mesh = box_mesh
		snowflake.material_override = material
		
		# ВАЖНО: отключаем тени!
		snowflake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
		# Случайная позиция в области
		var x := randf_range(-AREA_SIZE / 2, AREA_SIZE / 2)
		var y := randf_range(MIN_HEIGHT, MAX_HEIGHT)
		var z := randf_range(-AREA_SIZE / 2, AREA_SIZE / 2)
		
		snowflake.position = Vector3(x, y, z)
		add_child(snowflake)
		
		snowflakes.append(snowflake)
		snowflake_positions.append(Vector3(x, y, z))
	
	print("✅ Снег создан! Количество снежинок: ", SNOW_COUNT)


func _process(delta: float) -> void:
	# Двигаем каждую снежинку вниз
	for i in range(snowflakes.size()):
		var snowflake: MeshInstance3D = snowflakes[i]
		var pos: Vector3 = snowflake_positions[i]
		
		# Двигаем вниз
		pos.y -= FALL_SPEED * delta
		
		# Если достигла земли — возвращаем наверх
		if pos.y < MIN_HEIGHT:
			pos.y = MAX_HEIGHT
			pos.x = randf_range(-AREA_SIZE / 2, AREA_SIZE / 2)
			pos.z = randf_range(-AREA_SIZE / 2, AREA_SIZE / 2)
		
		snowflake.position = pos
		snowflake_positions[i] = pos
