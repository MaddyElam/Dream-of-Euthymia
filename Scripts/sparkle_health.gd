extends RigidBody2D
class_name SparkleHealth

const LIFETIME = 10000
const TIME_UNTIL_COLLECTED = 1000
const HOVER_RANGE = 10
const BLAST_FORCE_X_MIN = 5
const BLAST_FORCE_Y_MIN = -30
const BLAST_FORCE_X_MAX = 30
const BLAST_FORCE_Y_MAX = -5
const SPAWN_TIME = 0.2
const HOVER_FORCE = 5

var spawn_location
var spawning = true
var blast_direction = 0
var time_since_spawn = 0
var hover_direction_x = 0
var hover_direction_y = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blast_direction = randi_range(0, 1)
	if blast_direction == 0:
		blast_direction = -1
	hover_direction_x = randi_range(0, 1)
	if hover_direction_x == 0:
		hover_direction_x = -1
	hover_direction_y = randi_range(0, 1)
	if hover_direction_y == 0:
		hover_direction_y = -1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if spawning:
		time_since_spawn += delta
		if time_since_spawn > SPAWN_TIME:
			spawning = false
		else:
			self.apply_central_impulse(Vector2(randf_range(BLAST_FORCE_X_MIN, BLAST_FORCE_X_MAX) * blast_direction, randf_range(BLAST_FORCE_Y_MIN, BLAST_FORCE_Y_MAX)))
	

func on_collected():
	self.queue_free()
