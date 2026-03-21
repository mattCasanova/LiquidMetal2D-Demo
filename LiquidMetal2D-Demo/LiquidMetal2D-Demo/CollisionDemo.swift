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

    private var ui: DemoSceneUI!

    /// Scene protocol: called once when the scene is created.
    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input

        // Camera2D.defaultDistance is the engine's suggested starting camera z position
        renderer.setCamera()
        renderer.setCameraRotation(angle: 0)
        renderer.setDefaultPerspective()

        createObjects()

        // Spawn 20 ships immediately so the scene starts populated
        for _ in 0..<20 { spawnShip() }

        ui = DemoSceneUI(
            parentView: renderer.view, target: self,
            menuAction: #selector(onMenu))

        // Spawn one ship per second using a repeating scheduled task
        scheduler.add(task: ScheduledTask(time: 1, action: { [unowned self] _ in
            self.spawnShip()
        }))
    }

    /// Scene protocol: re-show the menu button when returning from PauseDemo.
    func resume() { ui.view.isHidden = false }

    /// Scene protocol: called on device rotation. Recalculate projection and recreate objects
    /// because the visible world bounds have changed.
    func resize() {
        renderer.setDefaultPerspective()
        ui.layout()
    }

    private let maxAge: Float = 30.0

    func update(dt: Float) {
        // Advance the spawn timer
        scheduler.update(dt: dt)

        // Update all objects' behaviors and age them
        for i in 0..<objects.count {
            let obj = objects[i]
            guard obj.isActive else { continue }

            obj.behavior.update(dt: dt)
            obj.age += dt

            // Blue and green die after 30s. Zombies persist forever.
            if obj.textureID != GameTextures.orange && obj.age >= maxAge {
                obj.isActive = false
            }
        }

        checkCollision()

        objects.sort(by: { $0.isActive && !$1.isActive })
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

    private func spawnShip() {
        guard let obj = objects.last(where: { !$0.isActive }) else { return }
        let bounds = renderer.getWorldBoundsFromCamera(zOrder: 0)

        // 5% zombie, 2% super zombie. Green only spawns (3%) when 20+ reds exist.
        let redCount = objects.filter { $0.isActive && $0.textureID == GameTextures.orange }.count
        let roll = Int.random(in: 0..<100)
        let texIndex: Int
        let isSuperZombie: Bool
        if roll < 2 {
            texIndex = 2; isSuperZombie = true
        } else if roll < 7 {
            texIndex = 2; isSuperZombie = false
        } else if roll < 10 && redCount >= 20 {
            texIndex = 1; isSuperZombie = false
        } else {
            texIndex = 0; isSuperZombie = false
        }

        obj.position.set(
            Float.random(in: bounds.minX...bounds.maxX),
            Float.random(in: bounds.minY...bounds.maxY))

        obj.isSuper = isSuperZombie
        obj.scale = isSuperZombie ? Vec2(4, 4) : Vec2(2, 2)
        obj.charges = texIndex == 1 ? 3 : (isSuperZombie ? 3 : 0)
        obj.textureID = GameTextures.all[texIndex]
        obj.tintColor = TokyoNight.shipTints[texIndex]
        obj.age = 0
        obj.isActive = true
        obj.behavior = FindAndGoBehavior(obj: obj, bounds: bounds)
        obj.collider = CircleCollider(obj: obj, radius: isSuperZombie ? 2 : 1)
    }

    private func setType(_ obj: CollisionObj, index: Int) {
        obj.textureID = GameTextures.all[index]
        obj.tintColor = TokyoNight.shipTints[index]
        obj.age = 0
    }

    /// O(n^2) brute-force collision check with zombie/cure mechanics:
    /// - Red + Blue → 80% infected, 20% blue dies
    /// - Green + normal Red → red becomes blue, green loses a charge
    /// - Green + super Red → super loses a hit point (dies at 0), green loses a charge
    /// - Green + Blue → blue becomes green (cure spreads)
    private func checkCollision() {
        let redTex = GameTextures.orange
        let blueTex = GameTextures.blue
        let greenTex = GameTextures.green

        for i in 0..<objects.count {
            let first = objects[i]
            guard first.isActive else { continue }
            for j in (i + 1)..<objects.count {
                let second = objects[j]
                guard second.isActive else { continue }
                guard first.collider.doesCollideWith(collider: second.collider) else { continue }

                let fTex = first.textureID
                let sTex = second.textureID

                // Red + Blue → 80% infection, 20% blue dies
                if fTex == redTex && sTex == blueTex {
                    bite(second)
                } else if sTex == redTex && fTex == blueTex {
                    bite(first)

                // Green + Red → cure the zombie, green loses a charge
                } else if fTex == greenTex && sTex == redTex {
                    cure(zombie: second, healer: first)
                } else if sTex == greenTex && fTex == redTex {
                    cure(zombie: first, healer: second)

                // Green + Blue → blue becomes green (cure spreads)
                } else if fTex == greenTex && sTex == blueTex {
                    recruit(second)
                } else if sTex == greenTex && fTex == blueTex {
                    recruit(first)
                }
            }
        }
    }

    /// Convert a blue ship to green (healer). Gets fresh 3 charges.
    private func recruit(_ obj: CollisionObj) {
        setType(obj, index: 1)
        obj.charges = 3
    }

    /// Zombie bite: 80% chance blue becomes red, 20% blue dies.
    private func bite(_ blue: CollisionObj) {
        if Float.random(in: 0...1) < 0.8 {
            setType(blue, index: 2)
            blue.isSuper = false
            blue.charges = 0
        } else {
            blue.isActive = false
        }
    }

    /// Green cures a zombie. Normal zombies become blue. Super zombies
    /// lose a hit point and die when charges hit 0. Green loses a charge
    /// and dies after 3 cures.
    private func cure(zombie: CollisionObj, healer: CollisionObj) {
        if zombie.isSuper {
            zombie.charges -= 1
            if zombie.charges <= 0 {
                zombie.isActive = false
            }
        } else {
            setType(zombie, index: 0)
        }

        healer.charges -= 1
        if healer.charges <= 0 {
            healer.isActive = false
        }
    }

    /// Push PauseDemo on top of this scene.
    @objc func onMenu() { ui.view.isHidden = true; sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    /// Required factory method for TSceneBuilder.
    static func build() -> Scene { return CollisionDemo() }
}
