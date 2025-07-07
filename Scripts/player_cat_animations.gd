extends Sprite2D

const DEFAULT_POS = Vector2(3.75,-41.25)
const CLIMBING_POS = Vector2(-28, 0)
const CLIMBING_ROT = -90
const DEFAULT_ROT = 0

const DEFAULT_COLLIDER_BOD_POS = Vector2(-4, 0)
const DEFAULT_COLLIDER_HEAD_POS = Vector2(31, -41)
const DEFAULT_COLLIDER_BOD_ROT = 90
const DEFAULT_COLLIDER_HEAD_ROT = 25

const CLIMBING_COLLIDER_BOD_POS = Vector2(10, 10)
const CLIMBING_COLLIDER_HEAD_POS = Vector2(10, -40)
const CLIMBING_COLLIDER_BOD_ROT = 0
const CLIMBING_COLLIDER_HEAD_ROT = 0

const CROUCH_COLLIDER_BOD_POS = Vector2(-10, -25)
const CROUCH_COLLIDER_BOD_ROT = 68
const CROUCH_COLLIDER_BOD_SCALE = 1
const DEFAULT_COLLIDER_BOD_SCALE = 1

const CROUCH_COLLIDER_HEAD_POS = Vector2(16, -22)
const CROUCH_COLLIDER_HEAD_ROT = 40

const BACK_SWIPE_COLLIDER_HEAD_POS = Vector2(-10, -70)

const JUMP_COLLIDER_HEAD_POS = Vector2(31, -60)

const FALL_COLLIDER_HEAD_POS = Vector2(31, -50)

const VFX_SWIPE_UP = Vector4(60, -98, 1, 0)
const VFX_SWIPE_IDLE = Vector4(100, -25, 1, 0)
const VFX_SWIPE_RUN = Vector4(110, -25, 1, 0)
const VFX_SWIPE_BACK_LEG = Vector4(80, 25, 1.5, 0)

@export var head_collider : CollisionShape2D
@export var body_collider : CollisionShape2D
@export var feet_collider : CollisionShape2D
@export var feet_collider_2 : CollisionShape2D

@export var head_hitbox : CollisionShape2D
@export var body_hitbox : CollisionShape2D

@export var vfx_node : VFX_Node

var idle_anim_chance = 0.3
var time_between_idle_attempts = 1500
var time_since_last_attempt = 0

var sprites_right = preload("res://Art/CatResources/Cat_Right_Sheet.png")
var normals_right = preload("res://Art/CatResources/Cat_Right_Sheet_Normals.png")
var sprites_left = preload("res://Art/CatResources/Cat_Left_Sheet.png")
var normals_left = preload("res://Art/CatResources/Cat_Left_Sheet_Normals.png")
var current_texture = CanvasTexture.new()
var current_animation = ""
var previous_animation = ""
var parent 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_texture.diffuse_texture = sprites_right
	current_texture.normal_texture = normals_right
	parent = get_parent()

func switch_textures(current_direction_x):
	if current_direction_x == 1:
		current_texture.diffuse_texture = sprites_right
		current_texture.normal_texture = normals_right
		self.texture = current_texture
	elif current_direction_x == -1:
		current_texture.diffuse_texture = sprites_left
		current_texture.normal_texture = normals_left
		self.texture = current_texture
		
func rotate_sprite(p_rotation_degrees, current_direction_x):
	self.rotation_degrees = p_rotation_degrees * current_direction_x
	
func position_sprite(p_pos_x, p_pos_y, current_direction_x):
	self.position = Vector2(p_pos_x * current_direction_x, p_pos_y)
	
func position_collider(collider, p_pos_x, p_pos_y, current_direction_x):
	collider.position = Vector2(p_pos_x * current_direction_x, p_pos_y)
	
func rotate_collider(collider, p_rotation_degrees, current_direction_x):
	collider.rotation_degrees = p_rotation_degrees * current_direction_x
	
func set_collider_enabled(collider, enabled):
	collider.set_deferred("disabled", !enabled)
	
