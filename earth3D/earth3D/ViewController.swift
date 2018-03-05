//
//  ViewController.swift
//  earth3D
//
//  Created by Julio César Fernández Muñoz on 1/3/18.
//  Copyright © 2018 Julio César Fernández Muñoz. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        sol()
        tierra()
    }
    
    func tierra() {
        guard let diffuse = UIImage(named: "art.scnassets/earth_diffuse_4k.jpg"), let specular = UIImage(named: "art.scnassets/earth_specular_1k.jpg"), let lights = UIImage(named: "art.scnassets/earth_lights_4k.jpg"), let normal = UIImage(named: "art.scnassets/earth_normal_4k.jpg"), let nubes = UIImage(named: "art.scnassets/clouds_transparent_2K.jpg") else {
            print("Error en la carga")
            return
        }
        
        let earthMaterial = SCNMaterial()
        earthMaterial.diffuse.contents = diffuse
        earthMaterial.normal.contents = normal
        earthMaterial.specular.contents = specular
        earthMaterial.emission.contents = lights
        earthMaterial.multiply.contents = UIColor(white: 0.7, alpha: 1.0)
        earthMaterial.shininess = 0.5
        
        let earth = SCNSphere(radius: 0.3)
        earth.firstMaterial = earthMaterial
        let earthNode = SCNNode(geometry: earth)
        earthNode.name = "tierra"
        
        earthNode.position = SCNVector3(0,0,-1)
        
        if let sunNode = sceneView.scene.rootNode.childNode(withName: "sol", recursively: false) {
            sunNode.constraints = [SCNLookAtConstraint(target: earthNode)]
        }
        
        let clouds = SCNSphere(radius: 0.325)
        clouds.segmentCount = 144
        let cloudsMaterial = SCNMaterial()
        cloudsMaterial.diffuse.contents = UIColor.white
        cloudsMaterial.locksAmbientWithDiffuse = true
        cloudsMaterial.transparent.contents = nubes
        cloudsMaterial.transparencyMode = .rgbZero
        cloudsMaterial.writesToDepthBuffer = false
        
        clouds.firstMaterial = cloudsMaterial
        
        if let shaderURL = Bundle.main.path(forResource: "AtmosphereHalo", ofType: "glsl"), let content = FileManager.default.contents(atPath: shaderURL), let shader = String(data:content, encoding:.utf8) {
            cloudsMaterial.shaderModifiers = [SCNShaderModifierEntryPoint.fragment: shader]
        }
        
        let cloudNode = SCNNode(geometry: clouds)
        cloudNode.name = "nubes"
        cloudNode.rotation = SCNVector4(0,1,0,0)
        earthNode.addChildNode(cloudNode)
        
        let axisNode = SCNNode()
        axisNode.name = "eje"
        sceneView.scene.rootNode.addChildNode(axisNode)
        axisNode.addChildNode(earthNode)
        axisNode.rotation = SCNVector4(1,0,0, Double.pi/6.0)
    }
    
    func sol() {
        let sun = SCNLight()
        sun.type = .spot
        sun.castsShadow = true
        sun.shadowRadius = 0.3
        sun.shadowColor = UIColor(white: 0.0, alpha: 0.75)
        sun.zNear = 1.0
        sun.zFar = 4.0
        
        let sunNode = SCNNode()
        sunNode.light = sun
        sunNode.name = "sol"
        sunNode.position = SCNVector3(-15,0,12)
        sceneView.scene.rootNode.addChildNode(sunNode)
        
        if let intensidad = sceneView.session.currentFrame?.lightEstimate?.ambientIntensity {
            sun.intensity = intensidad
        }
        if let temperatura = sceneView.session.currentFrame?.lightEstimate?.ambientColorTemperature {
            sun.temperature = temperatura
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
    
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let sol = sceneView.scene.rootNode.childNode(withName: "sol", recursively: false), let intensidad = frame.lightEstimate?.ambientIntensity, let temperature = frame.lightEstimate?.ambientColorTemperature else {
            print("ERROR")
            return
        }
        sol.light?.intensity = intensidad
        sol.light?.temperature = temperature
    }
}
