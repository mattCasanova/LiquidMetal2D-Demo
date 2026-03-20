//
//  MoveRightBehaviorFOV.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/17/26.
//

import LiquidMetal2D

/// Behavior wrapper for `MoveRightStateFOV`. Moves ships right with a
/// configurable z-depth range.
class MoveRightBehaviorFOV: Behavior {
    var current: State!

    init(obj: BehaviorObj, getBounds: @escaping (_ zOrder: Float) -> WorldBounds,
         zRange: ClosedRange<Float>) {
        let state = MoveRightStateFOV(
            obj: obj, getBounds: getBounds, zRange: zRange)
        setStartState(startState: state)
    }
}
