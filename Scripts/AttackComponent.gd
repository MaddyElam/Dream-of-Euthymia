extends Node2D
class_name AttackComponent

# All the important attributes of the attack
@export var attack_damage : float
@export var knockback_force : float
@export var stun_time : float
@export var attack_cooldown : float = 1.5

var current_target_bodies : Array[Area2D]
signal can_attack()
signal cooldown_started()

# If we're even able to attack someone, they're our current target.
func _on_attack_range_area_entered(area: Area2D) -> void:
	# We add the Area2D of the target to our list of current targets.
	current_target_bodies.append(area)
	for target_body in current_target_bodies:
		summon_attack(target_body)
	current_target_bodies.clear()
	
# We ensure that our target is actually capable of being attacked, then call its damage().
func summon_attack(given_target_body):
	if given_target_body.name == "HitboxComponent":
		if given_target_body.has_method("damage"):
			given_target_body.damage(attack_damage, _knockback_direction(given_target_body), stun_time)
			cooldown_started.emit()
			if attack_cooldown > 0:
				$Cooldown_Timer.wait_time = attack_cooldown
				$Cooldown_Timer.start()
			else:
				can_attack.emit()


# Determines which direction the entity being attacked should be knocked in based on what
# direction they're being attacked from. 
func _knockback_direction(victim_area):
	if (global_position - victim_area.global_position).normalized().x > 0:
		return knockback_force * -1
	else:
		return knockback_force


func _on_cooldown_timer_timeout() -> void:
	can_attack.emit()
