//
//  FOVDemo.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/17/26.
//

import UIKit
import LiquidMetal2D

/// Camera rotation demo: Four rows of ships form a tunnel. Drag left/right
/// to rotate the camera around the Z axis. The entire world spins while
/// the camera stays centered.
///
/// **What the user sees:** A tunnel of ships extending into the distance.
/// Dragging rotates the view like tilting your head — the world spins.
/// This is useful for screen shake effects, tilt transitions, or visual polish.
///
/// **Engine features demonstrated:**
/// - `renderer.setCameraRotation(angle:)` — rotates the view around Z
/// - Camera rotation is separate from camera position/distance
/// - The perspective projection is unaffected — only the view matrix rotates
class FOVDemo: Scene, @unchecked Sendable {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    private var objects = [GameObj]()

    /// Current camera rotation in radians. Increments every frame.
    private var currentRotation: Float = 0

    /// Rotation speed in radians per second.
    private let rotationSpeed: Float = 0.5

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
        renderer.setClearColor(color: Vec3(0.08, 0.06, 0.12))

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, target: self,
            menuAction: #selector(onMenu))

        rotationLabel = UILabel()
        rotationLabel.textColor = .white
        rotationLabel.textAlignment = .center
        rotationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        renderer.view.addSubview(rotationLabel)
        updateLabel()
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
        // Auto-rotate the camera continuously
        currentRotation += rotationSpeed * dt
        renderer.setCameraRotation(angle: currentRotation)
        updateLabel()
    }

    func draw() {
        let worldUniforms = WorldUniform()
        renderer.beginPass()
        renderer.usePerspective()

        // Draw back to front
        for i in stride(from: objects.count - 1, through: 0, by: -1) {
            let obj = objects[i]
            renderer.useTexture(textureId: obj.textureID)
            worldUniforms.transform.setToTransform2D(
                scale: obj.scale, angle: obj.rotation,
                translate: Vec3(obj.position, obj.zOrder))
            renderer.draw(uniforms: worldUniforms)
        }

        renderer.endPass()
    }

    func shutdown() {
        objects.removeAll()
        // Reset rotation so other scenes aren't tilted
        renderer.setCameraRotation(angle: 0)
        rotationLabel.removeFromSuperview()
        ui.removeFromSuperview()
        textures.forEach { renderer.unloadTexture(textureId: $0) }
        textures.removeAll()
    }

    // MARK: - Private

    private func updateLabel() {
        let degrees = GameMath.radianToDegree(currentRotation)
        rotationLabel.text = String(format: "Rotation: %.0f°", degrees)
    }

    private func layoutLabel() {
        let safeTop = renderer.view.safeAreaInsets.top
        rotationLabel.frame = CGRect(
            x: 0, y: safeTop + 8,
            width: renderer.view.bounds.width, height: 30)
    }

    private func createObjects() {
        objects.removeAll()

        // Four rows forming a rectangular tunnel
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
                obj.zOrder = startZ + Float(i) * zSpacing
                obj.scale.set(2, 2)
                obj.rotation = 0
                obj.textureID = textures[textureIndex]
                objects.append(obj)
            }
        }
    }

    @objc func onMenu() {
        ui.view.isHidden = true
        sceneMgr.pushScene(type: SceneTypes.pauseDemo)
    }

    static func build() -> Scene { return FOVDemo() }
}
