extends Panel

@onready var portrait: TextureRect = $Portrait
@onready var speaker_name: Label = $SpeakerName
@onready var dialogue_text: RichTextLabel = $DialogueText

var _placeholder_texture: ImageTexture

func _ready() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	img.fill(Color(0.3, 0.3, 0.5))
	_placeholder_texture = ImageTexture.create_from_image(img)
	portrait.texture = _placeholder_texture

	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	visible = false

func _on_dialogue_started() -> void:
	visible = true
	_display_line(DialogueManager.get_current_line())

func _on_dialogue_ended() -> void:
	visible = false

func _display_line(line: Dictionary) -> void:
	if line.is_empty():
		return
	speaker_name.text = line.get("speaker", "")
	dialogue_text.text = line.get("text", "")
	portrait.texture = _placeholder_texture

func _unhandled_input(event: InputEvent) -> void:
	if not DialogueManager.dialogue_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_Z or event.physical_keycode == KEY_ENTER:
			get_viewport().set_input_as_handled()
			DialogueManager.advance()
			if DialogueManager.dialogue_active:
				_display_line(DialogueManager.get_current_line())
