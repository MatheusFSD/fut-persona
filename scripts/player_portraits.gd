extends RefCounted
## Portrait identity belongs to the profile, never to a team side or lineup slot.
static var textures: Dictionary = {}

static func texture(profile: Resource) -> Texture2D:
	return _load(profile.retrato)

static func celebration(profile: Resource) -> Texture2D:
	return _load(profile.comemoracao)

static func _load(path: String) -> Texture2D:
	if path.is_empty(): return null
	if textures.has(path): return textures[path]
	var result: Texture2D
	if ResourceLoader.exists(path,"Texture2D"):
		result = load(path) as Texture2D
	if result == null and FileAccess.file_exists(path):
		# Newly supplied art also works before the editor's first import.
		var source := Image.load_from_file(path)
		if source != null and not source.is_empty(): result = ImageTexture.create_from_image(source)
	textures[path] = result
	return result

static func source_rect(profile: Resource, image_size: Vector2, frame_size: Vector2) -> Rect2:
	var normalized: Rect2 = profile.retrato_regiao
	var source := Rect2(normalized.position*image_size,normalized.size*image_size)
	if frame_size.x <= 0 or frame_size.y <= 0: return source
	# Cover the frame without stretching the face or changing the original bitmap.
	var ratio := frame_size.x/frame_size.y
	if source.size.x/source.size.y > ratio:
		var width := source.size.y*ratio
		source.position.x += (source.size.x-width)*.5; source.size.x = width
	else:
		var height := source.size.x/ratio
		source.position.y += (source.size.y-height)*.5; source.size.y = height
	return source
