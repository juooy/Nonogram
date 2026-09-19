extends RefCounted
## 테스트 베이스. tests/test_*.gd 는 이 스크립트를 extends 하고 test_* 메서드를 정의한다.

var tree: SceneTree
var failures: Array[String] = []
var _nodes: Array[Node] = []

## 트리에 붙여 _ready 를 실행시키고, 테스트 종료 시 자동 해제한다.
func add_node(node: Node) -> Node:
	tree.root.add_child(node)
	_nodes.append(node)
	return node

func cleanup() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()

func assert_eq(actual, expected, msg: String = "") -> void:
	if not _same(actual, expected):
		failures.append("%s expected=%s actual=%s" % [msg, str(expected), str(actual)])

func assert_true(cond: bool, msg: String = "") -> void:
	if not cond:
		failures.append("%s expected true" % msg)

## 타입까지 비교한다 (1 과 1.0 을 다르게 본다 — JSON 왕복 시 int→float 변환 검출용).
func _same(a, b) -> bool:
	if typeof(a) != typeof(b):
		return false
	if a is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not _same(a[i], b[i]):
				return false
		return true
	return a == b
