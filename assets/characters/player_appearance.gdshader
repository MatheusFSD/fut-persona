shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform sampler2D region_mask : filter_nearest, repeat_disable;
uniform vec4 skin_color : source_color = vec4(.72,.48,.32,1.0);
uniform vec4 hair_color : source_color = vec4(.07,.06,.05,1.0);
uniform vec4 shirt_color : source_color = vec4(.9,.6,.2,1.0);
uniform vec4 shorts_color : source_color = vec4(.08,.13,.18,1.0);
uniform vec4 socks_color : source_color = vec4(.9,.6,.2,1.0);
uniform vec4 trim_color : source_color = vec4(.94,.93,.84,1.0);
uniform int hair_type = 2;
uniform bool goalkeeper = false;
uniform vec4 secondary_color : source_color = vec4(.4,.7,.9,1.0);
uniform int shirt_pattern = 0;

void fragment() {
	vec4 mask = texture(region_mask,UV);
	int region = int(floor(mask.r*255.0+.5));
	float height = mask.g*1.8;
	float across = mask.b;
	float front = mask.a*.4-.2;
	vec3 color = skin_color.rgb;
	if (region == 2 || (region == 7 && goalkeeper)) {
		color = shirt_color.rgb;
		// Rest-space coordinates keep stripes stable across bodies and animations.
		if (!goalkeeper && across < .30) {
			if (shirt_pattern == 1 && mod(floor((across+.045)/.09),2.0) > .5) color = secondary_color.rgb;
			if (shirt_pattern == 2 && height > 1.23 && height < 1.38) color = secondary_color.rgb;
		}
		if (!goalkeeper && across > .37 && across < .40) color = trim_color.rgb;
	} else if (region == 9) {
		color = shirt_color.rgb*.92;
	} else if (region == 3) {
		color = shorts_color.rgb;
		if (height < .70) color = trim_color.rgb;
	} else if (region == 4) {
		color = socks_color.rgb;
		if (height > .335) color = trim_color.rgb;
	} else if (region == 5) {
		color = vec3(.025,.032,.039);
		if (height < .04 || (front > .065 && height > .065 && height < .095)) color = trim_color.rgb;
	} else if (region == 6) {
		// Face is a single skin color. Only the scalp receives a hairstyle pattern.
		float hairline = mix(1.605,1.68,smoothstep(-.055,.055,front));
		bool hair = hair_type > 0 && height > hairline;
		if (hair_type == 4) hair = hair && across < .045;
		if (hair) {
			color = hair_color.rgb;
			if (hair_type == 1) color = mix(skin_color.rgb,hair_color.rgb,.6);
			if (hair_type == 3) {
				vec2 cell = floor(UV*128.0);
				color *= .78+.22*mod(cell.x+cell.y,2.0);
			}
		}
	} else if (region == 8 && goalkeeper) {
		color = trim_color.rgb;
	}
	ALBEDO = color;
	ROUGHNESS = 1.0;
}
