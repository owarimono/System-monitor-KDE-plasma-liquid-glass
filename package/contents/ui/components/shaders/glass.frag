#version 440

// Liquid-glass compose pass. Receives the blurred wallpaper crop in
// widget-local UV and layers the macOS material on top of it:
//
//   1. Rounded-rect silhouette (exact SDF, uRadius corners) with
//      fwidth-based AA
//   2. Snell-style refraction through an edge band: the surface bends
//      like a rounded dome near the border, pulling the backdrop outward
//   3. Chromatic aberration on the refracted rim (slightly different
//      displacement per channel)
//   4. Vibrancy (a touch of saturation) and white tint over the backdrop
//   5. Specular border: key light from the top, soft catch on the left
//      and bottom, plus a crisp 1px inner highlight along the lit rim
//   6. Inner edge stroke: an Apple-style light outline hugging the whole
//      silhouette (strongest at the top, faintest at the bottom)
//   7. Mouse-following sheen and a bottom shade
//   8. Ordered-noise dithering to kill banding on the blurred gradient
//
// Output is premultiplied alpha (Qt Quick scene graph convention).

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2  uSize;        // widget size in px
    float uRadius;      // corner radius in px — exact rounded-rect corners
    vec4  uTint;        // rgb = tint color, a = tint strength
    float uEdgeBand;    // refraction band width in px, 0 disables
    float uRefract;     // max refraction displacement in px
    float uChroma;      // chromatic aberration strength, 0..1
    float uSpec;        // specular border strength, 0..1
    float uStroke;      // inner edge stroke strength, 0..1
    vec2  uMouse;       // mouse position in UV, (-1,-1) when not hovering
    float uMouseFade;   // 0..1 sheen fade
    float uNoise;       // dithering amplitude (e.g. 0.006)
};

layout(binding = 1) uniform sampler2D uBackdrop;

// Exact signed distance to a rounded rectangle (negative inside).
float sdRoundRect(vec2 p, vec2 halfSize, float r)
{
    vec2 q = abs(p) - (halfSize - vec2(r));
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

// Unit outward gradient of the rounded-rect SDF (y down). Axis-aligned on
// straight edges, radial in the corner arcs, zero deep inside.
vec2 sdRoundRectNormal(vec2 p, vec2 halfSize, float r)
{
    vec2 q = abs(p) - (halfSize - vec2(r));
    vec2 g = sign(p) * max(q, vec2(0.0));
    float len = length(g);
    return len > 1e-6 ? g / len : vec2(0.0);
}

float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main()
{
    vec2 halfSize = uSize * 0.5;
    vec2 p = (qt_TexCoord0 - 0.5) * uSize;      // center-origin, y down

    // Positive inside; corners follow uRadius exactly (no size-dependent
    // superellipse swelling).
    float fs = -sdRoundRect(p, halfSize, uRadius);
    vec2  n  = sdRoundRectNormal(p, halfSize, uRadius);
    float aa = max(fwidth(fs), 1e-4);
    float mask = smoothstep(-aa, aa, fs);

    // --- refraction through the edge dome -------------------------------
    float band = uEdgeBand > 0.0 ? clamp(1.0 - fs / uEdgeBand, 0.0, 1.0) : 0.0;
    band = band * band * (3.0 - 2.0 * band);    // dome profile
    float refractPx = band * uRefract;
    vec2 baseUV = qt_TexCoord0;

    vec3 col;
    if (uChroma > 0.0 && refractPx > 0.0) {
        vec2 uvR = baseUV + n * (refractPx * (1.0 + uChroma)) / uSize;
        vec2 uvG = baseUV + n * refractPx / uSize;
        vec2 uvB = baseUV + n * (refractPx * (1.0 - uChroma)) / uSize;
        col = vec3(texture(uBackdrop, uvR).r,
                   texture(uBackdrop, uvG).g,
                   texture(uBackdrop, uvB).b);
    } else {
        col = texture(uBackdrop, baseUV + n * refractPx / uSize).rgb;
    }

    // --- tint + vibrancy -------------------------------------------------
    // macOS vibrancy: the blurred backdrop keeps its colors but gains a
    // touch of saturation, which is what makes Apple's materials feel
    // alive instead of gray.
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = clamp(mix(vec3(luma), col, 1.14), 0.0, 1.0);
    col = clamp(col * 1.10 + 0.015, 0.0, 1.0);   // glass luminosity
    col = mix(col, uTint.rgb, uTint.a);

    // --- specular border -------------------------------------------------
    // Key light straight from the top, secondary catch from the upper-left.
    float topFacing    = clamp(-n.y, 0.0, 1.0);
    float leftFacing   = clamp(dot(n, normalize(vec2(-0.7, -0.7))), 0.0, 1.0);
    float bottomFacing = clamp(n.y, 0.0, 1.0);
    float rim          = band * band;
    float spec = rim * uSpec * (0.62 * topFacing + 0.26 * leftFacing + 0.10 * bottomFacing);
    col += spec;

    // Apple-style inner edge stroke hugging the whole silhouette.
    float strokeBand = 1.0 - smoothstep(0.0, 1.6, fs);
    float stroke = strokeBand * (0.42 * topFacing + 0.20 * leftFacing + 0.08 * bottomFacing + 0.06);
    col += stroke * uStroke;

    // --- mouse-following sheen -------------------------------------------
    if (uMouseFade > 0.0 && uMouse.x >= 0.0) {
        vec2 mp = uMouse * uSize;
        float md2 = dot(p - mp, p - mp);
        float sheen = exp(-md2 / (2.0 * 0.30 * 0.30 * uSize.x * uSize.x));
        col += sheen * 0.07 * uMouseFade * uSpec;
    }

    // --- grounding shade + dithering -------------------------------------
    col *= mix(1.0, 0.94, smoothstep(0.55, 1.0, qt_TexCoord0.y));
    col += (hash12(gl_FragCoord.xy) - 0.5) * uNoise;

    float alpha = mask * qt_Opacity;
    fragColor = vec4(col * alpha, alpha);
}
