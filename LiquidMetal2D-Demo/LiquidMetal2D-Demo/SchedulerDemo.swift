//
//  SchedulerDemo.swift
//  LiquidMetal2D-Demo
//
//  Originally ThirdScene by Matt Casanova on 3/18/20.
//

import UIKit
import simd
import LiquidMetal2D

/// Scheduler demo: 100 ships explode outward from center.
/// A scheduled task swaps the background colors every 2 seconds, but only 4 times total.
/// After the 4th swap, the onComplete callback fires — it stops the color animation and recreates objects.
/// Touch rotates all ships toward the touch point.
/// Demonstrates: ScheduledTask with finite repeat count, onComplete callback, task lifecycle.
class SchedulerDemo: Scene, @unchecked Sendable {
    var sceneDelegate = DefaultScene()

    var shouldChange = true
    var changeTime: Float = 0
    let maxChangeTime: Float = 2
    var distance: Float = 40
    let objectCount = 100

    var startColor = simd_float3(0, 0.5, 0.7)
    var endColor = simd_float3(0.4, 0, 0)

    private var ui: DemoSceneUI!
    private var textures = [Int]()
    private let scheduler = Scheduler()

    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        sceneDelegate.initialize(sceneMgr: sceneMgr, renderer: renderer, input: input)

        ["playerShip1_blue", "playerShip1_green", "playerShip1_orange"].forEach {
            textures.append(renderer.loadTexture(name: $0, ext: "png", isMipmaped: true))
        }

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, sceneType: .schedulerDemo, target: self,
            prevAction: #selector(onPrev), nextAction: #selector(onNext),
            pauseAction: #selector(onPause))

        scheduler.add(task: ScheduledTask(time: maxChangeTime, action: { [unowned self] in
            self.changeTime = 0
            let temp = self.startColor
            self.startColor = self.endColor
            self.endColor = temp
        }, count: 4, onComplete: { [unowned self] in
            self.shouldChange = false
            self.createObjects()
        }))
    }

    func resume() { ui.view.isHidden = false }

    func resize() {
        sceneDelegate.resize()
        ui.layout()
    }

    func update(dt: Float) {
        scheduler.update(dt: dt)

        if shouldChange {
            let t = changeTime / maxChangeTime
            sceneDelegate.renderer.setClearColor(
                color: simd_mix(startColor, endColor, simd_float3(repeating: t)))
        } else {
            sceneDelegate.renderer.setClearColor(color: startColor)
        }

        sceneDelegate.renderer.setCamera(point: simd_float3(0, 0, distance))
        let vec = sceneDelegate.input.getWorldTouch(forZ: 0)

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
        scheduler.clear()
        textures.forEach { sceneDelegate.renderer.unloadTexture(textureId: $0) }
        textures.removeAll()
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

    @objc func onPrev() { if let s = SceneTypes.schedulerDemo.prev() { sceneDelegate.sceneMgr.setScene(type: s) } }
    @objc func onNext() { if let s = SceneTypes.schedulerDemo.next() { sceneDelegate.sceneMgr.setScene(type: s) } }
    @objc func onPause() { ui.view.isHidden = true; sceneDelegate.sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    static func build() -> Scene { return SchedulerDemo() }
}
