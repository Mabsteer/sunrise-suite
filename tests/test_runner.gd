extends Node
## Runs every tests/unit/test_*.gd and quits with exit code 0 (all passed) or 1.
## Filter with: bash tools/godot.sh --headless --path . res://tests/test_runner.tscn -- --filter=save

const TEST_DIR := "res://tests/unit/"


func _ready() -> void:
	SaveManager.persist = false
	get_tree().create_timer(300.0).timeout.connect(func() -> void:
		printerr("FAIL tests timed out")
		get_tree().quit(1))
	AudioManager.enabled = false
	_run.call_deferred()


func _run() -> void:
	var filter := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.trim_prefix("--filter=")
	var files: Array[String] = []
	for file in DirAccess.get_files_at(TEST_DIR):
		if file.begins_with("test_") and file.ends_with(".gd"):
			files.append(file)
	files.sort()
	var passed := 0
	var failed: PackedStringArray = []
	for file in files:
		var script := load(TEST_DIR + file) as GDScript
		if script == null:
			failed.append("%s: could not load" % file)
			continue
		var methods: Array[String] = []
		for m: Dictionary in script.get_script_method_list():
			var name: String = m["name"]
			if name.begins_with("test_") and not methods.has(name):
				methods.append(name)
		for method in methods:
			var label := "%s::%s" % [file.get_basename(), method]
			if filter != "" and not label.contains(filter):
				continue
			var test: TestCase = script.new()
			test.tree = get_tree()
			test.current_test = label
			test.before_each()
			await test.call(method)
			test.after_each()
			if test.failures.is_empty():
				passed += 1
			else:
				failed.append_array(test.failures)
	for f in failed:
		printerr("FAIL ", f)
	print("TESTS: %d passed, %d failed" % [passed, failed.size()])
	AudioManager.stop_all()
	await get_tree().process_frame
	get_tree().quit(0 if failed.is_empty() else 1)
