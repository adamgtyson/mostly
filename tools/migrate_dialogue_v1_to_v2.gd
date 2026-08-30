extends SceneTree

## One-shot migration of the v1 flat dialogue files to schema v2 (§5):
##   godot --headless --path . -s tools/migrate_dialogue_v1_to_v2.gd
##
## v1  { "id", "lines": [{speaker: "Patch", portrait, text}] }
## v2  { "id", "entries": [{"when": "true", "start": "start"}],
##       "nodes": { "start": { "lines": [{speaker: "patch", portrait, text}] } } }
##
## Speaker display names become character ids resolved through
## data/characters.json. A portrait equal to the character's default is dropped,
## since resolve_line() fills it in — the rendered line is unchanged either way.
##
## Idempotent: a file already carrying "nodes" is left alone, so re-running is
## safe. Pass --dry-run to report without writing.

const DIALOGUE_DIR := "res://data/dialogue"
const CHARACTERS_PATH := "res://data/characters.json"

func _initialize() -> void:
	var dry_run: bool = OS.get_cmdline_user_args().has("--dry-run")
	var characters: Dictionary = _load_characters()
	var by_display: Dictionary = {}
	for id: String in characters:
		by_display[str(characters[id].get("display_name", id))] = id

	var dir := DirAccess.open(DIALOGUE_DIR)
	if dir == null:
		push_error("migrate: cannot open %s" % DIALOGUE_DIR)
		quit(1)
		return

	var migrated: int = 0
	var skipped: int = 0
	var failed: int = 0

	var files: PackedStringArray = dir.get_files()
	files.sort()
	for file_name: String in files:
		if not file_name.ends_with(".json"):
			continue
		var path: String = "%s/%s" % [DIALOGUE_DIR, file_name]
		var data: Variant = _read_json(path)
		if not (data is Dictionary):
			print("FAIL  %s: unreadable" % file_name)
			failed += 1
			continue
		var document: Dictionary = data
		if document.has("nodes"):
			print("skip  %s (already v2)" % file_name)
			skipped += 1
			continue
		var converted: Dictionary = _convert(document, by_display, characters)
		if converted.is_empty():
			print("FAIL  %s: could not convert" % file_name)
			failed += 1
			continue
		if dry_run:
			print("would migrate  %s (%d lines)" % [file_name, converted["nodes"]["start"]["lines"].size()])
		else:
			if not _write_json(path, converted):
				failed += 1
				continue
			print("ok    %s (%d lines)" % [file_name, converted["nodes"]["start"]["lines"].size()])
		migrated += 1

	print("")
	print("migrated %d, skipped %d, failed %d" % [migrated, skipped, failed])
	quit(1 if failed > 0 else 0)

func _convert(document: Dictionary, by_display: Dictionary, characters: Dictionary) -> Dictionary:
	var lines: Variant = document.get("lines", [])
	if not (lines is Array) or (lines as Array).is_empty():
		return {}
	var converted_lines: Array = []
	for line: Variant in lines:
		if not (line is Dictionary):
			return {}
		var l: Dictionary = line
		var display: String = str(l.get("speaker", ""))
		var speaker_id: String = str(by_display.get(display, display))
		if not characters.has(speaker_id):
			push_error("migrate: speaker '%s' has no entry in characters.json" % display)
			return {}

		var out_line: Dictionary = {"speaker": speaker_id, "text": str(l.get("text", ""))}
		var portrait: String = str(l.get("portrait", ""))
		var default_portrait: String = str(characters[speaker_id].get("default_portrait", ""))
		if not portrait.is_empty() and portrait != default_portrait:
			out_line["portrait"] = portrait
		converted_lines.append(out_line)

	return {
		"id": str(document.get("id", "")),
		"entries": [{"when": "true", "start": "start"}],
		"nodes": {"start": {"lines": converted_lines}},
	}

func _load_characters() -> Dictionary:
	var data: Variant = _read_json(CHARACTERS_PATH)
	if not (data is Dictionary):
		return {}
	var characters: Variant = (data as Dictionary).get("characters", {})
	return characters if characters is Dictionary else {}

func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return null
	return json.get_data()

func _write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("migrate: cannot write %s" % path)
		return false
	file.store_string(JSON.stringify(data, "  ") + "\n")
	file.close()
	return true
