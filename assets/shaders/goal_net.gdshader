shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec4 net_color : source_color = vec4(0.87, 0.88, 0.80, 1.0);
uniform int impact_count = 0;
// xyz: contact on the resting net, w: scaled age. No TIME: pause and slow motion agree with physics.
uniform vec4 impacts[4];
// x: amplitude, y: panel (0 / .5 / 1), z: radius.
uniform vec4 pulses[4];
uniform float wave_speed = 8.0;
uniform float frequency = 19.0;
uniform float damping = 3.8;

void vertex() {
	float displacement = 0.0;
	for (int i = 0; i < 4; i++) {
		if (i >= impact_count) { break; }
		if (abs(COLOR.a - pulses[i].y) > 0.1) { continue; }
		float distance_to_hit = distance(VERTEX, impacts[i].xyz);
		float time = impacts[i].w - distance_to_hit / wave_speed;
		if (time <= 0.0) { continue; }
		float radius = pulses[i].z;
		float local_weight = exp(-distance_to_hit * distance_to_hit / (radius * radius));
		float fade = 1.0 - smoothstep(1.3, 1.7, impacts[i].w);
		displacement += pulses[i].x * local_weight * exp(-damping * time) * sin(frequency * time) * fade;
	}
	// R stores the anchor mask; A selects a panel and its outward direction.
	vec3 direction = COLOR.a < 0.25 ? vec3(1.0,0.0,0.0) : (COLOR.a < 0.75 ? vec3(0.0,0.0,-1.0) : vec3(0.0,0.0,1.0));
	VERTEX += direction * clamp(displacement, -0.28, 0.75) * COLOR.r;
}

void fragment() {
	ALBEDO = net_color.rgb;
}
