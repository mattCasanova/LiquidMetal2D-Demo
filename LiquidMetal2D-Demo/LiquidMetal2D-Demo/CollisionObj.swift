//
//  CollisionObj.swift
//  LiquidMetal
//
//  Created by Matt Casanova on 3/24/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import LiquidMetal2D

/// Extends GameObj with Behavior, Collider, and an active flag for object pooling.
///
/// **How to combine Behavior and Collider on a GameObj:**
/// This is the pattern for objects that need both AI logic and collision detection.
/// Add a `Behavior` for state-machine-driven movement and a `Collider` for spatial queries.
///
/// **Object pooling with isActive:**
/// Instead of creating and destroying objects at runtime, pre-allocate all objects upfront
/// and toggle `isActive` to control which ones participate in update/draw/collision.
/// Inactive objects use `NilBehavior` and `NilCollider` (no-op defaults from the engine),
/// so calling update() or doesCollideWith() on them is safe and free.
///
/// See `CollisionDemo` for how this class is used with `FindAndGoBehavior` and `CircleCollider`.
class CollisionObj: GameObj {
  /// Controls whether this object participates in update, draw, and collision.
  /// The scene skips inactive objects during rendering and collision checks.
  var isActive: Bool = false

  /// The AI state machine driving this object's movement. Defaults to NilBehavior (no-op).
  var behavior: Behavior = NilBehavior()

  /// The collision shape for this object. Defaults to NilCollider (never collides).
  var collider: Collider = NilCollider()
}
