//
//  SchedulerDemo.swift
//  LiquidMetal2D-Demo
//
//  Originally ThirdScene by Matt Casanova on 3/18/20.
//

import UIKit
import LiquidMetal2D

/// Scheduler demo showcasing task chaining, finite repeats, and completion callbacks.
///
/// **What the user sees:** 100 ships explode outward from center. The demo cycles through
/// three phases in a continuous loop:
/// 1. Background color crossfades back and forth 4 times (6 seconds)
/// 2. Camera rotates a full 360° (6 seconds)
/// 3. Camera zooms in close then back out (6 seconds), ships respawn, and the cycle restarts
///
/// Touch rotates all ships toward the touch point at any time.
///
/// **Engine features demonstrated:**
/// - **Task chaining:** `task.then(time:action:count:onComplete:)` sequences multiple
///   tasks so each starts automatically when the previous one completes.
/// - **Finite repeat count:** Phase 1 uses `count: 4` to fire exactly 4 times.
/// - **onComplete callbacks:** Each phase's completion triggers the next phase's setup.
/// - **Infinite looping via chaining:** The final onComplete rebuilds the entire chain,
///   creating a self-restarting cycle.
/// - **Camera rotation:** `setCameraRotation(angle:)` rotates the view around the Z axis.
/// - **Camera zoom:** Varying the camera's Z distance changes the visible world area.
/// - **DefaultScene delegation:** Reuses DefaultScene for camera setup, projection, and drawing.
/// - **simd_mix:** Component-wise linear interpolation for smooth color transitions.
class SchedulerDemo: Scene {
    var sceneDelegate = DefaultScene()

    // Phase 1: Color crossfade
    var shouldChange = true
    var changeTime: Float = 0
    let maxChangeTime: Float = 1.5
    var startColor = Vec3(0, 0.5, 0.7)
    var endColor = Vec3(0.4, 0, 0)

    // Phase 2: Camera rotation
    var isRotating = false
    var cameraAngle: Float = 0
    let rotationDuration: Float = 6

    // Phase 3: Camera zoom
    var isZooming = false
    var zoomTime: Float = 0
    let zoomDuration: Float = 6

    let baseDistance: Float = 40
    var distance: Float = 40
    let objectCount = 100

    private var ui: DemoSceneUI!
    private var textures = [Int]()
    private let scheduler = Scheduler()

    /// Scene protocol: called once when the scene is created.
    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        sceneDelegate.initialize(sceneMgr: sceneMgr, renderer: renderer, input: input)

        ["playerShip1_blue", "playerShip1_green", "playerShip1_orange"].forEach {
            textures.append(renderer.loadTexture(name: $0, ext: "png", isMipmaped: true))
        }

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, target: self,
            menuAction: #selector(onMenu))

