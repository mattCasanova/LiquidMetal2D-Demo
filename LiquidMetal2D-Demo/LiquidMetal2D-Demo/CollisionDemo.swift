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
class CollisionDemo: Scene {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    private let objectCount = 200
    private var objects = [CollisionObj]()

    private let scheduler = Scheduler()
    private var textures = [Int]()
    private let blueIndex = 0    // normal (vulnerable)
    private let greenIndex = 1   // cure (immune, spreads immunity)
    private let redIndex = 2     // infected (zombie)

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

        // Spawn 20 ships immediately so the scene starts populated
        for _ in 0..<20 { spawnShip() }

        ui = DemoSceneUI(
            parentView: renderer.view, target: self,
            menuAction: #selector(onMenu))

        // Spawn one ship per second using a repeating scheduled task
        scheduler.add(task: ScheduledTask(time: 1, action: { [unowned self] in
            self.spawnShip()
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

    private let maxAge: Float = 30.0

    func update(dt: Float) {
        // Advance the spawn timer
        scheduler.update(dt: dt)

        // Update all objects' behaviors and age them
        let redTex = textures[redIndex]
        for i in 0..<objects.count {
            let obj = objects[i]
            guard obj.isActive else { continue }

            obj.behavior.update(dt: dt)
            obj.age += dt

            // Blue and green die of natural causes after maxAge seconds.
            // Zombies (red) persist forever — only green can kill them.
            if obj.textureID != redTex && obj.age >= maxAge {
                obj.isActive = false
            }
        }

        checkCollision()

        objects.sort(by: { $0.isActive.toInt() > $1.isActive.toInt() })
    }

    func draw() {
        guard renderer.beginPass() else { return }
        renderer.usePerspective()
        renderer.submit(objects: objects)
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
        for _ in 0..<objectCount {
            let obj = CollisionObj()
            obj.isActive = false
            objects.append(obj)
        }
    }

    private func getFOV() -> Float {
        renderer.screenWidth <= renderer.screenHeight ? 90 : 45
    }

    private func spawnShip() {
        guard let obj = objects.last(where: { !$0.isActive }) else { return }
        let bounds = renderer.getWorldBoundsFromCamera(zOrder: 0)

        let roll = Int.random(in: 0..<100)
        let texIndex: Int
        if roll < 5 { texIndex = redIndex }
        else if roll < 8 { texIndex = greenIndex }
        else { texIndex = blueIndex }

        obj.scale = Vec2(2, 2)
        obj.textureID = textures[texIndex]
        obj.tintColor = TokyoNight.shipTints[texIndex]
        obj.age = 0
        obj.isActive = true
        obj.behavior = FindAndGoBehavior(obj: obj, bounds: bounds)
        obj.collider = CircleCollider(obj: obj, radius: 1)
    }

    private func setType(_ obj: CollisionObj, index: Int) {
        obj.textureID = textures[index]
        obj.tintColor = TokyoNight.shipTints[index]
    }

    /// O(n^2) brute-force collision check with zombie/cure mechanics:
    /// - Red (zombie) touches blue (normal) → blue becomes red
    /// - Green (cure) touches red (zombie) → red dies (deactivated)
    /// - Green (cure) touches blue (normal) → blue becomes green (immune)
    /// - Green is immune to infection
    private func checkCollision() {
        let redTex = textures[redIndex]
        let blueTex = textures[blueIndex]
        let greenTex = textures[greenIndex]

        for i in 0..<objects.count {
            let first = objects[i]
            guard first.isActive else { continue }
            for j in (i + 1)..<objects.count {
                let second = objects[j]
                guard second.isActive else { continue }
                guard first.collider.doesCollideWith(collider: second.collider) else { continue }

                let fTex = first.textureID
                let sTex = second.textureID

                // Red + Blue → Blue becomes Red (infection)
                if fTex == redTex && sTex == blueTex {
                    setType(second, index: redIndex)
                } else if sTex == redTex && fTex == blueTex {
                    setType(first, index: redIndex)

                // Green touches anything → they become green (cure spreads to all)
                } else if fTex == greenTex && sTex != greenTex {
                    setType(second, index: greenIndex)
                } else if sTex == greenTex && fTex != greenTex {
                    setType(first, index: greenIndex)
                }
            }
        }
    }

    /// Push PauseDemo on top of this scene.
    @objc func onMenu() { ui.view.isHidden = true; sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    /// Required factory method for TSceneBuilder.
    static func build() -> Scene { return CollisionDemo() }
}
