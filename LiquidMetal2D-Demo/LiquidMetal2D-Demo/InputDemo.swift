//
//  InputDemo.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/9/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import UIKit
import LiquidMetal2D

/// Touch-spawn demo: 4500 ships spawn at the touch location and fly outward in random directions.
/// Scale varies 0.25-1.5x, sorted by scale for depth illusion. Touch anywhere to redirect spawning.
/// Demonstrates: touch input (world coordinates), spatial spawning, scale-based depth sorting.
class InputDemo: Scene, @unchecked Sendable {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    var distance: Float = 40

    let objectCount = GameConstants.MAX_OBJECTS
    var objects = [GameObj]()

    var spawnPos = Vec2()
    var bounds = WorldBounds(maxX: 0, minX: 0, maxY: 0, minY: 0)

    private var ui: DemoSceneUI!
    private var textures = [Int]()

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
        renderer.setClearColor(color: Vec3())

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
        bounds = renderer.getWorldBoundsFromCamera(zOrder: 0)
    }

    func update(dt: Float) {
        if let touch = input.getWorldTouch(forZ: 0) {
            spawnPos.set(touch.x, touch.y)
        }

        for i in 0..<objectCount {
            let obj = objects[i] as! BehaviorObj
            obj.behavior.update(dt: dt)
        }

        objects.sort(by: { $0.scale.x < $1.scale.x })
    }

    func draw() {
        let worldUniforms = WorldUniform()
        renderer.beginPass()
        renderer.usePerspective()

        for i in 0..<objectCount {
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
        ui.removeFromSuperview()
        textures.forEach { renderer.unloadTexture(textureId: $0) }
        textures.removeAll()
    }

    private func getFOV() -> Float {
        renderer.screenWidth <= renderer.screenHeight ? 90 : 45
    }

    private func createObjects() {
        objects.removeAll()
        bounds = renderer.getWorldBoundsFromCamera(zOrder: 0)

        let getSpawnLocation = { [unowned self] in self.spawnPos }
        let getBounds = { [unowned self] in self.bounds }

        for _ in 0..<objectCount {
            let obj = BehaviorObj()
            obj.behavior = RandomAngleBehavior(
                obj: obj, getSpawnLocation: getSpawnLocation,
                getBounds: getBounds, textures: textures)
            objects.append(obj)
        }
    }

    @objc func onPrev() { if let s = SceneTypes.inputDemo.prev() { sceneMgr.setScene(type: s) } }
    @objc func onNext() { if let s = SceneTypes.inputDemo.next() { sceneMgr.setScene(type: s) } }
    @objc func onPause() { ui.view.isHidden = true; sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    static func build() -> Scene { return InputDemo() }
}
