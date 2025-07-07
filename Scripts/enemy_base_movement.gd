extends CharacterBody2D
class_name EnemyBaseMovement

@export var current_direction_x : int = -1
@export var SPEED : float = 300.0
@export var ACCEPTABLE_PLAYER_DISTANCE : float = 10
@export var aerial_enemy : bool = false

const LOOP_ROTATION_SPEED = 7
var SPEED_COOLDOWN = 1000.0
var player_target : Node2D

var current_h_facing = 1
var old_h_facing = 1
var current_direction_y = 0
var current_v_facing = 1
var old_v_facing = 1

var flash_increment = 7

var running = false
var injured = false
var attacking = false
var can_attack = false
var knocked_back = false
var dead = false
var delayed_death = false
var injured_anim_finished = false
var flashing = false
var flying = false

var player_detected = false
var can_move = true
var current_speed_x = SPEED
var current_speed_y = SPEED

var mnvr_queue : Array[Maneuvers]
var mnvr_interval_counter = 0
var mnvr_prev = Vector2(0, 0)
var maneuver_finished = true
var stored_velocity_x = 0

var shader_animator

var mnvr_knockback : Array[Maneuvers] = [Maneuvers.initialize(0, 0, 0, 0), Maneuvers.initialize(0, 0, 0.2, 0)]

signal h_facing_changed(old_facing, new_facing)
signal v_facing_changed(old_facing, new_facing)

var enemy_control

func _ready() -> void:
	$PlayerDetector.player_detected.connect(on_player_detected)
	$PlayerDetector.player_lost.connect(on_player_lost)
	$AttackComponent.can_attack.connect(on_can_attack)
	$AttackComponent.cooldown_started.connect(on_attack_cooldown_started)
	$HealthComponent.can_attack.connect(on_can_attack)
	$HealthComponent.vulnerable.connect(on_invincible_timeout)
	$HealthComponent.injured.connect(on_injured)
	$HealthComponent.can_despawn.connect(on_can_despawn)
	$HitboxComponent.damage_knockback.connect(on_knockback_force)
	current_h_facing = current_direction_x
	
	if get_parent().name == "EnemyControl":
		enemy_control = get_parent()
	if enemy_control && enemy_control != null:
		player_target = enemy_control.player_target
	$PlayerDetector.player_target = player_target


# signallers
func call_h_flipper():
	h_facing_changed.emit(old_h_facing, current_h_facing)

# signal receivers
func on_injured(health_remaining):
	injured_anim_finished = false
	injured = true
	can_attack = false
	attacking = false
	set_attack_enabled(false)
	if health_remaining <= 0:
		knocked_back = true
		on_death()
	else:
		set_injured_blinking(true)
	$Sprite2D.material.set_shader_parameter("flash_opacity", 1)
	flashing = true

func on_can_despawn():
	destroy_enemy()

func on_death():
	if !knocked_back:
		can_attack = false
		attacking = false
		set_attack_enabled(false)
		can_move = false
		dead = true
		current_speed_x = 0
		velocity.x = 0
	else:
		delayed_death = true

func on_invincible_timeout():
	injured = false
	set_hitbox_enabled(true)
	set_injured_blinking(false)

func on_can_attack():
	can_attack = true
	set_attack_enabled(true)

func on_attack_cooldown_started():
	can_attack = false
	attacking = false
	set_attack_enabled(false)

func on_knockback_force(p_knockback_force):
	if !dead:
		knocked_back = true
		can_move = false
		running = false
		can_attack = false
		attacking = false
		set_attack_enabled(false)
		mnvr_knockback.front().force_x = p_knockback_force
		maneuver_initializer(mnvr_knockback, current_h_facing)

func on_player_detected(player_body):
	if !dead:
		player_detected = true
		direct_toward_player_h(player_body)
		set_velocity_x(SPEED)

func on_player_lost():
	if !dead:
		player_detected = false
		if mnvr_queue.size() <= 0:
			current_speed_x = 0
			velocity.x = 0


# setters
func set_attack_enabled(enabled : bool):
	$AttackComponent/CollisionShape2D.set_deferred("disabled", !enabled)

func set_hitbox_enabled(enabled : bool):
	$HitboxComponent/CollisionShape2D.set_deferred("disabled", !enabled)

func set_attacking(attacking_status):
	attacking = attacking_status

func set_injured(injured_status):
	injured = injured_status

func set_injured_blinking(blinking_status : bool):
	$Sprite2D.material.set_shader_parameter("blinking", blinking_status)

func set_h_facing(current_direction):
	if current_direction != 0:
		old_h_facing = current_h_facing
		current_h_facing = current_direction
		h_facing_changed.emit(old_h_facing, current_h_facing)

func set_v_facing(current_direction):
	if current_direction != 0:
		old_v_facing = current_v_facing
		current_v_facing = current_direction
		v_facing_changed.emit(old_v_facing, current_v_facing)

func set_velocity_x(p_speed_x : float):
	current_speed_x = p_speed_x

func set_injured_anim_finished(finished : bool):
	injured_anim_finished = finished


func position_attack_component(new_pos : Vector2):
	$AttackComponent/CollisionShape2D.position = Vector2(new_pos.x * (current_h_facing * -1), new_pos.y)


