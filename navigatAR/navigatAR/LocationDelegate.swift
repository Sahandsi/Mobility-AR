

import CoreLocation
import IndoorAtlas

protocol LocationDelegate: class {
	func locationUpdate(currentLocation: Location?, kalmanLocation: CLLocation?)
}
