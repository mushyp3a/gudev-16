class_name CloneState extends RefCounted

## State machine for the clone/replay system
## Defines valid states and enforces state transitions

enum State {
	IDLE,           # Paused in plan mode, no recording or playback
	WAITING_INPUT,  # Waiting for player to make first move after starting recording
	RECORDING,      # Currently recording a clone
	PLAYING,        # Playing back one or more clones
}

## Validates if a state transition is allowed
## Returns true if the transition from 'from_state' to 'to_state' is valid
static func can_transition(from_state: State, to_state: State) -> bool:
	# Allow staying in same state
	if from_state == to_state:
		return true

	match from_state:
		State.IDLE:
			# From IDLE, can go to WAITING_INPUT or PLAYING
			return to_state == State.WAITING_INPUT or to_state == State.PLAYING

		State.WAITING_INPUT:
			# From WAITING_INPUT, can go to RECORDING or back to IDLE (cancel)
			return to_state == State.RECORDING or to_state == State.IDLE

		State.RECORDING:
			# From RECORDING, can only return to IDLE (finish recording)
			return to_state == State.IDLE

		State.PLAYING:
			# From PLAYING, can only return to IDLE (finish playback)
			return to_state == State.IDLE

		_:
			return false

## Get human-readable name for a state
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
