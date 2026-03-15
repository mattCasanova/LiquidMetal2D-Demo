//
//  PlayerStateMachine.swift
//  LiquidMetal
//
//  Created by Matt Casanova on 3/20/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import LiquidMetal2D

class PlayerStateMachine: Behavoir {
  var current: State!

  private unowned let obj: BehavoirObj
  
  private let playerState: PlayerState
  
  init(obj: BehavoirObj, inputReader: InputReader) {
    self.obj = obj
    self.playerState = PlayerState(obj: self.obj, inputReader: inputReader)
    setStartState(startState: playerState)
  }
  
}
