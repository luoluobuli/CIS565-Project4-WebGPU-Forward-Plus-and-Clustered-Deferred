// CHECKITOUT: code that you add here will be prepended to all shaders

struct Light {
    pos: vec3f,
    color: vec3f
}

struct LightSet {
    numLights: u32,
    lights: array<Light>
}

// TODO-2: you may want to create a ClusterSet struct similar to LightSet
struct AABB { // 24 bytes
    minX : f32,
    maxX : f32,
    minY : f32,
    maxY : f32,
    minZ : f32,
    maxZ : f32
}

struct Cluster { // 428 bytes
    aabb : AABB, // 24 bytes
    numLights : u32, // 4 bytes
    lightInds : array<u32, ${maxLightsPerCluster}> // 400 bytes: maxLights(100) * 4
}

struct ClusterSet { // cluster num * 428 bytes
    clusters : array<Cluster>
}

struct CameraUniforms { // 224 bytes: 55 * 4 bytes + 4 bytes padding
    // DONE-1.3: add an entry for the view proj mat (of type mat4x4f)
    viewProjMat : mat4x4f,
    invProjMat : mat4x4f,
    viewMat : mat4x4f,
    clusterCountX : u32,
    clusterCountY : u32,
    clusterCountZ : u32,
    screenWidth : u32,
    screenHeight : u32,
    far : f32,
    near : f32
}

// CHECKITOUT: this special attenuation function ensures lights don't affect geometry outside the maximum light radius
fn rangeAttenuation(distance: f32) -> f32 {
    return clamp(1.f - pow(distance / ${lightRadius}, 4.f), 0.f, 1.f) / (distance * distance);
}

fn calculateLightContrib(light: Light, posWorld: vec3f, nor: vec3f) -> vec3f {
    let vecToLight = light.pos - posWorld;
    let distToLight = length(vecToLight);

    let lambert = max(dot(nor, normalize(vecToLight)), 0.f);
    return light.color * lambert * rangeAttenuation(distToLight);
}
