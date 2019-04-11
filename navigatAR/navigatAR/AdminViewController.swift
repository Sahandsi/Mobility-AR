

import Firebase
import UIKit
import IndoorAtlas

class AdminViewController: UIViewControllerWithBuilding {

	let locationManager = IALocationManager.sharedInstance()

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		// Delegate methods to our custom location handler

		Database.database().reference().observeSingleEvent(of: .value, with: { snapshot in
			if let building = Building.current(root: snapshot) {
				print(building)
			} else {
				print("whoopsie")
			}
		})
		
		navigationItem.prompt = forBuilding.1.name
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func unwindFromNewEvent(segue: UIStoryboardSegue) { }
}
