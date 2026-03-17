//
//  RandomCircleBehavoir.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/21/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import LiquidMetal2D

class RandomAngleBehavoir: Behavoir {
    var current: State!
    
    
    private let randomAngleState: RandomAngleState
    
    init(obj: BehavoirObj, getSpawnLocation: @escaping () -> Vec2, getBounds: @escaping () -> WorldBounds, textures: [Int]) {
        randomAngleState = RandomAngleState(
            obj: obj,
            getSpawnLocation: getSpawnLocation,
            getBounds: getBounds,
            textures: textures)
        setStartState(startState: randomAngleState)
    }
    
}
