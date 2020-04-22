//
//  InputDemo.swift
//  LiquidMetal2D-Demo
//
//  Created by Matt Casanova on 3/9/20.
//  Copyright © 2020 Matt Casanova. All rights reserved.
//

import UIKit
import simd
import MetalMath
import LiquidMetal2D

class InputDemo: Scene {
    private var sceneMgr: SceneManager!
    private var renderer: Renderer!
    private var input: InputReader!
    
    
    var distance: Float = 40
    
    let objectCount = GameConstants.MAX_OBJECTS
    var objects = [GameObj]()
    
    var spawnPos = simd_float2()
    var bounds = WorldBounds(maxX: 0, minX: 0, maxY: 0, minY: 0)
    
    var uiView: UIView!
    var nextButton: UIButton!
    var prevButton: UIButton!
    var popButton: UIButton!
    
    private var textures = [Int]()
    
    func initialize(sceneMgr: SceneManager, renderer: Renderer, input: InputReader) {
        self.sceneMgr = sceneMgr
        self.renderer = renderer
        self.input = input
        
        textures.append(renderer.loadTexture(name: "playerShip1_blue", ext: "png", isMipmaped: true))
        textures.append(renderer.loadTexture(name: "playerShip1_green", ext: "png", isMipmaped: true))
        textures.append(renderer.loadTexture(name: "playerShip1_orange", ext: "png", isMipmaped: true))
        
        renderer.setCamera(point: simd_float3(0, 0, distance))
        renderer.setPerspective(
            fov: degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
        
        renderer.setClearColor(color: simd_float3())
        
        createObjects()
        createUI()
    }
    
    func resume() {
        
    }
    
    func update(dt: Float) {
        
        let touch = input.getWorldTouch(forZ: 0)
        
        if let touch = touch {
            spawnPos.set(touch.x, touch.y)
        }
        
        
        for i in 0..<objectCount {
            let obj = objects[i] as! BehavoirObj
            obj.behavoir.update(dt: dt)
        }
        
        //We can sort by scale to give the illusion of 3D
        objects.sort(by: {first, second in return first.scale.x < second.scale.x })
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
            fov: degreeToRadian(getFOV()),
            aspect: renderer.screenAspect,
            nearZ: PerspectiveProjection.defaultNearZ,
            farZ: PerspectiveProjection.defaultFarZ)
        
        bounds = renderer.getWorldBoundsFromCamera(zOrder: 0)
    }
    
    private func getFOV() -> Float {
        return renderer.screenWidth <= renderer.screenHeight ? 90 : 45;
    }
    
    private func createObjects() {
        objects.removeAll()
        
        bounds = renderer.getWorldBoundsFromCamera(zOrder: 0)
        
        let getSpawnLocation = { [unowned self] in
            return self.spawnPos
        }
        
        let getBounds = { [unowned self] in
            return self.bounds
        }
        
        for _ in 0..<objectCount {
            let obj = BehavoirObj()
            obj.behavoir = RandomAngleBehavoir(
                obj: obj,
                getSpawnLocation: getSpawnLocation,
                getBounds: getBounds,
                textures: textures)
            
            
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


