//
//  VisualDemo.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/8/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import UIKit
import LiquidMetal2D

/// Mass rendering demo: 4500 ships at different z-depths (0-60) moving right across screen.
/// Camera oscillates back and forth via sine wave. Background color cycles every 2 seconds
/// using the Scheduler. Demonstrates: z-order sorting, camera movement, Scheduler, mass rendering.
class VisualDemo: Scene, @unchecked Sendable {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    var backgroundTime: Float = 0
    let maxBackgroundChangeTime: Float = 2

    var cameraTime: Float = 0.0
    var camDistance: Float = 30
    var distance: Float = 40

    let objectCount = GameConstants.MAX_OBJECTS
    var objects = [BehaviorObj]()

    var startColor = Vec3(0.7, 0, 0.7)
    var endColor = Vec3(0.0, 1, 1.0)

    private var ui: DemoSceneUI!
    private let scheduler = Scheduler()
    private var textures = [Int]()

    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input

        ["playerShip1_blue", "playerShip1_green", "playerShip1_orange"].forEach {
            textures.append(renderer.loadTexture(name: $0, ext: "png", isMipmaped: true))
        }

        renderer.setCamera(point: Vec3(0, 0, distance))
        renderer.setPerspective(
            fov: GameMath.degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)

        scheduler.add(task: ScheduledTask(time: maxBackgroundChangeTime, action: { [unowned self] in
            self.backgroundTime = 0
            let temp = self.startColor
            self.startColor = self.endColor
            self.endColor = temp
        }))

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, sceneType: .visualDemo, target: self,
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
        scheduler.update(dt: dt)

        cameraTime += dt * 0.5
        let newDist = -sinf(cameraTime) * camDistance + distance
        renderer.setCamera(point: Vec3(0, 0, newDist))

        backgroundTime += dt
        let t = backgroundTime / maxBackgroundChangeTime
        renderer.setClearColor(color: simd_mix(startColor, endColor, Vec3(repeating: t)))

        for i in 0..<objectCount {
            objects[i].behavior.update(dt: dt)
        }

        objects.sort(by: { $0.zOrder < $1.zOrder })
    }

    func draw() {
        let worldUniforms = WorldUniform()
        renderer.beginPass()
        renderer.usePerspective()

        for i in 0..<objectCount {
            let obj = objects[i]
            renderer.useTexture(textureId: obj.textureID)
            worldUniforms.transform.setToTransform2D(
                scale: obj.scale, angle: obj.rotation,
                translate: Vec3(obj.position, obj.zOrder))
            renderer.draw(uniforms: worldUniforms)
        }

        renderer.endPass()
    }

    func shutdown() {
        objects.removeAll()
        scheduler.clear()
        ui.removeFromSuperview()
        textures.forEach { renderer.unloadTexture(textureId: $0) }
        textures.removeAll()
    }

    private func getFOV() -> Float {
        renderer.screenWidth <= renderer.screenHeight ? 90 : 45
    }

    private func createObjects() {
        objects.removeAll()
        let getBounds = { [unowned self] (zOrder: Float) -> WorldBounds in
            self.renderer.getWorldBounds(cameraDistance: self.distance + self.camDistance, zOrder: zOrder)
        }
        for _ in 0..<objectCount {
            let obj = BehaviorObj()
            obj.behavior = MoveRightBehavior(obj: obj, getBounds: getBounds, textures: textures)
            objects.append(obj)
        }
    }

    @objc func onPrev() { if let s = SceneTypes.visualDemo.prev() { sceneMgr.setScene(type: s) } }
    @objc func onNext() { if let s = SceneTypes.visualDemo.next() { sceneMgr.setScene(type: s) } }
    @objc func onPause() { ui.view.isHidden = true; sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    static func build() -> Scene { return VisualDemo() }
}
