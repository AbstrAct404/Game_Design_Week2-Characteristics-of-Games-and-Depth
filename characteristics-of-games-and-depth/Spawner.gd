extends Node

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.2
@export var enemies_per_wave: int = 10

@onready var main = get_tree().current_scene
@onready var path: Path2D = main.get_node("Path2D")
@onready var enemies_root: Node2D = main.get_node("Enemies")

var timer := 0.0
var spawned := 0

func _process(delta: float) -> void:
	if enemy_scene == null:
		return

	timer += delta
	if timer < spawn_interval:
		return
	timer = 0.0

	if spawned >= enemies_per_wave:
		return

	var e = enemy_scene.instantiate()
	enemies_root.add_child(e)
	e.setup(path)
	e.reached_goal.connect(main._on_enemy_reached_goal)

	spawned += 1
