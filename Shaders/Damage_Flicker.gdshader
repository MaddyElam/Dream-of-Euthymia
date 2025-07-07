shader_type canvas_item;

uniform float blink_speed = 30;
uniform bool blinking = false;
uniform float flash_opacity = 0.0;

void fragment() {
	if (blinking){
		vec4 color = texture(TEXTURE, UV);
		float blink = sin(TIME * blink_speed);
		
		color.a *= abs(blink);
		
		COLOR = color;
	}
	else{
		COLOR.a = texture(TEXTURE,UV).a;
	}
	COLOR.rgb = texture(TEXTURE,UV).rgb * (1.0 - flash_opacity) + vec3(1,1,1) * flash_opacity;
}

