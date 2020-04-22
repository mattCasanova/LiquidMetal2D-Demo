//
//  VisualDemo.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/8/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//


import UIKit
import simd
import MetalMath
import LiquidMetal2D

/*
 Cool Visual demo showing lots of characters on screen at different z orders.
 
 It also demos:
 * How how to move the camera
 * Very basic behavoir (state machine)
 * Changing state with next/prev
 * Pausing a state and moving to another state (Using Push)
 * Scheduling a task
 
 
 */
class VisualDemo: Scene {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!
    
    // Time data for chaning the background
    var backgroundTime: Float = 0
    let maxBackgroundChangeTime: Float = 2
    
    // State data for moving the camera
    var cameraTime: Float = 0.0
    var camDistance: Float = 30
    var distance: Float = 40
    
    // Create our list of game objects
    let objectCount = GameConstants.MAX_OBJECTS
    var objects = [BehavoirObj]()
    
    //Set up start and end colors for clear color
    var startColor = simd_float3(0.7, 0, 0.7)
    var endColor = simd_float3(0.0, 1, 1.0)
    
    
    var uiView: UIView!
    var nextButton: UIButton!
    var prevButton: UIButton!
    var pushButton: UIButton!
    
    // If we want some task to happen at a give interval, we can use a scheduler
    private let scheduler = Scheduler()
    
    private var textures = [Int]()
    
    /**
     The initialize method is called one when the scene is created.
     
     - parameters:
        - sceneMgr: Used to switch states
        - renderer: Used to control how the scene is displayed on the screen
        - input: Used to get screen/world touch location
     
     */
    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input
        
        
        // These are the textures to load
        let textureNames = [
            "playerShip1_blue",
            "playerShip1_green",
            "playerShip1_orange"
        ]
        
        // Load those textures and save them in an array.  For this state, we are just using a random texture
        // but if this was a real game, we would probably save them to a dictionary or otherwise give them a name
        // so we know which texture we are referencing
        textureNames.forEach({
            textures.append(renderer.loadTexture(
                name: $0,
                ext: "png",
                isMipmaped: true))
        })
        
