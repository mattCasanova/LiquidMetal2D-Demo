//
//  PlayerState.swift
//  LiquidMetal
//
//  Created by Matt Casanova on 3/20/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import LiquidMetal2D

class PlayerState: State, @unchecked Sendable {
    private unowned let obj: BehaviorObj
    private unowned let inputReader: InputReader

    init(obj: BehaviorObj, inputReader: InputReader) {
        self.obj = obj
        self.inputReader = inputReader
    }

    func enter() {}
    func exit() {}

    func update(dt: Float) {
        MainActor.assumeIsolated {
            if let touch = inputReader.getWorldTouch(forZ: 0) {
                obj.rotation = atan2(touch.y, touch.x)
            }
        }
    }
}
