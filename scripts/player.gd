class_name Player
extends Entity

@export var sensitivity: float = 1
@export var maxcps: int = 30

@onready var enemy: Enemy = get_node("../").find_child("Enemy", true, false)
@onready var camera: Camera3D = $Camera3D
@onready var attack_ray: RayCast3D = $RayCast3D

var walk_fov: float = 90
var sprint_fov: float = walk_fov * 1.2
var fov_changing: bool = false
var referencetime: int
var cpsticker: int = 0
var cpscounter: Array[int]
var currentcps: int 
var toggle_sprint: bool = true
var cpsboost: bool
var blockboost: bool
var wtapboost: bool

signal hit_enemy(hitvector: Vector3)
signal sprint_toggled(sprinting: bool)

func _ready() -> void:
	#gui.togglesprintbutton_toggled.connect(on_toggle_sprint_toggled)
	gui.options_updated.connect(_update_settings)
	enemy.hit_player.connect(self.on_hit)

	cpscounter.resize(maxcps + 1)
	reach = 3

func _update_settings() -> void:
	sensitivity = float(settings.get_node("SensitivitySel").text)
	reach = float(settings.get_node("PlayerReachSel").text)
	ping = float(settings.get_node("PingSel").text) / 1000
	walk_speed = float(settings.get_node("SpeedSel").text)
	kb_factor = float(settings.get_node("KBFactorSel").text)
	toggle_sprint = settings.get_node("ToggleSprintButton").button_pressed
	cpsboost = settings.get_node("CPSKBButton").button_pressed
	blockboost = settings.get_node("BlockButton").button_pressed
	wtapboost = settings.get_node("WTapButton").button_pressed
	auto_run = settings.get_node("AutoMoveButton").button_pressed

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			self.rotate_y(event.relative.x * sensitivity * -0.001)
			camera.rotate_x(event.relative.y * sensitivity * -0.001)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _process(delta: float) -> void:
	if Globals.paused == true:
		return

	if $HitRotateTimer.is_stopped():
		camera.rotation.z = 0
	else:
		camera.rotation.z = $HitRotateTimer.time_left * 0.3

	if auto_run == false:
		var input_dir: Vector2 = Input.get_vector("left", "right", "forwards", "backwards")
		direction = transform.basis * Vector3(input_dir.x, 0, input_dir.y).normalized()
	else:
		if sqrt(global_position.x ** 2 + global_position.z ** 2) > 19:
			direction.x = -self.global_position.x / 5 + enemy.position.x - self.position.x
			direction.z = -self.global_position.z / 5 + enemy.position.z - self.position.z
		else:
			direction.x = enemy.position.x - self.position.x
			direction.z = enemy.position.z - self.position.z

	if Input.is_action_just_pressed("togglesprint"):
		toggle_sprint = not toggle_sprint
		sprint_toggled.emit(toggle_sprint) #for gui.gd

	if Input.is_action_pressed("sprint"):
		if not wish_sprinting:
			wtap_reset = true
		wish_sprinting = true
		sprint_reset = true

	if Input.is_action_just_pressed("forwards"):
		sprint_reset = true
		if toggle_sprint:
			wish_sprinting = true
			wtap_reset = true

	if Input.is_action_pressed("forwards"): 
		if toggle_sprint:
			wish_sprinting = true

	if Input.is_action_just_released("forwards"):
		wish_sprinting = false
		wtap_reset = false

	if Input.is_action_just_pressed("attack"):
		if cpsticker > maxcps:
			cpsticker = 0
		cpscounter[cpsticker] = int(Time.get_unix_time_from_system() * 100)
		cpsticker += 1
		if attack_ray.is_colliding():
			if attack_ray.get_collider() is Enemy:
				if wtap_reset:
					if wtapboost:
						print("boost") #fix the hit factors not changing vectors
						hit_enemy.emit(-get_global_transform().basis.z.normalized() * kb_factor * wtap_kb_factor * cps_factor)
						wtap_reset = false
					else:
						hit_enemy.emit(-get_global_transform().basis.z.normalized() * kb_factor * cps_factor)
						wtap_reset = false
				else:

					hit_enemy.emit(-get_global_transform().basis.z.normalized() * kb_factor * cps_factor)

	if Input.is_action_just_pressed("block"):
		if blockboost:
			block = 0
		else:
			block = 100

	if Input.is_action_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_velocity

	block += delta
	move(delta)
	check_fov_change(delta)
	move_and_slide()

func _physics_process(_delta: float) -> void:
	referencetime = int(Time.get_unix_time_from_system() * 100)
	currentcps = 0
	for i in maxcps:
		if referencetime - cpscounter[i] < 100:
			currentcps += 1
	$/root/World/GUI/HUD/Layers/CPS.text = "CPS: " + str(currentcps)
	if cpsboost:
		cps_factor = 1/((-log(currentcps+1)/log(10))/2 + 1) #more cps more kb
	else:
		cps_factor = 1
	attack_ray.target_position = -camera.transform.basis.z * reach

	check_death()

func on_toggle_sprint_toggled(toggled: bool):
	if toggled:
		toggle_sprint = true
	else:
		toggle_sprint = false

func _on_sensitivity_sel_text_changed(new_text: String) -> void:
	sensitivity = float(new_text)

func check_fov_change(delta: float) -> void:
	sprint_factor = 1.5
	if sprinting == true && camera.fov < sprint_fov - 1:
		camera.fov += (sprint_fov - camera.fov) * delta * 10
	elif sprinting == false && camera.fov > walk_fov + 1 || invincible == true:
		camera.fov -= (camera.fov - walk_fov) * delta * 10
