// TODO-2: implement the light clustering compute shader
@group(${bindGroup_scene}) @binding(0) var<storage, read_write> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(1) var<uniform> camera: CameraUniforms;
@group(${bindGroup_scene}) @binding(2) var<storage, read_write> clusterSet: ClusterSet;

// ------------------------------------
// Calculating cluster bounds:
// ------------------------------------
// For each cluster (X, Y, Z):
//     - Calculate the screen-space bounds for this cluster in 2D (XY).
//     - Calculate the depth bounds for this cluster in Z (near and far planes).
//     - Convert these screen and depth bounds into view-space coordinates.
//     - Store the computed bounding box (AABB) for the cluster.

// ------------------------------------
// Assigning lights to clusters:
// ------------------------------------
// For each cluster:
//     - Initialize a counter for the number of lights in this cluster.

//     For each light:
//         - Check if the light intersects with the cluster’s bounding box (AABB).
//         - If it does, add the light to the cluster's light list.
//         - Stop adding lights if the maximum number of lights is reached.

//     - Store the number of lights assigned to this cluster.

@compute
@workgroup_size(${clusteringWorkgroupSizeX}, ${clusteringWorkgroupSizeY}, ${clusteringWorkgroupSizeZ})
fn main (@builtin(global_invocation_id) globalIdx: vec3u) {
    let ix = globalIdx.x;
    let iy = globalIdx.y;
    let iz = globalIdx.z;

    if (ix >= camera.clusterCountX || 
        iy >= camera.clusterCountY ||
        iz >= camera.clusterCountZ) {
        return;
    }

    let clusterIdx = ix + (iy * camera.clusterCountX) + (iz * camera.clusterCountX * camera.clusterCountZ);

    // ------------------- Cluster Bounding box ----------------------
    var aabb = ClusterAABB(0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    // XY bounds - NDC
    let minX = f32(ix) / f32(camera.clusterCountX) * 2.0 - 1.0;
    let maxX = f32(ix + 1) / f32(camera.clusterCountX) * 2.0 - 1.0;
    let minY = 1.0 - f32(iy) / camera.clusterCountY * 2.0;
    let maxY = 1.0 - f32(iy + 1) / camera.clusterCountY * 2.0;

    let corners = array<vec4<f32>, 8>(
        vec4<f32>(minX, minY, -1.0, 1.0),
        vec4<f32>(maxX, minY, -1.0, 1.0),
        vec4<f32>(minX, maxY, -1.0, 1.0),
        vec4<f32>(maxX, maxY, -1.0, 1.0),
        vec4<f32>(minX, minY,  1.0, 1.0),
        vec4<f32>(maxX, minY,  1.0, 1.0),
        vec4<f32>(minX, maxY,  1.0, 1.0),
        vec4<f32>(maxX, maxY,  1.0, 1.0)
    );

    // Get view space coordinates
    let invProjMat = inverse(camera.projMat);

    var minView = vec3<f32>( 1e9,  1e9,  1e9);
    var maxView = vec3<f32>(-1e9, -1e9, -1e9);

    for (var i = 0u; i < 8u; i++) {
        var viewPos = invProjMat * corners[i];
        viewPos /= viewPos.w;
        minView = min(minView, viewPos.xyz);
        maxView = max(maxView, viewPos.xyz);
    }

    aabb.minX = minView.x;
    aabb.maxX = maxView.x;
    aabb.minY = minView.y;
    aabb.maxY = maxView.y;

    // Depth bounds - View
    let r = camera.far / camera.near;
    let minZ = camera.near * pow(r, f32(iz) / f32(camera.clusterCountZ)); // log slicing
    let maxZ = camera.near * pow(r, f32(iz + 1) / f32(camera.clusterCountZ));

    aabb.minZ = -maxZ;
    aabb.maxZ = -minZ;


    // ---------------------- Assign lights --------------------------------
    let lightCnt = 0;

    for (var i = 0; i < lightSet.numLights; ++i) {
        let light = lightSet.lights[i];
    }
}