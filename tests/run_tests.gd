extends SceneTree
## 헤드리스 테스트 러너. 실행: tools/test.sh
## res://tests/test_*.gd 의 test_* 메서드를 모두 실행하고, 실패가 있으면 exit code 1.

const TEST_DIR := "res://tests"

var _started := false

# _initialize 시점엔 root 에 붙인 노드의 _ready 가 호출되지 않으므로 첫 프레임에서 실행
func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false

func _run() -> void:
	var passed := 0
	var failed := 0
	for path in _find_tests():
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			print("FAIL %s (로드 실패)" % path)
			failed += 1
			continue
		for m in script.get_script_method_list():
			var name: String = m.name
			if not name.begins_with("test_"):
				continue
			var t = script.new()
			t.tree = self
			t.call(name)
			t.cleanup()
			if t.failures.is_empty():
				passed += 1
			else:
				failed += 1
				print("FAIL %s::%s" % [path.get_file(), name])
				for f in t.failures:
					print("     - " + f)
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _find_tests() -> Array[String]:
	var result: Array[String] = []
	for f in DirAccess.get_files_at(TEST_DIR):
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
			result.append(TEST_DIR + "/" + f)
	result.sort()
	return result
