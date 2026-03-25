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

class AsyncLoadDemo: DefaultScene {
    override class var sceneType: any SceneType { SceneTypes.asyncLoadDemo }

    private let artificialDelay: Float = 5.0

    private var statusLabel: UILabel!
    private var startButton: UIButton!

    // Star movement
    private let baseSpeed: Float = 0.2
    private let distanceSpeedScale: Float = 0.15
    private let globalSpeedMultiplier: Float = 3
    private let baseScale: Float = 0.04
    private let distanceScaleMultiplier: Float = 0.03
    private let maxDistance: Float = 60
    private let speedRange: ClosedRange<Float> = 0.2...1.8
    private let respawnDistanceRange: ClosedRange<Float> = 0.5...2
    private let initialJitter: ClosedRange<Float> = -2...2

    override func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        super.initialize(sceneMgr: sceneMgr, renderer: renderer, input: input)

        renderer.setClearColor(color: TokyoNight.clearColor)

        createStars()
        setupUI()

        scheduler.add(task: ScheduledTask(time: artificialDelay, action: { [weak self] _ in
            self?.loadAllTextures()
        }, count: 1))
    }

    override func layoutUI() {
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

    override func update(dt: Float) {
        scheduler.update(dt: dt)

        for star in objects {
            let dir = star.position.normalized
            let dist = star.position.length
            let starSpeed = star.zOrder

            let speed = (baseSpeed + dist * distanceSpeedScale) * starSpeed
            star.position += dir * speed * dt * globalSpeedMultiplier

            let scaleFactor = (baseScale + dist * distanceScaleMultiplier) * starSpeed
            star.scale.set(scaleFactor, scaleFactor)

            if dist > maxDistance {
                respawnStar(star)
            }
        }
    }

    override func shutdown() {
        super.shutdown()
        statusLabel.removeFromSuperview()
        startButton.removeFromSuperview()
    }

    // MARK: - Stars

    private func createStars() {
        let starCount = 600
        for i in 0..<starCount {
            let star = GameObj()
            star.textureID = renderer.defaultTextureId
            star.zOrder = Float.random(in: speedRange)

            let angle = Float.random(in: 0...GameMath.twoPi)
            let dist = Float(i) / Float(starCount) * maxDistance + Float.random(in: initialJitter)
            let clampedDist = max(dist, respawnDistanceRange.lowerBound)
            star.position.set(cos(angle) * clampedDist, sin(angle) * clampedDist)

            let scaleFactor = (baseScale + abs(dist) * distanceScaleMultiplier) * star.zOrder
            star.scale.set(scaleFactor, scaleFactor)
            star.tintColor = TokyoNight.accents.randomElement()!
            objects.append(star)
        }
    }

    private func respawnStar(_ star: GameObj) {
        let angle = Float.random(in: 0...GameMath.twoPi)
        let dist = Float.random(in: respawnDistanceRange)
        star.position.set(cos(angle) * dist, sin(angle) * dist)
        star.zOrder = Float.random(in: speedRange)
        star.scale.set(baseScale, baseScale)
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

    // MARK: - Loading

    private func loadAllTextures() {
        let ids = renderer.loadTextures([
            TextureDescriptor(name: "playerShip1_blue", isMipmapped: true),
            TextureDescriptor(name: "playerShip1_green", isMipmapped: true),
            TextureDescriptor(name: "playerShip1_orange", isMipmapped: true)
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
}
