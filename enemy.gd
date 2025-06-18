class_name Enemy
extends Entity

@onready var player: Player = get_node("../").find_child("Player", true, false)

signal hit_player(hitvector: Vector3)

func _ready() -> void:
	auto_run = true
	sprinting = true
	reach = 5
	player.hit_enemy.connect(self.on_hit)
	
func _process(_delta: float) -> void:
	if Globals.paused == true:
		return
	move_and_slide()

func _physics_process(delta: float) -> void:
	if Globals.paused == true:
		return
	sprint_reset = true #bots cant w tap
	if auto_run == true:
		direction.x = player.position.x - self.position.x
		direction.z = player.position.z - self.position.z
	if $RayCast3D is RayCast3D: 
		var ray: RayCast3D = $RayCast3D
		ray.target_position = (player.global_position - self.global_position).normalized() * reach/3
		if ray.is_colliding():
			if ray.get_collider() is Player:
				hit_player.emit(ray.target_position.normalized() * kb_factor)
	move(delta)
	check_death()
