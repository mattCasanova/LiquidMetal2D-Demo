//
//  StateDemo.swift
//  LiquidMetal2D-Demo
//
//  Originally StateTestScene by Matt Casanova on 3/20/20.
//

import UIKit
import LiquidMetal2D

/// State machine demo: A single large ship sits near the corner of the screen.
/// Touch the screen and the ship rotates to face the touch point.
/// Uses PlayerStateMachine (Behavior protocol) with a PlayerState that reads touch input each frame.
/// Demonstrates: Behavior/State protocol pattern, InputReader for touch, single-object scene.
class StateDemo: Scene, @unchecked Sendable {
    var sceneDelegate = DefaultScene()

    let objectCount = 1
    private var ui: DemoSceneUI!
    private var textures = [Int]()

    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        sceneDelegate.initialize(sceneMgr: sceneMgr, renderer: renderer, input: input)

        ["playerShip1_blue", "playerShip1_green", "playerShip1_orange"].forEach {
            textures.append(renderer.loadTexture(name: $0, ext: "png", isMipmaped: true))
        }

        sceneDelegate.objects = [BehaviorObj]()
        createObjects()

        sceneDelegate.renderer.setCamera(point: Vec3(0, 0, Camera2D.defaultDistance))
        sceneDelegate.renderer.setClearColor(color: Vec3(0.7, 0.5, 0.7))

        ui = DemoSceneUI(
            parentView: renderer.view, sceneType: .stateDemo, target: self,
            prevAction: #selector(onPrev), nextAction: #selector(onNext),
            pauseAction: #selector(onPause))
    }

    func resume() { ui.view.isHidden = false }

    func resize() {
        sceneDelegate.resize()
        ui.layout()
        repositionPlayer()
    }

    func update(dt: Float) {
        for i in 0..<objectCount {
            let obj = sceneDelegate.objects[i] as! BehaviorObj
            obj.behavior.update(dt: dt)
        }
        sceneDelegate.objects.sort(by: { $0.zOrder < $1.zOrder })
    }

    func draw() { sceneDelegate.draw() }

    func shutdown() {
        sceneDelegate.shutdown()
        textures.forEach { sceneDelegate.renderer.unloadTexture(textureId: $0) }
        textures.removeAll()
        ui.removeFromSuperview()
    }

    private func createObjects() {
        sceneDelegate.objects.removeAll()

        let zDepth: Float = 0
        let bounds = sceneDelegate.renderer.getWorldBoundsFromCamera(zOrder: zDepth)

        let player = BehaviorObj()
        player.zOrder = zDepth
        player.position.x = bounds.maxX - 3
        player.position.y = bounds.maxY - 3
        player.scale.set(5, 5)
        player.textureID = textures[0]
        player.rotation = 0
        player.velocity.set(0, 0)
        player.behavior = PlayerStateMachine(obj: player, inputReader: sceneDelegate.input)

        sceneDelegate.objects.append(player)
    }

    private func repositionPlayer() {
        guard let player = sceneDelegate.objects.first else { return }
        let bounds = sceneDelegate.renderer.getWorldBoundsFromCamera(zOrder: player.zOrder)
        player.position.set(bounds.maxX - 3, bounds.maxY - 3)
    }

    @objc func onPrev() { if let s = SceneTypes.stateDemo.prev() { sceneDelegate.sceneMgr.setScene(type: s) } }
    @objc func onNext() { if let s = SceneTypes.stateDemo.next() { sceneDelegate.sceneMgr.setScene(type: s) } }
    @objc func onPause() { ui.view.isHidden = true; sceneDelegate.sceneMgr.pushScene(type: SceneTypes.pauseDemo) }

    static func build() -> Scene { return StateDemo() }
}
