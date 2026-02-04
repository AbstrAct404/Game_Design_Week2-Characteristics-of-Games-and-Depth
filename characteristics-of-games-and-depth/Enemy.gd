extends CharacterBody2D
@export var max_hp: int = 10
@export var speed: float = 100.0
@export var gold_reward: int = 5  # Gold given on death
var hp: int
var path: Path2D
var progress: float = 0.0
signal reached_goal(enemy)
signal died(enemy)  # Signal when enemy dies
func _ready() -> void:
	hp = max_hp
	queue_redraw()
func setup(p: Path2D) -> void:
	path = p
	progress = 0.0
	global_position = path.curve.sample_baked(progress)
func _physics_process(delta: float) -> void:
	if path == null:
		return
	progress += speed * delta
	var end_len = path.curve.get_baked_length()
	if progress >= end_len:
		emit_signal("reached_goal", self)
		queue_free()
		return
	global_position = path.curve.sample_baked(progress)
func take_damage(dmg: int) -> void:
	hp -= dmg
	if hp <= 0:
		emit_signal("died", self)  # Emit only when dead
		queue_free()
@export var enemy_size: float = 26.0
@export var enemy_color: Color = Color(1.0, 0.35, 0.35)
func _draw() -> void:
	var s = enemy_size
	draw_rect(Rect2(Vector2(-s/2.0, -s/2.0), Vector2(s, s)), enemy_color)
