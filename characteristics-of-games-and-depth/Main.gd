extends Node2D

@export var tower_scene: PackedScene
@export var start_gold: int = 30
@export var start_lives: int = 10
@export var world_rect := Rect2(Vector2(0, 0), Vector2(960, 540))

var gold: int
var lives: int

@onready var towers_root: Node2D = $Towers
@onready var ui_hint: Label = $UI/Notifications
@onready var ui_gold: Label = $UI/Gold
@onready var ui_lives: Label = $UI/Lives
@onready var cam: Camera2D = $Camera2D


func _ready() -> void:
	gold = start_gold
	lives = start_lives
	_update_ui()

	for spot in $BuildSpots.get_children():
		spot.clicked.connect(_on_build_spot_clicked)
	
	cam.limit_left = int(world_rect.position.x)
	cam.limit_top = int(world_rect.position.y)
	cam.limit_right = int(world_rect.position.x + world_rect.size.x)
	cam.limit_bottom = int(world_rect.position.y + world_rect.size.y)
	debug_check_path_inside_world()


func _on_build_spot_clicked(spot) -> void:
	if spot.has_tower:
		_hint("There is already a tower here why r u keeping building here?")
		return

	if gold < spot.price:
		_hint("Gold not enough! Need %d" % spot.price)
		return

	if tower_scene == null:
		_hint("Undefined tower_scene")
		return

	gold -= spot.price

	var t = tower_scene.instantiate()
	towers_root.add_child(t)
	t.global_position = spot.global_position

	spot.has_tower = true
	spot.queue_redraw()

	_hint("Built success -%d" % spot.price)
	_update_ui()

func _on_enemy_reached_goal(_enemy) -> void:
	lives -= 1
	_hint("Life -1")
	_update_ui()

	if lives <= 0:
		_hint("Game Over")
		get_tree().paused = true

func _hint(msg: String) -> void:
	ui_hint.text = msg

func _update_ui() -> void:
	ui_gold.text = "Gold: %d" % gold
	ui_lives.text = "Lives: %d" % lives
	
	
func debug_check_path_inside_world() -> void:
	var pts = $Path2D.curve.get_baked_points()
	for p in pts:
		if not world_rect.has_point(p):
			print("Path point outside world: ", p)
