extends Node

var paused: bool = true

@onready var config: ConfigFile = ConfigFile.new()

signal game_paused
signal game_unpaused
signal game_ended

func _ready() -> void:
	var enemy: Enemy = $/root/World/Enemy
	var player: Player = $/root/World/Player
	var gui: Control = $/root/World/GUI
	gui.options_updated.connect(write_config)
	enemy.entity_died.connect(on_entity_died)
	player.entity_died.connect(on_entity_died)
	#write_config()
	load_config()

func write_config() -> void:
		for node in $"/root/World/GUI/Menus/Settings/ScrollContainer/SettingsGrid".get_children(true):
			if node is LineEdit:
				config.set_value("SettingsSel", node.name, node.text)
			elif node is Button:
				config.set_value("SettingsButton", node.name, node.button_pressed)
		for node in $"/root/World/GUI/Menus/Controls/GridContainer".get_children(true):
			if node is Button:
				config.set_value("Controls", node.name, node.text)
		config.save("user://config.cfg")
		#print("config saved")

func load_config() -> void:
	var err = config.load("user://config.cfg")
	if err != OK:
		print("config failed to load")
		return
	for section in config.get_sections():
		match section:
			"SettingsSel":
				for keys in config.get_section_keys(section):
					get_node("/root/World/GUI/Menus/Settings/ScrollContainer/SettingsGrid/" + keys).text = config.get_value(section, keys)
			"SettingsButton":
				for keys in config.get_section_keys(section):
					get_node("/root/World/GUI/Menus/Settings/ScrollContainer/SettingsGrid/" + keys).button_pressed = config.get_value(section, keys)
			"Controls":
				for keys in config.get_section_keys(section):
					get_node("/root/World/GUI/Menus/Controls/GridContainer/" + keys).text = config.get_value(section, keys)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		Globals.paused = not Globals.paused
		pause_toggled()

func pause_toggled() -> void:
	if Globals.paused == true:
		game_paused.emit()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else: 
		game_unpaused.emit()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#func enemy_reach_update() -> void:
	#var enemy: Enemy = $/root/World/Enemy
	#var reachlabel: Label = $/root/World/GUI/HUD/Layers/EnemyReach
	#reachlabel.text = "Enemy Reach" + " " + str(enemy.reach)
			
func on_entity_died() -> void:
	var enemy: Enemy = $/root/World/Enemy
	var player: Player = $/root/World/Player
	enemy.position = Vector3(0,2,-15)
	player.position = Vector3(0,2,15)
