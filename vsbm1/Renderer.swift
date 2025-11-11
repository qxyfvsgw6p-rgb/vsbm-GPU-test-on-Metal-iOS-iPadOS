import Metal
import MetalKit
import simd

struct Uniforms {
    var x: Float
    var y: Float
    var len: Float
    var origin: SIMD3<Float>
    var right: SIMD3<Float>
    var up: SIMD3<Float>
    var forward: SIMD3<Float>
}

class Renderer: NSObject, MTKViewDelegate {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState!
    private var uniformsBuffer: MTLBuffer!
    private var frameIndex: Int = 0
    private var viewSize: CGSize = .zero

    
    private var ang1: Float = 2.8
    private var ang2: Float = 0.4
    private var len: Float = 1.6
    private var cenx: Float = 0.0
    private var ceny: Float = 0.0
    private var cenz: Float = 0.0

    init(mtkView: MTKView) {
        guard let device = mtkView.device else { fatalError("Metal 设备初始化失败") }
        self.device = device
        guard let queue = device.makeCommandQueue() else { fatalError("Command Queue 创建失败") }
        self.commandQueue = queue

        super.init()
        setupPipeline(view: mtkView)
    }

    private func setupPipeline(view: MTKView) {
        guard let library = try? device.makeDefaultLibrary(bundle: .main) else {
            fatalError("❌ cannot load Metal Library")
        }

        guard let vertexFn = library.makeFunction(name: "vertex_main"),
              let fragFn = library.makeFunction(name: "fragment_main") else {
            fatalError("❌  Metal func not found: vertex_main or fragment_main")
        }

        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFn
        pipelineDesc.fragmentFunction = fragFn
        pipelineDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            fatalError("❌ error on creating pipeline: \(error)")
        }

        uniformsBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride * 3,
                                           options: .storageModeShared)
    }

    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewSize = size
    }

    func draw(in view: MTKView) {
       
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else {
            return
        }

        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

       
        encoder.setRenderPipelineState(pipelineState)

       
        let cx = Float(min(view.drawableSize.width, view.drawableSize.height))
        let cy = cx
        let x = cx * 2.0 / (cx + cy)
        let y = cy * 2.0 / (cx + cy)

        let origin = SIMD3<Float>(len * cos(ang1) * cos(ang2) + cenx,
                                  len * sin(ang2) + ceny,
                                  len * sin(ang1) * cos(ang2) + cenz)
        let right = SIMD3<Float>(sin(ang1), 0, -cos(ang1))
        let up = SIMD3<Float>(-sin(ang2) * cos(ang1), cos(ang2), -sin(ang2) * sin(ang1))
        let forward = SIMD3<Float>(-cos(ang1) * cos(ang2), -sin(ang2), -sin(ang1) * cos(ang2))

        var u = Uniforms(x: x, y: y, len: len, origin: origin, right: right, up: up, forward: forward)

        
        let stride = MemoryLayout<Uniforms>.stride
        let offset = stride * (frameIndex % 3)

       
        if uniformsBuffer == nil || uniformsBuffer.length < offset + stride {
            
            print("⚠️ uniformsBuffer invalid (nil or too small). length: \(String(describing: uniformsBuffer?.length)), needed: \(offset + stride)")
            encoder.endEncoding()
            commandBuffer.commit()
            return
        }

       
        memcpy(uniformsBuffer.contents().advanced(by: offset), &u, stride)

        
        encoder.setVertexBuffer(uniformsBuffer, offset: offset, index: 0)
        encoder.setFragmentBuffer(uniformsBuffer, offset: offset, index: 0)

        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()

        frameIndex += 1
    }

    
    func rotate(deltaAng1: Float, deltaAng2: Float) {
        ang1 += deltaAng1
        ang2 += deltaAng2
    }

    func pan(deltaX: Float, deltaY: Float) {
        let cx = Float(min(viewSize.width, viewSize.height))
        let l = len * 4.0 / (cx + cx)
        cenx += l * (-deltaX * sin(ang1) - deltaY * sin(ang2) * cos(ang1))
        ceny += l * ( deltaY * cos(ang2))
        cenz += l * ( deltaX * cos(ang1) - deltaY * sin(ang2) * sin(ang1))
    }

    func zoom(scale: Float) {
        len *= scale
    }
}
