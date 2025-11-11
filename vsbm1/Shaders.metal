#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float x;
    float y;
    float len;
    float3 origin;
    float3 right;
    float3 up;
    float3 forward;
};

struct VertexOut {
    float4 position [[position]];
    float3 dir;
    float3 localdir;
};

vertex VertexOut vertex_main(uint vid [[vertex_id]],
                             constant Uniforms &u [[buffer(0)]]) {
    // 全屏三角形（无需数组）
    float2 pos;
    if (vid == 0) pos = float2(-1.0, -1.0);
    else if (vid == 1) pos = float2(3.0, -1.0);
    else pos = float2(-1.0, 3.0);

    VertexOut out;
    out.position = float4(pos, 0.0, 1.0);
    out.dir = u.forward + u.right * (pos.x * u.x) + u.up * (pos.y * u.y);
    out.localdir = float3(pos.x * u.x, pos.y * u.y, -1.0);
    return out;
}

float kernal_func(float3 ver) {
    float3 a = ver;
    float b,c,d;
    for (int i=0;i<5;i++) {
        b = length(a);
        c = atan2(a.y, a.x) * 8.0;
        d = acos(a.z / b) * 8.0;
        b = pow(b, 8.0);
        a = float3(b*sin(d)*cos(c), b*sin(d)*sin(c), b*cos(d)) + ver;
        if (b > 6.0) break;
    }
    return 4.0 - dot(a, a);
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms &u [[buffer(0)]]) {
 
    float stepSize = 0.002;
    float v1 = kernal_func(u.origin + in.dir * (stepSize * u.len));
    float v2 = kernal_func(u.origin);
    float3 color = float3(0.0);
    for (int k = 2; k < 800; k++) {
        float3 ver = u.origin + in.dir * (stepSize * u.len * float(k));
        float v = kernal_func(ver);
        if (v > 0.0 && v1 < 0.0) {
            color = float3(0.2 + 0.8*sin(ver.x*5.0), 0.3 + 0.7*sin(ver.y*5.0), 0.4 + 0.6*sin(ver.z*5.0));
            break;
        }
        v2 = v1;
        v1 = v;
    }
    return float4(color, 1.0);
}
