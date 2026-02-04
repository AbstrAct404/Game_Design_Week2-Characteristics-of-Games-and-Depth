extends CharacterBody2D
@export var max_hp: int = 50
@export var speed: float = 120.0
@export var gold_reward: int = 25
var hp: int
var path: Path2D
var progress: float = 0.0
signal reached_goal(enemy)
signal died(enemy)
func _ready() -> void:
	name = "Boss"
	hp = max_hp
	print("Boss spawned with HP: ", hp, " at position: ", global_position)
	queue_redraw()
func setup(p: Path2D) -> void:
	path = p
	progress = 0.0
	global_position = path.curve.sample_baked(progress)
	print("Boss setup complete at position: ", global_position)
func _physics_process(delta: float) -> void:
	if path == null:
		return
	progress += speed * delta
	var end_len = path.curve.get_baked_length()
	
	# Add debug every second
	if int(progress) % 100 == 0:
		print("Boss at progress: ", progress, " position: ", global_position)
	
	if progress >= end_len:
		print("Boss reached goal!")
		emit_signal("reached_goal", self)
		queue_free()
		return
	global_position = path.curve.sample_baked(progress)
func take_damage(dmg: int) -> void:
	hp -= dmg
	print("Boss took %d damage! HP: %d / %d" % [dmg, hp, max_hp])
	if hp <= 0:
		print("Boss defeated!")
		emit_signal("died", self)
		queue_free()
@export var enemy_size: float = 40.0
@export var enemy_color: Color = Color(0.8, 0.1, 0.8)
func _draw() -> void:
	var s = enemy_size
	draw_rect(Rect2(Vector2(-s/2.0, -s/2.0), Vector2(s, s)), enemy_color)
