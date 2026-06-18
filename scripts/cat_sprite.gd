extends Sprite2D

func _ready() -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
	img.fill(Color(0.78, 0.59, 0.27))
	texture = ImageTexture.create_from_image(img)
