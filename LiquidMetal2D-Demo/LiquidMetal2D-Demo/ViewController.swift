//
//  ViewController.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/8/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import UIKit
import LiquidMetal2D

class ViewController: LiquidViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let sceneFactory = SceneFactory()
    sceneFactory.addScene(type: SceneTypes.visualDemo, builder: GenericSceneBuilder<VisualDemo>())
    sceneFactory.addScene(type: SceneTypes.inputDemo,  builder: GenericSceneBuilder<InputDemo>())
    
    let renderer = DefaultRenderer(
      parentView: self.view,
      maxObjects: GameConstants.MAX_OBJECTS,
      uniformSize: TransformUniformData.typeSize())
    
    gameEngine = DefaultEngine(
      renderer: renderer,
      intitialSceneType: SceneTypes.inputDemo,
      sceneFactory: sceneFactory)
    
    gameEngine.run()
  }
}

