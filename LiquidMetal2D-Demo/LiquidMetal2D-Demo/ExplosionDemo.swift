//
//  ExplosionDemo.swift
//  LiquidMetal2D-Demo
//
//  Originally SecondScene by Matt Casanova on 3/13/20.
//

import UIKit
import simd
import LiquidMetal2D

/// Explosion demo: 4500 ships spawn at center and fly outward in random directions.
/// Touch the screen to rotate ALL ships toward the touch point simultaneously.
/// Background cycles between cyan and red. Uses DefaultScene delegation pattern.
/// Demonstrates: mass rendering, random velocity, touch-to-rotate all objects, DefaultScene helper.
class ExplosionDemo: Scene, @unchecked Sendable {
    var sceneDelegate = DefaultScene()

    var changeTime: Float = 0
    let maxChangeTime: Float = 2
    var distance: Float = 40
    let objectCount = 4500

    var startColor = simd_float3(0, 1, 1)
    var endColor = simd_float3(1, 0, 0)

    private var ui: DemoSceneUI!
    private var textures = [Int]()

    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        sceneDelegate.initialize(sceneMgr: sceneMgr, renderer: renderer, input: input)

        ["playerShip1_blue", "playerShip1_green", "playerShip1_orange"].forEach {
            textures.append(renderer.loadTexture(name: $0, ext: "png", isMipmaped: true))
        }

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, sceneType: .explosionDemo, target: self,
            prevAction: #selector(onPrev), nextAction: #selector(onNext),
            pauseAction: #selector(onPause))
    }

    func resume() { ui.view.isHidden = false }

    func resize() {
        sceneDelegate.resize()
        ui.layout()
    }

    func update(dt: Float) {
        changeTime += dt
        let t = changeTime / maxChangeTime
        sceneDelegate.renderer.setClearColor(
            color: simd_mix(startColor, endColor, simd_float3(repeating: t)))
        sceneDelegate.renderer.setCamera(point: simd_float3(0, 0, distance))

        let vec = sceneDelegate.input.getWorldTouch(forZ: 0)

        if changeTime >= maxChangeTime {
            changeTime = 0
            let temp = startColor
            startColor = endColor
            endColor = temp
        }

        for i in 0..<objectCount {
            let obj = sceneDelegate.objects[i]
            obj.position += obj.velocity * dt
            if let v = vec { obj.rotation = atan2(v.y, v.x) }
            if simd_length_squared(obj.position) >= 3600 { randomize(obj: obj) }
        }

        sceneDelegate.objects.sort(by: { $0.zOrder < $1.zOrder })
    }

    func draw() { sceneDelegate.draw() }

    func shutdown() {
        ui.removeFromSuperview()
    }

    private func createObjects() {
        sceneDelegate.objects.removeAll()
        for _ in 0..<objectCount {
            let obj = GameObj()
            randomize(obj: obj)
            sceneDelegate.objects.append(obj)
        }
    }

    private func randomize(obj: GameObj) {
        obj.position.set(0, 0)
        let scale = Float.random(in: 0.25...5)
        obj.scale.set(scale, scale)
        obj.textureID = textures[Int.random(in: 0...2)]
        obj.rotation = Float.random(in: 0...twoPi)
        obj.velocity.set(angle: obj.rotation)
        obj.velocity *= Float.random(in: 1...10)
    }

    @objc func onPrev() { if let s = SceneTypes.explosionDemo.prev() { sceneDelegate.sceneMgr.setScene(type: s) } }
    @objc func onNext() { if let s = SceneTypes.explosionDemo.next() { sceneDelegate.sceneMgr.setScene(type: s) } }
    @objc func onPause() { ui.view.isHidden = true; sceneDelegate.sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    static func build() -> Scene { return ExplosionDemo() }
}
