extends Control

## New Game screen (BUILD_PLAN §8 phase 3, content-free slice). Two steps:
## Patch's gender, then the starting village. Data-driven: the nine villages
## come from data/villages/*.json, their text verbatim from Docs/03, so a
## wording change is a data edit, never a scene edit.
##
## What confirm applies is exactly the village file's starting state —
## starting_flags (sys.village at minimum) and starting_items (empty until the
## writing list lands) — plus sys.patch_gender from step one and the
## starting-region unlock a new run needs before SceneRouter will move at all.
## No pro/con mechanic lives here; this screen only records the choice.
##
## Keyboard/gamepad: everything is focused Buttons in containers, so arrows
## move focus and ui_accept activates — no mouse, no custom input handling.
## All copy on this screen is functional placeholder text; real menu copy is
## BUILD_PLAN §4.12, still unwritten.

const VILLAGES_DIR := "res://data/villages"

## Selection-screen order, from the Docs/00 table.
const VILLAGE_ORDER: Array[String] = [
	"again",
	"revised",
	"temporary",
	"good_soil_probably",
	"seven_chickens",
	"one_more_mile",
	"fine_now",
	"hay_mostly",
	"new_again",
]

var _villages: Dictionary = {}
var _selected_village: String = ""

var _gender_step: CenterContainer = null
var _village_step: MarginContainer = null
var _village_buttons: VBoxContainer = null
var _detail_label: RichTextLabel = null
var _confirm_button: Button = null

func _ready() -> void:
	_villages = load_villages()
	_build_ui()
	_show_gender_step()

# ── data ─────────────────────────────────────────────────────────────────────

## id -> village Dictionary, every readable file under data/villages/.
func load_villages() -> Dictionary:
	var found: Dictionary = {}
	var dir := DirAccess.open(VILLAGES_DIR)
	if dir == null:
		push_error("NewGame: cannot open %s" % VILLAGES_DIR)
		return found
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var file := FileAccess.open("%s/%s" % [VILLAGES_DIR, file_name], FileAccess.READ)
		if file == null:
			continue
		var json := JSON.new()
		var err := json.parse(file.get_as_text())
		file.close()
		if err != OK or not (json.get_data() is Dictionary):
			push_error("NewGame: malformed village file %s" % file_name)
			continue
		var village: Dictionary = json.get_data()
		found[str(village.get("id", file_name.get_basename()))] = village
	return found

func village_ids_in_order() -> Array[String]:
	var ordered: Array[String] = []
	for id_value: String in VILLAGE_ORDER:
		if _villages.has(id_value):
			ordered.append(id_value)
	# Anything the order list does not know lands at the end rather than
	# vanishing — the validator polices the canonical nine separately.
	for id_value: Variant in _villages:
		if not ordered.has(str(id_value)):
			ordered.append(str(id_value))
	return ordered

# ── step 1: gender ───────────────────────────────────────────────────────────

## 'm' or 'f' (sys.patch_gender [U2-7]); anything else is refused.
func choose_gender(code: String) -> bool:
	if code != "m" and code != "f":
		push_error("NewGame: gender code must be 'm' or 'f', got '%s'" % code)
		return false
	var state: Node = _game_state()
	if state != null:
		state.call("set_flag", "sys.patch_gender", code)
	_show_village_step()
	return true

# ── step 2: village ──────────────────────────────────────────────────────────

## Focusing or pressing a village button lands here: show its selection-screen
## text. Seven Chickens shows pro_text — the Docs/03 obfuscated wording — and
## never pro_text_hidden; spoiler protection is the data's rule, kept here.
func select_village(id_value: String) -> void:
	if not _villages.has(id_value):
		push_error("NewGame: unknown village '%s'" % id_value)
		return
	_selected_village = id_value
	if _detail_label != null:
		_detail_label.text = detail_text(_villages[id_value])
	if _confirm_button != null:
		_confirm_button.disabled = false

func selected_village() -> String:
	return _selected_village

func detail_text(village: Dictionary) -> String:
	return "[i]%s[/i]\n\nPro: %s\n\nCon: %s" % [
		str(village.get("epigraph", "")),
		str(village.get("pro_text", "")),
		str(village.get("con_text", "")),
	]

