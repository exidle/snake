# test_runner.gd
class_name TestReference
extends Node

@onready var test_is_done: bool = false

func _ready():
	# Call a function to run all tests
	run_tests()
	get_tree().quit()
	#await get_tree().create_timer(0.5).timeout
	#test_is_done = true

func _process(_delta: float) -> void:
	if test_is_done:
		get_tree().quit()

func run_tests():
	var test_files = [
		 # Add your test files here
		"res://tests/test_common_blocks_math.gd" 
	]

	var all_passed = true
	for test_file in test_files:
		var test_script = load(test_file).new()
		if not run_test_case(test_script):
			all_passed = false

	if all_passed:
		print("All tests passed!")
	else:
		print("Some tests failed.")

func run_test_case(test_instance):
	var passed = true
	for method_name in test_instance.get_method_list():
		if method_name.name.begins_with("test_"):
			var result = test_instance.call(method_name.name)
			if result != true:
				passed = false
				print("Test failed: ", method_name.name)
	return passed

static func assert_equal(actual, expected, test_name: String):
	if actual != expected:
		print("Test failed: ", test_name, " - Expected ", expected, ", got ", actual)
		return false
	return true
