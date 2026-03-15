//
//  DemoSceneUI.swift
//  LiquidMetal2D-Demo
//
//  Shared UI helper for demo scene navigation.
//  Provides title label, Prev/Next buttons, and Pause button.
//

import UIKit
import LiquidMetal2D

/// Reusable UI overlay for demo scenes: title + Prev / Pause / Next buttons.
@MainActor
class DemoSceneUI {
    let view: UIView
    let titleLabel: UILabel
    let prevButton: UIButton?
    let nextButton: UIButton?
    let pauseButton: UIButton

    private let sceneType: SceneTypes

    init(parentView: UIView, sceneType: SceneTypes, target: AnyObject,
         prevAction: Selector?, nextAction: Selector?, pauseAction: Selector) {
        self.sceneType = sceneType

        view = UIView(frame: parentView.safeAreaLayoutGuide.layoutFrame)
        parentView.addSubview(view)

        // Title label
        titleLabel = UILabel()
        titleLabel.text = sceneType.title
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        view.addSubview(titleLabel)

        // Prev button (nil if first scene)
        if let prevAction = prevAction, sceneType.prev() != nil {
            let btn = UIButton(frame: .zero)
            btn.backgroundColor = .blue
            btn.setTitle("Prev", for: .normal)
            btn.layer.cornerRadius = 4
            btn.addTarget(target, action: prevAction, for: .touchUpInside)
            view.addSubview(btn)
            prevButton = btn
        } else {
            prevButton = nil
        }

        // Next button (nil if last scene)
        if let nextAction = nextAction, sceneType.next() != nil {
            let btn = UIButton(frame: .zero)
            btn.backgroundColor = .blue
            btn.setTitle("Next", for: .normal)
            btn.layer.cornerRadius = 4
            btn.addTarget(target, action: nextAction, for: .touchUpInside)
            view.addSubview(btn)
            nextButton = btn
        } else {
            nextButton = nil
        }

        // Pause button (always present)
        pauseButton = UIButton(frame: .zero)
        pauseButton.backgroundColor = .red
        pauseButton.setTitle("Pause", for: .normal)
        pauseButton.layer.cornerRadius = 4
        pauseButton.addTarget(target, action: pauseAction, for: .touchUpInside)
        view.addSubview(pauseButton)

        layoutButtons()
    }

    func layout() {
        guard let superview = view.superview else { return }
        view.frame = superview.safeAreaLayoutGuide.layoutFrame
        layoutButtons()
    }

    private func layoutButtons() {
        let w: CGFloat = 100
        let h: CGFloat = 44
        let y = view.frame.height - h

        titleLabel.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 40)

        prevButton?.frame = CGRect(x: 0, y: y, width: w, height: h)
        nextButton?.frame = CGRect(x: view.frame.width - w, y: y, width: w, height: h)
        pauseButton.frame = CGRect(x: (view.frame.width - w) / 2, y: y, width: w, height: h)
    }

    func removeFromSuperview() {
        view.removeFromSuperview()
    }
}
