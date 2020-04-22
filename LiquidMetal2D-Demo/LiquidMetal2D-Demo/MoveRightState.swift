//
//  MoveRightState.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/22/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import MetalMath
import LiquidMetal2D

class MoveRightState: State {
    private unowned let obj: BehavoirObj
    
    private let textures: [Int]
    private let getBounds: (_ zOrder: Float) -> WorldBounds
    private var bounds = WorldBounds(maxX: 0, minX: 0, maxY: 0, minY: 0)
    
    init(obj: BehavoirObj, getBounds: @escaping (_ zOrder: Float) -> WorldBounds, textures: [Int]) {
        self.obj       = obj
        self.textures  = textures
        self.getBounds = getBounds
    }
    
    func enter() {
        randomize()
    }
    
    func exit() {
        
    }
    
    func update(dt: Float) {
        obj.position += obj.velocity * dt
        
        if !isInRange(value: obj.position.x, low: bounds.minX, high: bounds.maxX) ||
            !isInRange(value: obj.position.y, low: bounds.minY, high: bounds.maxY) {
            randomize()
        }
    }
    
    private func randomize() {
        
        obj.zOrder = Float.random(in: 0...60)
        
        bounds = getBounds(obj.zOrder)
        
        obj.position.x = bounds.minX
        obj.position.y = Float.random(in: bounds.minY/2...bounds.maxY/2)
        
        obj.scale.set(1, 1)
        obj.rotation = 0
        obj.velocity.set(Float.random(in: 2...10), 0)
        obj.textureID = textures[Int.random(in: 0...2)]
    }
    
}
