class_name BlocksCommon

static var palette = [Color.DARK_GRAY, Color.DARK_KHAKI, Color.CADET_BLUE, Color.CHOCOLATE,
Color.DARK_SLATE_GRAY, Color.DARK_TURQUOISE, Color.FOREST_GREEN, Color.GOLDENROD, Color.DARK_SLATE_BLUE, 
Color.DARK_SEA_GREEN, Color.HOT_PINK, Color.INDIAN_RED]

const BLOCK_SIZE = 120
const BLOCK_DISTANCE = 20

static func get_scale(value: int) -> float: 
	return clampf(pow(value - 1, 1.0 / 18.0), 1.0, 3.18)

static func get_color(value: int) -> Color:
	var p = get_inv_2_power(value)
	return palette[p % palette.size()]

static func get_inv_2_power(value: int) -> float:
	return log(value) / log(2)

static func get_value(index: int) -> int:
	return pow(2, index) as int
	
static func calc_distance_to_parent(scale: float, parent_scale: float) -> int:
	return 0.5 * BLOCK_SIZE * (scale + parent_scale) + BLOCK_DISTANCE as int

static func get_block_value_as_text(index: int) -> String:
	var number:int = BlocksCommon.get_value(index)
	var suffix = ""
	if index >= 10:
		suffix = "K"
		number /= 1024
	elif index >= 20:
		suffix = "M"
		number /= 1048576
	elif index >= 30:
		suffix = "T"
		number /= 1073741824
	return str(number) + suffix
