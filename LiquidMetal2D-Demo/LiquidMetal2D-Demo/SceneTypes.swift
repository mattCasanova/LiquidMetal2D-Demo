//
//  SceneTypes.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/8/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import Foundation
import LiquidMetal2D

enum SceneTypes: SceneType {
    case visualDemo
    case inputDemo
    case explosionDemo
    case schedulerDemo
    case stateDemo
    case collisionDemo
    case bezierDemo
    case pauseDemo

    var title: String {
        switch self {
        case .visualDemo: return "4,500 Ships - Batched Rendering"
        case .inputDemo: return "Touch Input & Camera Zoom"
        case .explosionDemo: return "4,500 Ships - Touch Rotation"
        case .schedulerDemo: return "Timed Tasks & Callbacks"
        case .stateDemo: return "Behavior / State Pattern"
        case .collisionDemo: return "Circle Collision & AI"
        case .bezierDemo: return "Cubic Bezier Curves"
        case .pauseDemo: return "Paused"
        }
    }

    /// Navigable scenes in order (excludes pauseDemo which is push-only)
    static let navigable: [SceneTypes] = [
        .visualDemo, .inputDemo, .explosionDemo,
        .schedulerDemo, .stateDemo, .collisionDemo,
        .bezierDemo
    ]

    func next() -> SceneTypes? {
        guard let index = SceneTypes.navigable.firstIndex(of: self) else { return nil }
        let nextIndex = index + 1
        return nextIndex < SceneTypes.navigable.count ? SceneTypes.navigable[nextIndex] : nil
    }

    func prev() -> SceneTypes? {
        guard let index = SceneTypes.navigable.firstIndex(of: self) else { return nil }
        let prevIndex = index - 1
        return prevIndex >= 0 ? SceneTypes.navigable[prevIndex] : nil
    }
}
