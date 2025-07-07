extends TileMapLayer

@export var terrain_particles : Dictionary
@export var particle_emitters : Array[Node2D]
@export var emitters_to_tile_coords : Dictionary
@export var randomize_particle_emitters : bool = false
@export var particle_emitter_tiles : Array[Vector2]
@export var particle_emitter_amount_range : Vector2i = Vector2i(1, 10)

func _ready() -> void:
	if randomize_particle_emitters:
		randomize_emitter()
		randomize_particle_amount()

func get_particle_dict():
	return terrain_particles

func randomize_emitter():
	for emitter in particle_emitters:
		var emitter_tile = get_used_cells_by_id(-1, particle_emitter_tiles.pick_random()).pick_random()
		var emitter_tile_pos = to_global(map_to_local(emitter_tile))
		emitter.global_position = Vector2(emitter_tile_pos.x, emitter_tile_pos.y - (tile_set.tile_size.x * 0.5))
		emitters_to_tile_coords[emitter] = emitter_tile

func randomize_particle_amount():
	for emitter in particle_emitters:
		emitter.amount = randi_range(particle_emitter_amount_range.x, particle_emitter_amount_range.y)
