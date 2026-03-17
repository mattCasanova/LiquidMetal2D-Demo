//
//  CollisionObj.swift
//  LiquidMetal
//
//  Created by Matt Casanova on 3/24/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import LiquidMetal2D

class CollisionObj: GameObj {
  var isActive: Bool = false
  var behavior: Behavior = NilBehavior()
  var collider: Collider = NilCollider()
}
