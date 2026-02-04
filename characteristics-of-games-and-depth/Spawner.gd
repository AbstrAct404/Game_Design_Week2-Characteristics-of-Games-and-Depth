extends Node
@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var enemies_per_normal_wave: int = 5
@export var normal_waves_before_boss: int = 5
@export var boss_cycles: int = 3
@export var spawn_interval: float = 1.2
@export var wave_delay: float = 1.5

@onready var main = get_tree().current_scene
@onready var path: Path2D = main.get_node("Path2D")
@onready var enemies_root: Node2D = main.get_node("Enemies")

var current_wave: int = 0
var current_cycle: int = 0
var spawned_in_wave: int = 0
var is_spawning: bool = false
var spawn_timer: float = 0.0
var wave_delay_timer: float = 0.0
var waiting_for_next_wave: bool = false
var all_spawned: bool = false
var waiting_for_wave_clear: bool = false
var enemies_alive_in_wave: int = 0

signal all_waves_completed

func _ready() -> void:
	_start_next_wave()

func _process(delta: float) -> void:
	# Handle delay between waves
	if waiting_for_next_wave:
		wave_delay_timer += delta
		if wave_delay_timer >= wave_delay:
			print("Delay complete, starting next wave")
			waiting_for_next_wave = false
			wave_delay_timer = 0.0
			_start_next_wave()
		return
	
	# Check if we're waiting for enemies to be cleared
	if waiting_for_wave_clear:
		if enemies_alive_in_wave <= 0:
			print("Wave cleared! All %d enemies from wave are gone" % spawned_in_wave)
			_end_wave()
		return
	
	# Handle spawning
	if not is_spawning:
		return
	
	spawn_timer += delta
	if spawn_timer < spawn_interval:
		return
	
	spawn_timer = 0.0
	_spawn_enemy()

func _start_next_wave() -> void:
	print("=== _start_next_wave called ===")
	
	if current_cycle >= boss_cycles:
		print("All waves completed!")
		is_spawning = false
		emit_signal("all_waves_completed")
		return
	
	spawned_in_wave = 0
	enemies_alive_in_wave = 0
	is_spawning = true
	all_spawned = false
	waiting_for_wave_clear = false
	
	if current_wave < normal_waves_before_boss:
		print("Starting normal wave %d of cycle %d" % [current_wave + 1, current_cycle + 1])
	else:
		print("Starting BOSS wave of cycle %d" % [current_cycle + 1])

func _spawn_enemy() -> void:
	var is_boss_wave = (current_wave >= normal_waves_before_boss)
	var scene_to_spawn = boss_scene if is_boss_wave else enemy_scene
	
	if scene_to_spawn == null:
		print("ERROR: Enemy scene not set!")
		is_spawning = false
		return
	
	var enemies_to_spawn = 1 if is_boss_wave else enemies_per_normal_wave
	
	if spawned_in_wave >= enemies_to_spawn:
		is_spawning = false
		all_spawned = true
		waiting_for_wave_clear = true
		print("All %d enemies spawned. Enemies alive: %d. Waiting for wave clear..." % [enemies_to_spawn, enemies_alive_in_wave])
		return
	
	var e = scene_to_spawn.instantiate()
	enemies_root.add_child(e)
	e.setup(path)
	
	# Connect to both main handlers AND our wave tracker
	e.reached_goal.connect(main._on_enemy_reached_goal)
	e.died.connect(main._on_enemy_died)
	e.reached_goal.connect(_on_enemy_removed)
	e.died.connect(_on_enemy_removed)
	
	spawned_in_wave += 1
	enemies_alive_in_wave += 1
	
	print("Spawned enemy %d/%d (alive in wave: %d)" % [spawned_in_wave, enemies_to_spawn, enemies_alive_in_wave])

func _on_enemy_removed(_enemy) -> void:
	# Just decrement counter, don't call main handlers (they're already connected)
	enemies_alive_in_wave -= 1
	print("Enemy removed! Remaining in wave: %d" % enemies_alive_in_wave)

func _end_wave() -> void:
	print("=== _end_wave called ===")
	waiting_for_wave_clear = false
	waiting_for_next_wave = true
	all_spawned = false
	
	current_wave += 1
	print("current_wave incremented to: %d" % current_wave)
	
	if current_wave > normal_waves_before_boss:
		current_wave = 0
		current_cycle += 1
		
		if current_cycle >= boss_cycles:
			print("All cycles completed!")
		else:
			print("Cycle %d completed! Starting cycle %d..." % [current_cycle, current_cycle + 1])
	
	print("Wave ended, starting %d second delay..." % wave_delay)
