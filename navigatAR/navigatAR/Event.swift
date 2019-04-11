

import Foundation

struct Event: Codable {
	let name: String
	let description: String
	let locations: FirebaseArray<FirebasePushKey>
	let start: Date
	let end: Date
}
