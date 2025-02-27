//
//  LoginViewController.swift
//  connectionsRegistration
//
//  Created by Venkat Dikonda on 4/08/20.
//  Copyright © 2020 Venkat Dikonda. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController {
    
    var currUserUID : String?
    var editProfileSegue = "successfulLoginSegue"

    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
    }

    @IBOutlet weak var emailAddress: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var errorMsg: UILabel!
    
    @IBAction func loginPressed(_ sender: Any) {
        
        if(!emailAddress.text!.isEmpty && !password.text!.isEmpty){
            
            guard let email = emailAddress.text, !email.isEmpty else{
                    errorMsg.text = "Email is empty"
                    return
            }
            guard let password = password.text, !password.isEmpty else{
                    errorMsg.text = "Password is empty"
                    return
            }
            
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                    if error == nil{
                        self.currUserUID = Auth.auth().currentUser?.uid
                        print(self.currUserUID)
                    }
                    else{
                        print(error)
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
    
}

