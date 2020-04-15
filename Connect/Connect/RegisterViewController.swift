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
    
    @IBAction func signUpPressed(_ sender: Any) {
        let db = Firestore.firestore()
       
        //let num = Int(phoneNumber.text!)
        if(!emailAddress.text!.isEmpty && !password.text!.isEmpty && !confirmPassword.text!.isEmpty){
            if(password.text != confirmPassword.text){
                errorMsg.text = "Passwords do not match"
            }
            /*else if(phoneNumber.text?.count != 10 || num == nil){
                error.text = "Invalid phone number"
            }*/
            else{
                guard let email = emailAddress.text, !email.isEmpty else{
                        errorMsg.text = "Email is empty"
                        return
                }
                guard let password = password.text, !password.isEmpty else{
                        errorMsg.text = "Password is empty"
                        return
                }
                
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    guard let user = authResult?.user, error == nil else {
                        print(error!.localizedDescription)
                        self.errorMsg.text = error!.localizedDescription
                        return
                    }

                    db.collection("users").document(Auth.auth().currentUser!.uid).setData([
                        "email": email,
                        "password": password,
                        "phoneNumber": Int(),
                        "connections": [Any](),
                        "pendingConnections": [Any](),
                        "pendingRelations": [Any](),
                        "sentConnections": [Any](),
                        "messages": [Any]()
                    ]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                            self.errorMsg.text = err.localizedDescription
                            return
                        } else {
                            print("Document successfully written!")
                            self.transitionToEditProfile()
                        }
                    }
                }
            }
        }
        else{
            errorMsg.text = "Please fill out all fields"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == editProfileSegue{
            
        }
    }
    
    func transitionToEditProfile(){
        let storyboard = UIStoryboard(name: "EditProfile", bundle:nil)
        
        let editViewController = storyboard.instantiateViewController(withIdentifier: "EditProfile") as? EditProfileViewController
        
        view.window?.rootViewController = editViewController
        view.window?.makeKeyAndVisible()
    }
    
}
