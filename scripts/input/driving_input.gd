class_name DrivingInput
extends Node
## Override get_command() for another driver, replay or a test double.

func get_command() -> DrivingCommand:
	return DrivingCommand.new()
