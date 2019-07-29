import ARKit

class Anchor: ARAnchor {
    var type: NodeType? // to assign a node tpe of either "trapped dog" or "fuel" to Anchors

}

enum NodeType: String {
    case trappedDog = "trapped dog"
    case fuel = "fuel"
} // declaring and defining enumertion outside of class enables other casses like Scene and ViewController to access it
