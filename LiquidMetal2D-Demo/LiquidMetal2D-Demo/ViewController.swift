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
        sceneFactory.addScene(type: SceneTypes.visualDemo, builder: TSceneBuilder<VisualDemo>())
        sceneFactory.addScene(type: SceneTypes.inputDemo, builder: TSceneBuilder<InputDemo>())
        sceneFactory.addScene(type: SceneTypes.explosionDemo, builder: TSceneBuilder<ExplosionDemo>())
        sceneFactory.addScene(type: SceneTypes.schedulerDemo, builder: TSceneBuilder<SchedulerDemo>())
        sceneFactory.addScene(type: SceneTypes.stateDemo, builder: TSceneBuilder<StateDemo>())
        sceneFactory.addScene(type: SceneTypes.collisionDemo, builder: TSceneBuilder<CollisionDemo>())
        sceneFactory.addScene(type: SceneTypes.pauseDemo, builder: TSceneBuilder<PauseDemo>())

        let renderer = DefaultRenderer(
            parentView: self.view,
            maxObjects: GameConstants.MAX_OBJECTS,
            uniformSize: WorldUniform.typeSize())

        gameEngine = DefaultEngine(
            renderer: renderer,
            intitialSceneType: SceneTypes.visualDemo,
            sceneFactory: sceneFactory)

        gameEngine.run()
    }
}
