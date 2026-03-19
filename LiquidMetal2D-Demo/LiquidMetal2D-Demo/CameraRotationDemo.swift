//
//  CameraRotationDemo.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/17/26.
//

import UIKit
import LiquidMetal2D

/// Camera rotation & scheduler pause demo: Four rows of ships form a tunnel
/// that oscillates like an earthquake. Touch the screen to pause the
/// oscillation and manually drag the rotation. Release to resume.
///
/// **What the user sees:** A tunnel of ships shakes back and forth (±45°)
/// like an earthquake. Touching the screen freezes the shake — you can
/// drag left/right to manually rotate. Releasing resumes the shake from
/// wherever you left off.
///
/// **Engine features demonstrated:**
/// - **Camera rotation:** `renderer.setCameraRotation(angle:)` rotates the
///   entire view around the Z axis without touching any object's individual
///   rotation. This is how you'd implement screen shake, tilt effects, or
///   camera transitions — one call rotates the whole world.
/// - **Scheduler pause/resume:** The oscillation is driven by a `Scheduler`.
///   When the user touches the screen, `scheduler.isPaused = true` freezes
///   all scheduled tasks. Releasing sets `isPaused = false` to resume.
///   This demonstrates pausing game logic during player input or menus.
/// - **Sine-wave oscillation:** `sin(time * speed) * amplitude` creates
///   smooth pendulum motion, a common pattern for idle animations, bobbing,
///   or breathing effects.
class CameraRotationDemo: Scene {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    private var objects = [GameObj]()

    /// Current camera rotation in radians, driven by scheduler or manual drag.
    private var currentRotation: Float = 0

    /// Elapsed time feeding the sine oscillation. Accumulates while scheduler runs.
    private var elapsedTime: Float = 0

    /// Oscillation frequency — higher = faster shaking.
    private let oscillationSpeed: Float = 4.0

    /// Maximum swing angle (±45°). The camera oscillates between -maxSwing and +maxSwing.
    private let maxSwing: Float = GameMath.degreeToRadian(45)

    /// The scheduler that drives the automatic oscillation.
    /// Setting `scheduler.isPaused = true` freezes the shake.
    private let scheduler = Scheduler()

    /// The oscillation task — kept as a reference so we can observe its state.
    private var oscillateTask: ScheduledTask!

    // Manual drag tracking
    private var lastTouchX: Float?
    private let dragSensitivity: Float = 0.01
    private var wasTouching = false

    // Tunnel layout
    private let shipsPerRow = 20
    private let trackSpacing: Float = 8
    private let zSpacing: Float = 4
    private let startZ: Float = 5

    private var rotationLabel: UILabel!
    private var ui: DemoSceneUI!
    private var textures = [Int]()

    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input

        ["playerShip1_blue", "playerShip1_green", "playerShip1_orange"].forEach {
            textures.append(renderer.loadTexture(name: $0, ext: "png", isMipmaped: true))
        }

