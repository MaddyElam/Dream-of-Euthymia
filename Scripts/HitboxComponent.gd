extends Area2D
class_name HitboxComponent

@export var health_component : HealthComponent
var hurt = false
const attackbox_layer = 512

signal damage_knockback(knockback_force)

func damage(p_attack_damage, p_attack_knockback, p_stun_time):
	if !hurt && health_component && health_component.invincible_timer.time_left <= 0:
		health_component.damage(p_attack_damage, p_stun_time)
		damage_knockback.emit(p_attack_knockback)
		set_hurt(true)

func set_hurt(p_hurt):
	hurt = p_hurt


func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer == attackbox_layer:
		damage(area.attack_damage, area.knockback_force, area.stun_time)
	