func increment_shader_flash(p_delta):
	var previous_flash_opacity = $Sprite2D.material.get_shader_parameter("flash_opacity")
	if previous_flash_opacity > 0.0:
		$Sprite2D.material.set_shader_parameter("flash_opacity", previous_flash_opacity - (flash_increment * p_delta))
	elif previous_flash_opacity < 0.0:
		$Sprite2D.material.set_shader_parameter("flash_opacity", 0.0)
	else:
		flashing = false

func destroy_enemy():
	self.queue_free()

func direct_toward_player_h(p_player_body):
	if p_player_body && p_player_body != null:
		if (self.global_position - p_player_body.global_position).normalized().x > 0:
			current_direction_x = -1
			set_h_facing(current_direction_x)
		elif (self.global_position - p_player_body.global_position).normalized().x < 0:
			current_direction_x = 1
			set_h_facing(current_direction_x)

func direct_toward_player_v(p_player_body):
	if p_player_body && p_player_body != null:
		if (self.global_position - p_player_body.global_position).normalized().y > 0:
			current_direction_y = -1
			set_h_facing(current_direction_x)
		elif (self.global_position - p_player_body.global_position).normalized().y < 0:
			current_direction_y = 1
			set_h_facing(current_direction_x)

func move_toward_player_x(p_player_body, p_delta):
	if player_detected && !injured && can_move && !knocked_back && !dead:
		direct_toward_player_h(player_target)
		running = true
		if abs(self.global_position - p_player_body.global_position).normalized().x > ACCEPTABLE_PLAYER_DISTANCE:
			current_speed_x = SPEED
			velocity.x = current_speed_x * current_direction_x
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED_COOLDOWN * p_delta)
	else:
		running = false

func move_toward_player_y(p_player_body):
	if player_detected && !injured && can_move && !knocked_back && !dead:
		direct_toward_player_v(player_target)
		flying = true
		if abs(self.global_position - p_player_body.global_position).normalized().y > ACCEPTABLE_PLAYER_DISTANCE:
			velocity.y = current_speed_y * current_direction_y
	else:
		flying = false

func idle_movement(_p_delta):
	pass

func maneuver_initializer(p_mnvr, current_dir_x):
	mnvr_queue.append_array(p_mnvr)
	stored_velocity_x = velocity.x
	maneuver_finished = false
	can_move = false
	if knocked_back:
		current_direction_x = 1
	else:
		current_direction_x = current_dir_x

func _physics_process(delta: float) -> void:
	if !aerial_enemy:
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			if $SlopeManager.collision_normal:
				if ($SlopeManager.collision_normal.x > 0 && current_direction_x == 1) || ($SlopeManager.collision_normal.x < 0 && current_direction_x == -1):
					velocity.y += get_gravity().y * delta * $SlopeManager.slope_modifier
		
	if mnvr_queue.size() > 0:
		mnvr_interval_counter += delta
		if mnvr_queue.front().time_between < mnvr_interval_counter:
			mnvr_interval_counter = 0.0
			var mnvr = mnvr_queue.pop_front()
			# If the previous command had you going left while the current one is pointing right:
			if mnvr_prev.x < 0 && mnvr.force_x > 0:
				velocity.x += (mnvr.force_x + abs(velocity.x)) * current_direction_x
				# Otherwise, if previously you were going right while the new one is pointed left:
			elif mnvr_prev.x > 0 && mnvr.force_x < 0:
				velocity.x += (mnvr.force_x + (abs(velocity.x) * -1)) * current_direction_x
			else:
				velocity.x += mnvr.force_x * current_direction_x
			# If prev had you going up and now you're going down:
			if mnvr_prev.y < 0 && mnvr.force_y > 0:
				velocity.y += mnvr.force_y + abs(velocity.y)
			# Otherwise, if you were going down and now are going up:
			elif mnvr_prev.y > 0 && mnvr.force_y < 0:
				velocity.y += mnvr.force_y + (abs(velocity.y) * -1)
			else:
				velocity.y += mnvr.force_y
			mnvr_prev = Vector3(mnvr.force_x, mnvr.force_y, mnvr.rotation_degrees)
		if self.rotation != deg_to_rad(mnvr_prev.z) * current_direction_x:
			self.rotation = rotate_toward(deg_to_rad(self.rotation_degrees), deg_to_rad(mnvr_prev.z) * current_direction_x, LOOP_ROTATION_SPEED * delta)
	else:
		if mnvr_interval_counter != 0.0:
			mnvr_interval_counter = 0.0
		if !maneuver_finished:
			if self.rotation_degrees != 0:
				self.rotation_degrees = 0
			# Instead of coming to a dead stop, we slow to a stop. Once we are fully stopped, we can shut off every other bool or condition, exiting from this block.
			if current_speed_x != 0:
				current_speed_x = move_toward(current_speed_x, 0, SPEED_COOLDOWN*delta)
			else:
				knocked_back = false
				attacking = false
				maneuver_finished = true
				can_move = true
				velocity.x = 0
				if player_target && player_target != null && !dead && !aerial_enemy:
					direct_toward_player_h(player_target)
		if delayed_death:
			on_death()
	
	if flashing:
		increment_shader_flash(delta)
	
	move_and_slide()
