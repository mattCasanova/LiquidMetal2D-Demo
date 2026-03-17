//
//  BezierDemo.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/17/26.
//

import UIKit
import LiquidMetal2D

/// Bezier curve demo: A ship follows a cubic bezier path defined by 4 control
/// points. Touch the screen to move the draggable control point (p1).
/// Demonstrates: GameMath.cubicBezier, touch input, orientation along curve.
class BezierDemo: Scene, @unchecked Sendable {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    private var ship: GameObj!
    private var controlPointShips = [GameObj]()

    private var p0 = Vec2(-20, -15)
    private var p1 = Vec2(-10, 20)
    private var p2 = Vec2(10, 20)
    private var p3 = Vec2(20, -15)

    private var t: Float = 0
    private let speed: Float = 0.4

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
        // Touch moves control point p1
        if let touch = input.getWorldTouch(forZ: 0) {
            p1.set(touch.x, touch.y)
            controlPointShips[1].position.set(p1.x, p1.y)
        }

        // Advance t along the curve
        t += speed * dt
        if t > 1 { t -= 1 }

        // Position ship on curve
        let pos = GameMath.cubicBezier(p0: p0, p1: p1, p2: p2, p3: p3, t: t)
        ship.position.set(pos.x, pos.y)

        // Orient ship along curve tangent (sample a point slightly ahead)
        let lookAhead = min(t + 0.02, 1.0)
        let next = GameMath.cubicBezier(p0: p0, p1: p1, p2: p2, p3: p3, t: lookAhead)
        let dir = next - pos
        if dir.lengthSquared > GameMath.epsilon {
            ship.rotation = atan2(dir.y, dir.x)
        }
    }

    func draw() {
        let worldUniforms = WorldUniform()
        renderer.beginPass()
        renderer.usePerspective()

        // Draw control points first (behind the ship)
        for cp in controlPointShips {
            renderer.useTexture(textureId: cp.textureID)
            worldUniforms.transform.setToTransform2D(
                scale: cp.scale, angle: cp.rotation,
                translate: Vec3(cp.position, cp.zOrder))
            renderer.draw(uniforms: worldUniforms)
        }

        // Draw the main ship
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

    private func getFOV() -> Float {
        renderer.screenWidth <= renderer.screenHeight ? 90 : 45
    }

    private func createObjects() {
        ship = GameObj()
        ship.scale.set(2, 2)
        ship.textureID = textures[0]
        ship.zOrder = -1

        let points = [p0, p1, p2, p3]
        controlPointShips.removeAll()
        for i in 0..<4 {
            let cp = GameObj()
            cp.position.set(points[i].x, points[i].y)
            cp.scale.set(0.8, 0.8)
            cp.textureID = textures[i == 1 ? 2 : 1]
            cp.zOrder = 0
            controlPointShips.append(cp)
        }
    }

    @objc func onPrev() { if let s = SceneTypes.bezierDemo.prev() { sceneMgr.setScene(type: s) } }
    @objc func onNext() { if let s = SceneTypes.bezierDemo.next() { sceneMgr.setScene(type: s) } }
    @objc func onPause() { ui.view.isHidden = true; sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    static func build() -> Scene { return BezierDemo() }
}
