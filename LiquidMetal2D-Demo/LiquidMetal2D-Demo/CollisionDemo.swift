//
//  CollisionDemo.swift
//  LiquidMetal2D-Demo
//
//  Originally CollisionScene by Matt Casanova on 3/24/20.
//

import UIKit
import LiquidMetal2D

/// Collision detection and AI state machine demo.
///
/// **What the user sees:** Ships spawn one per second (up to 200), wandering autonomously.
/// Each ship picks a random target point, rotates to face it, moves to it, then repeats.
/// Most ships are blue, but there is a 1% chance of spawning orange. When an orange ship
/// collides with a blue ship, the blue ship turns orange -- creating a spreading "infection."
///
/// **Engine features demonstrated:**
/// - **CircleCollider:** `CircleCollider(obj:radius:)` creates a circle collider centered on
///   the object's position. `doesCollideWith(collider:)` performs circle-circle intersection.
/// - **FindAndGoBehavior (3-state AI):** A multi-state Behavior with three states:
///   - **FindState:** Picks a random target position within world bounds.
///   - **RotateState:** Rotates the ship toward the target using cross product for turn direction.
///   - **GoState:** Moves forward until reaching the target, then loops back to FindState.
/// - **Scheduler for spawning:** A repeating ScheduledTask spawns one ship per second by
///   finding the first inactive object in the pool and activating it.
/// - **Object pooling (isActive flag):** All 200 CollisionObjs are pre-allocated. The `isActive`
///   flag controls which ones update and draw. Active objects are sorted to the front so the
///   draw loop can `break` early when it hits an inactive object.
/// - **NilBehavior / NilCollider:** Default no-op implementations of Behavior and Collider.
///   Inactive objects use these so update/collision calls are safe without nil checks.
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

    /// Scene protocol: called once when the scene is created.
    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input

        ["playerShip1_blue", "playerShip1_green", "playerShip1_orange"].forEach {
            textures.append(renderer.loadTexture(name: $0, ext: "png", isMipmaped: true))
        }

        // Camera2D.defaultDistance is the engine's suggested starting camera z position
        renderer.setCamera(point: Vec3(0, 0, Camera2D.defaultDistance))
        renderer.setPerspective(
            fov: GameMath.degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, target: self,
            menuAction: #selector(onMenu))

        // Spawn one ship per second using a repeating scheduled task (no count = infinite).
        // Uses the object pool pattern: find the last inactive object and activate it.
        scheduler.add(task: ScheduledTask(time: 1, action: { [unowned self] in
            // Find an inactive object from the pool to reuse
            let obj = self.objects.last(where: { !$0.isActive })
            guard let safeObj = obj else { return }

            // getWorldBoundsFromCamera computes visible area at z=0 using current camera position
            let bounds = self.renderer.getWorldBoundsFromCamera(zOrder: 0)

            // 1% chance of spawning orange (the "infection" seed)
            let chance = Int.random(in: 0..<100)

            safeObj.scale = Vec2(2, 2)
            safeObj.textureID = self.textures[chance == 0 ? self.orangeTextureIndex : 0]
            safeObj.isActive = true

            // FindAndGoBehavior is the 3-state AI: Find -> Rotate -> Go -> Find (loop)
            safeObj.behavior = FindAndGoBehavior(obj: safeObj, bounds: bounds)

            // CircleCollider wraps the object with a collision circle of the given radius
            safeObj.collider = CircleCollider(obj: safeObj, radius: 1)
        }))
    }

    /// Scene protocol: re-show the menu button when returning from PauseDemo.
    func resume() { ui.view.isHidden = false }

    /// Scene protocol: called on device rotation. Recalculate projection and recreate objects
    /// because the visible world bounds have changed.
    func resize() {
        renderer.setPerspective(
            fov: GameMath.degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
        ui.layout()
        // Recreate objects on resize since world bounds changed
        createObjects()
    }

    func update(dt: Float) {
        // Advance the spawn timer
        scheduler.update(dt: dt)

        // Update all objects' behaviors (inactive objects use NilBehavior, which is a no-op)
        for i in 0..<objects.count { objects[i].behavior.update(dt: dt) }

        // Check for collisions between active objects
        checkCollision()

        // Sort active objects to the front of the array so draw() can break early.
        // toInt() converts Bool to 0/1; active (1) sorts before inactive (0) in descending order.
        objects.sort(by: { $0.isActive.toInt() > $1.isActive.toInt() })
    }

    func draw() {
        let worldUniforms = WorldUniform()
        renderer.beginPass()
        renderer.usePerspective()

        for i in 0..<objects.count {
            let obj = objects[i]
            // Early exit: since active objects are sorted first, hitting an inactive one
            // means all remaining objects are also inactive -- skip them.
            if !obj.isActive { break }
            renderer.useTexture(textureId: obj.textureID)
            worldUniforms.transform.setToTransform2D(
                scale: obj.scale, angle: obj.rotation,
                translate: Vec3(obj.position, obj.zOrder))
            renderer.draw(uniforms: worldUniforms)
        }

        renderer.endPass()
    }

    /// Scene protocol: clean up everything -- objects, textures, scheduler, and UI.
    func shutdown() {
        objects.removeAll()
        textures.forEach(renderer.unloadTexture(textureId:))
        scheduler.clear()
        ui.removeFromSuperview()
    }

    /// Pre-allocate the full pool of CollisionObjs. They start inactive (isActive = false)
    /// with NilBehavior and NilCollider, and get activated one per second by the scheduler.
    private func createObjects() {
        objects.removeAll()
        for _ in 0..<objectCount { objects.append(CollisionObj()) }
    }

    private func getFOV() -> Float {
        renderer.screenWidth <= renderer.screenHeight ? 90 : 45
    }

    /// O(n^2) brute-force collision check. For each pair of active objects, if at least one
    /// is orange and they collide (circle-circle), both become orange. This creates the
    /// spreading "infection" effect.
    private func checkCollision() {
        for i in 0..<objects.count {
            let first = objects[i]
            guard first.isActive else { continue }
            for j in (i + 1)..<objects.count {
                let second = objects[j]
                guard second.isActive else { continue }

                // Only check collision if at least one ship is orange (infected)
                if (first.textureID == textures[orangeTextureIndex] ||
                    second.textureID == textures[orangeTextureIndex]) &&
                    // doesCollideWith performs circle-circle intersection test
                    first.collider.doesCollideWith(collider: second.collider) {
                    // Both ships become orange on collision (infection spreads)
                    first.textureID = textures[orangeTextureIndex]
                    second.textureID = textures[orangeTextureIndex]
                }
            }
        }
    }

    /// Push PauseDemo on top of this scene.
    @objc func onMenu() { ui.view.isHidden = true; sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    /// Required factory method for TSceneBuilder.
    static func build() -> Scene { return CollisionDemo() }
}
