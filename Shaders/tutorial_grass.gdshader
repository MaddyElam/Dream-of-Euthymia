shader_type canvas_item;

uniform float speed = 2.0;
uniform float distance = 10.0;

void vertex() {
	VERTEX.x += sin(TIME * speed) * distance * (UV.y - 1.0);
}
