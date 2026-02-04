extends Node2D
@export var tower_scene: PackedScene
@export var tower_medium_scene: PackedScene
@export var tower_heavy_scene: PackedScene
@export var tower_shotgun_scene: PackedScene
@export var start_gold: int = 30
@export var start_lives: int = 10
@export var world_rect := Rect2(Vector2(0, 0), Vector2(960, 540))

var gold: int
var lives: int
var selected_spot = null
var game_won: bool = false
var game_over: bool = false

@onready var towers_root: Node2D = $Towers
@onready var ui_hint: Label = $UI/Notifications
@onready var ui_gold: Label = $UI/Gold
@onready var ui_lives: Label = $UI/Lives
@onready var cam: Camera2D = $Camera2D
@onready var spawner: Node = $Spawner

# Tower costs
const BASIC_COST = 10
const MEDIUM_COST = 20
const HEAVY_COST = 35
const SPEED_BOOST_COST := 20
const SPEED_BOOST_DURATION := 5.0
var speed_boost_active := false


var tower_selector: Control = null

func _ready() -> void:
	gold = start_gold
	lives = start_lives
	_update_ui()
	
	# Allow this node to process input even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	for spot in $BuildSpots.get_children():
		spot.clicked.connect(_on_build_spot_clicked)
	
	if has_node("UI/TowerSelector"):
		tower_selector = $UI/TowerSelector
		tower_selector.tower_selected.connect(_on_tower_type_selected)
		tower_selector.cancelled.connect(_on_tower_selection_cancelled)
		tower_selector.upgrade_selected.connect(_on_upgrade_selected)
		tower_selector.hide()
	else:
		print("Warning: TowerSelector not found in UI")
	
	# Connect to spawner's win signal
	if spawner:
		spawner.all_waves_completed.connect(_on_all_waves_completed)
	
	cam.limit_left = int(world_rect.position.x)
	cam.limit_top = int(world_rect.position.y)
	cam.limit_right = int(world_rect.position.x + world_rect.size.x)
	cam.limit_bottom = int(world_rect.position.y + world_rect.size.y)# Center the camera on the game world so it shows the full world_rect.
	cam.global_position = world_rect.position + world_rect.size * 0.5

	debug_check_path_inside_world()

func _input(event: InputEvent) -> void:
	# Boost item: press B
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			use_speed_boost()

	# Restart
	if (game_over or game_won) and event is InputEventKey:
		if event.keycode == KEY_R and event.pressed and not event.echo:
			_restart_game()


func _on_build_spot_clicked(spot) -> void:
	if game_won:
		return  # Don't allow building after winning
	
	if spot.has_tower:
		if tower_selector != null:
			selected_spot = spot
			tower_selector.show_upgrade_menu(spot.global_position + Vector2(30, -50), spot.tower_type)
		return
	
	if tower_selector != null:
		selected_spot = spot
		tower_selector.show_at_position(spot.global_position + Vector2(30, -50))
	else:
		_build_tower(spot, "basic")

func _on_tower_type_selected(tower_type: String) -> void:
	if selected_spot == null:
		return
	_build_tower(selected_spot, tower_type)
	selected_spot = null

func _on_upgrade_selected(upgrade_to_type: String) -> void:
	if selected_spot == null:
		return
		
		# ---- FREE SWITCH: heavy <-> shotgun ----
	if upgrade_to_type == "shotgun":
		# only allow heavy -> shotgun
		if selected_spot.tower_type != "heavy":
			_hint("Only Heavy can switch to Shotgun")
			selected_spot = null
			return

		if tower_shotgun_scene == null:
			_hint("Shotgun tower scene not set")
			selected_spot = null
			return

		if selected_spot.tower_node != null:
			selected_spot.tower_node.queue_free()

		var t = tower_shotgun_scene.instantiate()
		t.add_to_group("towers")
		towers_root.add_child(t)
		t.global_position = selected_spot.global_position

		selected_spot.tower_type = "shotgun"
		selected_spot.tower_node = t
		selected_spot.has_tower = true
		selected_spot.queue_redraw()

		_hint("Switched to Shotgun tower")
		_update_ui()
		selected_spot = null
		return

	if upgrade_to_type == "heavy" and selected_spot.tower_type == "shotgun":
		# shotgun -> heavy (free)
		if tower_heavy_scene == null:
			_hint("Heavy tower scene not set")
			selected_spot = null
			return

		if selected_spot.tower_node != null:
			selected_spot.tower_node.queue_free()

		var t2 = tower_heavy_scene.instantiate()
		t2.add_to_group("towers")
		towers_root.add_child(t2)
		t2.global_position = selected_spot.global_position

		selected_spot.tower_type = "heavy"
		selected_spot.tower_node = t2
		selected_spot.has_tower = true
		selected_spot.queue_redraw()

		_hint("Switched to Heavy tower")
		_update_ui()
		selected_spot = null
		return
	# ---- END FREE SWITCH ----



	var upgrade_cost: int = 0
	# Upgrade pricing rule:
	# cost = target_price - (current_price / 2)
	var current_cost: int = 0
	match selected_spot.tower_type:
		"basic":
			current_cost = BASIC_COST
		"medium":
			current_cost = MEDIUM_COST
		"heavy":
			current_cost = HEAVY_COST

	var target_cost: int = 0
	match upgrade_to_type:
		"medium":
			target_cost = MEDIUM_COST
		"heavy":
			target_cost = HEAVY_COST

	upgrade_cost = target_cost - int(current_cost / 2)

	if gold < upgrade_cost:
		_hint("Gold not enough! Need %d" % upgrade_cost)
		selected_spot = null
		return
	
	if selected_spot.tower_node != null:
		selected_spot.tower_node.queue_free()
	
	gold -= upgrade_cost
	var tower_scene_to_use = null
	
	match upgrade_to_type:
		"medium":
			tower_scene_to_use = tower_medium_scene
		"heavy":
			tower_scene_to_use = tower_heavy_scene
	
	if tower_scene_to_use == null:
		_hint("Tower scene not set for: %s" % upgrade_to_type)
		selected_spot = null
		return
	
	var t = tower_scene_to_use.instantiate()
	t.add_to_group("towers")
	towers_root.add_child(t)
	t.global_position = selected_spot.global_position
	
	selected_spot.tower_type = upgrade_to_type
	selected_spot.tower_node = t
	selected_spot.queue_redraw()
	
	_hint("Upgraded to %s tower -%d gold" % [upgrade_to_type, upgrade_cost])
	_update_ui()
	selected_spot = null

