extends Sprite2D

const DEFAULT_POS = Vector2(7.5,-18)
const SPIKING_POS = Vector2(-15, -7.5)
const SPIKING_ROT = -45
const DEFAULT_ROT = 0

const DEFAULT_COLLIDER_ROT = 25
const DEFAULT_COLLIDER_POS = Vector2(10, 3)

const SPIKING_COLLIDER_ROT = 0
const SPIKING_COLLIDER_POS = Vector2(0, 0)

const FLYING_COLLIDER_ROT = 75
const FLYING_COLLIDER_POS = Vector2(11, -3)

const BARREL_COLLIDER_ROT = 90
const BARREL_COLLIDER_POS = Vector2(14, -17)

var current_animation = ""
var previous_animation = ""

@export var collider : CollisionShape2D
@export var hitbox : CollisionShape2D
@export var particle_system : GPUParticles2D

var parent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent()

func rotate_sprite(p_rotation_degrees, current_direction_x):
	self.rotation_degrees = p_rotation_degrees * current_direction_x
	
func position_sprite(p_pos_x, p_pos_y, current_direction_x):
	self.position = Vector2(p_pos_x * current_direction_x, p_pos_y)
	
func rotate_collider(p_collider, p_rotation_degrees, current_direction_x):
	p_collider.rotation_degrees = p_rotation_degrees * current_direction_x
	
func position_collider(p_collider, p_pos_x, p_pos_y, current_direction_x):
	p_collider.position = Vector2(p_pos_x * current_direction_x, p_pos_y)

func animation_started(anim_name: String):
	previous_animation = current_animation
	current_animation = anim_name
	
	if anim_name == "Flap_Loop_Spiking":
		if self.rotation_degrees != SPIKING_ROT * parent.current_h_facing:
			rotate_sprite(SPIKING_ROT, parent.current_h_facing)
			position_sprite(SPIKING_POS.x, SPIKING_POS.y, parent.current_h_facing)
		if collider.rotation_degrees != SPIKING_COLLIDER_ROT * parent.current_h_facing:
			rotate_collider(collider, SPIKING_COLLIDER_ROT, parent.current_h_facing)
			position_collider(collider, SPIKING_COLLIDER_POS.x, SPIKING_COLLIDER_POS.y, parent.current_h_facing)
			hitbox.rotation_degrees = collider.rotation_degrees
			hitbox.position = collider.position
	else:
		if self.rotation_degrees != DEFAULT_ROT * parent.current_h_facing:
			rotate_sprite(DEFAULT_ROT, parent.current_h_facing)
			position_sprite(DEFAULT_POS.x, DEFAULT_POS.y, parent.current_h_facing)
		if anim_name == "Injured":
			parent.injured_anim_finished = true
			particle_system.emitting = true
		if anim_name == "Lift_Off" || anim_name == "Land":
			parent.takeoff_landing = true
		elif parent.takeoff_landing:
			parent.takeoff_landing = false
			
		if anim_name == "Flap" || anim_name == "Flap_Loop" || anim_name == "Float" || anim_name == "Soar":
			if collider.rotation_degrees != FLYING_COLLIDER_ROT * parent.current_h_facing:
				rotate_collider(collider, FLYING_COLLIDER_ROT, parent.current_h_facing)
				position_collider(collider, FLYING_COLLIDER_POS.x, FLYING_COLLIDER_POS.y, parent.current_h_facing)
				hitbox.rotation_degrees = collider.rotation_degrees
				hitbox.position = collider.position
				
		elif anim_name == "Barrel" || anim_name == "Barrel_Continuous":
			if collider.rotation_degrees != BARREL_COLLIDER_ROT * parent.current_h_facing:
				rotate_collider(collider, BARREL_COLLIDER_ROT, parent.current_h_facing)
				position_collider(collider, BARREL_COLLIDER_POS.x, BARREL_COLLIDER_POS.y, parent.current_h_facing)
				hitbox.rotation_degrees = collider.rotation_degrees
				hitbox.position = collider.position
				
		elif anim_name == "Spell_Windup" || anim_name == "Spell":
			if collider.rotation_degrees != SPIKING_COLLIDER_ROT * parent.current_h_facing:
				rotate_collider(collider, SPIKING_COLLIDER_ROT, parent.current_h_facing)
				position_collider(collider, SPIKING_COLLIDER_POS.x, SPIKING_COLLIDER_POS.y, parent.current_h_facing)
				hitbox.rotation_degrees = collider.rotation_degrees
				hitbox.position = collider.position
				
		else:
			if collider.rotation_degrees != DEFAULT_COLLIDER_ROT * parent.current_h_facing:
				rotate_collider(collider, DEFAULT_COLLIDER_ROT, parent.current_h_facing)
				position_collider(collider, DEFAULT_COLLIDER_POS.x, DEFAULT_COLLIDER_POS.y, parent.current_h_facing)
				hitbox.rotation_degrees = collider.rotation_degrees
				hitbox.position = collider.position
			
	

func animation_ended(_anim_name : String):
	pass
