extends Node

var paused: bool = true

signal game_paused
signal game_unpaused
signal game_ended

func _ready() -> void: # ACUTE CHECK
	#await get_tree().create_timer(0.1).timeout
	var enemy: Enemy = $/root/World/Enemy
	var player: Player = $/root/World/Player
	enemy.entity_died.connect(on_entity_died)
	player.entity_died.connect(on_entity_died)

func _physics_process(_delta: float) -> void:
	enemy_reach_update()
	
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

func enemy_reach_update() -> void:
	var enemy: Enemy = $/root/World/Enemy
	var reachlabel: Label = $/root/World/GUI/HUD/Layers/EnemyReach
	reachlabel.text = "Enemy Reach" + " " + str(enemy.reach)
			
func on_entity_died() -> void:
	var reachlabel: Label = $/root/World/GUI/HUD/Layers/EnemyReach
	var enemy: Enemy = $/root/World/Enemy
	var player: Player = $/root/World/Player
	enemy.position = Vector3(0,2,-15)
	player.position = Vector3(0,2,15)
