# Test of some math

func test_value_converter():
	var result = BlocksCommon.get_value(1)
	return TestReference.assert_equal(result, 2, "Value for index 1 is 2")

func test_initial_scale():
	var result = BlocksCommon.get_scale(2)
	return TestReference.assert_equal(result, 1, "Initial scale shall be 1")

func test_max_scale():
	var result = BlocksCommon.get_scale(2000000000)
	return TestReference.assert_equal(result, 3.18, "Max scale shall be 3.18")

# Rename to test_scale_math to enable this function
func _scale_math():
	for k in [1, 10, 20, 30]:
		var value = BlocksCommon.get_value(k)
		#print("Value: %17d, Scale %2.5f" % [value, BlocksCommon.get_scale(value)])
	return true
