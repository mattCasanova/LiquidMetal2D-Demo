//
//  SceneTypes.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/8/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import Foundation
import LiquidMetal2D

/// Defines all scene types in the app by conforming to the engine's `SceneType` protocol.
///
/// **How scene types work in LiquidMetal2D:**
/// The engine identifies scenes by `SceneType` values. You define your own enum conforming
/// to `SceneType`, then register each case with the `SceneFactory` in your ViewController.
/// This decouples scene transitions from concrete scene classes -- you call
/// `sceneMgr.setScene(type: .inputDemo)` without importing InputDemo directly.
///
/// **Registration flow:**
/// 1. Define your enum cases here
/// 2. In ViewController, call `sceneFactory.addScene(type:builder:)` for each case
/// 3. In your scenes, call `sceneMgr.setScene(type:)` or `sceneMgr.pushScene(type:)` to navigate
///
/// The `title` property provides human-readable names used by the PauseDemo menu.
/// The `navigable` list controls which scenes appear in the menu (excludes pauseDemo
/// since it is a push-only overlay, not a standalone scene).
enum SceneTypes: SceneType {
    case visualDemo
    case inputDemo
    case explosionDemo
    case schedulerDemo
    case stateDemo
    case collisionDemo
    case bezierDemo
    case fovDemo
    case pauseDemo

    /// Human-readable display name for each scene, used in the PauseDemo menu table view.
    var title: String {
        switch self {
        case .visualDemo: return "4,500 Ships - Batched Rendering"
        case .inputDemo: return "Touch Input & Camera Zoom"
        case .explosionDemo: return "4,500 Ships - Touch Rotation"
        case .schedulerDemo: return "Timed Tasks & Callbacks"
        case .stateDemo: return "Touch Spawn & Easing"
        case .collisionDemo: return "Collision & AI States"
        case .bezierDemo: return "Cubic Bezier Curves"
        case .fovDemo: return "Camera Rotation"
        case .pauseDemo: return "Paused"
        }
    }

    /// Navigable scenes in order (excludes pauseDemo which is push-only, not a standalone scene).
    static let navigable: [SceneTypes] = [
        .visualDemo, .inputDemo, .explosionDemo,
        .schedulerDemo, .stateDemo, .collisionDemo,
        .bezierDemo, .fovDemo
    ]

    /// Returns the next scene in the navigable list, or nil if this is the last one.
    func next() -> SceneTypes? {
        guard let index = SceneTypes.navigable.firstIndex(of: self) else { return nil }
        let nextIndex = index + 1
        return nextIndex < SceneTypes.navigable.count ? SceneTypes.navigable[nextIndex] : nil
    }

    /// Returns the previous scene in the navigable list, or nil if this is the first one.
    func prev() -> SceneTypes? {
        guard let index = SceneTypes.navigable.firstIndex(of: self) else { return nil }
        let prevIndex = index - 1
        return prevIndex >= 0 ? SceneTypes.navigable[prevIndex] : nil
    }
}
