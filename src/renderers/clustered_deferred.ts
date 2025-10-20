import * as renderer from '../renderer';
import * as shaders from '../shaders/shaders';
import { Stage } from '../stage/stage';

export class ClusteredDeferredRenderer extends renderer.Renderer {
    sceneUniformsBindGroupLayout: GPUBindGroupLayout;
    sceneUniformsBindGroup: GPUBindGroup;

    gbufferBindGroupLayout: GPUBindGroupLayout;
    gbufferBindGroup: GPUBindGroup;

    // GBuffers
    gBufferPosTexture: GPUTexture;
    gBufferPosTextureView: GPUTextureView;

    gBufferNormalTexture: GPUTexture;
    gBufferNormalTextureView: GPUTextureView;

    gBufferColorTexture: GPUTexture;
    gBufferColorTextureView: GPUTextureView;

    depthTexture: GPUTexture;
    depthTextureView: GPUTextureView;

    pipeline: GPURenderPipeline;
    lightingPipeline: GPURenderPipeline;

    constructor(stage: Stage) {
        super(stage);

        this.sceneUniformsBindGroupLayout = renderer.device.createBindGroupLayout({
            label: "scene uniforms bind group layout",
            entries: [

                {
                    binding: 0,
                    visibility: GPUShaderStage.VERTEX | GPUShaderStage.FRAGMENT,
                    buffer: { type: "uniform" }
                },
                { // lightSet
                    binding: 1,
                    visibility: GPUShaderStage.FRAGMENT,
                    buffer: { type: "read-only-storage" }
                },
                { // clusterSet
                    binding: 2,
                    visibility: GPUShaderStage.FRAGMENT,
                    buffer: { type: "read-only-storage" }
                }
            ]
        });

        this.sceneUniformsBindGroup = renderer.device.createBindGroup({
            label: "scene uniforms bind group",
            layout: this.sceneUniformsBindGroupLayout,
            entries: [
                {
                    binding: 0,
                    resource: { buffer: this.camera.uniformsBuffer }
                },
                {
                    binding: 1,
                    resource: { buffer: this.lights.lightSetStorageBuffer }
                },
                {
                    binding: 2,
                    resource: { buffer: this.lights.clusterSetStorageBuffer }
                }
            ]
        });

        
        this.gbufferBindGroupLayout = renderer.device.createBindGroupLayout({
            label: "lighting pass bind group layout",
            entries: [
                { // sampler
                    binding: 0,
                    visibility: GPUShaderStage.FRAGMENT,
                    sampler: {}
                },
                { // pos
                    binding: 1,
                    visibility: GPUShaderStage.FRAGMENT,
                    texture: {}
                },
                { // normal
                    binding: 2,
                    visibility: GPUShaderStage.FRAGMENT,
                    texture: {}
                },
                { // albedo
                    binding: 3,
                    visibility: GPUShaderStage.FRAGMENT,
                    texture: {}
                }
            ]
        });


        this.gBufferPosTexture = renderer.device.createTexture({
            size: [renderer.canvas.width, renderer.canvas.height],
            format: "rgba16float",
            usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_SRC
        });
        this.gBufferPosTextureView = this.gBufferPosTexture.createView();

        this.gBufferNormalTexture = renderer.device.createTexture({
            size: [renderer.canvas.width, renderer.canvas.height],
            format: "rgba16float",
            usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_SRC
        });
        this.gBufferNormalTextureView = this.gBufferNormalTexture.createView();

        this.gBufferColorTexture = renderer.device.createTexture({
            size: [renderer.canvas.width, renderer.canvas.height],
            format: "rgba8unorm",
            usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_SRC
        });
        this.gBufferColorTextureView = this.gBufferColorTexture.createView();
        
        this.depthTexture = renderer.device.createTexture({
            size: [renderer.canvas.width, renderer.canvas.height],
            format: "depth24plus",
            usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_SRC
        });
        this.depthTextureView = this.depthTexture.createView();

        const sampler = renderer.device.createSampler({
            magFilter: "nearest",
            minFilter: "nearest",
        });

        this.gbufferBindGroup = renderer.device.createBindGroup({
            label: "lighting pass bind group",
            layout: this.gbufferBindGroupLayout,
            entries: [
                { binding: 0, resource: sampler },
                { binding: 1, resource: this.gBufferPosTextureView },
                { binding: 2, resource: this.gBufferNormalTextureView },
                { binding: 3, resource: this.gBufferColorTextureView },
            ],
        });

        this.pipeline = renderer.device.createRenderPipeline({
            layout: renderer.device.createPipelineLayout({
                label: "naive pipeline layout",
                bindGroupLayouts: [
                    this.sceneUniformsBindGroupLayout,
                    renderer.modelBindGroupLayout,
                    renderer.materialBindGroupLayout
                ]
            }),
            depthStencil: {
                depthWriteEnabled: true,
                depthCompare: "less",
                format: "depth24plus"
            },
            vertex: {
                module: renderer.device.createShaderModule({
                    label: "naive vert shader",
                    code: shaders.naiveVertSrc
                }),
                buffers: [ renderer.vertexBufferLayout ]
            },
            fragment: {
                module: renderer.device.createShaderModule({
                    label: "gbuffer frag",
                    code: shaders.clusteredDeferredFragSrc,
                }),
                targets: [
                    {
                        // format: renderer.canvasFormat,
                        format: "rgba16float"
                    },
                    {
                        format: "rgba16float"
                    },
                    {
                        format: "rgba8unorm"
                    }
                ]
            }
        });

        this.lightingPipeline = renderer.device.createRenderPipeline({
            layout: renderer.device.createPipelineLayout({
                label: "lighting layout",
                bindGroupLayouts: [
                    this.sceneUniformsBindGroupLayout,
                    this.gbufferBindGroupLayout
                ]
            }),
            depthStencil: undefined,   // disable depth test
            vertex: {
                module: renderer.device.createShaderModule({
                    label: "lighting vert shader",
                    code: shaders.clusteredDeferredFullscreenVertSrc
                }),
            },
            fragment: {
                module: renderer.device.createShaderModule({
                    label: "lighting frag",
                    code: shaders.clusteredDeferredFullscreenFragSrc,
                }),
                targets: [
                    {
                        format: renderer.canvasFormat
                    }
                ]
            }
        });
    }

