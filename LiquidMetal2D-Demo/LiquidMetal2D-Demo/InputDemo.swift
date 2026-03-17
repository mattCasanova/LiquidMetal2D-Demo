//
//  InputDemo.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/9/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import UIKit
import LiquidMetal2D

/// Touch input & camera zoom demo: One center ship orients toward touch,
/// four corner ships pin to world bounds. Touch toggles a smooth camera
/// zoom in/out using easing. Corner ships reposition as bounds change.
/// Demonstrates: touch input, world bounds, camera Z, Easing functions.
class InputDemo: Scene, @unchecked Sendable {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    private let nearZ: Float = 30
    private let farZ: Float = 70
    private var targetZ: Float = 50
    private var startZ: Float = 50
    private var currentZ: Float = 50
    private var zoomT: Float = 1
    private let zoomDuration: Float = 1.0
    private var isZoomedIn = false

    private var centerShip: GameObj!
    private var cornerShips = [GameObj]()

    private var ui: DemoSceneUI!
    private var textures = [Int]()

    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input

        ["playerShip1_blue", "playerShip1_green", "playerShip1_orange"].forEach {
            textures.append(renderer.loadTexture(name: $0, ext: "png", isMipmaped: true))
        }

        currentZ = Camera2D.defaultDistance
        startZ = currentZ
        targetZ = currentZ

        renderer.setCamera(point: Vec3(0, 0, currentZ))
        renderer.setPerspective(
            fov: GameMath.degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
        renderer.setClearColor(color: Vec3(0.15, 0.1, 0.2))

        createObjects()

        ui = DemoSceneUI(
            parentView: renderer.view, sceneType: .inputDemo, target: self,
            prevAction: #selector(onPrev), nextAction: #selector(onNext),
            pauseAction: #selector(onPause))
    }

    func resume() { ui.view.isHidden = false }

    func resize() {
        ui.layout()
        renderer.setPerspective(
            fov: GameMath.degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
        positionCornerShips()
    }

    func update(dt: Float) {
        if let touch = input.getWorldTouch(forZ: 0) {
            let dir = Vec2(touch.x, touch.y) - centerShip.position
            centerShip.rotation = atan2(dir.y, dir.x)

            // Toggle zoom on touch
            if zoomT >= 1.0 {
                isZoomedIn.toggle()
                startZ = currentZ
                targetZ = isZoomedIn ? nearZ : farZ
                zoomT = 0
            }
        }

        // Animate camera zoom
        if zoomT < 1.0 {
            zoomT = min(zoomT + dt / zoomDuration, 1.0)
            let easedT = Easing.easeInOutCubic(zoomT)
            currentZ = GameMath.lerp(a: startZ, b: targetZ, t: easedT)
            renderer.setCamera(point: Vec3(0, 0, currentZ))
            positionCornerShips()
        }
    }

    func draw() {
        let worldUniforms = WorldUniform()
        renderer.beginPass()
        renderer.usePerspective()

        let allObjects = [centerShip!] + cornerShips
        for obj in allObjects {
            renderer.useTexture(textureId: obj.textureID)
            worldUniforms.transform.setToTransform2D(
                scale: obj.scale, angle: obj.rotation,
                translate: Vec3(obj.position, obj.zOrder))
            renderer.draw(uniforms: worldUniforms)
        }

        renderer.endPass()
    }

    func shutdown() {
        ui.removeFromSuperview()
        textures.forEach { renderer.unloadTexture(textureId: $0) }
        textures.removeAll()
    }

    private func getFOV() -> Float {
        renderer.screenWidth <= renderer.screenHeight ? 90 : 45
    }

    private func createObjects() {
        centerShip = GameObj()
        centerShip.position.set(0, 0)
        centerShip.scale.set(3, 3)
        centerShip.textureID = textures[0]

        cornerShips.removeAll()
        for i in 0..<4 {
            let ship = GameObj()
            ship.scale.set(1.5, 1.5)
            ship.textureID = textures[1 + (i % 2)]
            cornerShips.append(ship)
        }

        positionCornerShips()
    }

    private func positionCornerShips() {
        let bounds = renderer.getWorldBounds(cameraDistance: currentZ, zOrder: 0)
        let offset: Float = 3

        // Top-right, top-left, bottom-left, bottom-right
        let positions: [(Float, Float, Float)] = [
            (bounds.maxX - offset, bounds.maxY - offset, GameMath.degreeToRadian(135)),
            (bounds.minX + offset, bounds.maxY - offset, GameMath.degreeToRadian(225)),
            (bounds.minX + offset, bounds.minY + offset, GameMath.degreeToRadian(315)),
            (bounds.maxX - offset, bounds.minY + offset, GameMath.degreeToRadian(45))
        ]

        for i in 0..<cornerShips.count {
            cornerShips[i].position.set(positions[i].0, positions[i].1)
            cornerShips[i].rotation = positions[i].2
        }
    }

    @objc func onPrev() { if let s = SceneTypes.inputDemo.prev() { sceneMgr.setScene(type: s) } }
    @objc func onNext() { if let s = SceneTypes.inputDemo.next() { sceneMgr.setScene(type: s) } }
    @objc func onPause() { ui.view.isHidden = true; sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    static func build() -> Scene { return InputDemo() }
}
