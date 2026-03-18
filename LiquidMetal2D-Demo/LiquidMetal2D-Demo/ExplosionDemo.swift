//
//  ExplosionDemo.swift
//  LiquidMetal2D-Demo
//
//  Originally SecondScene by Matt Casanova on 3/13/20.
//

import UIKit
import LiquidMetal2D

/// Explosion / radial burst demo with touch-to-rotate.
///
/// **What the user sees:** 4,500 ships spawn at the center and fly outward in random
/// directions at varying speeds. When the user touches the screen, ALL ships instantly
/// rotate to face the touch point. Ships that travel too far from center respawn.
/// The background smoothly cycles between cyan and red.
///
/// **Engine features demonstrated:**
/// - **DefaultScene delegation:** Instead of implementing Scene protocol methods directly,
///   this scene delegates camera setup, drawing, and resize to a `DefaultScene` helper.
///   This is useful when you want standard camera/projection behavior without boilerplate.
/// - **Mass rendering with velocity:** Each ship has a random velocity vector. Position is
///   updated via `obj.position += obj.velocity * dt` for simple physics.
/// - **Touch rotation:** `input.getWorldTouch(forZ:)` provides the touch in world space.
///   `atan2` computes the angle from origin to touch, applied to all ships simultaneously.
/// - **Z-order sorting:** Ships are sorted by `zOrder` each frame for correct draw order.
/// - **Vec2 angle constructor:** `obj.velocity.set(angle:)` creates a unit vector from a
///   rotation angle, which is then scaled by a random speed.
///
/// **DefaultScene delegation pattern:**
/// Instead of implementing all Scene protocol methods from scratch, you can create a
/// `DefaultScene` instance and delegate common work (camera setup, projection, drawing)
/// to it. You still implement the Scene protocol yourself, but forward calls you do not
/// want to customize. This avoids boilerplate while keeping full control over update logic.
class ExplosionDemo: Scene, @unchecked Sendable {
    /// DefaultScene handles standard camera/projection setup and provides a draw() that
    /// iterates over its `objects` array. Access its `renderer`, `input`, `sceneMgr`,
    /// and `objects` properties to interact with the engine through the delegate.
    var sceneDelegate = DefaultScene()

    /// Tracks the color interpolation progress (0 to maxChangeTime seconds)
    var changeTime: Float = 0
    /// Duration of one full color crossfade cycle in seconds
    let maxChangeTime: Float = 2
    /// Camera z-distance -- higher values show more of the world
    var distance: Float = 40
    let objectCount = GameConstants.MAX_OBJECTS

    var startColor = Vec3(0, 1, 1)
    var endColor = Vec3(1, 0, 0)

    private var ui: DemoSceneUI!
    private var textures = [Int]()

    /// Scene protocol: called once when the scene is created.
    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        // Delegate initialization sets up the camera at Camera2D.defaultDistance,
        // configures the perspective projection, and stores references to sceneMgr,
        // renderer, and input so you can access them via sceneDelegate.renderer, etc.
        sceneDelegate.initialize(sceneMgr: sceneMgr, renderer: renderer, input: input)

        ["playerShip1_blue", "playerShip1_green", "playerShip1_orange"].forEach {
            textures.append(renderer.loadTexture(name: $0, ext: "png", isMipmaped: true))
        }

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, target: self,
            menuAction: #selector(onMenu))
    }

    /// Scene protocol: re-show the menu button when returning from PauseDemo.
    func resume() { ui.view.isHidden = false }

    /// Scene protocol: called on device rotation. Delegate handles projection recalculation.
    func resize() {
        // DefaultScene.resize() recalculates the perspective projection for the new screen aspect ratio
        sceneDelegate.resize()
        ui.layout()
    }

    func update(dt: Float) {
        // Smoothly interpolate background color using simd_mix (component-wise lerp)
        changeTime += dt
        let t = changeTime / maxChangeTime
        sceneDelegate.renderer.setClearColor(
            color: simd_mix(startColor, endColor, Vec3(repeating: t)))
        sceneDelegate.renderer.setCamera(point: Vec3(0, 0, distance))

        // getWorldTouch returns the touch position in world-space at z=0, or nil if no touch
        let vec = sceneDelegate.input.getWorldTouch(forZ: 0)

        // Swap colors when the interpolation completes one full cycle
        if changeTime >= maxChangeTime {
            changeTime = 0
            let temp = startColor
            startColor = endColor
            endColor = temp
        }

        for i in 0..<objectCount {
            let obj = sceneDelegate.objects[i]

            // Simple position integration: move by velocity * delta time
            obj.position += obj.velocity * dt

            // If touch is active, rotate all ships to face the touch direction
            if let v = vec { obj.rotation = atan2(v.y, v.x) }

            // Respawn ships that fly too far from center (60 units squared = 3600)
            if simd_length_squared(obj.position) >= 3600 { randomize(obj: obj) }
        }

        // Sort by zOrder for correct back-to-front rendering
        sceneDelegate.objects.sort(by: { $0.zOrder < $1.zOrder })
    }

    /// Delegate drawing entirely to DefaultScene, which iterates over objects
    /// and submits draw calls with each object's transform
    func draw() { sceneDelegate.draw() }

    /// Scene protocol: clean up UI overlays.
    /// Note: DefaultScene does not own textures, so the scene should unload them if needed.
    /// This demo does not unload textures explicitly (a simplification for the demo).
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

    /// Respawn a ship at center with random scale, rotation, and outward velocity.
    private func randomize(obj: GameObj) {
        obj.position.set(0, 0)
        let scale = Float.random(in: 0.25...5)
        obj.scale.set(scale, scale)
        obj.textureID = textures[Int.random(in: 0...2)]

        // GameMath.twoPi is a convenience constant for 2 * pi
        obj.rotation = Float.random(in: 0...GameMath.twoPi)

        // set(angle:) creates a unit direction vector from the rotation angle
        obj.velocity.set(angle: obj.rotation)
        // Scale the unit vector by a random speed
        obj.velocity *= Float.random(in: 1...10)
    }

    /// Push PauseDemo on top. Access sceneMgr through the delegate when using DefaultScene.
    @objc func onMenu() { ui.view.isHidden = true; sceneDelegate.sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    /// Required factory method for TSceneBuilder. Every Scene must provide this.
    static func build() -> Scene { return ExplosionDemo() }
}
