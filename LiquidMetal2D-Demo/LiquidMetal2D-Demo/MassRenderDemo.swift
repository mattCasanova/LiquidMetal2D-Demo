//
//  MassRenderDemo.swift
//  LiquidMetal2D-Demo
//
//  Copyright © 2026 Matt Casanova. All rights reserved.
//

import UIKit
import LiquidMetal2D

/// Mass rendering and visual effects demo showcasing 4,500 ships at varying z-depths.
///
/// **What the user sees:** Thousands of ships scroll right across the screen at different
/// distances (z = 0..60). The camera gently oscillates forward and backward via a sine wave,
/// creating a parallax-like zoom effect. The background color smoothly crossfades between
/// two colors every 2 seconds using a scheduled task.
///
/// **Engine features demonstrated:**
/// - **Mass rendering:** Drawing 4,500 textured quads per frame with the Metal renderer.
/// - **Z-depth sorting:** Objects at different z values appear at different sizes due to
///   perspective projection. Sorting by `zOrder` ensures correct back-to-front draw order.
/// - **Camera movement:** `renderer.setCamera(point:)` moves the camera each frame.
/// - **Scheduler:** `ScheduledTask` fires a repeating callback to swap colors.
/// - **Perspective projection:** FOV-based projection with configurable near/far planes.
/// - **Global textures:** Uses `GameTextures` static properties loaded once at app startup.
/// - **MoveRightBehavior:** A single-state Behavior that moves ships right and wraps them.
class MassRenderDemo: Scene {
    static var sceneType: any SceneType { SceneTypes.massRenderDemo }

    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    /// Tracks progress of the background color interpolation (0 to maxBackgroundChangeTime)
    var backgroundTime: Float = 0
    /// Duration in seconds for one full color crossfade cycle
    let maxBackgroundChangeTime: Float = 2

    /// Accumulator for the sine-wave camera oscillation
    var cameraTime: Float = 0.0
    /// Amplitude of the camera z-oscillation (camera moves +/- this amount from center)
    var camDistance: Float = 30
    /// Center z-distance for the camera oscillation
    var distance: Float = 40
    let cameraOscillationSpeed: Float = 0.5

    let objectCount = GameConstants.MAX_OBJECTS
    var objects = [BehaviorObj]()

    var startColor = Vec3(0.102, 0.106, 0.149)
    var endColor = Vec3(0.255, 0.282, 0.408)

    private var ui: DemoSceneUI!
    /// Scheduler manages a list of timed tasks. Call scheduler.update(dt:) each frame.
    private let scheduler = Scheduler()

    /// Called once when the scene is first loaded.
    /// The Scene protocol requires `initialize(sceneMgr:renderer:input:)` -- this is where
    /// you set up textures, camera, projection, and create your game objects.
    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input

        // Position the camera at z=40. Higher z = further back = more of the world visible.
        renderer.setCamera(point: Vec3(0, 0, distance))

        // Random camera tilt for visual variety — ships scroll at a slight angle
        renderer.setCameraRotation(angle: Float.random(in: 0...GameMath.twoPi))

        // Set up perspective projection. FOV adapts to portrait vs landscape orientation.
        // PerspectiveProjection.defaultNearZ/defaultFarZ provide sensible clip plane defaults.
        renderer.setDefaultPerspective()

        // Scheduler fires a repeating task every 2 seconds (indefinitely, since no count).
        // The action swaps start/end colors so the background crossfade reverses direction.
        scheduler.add(task: ScheduledTask(time: maxBackgroundChangeTime, action: { [unowned self] _ in
            self.backgroundTime = 0
            let temp = self.startColor
            self.startColor = self.endColor
            self.endColor = temp
        }))

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, target: self,
            menuAction: #selector(onMenu))
    }

    /// Called when this scene becomes active again after a pushed scene (e.g., PauseDemo) pops.
    /// Re-show the UI overlay that was hidden before pushing.
    func resume() { ui.view.isHidden = false }

    /// Called on device rotation or window resize. Recalculate projection to match new aspect ratio.
    func resize() {
        ui.layout()
        renderer.setDefaultPerspective()
    }

    func update(dt: Float) {
        scheduler.update(dt: dt)

        cameraTime += dt * cameraOscillationSpeed
        let newDist = -sinf(cameraTime) * camDistance + distance
        renderer.setCamera(point: Vec3(0, 0, newDist))

        backgroundTime += dt
        let t = backgroundTime / maxBackgroundChangeTime
        renderer.setClearColor(color: startColor.lerp(to: endColor, t: t))

        for obj in objects {
            obj.behavior.update(dt: dt)
        }

        objects.sort(by: { $0.zOrder < $1.zOrder })
    }

    func draw() {
        guard renderer.beginPass() else { return }
        renderer.usePerspective()
        renderer.submit(objects: objects)
        renderer.endPass()
    }

    func shutdown() {
        objects.removeAll()
        scheduler.clear()
        ui.removeFromSuperview()
    }

    private func createObjects() {
        objects.removeAll()

        // getWorldBounds calculates the visible world-space rectangle at a given zOrder
        // for a given camera distance. We use the maximum camera distance (distance + camDistance)
        // so ships span the full visible area even when the camera is zoomed out furthest.
        let getBounds = { [unowned self] (zOrder: Float) -> WorldBounds in
            self.renderer.getWorldBounds(cameraDistance: self.distance + self.camDistance, zOrder: zOrder)
        }
        for _ in 0..<objectCount {
            let obj = BehaviorObj()
            // MoveRightBehavior is a single-state Behavior: ships start at the left edge
            // and move right. When they exit bounds, they respawn at a new random z-depth.
            obj.behavior = MoveRightBehavior(obj: obj, getBounds: getBounds)
            objects.append(obj)
        }
    }

    /// Push the pause/menu scene on top of this scene. The current scene stays alive underneath.
    @objc func onMenu() { ui.view.isHidden = true; sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    /// Every Scene needs a static build() method used by TSceneBuilder for the SceneFactory.
    static func build() -> Scene { return MassRenderDemo() }
}
