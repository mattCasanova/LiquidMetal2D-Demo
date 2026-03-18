//
//  StateDemo.swift
//  LiquidMetal2D-Demo
//
//  Originally StateTestScene by Matt Casanova on 3/20/20.
//

import UIKit
import LiquidMetal2D

/// Touch-spawn demo: Ships spawn at the touch location and fly outward in
/// random directions with varying speeds and scales. Ships ease out as they
/// spawn (scale from 0 to full over a short duration). Touch to redirect.
/// Demonstrates: touch input (world coords), RandomAngleBehavior, easing.
class StateDemo: Scene, @unchecked Sendable {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    let distance: Float = 40
    let objectCount = GameConstants.MAX_OBJECTS
    var objects = [BehaviorObj]()

    var spawnPos = Vec2()
    private var spawnAge = [Float]()
    private let spawnEaseDuration: Float = 0.3

    private var ui: DemoSceneUI!
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
        renderer.setClearColor(color: Vec3(0.1, 0.05, 0.15))

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, sceneType: .stateDemo, target: self,
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
        if let touch = input.getWorldTouch(forZ: 0) {
            spawnPos.set(touch.x, touch.y)
        }

        for i in 0..<objectCount {
            objects[i].behavior.update(dt: dt)

            // Ease in the scale on spawn
            if spawnAge[i] < spawnEaseDuration {
                spawnAge[i] += dt
                let t = min(spawnAge[i] / spawnEaseDuration, 1.0)
                let eased = Easing.easeOutBack(t)
                let baseScale = objects[i].zOrder // stash base scale in zOrder
                objects[i].scale.set(baseScale * eased, baseScale * eased)
            }
        }

        objects.sort(by: { $0.scale.x < $1.scale.x })
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
                translate: Vec3(obj.position, 0))
            renderer.draw(uniforms: worldUniforms)
        }

        renderer.endPass()
    }

    func shutdown() {
        objects.removeAll()
        spawnAge.removeAll()
        ui.removeFromSuperview()
        textures.forEach { renderer.unloadTexture(textureId: $0) }
        textures.removeAll()
    }

    private func getFOV() -> Float {
        renderer.screenWidth <= renderer.screenHeight ? 90 : 45
    }

    private func createObjects() {
        objects.removeAll()
        spawnAge.removeAll()

        let bounds = renderer.getWorldBoundsFromCamera(zOrder: 0)
        let getSpawnLocation = { [unowned self] in self.spawnPos }
        let getBounds = { bounds }

        for _ in 0..<objectCount {
            let obj = BehaviorObj()
            obj.behavior = RandomAngleBehavior(
                obj: obj, getSpawnLocation: getSpawnLocation,
                getBounds: getBounds, textures: textures)
            objects.append(obj)
            spawnAge.append(spawnEaseDuration) // start fully eased in
        }
    }

    @objc func onPrev() { if let s = SceneTypes.stateDemo.prev() { sceneMgr.setScene(type: s) } }
    @objc func onNext() { if let s = SceneTypes.stateDemo.next() { sceneMgr.setScene(type: s) } }
    @objc func onPause() { ui.view.isHidden = true; sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    static func build() -> Scene { return StateDemo() }
}
