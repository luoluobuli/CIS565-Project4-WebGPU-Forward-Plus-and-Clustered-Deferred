// TODO-3: implement the Clustered Deferred G-buffer fragment shader

// This shader should only store G-buffer information and should not do any shading.

@group(${bindGroup_material}) @binding(0) var diffuseTex: texture_2d<f32>;
@group(${bindGroup_material}) @binding(1) var diffuseTexSampler: sampler;

struct FragmentInput
{
    @location(0) pos: vec3f,
    @location(1) nor: vec3f,
    @location(2) uv: vec2f
}

struct FragmentOutput
{
    @location(0) pos_out: vec4f,
    @location(1) nor_out: vec4f,
    @location(2) color_out: vec4f
}

@fragment
fn main(in: FragmentInput) -> FragmentOutput
// fn main(in: FragmentInput) -> @location(0) vec4f
{
    let diffuseColor = textureSample(diffuseTex, diffuseTexSampler, in.uv);
    // return vec4(in.pos.xyz, 1.0);

    // let diffuseColor = textureSample(diffuseTex, diffuseTexSampler, in.uv);
    // if (diffuseColor.a < 0.5) {
    //     discard;
    // }

    var out: FragmentOutput;
    out.pos_out = vec4f(in.pos, 1.0);
    out.nor_out = vec4f(in.nor, 1.0);
    out.color_out = vec4f(diffuseColor.rgb, 1.0);
    
    return out;
}