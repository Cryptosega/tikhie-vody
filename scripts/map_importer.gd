extends Node3D

## Скрипт импорта карты Дедовска из GeoJSON
## Читает файл dedovsk.json и строит дороги как 3D-линии

# Центр Дедовска (относительно него считаем метры)
const CENTER_LAT := 55.865
const CENTER_LON := 37.12

# Масштаб: 1 градус широты ≈ 111320 м
# 1 градус долготы на этой широте ≈ 62450 м
const METERS_PER_LAT := 111320.0
const METERS_PER_LON := 62450.0

# Множитель масштаба карты (чтобы было видно)
const MAP_SCALE := 1.0

# Путь к файлу
const GEOJSON_PATH := "res://data/dedovsk.json"


func _ready() -> void:
	print("🗺 Начинаем импорт карты Дедовска...")
	import_geojson()


func import_geojson() -> void:
	# Читаем файл
	var file := FileAccess.open(GEOJSON_PATH, FileAccess.READ)
	if file == null:
		print("❌ Ошибка: файл не найден по пути ", GEOJSON_PATH)
		return
	
	var json_text := file.get_as_text()
	file.close()
	
	# Парсим JSON
	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		print("❌ Ошибка парсинга JSON: ", json.get_error_message())
		return
	
	var data: Dictionary = json.data
	if not data is Dictionary or not data.has("features"):
		print("❌ Неверный формат GeoJSON")
		return
	
	var features: Array = data["features"]
	print("📊 Найдено объектов: ", features.size())
	
	var roads_count := 0
	var water_count := 0
	
	# Обрабатываем каждый объект
	for feature in features:
		var props: Dictionary = feature.get("properties", {})
		var geom: Dictionary = feature.get("geometry", {})
		var geom_type: String = geom.get("type", "")
		
		# Определяем тип: дорога или вода
		var is_road := props.has("highway")
		var is_water := props.has("natural") or props.has("landuse")
		
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
	var x := (lon - CENTER_LON) * METERS_PER_LON * MAP_SCALE
	var z := (lat - CENTER_LAT) * METERS_PER_LAT * MAP_SCALE
	return Vector3(x, 0.0, z)


## Строит дорогу как линию
func build_road(geom: Dictionary) -> void:
	var geom_type: String = geom.get("type", "")
	var coords = geom.get("coordinates", [])
	
	if geom_type == "LineString":
		draw_line_strip(coords, Color(1.0, 0.95, 0.8, 1.0), 0.8)
	elif geom_type == "MultiLineString":
		for line in coords:
			draw_line_strip(line, Color(0.9, 0.9, 0.9, 1.0), 0.3)


## Строит водоём как плоскость
func build_water(geom: Dictionary) -> void:
	var geom_type: String = geom.get("type", "")
	var coords = geom.get("coordinates", [])
	
	if geom_type == "Polygon":
		# Берём внешний контур (первый массив)
		if coords.size() > 0:
			draw_polygon(coords[0], Color(0.2, 0.4, 0.7, 0.8))
	elif geom_type == "MultiPolygon":
		for polygon in coords:
			if polygon.size() > 0:
				draw_polygon(polygon[0], Color(0.2, 0.4, 0.7, 0.8))


## Рисует линию по массиву координат [lon, lat]
func draw_line_strip(coords: Array, color: Color, width: float) -> void:
	if coords.size() < 2:
		return
	
	var mesh := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.unshaded = true  # чтобы было видно без сложного освещения
	
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(coords.size() - 1):
		var p1: Array = coords[i]
		var p2: Array = coords[i + 1]
		var v1 := geo_to_meters(p1[1], p1[0])
		var v2 := geo_to_meters(p2[1], p2[0])
		# Чуть приподнимаем над землёй
		v1.y = 0.1
		v2.y = 0.1
		mesh.surface_add_vertex(v1)
		mesh.surface_add_vertex(v2)
	
	mesh.surface_end()


## Рисует полигон (водоём)
func draw_polygon(coords: Array, color: Color) -> void:
	if coords.size() < 3:
		return
	
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.unshaded = true
	surface_tool.set_material(mat)
	
	# Конвертируем координаты
	var points: PackedVector3Array = []
	for c in coords:
		var p := geo_to_meters(c[1], c[0])
		p.y = 0.05  # чуть выше земли
		points.append(p)
	
	# Триангуляция веером от первой точки
	for i in range(1, points.size() - 1):
		surface_tool.add_vertex(points[0])
		surface_tool.add_vertex(points[i])
		surface_tool.add_vertex(points[i + 1])
	
	var mesh := surface_tool.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)
