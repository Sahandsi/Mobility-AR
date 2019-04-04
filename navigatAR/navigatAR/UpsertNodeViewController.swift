//
//  UpsertNodeViewController.swift
//  navigatAR
//
//  Created by Michael Gira on 2/3/18.
//  Copyright © 2018 MICDS Programming. All rights reserved.
//

import CodableFirebase
import Eureka
import Firebase
import IndoorAtlas

class UpsertNodeViewController: FormViewController {

	@IBAction func unwindToUpsertNodes(unwindSegue: UIStoryboardSegue) {
		let r: CheckRow! = form.rowBy(tag: "location")
		r.value = locationData != nil
		r.reload()
	}
	
	let nodeTypes: [(display: String, value: NodeType)] = [(
		display: "Pathway",
		value: .pathway
	), (
		display: "Bathroom",
		value: .bathroom
	), (
		display: "Printer",
		value: .printer
	), (
		display: "Water Fountain",
		value: .fountain
	), (
		display: "Room",
		value: .room
	), (
		display: "Sports Venue",
		value: .sportsVenue
	), (
		display: "Point of Interest",
		value: .pointOfInterest
	)]
	
	let ref = Database.database().reference()
	
	var tagInfos: [TagInfo] = []
	
	var locationData: Location?
//	var currentBuilding: Building?

	override func viewDidLoad() {
		super.viewDidLoad()

		form +++ Section("Name")
			<<< TextRow("name") {
				$0.value = "Presentation Stage"
				$0.title = "Name"
				$0.placeholder = "Ex. STEM 252"
			}
	
		+++ SelectableSection<ListCheckRow<String>>("Node Type", selectionType: .singleSelection(enableDeselection: true))

		for option in nodeTypes {
			form.last! <<< ListCheckRow<String>(String(describing: option.value)){ listRow in
				listRow.title = option.display
				listRow.selectableValue = String(describing: option.value)
				listRow.value = nil
			}
		}

		form +++ Section("Location")
			<<< CheckRow("location") { row in
				row.title = "Location"
//				row.value = true
				row.disabled = true
			}
			<<< ButtonRow() { row in
			row.title = locationData == nil ? "Record Location" : "Record Location Again"
			row.onCellSelection(self.recordPosition)
		}

		form +++ ButtonRow() { row in
			row.title = "Create"
//			row.disabled = Condition.function(["... Tags ..."]) { form in
//				return form.validate().count != 0
//			}
			row.onCellSelection(self.createNode)
		}
		
		ref.observeSingleEvent(of: .value, with: { snapshot in
			guard let currentBuilding = Building.current(root: snapshot) else { print("not in a building"); return }
			guard let value = snapshot.childSnapshot(forPath: "tags").value else { return }
			
			do {
				self.tagInfos = Array((try FirebaseDecoder().decode([FirebasePushKey: TagInfo].self, from: value)).values).filter({ $0.building == currentBuilding.id })
			} catch let err {
				print(err) // handle error properly
				return
			}

			if !self.tagInfos.isEmpty {
				// TODO: figure out how to insert this in the right place
				let tagsSection = Section("Tags")
				self.form.insert(tagsSection, at: 3 /* After location */)
				
				for tagInfo in self.tagInfos {
					// TODO: Figure out multiple values
					if tagInfo.multiple {
						self.form.insert(MultivaluedSection(multivaluedOptions: [.Insert, .Delete], header: tagInfo.name) { section in
							section.tag = tagInfo.name
							section.addButtonProvider = { _ in
								return ButtonRow() { row in
									row.title = "Add New Value"
								}
							}
							
							let rowCallback = { (_: Int) -> BaseRow in
								switch tagInfo.type {
								case .string:
									return TextRow() { row in
										row.placeholder = tagInfo.name
									}
								case .number:
									return IntRow() { row in
										row.placeholder = tagInfo.name
									}
								default:
									return BaseRow() // ok compiler, sure
								}
							}
							
							section.multivaluedRowToInsertAt = rowCallback
							section <<< rowCallback(0)
						}, at: 4)
					} else {
						switch tagInfo.type {
						case .string:
							tagsSection <<< TextRow(tagInfo.name) { row in
								row.title = tagInfo.name
								row.placeholder = "Text"
							}
						case .number:
							tagsSection <<< IntRow(tagInfo.name) { row in
								row.title = tagInfo.name
								row.placeholder = "Number"
							}
						case .boolean:
							tagsSection <<< SwitchRow(tagInfo.name) { row in
								row.title = tagInfo.name
							}
						}
					}
				}
			}
		})

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func createNode(cell: ButtonCellOf<String>, row: ButtonRow) {
		let formValues = form.values()

		var selectedNodeType: NodeType? = nil
		for nodeType in nodeTypes {
			if formValues[String(describing: nodeType.value)]! != nil {
				selectedNodeType = nodeType.value
			}
		}

		// Make sure user selected type
		/** @TODO Actually add form validation and disable button */
		if (formValues["name"] == nil || selectedNodeType == nil || locationData == nil) {
			return
		}
		
		ref.observeSingleEvent(of: .value, with: { snapshot in
			guard let currentBuilding = Building.current(root: snapshot) else {
				print("not in a building")
				return
			}
			
			let tags: [String: Tag] = self.tagInfos.reduce(into: [:]) { (result, tagInfo) in
				if let formValue = formValues[tagInfo.name]! {
					var tagValue: Tag? = nil
					
					switch (tagInfo.type, tagInfo.multiple) {
					case (.string, false):
						tagValue = Tag.string(formValue as! String)
					case (.number, false):
						tagValue = Tag.number(formValue as! Int)
					case (.boolean, false):
						tagValue = Tag.boolean(formValue as! Bool)
					case (.string, true):
						tagValue = Tag.multipleStrings(FirebaseArray(values: (formValue as! [String?]).compactMap { $0 }))
					case (.number, true):
						tagValue = Tag.multipleNumbers(FirebaseArray(values: (formValue as! [Int?]).compactMap { $0 }))
					default:
						break // thanks, compiler
					}
					
					result[tagInfo.name] = tagValue!
				}
			}
			
			print("Create Node!", selectedNodeType!, self.form.validate(), self.form.values(), self.locationData ?? "No Location"/*, currentBuilding*/);
			
			let data = try! FirebaseEncoder().encode(Node(
				building: currentBuilding.id,
				name: formValues["name"] as! String,
				type: selectedNodeType!,
				position: self.locationData!,
				tags: tags,
				connectedTo: [],
				highPriority: false
			))
			
			self.ref.child("nodes").childByAutoId().setValue(data)

			_ = self.navigationController?.popViewController(animated: true)
//			self.performSegue(withIdentifier: "unwindToUpsertNodesWithUnwindSegue", sender: self)
		})
	}
	
	func recordPosition(cell: ButtonCellOf<String>, row: ButtonRow) {
		performSegue(withIdentifier: "NodePositionSegue", sender: self)
	}

}

//extension UpsertNodeViewController: IALocationManagerDelegate {
//	func indoorLocationManager(_ manager: IALocationManager, didEnter region: IARegion) {
//		try? currentBuilding = Building(fromIARegion: region)
//	}
//}

