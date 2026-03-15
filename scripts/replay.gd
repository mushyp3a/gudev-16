class_name Replay

var positionHistory:    Array[Vector2]
var timeHistory:        Array[float]
var playerActionHistory: Array[PlayerActions]
var facingHistory:       Array[float]
var velocityYHistory:    Array[float]
var isSlidingHistory:    Array[bool]
var isWallSlidingHistory: Array[bool]
var hasDoubleJumpHistory: Array[bool]
var lastIx: int

func _init(pos: Vector2, t: float, actions: PlayerActions):
	positionHistory     = []
	timeHistory         = []
	playerActionHistory = []
	facingHistory        = []
	velocityYHistory     = []
	isSlidingHistory     = []
	isWallSlidingHistory = []
	hasDoubleJumpHistory = []
	record(pos, t, actions, 1.0, 0.0, false, false, true)
	lastIx = 0

func reset() -> void:
	lastIx = 0

func record(pos: Vector2, t: float, actions: PlayerActions,
		facing: float, vel_y: float,
		sliding: bool, wall_sliding: bool, double_jump: bool) -> void:
	positionHistory.push_back(pos)
	timeHistory.push_back(t)
	playerActionHistory.push_back(actions)
	facingHistory.push_back(facing)
	velocityYHistory.push_back(vel_y)
	isSlidingHistory.push_back(sliding)
	isWallSlidingHistory.push_back(wall_sliding)
	hasDoubleJumpHistory.push_back(double_jump)

func lerpPos(t: float) -> Vector2:
	t -= timeHistory[lastIx]
	var deltaT = timeHistory[lastIx + 1] - timeHistory[lastIx]
	t /= deltaT
	var deltaP = positionHistory[lastIx + 1] - positionHistory[lastIx]
	return positionHistory[lastIx] + t * deltaP

func replayPos(t: float) -> Vector2:
	for i in range(lastIx, len(positionHistory)):
		if timeHistory[i] > t:
			break
		playerActionHistory[i].actAll()
		lastIx = i
	if lastIx == len(positionHistory) - 1:
		return positionHistory[lastIx]
	return lerpPos(t)

func sample(t: float) -> Dictionary:
	for i in range(lastIx, len(positionHistory)):
		if timeHistory[i] > t:
			break
		lastIx = i
	var ix = lastIx
	var pos: Vector2
	if ix < len(positionHistory) - 1:
		pos = lerpPos(t)
	else:
		pos = positionHistory[ix]
	return {
		"position":       pos,
		"facing":         facingHistory[ix],
		"velocity_y":     velocityYHistory[ix],
		"is_sliding":     isSlidingHistory[ix],
		"is_wall_sliding": isWallSlidingHistory[ix],
		"has_double_jump": hasDoubleJumpHistory[ix],
	}

func clear() -> void:
	positionHistory.clear()
	timeHistory.clear()
	playerActionHistory.clear()
	facingHistory.clear()
	velocityYHistory.clear()
	isSlidingHistory.clear()
	isWallSlidingHistory.clear()
	hasDoubleJumpHistory.clear()
	lastIx = 0

func is_empty() -> bool:
	return positionHistory.size() == 0

func get_duration() -> float:
	if timeHistory.size() == 0:
		return 0.0
	return timeHistory[-1]
