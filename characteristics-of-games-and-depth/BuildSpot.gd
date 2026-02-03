extends Area2D

@export var price: int = 10
@export var built_color: Color = Color(0.3, 0.9, 0.3)
@export var empty_color: Color = Color(0.7, 0.7, 0.7)
@export var radius: float = 18.0

var has_tower := false

signal clicked(spot)

func _ready() -> void:
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, (built_color if has_tower else empty_color))

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("clicked", self)

func _on_mouse_entered() -> void:
	pass

func _on_mouse_exited() -> void:
	pass
