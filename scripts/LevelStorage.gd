class_name LevelStorage extends RefCounted
## 레벨 JSON 저장소 — {dir}/{id}.json
## id 는 [A-Za-z0-9_-] 만 허용 (업로드 레벨 수신 시 경로 조작 방지).

const DEFAULT_DIR := "user://levels"

var dir: String

static var _id_re := RegEx.create_from_string("^[A-Za-z0-9_-]{1,64}$")

func _init(d: String = DEFAULT_DIR) -> void:
	dir = d

## 생성순 정렬되는 id: {unix ms}_{4자리 난수}
static func new_id() -> String:
	var ms := int(Time.get_unix_time_from_system() * 1000.0)
	return "%d_%04d" % [ms, randi() % 10000]

static func is_valid_id(id: String) -> bool:
	return _id_re.search(id) != null

## id 가 비어 있으면 새로 발급해 level.id 에 채운다.
func save(level: LevelData) -> Error:
	if level.id == "":
		level.id = new_id()
	if not is_valid_id(level.id):
		return ERR_INVALID_PARAMETER
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK:
		return err
	var f := FileAccess.open(_path(level.id), FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(level.to_dict(), "\t"))
	f.close()
	return OK

## 없거나 깨진 파일이면 null
func load_level(id: String) -> LevelData:
	if not is_valid_id(id):
		return null
	return _read(_path(id))

## 최신순 (id 내림차순). 깨진 파일은 건너뛴다.
func list() -> Array[LevelData]:
	var result: Array[LevelData] = []
	if not DirAccess.dir_exists_absolute(dir):
		return result
	var files := DirAccess.get_files_at(dir)
	files.sort()
	files.reverse()
	for f in files:
		if not f.ends_with(".json"):
			continue
		var level := _read(dir + "/" + f)
		if level != null:
			result.append(level)
	return result

func delete(id: String) -> Error:
	if not is_valid_id(id):
		return ERR_INVALID_PARAMETER
	return DirAccess.remove_absolute(_path(id))

func _path(id: String) -> String:
	return "%s/%s.json" % [dir, id]

func _read(path: String) -> LevelData:
	if not FileAccess.file_exists(path):
		return null
	# JSON.parse_string 은 실패 시 엔진 에러 로그를 남기므로 인스턴스 파서 사용
	var json := JSON.new()
	var data = json.data if json.parse(FileAccess.get_file_as_string(path)) == OK else null
	if not data is Dictionary:
		push_warning("레벨 파일 파싱 실패: " + path)
		return null
	return LevelData.from_dict(data)
