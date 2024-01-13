shader_type canvas_item;

uniform sampler2D texture_albedo : hint_default_white;

void vertex() {
    // Transform the texture coordinates to achieve repeating pattern

}

void fragment() {
    // Repeat the texture using the modulo operation
    vec2 uv = fract(UV * vec2(5.0, 5.0));

    // Sample the texture
    COLOR = texture(texture_albedo, uv);
}