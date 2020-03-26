//
//  RandomCircleBehavoir.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/21/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import MetalMath
import LiquidMetal2D

class RandomAngleBehavoir: Behavoir {
  
  private let randomAngleState: RandomAngleState
  
  init(obj: BehavoirObj, getSpawnLocation: @escaping () -> Vector2D, getBounds: @escaping () -> Bounds, textures: [Int]) {
    randomAngleState = RandomAngleState(
      obj: obj,
      getSpawnLocation: getSpawnLocation,
      getBounds: getBounds,
      textures: textures)
    super.init(startState: randomAngleState)
  }
  
}
