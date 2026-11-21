extends Node3D

## Скрипт импорта карты Дедовска из GeoJSON
## Читает файл dedovsk.json и строит дороги как 3D-линии,
## а водоёмы как плоскости.

# Центр Дедовска (относительно него считаем метры)
const CENTER_LAT: float = 55.865
const CENTER_LON: float = 37.115

# Масштаб: 1 градус широты ≈ 111320 м
# 1 градус долготы на этой широте ≈ 62450 м
const METERS_PER_LAT: float = 111320.0
const METERS_PER_LON: float = 62450.0

# Множитель масштаба карты
const MAP_SCALE: float = 1.0

# Путь к файлу
const GEOJSON_PATH: String = "res://data/dedovsk.json"

# Цвета
const ROAD_COLOR: Color = Color(1.0, 0.75, 0.3, 1.0)
const WATER_COLOR: Color = Color(0.05, 0.1, 0.3, 0.95)

# Ширина дорог (в метрах)
const ROAD_WIDTH: float = 1.5


func _ready() -> void:
	print("🗺 Начинаем импорт карты Дедовска...")
	import_geojson()


func import_geojson() -> void:
	# Читаем файл
	var file: FileAccess = FileAccess.open(GEOJSON_PATH, FileAccess.READ)
	if file == null:
		print("❌ Ошибка: файл не найден по пути ", GEOJSON_PATH)
		return
	
	var json_text: String = file.get_as_text()
	file.close()
	
	# Парсим JSON
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_text)
	if error != OK:
		print("❌ Ошибка парсинга JSON: ", json.get_error_message())
		return
	
	var data: Dictionary = json.data
	if not data.has("features"):
		print("❌ Неверный формат GeoJSON")
		return
	
	var features: Array = data["features"]
	print("📊 Найдено объектов: ", features.size())
	
	var roads_count: int = 0
	var water_count: int = 0
	
	# Обрабатываем каждый объект
	for feature in features:
		var props: Dictionary = feature.get("properties", {})
		var geom: Dictionary = feature.get("geometry", {})
		var geom_type: String = geom.get("type", "")
		
		# Определяем тип: дорога или вода
		var is_road: bool = props.has("highway")
		var is_water: bool = props.has("natural") or props.has("landuse")
		
		if is_road:
			build_road(geom)
			roads_count += 1
		elif is_water:
			build_water(geom)
			water_count += 1
	
	print("✅ Импорт завершён!")
	print("   🛣 Дорог: ", roads_count)
	print("   💧 Водоёмов: ", water_count)


## Преобразует lat/lon в метры относительно центра
func geo_to_meters(lat: float, lon: float) -> Vector3:
	var x: float = (lon - CENTER_LON) * METERS_PER_LON * MAP_SCALE
	var z: float = (lat - CENTER_LAT) * METERS_PER_LAT * MAP_SCALE
	return Vector3(x, 0.0, z)


## Строит дорогу как линию
func build_road(geom: Dictionary) -> void:
	var geom_type: String = geom.get("type", "")
	var coords: Array = geom.get("coordinates", [])
	
	if geom_type == "LineString":
		draw_line_strip(coords, ROAD_COLOR, ROAD_WIDTH)
	elif geom_type == "MultiLineString":
		for line in coords:
			draw_line_strip(line, ROAD_COLOR, ROAD_WIDTH)


## Строит водоём как плоскость
func build_water(geom: Dictionary) -> void:
	var geom_type: String = geom.get("type", "")
	var coords: Array = geom.get("coordinates", [])
	
	if geom_type == "Polygon":
		if coords.size() > 0:
			draw_polygon(coords[0], WATER_COLOR)
	elif geom_type == "MultiPolygon":
		for polygon in coords:
			if polygon.size() > 0:
				draw_polygon(polygon[0], WATER_COLOR)


## Рисует линию по массиву координат [lon, lat]
func draw_line_strip(coords: Array, color: Color, width: float) -> void:
	if coords.size() < 2:
		return
	
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	# Рисуем каждый сегмент как отдельную линию
	for i in range(coords.size() - 1):
		var p1: Array = coords[i]
		var p2: Array = coords[i + 1]
		var v1: Vector3 = geo_to_meters(float(p1[1]), float(p1[0]))
		var v2: Vector3 = geo_to_meters(float(p2[1]), float(p2[0]))
		v1.y = 0.2
		v2.y = 0.2
		surface_tool.add_vertex(v1)
		surface_tool.add_vertex(v2)
	
	var mesh: Mesh = surface_tool.commit()
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	
	# Применяем материал напрямую к MeshInstance3D
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.unshaded = true
	mi.material_override = mat
	
	add_child(mi)


## Рисует полигон (водоём)
func draw_polygon(coords: Array, color: Color) -> void:
	if coords.size() < 3:
		return
	
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Конвертируем координаты
	var points: PackedVector3Array = PackedVector3Array()
	for c in coords:
		var p: Vector3 = geo_to_meters(float(c[1]), float(c[0]))
		p.y = 0.05  # чуть выше земли
		points.append(p)
	
	# Триангуляция веером от первой точки
	for i in range(1, points.size() - 1):
		surface_tool.add_vertex(points[0])
		surface_tool.add_vertex(points[i])
		surface_tool.add_vertex(points[i + 1])
	
	var mesh: Mesh = surface_tool.commit()
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	
	# Применяем материал напрямую к MeshInstance3D
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.unshaded = true
	mi.material_override = mat
	
	add_child(mi)