    override draw() {
        const encoder = renderer.device.createCommandEncoder();

        this.lights.doLightClustering(encoder);

        const renderPass = encoder.beginRenderPass({
            label: "naive render pass",
            colorAttachments: [
                {
                    view: this.gBufferPosTextureView,
                    clearValue: [0, 0, 0, 0],
                    loadOp: "clear",
                    storeOp: "store"
                },
                {
                    view: this.gBufferNormalTextureView,
                    clearValue: [0, 0, 0, 0],
                    loadOp: "clear",
                    storeOp: "store"
                },
                {
                    view: this.gBufferColorTextureView,
                    clearValue: [0, 0, 0, 0],
                    loadOp: "clear",
                    storeOp: "store"
                }
            ],
            depthStencilAttachment: {
                view: this.depthTextureView,
                depthClearValue: 1.0,
                depthLoadOp: "clear",
                depthStoreOp: "store"
            }
        });
        renderPass.setPipeline(this.pipeline);

        renderPass.setBindGroup(shaders.constants.bindGroup_scene, this.sceneUniformsBindGroup);

        this.scene.iterate(node => {
            renderPass.setBindGroup(shaders.constants.bindGroup_model, node.modelBindGroup);
        }, material => {
            renderPass.setBindGroup(shaders.constants.bindGroup_material, material.materialBindGroup);
        }, primitive => {
            renderPass.setVertexBuffer(0, primitive.vertexBuffer);
            renderPass.setIndexBuffer(primitive.indexBuffer, 'uint32');
            renderPass.drawIndexed(primitive.numIndices);
        });

        renderPass.end();

        // lighting pass

        const canvasTextureView = renderer.context.getCurrentTexture().createView();

        const lightingPass = encoder.beginRenderPass({
            label: "lighting pass",
            colorAttachments: [
                {
                    view: canvasTextureView,
                    clearValue: [0, 0, 0, 0],
                    loadOp: "clear",
                    storeOp: "store"
                }
            ]
        });
        lightingPass.setPipeline(this.lightingPipeline);
        lightingPass.setBindGroup(shaders.constants.bindGroup_scene, this.sceneUniformsBindGroup);
        lightingPass.setBindGroup(shaders.constants.bindGroup_gbuffer, this.gbufferBindGroup);
        lightingPass.draw(3);
        lightingPass.end();

        renderer.device.queue.submit([encoder.finish()]);
    }
}
