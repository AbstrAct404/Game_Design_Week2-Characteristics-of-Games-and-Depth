extends Node2D

@export var fire_interval: float = 0.6
@export var bullet_scene: PackedScene
@export var bullet_damage: int = 1
@export var bullet_speed: float = 800.0
@export var tower_radius: float = 16.0
@export var tower_color: Color = Color(0.2, 0.8, 1.0)

@onready var range_area: Area2D = $Range
@onready var fire_timer: Timer = $FireTimer

var target: Node2D = null
var enemies_in_range: Array[Node2D] = []
var _base_fire_interval: float = 0.0


func _ready() -> void:
	queue_redraw()
	fire_timer.wait_time = fire_interval
	_base_fire_interval = fire_timer.wait_time
	fire_timer.autostart = true
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)


func _draw() -> void:
	draw_circle(Vector2.ZERO, tower_radius, tower_color)


func _is_valid_enemy(body: Node) -> bool:
	return (body is Node2D) and body.has_method("take_damage")


func _on_body_entered(body: Node) -> void:
	if not _is_valid_enemy(body):
		return

	var e := body as Node2D
	if enemies_in_range.has(e) == false:
		enemies_in_range.append(e)


func _on_body_exited(body: Node) -> void:
	if not (body is Node2D):
		return

	var e := body as Node2D
	if enemies_in_range.has(e):
		enemies_in_range.erase(e)

	if e == target:
		target = null


func _pick_target() -> void:
	for i in range(enemies_in_range.size() - 1, -1, -1):
		var e = enemies_in_range[i]
		if e == null or not is_instance_valid(e):
			enemies_in_range.remove_at(i)

	if enemies_in_range.is_empty():
		target = null
		return
	
	var best: Node2D = null
	var best_p: float = -1.0

	for e in enemies_in_range:
		if e == null or not is_instance_valid(e):
			continue

		var p: float = 0.0
		if e.has_method("get_progress"):
			p = float(e.call("get_progress"))
		else:
			p = float(e.get("progress"))

		if best == null or p > best_p:
			best = e
			best_p = p

	target = best


func _on_fire_timer_timeout() -> void:
	_pick_target()
	if target == null or not is_instance_valid(target):
		target = null
		return
	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate()
	if bullet == null:
		return

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position

	var d = (target.global_position - global_position).normalized()
	if bullet.has_method("set"):
		bullet.set("damage", bullet_damage)
		bullet.set("speed", bullet_speed)
		bullet.set("dir", d)
	else:
		bullet.damage = bullet_damage
		bullet.speed = bullet_speed
		bullet.dir = d
		
func set_attack_speed_multiplier(mult: float) -> void:
	if mult <= 0.0:
		mult = 1.0
	fire_timer.wait_time = _base_fire_interval / mult
