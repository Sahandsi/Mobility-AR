

enum TagType: String, Codable {
	case string
	case number
	case boolean
}

struct TagInfo: Codable {
	let building: FirebasePushKey
	let multiple: Bool
	let name: String
	let type: TagType
}
