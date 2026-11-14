extends SceneTree
const SHAPES = preload("res://scripts/ui_shapes.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)

# draw_colored_polygon refuses polygons that cross themselves.
func drawable(points: PackedVector2Array) -> bool:
	return points.size() >= 3 and not Geometry2D.triangulate_polygon(points).is_empty()

func parallel(a: Vector2, b: Vector2) -> bool:
	return absf(a.normalized().cross(b.normalized())) < .012

func run() -> void:
	var sizes := [Vector2(44,36),Vector2(80,30),Vector2(205,36),Vector2(368,104),Vector2(592,428),Vector2(1760,236),Vector2(26,26)]
	var bad_torn := 0; var bad_burst := 0; var bad_balloon := 0; var parallelograms := 0; var tested := 0
	for size: Vector2 in sizes:
		for seed_value in 400:
			var rect := Rect2(Vector2(-size.x*.5,10),size)
			var bite := minf(size.y*.3,34.0)
			var panel := SHAPES.torn(rect,seed_value,bite)
			if not drawable(panel): bad_torn += 1
			# The complaint that started this: a panel must never be a parallelogram.
			if panel.size() == 4 and parallel(panel[1]-panel[0],panel[2]-panel[3]) and parallel(panel[2]-panel[1],panel[3]-panel[0]): parallelograms += 1
			if not drawable(SHAPES.burst(rect.get_center(),size*.5,8+seed_value%9,seed_value,.5+(seed_value%5)*.05)): bad_burst += 1
			var angle := seed_value*.37
			# Far enough to clear the corners of the rounded box, as the HUD guarantees.
			var tip := rect.get_center()+Vector2.from_angle(angle)*(size*.72+Vector2.ONE*(30+seed_value%60))
			if not drawable(SHAPES.balloon(rect,tip,seed_value)): bad_balloon += 1
			tested += 1
	check(tested == 2800 and bad_torn == 0,"torn panels are drawable at every size: "+str(bad_torn))
	check(bad_burst == 0,"bursts are drawable at every size: "+str(bad_burst))
	check(bad_balloon == 0,"balloons with a tail in any direction are drawable: "+str(bad_balloon))
	check(parallelograms == 0,"no panel is a parallelogram: "+str(parallelograms))
	var panel := SHAPES.torn(Rect2(0,0,300,100),5,14)
	check(panel == SHAPES.torn(Rect2(0,0,300,100),5,14),"same seed keeps the same silhouette between frames")
	check(panel != SHAPES.torn(Rect2(0,0,300,100),6,14),"different seeds give different silhouettes")
	var tip := Vector2(400,300)
	check(SHAPES.balloon(Rect2(0,0,240,74),tip,3).has(tip),"balloon tail ends exactly at the point it speaks about")
	var bar := SHAPES.wedge(Vector2.ZERO,200,2,10)
	check(not parallel(bar[1]-bar[0],bar[2]-bar[3]),"bars taper instead of keeping parallel sides")
	for shape in [SHAPES.star(Vector2.ZERO,10),SHAPES.heart(Vector2.ZERO,10),SHAPES.pipa(Vector2.ZERO,10,.4),SHAPES.sugarloaf(Vector2.ZERO,500,200),SHAPES.shard(Vector2.ZERO,Vector2(10,4),3)]:
		check(drawable(shape),"motif is drawable")
	print("UI_SHAPES ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
