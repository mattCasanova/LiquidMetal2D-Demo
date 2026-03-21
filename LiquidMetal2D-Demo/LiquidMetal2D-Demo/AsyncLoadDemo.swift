//
//  AsyncLoadDemo.swift
//  LiquidMetal2D-Demo
//
//  Loading screen with a starfield flythrough effect. Stars are
//  procedural 1x1 white textures tinted with Tokyo Night colors —
//  no file loading required. After a brief delay, game textures
//  load asynchronously. On completion, "Ready!" and a Start button
//  appear over the starfield.
//
//  Copyright © 2026 Matt Casanova. All rights reserved.
//

import UIKit
import LiquidMetal2D

class AsyncLoadDemo: Scene {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    private let scheduler = Scheduler()
    private let artificialDelay: Float = 5.0

    private var statusLabel: UILabel!
    private var startButton: UIButton!

    private var stars = [GameObj]()
    private let starCount = 600

    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input

        renderer.setDefaultPerspective()
        renderer.setCameraRotation(angle: 0)
        renderer.setClearColor(color: TokyoNight.clearColor)

        createStars()
        setupUI()

        scheduler.add(task: ScheduledTask(time: artificialDelay, action: { [weak self] in
            self?.loadAllTextures()
        }, count: 1))
    }

    func resume() {}
    func resize() {
        renderer.setDefaultPerspective()
        layoutUI()
    }

    func update(dt: Float) {
        scheduler.update(dt: dt)

        // Move stars outward from center, scale up as they move
        // star.zOrder stores the per-star speed multiplier (0.3 to 1.0)
        for star in stars {
            let dir = simd_normalize(star.position)
            let dist = simd_length(star.position)
            let starSpeed = star.zOrder

            // Speed increases with distance, scaled by per-star multiplier
            let speed = (0.2 + dist * 0.15) * starSpeed
            star.position += dir * speed * dt * 3

            // Closer stars (higher speed) appear bigger
            let scaleFactor = (0.04 + dist * 0.03) * starSpeed
            star.scale.set(scaleFactor, scaleFactor)

            if dist > 60 {
                respawnStar(star)
            }
        }
    }

    func draw() {
        guard renderer.beginPass() else { return }
        renderer.usePerspective()
        renderer.submit(objects: stars)
        renderer.endPass()
    }

    func shutdown() {
        scheduler.clear()
        stars.removeAll()
        statusLabel.removeFromSuperview()
        startButton.removeFromSuperview()
    }

    // MARK: - Stars

    private func createStars() {
        for i in 0..<starCount {
            let star = GameObj()
            star.textureID = renderer.defaultTextureId

            // Random speed multiplier — close stars move fast/big, far stars slow/small
            star.zOrder = Float.random(in: 0.2...1.8)

            // Evenly distribute initial distances so there's no wave pattern
            let angle = Float.random(in: 0...GameMath.twoPi)
            let dist = Float(i) / Float(starCount) * 60.0 + Float.random(in: -2...2)
            star.position.set(cos(angle) * max(dist, 0.5), sin(angle) * max(dist, 0.5))
            let scaleFactor = (0.04 + abs(dist) * 0.03) * star.zOrder
            star.scale.set(scaleFactor, scaleFactor)
            star.tintColor = TokyoNight.accents.randomElement()!
            stars.append(star)
        }
    }

    private func respawnStar(_ star: GameObj) {
        let angle = Float.random(in: 0...GameMath.twoPi)
        let dist = Float.random(in: 0.5...2)
        star.position.set(cos(angle) * dist, sin(angle) * dist)
        star.zOrder = Float.random(in: 0.2...1.8)
        star.scale.set(0.04, 0.04)
        star.tintColor = TokyoNight.accents.randomElement()!
    }

    // MARK: - UI

    private func setupUI() {
        statusLabel = UILabel()
        statusLabel.textColor = TokyoNight.uiFg
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
        statusLabel.text = "Loading..."
        renderer.view.addSubview(statusLabel)

        startButton = UIButton(type: .system)
        startButton.setTitle("Start", for: .normal)
        startButton.setTitleColor(TokyoNight.uiBg, for: .normal)
        startButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        startButton.backgroundColor = TokyoNight.uiBlue
        startButton.layer.cornerRadius = 10
        startButton.addTarget(self, action: #selector(onStart), for: .touchUpInside)
        startButton.isHidden = true
        renderer.view.addSubview(startButton)

        layoutUI()
    }

    private func layoutUI() {
        let bounds = renderer.view.bounds
        let centerX = bounds.width / 2
        let centerY = bounds.height / 2
        statusLabel.frame = CGRect(
            x: 0, y: centerY - 40,
            width: bounds.width, height: 40)
        startButton.frame = CGRect(
            x: centerX - 60, y: centerY + 20,
            width: 120, height: 50)
    }

    // MARK: - Loading

    private func loadAllTextures() {
        let ids = renderer.loadTextures([
            TextureDescriptor(name: "playerShip1_blue", ext: "png", isMipmapped: true),
            TextureDescriptor(name: "playerShip1_green", ext: "png", isMipmapped: true),
            TextureDescriptor(name: "playerShip1_orange", ext: "png", isMipmapped: true)
        ], completion: { [weak self] in
            self?.onLoadComplete()
        })

        GameTextures.blue = ids[0]
        GameTextures.green = ids[1]
        GameTextures.orange = ids[2]
    }

    private func onLoadComplete() {
        statusLabel.text = "Ready!"
        startButton.isHidden = false
    }

    @objc func onStart() {
        sceneMgr.setScene(type: SceneTypes.massRenderDemo)
    }

    static func build() -> Scene { return AsyncLoadDemo() }
}
