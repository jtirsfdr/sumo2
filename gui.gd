class_name GUI
extends Control

@onready var globals: Globals = get_node("/root/Globals")
@onready var player: Node = $"/root/World/Player"
@onready var main_menu: VBoxContainer = $Menus/MainMenu
@onready var settings_menu: VBoxContainer = $Menus/Settings
@onready var controls_menu: VBoxContainer = $Menus/Controls

var changing_button: String 

signal toggle_sprint_toggled(toggled: bool)
signal cps_reduction_toggled(toggled: bool)
signal w_tap_toggled(toggled: bool)

func _ready() -> void:
	globals.game_paused.connect(self.on_game_paused)
	globals.game_unpaused.connect(self.on_game_unpaused)
	player.sprint_toggled.connect(self.on_sprint_toggled)

func _input(event: InputEvent) -> void:
	#Checks if modifying controls, and takes next key pressed as new control
	if changing_button == "":
		return
	elif event is InputEventKey and event.pressed:
		var action: String = changing_button.left(-6)
		action = action.to_lower()
		var button: Button = get_node("Menus/Controls/GridContainer/" + changing_button)

		button.text = OS.get_keycode_string(event.key_label)
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
		changing_button = ""

	elif event is InputEventMouseButton and event.pressed:
		var action: String = changing_button.left(-6)
		action = action.to_lower()
		var button: Button = get_node("Menus/Controls/GridContainer/" + changing_button)

		match event.button_index:
			1:
				button.text = "Mouse 1"
				InputMap.action_erase_events(action)
				InputMap.action_add_event(action, event)
			2: 
				button.text = "Mouse 2"
				InputMap.action_erase_events(action)
				InputMap.action_add_event(action, event)
			_:
				return
		changing_button = ""

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	main_menu.visible = false
	controls_menu.visible = false
	settings_menu.visible = true

func on_sprint_toggled(sprinting: bool) -> void:
	if sprinting:
		$HUD/Layers/ToggleSprint.text = "Toggle Sprint: On"
	else:
		$HUD/Layers/ToggleSprint.text = "Toggle Sprint: Off"

func _on_main_menu_button_pressed() -> void:
	main_menu.visible = true
	controls_menu.visible = false
	settings_menu.visible = false

func _on_play_button_pressed() -> void:
	$"/root/Globals".paused = false
	if $"/root/Globals/".has_method("pause_toggled"):
		$"/root/Globals/".pause_toggled()
	else:
		print("Invalid method || ", get_stack())

func on_game_paused() -> void:
	main_menu.visible = true
	$HUD.visible = false
	
func on_game_unpaused() -> void:
	main_menu.visible = false
	settings_menu.visible = false
	controls_menu.visible = false
	$HUD.visible = true
	
#MERGE NEXT FOUR FUNCTIONS INTO 1 WITH (BUTTON, TOGGLED, SIGNAL) AS ARGUMENTS
func _on_settings_option_button_pressed(toggled_on: bool, button_name: String) -> void:
	var button: Button = get_node("Menus/Settings/SettingsGrid/" + button_name)
	if toggled_on:
		button.text = "Enabled"
		match button_name:
			"ToggleSprintButton":
				toggle_sprint_toggled.emit(true)
				$HUD/Layers/ToggleSprint.visible = true
	else:
		button.text = "Disabled"
		match button_name:
			"ToggleSprintButton":
				$HUD/Layers/ToggleSprint.visible = false
				toggle_sprint_toggled.emit(false)


func _on_sprint_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$Menus/Settings/GridContainer/SprintButton.text = "Yeah :)"
		toggle_sprint_toggled.emit(true)
		$HUD/Layers/ToggleSprint.visible = true
	else:
		$Menus/Settings/GridContainer/SprintButton.text = " No :(  "
		$HUD/Layers/ToggleSprint.visible = false

func _on_cps_reduction_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$Menus/Settings/GridContainer/CPSReductionButton.text = "Yeah :)"
	else:
		$Menus/Settings/GridContainer/CPSReductionButton.text = " No :(  "

func _on_w_tap_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$Menus/Settings/GridContainer/CPSReductionButton.text = "Yeah :)"
	else:
		$Menus/Settings/GridContainer/CPSReductionButton.text = " No :(  "


func _on_alt_click_label_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$Menus/Settings/GridContainer/AltClickButton.text = "Yeah :)"
	else:
		$Menus/Settings/GridContainer/AltClickButton.text = " No :(  "


func _on_controls_menu_button_pressed() -> void:
	controls_menu.visible = true
	settings_menu.visible = false
	main_menu.visible = false

func _on_player_control_button_pressed(button_name: String) -> void:
	if changing_button == button_name: #locks button until actually changed
		return
	changing_button = button_name
	var button: Button = get_node("Menus/Controls/GridContainer/" + button_name)
	button.text = "..."
	
	
