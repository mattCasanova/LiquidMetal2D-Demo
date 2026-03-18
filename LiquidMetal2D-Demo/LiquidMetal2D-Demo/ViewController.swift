//
//  ViewController.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/8/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import UIKit
import LiquidMetal2D

/// The app's root view controller, subclassing LiquidViewController.
///
/// **Engine setup pattern:** This is the entry point for a LiquidMetal2D app. The three
/// steps to launch the engine are:
///
/// 1. **Register scenes with a SceneFactory:** Create a `SceneFactory` and call
///    `addScene(type:builder:)` for every scene in your game. `TSceneBuilder<T>` is a
///    generic builder that calls `T.build()` to create scene instances. The `type` parameter
///    is your `SceneType` enum value.
///
/// 2. **Create a renderer:** `DefaultRenderer` is the engine's Metal-based renderer.
///    It needs the parent UIView, the maximum number of objects you will draw per frame
///    (`maxObjects`), and the byte size of your per-object uniform struct (`uniformSize`).
///    `WorldUniform.typeSize()` returns the correct size for the built-in uniform type.
///
/// 3. **Create and run the engine:** `DefaultEngine` takes the renderer, the initial scene
///    type, and the scene factory. Calling `gameEngine.run()` starts the CADisplayLink
///    game loop. The engine owns the game loop and scene stack from this point forward.
///
/// `LiquidViewController` (the superclass) handles device rotation (calling `resize()` on
/// the active scene), touch forwarding (populating the `InputReader` that scenes query),
/// and provides the `gameEngine` property. You only need to override `viewDidLoad()`.
class ViewController: LiquidViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Step 1: Register all scenes with the factory.
        // Each SceneType maps to a builder that can create instances of that scene.
        let sceneFactory = SceneFactory()
        sceneFactory.addScene(type: SceneTypes.visualDemo, builder: TSceneBuilder<VisualDemo>())
        sceneFactory.addScene(type: SceneTypes.inputDemo, builder: TSceneBuilder<InputDemo>())
        sceneFactory.addScene(type: SceneTypes.explosionDemo, builder: TSceneBuilder<ExplosionDemo>())
        sceneFactory.addScene(type: SceneTypes.schedulerDemo, builder: TSceneBuilder<SchedulerDemo>())
        sceneFactory.addScene(type: SceneTypes.stateDemo, builder: TSceneBuilder<StateDemo>())
        sceneFactory.addScene(type: SceneTypes.collisionDemo, builder: TSceneBuilder<CollisionDemo>())
        sceneFactory.addScene(type: SceneTypes.bezierDemo, builder: TSceneBuilder<BezierDemo>())
        sceneFactory.addScene(type: SceneTypes.pauseDemo, builder: TSceneBuilder<PauseDemo>())

        // Step 2: Create the Metal renderer.
        // maxObjects defines the triple-buffered uniform ring buffer size.
        // uniformSize is the byte size of each object's GPU data (transform matrix, etc.).
        let renderer = DefaultRenderer(
            parentView: self.view,
            maxObjects: GameConstants.MAX_OBJECTS,
            uniformSize: WorldUniform.typeSize())

        // Step 3: Create the engine and start the game loop.
        // The engine manages the scene stack, calls update/draw each frame via CADisplayLink,
        // and routes input events from LiquidViewController to the active scene.
        gameEngine = DefaultEngine(
            renderer: renderer,
            initialSceneType: SceneTypes.visualDemo,
            sceneFactory: sceneFactory)

        gameEngine.run()
    }
}
