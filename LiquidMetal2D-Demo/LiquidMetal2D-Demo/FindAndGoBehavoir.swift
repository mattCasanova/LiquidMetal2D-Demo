//
//  FindAndGoBehavoir.swift
//  LiquidMetal
//
//  Created by Matt Casanova on 3/24/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import simd
import LiquidMetal2D

/// AI behavior: Find a random target → Rotate toward it → Move to it → Repeat.
/// Uses a 3-state state machine (FindState → RotateState → GoState → FindState...).
/// The target position is shared between states via the `target` property.
class FindAndGoBehavoir: Behavoir {
    unowned let obj: CollisionObj

    var current: State!
    var target = simd_float2()

    private var findState: FindState!
    private var rotateState: RotateState!
    private var goState: GoState!

    init(obj: CollisionObj, bounds: WorldBounds) {
        self.obj = obj

        obj.position.x = Float.random(in: bounds.minX...bounds.maxX)
        obj.position.y = Float.random(in: bounds.minY...bounds.maxY)

        findState = FindState(parent: self, bounds: bounds)
        rotateState = RotateState(parent: self)
        goState = GoState(parent: self)

        self.setStartState(startState: findState)
    }

    func setToFind() {
        setNext(next: findState)
    }

    func setToRotate() {
        setNext(next: rotateState)
    }

    func setToGo() {
        setNext(next: goState)
    }
}