        renderer.setCamera(point: Vec3(0, 0, Camera2D.defaultDistance))
        renderer.setCameraRotation(angle: 0)
        renderer.setPerspective(
            fov: GameMath.degreeToRadian(45),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
        renderer.setClearColor(color: TokyoNight.clearColor)

        createObjects()

        // Schedule the oscillation task — fires every frame (small interval, infinite repeats).
        // The scheduler's isPaused flag controls whether this runs.
        oscillateTask = ScheduledTask(time: 0.001, action: { [weak self] in
            // intentionally empty — oscillation is computed in update() from elapsedTime
        })
        scheduler.add(task: oscillateTask)

        ui = DemoSceneUI(
            parentView: renderer.view, target: self,
            menuAction: #selector(onMenu))

        rotationLabel = UILabel()
        rotationLabel.textColor = TokyoNight.uiFg
        rotationLabel.textAlignment = .center
        rotationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        renderer.view.addSubview(rotationLabel)
        updateLabel(0)
        layoutLabel()
    }

    func resume() { ui.view.isHidden = false }

    func resize() {
        ui.layout()
        renderer.setPerspective(
            fov: GameMath.degreeToRadian(45),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
        layoutLabel()
    }

    func update(dt: Float) {
        let isTouching = input.getScreenTouch() != nil

        if isTouching {
            // Touch active: pause the scheduler so the oscillation freezes.
            // The user takes manual control of the camera rotation via drag.
            scheduler.isPaused = true

            if let touch = input.getScreenTouch() {
                let touchX = touch.x
                if let last = lastTouchX {
                    let delta = (touchX - last) * dragSensitivity
                    // Clamp manual rotation to the same range as the oscillation
                    currentRotation = GameMath.clamp(
                        value: currentRotation + delta,
                        low: -maxSwing, high: maxSwing)
                }
                lastTouchX = touchX
            }
        } else {
            lastTouchX = nil

            if wasTouching {
                // Just released: resume the scheduler and sync elapsed time
                // to the current rotation so the oscillation picks up smoothly.
                // Solve: sin(elapsedTime * speed) * maxSwing = currentRotation
                //    →   elapsedTime = asin(currentRotation / maxSwing) / speed
                let clamped = GameMath.clamp(
                    value: currentRotation / maxSwing, low: -1, high: 1)
                elapsedTime = asin(clamped) / oscillationSpeed
                scheduler.isPaused = false
            }

            // Scheduler is running: advance the oscillation
            elapsedTime += dt
            currentRotation = sin(elapsedTime * oscillationSpeed) * maxSwing
        }

        wasTouching = isTouching

        // Apply the rotation to the camera — this one call rotates the entire
        // rendered world without modifying any individual object's transform.
        renderer.setCameraRotation(angle: currentRotation)
        updateLabel(currentRotation)

        // Advance the scheduler (fires tasks, respects isPaused)
        scheduler.update(dt: dt)
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
        // Reset rotation so other scenes don't inherit the tilt
        renderer.setCameraRotation(angle: 0)
        rotationLabel.removeFromSuperview()
        ui.removeFromSuperview()
        textures.forEach { renderer.unloadTexture(textureId: $0) }
        textures.removeAll()
    }

    // MARK: - Private

    private func updateLabel(_ rotation: Float) {
        let degrees = GameMath.radianToDegree(rotation)
        rotationLabel.text = String(format: "Rotation: %.1f°", degrees)
    }

    private func layoutLabel() {
        let safeTop = renderer.view.safeAreaInsets.top
        rotationLabel.frame = CGRect(
            x: 0, y: safeTop + 8,
            width: renderer.view.bounds.width, height: 30)
    }

    /// Creates four rows of ships forming a rectangular tunnel extending into the distance.
    /// All ships are the same size and evenly spaced — the only visual variable is FOV/rotation.
    private func createObjects() {
        objects.removeAll()

        // Four tracks: left (blue), right (green), top (orange), bottom (blue)
        let positions: [(Float, Float, Int)] = [
            (-trackSpacing, 0, 0),
            (trackSpacing, 0, 1),
            (0, trackSpacing, 2),
            (0, -trackSpacing, 0)
        ]

        for (xPos, yPos, textureIndex) in positions {
            for i in 0..<shipsPerRow {
                let obj = GameObj()
                obj.position.set(xPos, yPos)
                // Each ship is 4 units further in z, creating the tunnel perspective
                obj.zOrder = startZ + Float(i) * zSpacing
                obj.scale.set(2, 2)
                obj.rotation = 0
                obj.textureID = textures[textureIndex]
                obj.tintColor = TokyoNight.shipTints[textureIndex]
                objects.append(obj)
            }
        }
    }

    @objc func onMenu() {
        ui.view.isHidden = true
        sceneMgr.pushScene(type: SceneTypes.pauseDemo)
    }

    static func build() -> Scene { return CameraRotationDemo() }
}
