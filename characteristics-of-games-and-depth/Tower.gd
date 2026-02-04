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

func _ready() -> void:
	queue_redraw()
	fire_timer.wait_time = fire_interval
	fire_timer.autostart = true
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)

func _draw() -> void:
	draw_circle(Vector2.ZERO, tower_radius, tower_color)

func _on_body_entered(body: Node) -> void:
	print("Body entered range: ", body.name, " Type: ", body.get_class())
	print("Has take_damage method: ", body.has_method("take_damage"))  # NEW DEBUG LINE
	print("Script: ", body.get_script())  # NEW DEBUG LINE
	
	if target == null and body is Node2D and body.has_method("take_damage"):
		target = body
		print("Tower locked onto: ", body.name)
	else:
		print("Body not valid target - target is null: ", (target == null), " is Node2D: ", (body is Node2D), " has method: ", body.has_method("take_damage"))

func _on_body_exited(body: Node) -> void:
	print("Body exited range: ", body.name)
	if body == target:
		target = null
		print("Target cleared")

func _on_fire_timer_timeout() -> void:
	if target == null or not is_instance_valid(target):
		target = null
		return
	if bullet_scene == null:
		print("No bullet scene assigned!")
		return
	
	print("Tower firing at: ", target.name)
	var bullet = bullet_scene.instantiate()
	
	if bullet == null:
		print("Failed to instantiate bullet!")
		return
	
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	
	if bullet.has_method("set"):
		bullet.set("damage", bullet_damage)
		bullet.set("speed", bullet_speed)
		bullet.set("dir", (target.global_position - global_position).normalized())
	else:
		bullet.damage = bullet_damage
		bullet.speed = bullet_speed
		bullet.dir = (target.global_position - global_position).normalized()
	
	print("Bullet fired with damage: ", bullet_damage, " and speed: ", bullet_speed)
