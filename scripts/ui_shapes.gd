extends RefCounted
## Cut-paper geometry for the HUD: torn panels, bursts, speech balloons and Rio motifs.
## Pure functions of their inputs, so a shape keeps its silhouette from frame to frame.

# Stable pseudo-random value in -1..1 for a seed and an index.
static func noise(seed_value: int, index: int) -> float:
	var x := sin(float(seed_value)*12.9898+float(index)*78.233)*43758.5453
	return (x-floorf(x))*2.0-1.0

## A panel with no two parallel sides: skewed corners, sharp bites and one stepped edge.
static func torn(rect: Rect2, seed_value := 0, bite := 16.0) -> PackedVector2Array:
	var p := rect.position; var s := rect.size
	var skew := minf(bite*1.6,minf(s.x,s.y)*.28)
	var corners := [
		p+Vector2(noise(seed_value,0)*skew,noise(seed_value,1)*skew*.6),
		p+Vector2(s.x+noise(seed_value,2)*skew,noise(seed_value,3)*skew*.6),
		p+s+Vector2(noise(seed_value,4)*skew,noise(seed_value,5)*skew*.6),
		p+Vector2(noise(seed_value,6)*skew,s.y+noise(seed_value,7)*skew*.6)]
	# Tiny tiles have no room for bites, so they must already differ in their corners.
	var top: Vector2 = corners[1]-corners[0]; var low: Vector2 = corners[2]-corners[3]
	if absf(top.normalized().cross(low.normalized())) < .015: corners[2] += Vector2(skew*.3,skew*.5)
	var points := PackedVector2Array()
	for side in 4:
		var a: Vector2 = corners[side]; var b: Vector2 = corners[(side+1)%4]
		points.append(a)
		var length := a.distance_to(b)
		var inward := (b-a).normalized().orthogonal()
		var depth := minf(bite,minf(s.x,s.y)*.2)
		var kind := int(absf(noise(seed_value,10+side))*3.0)
		var at := .25+absf(noise(seed_value,20+side))*.5
		var width := minf(depth*1.6,length*.16)
		if length < depth*5: continue
		if kind == 0:
			# A triangular bite out of the edge.
			points.append(a.lerp(b,at-width/length))
			points.append(a.lerp(b,at)+inward*depth)
			points.append(a.lerp(b,at+width/length))
		elif kind == 1:
			# A stair: the rest of the edge continues further out.
			points.append(a.lerp(b,at))
			points.append(a.lerp(b,at+width*.4/length)-inward*depth*.8)
		else:
			# A small spike out of the edge.
			points.append(a.lerp(b,at-width/length))
			points.append(a.lerp(b,at)-inward*depth*.9)
			points.append(a.lerp(b,at+width*.3/length))
	return points

## An irregular explosion. Star-shaped around its center, so it is always a simple polygon.
static func burst(center: Vector2, radius: Vector2, spikes := 11, seed_value := 0, depth := .52) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in spikes:
		var step := TAU/spikes
		var angle := i*step+noise(seed_value,i)*step*.22
		var reach := 1.0+noise(seed_value,i+40)*.2
		points.append(center+Vector2.from_angle(angle)*radius*reach)
		var valley := angle+step*(.5+noise(seed_value,i+80)*.1)
		points.append(center+Vector2.from_angle(valley)*radius*depth*(1.0+noise(seed_value,i+120)*.12))
	return points

