extends AnimationPlayer

@export var animation_tree_ref : AnimationTree
@export var player_root_node : Node2D
@export var affected_node_track_id : int = 0
@export var current_library : AnimationLibrary
@export var ground_detector_raycast : RayCast2D
var animation_statemachine
var current_anim_name = ""
var current_anim_data
var current_anim_length = 0
var key_pos = 0
var disqualified_animations = ["Death", "Empty", "Fall", "Roll", "RESET"]
var default_anim_values = {}
var default_anim_values_archive = {}
var movement_amt = 200
var anims_reset = true
var flat_normal = Vector2(0.0, -1.0)

func _ready() -> void:
	animation_statemachine = animation_tree_ref.get("parameters/playback")
	current_library = self.get_animation_library("")
	player_root_node.rolling_started.connect(on_rolling_started)
	player_root_node.attacking_started.connect(on_attack_started)
	for anims in current_library.get_animation_list():
		default_anim_values[anims] = self.get_animation(anims)
		default_anim_values_archive[anims] = self.get_animation(anims).duplicate(true)

func shift_bone_pos(affected_node, affected_node_look, p_new_pos, p_new_look, substr_cutoff, p_delta):
	if animation_statemachine.get_current_node() != null:
		current_anim_name = animation_statemachine.get_current_node()
		if !disqualified_animations.has(current_anim_name) && current_anim_name != "":
			current_anim_data = self.get_animation(current_anim_name)
			var track_id : int = current_anim_data.find_track(str(self.get_path_to(affected_node), ":position").substr(substr_cutoff), 0)
			if track_id != -1 && track_id <= current_anim_data.get_track_count():
				var current_key = current_anim_data.track_find_key(track_id, animation_statemachine.get_current_play_position(), 0, true)
				if current_key != -1:
					var default_key_value = default_anim_values[current_anim_name].track_get_key_value(track_id, current_key)
					if default_key_value && default_key_value != null:
						var new_key_value = default_key_value
						new_key_value = new_key_value.move_toward(Vector2(new_key_value.x + p_new_pos.x, p_new_pos.y), p_delta * movement_amt)
						current_anim_data.track_set_key_value(track_id, current_key, new_key_value)
			if affected_node_look && affected_node_look != null:
				var look_track_id : int = current_anim_data.find_track(str(self.get_path_to(affected_node_look), ":position").substr(substr_cutoff), 0)
				if look_track_id != -1 && look_track_id <= current_anim_data.get_track_count():
					var look_current_key = current_anim_data.track_find_key(look_track_id, animation_statemachine.get_current_play_position(), 0, true)
					if look_current_key != -1:
						current_anim_data.track_set_key_value(look_track_id, look_current_key, p_new_look)

func reset_bone_pos(affected_node, substr_cutoff, p_delta):
	if animation_statemachine.get_current_node() != null:
		current_anim_name = animation_statemachine.get_current_node()
		if !disqualified_animations.has(current_anim_name) && current_anim_name != "":
			current_anim_data = self.get_animation(current_anim_name)
			var track_id : int = current_anim_data.find_track(str(self.get_path_to(affected_node), ":position").substr(substr_cutoff), 0)
			if track_id != -1 && track_id <= current_anim_data.get_track_count():
				var current_key = current_anim_data.track_find_key(track_id, animation_statemachine.get_current_play_position(), 0, true)
				if current_key != -1:
					var default_key_value = default_anim_values_archive[current_anim_name].track_get_key_value(track_id, current_key)
					var current_key_value = current_anim_data.track_get_key_value(track_id, current_key)
					if default_key_value && default_key_value != null && current_key_value && current_key_value != null:
						var new_key_value = current_key_value.move_toward(default_key_value, p_delta * movement_amt)
						current_anim_data.track_set_key_value(track_id, current_key, new_key_value)

func set_anims_reset(p_reset):
	anims_reset = p_reset

func reset_anim_values():
	for anims in current_library.get_animation_list():
		if !disqualified_animations.has(anims):
			var anim_data = self.get_animation(anims)
			for tracks in anim_data.get_track_count():
				for keys in anim_data.track_get_key_count(tracks):
					if default_anim_values_archive[anims].track_get_key_value(tracks, keys) != null:
						anim_data.track_set_key_value(tracks, keys, default_anim_values_archive[anims].track_get_key_value(tracks, keys))
	set_anims_reset(true)

func on_rolling_started():
	animation_statemachine.travel("Roll")

func on_attack_started(p_attack_num, p_special):
	if p_special:
		animation_statemachine.travel("Attack_BackUpSwipe")
	else:
		if p_attack_num == -1:
			animation_statemachine.travel("Attack_BackDownSwipe")
		elif p_attack_num == 0:
			animation_statemachine.travel("Attack_FrontForwardSwipe")
		elif p_attack_num == 1:
			animation_statemachine.travel("Attack_BackKick")

func _physics_process(delta: float) -> void:
	if !anims_reset && (!ground_detector_raycast.is_colliding() || ground_detector_raycast.get_collision_normal() == flat_normal):
		reset_anim_values()
