// CHECKITOUT: this file loads all the shaders and preprocesses them with some common code

import { Camera } from '../stage/camera';

import commonRaw from './common.wgsl?raw';

import naiveVertRaw from './naive.vs.wgsl?raw';
import naiveFragRaw from './naive.fs.wgsl?raw';

import forwardPlusFragRaw from './forward_plus.fs.wgsl?raw';

import clusteredDeferredFragRaw from './clustered_deferred.fs.wgsl?raw';
import clusteredDeferredFullscreenVertRaw from './clustered_deferred_fullscreen.vs.wgsl?raw';
import clusteredDeferredFullscreenFragRaw from './clustered_deferred_fullscreen.fs.wgsl?raw';

import moveLightsComputeRaw from './move_lights.cs.wgsl?raw';
import clusteringComputeRaw from './clustering.cs.wgsl?raw';

// CONSTANTS (for use in shaders)
// =================================

// CHECKITOUT: feel free to add more constants here and to refer to them in your shader code

// Note that these are declared in a somewhat roundabout way because otherwise minification will drop variables
// that are unused in host side code.
export const constants = {
    bindGroup_scene: 0,
    bindGroup_model: 1,
    bindGroup_material: 2,
    bindGroup_gbuffer: 1,

    moveLightsWorkgroupSize: 128,
    clusteringWorkgroupSizeX: 4,
    clusteringWorkgroupSizeY: 4,
    clusteringWorkgroupSizeZ: 4,

    clusterCountX: 32,
    clusterCountY: 16,
    clusterCountZ: 8,

    lightRadius: 2,
    maxLightsPerCluster: 512
};

// =================================

function evalShaderRaw(raw: string) {
    //return eval('`' + raw.replaceAll('${', '${constants.') + '`');
    return raw
        .replace(/\$\{bindGroup_scene\}/g, constants.bindGroup_scene.toString())
        .replace(/\$\{bindGroup_model\}/g, constants.bindGroup_model.toString())
        .replace(/\$\{bindGroup_material\}/g, constants.bindGroup_material.toString())
        .replace(/\$\{bindGroup_gbuffer\}/g, constants.bindGroup_gbuffer.toString())

        .replace(/\$\{moveLightsWorkgroupSize\}/g, constants.moveLightsWorkgroupSize.toString())

        .replace(/\$\{clusteringWorkgroupSizeX\}/g, constants.clusteringWorkgroupSizeX.toString())
        .replace(/\$\{clusteringWorkgroupSizeY\}/g, constants.clusteringWorkgroupSizeY.toString())
        .replace(/\$\{clusteringWorkgroupSizeZ\}/g, constants.clusteringWorkgroupSizeZ.toString())

        .replace(/\$\{clusterCountX\}/g, constants.clusterCountX.toString())
        .replace(/\$\{clusterCountY\}/g, constants.clusterCountY.toString())
        .replace(/\$\{clusterCountZ\}/g, constants.clusterCountZ.toString())

        .replace(/\$\{lightRadius\}/g, constants.lightRadius.toString())
        .replace(/\$\{maxLightsPerCluster\}/g, constants.maxLightsPerCluster.toString());
}

const commonSrc: string = evalShaderRaw(commonRaw);

function processShaderRaw(raw: string) {
    return commonSrc + evalShaderRaw(raw);
}

export const naiveVertSrc: string = processShaderRaw(naiveVertRaw);
export const naiveFragSrc: string = processShaderRaw(naiveFragRaw);

export const forwardPlusFragSrc: string = processShaderRaw(forwardPlusFragRaw);

export const clusteredDeferredFragSrc: string = processShaderRaw(clusteredDeferredFragRaw);
export const clusteredDeferredFullscreenVertSrc: string = processShaderRaw(clusteredDeferredFullscreenVertRaw);
export const clusteredDeferredFullscreenFragSrc: string = processShaderRaw(clusteredDeferredFullscreenFragRaw);

export const moveLightsComputeSrc: string = processShaderRaw(moveLightsComputeRaw);
export const clusteringComputeSrc: string = processShaderRaw(clusteringComputeRaw);
