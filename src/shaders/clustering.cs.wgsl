// DONE-2: implement the light clustering compute shader
@group(0) @binding(0) var<storage, read_write> lightSet: LightSet;
@group(0) @binding(1) var<uniform> camera: CameraUniforms;
@group(0) @binding(2) var<storage, read_write> clusterSet: ClusterSet;

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

fn ndcToView(x: f32, y: f32, z: f32) -> vec3<f32> {
    let invProjMat = camera.invProjMat;

    var viewPos = invProjMat * vec4(x, y, -1.0, 1.0);
    viewPos /= viewPos.w;

    return viewPos.xyz * (z / -viewPos.z);
}


@compute
@workgroup_size(${clusteringWorkgroupSizeX}, ${clusteringWorkgroupSizeY}, ${clusteringWorkgroupSizeZ})
fn main (@builtin(global_invocation_id) globalIdx: vec3u) {
    let ix = globalIdx.x;
    let iy = globalIdx.y;
    let iz = globalIdx.z;

    let countX = u32(${clusterCountX});
    let countY = u32(${clusterCountY});
    let countZ = u32(${clusterCountZ});

    if (ix >= countX || 
        iy >= countY ||
        iz >= countZ) {
        return;
    }

    let clusterIdx = ix + (iy * countX) + (iz * countX * countY);

    // ------------------- Cluster Bounding box ----------------------
    var aabb = AABB(0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    // XY bounds - screen
    let clusterSizeX = f32(camera.screenWidth) / f32(countX);
    let clusterSizeY = f32(camera.screenHeight) / f32(countY);
    var minX = f32(ix) * clusterSizeX;
    var maxX = f32(ix + 1) * clusterSizeX;
    var minY = f32(iy) * clusterSizeY;
    var maxY = f32(iy + 1) * clusterSizeY;

    // XY bounds - ndc
    minX = minX / f32(camera.screenWidth) * 2.0 - 1.0;
    maxX = maxX / f32(camera.screenWidth) * 2.0 - 1.0;
    minY = minY / f32(camera.screenHeight) * 2.0 - 1.0;
    maxY = maxY / f32(camera.screenHeight) * 2.0 - 1.0;

    // Depth bounds - View
    let r = camera.far / camera.near;
    let zNear = camera.near * pow(r, f32(iz) / f32(countZ)); // log slicing
    let zFar = camera.near * pow(r, f32(iz + 1) / f32(countZ));

    // Get view space coordinates
    let nearBottomLeft = ndcToView(minX, minY, zNear);
    let nearBottomRight = ndcToView(maxX, minY, zNear);
    let nearTopLeft = ndcToView(minX, maxY, zNear);
    let nearTopRight = ndcToView(maxX, maxY, zNear);

    let farBottomLeft = ndcToView(minX, minY, zFar);
    let farBottomRight = ndcToView(maxX, minY, zFar);
    let farTopLeft = ndcToView(minX, maxY, zFar);
    let farTopRight = ndcToView(maxX, maxY, zFar);

    var minPos = min(farTopRight,(min(farTopLeft, min(farBottomRight, 
        min(farBottomLeft, min(nearTopRight, min(nearTopLeft, 
        min(nearBottomLeft, nearBottomRight))))))));
    var maxPos = max(farTopRight,(max(farTopLeft, max(farBottomRight, 
        max(farBottomLeft, max(nearTopRight, max(nearTopLeft, 
        max(nearBottomLeft, nearBottomRight))))))));

    aabb.minX = minPos.x;
    aabb.minY = minPos.y;
    aabb.minZ = -zFar;
    aabb.maxX = maxPos.x;
    aabb.maxY = maxPos.y;
    aabb.maxZ = -zNear;

    clusterSet.clusters[clusterIdx].aabb = aabb;


    // ---------------------- Assign lights --------------------------------
    var lightCnt = 0u;

    for (var i = 0u; i < lightSet.numLights; i++) {
        let light = lightSet.lights[i];
        let lightPosView = (camera.viewMat * vec4(light.pos, 1.0)).xyz; // convert to view space
        let closestPos = vec3<f32>(
            clamp(lightPosView.x, aabb.minX, aabb.maxX),
            clamp(lightPosView.y, aabb.minY, aabb.maxY),
            clamp(lightPosView.z, aabb.minZ, aabb.maxZ)
        );
        let d = lightPosView - closestPos;
        let d2 = dot(d, d);
        let radius = f32(${lightRadius});
        if (d2 <= radius * radius) {
            clusterSet.clusters[clusterIdx].lightInds[lightCnt] = i;
            lightCnt++;
        }
        if (lightCnt >= ${maxLightsPerCluster}) {
            break;
        }
    }
    clusterSet.clusters[clusterIdx].numLights = lightCnt;
}