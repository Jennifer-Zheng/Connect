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
    
    // code to dismiss keyboard when user clicks on background

    func textFieldShouldReturn(textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
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
                guard let _ = authResult?.user, error == nil else {
                    print(error!.localizedDescription)
                    self.errorMsg.text = error!.localizedDescription
                    return
                }
                self.currUserUID = Auth.auth().currentUser?.uid
                self.transitionToHome(self.currUserUID)
            }
        }
        else{
            errorMsg.text = "Please fill out all fields"
        }
    }
    
    func transitionToHome(_ uid : String?){
        do {
            sleep(1)
        }
        let storyboard = UIStoryboard(name: "Connections", bundle:nil)
        
        let connectionsViewController = storyboard.instantiateViewController(withIdentifier: "Connections") as? ConnectionsViewController
        
        if uid != nil {
            connectionsViewController?.uid = uid!
        }
        
        view.window?.rootViewController = connectionsViewController
        view.window?.makeKeyAndVisible()
    }
    
}

