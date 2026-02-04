extends "res://Tower.gd"

# Shotgun tower:
# - Uses the SAME exported stats as Tower.gd (fire_interval, bullet_damage, bullet_speed, bullet_scene, tower_color...)
# - Only changes firing behavior: shoots 3 bullets with fixed angular spread.

@export var spread_deg: float = 30.0

func _on_fire_timer_timeout() -> void:
	_pick_target()

	if target == null or not is_instance_valid(target):
		target = null
		return

	if bullet_scene == null:
		return

	var dir0: Vector2 = (target.global_position - global_position).normalized()

	# Shoot 3 bullets: -spread, 0, +spread
	for i in [-1, 0, 1]:
		var bullet = bullet_scene.instantiate()
		if bullet == null:
			continue

		# Keep consistent with your base Tower.gd behavior
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position

		var d: Vector2 = dir0.rotated(deg_to_rad(spread_deg * float(i)))

		# Your Bullets.gd uses fields: damage, speed, dir
		bullet.damage = bullet_damage
		bullet.speed = bullet_speed
		bullet.dir = d