        buildDemoChain()
    }

    /// Scene protocol: re-show the menu button when returning from PauseDemo.
    func resume() { ui.view.isHidden = false }

    /// Scene protocol: called on device rotation. Delegate recalculates projection.
    func resize() {
        sceneDelegate.resize()
        ui.layout()
    }

    func update(dt: Float) {
        scheduler.update(dt: dt)

        // Phase 1: Smooth color crossfade between swaps
        if shouldChange {
            changeTime += dt
            let t = min(changeTime / maxChangeTime, 1)
            sceneDelegate.renderer.setClearColor(
                color: simd_mix(startColor, endColor, Vec3(repeating: t)))
        } else {
            sceneDelegate.renderer.setClearColor(color: startColor)
        }

        // Phase 2: Smooth 360° camera rotation
        if isRotating {
            cameraAngle += (GameMath.twoPi / rotationDuration) * dt
            sceneDelegate.renderer.setCameraRotation(angle: cameraAngle)
        }

        // Phase 3: Zoom in then back out (sine curve)
        if isZooming {
            zoomTime += dt
            let t = min(zoomTime / zoomDuration, 1)
            distance = baseDistance + 50 * sin(t * .pi)
        }

        sceneDelegate.renderer.setCamera(point: Vec3(0, 0, distance))
        let vec = sceneDelegate.input.getWorldTouch(forZ: 0)

        for i in 0..<objectCount {
            let obj = sceneDelegate.objects[i]
            obj.position += obj.velocity * dt
            if let v = vec { obj.rotation = atan2(v.y, v.x) }
            if simd_length_squared(obj.position) >= 3600 { randomize(obj: obj) }
        }

        sceneDelegate.objects.sort(by: { $0.zOrder < $1.zOrder })
    }

    /// Delegate the entire draw to DefaultScene, which iterates sceneDelegate.objects
    /// and submits draw calls with each object's transform, texture, and zOrder.
    func draw() { sceneDelegate.draw() }

    /// Scene protocol: clean up. Always clear the scheduler to cancel pending tasks,
    /// and unload textures to free GPU memory.
    func shutdown() {
        scheduler.clear()
        sceneDelegate.renderer.setCameraRotation(angle: 0)
        textures.forEach { sceneDelegate.renderer.unloadTexture(textureId: $0) }
        textures.removeAll()
        ui.removeFromSuperview()
    }

    /// Builds the three-phase task chain and adds it to the scheduler.
    /// Called on init and again from the final onComplete to loop forever.
    private func buildDemoChain() {
        // Reset all phase state
        shouldChange = true
        changeTime = 0
        isRotating = false
        cameraAngle = 0
        isZooming = false
        zoomTime = 0
        distance = baseDistance
        startColor = Vec3(0, 0.5, 0.7)
        endColor = Vec3(0.4, 0, 0)
        sceneDelegate.renderer.setCameraRotation(angle: 0)

        // Phase 1: Swap background color 4 times with smooth crossfades
        let colorSwap = ScheduledTask(time: maxChangeTime, action: { [unowned self] in
            self.changeTime = 0
            let temp = self.startColor
            self.startColor = self.endColor
            self.endColor = temp
        }, count: 4, onComplete: { [unowned self] in
            // Phase 1 done — freeze color, start rotation
            self.shouldChange = false
            self.isRotating = true
            self.cameraAngle = 0
        })

        // Phase 2: Camera rotates 360° over rotationDuration seconds
        let rotation = colorSwap.then(time: rotationDuration, action: { [unowned self] in
            self.isRotating = false
            self.cameraAngle = 0
            self.sceneDelegate.renderer.setCameraRotation(angle: 0)
        }, count: 1, onComplete: { [unowned self] in
            // Phase 2 done — start zoom
            self.isZooming = true
            self.zoomTime = 0
        })

        // Phase 3: Zoom in then back out over zoomDuration seconds
        rotation.then(time: zoomDuration, action: { [unowned self] in
            self.isZooming = false
            self.distance = self.baseDistance
        }, count: 1, onComplete: { [unowned self] in
            // All phases done — respawn ships and restart the whole cycle
            self.createObjects()
            self.buildDemoChain()
        })

        scheduler.add(task: colorSwap)
    }

    private func createObjects() {
        sceneDelegate.objects.removeAll()
        for _ in 0..<objectCount {
            let obj = GameObj()
            randomize(obj: obj)
            sceneDelegate.objects.append(obj)
        }
    }

    /// Respawn a ship at center with random properties (same pattern as InstanceDemo).
    private func randomize(obj: GameObj) {
        obj.position.set(0, 0)
        let scale = Float.random(in: 0.25...5)
        obj.scale.set(scale, scale)
        obj.textureID = textures[Int.random(in: 0...2)]
        // Random rotation in full circle
        obj.rotation = Float.random(in: 0...GameMath.twoPi)
        // set(angle:) creates a unit vector from the rotation, then scale by random speed
        obj.velocity.set(angle: obj.rotation)
        obj.velocity *= Float.random(in: 1...10)
    }

    /// Push PauseDemo on top. Access sceneMgr through the delegate.
    @objc func onMenu() { ui.view.isHidden = true; sceneDelegate.sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    /// Required factory method for TSceneBuilder.
    static func build() -> Scene { return SchedulerDemo() }
}
