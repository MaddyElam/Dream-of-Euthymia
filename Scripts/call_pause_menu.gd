extends CanvasLayer

var options_menu

func _ready() -> void:
	visible = true
	options_menu = $OptionsMenuControl
	set_options_visible(false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("player_esc") && !options_menu.visible:
		if !get_tree().paused:
			set_paused(true)
			$PauseMenuControl.shift_menu_onscreen()
		else:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
			unpause()

func set_paused(paused):
	get_tree().paused = paused

func unpause():
	$PauseMenuControl.shift_menu_offscreen()

func set_options_visible(p_visible):
	options_menu.visible = p_visible

func _on_quit_button_pressed() -> void:
	get_tree().quit()
