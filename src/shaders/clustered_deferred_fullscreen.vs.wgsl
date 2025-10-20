// DONE-3: implement the Clustered Deferred fullscreen vertex shader

// This shader should be very simple as it does not need all of the information passed by the the naive vertex shader.

struct VertexOutput
{
    @builtin(position) fragPos: vec4f,
    @location(0) uv: vec2f
}

@vertex
fn main(@builtin(vertex_index) idx : u32) -> VertexOutput {
    // Positions of 3 vertices in clip space
    var pos = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>( 3.0, -1.0),
        vec2<f32>(-1.0,  3.0)
    );

    // Map from clip space [-1,1] → UV space [0,1]
    var uv = array<vec2<f32>, 3>(
        vec2<f32>(0.0, 0.0),
        vec2<f32>(2.0, 0.0),
        vec2<f32>(0.0, 2.0)
    );

    var out : VertexOutput;
    out.fragPos = vec4<f32>(pos[idx], 0.0, 1.0);
    out.uv = vec2(uv[idx].x, 1.0 - uv[idx].y);
    return out;
}