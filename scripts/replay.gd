class_name Replay

var positionHistory: Array[Vector2]
var timeHistory: Array[float]

var lastIx: int

func _init(pos: Vector2, t: float):
	positionHistory = []
	timeHistory = []
	record(pos, t)
	lastIx = 0
	
func reset() -> void:
	lastIx = 0

func record(pos: Vector2, t: float):
	positionHistory.push_back(pos)
	timeHistory.push_back(t)

# Required to ensure that clone position is independent of framerate
# May result in strange behaviour for vastly different framerates
# Should maybe consider using fixed update (assuming Godot has an equivalent)
func lerpPos(t: float) -> Vector2:
	# Oddball mathematics
	t -= timeHistory[lastIx]
	var deltaT = timeHistory[lastIx + 1] - timeHistory[lastIx]
	t /= deltaT
	var deltaP = positionHistory[lastIx + 1] - positionHistory[lastIx]
	return positionHistory[lastIx] + t*deltaP

func getPos(t: float) -> Vector2:
	# Assume that t is in seconds, and is a float (an explicit conversion calculation may be necessary here
	# Do something silly vvvv
	for i in range(lastIx, len(positionHistory)):
		if timeHistory[i] > t:
			break
		lastIx = i
	if lastIx == len(positionHistory) - 1:
		return positionHistory[lastIx]
	return lerpPos(t)
