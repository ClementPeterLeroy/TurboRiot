extends RefCounted
## Later authorized audio integration supersedes only these five code hashes;
## historical City fixtures and all geometry/physics expectations stay intact.
static var _approved := {}
static func expected_hash(path: String, previous: String) -> String:
	if _approved.is_empty():
		var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/music_update.json"))
		_approved=fixture.approved_code_hashes
	return _approved.get(path,previous)
