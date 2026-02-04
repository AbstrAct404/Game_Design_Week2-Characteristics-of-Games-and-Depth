extends Node2D
@export var world_rect := Rect2(Vector2(0,0), Vector2(960,540))
@export var bg_color: Color = Color(0.12, 0.12, 0.12)
@export var border_color: Color = Color(0.8, 0.8, 0.8)
@export var border_width: float = 2.0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(world_rect, bg_color, true)
	draw_rect(world_rect, border_color, false, border_width)
