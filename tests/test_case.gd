class_name TestCase
extends RefCounted
## Base class for unit tests in tests/unit/test_*.gd. Every method starting with `test_` is run.
## Tests may `await` (e.g. process frames); `tree` gives access to the SceneTree.

var failures: PackedStringArray = []
var current_test := ""
var tree: SceneTree


## Called before each test method.
func before_each() -> void:
	pass


## Called after each test method.
func after_each() -> void:
	pass


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_fail("expected true. " + message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		_fail("expected false. " + message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) and not (_is_number(actual) and _is_number(expected)):
		_fail("expected %s (%s), got %s (%s). %s" % [str(expected), type_string(typeof(expected)), str(actual), type_string(typeof(actual)), message])
	elif actual != expected:
		_fail("expected %s, got %s. %s" % [str(expected), str(actual), message])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if actual == unexpected:
		_fail("did not expect %s. %s" % [str(unexpected), message])


func assert_between(value: float, low: float, high: float, message: String = "") -> void:
	if value < low or value > high:
		_fail("expected %s to be within [%s, %s]. %s" % [str(value), str(low), str(high), message])


func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		_fail("expected a value, got null. " + message)


func fail(message: String) -> void:
	_fail(message)


func _fail(message: String) -> void:
	failures.append("%s: %s" % [current_test, message.strip_edges()])


static func _is_number(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT
