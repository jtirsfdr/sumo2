class_name Player
extends Entity

@export var sensitivity: float = 1
@export var maxcps: int = 30

@onready var enemy: Enemy = get_node("../").find_child("Enemy", true, false)
@onready var gui: GUI = $"/root/World/GUI"
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

signal hit_enemy(hitvector: Vector3)
signal sprint_toggled(sprinting: bool)

func _ready() -> void:
	gui.toggle_sprint_toggled.connect(on_toggle_sprint_toggled)
	enemy.hit_player.connect(self.on_hit)
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cpscounter.resize(maxcps + 1)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			self.rotate_y(event.relative.x * sensitivity * -0.001)
			camera.rotate_x(event.relative.y * sensitivity * -0.001)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _process(delta: float) -> void:
	if Globals.paused == true:
		return

	if auto_run == false:
		var input_dir: Vector2 = Input.get_vector("left", "right", "forwards", "backwards")
		direction = transform.basis * Vector3(input_dir.x, 0, input_dir.y).normalized()
	else:
		direction = enemy.position - self.position

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
					hit_enemy.emit(-get_global_transform().basis.z.normalized() * kb_factor * wtap_kb_factor)
					wtap_reset = false
				else:
					hit_enemy.emit(-get_global_transform().basis.z.normalized() * kb_factor)

	if Input.is_action_pressed("block"):
		block = 0

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
