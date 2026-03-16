//
//  CollisionDemo.swift
//  LiquidMetal2D-Demo
//
//  Originally CollisionScene by Matt Casanova on 3/24/20.
//

import UIKit
import simd
import LiquidMetal2D

/// Collision + AI demo: Ships spawn one per second (up to 200) and wander using FindAndGo AI.
/// Each ship picks a random target, rotates toward it, moves to it, then picks a new target.
/// There's a 1% chance each spawn is orange. When an orange ship collides with a blue ship,
/// the blue ship turns orange too — creating a spreading "infection" effect.
/// Demonstrates: Collision detection (CircleCollider), AI behavior (FindAndGoBehavoir with
/// Find/Rotate/Go state machine), Scheduler for timed spawning, object pooling (isActive flag).
class CollisionDemo: Scene, @unchecked Sendable {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    private let objectCount = 200
    private var objects = [CollisionObj]()

    private let scheduler = Scheduler()
    private var textures = [Int]()
    private let orangeTextureIndex = 2

    private var ui: DemoSceneUI!

    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input

        ["playerShip1_blue", "playerShip1_green", "playerShip1_orange"].forEach {
            textures.append(renderer.loadTexture(name: $0, ext: "png", isMipmaped: true))
        }

        renderer.setCamera(point: simd_float3(0, 0, Camera2D.defaultDistance))
        renderer.setPerspective(
            fov: GameMath.degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, sceneType: .collisionDemo, target: self,
            prevAction: #selector(onPrev), nextAction: #selector(onNext),
            pauseAction: #selector(onPause))

        scheduler.add(task: ScheduledTask(time: 1, action: { [unowned self] in
            let obj = self.objects.last(where: { !$0.isActive })
            guard let safeObj = obj else { return }

            let bounds = self.renderer.getWorldBoundsFromCamera(zOrder: 0)
            let chance = Int.random(in: 0..<100)

            safeObj.scale = simd_float2(2, 2)
            safeObj.textureID = self.textures[chance == 0 ? self.orangeTextureIndex : 0]
            safeObj.isActive = true
            safeObj.behavoir = FindAndGoBehavoir(obj: safeObj, bounds: bounds)
            safeObj.collider = CircleCollider(obj: safeObj, radius: 1)
        }))
    }

    func resume() { ui.view.isHidden = false }

    func resize() {
        renderer.setPerspective(
            fov: GameMath.degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
        ui.layout()
        createObjects()
    }

    func update(dt: Float) {
        scheduler.update(dt: dt)
        for i in 0..<objects.count { objects[i].behavoir.update(dt: dt) }
        checkCollision()
        objects.sort(by: { $0.isActive.toInt() > $1.isActive.toInt() })
    }

    func draw() {
        let worldUniforms = WorldUniform()
        renderer.beginPass()
        renderer.usePerspective()

        for i in 0..<objects.count {
            let obj = objects[i]
            if !obj.isActive { break }
            renderer.useTexture(textureId: obj.textureID)
            worldUniforms.transform.setToTransform2D(
                scale: obj.scale, angle: obj.rotation,
                translate: simd_float3(obj.position, obj.zOrder))
            renderer.draw(uniforms: worldUniforms)
        }

        renderer.endPass()
    }

    func shutdown() {
        objects.removeAll()
        textures.forEach(renderer.unloadTexture(textureId:))
        scheduler.clear()
        ui.removeFromSuperview()
    }

    private func createObjects() {
        objects.removeAll()
        for _ in 0..<objectCount { objects.append(CollisionObj()) }
    }

    private func getFOV() -> Float {
        renderer.screenWidth <= renderer.screenHeight ? 90 : 45
    }

    private func checkCollision() {
        for i in 0..<objects.count {
            let first = objects[i]
            guard first.isActive else { continue }
            for j in (i + 1)..<objects.count {
                let second = objects[j]
                guard second.isActive else { continue }
                if (first.textureID == textures[orangeTextureIndex] ||
                    second.textureID == textures[orangeTextureIndex]) &&
                    first.collider.doesCollideWith(collider: second.collider) {
                    first.textureID = textures[orangeTextureIndex]
                    second.textureID = textures[orangeTextureIndex]
                }
            }
        }
    }

    @objc func onPrev() { if let s = SceneTypes.collisionDemo.prev() { sceneMgr.setScene(type: s) } }
    @objc func onNext() { if let s = SceneTypes.collisionDemo.next() { sceneMgr.setScene(type: s) } }
    @objc func onPause() { ui.view.isHidden = true; sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    static func build() -> Scene { return CollisionDemo() }
}
