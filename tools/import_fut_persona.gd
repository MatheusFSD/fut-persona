extends SceneTree
## Copies the portraits and goal celebrations from fut_persona_todas_imagens_aprovadas.zip
## into assets/portraits/, reduced to the size the screen uses. Expressions stay out:
## they belong to the future visual novel. Usage:
## godot --headless --path . --script res://tools/import_fut_persona.gd -- <zip path>
const PORTRAIT_SIZE := 512
const CELEBRATION_SIZE := 768
const FOLDERS := {"retratos":PORTRAIT_SIZE,"comemoracoes":CELEBRATION_SIZE}
const TEAMS := ["brasil","argentina","alemanha","franca"]

func _initialize() -> void:
	var zip_path := "../fut_persona_todas_imagens_aprovadas.zip"
	if not OS.get_cmdline_user_args().is_empty(): zip_path = OS.get_cmdline_user_args()[0]
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		push_error("Cannot open "+zip_path); quit(1); return
	var written := 0
	for entry in reader.get_files():
		var parts := entry.split("/")
		if parts.size() != 3 or parts[0] not in TEAMS or not FOLDERS.has(parts[1]): continue
		var image := Image.new()
		if image.load_png_from_buffer(reader.read_file(entry)) != OK:
			push_error("Bad image "+entry); quit(1); return
		# Transparent pixels hold no color; without this the edges darken when reduced.
		image.fix_alpha_edges()
		image.resize(FOLDERS[parts[1]],FOLDERS[parts[1]],Image.INTERPOLATE_LANCZOS)
		var folder := "res://assets/portraits/"+parts[0]+("/" if parts[1] == "retratos" else "/comemoracoes/")
		DirAccess.make_dir_recursive_absolute(folder)
		image.save_png(folder+parts[2])
		_write_import(folder+parts[2])
		written += 1
	reader.close()
	print("IMPORT_FUT_PERSONA wrote ",written," images")
	quit(0 if written == 40 else 1)

# The HUD shows the same art at many sizes, so it needs mipmaps to stay sharp when small.
func _write_import(path: String) -> void:
	var file := FileAccess.open(path+".import",FileAccess.WRITE)
	file.store_string('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[deps]\n\nsource_file="%s"\n\n[params]\n\ncompress/mode=0\nmipmaps/generate=true\nmipmaps/limit=-1\nprocess/fix_alpha_border=true\nprocess/size_limit=0\ndetect_3d/compress_to=1\n' % path)
