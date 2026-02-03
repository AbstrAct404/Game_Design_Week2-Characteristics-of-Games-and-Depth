extends Area2D
@export var speed: float = 1200.0  # Increased from 600.0 to 1200.0
@export var damage: int = 1
@export var bullet_radius: float = 6.0
@export var bullet_color: Color = Color(1.0, 0.95, 0.2) # 黄色系
var dir: Vector2 = Vector2.RIGHT
func _ready() -> void:
	queue_redraw()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
func _draw() -> void:
	draw_circle(Vector2.ZERO, bullet_radius, bullet_color)
func _physics_process(delta: float) -> void:
	global_position += dir * speed * delta
func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
