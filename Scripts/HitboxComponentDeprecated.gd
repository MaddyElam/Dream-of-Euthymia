extends Area2D
class_name HitboxComponentDeprecated

@export var health_component : HealthComponent
var hurt = false

signal damage_knockback(knockback_force)

func _ready() -> void:
	print(collision_layer)

func damage(p_attack_damage, p_attack_knockback, p_stun_time):
	if !hurt && health_component && health_component.invincible_timer.time_left <= 0:
		health_component.damage(p_attack_damage, p_stun_time)
		damage_knockback.emit(p_attack_knockback)
		set_hurt(true)

func set_hurt(p_hurt):
	hurt = p_hurt
