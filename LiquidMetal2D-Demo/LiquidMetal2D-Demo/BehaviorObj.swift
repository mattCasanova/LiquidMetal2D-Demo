//
//  StateMachineObj.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/21/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import LiquidMetal2D

/// Extends GameObj with a Behavior, enabling state-machine-driven logic.
///
/// **How to use Behavior with GameObj:**
/// `GameObj` is the engine's base game object class providing position, rotation, scale,
/// velocity, zOrder, and textureID. It has no built-in logic -- just data.
///
/// To add logic, subclass GameObj and add a `Behavior` property. A `Behavior` is a
/// state machine that holds a `current: State` and calls `state.update(dt:)` each frame.
/// You call `behavior.update(dt:)` in your scene's update loop.
///
/// `NilBehavior` is the engine's default no-op behavior. It does nothing on update,
/// so it is safe to call update() on objects that have not been assigned real behavior yet.
///
/// See `RandomAngleBehavior`, `MoveRightBehavior`, and `FindAndGoBehavior` for examples
/// of concrete Behavior implementations.
class BehaviorObj: GameObj {
  var behavior: Behavior = NilBehavior()
}
