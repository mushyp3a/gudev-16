extends Node




var completed_levels: int = 0


func complete_level(level_num: int) -> void:
	if level_num < 1 or level_num > 4:
		push_error("Invalid level number: %d. Must be 1-4" % level_num)
		return

	var bit_index = level_num - 1
	completed_levels |= (1 << bit_index)

	print("Level %d completed! Progress: %s" % [level_num, get_completion_string()])


func is_level_completed(level_num: int) -> bool:
	if level_num < 1 or level_num > 4:
		return false

	var bit_index = level_num - 1
	return (completed_levels & (1 << bit_index)) != 0


func get_completed_count() -> int:
	var count = 0
	for i in range(4):
		if (completed_levels & (1 << i)) != 0:
			count += 1
	return count


func get_completion_string() -> String:
	var result = ""
	for i in range(1, 5):
		result += "[X]" if is_level_completed(i) else "[ ]"
	return result


func reset_progress() -> void:
	completed_levels = 0
	print("Progress reset!")