func _build_tower(spot, tower_type: String) -> void:
	var cost = 0
	var tower_scene_to_use = null
	
	match tower_type:
		"basic":
			cost = BASIC_COST
			tower_scene_to_use = tower_scene
		"medium":
			cost = MEDIUM_COST
			tower_scene_to_use = tower_medium_scene
		"heavy":
			cost = HEAVY_COST
			tower_scene_to_use = tower_heavy_scene
	
	if gold < cost:
		_hint("Gold not enough! Need %d" % cost)
		return
	
	if tower_scene_to_use == null:
		_hint("Tower scene not set for type: %s" % tower_type)
		return
	
	gold -= cost
	var t = tower_scene_to_use.instantiate()
	t.add_to_group("towers")
	towers_root.add_child(t)
	t.global_position = spot.global_position
	
	spot.has_tower = true
	spot.tower_type = tower_type
	spot.tower_node = t
	spot.queue_redraw()
	_hint("Built %s tower -%d gold" % [tower_type, cost])
	_update_ui()

func _on_tower_selection_cancelled() -> void:
	selected_spot = null
	_hint("Build cancelled")
	
func use_speed_boost() -> void:
	if speed_boost_active:
		return
	if gold < SPEED_BOOST_COST:
		return

	gold -= SPEED_BOOST_COST
	_update_ui()
	speed_boost_active = true

	get_tree().call_group("towers", "set_attack_speed_multiplier", 2.0)

	await get_tree().create_timer(SPEED_BOOST_DURATION).timeout

	get_tree().call_group("towers", "set_attack_speed_multiplier", 1.0)
	speed_boost_active = false


func _on_enemy_reached_goal(_enemy) -> void:
	lives -= 1
	_hint("Life -1")
	_update_ui()
	if lives <= 0:
		game_over = true
		spawner.stop_spawning()  # Stop spawner properly
		_clear_game_entities()
		_hint("Game Over - You Lost! Press R to Restart")
		get_tree().paused = true

func _on_enemy_died(enemy) -> void:
	gold += enemy.gold_reward
	var enemy_type = "Boss" if enemy.gold_reward > 5 else "Enemy"
	_hint("%s killed! +%d gold" % [enemy_type, enemy.gold_reward])
	_update_ui()

func _on_all_waves_completed() -> void:
	game_won = true
	_clear_game_entities()
	_hint("VICTORY! You defeated all waves! Press R to Restart")
	print("Player has won the game!")
	# Optional: pause the game or show a victory screen
	# get_tree().paused = true

func _clear_game_entities() -> void:
	# Clear all towers
	for tower in towers_root.get_children():
		tower.queue_free()
	
	# Clear all enemies
	var enemies_root_node = $Enemies
	for enemy in enemies_root_node.get_children():
		enemy.queue_free()
	
	# Clear all projectiles (bullets)
	var projectiles_root = $Projectiles
	if projectiles_root:
		for projectile in projectiles_root.get_children():
			projectile.queue_free()
	
	# Also clear any bullets that might be direct children of main scene
	for child in get_children():
		if child.is_in_group("bullet") or child.name.contains("Bullet"):
			child.queue_free()
	
	# Reset build spots visual state
	for spot in $BuildSpots.get_children():
		spot.has_tower = false
		spot.tower_type = ""
		spot.tower_node = null
		spot.queue_redraw()
	
	print("All game entities cleared from screen")

func _restart_game() -> void:
	print("Restarting game...")
	get_tree().paused = false
	get_tree().reload_current_scene()

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
