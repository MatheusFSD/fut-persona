extends RefCounted
## Small original pixel flags, generated once and reused by menus and the HUD.
const IDS := ["brasil","argentina","alemanha","franca"]
static var textures: Dictionary = {}

static func texture(id: String) -> Texture2D:
	if textures.has(id): return textures[id]
	var image := Image.create(64,40,false,Image.FORMAT_RGBA8)
	for y in 40:
		for x in 64:
			var color := Color("24243d")
			match id:
				"brasil":
					color = Color("168449")
					if absf((x-31.5)/26.0)+absf((y-19.5)/16.0) <= 1.0: color = Color("ffe349")
					var local := Vector2(x-31.5,y-19.5)
					if local.length() < 10:
						color = Color("203a9d")
						if absf(local.y-local.x*.18+1.0) < 1.1: color = Color("fff8e7")
						if y in [22,25] and x in [29,33,36]: color = Color("fff8e7")
				"argentina":
					color = Color("80c9ed") if y < 13 or y > 26 else Color("fff8ec")
					var local := Vector2(x-31.5,y-19.5)
					if local.length() < 3.1 or (local.length() < 5.5 and absf(sin(local.angle()*8)) < .25): color = Color("e9aa32")
				"alemanha": color = Color("14121c") if y < 13 else (Color("e43843") if y < 27 else Color("ffcf3d"))
				"franca": color = Color("2049a0") if x < 21 else (Color("fff8ec") if x < 43 else Color("f13d50"))
				_:
					if abs(x-32) < 2 or abs(y-20) < 2: color = Color("fff8ec")
			image.set_pixel(x,y,color)
	var result := ImageTexture.create_from_image(image)
	textures[id] = result
	return result
