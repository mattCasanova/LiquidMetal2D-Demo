//
//  VisualDemo.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/8/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//


import UIKit
import MetalMath
import LiquidMetal2D

class VisualDemo: Scene {
  private var sceneMgr: SceneManager!
  private var renderer: Renderer!
  private var input: InputReader!
  


  var backgroundTime: Float = 0
  let maxBackgroundChangeTime: Float = 2
  
  
  var cameraTime: Float = 0.0
  var camDistance: Float = 30
  var distance: Float = 40
  
  let objectCount = GameConstants.MAX_OBJECTS
  var objects = [GameObj]()
  
  var startColor = Vector3D()
  var endColor = Vector3D()
  
  var nextButton: UIButton!
  
  private var textures = [Int]()
  
  func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
    self.sceneMgr = sceneMgr
    self.renderer = renderer
    self.input = input
    
    startColor.r = 0.5
    startColor.g = 0
    startColor.b = 0.5
    
    endColor.r = 0
    endColor.g = 0
    endColor.b = 0
    
    textures.append(renderer.loadTexture(name: "playerShip1_blue", ext: "png", isMipmaped: true, shouldFlip: true))
    textures.append(renderer.loadTexture(name: "playerShip1_green", ext: "png", isMipmaped: true, shouldFlip: true))
    textures.append(renderer.loadTexture(name: "playerShip1_orange", ext: "png", isMipmaped: true, shouldFlip: true))
    
    
    renderer.setPerspective(
      fov: GameMath.toRadian(fromDegree: getFOV()),
      aspect: renderer.screenAspect,
      nearZ: PerspectiveData.defaultNearZ,
      farZ: PerspectiveData.defaultFarZ)
    renderer.setCamera(x: 0, y: 0, distance: distance)
    
    createObjects()
    
    
    nextButton = UIButton(frame: CGRect(x: renderer.view.safeAreaInsets.left, y: renderer.view.safeAreaInsets.top, width: 100, height: 44))
    nextButton.backgroundColor = UIColor.black
    nextButton.setTitle("Next", for: .normal)
    nextButton.layer.cornerRadius = 4
    
    nextButton.addTarget(self, action: #selector(onClick), for: .touchUpInside)
    
    renderer.view.addSubview(nextButton)
    
  }
  
  @objc func onClick() {
    createObjects()
  }
  
  func resize() {
    nextButton.frame = CGRect(
      x: renderer.view.safeAreaInsets.left,
      y: renderer.view.safeAreaInsets.top,
      width: 100,
      height: 44)
    
    renderer.setPerspective(
    fov: GameMath.toRadian(fromDegree: getFOV()),
    aspect: renderer.screenAspect,
    nearZ: PerspectiveData.defaultNearZ,
    farZ: PerspectiveData.defaultFarZ)
  }
  
  func update(dt: Float) {

    
    cameraTime += dt * 0.1 //To slow down the camera
    let newDist = -sinf(cameraTime) * camDistance + distance
    renderer.setCamera(x: 0, y: 0, distance: newDist)
    
    /*
    let touch = input.getWorldTouch()
    
    if let touch = touch {
      renderer.setCamera(x: 0, y: 0, distance: newDist)
    } else {
      renderer.setCamera(x: 0, y: 0, distance: newDist)
    }*/
    
    
    //renderer.setCamera(x: 0, y: 0, distance: distance)
    //let vec = renderer.unProject(screenCoordinate: Vector2D(x: 0, y: 0))
    
    /*if let vec = input.getWorldTouch() {
      objects[0].rotation = vec.angle
    }*/
    
    
    backgroundTime += dt
    let clearColor = startColor.linearInterpolate(
      to: endColor,
      atTime: backgroundTime / maxBackgroundChangeTime)
    
    renderer.setClearColor(clearColor: clearColor)
    
    if backgroundTime >= maxBackgroundChangeTime {
      backgroundTime = 0
      let temp = startColor
      startColor = endColor
      endColor = temp
    }
    
    for i in 0..<objectCount {
      let obj = objects[i]
      obj.position += obj.velocity * dt
      
      if obj.position.lengthSquared >= 3600 {
        randomize(obj: obj)
      }
    }
    
    //We must sort by z before drawing to have alpha blending work correctly
    objects.sort(by: {first, second in return first.zOrder < second.zOrder })
  }
  
  func draw() {
    let worldUniforms = TransformUniformData()
    
    renderer.beginRenderPass()
    renderer.renderPerspective()
    
    for i in 0..<objectCount {
      let obj = objects[i]
      
      renderer.setTexture(textureId: obj.textureID)
      worldUniforms.transform.setToScaleX(
        obj.scale.x,
        scaleY:  obj.scale.y,
        radians: obj.rotation,
        transX:  obj.position.x,
        transY:  obj.position.y,
        zOrder:  obj.zOrder)
      renderer.draw(uniforms: worldUniforms)
    }
    
    renderer.endRenderPass()
  }
  
  func shutdown() {
    nextButton.removeFromSuperview()
  }
  
  
  private func getFOV() -> Float {
    return renderer.screenWidth <= renderer.screenHeight ? 90 : 45;
  }
  
  private func createObjects() {
    objects.removeAll()
    
    for _ in 0..<objectCount {
      let obj = GameObj()
      randomize(obj: obj)
      objects.append(obj)
    }
  }
  
  private func randomize(obj: GameObj) {
    /*
    obj.zOrder = 0
    obj.position.x = 0
    obj.position.y = 0
    
    
    obj.scale.setX(20, andY: 20)
    obj.textureID = 0
    obj.rotation = 0
    obj.velocity.setX(0, andY: 0)
    obj.textureID = Int.random(in: 0...2)
 */
    
    obj.zOrder = Float.random(in: 0...60)
     obj.position.x = -30
     obj.position.y = Float.random(in: -10...10)
     
     
     obj.scale.setX(1, andY: 1)
     obj.textureID = 0
     obj.rotation = 0
     obj.velocity.setX(Float.random(in: 2...10), andY: 0)
     obj.textureID = Int.random(in: 0...2)
     
    
    /*
     obj.position.x = 0//Float.random(in: -5...5)
     obj.position.y = 0//Float.random(in: -10...10)
     
     let scale = Float.random(in: 0.25...5)
     obj.scale.setX(scale, andY: scale)
     
     
     
     obj.rotation = Float.random(in: 0...GameMath.twoPi())
     obj.velocity.setRotation(obj.rotation)
     obj.velocity *= (Float.random(in: 1...10))
     */
  }
  
  static func build() -> Scene {
    return VisualDemo()
  }
  
}

