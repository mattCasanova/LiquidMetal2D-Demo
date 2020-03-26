//
//  RandomCircleState.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/21/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import MetalMath
import LiquidMetal2D

class RandomAngleState: State {
  private unowned let obj: BehavoirObj
  
  private let textures: [Int]
  private let getSpawnLocation: () -> Vector2D
  private let getBounds: () -> Bounds
  
  init(obj: BehavoirObj, getSpawnLocation: @escaping () -> Vector2D, getBounds: @escaping () -> Bounds, textures: [Int]) {
    self.obj              = obj
    self.getSpawnLocation = getSpawnLocation
    self.getBounds        = getBounds
    self.textures         = textures
  }
  
  func enter() {
    randomize()
  }
  
  func exit() {
    
  }
  
  func update(dt: Float) {
    obj.position += obj.velocity * dt
    
    let bounds = getBounds()
       
    if !GameMath.isFloat(inRange: obj.position.x, betweenLow: bounds.minX, andHigh: bounds.maxX) ||
      !GameMath.isFloat(inRange: obj.position.y, betweenLow: bounds.minY, andHigh: bounds.maxY){
      randomize()
    }
  }
  
  private func randomize() {
    let spawnLocation = getSpawnLocation()
    
    obj.zOrder = 0
    obj.position.x = spawnLocation.x
    obj.position.y = spawnLocation.y
    
    let scale = Float.random(in: 0.25...1.5)
    obj.scale.setX(scale, andY: scale)
    
    obj.rotation = Float.random(in: 0...GameMath.twoPi())
    obj.velocity.setRotation(obj.rotation)
    obj.velocity *= 5 * scale
    obj.textureID = textures[Int.random(in: 0..<textures.count)]
  }
  
}