        // Set the initial data for our renderer
        renderer.setCamera(point: simd_float3(0, 0, distance))
        renderer.setPerspective(
            fov:  degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
        
        
        // Add a task to change the background color at a given interval
        // This task will fire indefinitly since we don't give a count
        // Also notice that we are capturing unowned self.  If we do this, we must clear
        // the task in the shutdown method
        scheduler.add(task: Task(time: maxBackgroundChangeTime, action: { [unowned self] in
            self.backgroundTime = 0
            let temp = self.startColor
            self.startColor = self.endColor
            self.endColor = temp
        }))
        
        createObjects()
        createUI()
    }
    /**
     The resume method is called when a pushed scene exits via pop
     */
    func resume() {
        // Since we hid this scenes ui when pushing another scene, we need to show
        // it on resume
        uiView.isHidden = false
    }
    /**
     Resize gets called when the device window changes.  This may once and the start of the program
     and also whenever the screen is rotated
     */
    func resize() {
        // Make sure we are drawing at the most up to date frame
        // Because some screens how rounded corners or notches, we should
        // Only draw ui in the save area
        uiView.frame = renderer.view.safeAreaLayoutGuide.layoutFrame
        
        let frameWidth = uiView.frame.width
        let frameHeight = uiView.frame.height
        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 44
        
        // Just update size/location of all the ui elements
        nextButton.frame = CGRect(
            x: 0,
            y: frameHeight - buttonHeight,
            width: buttonWidth,
            height: buttonHeight)
        
        prevButton.frame = CGRect(
            x: frameWidth - buttonWidth,
            y: frameHeight - buttonHeight,
            width: buttonWidth,
            height: buttonHeight)
        
        pushButton.frame = CGRect(
            x: (frameWidth / 2) - (buttonWidth / 2),
            y: frameHeight - buttonHeight,
            width: buttonWidth,
            height: buttonHeight)
        
        // Also reset the projection matrix so it matches our current aspect ratio
        renderer.setPerspective(
            fov: degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
    }
    /**
     This is used to upate our game world every frame.  Ideally this would be called 60 FPS but we can't
     guarentee that, so instead, we get the time since the last frame
     
     - parameters:
        - dt: The delta time since the last frame
     */
    func update(dt: Float) {
        // Update all scheduled tasks and fire the task if ness
        scheduler.update(dt: dt)
        
        
        cameraTime += dt * 0.5 //To slow down the camera
        let newDist = -sinf(cameraTime) * camDistance + distance
        renderer.setCamera(point: simd_float3(0, 0, newDist))
        
        
        backgroundTime += dt
        let clearColor = simd_mix(startColor, endColor, simd_float3(repeating: backgroundTime / maxBackgroundChangeTime))
        renderer.setClearColor(color: clearColor)
        
        
        for i in 0..<objectCount {
            let obj = objects[i]
            obj.behavoir.update(dt: dt)
        }
        
        //We must sort by z before drawing to have alpha blending work correctly
        objects.sort(by: {first, second in return first.zOrder < second.zOrder })
    }
    
    func draw() {
        let worldUniforms = TransformUniformData()
        
        renderer.beginPass()
        renderer.usePerspective()
        
        for i in 0..<objectCount {
            let obj = objects[i]
            
            renderer.useTexture(textureId: obj.textureID)
            worldUniforms.transform.setToTransform2D(
                scale: obj.scale,
                angle: obj.rotation,
                translate: simd_float3(obj.position, obj.zOrder))
            renderer.draw(uniforms: worldUniforms)
        }
        
        renderer.endPass()
    }
    
    func shutdown() {
        objects.removeAll()
        uiView.removeFromSuperview()
        
        textures.forEach({ renderer.unloadTexture(textureId: $0) })
        textures.removeAll()
    }
    
    
    private func getFOV() -> Float {
        return renderer.screenWidth <= renderer.screenHeight ? 90 : 45;
    }
    
    private func createObjects() {
        objects.removeAll()
        
        let getBounds = { [unowned self] (zOrder: Float) -> WorldBounds in
            return self.renderer.getWorldBounds(
                cameraDistance: self.distance + self.camDistance,
                zOrder: zOrder)
        }
        
        for _ in 0..<objectCount {
            let obj = BehavoirObj()
            
            obj.behavoir = MoveRightBehavoir(obj: obj, getBounds: getBounds, textures: textures)
            
            objects.append(obj)
        }
    }
    
    private func createUI() {
        uiView = UIView(frame: renderer.view.safeAreaLayoutGuide.layoutFrame)
        renderer.view.addSubview(uiView)
        
        nextButton = UIButton(frame: CGRect(x: 0, y: uiView.frame.height - 44, width: 100, height: 44))
        nextButton.backgroundColor = UIColor.blue
        nextButton.setTitle("Next", for: .normal)
        nextButton.layer.cornerRadius = 4
        nextButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        uiView.addSubview(nextButton)
        
        prevButton = UIButton(frame: CGRect(x: uiView.frame.width + 100, y: uiView.frame.height - 44, width: 100, height: 44))
        prevButton.backgroundColor = UIColor.blue
        prevButton.setTitle("Prev", for: .normal)
        prevButton.layer.cornerRadius = 4
        prevButton.addTarget(self, action: #selector(onPrev), for: .touchUpInside)
        uiView.addSubview(prevButton)
        
        pushButton = UIButton(frame: CGRect(x: (uiView.frame.width / 2) - 50 , y: uiView.frame.height - 44, width: 100, height: 44))
        pushButton.backgroundColor = UIColor.red
        pushButton.setTitle("Push", for: .normal)
        pushButton.layer.cornerRadius = 4
        pushButton.addTarget(self, action: #selector(onPush), for: .touchUpInside)
        uiView.addSubview(pushButton)
    }
    
    @objc func onNext() {
        sceneMgr.setScene(type: SceneTypes.inputDemo)
    }
    
    @objc func onPrev() {
        sceneMgr.setScene(type: SceneTypes.inputDemo)
    }
    
    @objc func onPush() {
        uiView.isHidden = true
        sceneMgr.pushScene(type: SceneTypes.inputDemo)
    }
    
    static func build() -> Scene { return VisualDemo() }
    
}

