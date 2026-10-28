#version 440

// Separable Gaussian blur pass. Run twice: once with uDirection = (1, 0),
// then with (0, 1). 13 taps spread across +/- uRadius texels with weights
// sampled from a Gaussian of sigma = uRadius / 2, so the kernel covers
// +/- 2 sigma — the standard clean truncation.
//
// GlassBackground runs this at half resolution, which doubles the
// effective blur reach in widget pixels and halves the sampling cost.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 uDirection;   // unit axis times 1: (1,0) or (0,1)
    float uRadius;     // spread in texels of the sampled texture
    vec2 uTexel;       // 1 / texture size
};

layout(binding = 1) uniform sampler2D uSource;

void main()
{
    float sigma = max(uRadius * 0.5, 0.01);
    vec4 sum = vec4(0.0);
    float wsum = 0.0;

    for (int i = -6; i <= 6; ++i) {
        float x = float(i) * uRadius / 6.0;
        float w = exp(-0.5 * x * x / (sigma * sigma));
        vec2 uv = qt_TexCoord0 + uDirection * (x * uTexel);
        sum += texture(uSource, uv) * w;
        wsum += w;
    }

    fragColor = sum / wsum;
}
