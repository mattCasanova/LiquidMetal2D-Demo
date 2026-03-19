//
//  AsyncLoadDemo.swift
//  LiquidMetal2D-Demo
//
//  Demonstrates async texture loading. Ships spawn immediately with no
//  textures loaded — they render as magenta (the engine's error texture).
//  After 5 seconds, textures load asynchronously in bulk. Once each
//  texture finishes loading on the background thread, the magenta
//  seamlessly swaps to the real texture on the next frame.
//
//  Press "Reset" to unload textures and restart the countdown.
//

import UIKit
import LiquidMetal2D

class AsyncLoadDemo: Scene {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    private var objects = [GameObj]()
    private let scheduler = Scheduler()
    private var ui: DemoSceneUI!
    private var textures = [Int]()

    private var texturesLoaded = false
    private var countdown: Float = 0
    private var countdownLabel: UILabel!
    private var resetButton: UIButton!

    private let objectCount = 50
    private let loadDelay: Float = 5.0

    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input

        renderer.setDefaultPerspective()
        renderer.setClearColor(color: TokyoNight.clearColor)

        createObjects()
        scheduleLoad()

        ui = DemoSceneUI(
            parentView: renderer.view, target: self,
            menuAction: #selector(onMenu))

        setupCountdownLabel()
        setupResetButton()
        layoutUI()
    }

    func resume() { ui.view.isHidden = false }

    func resize() {
        ui.layout()
        renderer.setDefaultPerspective()
        layoutUI()
    }

    func update(dt: Float) {
        scheduler.update(dt: dt)

        for obj in objects {
            obj.rotation += dt * 0.5
        }

        if !texturesLoaded {
            countdown = max(0, countdown - dt)
            countdownLabel.text = String(format: "Loading in %.1fs", countdown)
            countdownLabel.isHidden = false
        } else {
            countdownLabel.isHidden = true
        }
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
        countdownLabel.removeFromSuperview()
        resetButton.removeFromSuperview()
        textures.forEach { renderer.unloadTexture(textureId: $0) }
        textures.removeAll()
    }

    // MARK: - UI Setup

    private func setupCountdownLabel() {
        countdownLabel = UILabel()
        countdownLabel.textColor = TokyoNight.uiFg
        countdownLabel.textAlignment = .right
        countdownLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        renderer.view.addSubview(countdownLabel)
    }

    private func setupResetButton() {
        resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(TokyoNight.uiBlue, for: .normal)
        resetButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        resetButton.backgroundColor = TokyoNight.uiDarker
        resetButton.layer.cornerRadius = 8
        resetButton.addTarget(self, action: #selector(onReset), for: .touchUpInside)
        renderer.view.addSubview(resetButton)
    }

    private func layoutUI() {
        let safeArea = renderer.view.safeAreaInsets
        let viewWidth = renderer.view.bounds.width

        countdownLabel.frame = CGRect(
            x: viewWidth - 220, y: safeArea.top + 8,
            width: 200, height: 30)

        resetButton.frame = CGRect(
            x: viewWidth - 90 - safeArea.right,
            y: renderer.view.bounds.height - safeArea.bottom - 52,
            width: 80, height: 40)
    }

    // MARK: - Loading

    private func createObjects() {
        objects.removeAll()
        let bounds = renderer.getWorldBoundsFromCamera(zOrder: 0)
        for _ in 0..<objectCount {
            let obj = GameObj()
            obj.position.set(
                Float.random(in: bounds.minX...bounds.maxX),
                Float.random(in: bounds.minY...bounds.maxY))
            let scale = Float.random(in: 1...4)
            obj.scale.set(scale, scale)
            obj.rotation = Float.random(in: 0...GameMath.twoPi)
            obj.textureID = 0
            objects.append(obj)
        }
    }

    private func scheduleLoad() {
        countdown = loadDelay
        texturesLoaded = false
        scheduler.add(task: ScheduledTask(time: loadDelay, action: { [weak self] in
            self?.loadAndAssignTextures()
        }, count: 1))
    }

    private func loadAndAssignTextures() {
        textures = renderer.loadTextures([
            (name: "playerShip1_blue", ext: "png", isMipmaped: true),
            (name: "playerShip1_green", ext: "png", isMipmaped: true),
            (name: "playerShip1_orange", ext: "png", isMipmaped: true)
        ])

        let tintMap = [
            textures[0]: TokyoNight.blue,
            textures[1]: TokyoNight.teal,
            textures[2]: TokyoNight.red
        ]

        for obj in objects {
            let tex = textures.randomElement()!
            obj.textureID = tex
            obj.tintColor = tintMap[tex]!
        }

        texturesLoaded = true
    }

    // MARK: - Actions

    @objc func onReset() {
        textures.forEach { renderer.unloadTexture(textureId: $0) }
        textures.removeAll()

        for obj in objects {
            obj.textureID = 0
        }

        texturesLoaded = false
        scheduler.clear()
        scheduleLoad()
    }

    @objc func onMenu() {
        ui.view.isHidden = true
        sceneMgr.pushScene(type: SceneTypes.pauseDemo)
    }

    static func build() -> Scene { return AsyncLoadDemo() }
}
