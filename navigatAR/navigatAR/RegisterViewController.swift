

import CodableFirebase
import Eureka
import Firebase

class RegisterViewController: FormViewController {
     @IBOutlet weak var errorLabel: UILabel!
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
        
		form +++ Section("Register")
			<<< EmailRow("email") { row in
				row.title = "Email"
				row.placeholder = "jobs@example.com"
			}
			<<< PasswordRow("password") { row in
				row.title = "Password"
				row.placeholder = "6 or more characters"
			}
			<<< PasswordRow("confirmPassword") { row in
				row.title = "Confirm Password"
			}
		
		form +++ ButtonRow { row in
			row.title = "Register"
			row.disabled = Condition.function(["password", "confirmPassword"]) { form in
				let password = (form.rowBy(tag: "password") as? PasswordRow)?.value
				let confirm = (form.rowBy(tag: "confirmPassword") as? PasswordRow)?.value
				
				return !(password == confirm)
			}
			
			row.onCellSelection(self.register)
		}
	}
	
	func register(cell: ButtonCellOf<String>, row: ButtonRow) {
		let formValues = form.values()
		
		guard let email = formValues["email"]! as? String, let password = formValues["password"]! as? String else { return }
		
		Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
			guard let user = user else {
				print("error signing up somehow", error!) // TODO: properly handle error
                let alert = UIAlertController(title: "Email already exists", message: "This email is already exists please login.", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                
                self.present(alert, animated: true)
				return
			}
			
			let userObject = User(email: email, admin: [])
			Database.database().reference().child("users/\(user.uid)").setValue(try! FirebaseEncoder().encode(userObject))
			
			_ = self.navigationController?.popViewController(animated: true)
		}
	}
}