func collider_switch(climbing, p_anim_name, p_parent):
	if climbing:
		if head_collider.rotation_degrees != CLIMBING_COLLIDER_HEAD_ROT:
			head_collider.rotation_degrees = CLIMBING_COLLIDER_HEAD_ROT * p_parent.current_h_facing
			head_hitbox.rotation_degrees = head_collider.rotation_degrees
		if body_collider.rotation_degrees != CLIMBING_COLLIDER_BOD_ROT:
			body_collider.rotation_degrees = CLIMBING_COLLIDER_BOD_ROT * p_parent.current_h_facing
			
		if head_collider.position != Vector2(CLIMBING_COLLIDER_HEAD_POS.x * p_parent.current_h_facing, CLIMBING_COLLIDER_HEAD_POS.y):
			head_collider.position = Vector2(CLIMBING_COLLIDER_HEAD_POS.x * p_parent.current_h_facing, CLIMBING_COLLIDER_HEAD_POS.y)
		if body_collider.position != Vector2(CLIMBING_COLLIDER_BOD_POS.x * p_parent.current_h_facing, CLIMBING_COLLIDER_BOD_POS.y):
			body_collider.position = Vector2(CLIMBING_COLLIDER_BOD_POS.x * p_parent.current_h_facing, CLIMBING_COLLIDER_BOD_POS.y)
	else:
		if p_anim_name == "Ledge_Crouch":
			if body_collider.rotation_degrees != CROUCH_COLLIDER_BOD_ROT * p_parent.current_h_facing:
				body_collider.rotation_degrees = CROUCH_COLLIDER_BOD_ROT * p_parent.current_h_facing
			if body_collider.position != Vector2(CROUCH_COLLIDER_BOD_POS.x * p_parent.current_h_facing, CROUCH_COLLIDER_BOD_POS.y):
				body_collider.position = Vector2(CROUCH_COLLIDER_BOD_POS.x * p_parent.current_h_facing, CROUCH_COLLIDER_BOD_POS.y)
			if body_collider.scale != Vector2(CROUCH_COLLIDER_BOD_SCALE, CROUCH_COLLIDER_BOD_SCALE):
				body_collider.scale = Vector2(CROUCH_COLLIDER_BOD_SCALE, CROUCH_COLLIDER_BOD_SCALE)
			if head_collider.rotation_degrees != CROUCH_COLLIDER_HEAD_ROT * p_parent.current_h_facing:
				head_collider.rotation_degrees = CROUCH_COLLIDER_HEAD_ROT * p_parent.current_h_facing
			if head_collider.position != Vector2(CROUCH_COLLIDER_HEAD_POS.x * p_parent.current_h_facing, CROUCH_COLLIDER_HEAD_POS.y):
				head_collider.position = Vector2(CROUCH_COLLIDER_HEAD_POS.x * p_parent.current_h_facing, CROUCH_COLLIDER_HEAD_POS.y)
		else:
			if head_collider.rotation_degrees != DEFAULT_COLLIDER_HEAD_ROT:
				head_collider.rotation_degrees = DEFAULT_COLLIDER_HEAD_ROT * p_parent.current_h_facing
			if body_collider.rotation_degrees != DEFAULT_COLLIDER_BOD_ROT:
				body_collider.rotation_degrees = DEFAULT_COLLIDER_BOD_ROT * p_parent.current_h_facing
				
			if head_collider.position != Vector2(DEFAULT_COLLIDER_HEAD_POS.x * p_parent.current_h_facing, DEFAULT_COLLIDER_HEAD_POS.y):
				head_collider.position = Vector2(DEFAULT_COLLIDER_HEAD_POS.x * p_parent.current_h_facing, DEFAULT_COLLIDER_HEAD_POS.y)
			if body_collider.position != Vector2(DEFAULT_COLLIDER_BOD_POS.x * p_parent.current_h_facing, DEFAULT_COLLIDER_BOD_POS.y):
				body_collider.position = Vector2(DEFAULT_COLLIDER_BOD_POS.x * p_parent.current_h_facing, DEFAULT_COLLIDER_BOD_POS.y)
				
			if body_collider.scale != Vector2(DEFAULT_COLLIDER_BOD_SCALE, DEFAULT_COLLIDER_BOD_SCALE):
				body_collider.scale = Vector2(DEFAULT_COLLIDER_BOD_SCALE, DEFAULT_COLLIDER_BOD_SCALE)
			
		if p_anim_name == "Jump" || p_anim_name == "Swipe_Up":
			if head_collider.position != Vector2(JUMP_COLLIDER_HEAD_POS.x * p_parent.current_h_facing, JUMP_COLLIDER_HEAD_POS.y):
				head_collider.position = Vector2(JUMP_COLLIDER_HEAD_POS.x * p_parent.current_h_facing, JUMP_COLLIDER_HEAD_POS.y)
		elif p_anim_name == "Fall" || p_anim_name == "Jump_To_Fall":
			if head_collider.position != Vector2(FALL_COLLIDER_HEAD_POS.x * p_parent.current_h_facing, FALL_COLLIDER_HEAD_POS.y):
				head_collider.position = Vector2(FALL_COLLIDER_HEAD_POS.x * p_parent.current_h_facing, FALL_COLLIDER_HEAD_POS.y)
				
	head_hitbox.rotation_degrees = head_collider.rotation_degrees
	body_hitbox.rotation_degrees = body_collider.rotation_degrees
	head_hitbox.position = head_collider.position
	body_hitbox.position = body_collider.position
	
