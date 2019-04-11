
enum NodeType: String, Codable {
	// Generic stuff
	case pointOfInterest
	
	// More specific nodes
	case pathway
	case bathroom
	case printer
	case waterFountain
	case room
	case cafe
    case elevator
    case door
	
	// TODO: add more types if necessary
}

struct Node: Codable {
	let building: FirebasePushKey
	let name: String
	let type: NodeType
	let position: Location
	// there's no way to provide a default value for this when decoding without a custom implementation, so has to be optional
	let tags: [String: Tag]?
	var connectedTo: FirebaseArray<FirebasePushKey>?
	let highPriority: Bool?
}
