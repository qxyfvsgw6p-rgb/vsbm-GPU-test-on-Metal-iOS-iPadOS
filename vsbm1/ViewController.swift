import UIKit
import MetalKit

class ViewController: UIViewController {

    private var mtkView: MTKView!
    private var renderer: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("❌  Metal not supported")
        }


        mtkView = MTKView(frame: view.bounds, device: device)
        mtkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.framebufferOnly = false
        mtkView.preferredFramesPerSecond = 60
        view.addSubview(mtkView)

        // 创建渲染器
        renderer = Renderer(mtkView: mtkView)
        mtkView.delegate = renderer

        setupGestures()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()


        let scale = view.window?.windowScene?.screen.scale ?? 1.0

        mtkView.drawableSize = CGSize(width: view.bounds.width * scale,
                                      height: view.bounds.height * scale)
    }


    private var lastPanPoint = CGPoint.zero
    private var lastPinch: CGFloat = 1.0

    private func setupGestures() {
 
        let rotate = UIPanGestureRecognizer(target: self, action: #selector(handleRotate(_:)))
        rotate.minimumNumberOfTouches = 1
        rotate.maximumNumberOfTouches = 1
        mtkView.addGestureRecognizer(rotate)

    
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        mtkView.addGestureRecognizer(pan)

  
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        mtkView.addGestureRecognizer(pinch)
    }

    @objc private func handleRotate(_ g: UIPanGestureRecognizer) {
        let pt = g.translation(in: mtkView)
        if g.state == .began { lastPanPoint = .zero }
        let dx = Float(pt.x - lastPanPoint.x)
        let dy = Float(pt.y - lastPanPoint.y)
        lastPanPoint = pt
        renderer.rotate(deltaAng1: dx * 0.002, deltaAng2: dy * 0.002)
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        let pt = g.translation(in: mtkView)
        if g.state == .began { lastPanPoint = .zero }
        let dx = Float(pt.x - lastPanPoint.x)
        let dy = Float(pt.y - lastPanPoint.y)
        lastPanPoint = pt
        renderer.pan(deltaX: dx, deltaY: dy)
    }

    @objc private func handlePinch(_ g: UIPinchGestureRecognizer) {
        if g.state == .began { lastPinch = g.scale }
        let scaleChange = g.scale / lastPinch
        lastPinch = g.scale
        renderer.zoom(scale: Float(scaleChange))
    }
}
