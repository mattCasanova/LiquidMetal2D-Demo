//
//  InputDemo.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/9/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import UIKit
import MetalMath
import LiquidMetal2D

class InputDemo: Scene {
  private var sceneMgr: SceneManager!
  private var renderer: Renderer!
  private var input: InputReader!
  
  
  var distance: Float = 40
  
  let objectCount = GameConstants.MAX_OBJECTS
  var objects = [GameObj]()
  
  let spawnPos = Vector2D()
  
  var uiView: UIView!
  var nextButton: UIButton!
  var prevButton: UIButton!
  var popButton: UIButton!
  
  private var textures = [Int]()
  
  func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
    self.sceneMgr = sceneMgr
    self.renderer = renderer
    self.input = input
    
    textures.append(renderer.loadTexture(name: "playerShip1_blue", ext: "png", isMipmaped: true, shouldFlip: true))
    textures.append(renderer.loadTexture(name: "playerShip1_green", ext: "png", isMipmaped: true, shouldFlip: true))
    textures.append(renderer.loadTexture(name: "playerShip1_orange", ext: "png", isMipmaped: true, shouldFlip: true))
    
    
    
    renderer.setPerspective(
      fov: GameMath.toRadian(fromDegree: getFOV()),
      aspect: renderer.screenAspect,
      nearZ: PerspectiveData.defaultNearZ,
      farZ: PerspectiveData.defaultFarZ)
    
    renderer.setCamera(x: 0, y: 0, distance: distance)
    
    
    let clearColor = Vector3D()
    clearColor.r = 0
    clearColor.g = 0
    clearColor.b = 0
    renderer.setClearColor(clearColor: clearColor)
    
    createObjects()
    createUI()
  }
  
  func update(dt: Float) {
    
    let touch = input.getWorldTouch()
    
    if let touch = touch {
      spawnPos.setX(touch.x, andY: touch.y)
    }
    
    for i in 0..<objectCount {
      let obj = objects[i]
      obj.position += obj.velocity * dt
      
      if obj.position.lengthSquared >= 3600 {
        randomize(obj: obj)
      }
    }
    
    //We can sort by scale to give the illusion of 3D
    objects.sort(by: {first, second in return first.scale.x < second.scale.x })
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
    uiView.removeFromSuperview()
  }
  
  func resize() {
    uiView.frame = renderer.view.safeAreaLayoutGuide.layoutFrame
    
    nextButton.frame = CGRect(
      x: 0,
      y: uiView.frame.height - 44,
      width: 100,
      height: 44)
    
    let x = uiView.frame.width - 100
    prevButton.frame = CGRect(
      x: x,
      y: uiView.frame.height - 44,
      width: 100,
      height: 44)
    
    popButton.frame = CGRect(
       x: uiView.frame.width / 2 - 50,
       y: uiView.frame.height - 44,
       width: 100,
       height: 44)
    
    renderer.setPerspective(
      fov: GameMath.toRadian(fromDegree: getFOV()),
      aspect: renderer.screenAspect,
      nearZ: PerspectiveData.defaultNearZ,
      farZ: PerspectiveData.defaultFarZ)
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
    
    
    obj.zOrder = 0
    obj.position.x = spawnPos.x
    obj.position.y = spawnPos.y
    
    let scale = Float.random(in: 0.25...1.5)
    obj.scale.setX(scale, andY: scale)
    
    obj.rotation = Float.random(in: 0...GameMath.twoPi())
    obj.velocity.setRotation(obj.rotation)
    obj.velocity *= 5 * scale
    obj.textureID = Int.random(in: 0...2)
    
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
    
    popButton = UIButton(frame: CGRect(x: (uiView.frame.width / 2) - 50 , y: uiView.frame.height - 44, width: 100, height: 44))
    popButton.backgroundColor = UIColor.red
    popButton.setTitle("Pop", for: .normal)
    popButton.layer.cornerRadius = 4
    popButton.addTarget(self, action: #selector(onPop), for: .touchUpInside)
    uiView.addSubview(popButton)
  }
  
  @objc func onNext() {
    sceneMgr.setScene(type: SceneTypes.visualDemo)
  }
  
  @objc func onPrev() {
    sceneMgr.setScene(type: SceneTypes.visualDemo)
  }
  
  @objc func onPop() {
    sceneMgr.popScene()
  }
  
  static func build() -> Scene {
    return InputDemo()
  }
  
}


