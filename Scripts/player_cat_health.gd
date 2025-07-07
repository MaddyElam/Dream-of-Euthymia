extends CanvasLayer

var animation_player
var warning_1_threshold = 2
var warning_2_threshold = 1
var default_offset = Vector2(-800, -450)
var default_scale = Vector2(2, 2)
var reset_speed = 1.5
var warning_1_offset = Vector2(-100, -56.25)
var warning_2_offset = Vector2(0, 0)
var warning_1_scale = Vector2(1.125, 1.125)
var warning_2_scale = Vector2(1, 1)
var warning_1_speed = 0.5
var warning_2_speed = 0.5
var current_health = 5
@export var particle_emitters : Array[Node2D]

func _ready() -> void:
	offset = default_offset
	scale = default_scale
	visible = true

func on_player_health_change(p_remaining_health):
	set_process(true)
	current_health = p_remaining_health
	
	if p_remaining_health <= warning_1_threshold && p_remaining_health > warning_2_threshold:
		visible = true
		var tween_offset_1 = create_tween()
		tween_offset_1.tween_property(self, "offset", warning_1_offset, warning_1_speed).set_trans(Tween.TRANS_SPRING)
		var tween_scale_1 = create_tween()
		tween_scale_1.tween_property(self, "scale", warning_1_scale, warning_1_speed).set_trans(Tween.TRANS_SPRING)
	
	if p_remaining_health <= warning_2_threshold && p_remaining_health > 0:
		visible = true
		for emitter in particle_emitters:
			emitter.emitting = true
		var tween_offset_2 = create_tween()
		tween_offset_2.tween_property(self, "offset", warning_2_offset, warning_2_speed).set_trans(Tween.TRANS_SPRING)
		var tween_scale_2 = create_tween()
		tween_scale_2.tween_property(self, "scale", warning_2_scale, warning_2_speed).set_trans(Tween.TRANS_SPRING)
	
	if p_remaining_health > warning_1_threshold:
		visible = true
		var tween_offset_reset = create_tween()
		tween_offset_reset.tween_property(self, "offset", default_offset, reset_speed).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		var tween_scale_reset = create_tween()
		tween_scale_reset.tween_property(self, "scale", default_scale, reset_speed).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

func _process(_delta: float) -> void:
	if offset == default_offset && scale == default_scale && current_health > warning_1_threshold:
		visible = false
		set_process(false)
