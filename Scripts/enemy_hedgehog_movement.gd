extends EnemyBaseMovement

const ROLL_SPEED = 700

var rolling = false
var can_roll = false

var rotate_speed = 0.5
var roll_speed_increment = 200
var max_speed = 1000

func _ready() -> void:
	super()
	running = true


func on_player_detected(player_body):
	if !dead && !player_detected && !rolling:
		player_detected = true
		direct_toward_player_h(player_body)
		set_can_roll(true)

func on_player_lost():
	if !dead:
		player_detected = false

func on_knockback_force(p_knockback_force):
	velocity.x = 0
	super(p_knockback_force)
	if !dead:
		velocity.y -= abs(p_knockback_force)

# Bool to let animationtree know to play animation that makes hedgehog roll up
func set_can_roll(p_can_roll : bool):
	can_roll = p_can_roll
	if can_roll:
		running = false

# Bool called by the roll-up animation that lets the script know to start moving the hedgehog
func set_rolling(p_rolling : bool):
	rolling = p_rolling
	$Rolling_Collision.set_deferred("disabled", !rolling)
	if !rolling && !dead:
		running = true
		current_speed_x = SPEED
	elif rolling && !dead:
		current_speed_x = ROLL_SPEED
	elif dead:
		current_speed_x = 0

func reset_rotation():
	$Sprite2D.rotation_degrees = 0


func roll_toward_player(p_delta):
	if current_speed_x < max_speed:
		current_speed_x += (roll_speed_increment * p_delta)
	$Sprite2D.rotate(rotate_speed * current_direction_x)
	velocity.x = move_toward(velocity.x, current_speed_x * current_direction_x, SPEED_COOLDOWN * p_delta)

func idle_movement(p_delta):
	velocity.x = move_toward(velocity.x, current_speed_x * current_direction_x, SPEED_COOLDOWN * p_delta)
	if $Wall_Detector.is_colliding():
		current_direction_x *= -1
		set_h_facing(current_direction_x)

func _physics_process(delta: float) -> void:
	super(delta)
	if mnvr_queue.size() <= 0 && !dead:
		if can_move && !knocked_back && rolling && can_roll:
			roll_toward_player(delta)
			if $Wall_Detector.is_colliding() && (rolling || $Sprite2D.rotation_degrees != 0):
				set_rolling(false)
				set_can_roll(false)
				if $Sprite2D.rotation_degrees != 0:
					reset_rotation()
				if player_detected:
					direct_toward_player_h(player_target)
					set_can_roll(true)
		elif is_on_floor():
			idle_movement(delta)
	if maneuver_finished && abs(current_speed_x) < SPEED && !dead:
		current_speed_x = SPEED