func idle_animation():
	time_since_last_attempt = Time.get_ticks_msec()
	if randf() < idle_anim_chance:
		parent.on_idle_anim(randi_range(0,1))

func animation_started(anim_name: String):
	previous_animation = current_animation
	current_animation = anim_name
	
	if previous_animation == "Swipe_Idle" || previous_animation == "Swipe_Run" || previous_animation == "Swipe_Back_Leg" || previous_animation == "Swipe_Up":
		get_parent().get_trail().set_points_clearing(true)
	
	if anim_name != "Tail" && anim_name != "Blink":
		parent.on_idle_anim(-1)
		
	if anim_name == "Jump":
		if previous_animation == "Jump_Wall" || previous_animation == "Climb_Idle" || previous_animation == "Climb"|| previous_animation == "Injured_Climb"|| previous_animation == "Land_On_Wall":
			parent.set_h_facing(parent.current_direction_x)
			collider_switch(false, anim_name, parent)
			if self.rotation_degrees != DEFAULT_ROT * parent.current_h_facing:
				rotate_sprite(DEFAULT_ROT, parent.current_h_facing)
			if self.position != Vector2(DEFAULT_POS.x * parent.current_h_facing, DEFAULT_POS.y):
				position_sprite(DEFAULT_POS.x, DEFAULT_POS.y, parent.current_h_facing)
	
	if anim_name == "Ledge_Crouch":
		set_collider_enabled(feet_collider, true)
		set_collider_enabled(feet_collider_2, true)
	else:
		set_collider_enabled(feet_collider, false)
		set_collider_enabled(feet_collider_2, false)
	
	if (anim_name == "Roll"):
		set_collider_enabled(head_collider, false)
		set_collider_enabled(head_hitbox, false)
	else:
		set_collider_enabled(head_collider, true)
		if !parent.injured:
			set_collider_enabled(head_hitbox, true)
	
	if (anim_name == "Climb" || anim_name == "Climb_Idle" || anim_name == "Land_On_Wall" || anim_name == "Injured_Climb"):
		collider_switch(true, anim_name, parent)
		if self.rotation_degrees != CLIMBING_ROT * parent.current_h_facing:
			rotate_sprite(CLIMBING_ROT, parent.current_h_facing)
		if self.position != Vector2(CLIMBING_POS.x * parent.current_h_facing, CLIMBING_POS.y):
			position_sprite(CLIMBING_POS.x, CLIMBING_POS.y, parent.current_h_facing)
		if anim_name == "Injured_Climb":
			parent.injured_anim_finished = true
	elif  anim_name == "Jump_Wall":
		collider_switch(true, anim_name, parent)
		if self.rotation_degrees != CLIMBING_ROT * parent.current_h_facing:
			rotate_sprite(CLIMBING_ROT, parent.current_h_facing)
		if self.position != Vector2(CLIMBING_POS.x * parent.current_h_facing, CLIMBING_POS.y):
			position_sprite(CLIMBING_POS.x, CLIMBING_POS.y, parent.current_h_facing)
	else:
		collider_switch(false, anim_name, parent)
		if anim_name == "Injured" || anim_name == "Injured_Up":
			parent.injured_anim_finished = true
		if self.rotation_degrees != DEFAULT_ROT * parent.current_h_facing:
			rotate_sprite(DEFAULT_ROT, parent.current_h_facing)
		if self.position != Vector2(DEFAULT_POS.x * parent.current_h_facing, DEFAULT_POS.y):
			position_sprite(DEFAULT_POS.x, DEFAULT_POS.y, parent.current_h_facing)
		if anim_name == "Swipe_Back_Leg":
			head_hitbox.position = Vector2(BACK_SWIPE_COLLIDER_HEAD_POS.x * parent.current_h_facing, BACK_SWIPE_COLLIDER_HEAD_POS.y)
			head_collider.position = head_hitbox.position
			
