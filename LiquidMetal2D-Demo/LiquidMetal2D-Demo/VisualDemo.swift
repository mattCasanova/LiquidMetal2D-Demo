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
  var objects = [BehavoirObj]()
  
  var startColor = Vector3D()
  var endColor = Vector3D()
  
  var uiView: UIView!
  var nextButton: UIButton!
  var prevButton: UIButton!
  var pushButton: UIButton!
  
  private let scheduler = Scheduler()
  
  private var textures = [Int]()
  
  func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
    self.sceneMgr = sceneMgr
    self.renderer = renderer
    self.input = input
    
    startColor.r = 0.7
    startColor.g = 0
    startColor.b = 0.7
    
    endColor.r = 0.0
    endColor.g = 1.0
    endColor.b = 1.0
    
    let textureNames = [
      "playerShip1_blue",
      "playerShip1_green",
      "playerShip1_orange"
    ]
    textureNames.forEach({
      textures.append(renderer.loadTexture(
        name: $0,
        ext: "png",
        isMipmaped: true,
        shouldFlip: true))
    })
    
    renderer.setCamera(x: 0, y: 0, distance: distance)
    renderer.setPerspective(
      fov: GameMath.toRadian(fromDegree: getFOV()),
      aspect: renderer.screenAspect,
      nearZ: PerspectiveData.defaultNearZ,
      farZ: PerspectiveData.defaultFarZ)

    
    scheduler.add(task: Task(time: maxBackgroundChangeTime, action: { [unowned self] in
      self.backgroundTime = 0
      let temp = self.startColor
      self.startColor = self.endColor
      self.endColor = temp
    }))
    
    createObjects()
    createUI()
  }
  
  func resume() {
    uiView.isHidden = false
  }
  
  func resize() {
    uiView.frame = renderer.view.safeAreaLayoutGuide.layoutFrame
    
    let frameWidth = uiView.frame.width
    let frameHeight = uiView.frame.height
    let buttonWidth: CGFloat = 100
    let buttonHeight: CGFloat = 44
    
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
    
    renderer.setPerspective(
      fov: GameMath.toRadian(fromDegree: getFOV()),
      aspect: renderer.screenAspect,
      nearZ: PerspectiveData.defaultNearZ,
      farZ: PerspectiveData.defaultFarZ)
  }
  
  func update(dt: Float) {
    
    scheduler.update(dt: dt)
    
    
    cameraTime += dt * 0.5 //To slow down the camera
    let newDist = -sinf(cameraTime) * camDistance + distance
    renderer.setCamera(x: 0, y: 0, distance: newDist)
    

    
    backgroundTime += dt
    let clearColor = startColor.linearInterpolate(
      to: endColor,
      atTime: backgroundTime / maxBackgroundChangeTime)
    
    renderer.setClearColor(clearColor: clearColor)
    
    
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
      worldUniforms.transform.setToScaleX(
        obj.scale.x,
        scaleY:  obj.scale.y,
        radians: obj.rotation,
        transX:  obj.position.x,
        transY:  obj.position.y,
        zOrder:  obj.zOrder)
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
    
    let getBounds = { [unowned self] (zOrder: Float) -> Bounds in
      return self.renderer.getWorldBounds(cameraDistance: self.distance + self.camDistance, zOrder: zOrder)
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
  
  static func build() -> Scene {
    return VisualDemo()
  }
  
}

