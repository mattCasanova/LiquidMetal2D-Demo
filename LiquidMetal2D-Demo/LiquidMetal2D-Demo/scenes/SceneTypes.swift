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
  
  
  
  var value: Int { get { return self.rawValue } }
}
