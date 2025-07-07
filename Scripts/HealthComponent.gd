extends Node2D
class_name HealthComponent

const SPARKLE_HEALTH = 0.5
@export var MAX_HEALTH : float
@export var invincible_time : float = 1
@export var SPARKLE_NUMBER : int = 0
@export var despawn_time : float = 2
@export var hitbox_component : HitboxComponent
var health : float
var invincible_timer
var stun_timer
var despawn_timer

var sparkle_node = preload("res://Scenes/Sparkle_Health.tscn")

signal injured(health_remaining)
signal vulnerable()
signal can_attack()
signal can_despawn()
signal health_changed(health_remaining)

func _ready():
	health = MAX_HEALTH
	invincible_timer = $Invincible_Timer
	stun_timer = $Stun_Timer
	despawn_timer = $Despawn_Timer

# Logic for taking damage and starting stun and invincible timers
func damage(p_attack_damage, p_stun_time):
	# VFX for taking damage
	$GPUParticles2D.emitting = true
	
	# Actually losing health
	health -= p_attack_damage
	
	# If we're not dead, start the timers when applicable. Otherwise,
	if health > 0:
		if p_stun_time > 0:
			stun_timer.wait_time = p_stun_time
			stun_timer.start()
			
		if invincible_time > 0:
			invincible_timer.wait_time = invincible_time
			invincible_timer.start()
		else:
			vulnerable.emit()
	
	injured.emit(health)
	health_changed.emit(health)

func reset_health():
	health = MAX_HEALTH
	invincible_timer.wait_time = invincible_time
	invincible_timer.start()
	health_changed.emit(health)

# Start timer before entity despawns on death
func start_despawn_countdown():
	despawn_timer.wait_time = despawn_time
	despawn_timer.start()

# End of stun time
func _on_stun_timer_timeout() -> void:
	can_attack.emit()

# End of invincible frames
func _on_invincible_timer_timeout() -> void:
	vulnerable.emit()
	hitbox_component.set_hurt(false)


# Logic for picking up sparkles and gaining health from them
func _on_hitbox_component_body_entered(body) -> void:
	if body.get_script() == SparkleHealth:
		health += SPARKLE_HEALTH
		if health > MAX_HEALTH:
			health = MAX_HEALTH
		body.on_collected()
		health_changed.emit(health)

# Logic for spawning particles on enemy death
func drop_sparkles():
	for sparkle in SPARKLE_NUMBER:
		var new_sparkle = sparkle_node.instantiate()
		get_parent().add_child(new_sparkle)
		new_sparkle.reparent(get_parent().get_parent(), true)

# Logic for despawning after death
func _on_despawn_timer_timeout() -> void:
	can_despawn.emit()