func animation_ended(anim_name : String):
	if anim_name == "Blink" || anim_name == "Tail":
		parent.on_idle_anim(-1)
		
	if anim_name == "Jump_Wall":
		parent.set_h_facing(parent.current_direction_x)
		collider_switch(false, anim_name, parent)
		if self.rotation_degrees != DEFAULT_ROT * parent.current_h_facing:
			rotate_sprite(DEFAULT_ROT, parent.current_h_facing)
		if self.position != Vector2(DEFAULT_POS.x * parent.current_h_facing, DEFAULT_POS.y):
			position_sprite(DEFAULT_POS.x, DEFAULT_POS.y, parent.current_h_facing)
		
	if anim_name == "Death":
		parent.respawn_player()
		
	if anim_name == "Injured" || anim_name == "Injured_Climb" || anim_name == "Injured_Up":
		parent.injured = false
		
func summon_vfx(anim_name : String):
	if anim_name == "Swipe_Back_Leg":
		vfx_node.modify_vfx_pos(VFX_SWIPE_BACK_LEG.x, VFX_SWIPE_BACK_LEG.y, parent.current_h_facing)
		vfx_node.modify_vfx_scale(VFX_SWIPE_BACK_LEG.z, VFX_SWIPE_BACK_LEG.z)
		vfx_node.modify_vfx_rot(VFX_SWIPE_BACK_LEG.w, parent.current_h_facing)
	elif anim_name == "Swipe_Idle":
		vfx_node.modify_vfx_pos(VFX_SWIPE_IDLE.x, VFX_SWIPE_IDLE.y, parent.current_h_facing)
		vfx_node.modify_vfx_scale(VFX_SWIPE_IDLE.z, VFX_SWIPE_IDLE.z)
		vfx_node.modify_vfx_rot(VFX_SWIPE_IDLE.w, parent.current_h_facing)
	elif anim_name == "Swipe_Run":
		vfx_node.modify_vfx_pos(VFX_SWIPE_RUN.x, VFX_SWIPE_RUN.y, parent.current_h_facing)
		vfx_node.modify_vfx_scale(VFX_SWIPE_RUN.z, VFX_SWIPE_RUN.z)
		vfx_node.modify_vfx_rot(VFX_SWIPE_RUN.w, parent.current_h_facing)
	elif anim_name == "Swipe_Up":
		vfx_node.modify_vfx_pos(VFX_SWIPE_UP.x, VFX_SWIPE_UP.y, parent.current_h_facing)
		vfx_node.modify_vfx_scale(VFX_SWIPE_UP.z, VFX_SWIPE_UP.z)
		vfx_node.modify_vfx_rot(VFX_SWIPE_UP.w, parent.current_h_facing)
		
	if vfx_node.animator.is_playing():
		vfx_node.animator.stop()
		
	vfx_node.play_animation(anim_name)
	
func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - time_since_last_attempt > time_between_idle_attempts && current_animation == "Idle":
		idle_animation()

func get_current_animation():
	return current_animation
