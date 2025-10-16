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

    var aabb = ClusterAABB(0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    // XY bounds
    let clusterSizeX = f32(camera.screenWidth) / f32(camera.clusterCountX);
    let clusterSizeY = f32(camera.screenHeight) / f32(camera.clusterCountY);

    aabb.minX = f32(ix) * clusterSizeX;
    aabb.maxX = f32(ix + 1) * clusterSizeX;
    aabb.minY = f32(iy) * clusterSizeY;
    aabb.maxY = f32(iy + 1) * clusterSizeY;

    // Depth bounds
    let r = camera.far / camera.near;
    aabb.minZ = camera.near * pow(r, f32(iz) / f32(camera.clusterCountZ)); // log slicing
    aabb.maxZ = camera.near * pow(r, f32(iz + 1) / f32(camera.clusterCountZ));

    clusterSet.aabbs[clusterIdx] = aabb;

    // Assign lights
    let lightCnt = 0;
}