## A hand-cut oval with a lightning tail ending exactly at the tip.
static func balloon(rect: Rect2, tip: Vector2, seed_value := 0, sides := 14) -> PackedVector2Array:
	var center := rect.get_center(); var radius := rect.size*.5
	var ring := PackedVector2Array()
	for i in sides:
		var angle := i*TAU/sides
		var sample := Vector2(cos(angle),sin(angle))
		# Superellipse: long flat sides with tight corners, closer to cut paper than an oval.
		var shape := Vector2(signf(sample.x)*pow(absf(sample.x),.72),signf(sample.y)*pow(absf(sample.y),.72))
		ring.append(center+shape*radius*(1.0+noise(seed_value,i)*.045))
	# The tail leaves through the side nearest the tip, so it can never cross the body.
	var gap := 0; var nearest := INF
	for i in sides:
		var distance := ring[i].lerp(ring[(i+1)%sides],.5).distance_squared_to(tip)
		if distance < nearest: nearest = distance; gap = i
	var points := PackedVector2Array()
	for i in sides: points.append(ring[(gap+1+i)%sides])
	var first: Vector2 = points[0]; var last: Vector2 = points[sides-1]
	var base := first.lerp(last,.5)
	var along := tip-base
	var normal := along.normalized().orthogonal()
	var width := clampf(first.distance_to(last)*.5,14,minf(40,along.length()*.42))
	var side := 1.0 if (first-base).dot(normal) >= 0 else -1.0
	# The bolt steps back once on each side; `first` is on the +side of the tail.
	points.append(base+along*.48-normal*side*width*.95)
	points.append(base+along*.34-normal*side*width*.34)
	points.append(tip)
	points.append(base+along*.62+normal*side*width*.20)
	points.append(base+along*.46+normal*side*width*.95)
	return points

static func star(center: Vector2, radius: float, rotation_value := 0.0, inner := .42) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var reach := radius if i%2 == 0 else radius*inner
		points.append(center+Vector2.from_angle(rotation_value-PI*.5+i*TAU/10.0)*reach)
	return points

static func heart(center: Vector2, size: float, rotation_value := 0.0) -> PackedVector2Array:
	var profile := [Vector2(0,1),Vector2(-.62,.3),Vector2(-1,-.2),Vector2(-.82,-.72),Vector2(-.36,-.86),Vector2(0,-.42),Vector2(.36,-.86),Vector2(.82,-.72),Vector2(1,-.2),Vector2(.62,.3)]
	var points := PackedVector2Array()
	for sample: Vector2 in profile: points.append(center+(sample*size).rotated(rotation_value))
	return points

## Long thin triangle: the wedge that replaces parallel bars and rules.
static func shard(from: Vector2, to: Vector2, width: float) -> PackedVector2Array:
	var normal := (to-from).normalized().orthogonal()*width*.5
	return PackedVector2Array([from+normal,to,from-normal])

## A bar that grows thicker along its length and ends in a slanted cut.
static func wedge(from: Vector2, length: float, thin: float, thick: float, cut := 8.0) -> PackedVector2Array:
	return PackedVector2Array([from+Vector2(cut,-thin),from+Vector2(length+cut,-thick),from+Vector2(length,thick*.35),from+Vector2(0,thin*.35)])

## Diamond of a pipa (kite), the tail is drawn separately because it moves with the wind.
static func pipa(center: Vector2, size: float, rotation_value := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(0,-size),Vector2(size*.72,-size*.18),Vector2(0,size*1.05),Vector2(-size*.72,-size*.18)])
	for i in points.size(): points[i] = center+points[i].rotated(rotation_value)
	return points

## Sugarloaf skyline: Pão de Açúcar, Urca and the low hill by the water.
static func sugarloaf(base: Vector2, width: float, height: float) -> PackedVector2Array:
	var profile := [[0,0],[.08,.16],[.16,.22],[.24,.42],[.29,.5],[.34,.46],[.40,.3],[.46,.24],[.52,.34],[.58,.74],[.63,.96],[.67,1.0],[.71,.94],[.76,.62],[.82,.3],[.9,.14],[1,0]]
	var points := PackedVector2Array()
	for sample in profile: points.append(base+Vector2(sample[0]*width,-sample[1]*height))
	return points

## Points of one Copacabana sidewalk wave.
static func calcadao(from: Vector2, to_x: float, amplitude: float, wavelength: float, phase := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	var x := from.x
	while x <= to_x+wavelength*.1:
		points.append(Vector2(x,from.y+sin((x+phase)/wavelength*TAU)*amplitude))
		x += wavelength*.1
	return points
