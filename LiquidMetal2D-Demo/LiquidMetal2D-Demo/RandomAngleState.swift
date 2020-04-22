//
//  RandomCircleState.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/21/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import simd
import MetalMath
import LiquidMetal2D

class RandomAngleState: State {
    private unowned let obj: BehavoirObj
    
    private let textures: [Int]
    private let getSpawnLocation: () -> simd_float2
    private let getBounds: () -> WorldBounds
    
    init(obj: BehavoirObj, getSpawnLocation: @escaping () -> simd_float2, getBounds: @escaping () -> WorldBounds, textures: [Int]) {
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
        
        if !isInRange(value: obj.position.x, low: bounds.minX, high: bounds.maxX) ||
            !isInRange(value: obj.position.y, low: bounds.minY, high: bounds.maxY) {
            randomize()
        }
    }
    
    private func randomize() {
        let spawnLocation = getSpawnLocation()
        
        obj.zOrder = 0
        obj.position.x = spawnLocation.x
        obj.position.y = spawnLocation.y
        
        let scale = Float.random(in: 0.25...1.5)
        obj.scale.set(scale, scale)
        
        obj.rotation = Float.random(in: 0...twoPi)
        obj.velocity.set(angle: obj.rotation)
        obj.velocity *= 5 * scale
        obj.textureID = textures[Int.random(in: 0..<textures.count)]
    }
    
}
