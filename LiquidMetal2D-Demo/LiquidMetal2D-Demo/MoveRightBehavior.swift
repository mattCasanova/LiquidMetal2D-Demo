//
//  MoveRightBehavior.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/22/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import LiquidMetal2D

/// A single-state Behavior that moves ships rightward and wraps them at z-varying bounds.
///
/// **Single-state Behavior pattern:**
/// Like `RandomAngleBehavior`, this Behavior contains exactly one State and never transitions.
/// The difference is that `MoveRightState` takes a `getBounds` closure that accepts a `zOrder`
/// parameter, so the bounds change depending on how far the ship is from the camera.
///
/// **Why bounds depend on zOrder:**
/// In a perspective projection, objects at higher z values (further from the camera) occupy
/// a larger world-space area on screen. `getWorldBounds(cameraDistance:zOrder:)` returns
/// the visible rectangle at that depth. Ships at z=60 have much wider bounds than ships at z=0,
/// so they correctly wrap at the screen edges regardless of their depth.
///
/// **Used by:** `MassRenderDemo` -- 4,500 ships scrolling right at different z-depths.
class MoveRightBehavior: Behavior {
    /// Required by the Behavior protocol. Holds the currently active State.
    var current: State!

    private let moveRightState: MoveRightState

    /// - Parameters:
    ///   - obj: The game object this behavior controls
    ///   - getBounds: Closure that returns world bounds for a given zOrder depth
    ///   - textures: Array of texture IDs to randomly assign on spawn
    init(obj: BehaviorObj, getBounds: @escaping (_ zOrder: Float) -> WorldBounds, textures: [Int]) {
        moveRightState = MoveRightState(obj: obj, getBounds: getBounds, textures: textures)
        // setStartState activates the state and calls its enter() method
        setStartState(startState: moveRightState)
    }

}
