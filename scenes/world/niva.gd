extends CharacterBody3D

## Скрипт вождения Нивы
## WASD — газ/тормоз/поворот, пробел — ручник

# Параметры машины (немного подкрутил для более отзывчивого управления)
const MAX_SPEED := 25.0          # м/с (~90 км/ч)
const ACCELERATION := 12.0       # м/с² (разгон)
const TURN_SPEED := 2.2          # радиан/с (резкость поворота)
const FRICTION := 0.95           # трение (0-1, чем меньше — тем быстрее останавливается)
const DRIFT_FACTOR := 0.8        # фактор заноса на снегу

# Ввод
var steer_input := 0.0
var throttle_input := 0.0

# Текущая скорость
var current_speed := 0.0


func _physics_process(delta: float) -> void:
	# Считываем ввод. 
	# ВАЖНО: минус перед Input.get_axis инвертирует поворот, если машина крутится не туда
	steer_input = -Input.get_axis("ui_left", "ui_right")
	throttle_input = Input.get_axis("ui_down", "ui_up")
	var handbrake := Input.is_action_pressed("ui_select")
	
	# Ускорение / торможение
	if throttle_input != 0.0:
		current_speed += throttle_input * ACCELERATION * delta
	else:
		# Естественное замедление (трение)
		current_speed *= FRICTION
	
	# Ручник (резкое торможение и занос)
	if handbrake:
		current_speed *= 0.9
	
	# Ограничение максимальной скорости (вперёд и назад)
	current_speed = clamp(current_speed, -MAX_SPEED * 0.4, MAX_SPEED)
	
	# Поворот (работает только если машина движется)
	if abs(current_speed) > 0.5:
		var turn_direction := steer_input * TURN_SPEED * delta
		# При движении задним ходом руль крутится в обратную сторону (как в реальной жизни)
		if current_speed < 0:
			turn_direction *= -1
		rotate_y(turn_direction)
	
	# Движение: в Godot "вперёд" для 3D-объектов — это ось -Z (минус зет)
	var direction := -transform.basis.z
	velocity = direction * current_speed
	
	# Простая имитация заноса на снегу при резком повороте на скорости
	if abs(steer_input) > 0.5 and abs(current_speed) > 6.0:
		var drift := Vector3(-transform.basis.x.x, 0, -transform.basis.x.z) * steer_input * DRIFT_FACTOR
		velocity += drift * delta * 10.0
	
	# Применяем физику
	move_and_slide()
	
	# Отладка: нажми Tab (или кнопку, назначенную на ui_focus_next), чтобы увидеть скорость в консоли
	if Input.is_action_just_pressed("ui_focus_next"):
		print("Скорость: ", int(abs(current_speed) * 3.6), " км/ч")