## Applies the choice and departs. Returns the destination it routes to, empty
## on refusal. `depart` is a test seam: the suite drives everything up to the
## actual transition, because travelling would start the opening cutscene in
## the middle of a test run.
func confirm_village(id_value: String, depart: bool = true) -> Dictionary:
	if not _villages.has(id_value):
		push_error("NewGame: cannot confirm unknown village '%s'" % id_value)
		return {}
	var village: Dictionary = _villages[id_value]
	var state: Node = _game_state()
	if state != null:
		var starting_flags: Variant = village.get("starting_flags", {})
		if starting_flags is Dictionary:
			for flag: Variant in (starting_flags as Dictionary):
				state.call("set_flag", str(flag), (starting_flags as Dictionary)[flag])

	var root_node: Node = get_tree().root
	if root_node.has_node("Inventory"):
		for item: Variant in village.get("starting_items", []):
			root_node.get_node("Inventory").call("add_item", str(item))

	if not root_node.has_node("SceneRouter"):
		push_error("NewGame: no SceneRouter to depart with")
		return {}
	var router: Node = root_node.get_node("SceneRouter")
	# A new run must be able to reach its starting region (§6); without this,
	# go_to refuses the very first move.
	router.call("new_game")
	var destination: Dictionary = {
		"region": str(router.call("starting_region")),
		"area": str(router.call("starting_area")),
		"spawn": str(router.call("starting_spawn")),
	}
	if depart:
		router.call("go_to", destination["region"], destination["area"], destination["spawn"])
	return destination

# ── UI (session 10: 320x180 canvas space, containers own all placement) ────

## Everything lives inside Rect2(0, 0, 320, 180); fonts and styles come from
## ui/ui_theme.tres on the scene root, sized like the dialogue box (font 8).
## Nine village names plus a detail panel do not fit 180px with room to spare,
## so the list is a ScrollContainer with follow_focus: arrowing through the
## buttons scrolls the list itself, which keeps the whole flow
## keyboard/gamepad-only with zero custom input code. No absolute positions —
## a container owns every placement.
func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_gender_step = CenterContainer.new()
	_gender_step.name = "GenderStep"
	_gender_step.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_gender_step)

	var options := VBoxContainer.new()
	options.name = "Options"
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	options.add_theme_constant_override("separation", 6)
	_gender_step.add_child(options)

	var title := Label.new()
	title.name = "Heading"
	title.text = "New Game"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options.add_child(title)

	var prompt := Label.new()
	prompt.name = "Prompt"
	prompt.text = "Patch is…"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options.add_child(prompt)

	for option: Array in [["Masculine", "m"], ["Feminine", "f"]]:
		var button := Button.new()
		button.text = str(option[0])
		button.name = "Gender_%s" % str(option[1])
		button.pressed.connect(choose_gender.bind(str(option[1])))
		options.add_child(button)

	_village_step = MarginContainer.new()
	_village_step.name = "VillageStep"
	_village_step.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		_village_step.add_theme_constant_override("margin_%s" % side, 4)
	_village_step.visible = false
	add_child(_village_step)

	var layout := HBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 4)
	_village_step.add_child(layout)

	var scroll := ScrollContainer.new()
	scroll.name = "VillageScroll"
	scroll.custom_minimum_size = Vector2(120, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	layout.add_child(scroll)

	_village_buttons = VBoxContainer.new()
	_village_buttons.name = "VillageButtons"
	_village_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_village_buttons)

	for id_value: String in village_ids_in_order():
		var village: Dictionary = _villages[id_value]
		var button := Button.new()
		button.text = str(village.get("display_name", id_value))
		button.name = "Village_%s" % id_value
		button.focus_entered.connect(select_village.bind(id_value))
		button.pressed.connect(_on_village_pressed.bind(id_value))
		_village_buttons.add_child(button)

	var right := VBoxContainer.new()
	right.name = "Detail"
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 4)
	layout.add_child(right)

	var panel := PanelContainer.new()
	panel.name = "DetailPanel"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(panel)

	_detail_label = RichTextLabel.new()
	_detail_label.name = "DetailText"
	_detail_label.bbcode_enabled = true
	# Long pro/con text scrolls inside the panel rather than growing the panel
	# past 180px — the dialogue box's approach, not fit_content.
	_detail_label.fit_content = false
	_detail_label.scroll_active = true
	panel.add_child(_detail_label)

	_confirm_button = Button.new()
	_confirm_button.name = "Confirm"
	_confirm_button.text = "Begin"
	_confirm_button.disabled = true
	_confirm_button.pressed.connect(_on_confirm_pressed)
	right.add_child(_confirm_button)

func _show_gender_step() -> void:
	if _gender_step == null:
		return
	_gender_step.visible = true
	_village_step.visible = false
	var first: Node = _gender_step.get_node_or_null("Options/Gender_m")
	if first is Button:
		(first as Button).grab_focus()

func _show_village_step() -> void:
	if _village_step == null:
		return
	_gender_step.visible = false
	_village_step.visible = true
	if _village_buttons != null and _village_buttons.get_child_count() > 0:
		var first: Node = _village_buttons.get_child(0)
		if first is Button:
			(first as Button).grab_focus()

func _on_village_pressed(id_value: String) -> void:
	select_village(id_value)
	if _confirm_button != null:
		_confirm_button.grab_focus()

func _on_confirm_pressed() -> void:
	if not _selected_village.is_empty():
		confirm_village(_selected_village)

func _game_state() -> Node:
	var root_node: Node = get_tree().root
	return root_node.get_node("GameState") if root_node.has_node("GameState") else null
