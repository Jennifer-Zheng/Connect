//
//  SettingsViewController.swift
//  Connect
//
//  Created by Nikhil Pandeti on 4/15/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import Foundation
import Firebase

class SettingsViewController: UIViewController {
    @IBOutlet weak var connectionMessagesOnlySwitch: UISwitch!
    @IBOutlet weak var hideProfileSwitch: UISwitch!
    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    var uid = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        uid = Auth.auth().currentUser!.uid
        showCurrentMaxRadius()
    }
    
    func showCurrentMaxRadius() {
        let db = Firestore.firestore()

        db.collection("users").document("\(uid)")
        .getDocument { document, error in
            guard let document = document, document.exists else {
            print("Error fetching document: \(error!)")
            return
          }
            let currMaxRadius = document.get("maxRadius") as? Float
            if currMaxRadius == 1 {
                self.radiusLabel.text = Int(currMaxRadius!).description + " mile"
            } else {
                self.radiusLabel.text = Int(currMaxRadius!).description + " miles"
            }
            self.radiusSlider.value = currMaxRadius!
        }
    }
    
    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Toggling "Only Allow Messages From Connections"
    @IBAction func onMessagesSettingToggle(_ sender: Any) {
        let db = Firestore.firestore()
        
        let userRef = db.collection("users").document("\(self.uid)");

        userRef.updateData([
            "connectionMessagesOnly": connectionMessagesOnlySwitch.isOn,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    // Toggling "Hide My Profile"
    @IBAction func onHideProfileToggle(_ sender: Any) {
        let db = Firestore.firestore()
        
        let userRef = db.collection("users").document("\(self.uid)");

        userRef.updateData([
            "hideProfile": hideProfileSwitch.isOn,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    @IBAction func radiusSliderUpdate(_ sender: UISlider, event: UIEvent) {
        // Round the radius to nearest whole number value
        let roundedValue = round(sender.value / 1) * 1
        sender.value = roundedValue
        if roundedValue == 1 {
            radiusLabel.text = Int(roundedValue).description + " mile"
        } else {
            radiusLabel.text = Int(roundedValue).description + " miles"
        }

        // Only update value in db when user finishes dragging
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .ended:
                let db = Firestore.firestore()
                let userRef = db.collection("users").document("\(self.uid)");
                userRef.updateData([
                    "maxRadius": radiusSlider.value,
                ]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Document successfully updated")
                    }
                }
            default:
                break
            }
        }
    }
    
    @IBAction func updatePhoneNumber(_ sender: Any) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document("\(self.uid)");
        if (phoneNumberTextField.text != "") {
            // Format phone number input so it only contains the digits
            let newPhoneNumber = phoneNumberTextField.text!.digits
            userRef.updateData([
                "phoneNumber": newPhoneNumber
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                    let controller = UIAlertController(
                        title: "Success!",
                        message: "Phone number was updated",
                        preferredStyle: .alert)
                    controller.addAction(UIAlertAction(
                        title: "OK",
                        style: .default,
                        handler: nil))
                    self.present(controller, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func updatePassword(_ sender: Any) {
        if (passwordTextField.text != "") {
            // Need to reauthenticate user to update password
            showReenterPasswordAlert()
        }
    }
    
    func showReenterPasswordAlert() {
        let reenterPasswordController = UIAlertController(
            title: "Reauthentication required",
            message: "Please enter your current password",
            preferredStyle: .alert)
        reenterPasswordController.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil))
        reenterPasswordController.addTextField()
        reenterPasswordController.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: {
                (paramAction:UIAlertAction!) in
                if let textFieldArray = reenterPasswordController.textFields {
                    let textFields = textFieldArray as [UITextField]
                    let enteredText = textFields[0].text
                    self.reauthenticateUser(password: enteredText!)
                }
        }))
        present(reenterPasswordController, animated: true, completion: nil)
    }
    
    func reauthenticateUser(password: String) {
        let user = Auth.auth().currentUser!
        let credential = EmailAuthProvider.credential(
            withEmail: user.email!,
            password: password
        );

        user.reauthenticate(with: credential, completion: {(authResult, error) in
            if let err = error {
                print(err.localizedDescription)
                let reauthStateController = UIAlertController(
                    title: "Error",
                    message: "Password is incorrect",
                    preferredStyle: .alert)
                reauthStateController.addAction(UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: nil))
                self.present(reauthStateController, animated: true, completion: nil)
            } else {
                self.updatePasswordInAuth()
            }
        })
    }
    
    func updatePasswordInAuth() {
        let user = Auth.auth().currentUser!
        user.updatePassword(to: passwordTextField.text!, completion: { (error) in
            if let err = error {
                print(err.localizedDescription)
                let controller = UIAlertController(
                    title: "Error",
                    message: "Failed to update password",
                    preferredStyle: .alert)
                controller.addAction(UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: nil))
                self.present(controller, animated: true, completion: nil)
            } else {
                let controller = UIAlertController(
                    title: "Success!",
                    message: "Password was updated",
                    preferredStyle: .alert)
                controller.addAction(UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: nil))
                self.present(controller, animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func signOut(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            self.performSegue(withIdentifier: "signOutToLoginSegue", sender: self)
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
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
