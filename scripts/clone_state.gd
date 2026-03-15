class_name CloneState extends RefCounted

enum State {
	IDLE,
	WAITING_INPUT,
	RECORDING,
	PLAYING,
}

static func can_transition(from_state: State, to_state: State) -> bool:
	if from_state == to_state:
		return true

	match from_state:
		State.IDLE:
			return to_state == State.WAITING_INPUT or to_state == State.PLAYING
		State.WAITING_INPUT:
			return to_state == State.RECORDING or to_state == State.IDLE
		State.RECORDING:
			return to_state == State.IDLE
		State.PLAYING:
			return to_state == State.IDLE
		_:
			return false

static func get_state_name(state: State) -> String:
	match state:
		State.IDLE:
			return "IDLE"
		State.WAITING_INPUT:
			return "WAITING_INPUT"
		State.RECORDING:
			return "RECORDING"
		State.PLAYING:
			return "PLAYING"
		_:
			return "UNKNOWN"
