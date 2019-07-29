import SpriteKit
import ARKit

class Scene: SKScene {
    
    var sceneView: ARSKView {
        return view as! ARSKView
    }
    var isWorldSetUp = false
    var isWorldSetUp2 = false
    var aim: SKSpriteNode!
    let gameSize = CGSize(width: 2, height: 2)
    var haveFuel = false
    let spaceDogLabel = SKLabelNode(text: "Space Dogs Rescued")
    let numberOfDogsLabel = SKLabelNode(text: "0")
    var dogCount = 0 {
        didSet {
            self.numberOfDogsLabel.text = "\(dogCount)"
        }
    }
    var backgroundMusic: SKAudioNode!
    var logo: SKSpriteNode!
    var updateScore: SKLabelNode!
    var score = 0 {
        didSet {
            updateScore.text = "SCORE: \(score)"
        } // didset is a property observer, observe and respond to changes in a property's value
    }
    var lastScoreUpdateTime: TimeInterval = 0.0
    
    override func didMove(to view: SKView) {
        aim = SKSpriteNode(imageNamed: "aim")
        addChild(aim)
        
        setUpLabels()
        
        if let musicURL = Bundle.main.url(forResource: "backgroundmusic", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        } else {
            print("could not laod file")
        }
        
        createLogo()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isWorldSetUp == false && dogCount == 0 {
            setUpWorld()
            
        }
        
        if isWorldSetUp2 == false && dogCount == 4 {
            isWorldSetUp = false
            setUpWorld2()
        }
        
        adjustLighting()
        
        guard let currentFrame = sceneView.session.currentFrame else {
            return
        }
        collectFuel(currentFrame: currentFrame)
        updateScore(withCurrentTime: currentTime)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        rescueDog()
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let wait = SKAction.wait(forDuration: 0.5)
        let sequence = SKAction.sequence([fadeOut, remove, wait])
        logo.run(sequence) // adding fading logo when game is opened
    }
    
        
        func setUpWorld() {
        // Create anchor using the camera's current position
        guard let currentFrame = sceneView.session.currentFrame, let scene = SKScene(fileNamed: "Level1") else {
            return
            } //The first three lines inside the method now sets the currentFrame to be the currentFrame in the session and the scene to be our Level1.sks file we created earlier.
            
            /*
            // Create a transform with a translation of 0.2 meters in front of the camera
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -1.0
            let transform = simd_mul(currentFrame.camera.transform, translation)
            
            // Add a new anchor to the session
            let anchor = ARAnchor(transform: transform)
            sceneView.session.add(anchor: anchor)
            }
             */
            for node in scene.children {
                if let node = node as? SKSpriteNode {
                    var translation = matrix_identity_float4x4
                    let positionX = node.position.x/scene.size.width
                    let positionY = node.position.y/scene.size.height
                    translation.columns.3.x = Float(positionX*gameSize.width)
                    translation.columns.3.z = -Float(positionX*gameSize.height)
                    translation.columns.3.y = Float.random(in: -0.5..<0.5)
                    let transform = simd_mul(currentFrame.camera.transform, translation)
                    //let anchor = ARAnchor(transform: transform)
                    //sceneView.session.add(anchor: anchor)
                    let anchor = Anchor(transform: transform)
                    if let name = node.name,
                        let type = NodeType(rawValue: name) {
                        anchor.type = type
                        sceneView.session.add(anchor: anchor)
                    }
                }
            }
            isWorldSetUp = true
    }
    
    func setUpWorld2() {
        guard let currentFrame = sceneView.session.currentFrame, let scene = SKScene(fileNamed: "Level2") else {
            return
        }
        for node in scene.children {
            if let node = node as? SKSpriteNode {
                var translation = matrix_identity_float4x4
                let positionX = node.position.x/scene.size.width
                let positionY = node.position.y/scene.size.height
                translation.columns.3.x = Float(positionX*gameSize.width)
                translation.columns.3.z = -Float(positionX*gameSize.height)
                translation.columns.3.y = Float.random(in: -0.5..<0.5)
                let transform = simd_mul(currentFrame.camera.transform, translation)
                
                let anchor = Anchor(transform: transform)
                if let name = node.name,
                    let type = NodeType(rawValue: name) {
                    anchor.type = type
                    sceneView.session.add(anchor: anchor)
                }
            }
        }
        isWorldSetUp2 = true
    }
    func adjustLighting() {
        guard let currentFrame = sceneView.session.currentFrame, let lightEstimate = currentFrame.lightEstimate else {
            return }
            
            let neutralIntensity: CGFloat = 1000
            let ambientIntensity = min(lightEstimate.ambientIntensity, neutralIntensity)
            let blendFactor = 1 - ambientIntensity / neutralIntensity
            for node in children {
                if let spaceDog = node as? SKSpriteNode {
                    spaceDog.color = .black
                    spaceDog.colorBlendFactor = blendFactor
                }
            }
    }
    
    func rescueDog() {
        let location = aim.position
        let hitNodes = nodes(at: location)
        var rescuedDog: SKNode?
        for node in hitNodes {
            if node.name == "trapped dog" && haveFuel == true {
                rescuedDog = node
                break
            }
        }
        if let rescuedDog = rescuedDog {
            let wait = SKAction.wait(forDuration: 0.3)
            let removeDog = SKAction.removeFromParent()
            let sequence = SKAction.sequence([wait, removeDog])
            rescuedDog.run(sequence)
            dogCount += 1
        }
    }
    
    func collectFuel(currentFrame: ARFrame) {
        for anchor in currentFrame.anchors {
            guard let node = sceneView.node(for: anchor),
            node.name == NodeType.fuel.rawValue
                else {continue}
            let distance = simd_distance(anchor.transform.columns.3, currentFrame.camera.transform.columns.3)
            if distance < 0.1 {
                sceneView.session.remove(anchor: anchor)
                haveFuel = true
                break
            } // go through each anchor in the current frame
        }
    }
    
    func setUpLabels() {
        spaceDogLabel.fontSize = 20
        spaceDogLabel.fontName = "Futura-Medium"
        spaceDogLabel.color = .white
        spaceDogLabel.position = CGPoint(x: 0, y: 280)
        addChild(spaceDogLabel)
        
        numberOfDogsLabel.fontSize = 20
        numberOfDogsLabel.fontName = "Futura-Medium"
        numberOfDogsLabel.color = .white
        numberOfDogsLabel.position = CGPoint(x: 0, y: 240)
        addChild(numberOfDogsLabel)
    }
    
    func createLogo() {
        logo = SKSpriteNode(imageNamed: "Space Rescue")
        logo.position = CGPoint(x:frame.midX, y: frame.midY)
        addChild(logo)
    }
    
    func updateScore(withCurrentTime currentTime: TimeInterval) {
        let elapsedTime = currentTime - lastScoreUpdateTime
        if elapsedTime > 1.0 {
            score += 1
            lastScoreUpdateTime = currentTime
        }
    }
}
