//
//  MoveRightBehavoir.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/22/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import LiquidMetal2D

class MoveRightBehavoir: Behavoir {
  
  private let moveRightState: MoveRightState
  
  init(obj: BehavoirObj, getBounds: @escaping (_ zOrder: Float) -> Bounds, textures: [Int]) {
    moveRightState = MoveRightState(obj: obj, getBounds: getBounds, textures: textures)
    super.init(startState: moveRightState)
  }
  
}
