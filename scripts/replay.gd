class_name Replay

var positionHistory: Array[Vector2]
var timeHistory: Array[float]
var facingHistory: Array[float]
var slidingHistory: Array[bool]
var wallSlidingHistory: Array[bool]
var velocityYHistory: Array[float]
var hasDoubleJumpHistory: Array[bool]

var lastIx: int

func _init(pos: Vector2, t: float) -> void:
	positionHistory = []
	timeHistory = []
	facingHistory = []
	slidingHistory = []
	wallSlidingHistory = []
	velocityYHistory = []
	hasDoubleJumpHistory = []
	lastIx = 0
	record(pos, t, 1.0, false, false, 0.0, true)

func reset() -> void:
	lastIx = 0

func record(pos: Vector2, t: float, facing: float, sliding: bool, wall_sliding: bool, vel_y: float, has_double_jump: bool) -> void:
	positionHistory.push_back(pos)
	timeHistory.push_back(t)
	facingHistory.push_back(facing)
	slidingHistory.push_back(sliding)
	wallSlidingHistory.push_back(wall_sliding)
	velocityYHistory.push_back(vel_y)
	hasDoubleJumpHistory.push_back(has_double_jump)

func _advance(t: float) -> void:
	for i in range(lastIx, len(positionHistory)):
		if timeHistory[i] > t:
			break
		lastIx = i

func lerpPos(t: float) -> Vector2:
	var local_t = t - timeHistory[lastIx]
	var deltaT = timeHistory[lastIx + 1] - timeHistory[lastIx]
	var deltaP = positionHistory[lastIx + 1] - positionHistory[lastIx]
	return positionHistory[lastIx] + (local_t / deltaT) * deltaP

# Single call that returns both position and full state — advances lastIx once
func sample(t: float) -> Dictionary:
	_advance(t)
	var pos: Vector2
	if lastIx == len(positionHistory) - 1:
		pos = positionHistory[lastIx]
	else:
		pos = lerpPos(t)
	return {
		"position": pos,
		"facing": facingHistory[lastIx],
		"is_sliding": slidingHistory[lastIx],
		"is_wall_sliding": wallSlidingHistory[lastIx],
		"velocity_y": velocityYHistory[lastIx],
		"has_double_jump": hasDoubleJumpHistory[lastIx],
	}
