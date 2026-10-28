#version 440

// Crop the widget's region out of the full wallpaper texture.
//
// The wallpaper is captured as one big texture; this pass remaps the
// widget-local UV onto wallpaper UV so every later stage (blur, glass)
// works in widget pixel space. uUVScale/uUVOffset are supplied by
// GlassBackground from mapToItem(wallpaperItem).

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 uUVOffset;
    vec2 uUVScale;
};

layout(binding = 1) uniform sampler2D uSource;

void main()
{
    vec2 uv = uUVOffset + qt_TexCoord0 * uUVScale;
    fragColor = texture(uSource, uv) * qt_Opacity;
}
