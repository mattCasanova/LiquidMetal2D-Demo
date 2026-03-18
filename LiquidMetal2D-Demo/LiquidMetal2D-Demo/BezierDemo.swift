//
//  BezierDemo.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/17/26.
//

import UIKit
import LiquidMetal2D

/// Bezier curve demo: A ship follows two chained cubic bezier segments
/// (7 control points). Touch near a control point to grab it, then drag
/// to reshape the curve. Demonstrates: GameMath.cubicBezier, click-and-drag
/// input, orientation along curve tangent.
class BezierDemo: Scene, @unchecked Sendable {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    private var ship: GameObj!
    private var controlPointShips = [GameObj]()

    // Two chained cubic bezier segments: [0..3] and [3..6]
    private var controlPoints: [Vec2] = [
        Vec2(-25, -10),
        Vec2(-18, 20),
        Vec2(-5, 15),
        Vec2(0, -5),
        Vec2(5, -20),
        Vec2(18, 15),
        Vec2(25, -10)
    ]

    private var t: Float = 0
    private let speed: Float = 0.3

    private let grabRadius: Float = 4
    private var dragIndex: Int? = nil
    private var wasTouching = false

    private var ui: DemoSceneUI!
    private var textures = [Int]()

    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input

        ["playerShip1_blue", "playerShip1_green", "playerShip1_orange"].forEach {
            textures.append(renderer.loadTexture(name: $0, ext: "png", isMipmaped: true))
        }

        renderer.setCamera(point: Vec3(0, 0, Camera2D.defaultDistance))
        renderer.setPerspective(
            fov: GameMath.degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
        renderer.setClearColor(color: Vec3(0.05, 0.1, 0.15))

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, sceneType: .bezierDemo, target: self,
            prevAction: #selector(onPrev), nextAction: #selector(onNext),
            pauseAction: #selector(onPause))
    }

    func resume() { ui.view.isHidden = false }

    func resize() {
        ui.layout()
        renderer.setPerspective(
            fov: GameMath.degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
    }

    func update(dt: Float) {
        handleDrag()

        // Advance t along the full path (0→2 maps to two segments)
        t += speed * dt
        if t > 2 { t -= 2 }

        // Evaluate position on chained curves
        let pos = evaluatePath(at: t)
        ship.position.set(pos.x, pos.y)

        // Orient along tangent
        let lookAhead = t + 0.02 < 2 ? t + 0.02 : t + 0.02 - 2
        let next = evaluatePath(at: lookAhead)
        let dir = next - pos
        if dir.lengthSquared > GameMath.epsilon {
            ship.rotation = atan2(dir.y, dir.x)
        }

        // Sync control point visuals
        for i in 0..<controlPoints.count {
            controlPointShips[i].position.set(controlPoints[i].x, controlPoints[i].y)
        }
    }

    func draw() {
        let worldUniforms = WorldUniform()
        renderer.beginPass()
        renderer.usePerspective()

        for cp in controlPointShips {
            renderer.useTexture(textureId: cp.textureID)
            worldUniforms.transform.setToTransform2D(
                scale: cp.scale, angle: cp.rotation,
                translate: Vec3(cp.position, cp.zOrder))
            renderer.draw(uniforms: worldUniforms)
        }

        renderer.useTexture(textureId: ship.textureID)
        worldUniforms.transform.setToTransform2D(
            scale: ship.scale, angle: ship.rotation,
            translate: Vec3(ship.position, ship.zOrder))
        renderer.draw(uniforms: worldUniforms)

        renderer.endPass()
    }

    func shutdown() {
        ui.removeFromSuperview()
        textures.forEach { renderer.unloadTexture(textureId: $0) }
        textures.removeAll()
    }

    // MARK: - Private

    private func getFOV() -> Float {
        renderer.screenWidth <= renderer.screenHeight ? 90 : 45
    }

    /// Evaluates the chained bezier path. t in [0,1) = first segment, [1,2) = second.
    private func evaluatePath(at t: Float) -> Vec2 {
        if t < 1 {
            return GameMath.cubicBezier(
                p0: controlPoints[0], p1: controlPoints[1],
                p2: controlPoints[2], p3: controlPoints[3], t: t)
        } else {
            return GameMath.cubicBezier(
                p0: controlPoints[3], p1: controlPoints[4],
                p2: controlPoints[5], p3: controlPoints[6], t: t - 1)
        }
    }

    private func handleDrag() {
        guard let touch = input.getWorldTouch(forZ: 0) else {
            wasTouching = false
            dragIndex = nil
            return
        }

        let touchPos = Vec2(touch.x, touch.y)

        if !wasTouching {
            // New touch — find closest control point within grab radius
            var bestDist: Float = grabRadius * grabRadius
            var bestIndex: Int? = nil
            for i in 0..<controlPoints.count {
                let dist = (touchPos - controlPoints[i]).lengthSquared
                if dist < bestDist {
                    bestDist = dist
                    bestIndex = i
                }
            }
            dragIndex = bestIndex
        }

        if let index = dragIndex {
            controlPoints[index] = touchPos
        }

        wasTouching = true
    }

    private func createObjects() {
        ship = GameObj()
        ship.scale.set(2, 2)
        ship.textureID = textures[0]
        ship.zOrder = -1

        controlPointShips.removeAll()
        for i in 0..<controlPoints.count {
            let cp = GameObj()
            cp.position.set(controlPoints[i].x, controlPoints[i].y)
            let isPassThrough = (i == 0 || i == 3 || i == 6)
            cp.scale.set(isPassThrough ? 4 : 3, isPassThrough ? 4 : 3)
            cp.textureID = isPassThrough ? textures[1] : textures[2]
            cp.zOrder = 0
            controlPointShips.append(cp)
        }
    }

    @objc func onPrev() { if let s = SceneTypes.bezierDemo.prev() { sceneMgr.setScene(type: s) } }
    @objc func onNext() { if let s = SceneTypes.bezierDemo.next() { sceneMgr.setScene(type: s) } }
    @objc func onPause() { ui.view.isHidden = true; sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    static func build() -> Scene { return BezierDemo() }
}
