// TODO-2: implement the Forward+ fragment shader

// See naive.fs.wgsl for basic fragment shader setup; this shader should use light clusters instead of looping over all lights
@group(${bindGroup_scene}) @binding(0) var<uniform> camera : CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read> clusterSet: ClusterSet;

@group(${bindGroup_material}) @binding(0) var diffuseTex: texture_2d<f32>;
@group(${bindGroup_material}) @binding(1) var diffuseTexSampler: sampler;


// ------------------------------------
// Shading process:
// ------------------------------------
// Determine which cluster contains the current fragment.
// Retrieve the number of lights that affect the current fragment from the cluster’s data.
// Initialize a variable to accumulate the total light contribution for the fragment.
// For each light in the cluster:
//     Access the light's properties using its index.
//     Calculate the contribution of the light based on its position, the fragment’s position, and the surface normal.
//     Add the calculated contribution to the total light accumulation.
// Multiply the fragment’s diffuse color by the accumulated light contribution.
// Return the final color, ensuring that the alpha component is set appropriately (typically to 1).

struct FragmentInput
{
    @location(0) pos: vec3f,
    @location(1) nor: vec3f,
    @location(2) uv: vec2f
}

@fragment
fn main(in: FragmentInput) -> @location(0) vec4f
{
    let diffuseColor = textureSample(diffuseTex, diffuseTexSampler, in.uv);
    if (diffuseColor.a < 0.5f) {
        discard;
    }

    // Identify which cluster the pixel is in
    // Compute cluster indices
    // XY
    let clipPos = camera.viewProjMat * vec4f(in.pos, 1.0); // clip space
    let ndcPos = clipPos.xyz / clipPos.w; // ndc

    let countX = u32(${clusterCountX});
    let countY = u32(${clusterCountY});
    let countZ = u32(${clusterCountZ});

    let nx = clamp(ndcPos.x * 0.5 + 0.5, 0.0, 1.0);
    let ny = clamp(ndcPos.y * 0.5 + 0.5, 0.0, 1.0);
    let ix = u32(nx * f32(countX));
    let iy = u32(ny * f32(countY));

    // Z
    let viewPos = (camera.viewMat * vec4f(in.pos, 1.0)).xyz;
    let viewZ = -viewPos.z;

    let logDepth = log(-viewPos.z / camera.near) / log(camera.far / camera.near);
    let iz = u32(logDepth * f32(countZ));

    let clusterIdx = ix + iy * countX + iz * countX * countY;

    // Get cluster
    let cluster = clusterSet.clusters[clusterIdx];

    // Shading
    // var intersectionCnt = 0;
    var totalLightContrib = vec3f(0, 0, 0);
    for (var i = 0u; i < cluster.numLights; i++) {
        let lightIdx = cluster.lightInds[i];
        let light = lightSet.lights[lightIdx];
        // let light = lightSet.lights[0];
        // intersectionCnt++;
        // totalLightContrib += f32(light.color);
        totalLightContrib += calculateLightContrib(light, in.pos, normalize(in.nor));
        // let vecToLight = light.pos - in.pos;
        // let distToLight = length(vecToLight);

        // let lambert = max(dot(normalize(in.nor), normalize(vecToLight)), 0.f);
        // totalLightContrib += light.color * lambert;
    }
    // var totalLightContrib = calculateLightContrib(lightSet.lights[0], in.pos, normalize(in.nor));
    // return vec4(vec3(f32(cluster.numLights)) / 10.0, 1.0);

    // return vec4(diffuseColor.rgb, 1.0);

    var finalColor = diffuseColor.rgb * totalLightContrib;
    return vec4(finalColor, 1);
}
