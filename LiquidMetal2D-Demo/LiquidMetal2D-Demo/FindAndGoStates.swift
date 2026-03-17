//
//  FindAndGoStates.swift
//  LiquidMetal
//
//  Created by Matt Casanova on 3/24/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import LiquidMetal2D

/// Picks a random target position within the world bounds, then immediately transitions to RotateState.
class FindState: State {
    private unowned let parent: FindAndGoBehavoir
    private let bounds: WorldBounds

    init(parent: FindAndGoBehavoir, bounds: WorldBounds) {
        self.parent = parent
        self.bounds = bounds
    }

    func enter() {
        parent.target.x = Float.random(in: bounds.minX...bounds.maxX)
        parent.target.y = Float.random(in: bounds.minY...bounds.maxY)
    }

    func exit() {}

    func update(dt: Float) {
        parent.setToRotate()
    }
}

/// Rotates the ship toward the target using a 2D cross product to determine turn direction.
/// Once the ship's rotation is within 0.1 radians of the target angle, transitions to GoState.
class RotateState: State {
    private unowned let parent: FindAndGoBehavoir

    private var rotation: Float = 0.0
    private var rotationVelocity: Float = 0.0

    init(parent: FindAndGoBehavoir) {
        self.parent = parent
    }

    func enter() {
        let targetDirection = parent.target - parent.obj.position
        let currentRotationVec = Vec2(angle: parent.obj.rotation)

        let crossZ = currentRotationVec.cross(targetDirection)

        rotationVelocity = Float.random(in: 1...3) * ((crossZ < 0) ? -1 : 1)

        rotation = targetDirection.angle
        rotation = GameMath.wrap(value: rotation, low: 0, high: GameMath.twoPi)
    }

    func exit() {}

    func update(dt: Float) {
        parent.obj.rotation += rotationVelocity * dt
        parent.obj.rotation = GameMath.wrap(value: parent.obj.rotation, low: 0, high: GameMath.twoPi)

        if GameMath.isInRange(value: parent.obj.rotation, low: rotation - 0.1, high: rotation + 0.1) {
            parent.obj.rotation = rotation
            parent.setToGo()
        }
    }
}

/// Moves the ship forward in its facing direction at a random speed.
/// When the ship reaches the target (point-in-circle check), transitions back to FindState.
class GoState: State {
    private unowned let parent: FindAndGoBehavoir

    init(parent: FindAndGoBehavoir) {
        self.parent = parent
    }

    func enter() {
        var direction = Vec2(angle: parent.obj.rotation)
        direction *= Float.random(in: 6...10)

        parent.obj.velocity = direction
    }

    func exit() {}

    func update(dt: Float) {
        parent.obj.position += parent.obj.velocity * dt

        if Intersect.pointCircle(point: parent.target, circle: parent.obj.position, radius: 2) {
            parent.setToFind()
        }
    }
}
