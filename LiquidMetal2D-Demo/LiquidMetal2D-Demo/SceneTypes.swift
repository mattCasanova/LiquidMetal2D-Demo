//
//  SceneTypes.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/8/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import Foundation
import LiquidMetal2D

enum SceneTypes: Int, SceneType {
    case visualDemo = 0
    case inputDemo = 1
    case explosionDemo = 2
    case schedulerDemo = 3
    case stateDemo = 4
    case collisionDemo = 5
    case pauseDemo = 6

    var value: Int { return self.rawValue }

    var title: String {
        switch self {
        case .visualDemo: return "Visual Demo"
        case .inputDemo: return "Input Demo"
        case .explosionDemo: return "Explosion Demo"
        case .schedulerDemo: return "Scheduler Demo"
        case .stateDemo: return "State Machine Demo"
        case .collisionDemo: return "Collision Demo"
        case .pauseDemo: return "Paused"
        }
    }

    /// Navigable scenes in order (excludes pauseDemo which is push-only)
    static let navigable: [SceneTypes] = [
        .visualDemo, .inputDemo, .explosionDemo,
        .schedulerDemo, .stateDemo, .collisionDemo
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
