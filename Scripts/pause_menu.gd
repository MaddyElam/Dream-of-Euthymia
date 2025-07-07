extends Control

var star_speed_range = Vector3(0.6, 0.7, 0.8)
var fg_shadow_speed = 0.9
var panel_container_speed = 0.8
var clouds_speed = 0.6

var return_speed = 0.5
var return_time = 500
var menu_reset_time = 0

var bg_shadow_visible = Color(0.032, 0, 0.16, 0.49803921568)
var bg_shadow_invisible = Color(0.032, 0, 0.16, 0)
var bg_shadow_increment = 0.5

var BGSHADOW
var STAR_1
var STAR_2
var STAR_3
var FGSHADOW
var PANELCONTAINER
var CLOUD_1
var CLOUD_2

var MOVING_PARTS : Array[SlidingUI]

var reset_pause = false

func _ready() -> void:
	BGSHADOW = $BackgroundShadow
	STAR_1 = SlidingUI.initialize($StarString1, $StarString1.anchor_left, $StarString1.anchor_right, -0.7, -0.7, star_speed_range.x, $StarString1.anchor_left, $StarString1.anchor_right, $StarString1.anchor_top, $StarString1.anchor_bottom)
	STAR_2 = SlidingUI.initialize($StarString2, $StarString2.anchor_left, $StarString2.anchor_right, -1, -1, star_speed_range.y, $StarString2.anchor_left, $StarString2.anchor_right, $StarString2.anchor_top, $StarString2.anchor_bottom)
	STAR_3 = SlidingUI.initialize($StarString3, $StarString3.anchor_left, $StarString3.anchor_right, -0.8, -0.8, star_speed_range.z, $StarString3.anchor_left, $StarString3.anchor_right, $StarString3.anchor_top, $StarString3.anchor_bottom)
	FGSHADOW = SlidingUI.initialize($ForegroundShadow, $ForegroundShadow.anchor_left, $ForegroundShadow.anchor_right, $ForegroundShadow.anchor_top, 0, fg_shadow_speed, $ForegroundShadow.anchor_left, $ForegroundShadow.anchor_right, $ForegroundShadow.anchor_top, $ForegroundShadow.anchor_bottom)
	PANELCONTAINER = SlidingUI.initialize($PanelContainer, -0.47, -0.1, $PanelContainer.anchor_top, $PanelContainer.anchor_bottom, panel_container_speed, $PanelContainer.anchor_left, $PanelContainer.anchor_right, $PanelContainer.anchor_top, $PanelContainer.anchor_bottom)
	CLOUD_1 = SlidingUI.initialize($Cloud_1, -0.4, -0.4, $Cloud_1.anchor_top, $Cloud_1.anchor_bottom, clouds_speed, $Cloud_1.anchor_left, $Cloud_1.anchor_right, $Cloud_1.anchor_top, $Cloud_1.anchor_bottom)
	CLOUD_2 = SlidingUI.initialize($Cloud_2, -0.65, -0.65, $Cloud_2.anchor_top, $Cloud_2.anchor_bottom, clouds_speed, $Cloud_2.anchor_left, $Cloud_2.anchor_right, $Cloud_2.anchor_top, $Cloud_2.anchor_bottom)
	
	MOVING_PARTS.append(STAR_1)
	MOVING_PARTS.append(STAR_2)
	MOVING_PARTS.append(STAR_3)
	MOVING_PARTS.append(FGSHADOW)
	MOVING_PARTS.append(PANELCONTAINER)
	MOVING_PARTS.append(CLOUD_1)
	MOVING_PARTS.append(CLOUD_2)
	
	for part in MOVING_PARTS:
		part.ui_item.anchor_left = part.init_anchor_left
		part.ui_item.anchor_right = part.init_anchor_right
		part.ui_item.anchor_top = part.init_anchor_top
		part.ui_item.anchor_bottom = part.init_anchor_bottom
	
	BGSHADOW.color = bg_shadow_invisible


func shift_menu_onscreen():
	for part in MOVING_PARTS:
		var tween_left_anchor = create_tween()
		tween_left_anchor.tween_property(part.ui_item, "anchor_left", part.new_anchor_left, part.slide_speed).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		var tween_right_anchor = create_tween()
		tween_right_anchor.tween_property(part.ui_item, "anchor_right", part.new_anchor_right, part.slide_speed).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		var tween_top_anchor = create_tween()
		tween_top_anchor.tween_property(part.ui_item, "anchor_top", part.new_anchor_top, part.slide_speed).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		var tween_bottom_anchor = create_tween()
		tween_bottom_anchor.tween_property(part.ui_item, "anchor_bottom", part.new_anchor_bottom, part.slide_speed).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	var tween_alpha = create_tween()
	tween_alpha.tween_property(BGSHADOW, "color", bg_shadow_visible, bg_shadow_increment)

func shift_menu_offscreen():
	for part in MOVING_PARTS:
		var tween_left_anchor = create_tween()
		tween_left_anchor.tween_property(part.ui_item, "anchor_left", part.init_anchor_left, return_speed)
		var tween_right_anchor = create_tween()
		tween_right_anchor.tween_property(part.ui_item, "anchor_right", part.init_anchor_right, return_speed)
		var tween_top_anchor = create_tween()
		tween_top_anchor.tween_property(part.ui_item, "anchor_top", part.init_anchor_top, return_speed)
		var tween_bottom_anchor = create_tween()
		tween_bottom_anchor.tween_property(part.ui_item, "anchor_bottom", part.init_anchor_bottom, return_speed)
	var tween_alpha = create_tween()
	tween_alpha.tween_property(BGSHADOW, "color", bg_shadow_invisible, bg_shadow_increment)
	
	await tween_alpha.finished
	get_parent().set_paused(false)


func _on_resume_button_pressed() -> void:
	shift_menu_offscreen()


func _on_options_button_pressed() -> void:
	get_parent().set_options_visible(true)
