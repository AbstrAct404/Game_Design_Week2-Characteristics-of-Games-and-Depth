extends Control
signal tower_selected(tower_type)
signal cancelled
signal upgrade_selected(upgrade_to_type)

@onready var basic_btn: Button = $Panel/VBoxContainer/BasicButton
@onready var medium_btn: Button = $Panel/VBoxContainer/MediumButton
@onready var heavy_btn: Button = $Panel/VBoxContainer/HeavyButton
@onready var cancel_btn: Button = $Panel/VBoxContainer/CancelButton

var is_upgrade_mode := false
var current_tower_type := ""

func _ready() -> void:
	basic_btn.pressed.connect(_on_basic_pressed)
	medium_btn.pressed.connect(_on_medium_pressed)
	heavy_btn.pressed.connect(_on_heavy_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	hide()

func show_at_position(pos: Vector2) -> void:
	is_upgrade_mode = false
	current_tower_type = ""
	_update_button_text_for_build()
	position = pos
	show()

func show_upgrade_menu(pos: Vector2, tower_type: String) -> void:
	is_upgrade_mode = true
	current_tower_type = tower_type
	_update_button_text_for_upgrade(tower_type)
	position = pos
	show()

func _update_button_text_for_build() -> void:
	basic_btn.text = "Basic Tower (10 gold)"
	basic_btn.disabled = false
	medium_btn.text = "Medium Tower (20 gold)"
	medium_btn.disabled = false
	heavy_btn.text = "Heavy Tower (35 gold)"
	heavy_btn.disabled = false

func _update_button_text_for_upgrade(tower_type: String) -> void:
	match tower_type:
		"basic":
			basic_btn.text = "Already Basic"
			basic_btn.disabled = true
			medium_btn.text = "Upgrade to Medium (20 gold)"
			medium_btn.disabled = false
			heavy_btn.text = "Upgrade to Heavy (35 gold)"
			heavy_btn.disabled = false
		"medium":
			basic_btn.text = "Cannot Downgrade"
			basic_btn.disabled = true
			medium_btn.text = "Already Medium"
			medium_btn.disabled = true
			heavy_btn.text = "Upgrade to Heavy (35 gold)"
			heavy_btn.disabled = false
		"heavy":
			basic_btn.text = "Max Level"
			basic_btn.disabled = true
			medium_btn.text = "Max Level"
			medium_btn.disabled = true
			heavy_btn.text = "Already Heavy (Max)"
			heavy_btn.disabled = true

func _on_basic_pressed() -> void:
	if is_upgrade_mode:
		# Shouldn't happen since button is disabled
		return
	emit_signal("tower_selected", "basic")
	hide()

func _on_medium_pressed() -> void:
	if is_upgrade_mode:
		emit_signal("upgrade_selected", "medium")
	else:
		emit_signal("tower_selected", "medium")
	hide()

func _on_heavy_pressed() -> void:
	if is_upgrade_mode:
		emit_signal("upgrade_selected", "heavy")
	else:
		emit_signal("tower_selected", "heavy")
	hide()

func _on_cancel_pressed() -> void:
	emit_signal("cancelled")
	hide()
