//
//  RegisterViewController.swift
//  connectionsRegistration
//
//  Created by Venkat Dikonda on 4/08/20.
//  Copyright © 2020 Venkat Dikonda. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class RegisterViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    var editProfileSegue = "successfulSignupSegue"
    
    @IBOutlet weak var emailAddress: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    @IBOutlet weak var errorMsg: UILabel!
    @IBOutlet weak var phoneNumber: UITextField!
    
    @IBAction func signUpPressed(_ sender: Any) {
        let db = Firestore.firestore()
       
        if (!emailAddress.text!.isEmpty && !password.text!.isEmpty && !confirmPassword.text!.isEmpty && !phoneNumber.text!.isEmpty) {
            let phoneText = phoneNumber.text?.digits
            if (password.text != confirmPassword.text) {
                errorMsg.text = "Passwords do not match"
            }
            else if (phoneText == nil || phoneText?.count != 10) {
                errorMsg.text = "Invalid phone number"
            }
            else {
                guard let email = emailAddress.text, !email.isEmpty else {
                        errorMsg.text = "Email is empty"
                        return
                }
                guard let password = password.text, !password.isEmpty else {
                        errorMsg.text = "Password is empty"
                        return
                }
                
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    guard let _ = authResult?.user, error == nil else {
                        print(error!.localizedDescription)
                        self.errorMsg.text = error!.localizedDescription
                        return
                    }

                    db.collection("users").document(Auth.auth().currentUser!.uid).setData([
                        "name": "New User",
                        "phoneNumber": phoneText!,
                        "connections": [Any](),
                        "pendingConnections": [Any](),
                        "pendingRelations": [Any](),
                        "sentConnections": [Any](),
                        "messages": [Any](),
                        "blockedUsers": [Any](),
                        "connectionMessagesOnly": true,
                        "hideProfile": false,
                        "maxRadius": 20
                    ]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                            self.errorMsg.text = "Invalid email or password"
                            return
                        } else {
                            print("Document successfully written!")
                            self.transitionToEditProfile(Auth.auth().currentUser!.uid)
                        }
                    }
                }
            }
        }
        else {
            errorMsg.text = "Please fill out all fields"
        }
    }
    
    func transitionToEditProfile(_ uid : String?) {
        sleep(1)
        FirebaseManager.manager = FirebaseManager()
        FirebaseManager.manager.loadSelf() {
            FirebaseManager.manager.uploadImage(image: UIImage(named: "Profile")!)
            DispatchQueue.global().async {
                DispatchQueue.main.sync {
                    let storyboard = UIStoryboard(name: "EditProfile", bundle:nil)
                    let editViewController = storyboard.instantiateViewController(withIdentifier: "EditProfile") as? EditProfileViewController
                    editViewController?.initialCreation = true
                    self.view.window?.rootViewController = editViewController
                    self.view.window?.makeKeyAndVisible()
                }
            }
        }
    }
    
    // Code to dismiss keyboard
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}
