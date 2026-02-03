extends Node2D
@export var fire_interval: float = 0.6
@export var bullet_scene: PackedScene
@export var bullet_damage: int = 1
@export var bullet_speed: float = 800.0  # Add this
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
	if target == null and body is Node2D and body.has_method("take_damage"):
		target = body

func _on_body_exited(body: Node) -> void:
	if body == target:
		target = null

func _on_fire_timer_timeout() -> void:
	if target == null or not is_instance_valid(target):
		target = null
		return
	if bullet_scene == null:
		return
	var b = bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = global_position
	b.damage = bullet_damage
	b.speed = bullet_speed  # Set the speed
	b.dir = (target.global_position - global_position).normalized()
