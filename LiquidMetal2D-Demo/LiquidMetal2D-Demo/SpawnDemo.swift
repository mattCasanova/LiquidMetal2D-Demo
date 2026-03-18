//
//  SpawnDemo.swift
//  LiquidMetal2D-Demo
//
//  Originally StateTestScene by Matt Casanova on 3/20/20.
//

import UIKit
import LiquidMetal2D

/// Touch-spawn demo with easing on spawn scale.
///
/// **What the user sees:** Ships continuously spawn at the touch location (or center if
/// no touch) and fly outward in random directions. Each ship "pops" into existence with
/// an overshoot scale animation (easeOutBack). Smaller ships draw behind larger ones,
/// creating a layered depth effect even though all ships are at z=0.
///
/// **Engine features demonstrated:**
/// - **Touch input (world coords):** `input.getWorldTouch(forZ:)` maps screen touches
///   to world-space at z=0. The spawn position updates every frame the touch is active.
/// - **RandomAngleBehavior:** A single-state Behavior that spawns an object at a given
///   position, assigns random rotation/velocity/scale, and respawns when out of bounds.
/// - **Easing (easeOutBack):** `Easing.easeOutBack(t)` produces a value that overshoots
///   1.0 then settles back, creating a satisfying "pop" effect on spawn scale.
/// - **getWorldBoundsFromCamera:** Computes world bounds using the camera's current position
///   (unlike `getWorldBounds` which takes an explicit camera distance). Simpler when you
///   do not need bounds for a different camera distance than the current one.
/// - **Sort by scale for depth:** Objects sorted by scale.x so smaller ships draw first.
class SpawnDemo: Scene {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    let distance: Float = 40
    let objectCount = GameConstants.MAX_OBJECTS
    var objects = [BehaviorObj]()
    private let worldUniforms = WorldUniform()

    /// Current spawn position in world space. Updated each frame from touch input.
    var spawnPos = Vec2()
    /// Per-object age tracker for the spawn scale animation. Parallel array with `objects`.
    private var spawnAge = [Float]()
    /// Duration of the easeOutBack scale animation in seconds
    private let spawnEaseDuration: Float = 0.3

    private var ui: DemoSceneUI!
    private var textures = [Int]()

    /// Scene protocol: called once when the scene is created.
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
            parentView: renderer.view, target: self,
            menuAction: #selector(onMenu))
    }

    /// Scene protocol: re-show the menu button when returning from PauseDemo.
    func resume() { ui.view.isHidden = false }

    /// Scene protocol: called on device rotation. Recalculate perspective projection.
    func resize() {
        ui.layout()
        renderer.setPerspective(
            fov: GameMath.degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
    }

    func update(dt: Float) {
        // Update spawn position to the current touch location in world space.
        // If no touch, spawnPos retains its last value (ships keep spawning there).
        if let touch = input.getWorldTouch(forZ: 0) {
            spawnPos.set(touch.x, touch.y)
        }

        for i in 0..<objectCount {
            // Update the RandomAngleBehavior, which moves the ship and respawns when out of bounds
            objects[i].behavior.update(dt: dt)

            // Animate scale on spawn using Easing.easeOutBack for a satisfying "pop" effect.
            // easeOutBack returns values that overshoot 1.0 briefly then settle, so the ship
            // appears to expand slightly past its target size before snapping into place.
            // obj.zOrder stores the base scale (a trick to avoid an extra property).
            if spawnAge[i] < spawnEaseDuration {
                spawnAge[i] += dt
                let t = min(spawnAge[i] / spawnEaseDuration, 1.0)
                let eased = Easing.easeOutBack(t)
                let baseScale = objects[i].zOrder // stash base scale in zOrder
                objects[i].scale.set(baseScale * eased, baseScale * eased)
            }
        }

        // Sort by scale so smaller objects (appearing further away) draw behind larger ones.
        // Since all objects are at z=0, scale-based sorting simulates depth layering.
        objects.sort(by: { $0.scale.x < $1.scale.x })
    }

    /// Uses the advanced useTexture()/draw() API instead of submit() to preserve
    /// insertion order. This demonstrates non-batched rendering where textures
    /// interleave naturally based on spawn order, unlike submit() which sorts
    /// by (zOrder, textureID) and groups all same-texture objects together.
    ///
    /// **Important:** draw() does no sorting — objects render in the order you
    /// submit them. If you need correct z-ordering or depth layering, sort your
    /// objects before the loop (as shown in update() which sorts by scale).
    func draw() {
        guard renderer.beginPass() else { return }
        renderer.usePerspective()

        for obj in objects {
            renderer.useTexture(textureId: obj.textureID)
            obj.toUniform(worldUniforms)
            renderer.draw(uniforms: worldUniforms)
        }

        renderer.endPass()
    }

    /// Scene protocol: clean up game objects, UI, and GPU resources.
    func shutdown() {
        objects.removeAll()
        spawnAge.removeAll()
        ui.removeFromSuperview()
        // Always unload textures to free GPU memory
        textures.forEach { renderer.unloadTexture(textureId: $0) }
        textures.removeAll()
    }

    private func getFOV() -> Float {
        renderer.screenWidth <= renderer.screenHeight ? 90 : 45
    }

    private func createObjects() {
        objects.removeAll()
        spawnAge.removeAll()

        // getWorldBoundsFromCamera uses the camera's current position to compute the visible
        // world rectangle at a given z-plane. This is simpler than getWorldBounds when you
        // don't need bounds at a different camera distance.
        let bounds = renderer.getWorldBoundsFromCamera(zOrder: 0)
        let getSpawnLocation = { [unowned self] in self.spawnPos }
        let getBounds = { bounds }

        for _ in 0..<objectCount {
            let obj = BehaviorObj()
            // RandomAngleBehavior wraps a single RandomAngleState that assigns a random direction,
            // speed, and scale on enter(), then checks bounds on update() to respawn when needed.
            obj.behavior = RandomAngleBehavior(
                obj: obj, getSpawnLocation: getSpawnLocation,
                getBounds: getBounds, textures: textures)
            objects.append(obj)
            // Start with full ease duration so objects appear fully scaled on first frame
            spawnAge.append(spawnEaseDuration)
        }
    }

    /// Push PauseDemo on top. Hide menu button first so it does not overlap the overlay.
    @objc func onMenu() { ui.view.isHidden = true; sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    /// Required factory method for TSceneBuilder.
    static func build() -> Scene { return SpawnDemo() }
}
