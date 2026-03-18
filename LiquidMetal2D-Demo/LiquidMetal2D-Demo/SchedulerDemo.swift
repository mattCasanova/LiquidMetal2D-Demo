//
//  SchedulerDemo.swift
//  LiquidMetal2D-Demo
//
//  Originally ThirdScene by Matt Casanova on 3/18/20.
//

import UIKit
import LiquidMetal2D

/// Scheduler demo showcasing timed tasks with finite repeat counts and completion callbacks.
///
/// **What the user sees:** 100 ships explode outward from center. The background color
/// swaps every 2 seconds, but only 4 times total. After the 4th swap, the background
/// freezes and all ships respawn -- a visual cue that the onComplete callback fired.
/// Touch rotates all ships toward the touch point.
///
/// **Engine features demonstrated:**
/// - **Scheduler:** The `Scheduler` manages a list of `ScheduledTask` objects. Call
///   `scheduler.update(dt:)` each frame to advance all tasks.
/// - **ScheduledTask with finite count:** `ScheduledTask(time:action:count:onComplete:)`
///   fires `action` every `time` seconds, but only `count` times. After the last fire,
///   `onComplete` is called. This is how you create one-shot sequences or limited loops.
/// - **DefaultScene delegation:** Reuses DefaultScene for camera setup, projection, and drawing.
/// - **simd_mix:** Component-wise linear interpolation for smooth color transitions.
class SchedulerDemo: Scene, @unchecked Sendable {
    var sceneDelegate = DefaultScene()

    /// Becomes false after the scheduled task completes, freezing the background color
    var shouldChange = true
    /// Tracks color interpolation progress (0 to maxChangeTime seconds)
    var changeTime: Float = 0
    /// Duration of one color crossfade cycle in seconds
    let maxChangeTime: Float = 2
    /// Camera z-distance
    var distance: Float = 40
    /// Fewer objects than VisualDemo to keep focus on the scheduler behavior
    let objectCount = 100

    var startColor = Vec3(0, 0.5, 0.7)
    var endColor = Vec3(0.4, 0, 0)

    private var ui: DemoSceneUI!
    private var textures = [Int]()
    private let scheduler = Scheduler()

    /// Scene protocol: called once when the scene is created.
    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        // Delegate handles camera, projection, and stores engine references
        sceneDelegate.initialize(sceneMgr: sceneMgr, renderer: renderer, input: input)

        ["playerShip1_blue", "playerShip1_green", "playerShip1_orange"].forEach {
            textures.append(renderer.loadTexture(name: $0, ext: "png", isMipmaped: true))
        }

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, target: self,
            menuAction: #selector(onMenu))

        // ScheduledTask with count: 4 means the action fires exactly 4 times (every 2 seconds).
        // After the 4th fire, onComplete runs once. Compare with VisualDemo's scheduler which
        // omits count, making it repeat indefinitely.
        //
        // action: fires every `maxChangeTime` seconds -- swaps the two colors
        // count: 4 -- limits how many times action fires
        // onComplete: fires once after all 4 actions complete -- stops color changes and respawns ships
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

    /// Scene protocol: re-show the menu button when returning from PauseDemo.
    func resume() { ui.view.isHidden = false }

    /// Scene protocol: called on device rotation. Delegate recalculates projection.
    func resize() {
        sceneDelegate.resize()
        ui.layout()
    }

    func update(dt: Float) {
        // Advance the scheduler -- this ticks all active ScheduledTasks
        scheduler.update(dt: dt)

        // Only animate background color while the scheduler task is still active
        if shouldChange {
            let t = changeTime / maxChangeTime
            sceneDelegate.renderer.setClearColor(
                color: simd_mix(startColor, endColor, Vec3(repeating: t)))
        } else {
            // After onComplete fires, lock the background to the current startColor
            sceneDelegate.renderer.setClearColor(color: startColor)
        }

        sceneDelegate.renderer.setCamera(point: Vec3(0, 0, distance))
        let vec = sceneDelegate.input.getWorldTouch(forZ: 0)

        for i in 0..<objectCount {
            let obj = sceneDelegate.objects[i]
            obj.position += obj.velocity * dt
            if let v = vec { obj.rotation = atan2(v.y, v.x) }
            // Respawn ships that travel beyond 60 units from center
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

    /// Respawn a ship at center with random properties (same pattern as ExplosionDemo).
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
