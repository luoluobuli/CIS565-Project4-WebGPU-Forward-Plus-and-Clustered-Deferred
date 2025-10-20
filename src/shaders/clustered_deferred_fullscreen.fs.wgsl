// DONE-3: implement the Clustered Deferred fullscreen fragment shader

// Similar to the Forward+ fragment shader, but with vertex information coming from the G-buffer instead.
@group(${bindGroup_scene}) @binding(0) var<uniform> camera : CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read> clusterSet: ClusterSet;

@group(${bindGroup_gbuffer}) @binding(0) var textureSampler: sampler;
@group(${bindGroup_gbuffer}) @binding(1) var posTexture: texture_2d<f32>;
@group(${bindGroup_gbuffer}) @binding(2) var normTexture: texture_2d<f32>;
@group(${bindGroup_gbuffer}) @binding(3) var colorTexture: texture_2d<f32>;

struct FragmentInput
{
    @location(0) uv: vec2f,
}

@fragment
fn main(in: FragmentInput) -> @location(0) vec4f
{
    let pos = textureSample(posTexture, textureSampler, in.uv).xyz;
    let norm = textureSample(normTexture, textureSampler, in.uv).xyz;
    let diffuseColor = textureSample(colorTexture, textureSampler, in.uv).xyz;

    // return vec4(diffuseColor.rgb, 1.0);

    // Identify which cluster the pixel is in
    // Compute cluster indices
    // XY
    let clipPos = camera.viewProjMat * vec4f(pos, 1.0); // clip space
    let ndcPos = clipPos.xyz / clipPos.w; // ndc

    let countX = u32(${clusterCountX});
    let countY = u32(${clusterCountY});
    let countZ = u32(${clusterCountZ});

    let nx = clamp(ndcPos.x * 0.5 + 0.5, 0.0, 1.0);
    let ny = clamp(ndcPos.y * 0.5 + 0.5, 0.0, 1.0);
    let ix = u32(nx * f32(countX));
    let iy = u32(ny * f32(countY));

    // Z
    let viewPos = (camera.viewMat * vec4f(pos, 1.0)).xyz;
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
        totalLightContrib += calculateLightContrib(light, pos, normalize(norm));
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
