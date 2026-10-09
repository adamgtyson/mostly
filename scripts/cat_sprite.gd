extends Sprite2D

## The workshop cat's programmatic placeholder (EC-12a is OPEN: no art files).
##
## Session 7, ledger L5: the cat stopped rendering in windowed runs after the
## session-5 relocation, while every headless check stayed green. Diagnosis
## eliminated the scene data (byte-identical since session 2), the script
## lifecycle (in-tree test: visible, textured), the opening cutscene (never
## references the cat) and floor contrast (dark wood under a tan cat). The one
## path headless tests cannot reach is the windowed renderer's texture upload,
## and the one anomaly on it was the deprecated Image.create with FORMAT_RGB8 —
## a 24-bit, no-alpha format the GPU path has to convert. This build uses
## create_empty with RGBA8, the renderer's native format, and draws a bordered
## body with ears so a rendered cat is unmistakable from floor tiles at a
## glance. tests/test_placeholders_visible.gd now asserts the render-side facts
## permanently.

const BODY := Color(0.78, 0.59, 0.27)
const OUTLINE := Color(0.16, 0.12, 0.05)

func _ready() -> void:
	add_to_group("placeholder")
	texture = _build_placeholder()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _build_placeholder() -> ImageTexture:
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body: a bordered square, rows 4-15.
	for y: int in range(4, 16):
		for x: int in range(0, 16):
			var edge: bool = x == 0 or x == 15 or y == 4 or y == 15
			img.set_pixel(x, y, OUTLINE if edge else BODY)
	# Ears: two filled triangles above the body, so it reads as "cat
	# placeholder" rather than "stray tile".
	for ear_x: int in [2, 11]:
		for row: int in 4:
			for x: int in range(ear_x + (3 - row), ear_x + (3 - row) + 2 * row + 1):
				if x >= 0 and x < 16:
					img.set_pixel(x, row, OUTLINE if row < 2 else BODY)
	return ImageTexture.create_from_image(img)
