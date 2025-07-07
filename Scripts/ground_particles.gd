extends GPUParticles2D

@export var parent_body : Node2D
var ground_detector
var current_tile_atlas_coords
var current_tile_map_coords
var current_particle_texture
var can_emit = false

@export var particle_scale : Vector2 = Vector2(0.1, 1.0)
@export var init_velocity : Vector2 = Vector2(0, 0)

func _ready() -> void:
	ground_detector = $RayCast2D
	process_material.scale = particle_scale
	process_material.initial_velocity = init_velocity

func on_running():
	can_emit = true

func on_not_running():
	can_emit = false

func detect_ground_type():
	current_tile_map_coords = ground_detector.get_collider().get_coords_for_body_rid(ground_detector.get_collider_rid())
	current_tile_atlas_coords = ground_detector.get_collider().get_cell_atlas_coords(current_tile_map_coords)
	current_particle_texture = ground_detector.get_collider().get_particle_dict().get(current_tile_atlas_coords)
	
	for emitter in ground_detector.get_collider().emitters_to_tile_coords:
		if ground_detector.get_collider().emitters_to_tile_coords.get(emitter) == current_tile_map_coords:
			emitter.emitting = true
	
	if current_particle_texture && current_particle_texture != null && can_emit:
		texture = current_particle_texture
		emitting = true
		process_material.direction.x *= parent_body.current_direction_x
	else:
		emitting = false

func _physics_process(_delta: float) -> void:
	if ground_detector.is_colliding() && ground_detector.get_collider().name == "Terrain" && parent_body.velocity.x != 0:
		detect_ground_type()
		can_emit = true
	else:
		can_emit = false
		emitting = false
