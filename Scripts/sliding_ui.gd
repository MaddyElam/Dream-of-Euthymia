class_name SlidingUI extends Object

var ui_item : Control
var init_anchor_left : float
var init_anchor_right : float
var init_anchor_top : float
var init_anchor_bottom : float
var slide_speed : float
var new_anchor_left : float
var new_anchor_right : float
var new_anchor_top : float
var new_anchor_bottom : float

static func initialize(p_ui_item, p_init_anchor_left, p_init_anchor_right, p_init_anchor_top, p_init_anchor_bottom, p_slide_speed, p_new_anchor_left, p_new_anchor_right, p_new_anchor_top, p_new_anchor_bottom):
	var new_sliding_ui = SlidingUI.new()
	new_sliding_ui.ui_item = p_ui_item
	
	new_sliding_ui.init_anchor_left = p_init_anchor_left
	new_sliding_ui.init_anchor_right = p_init_anchor_right
	new_sliding_ui.init_anchor_top = p_init_anchor_top
	new_sliding_ui.init_anchor_bottom = p_init_anchor_bottom
	
	new_sliding_ui.slide_speed = p_slide_speed
	
	new_sliding_ui.new_anchor_left = p_new_anchor_left
	new_sliding_ui.new_anchor_right = p_new_anchor_right
	new_sliding_ui.new_anchor_top = p_new_anchor_top
	new_sliding_ui.new_anchor_bottom = p_new_anchor_bottom
	
	return new_sliding_ui
