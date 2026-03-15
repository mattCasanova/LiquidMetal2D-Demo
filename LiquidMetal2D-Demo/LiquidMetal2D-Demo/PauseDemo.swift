//
//  PauseDemo.swift
//  LiquidMetal2D-Demo
//
//  Freeze-frame pause overlay. The previous scene stays rendered underneath.
//

import UIKit
import LiquidMetal2D

/// Pause overlay: pushed on top of the current scene via pushScene.
/// The previous scene's last frame stays visible (Metal doesn't clear).
/// A tinted overlay and "Paused" label appear on top. Resume pops back.
/// Demonstrates: scene stacking (pushScene/popScene) as a pause mechanism.
class PauseDemo: Scene, @unchecked Sendable {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!

    private var overlayView: UIView!
    private var pausedLabel: UILabel!
    private var resumeButton: UIButton!

    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input

        // Semi-transparent dark overlay
        overlayView = UIView(frame: renderer.view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        renderer.view.addSubview(overlayView)

        // "Paused" label
        pausedLabel = UILabel()
        pausedLabel.text = "Paused"
        pausedLabel.textColor = .white
        pausedLabel.textAlignment = .center
        pausedLabel.font = UIFont.boldSystemFont(ofSize: 36)
        overlayView.addSubview(pausedLabel)

        // Resume button
        resumeButton = UIButton(frame: .zero)
        resumeButton.backgroundColor = .systemGreen
        resumeButton.setTitle("Resume", for: .normal)
        resumeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        resumeButton.layer.cornerRadius = 8
        resumeButton.addTarget(self, action: #selector(onResume), for: .touchUpInside)
        overlayView.addSubview(resumeButton)

        layoutUI()
    }

    func resume() {}

    func resize() {
        overlayView.frame = renderer.view.bounds
        layoutUI()
    }

    func update(dt: Float) {
        // No game logic — scene is paused
    }

    func draw() {
        // Don't render anything — the previous scene's last frame stays visible
    }

    func shutdown() {
        overlayView.removeFromSuperview()
    }

    private func layoutUI() {
        let center = CGPoint(x: overlayView.bounds.midX, y: overlayView.bounds.midY)

        pausedLabel.frame = CGRect(x: 0, y: center.y - 60, width: overlayView.bounds.width, height: 44)

        let buttonWidth: CGFloat = 140
        let buttonHeight: CGFloat = 50
        resumeButton.frame = CGRect(
            x: center.x - buttonWidth / 2,
            y: center.y,
            width: buttonWidth,
            height: buttonHeight)
    }

    @objc func onResume() {
        sceneMgr.popScene()
    }

    static func build() -> Scene { return PauseDemo() }
}
