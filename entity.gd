class_name Entity
extends CharacterBody3D

@export var land_particles_tscn: PackedScene

@export var max_speed: float
@export var walk_speed: float = 4
@export var sprint_factor: float = 1.6
@export var air_factor: float = 1.05
@export var accel: float = 7
@export var airaccel: float = 3
@export var decel: float = 7
@export var jump_velocity: int = 3
@export var ping: float = 0.05
@export var reach: float = 3
@export var auto_run: bool = false

var sprinting: bool = false
var invincible: bool = false
var speed: Vector3 = Vector3.ZERO
var wishspeed: Vector2 = Vector2.ZERO
var direction: Vector3
var hitvector: Vector3
var hitspeed: Vector3 = Vector3.ZERO
var strafe: int = 2
var turnfactor: int = 25 #higher = shallower
var shallowfactor: float = 1.2 #multiplier
var wish_sprinting: bool = true
var landed: bool = false
var sprint_reset: bool = true
var wtap_reset: bool = true
var kb_factor: float = 0.7
var wtap_kb_factor: float = 1.0
var block: float = 0.0
var max_block: float = 1
var cps_factor: float = 1

signal entity_died

func move(delta: float) -> void:
	var total_speed: float = abs(speed.x) + abs(speed.z)
	if wish_sprinting == true:
		if $SprintTimer.is_stopped():
			if sprint_reset:
				sprinting = true
	else:
		sprinting = false

	if sprinting == true:
		max_speed = walk_speed * sprint_factor
	else:
		max_speed = walk_speed

	if not is_on_floor(): #Falling
		landed = false
		if sprinting == true:
			max_speed = max_speed * air_factor
		velocity += get_gravity() * delta
	else:
		if not landed:
			var land_particles: CPUParticles3D = land_particles_tscn.instantiate()
			add_child(land_particles)
			land_particles.finished.connect(_on_particle_finish.bind(land_particles.get_path()))
			land_particles.position.y -= 1
			land_particles.emitting = true
			landed = true
		
	if direction == Vector3.ZERO: # Deceleration
		if total_speed > 0.3:
			speed -= speed * decel * delta
		else:
			speed = Vector3.ZERO
	else: #Acceleration (split into forward and side vectors)
		wishspeed = Vector2(direction.x * 5, direction.z * 5)
		if not is_on_floor():
			speed.x += wishspeed.x * airaccel * delta
			speed.z += wishspeed.y * airaccel * delta
		else:
			speed.x += wishspeed.x * accel * delta 
			speed.z += wishspeed.y * accel * delta
		if total_speed > max_speed:
			speed.x = speed.x / (total_speed / max_speed)
			speed.z = speed.z / (total_speed / max_speed)

	if auto_run == true:
		match strafe:
			0:
				speed.x = cos(PI/turnfactor)*speed.x - sin(PI/turnfactor)*speed.z
				speed.z = cos(PI/turnfactor)*speed.z + sin(PI/turnfactor)*speed.x
			1: # shallower turn
				speed.x = cos(PI/(turnfactor*shallowfactor))*speed.x - sin(PI/(turnfactor*shallowfactor))*speed.z
				speed.z = cos(PI/(turnfactor*shallowfactor))*speed.z + sin(PI/(turnfactor*shallowfactor))*speed.x
			2:
				pass
			3: 
				speed.x = cos(PI/(turnfactor*shallowfactor))*speed.x + sin(PI/(turnfactor*shallowfactor))*speed.z
				speed.z = cos(PI/(turnfactor*shallowfactor))*speed.z - sin(PI/(turnfactor*shallowfactor))*speed.x
			4: 

				speed.x = cos(PI/turnfactor)*speed.x + sin(PI/turnfactor)*speed.z
				speed.z = cos(PI/turnfactor)*speed.z - sin(PI/turnfactor)*speed.x

	hitspeed = hitspeed * (1-delta*2.4)
	velocity.x = speed.x + hitspeed.x
	velocity.z = speed.z + hitspeed.z
	

func _on_particle_finish(path: NodePath) -> void:
	get_node(path).queue_free()

func check_death() -> void:
	if self.position.y < -7:
		entity_died.emit()
	
func on_hit(hitvectorarg: Vector3) -> void:
	if block > max_block:
		hitvector = hitvectorarg
	else:
		print(block)
		hitvector = hitvectorarg * 0.8
	if invincible:
		pass
	else:
		if $LagTimer.is_stopped():
			$LagTimer.wait_time = ping
			$LagTimer.start()
		if $InvincibleTimer.is_stopped(): 
			$InvincibleTimer.start()
			$SprintTimer.start()
			invincible = true
			sprinting = false
			sprint_reset = false
			$Mesh.mesh.material.albedo_color = Color(0.75, 0, 0, 0)

func rng() -> void:
	#0 = left | 1 = forward left | 2 = forward | 3 = forward right | 4 = right
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	strafe = rng.randi_range(0,4)
	strafe = 1

func _on_lag_timer_timeout() -> void:
	hitspeed.x = hitvector.x * 20
	velocity.y = 3
	hitspeed.z = hitvector.z * 20
	
func _on_invincible_timer_timeout() -> void:
	$Mesh.mesh.material.albedo_color = Color(0.75, 0.75, 0.75, 0)
	invincible = false
	sprint_reset = true

func _on_strafe_timer_timeout() -> void:
	#0 = left | 1 = forward left | 2 = forward | 3 = forward right | 4 = right
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	strafe = rng.randi_range(0,4)
