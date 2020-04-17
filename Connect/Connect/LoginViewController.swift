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

    @IBOutlet weak var emailAddress: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var errorMsg: UILabel!
    
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
    
    @IBAction func loginPressed(_ sender: Any) {
        
        if(!emailAddress.text!.isEmpty && !password.text!.isEmpty) {
            
            guard let email = emailAddress.text, !email.isEmpty else {
                    errorMsg.text = "Email is empty"
                    return
            }
            guard let password = password.text, !password.isEmpty else {
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
                if (self.currUserUID == "gCWpsbrZLrQjBa4E0vzw258TdUK2") {
                    self.resetTestUsers()
                }
                self.transitionToHome(self.currUserUID)
            }
        }
        else {
            errorMsg.text = "Please fill out all fields"
        }
    }
    
    func transitionToHome(_ uid : String?) {
        sleep(1)
        let storyboard = UIStoryboard(name: "Main", bundle:nil)
        let tabBarViewController = storyboard.instantiateViewController(withIdentifier: "Main") as? ViewController
        self.view.window?.rootViewController = tabBarViewController
        self.view.window?.makeKeyAndVisible()

    }
    
    func resetTestUsers() {
        Firestore.firestore().collection("users").document("gCWpsbrZLrQjBa4E0vzw258TdUK2").updateData([
            "connections": [
                ["user": "D7lCTYj3JTOFjxZlFfKgQHri2ew1",
                 "relationship": "Lab Partner"],
                ["user": "km5NceyWM5YNDQSJNYGp6hvzRYD2",
                 "relationship": "Cousin"]],
            "pendingConnections": [
                ["user": "DdKGtN05jAUyDmBS8ARL12xslK73"]],
            "pendingRelations": [
                ["user": "D7lCTYj3JTOFjxZlFfKgQHri2ew1",
                 "relationship": "Friend"]],
            "sentConnections": [],
            "sentRelations": []
        ])
        Firestore.firestore().collection("users").document("D7lCTYj3JTOFjxZlFfKgQHri2ew1").updateData([
            "connections": [
                ["user": "gCWpsbrZLrQjBa4E0vzw258TdUK2",
                 "relationship": "Lab Partner"],
                ["user": "DdKGtN05jAUyDmBS8ARL12xslK73",
                 "relationship": "Previous Roommate"]],
            "pendingConnections": [],
            "pendingRelations": [],
            "sentConnections": [],
            "sentRelations": [
                ["user": "gCWpsbrZLrQjBa4E0vzw258TdUK2",
                 "relationship": "Friend"]]
        ])
        Firestore.firestore().collection("users").document("DdKGtN05jAUyDmBS8ARL12xslK73").updateData([
            "connections": [
                ["user": "D7lCTYj3JTOFjxZlFfKgQHri2ew1",
                "relationship": "Previous Roommate"]],
            "pendingConnections": [],
            "pendingRelations": [],
            "sentConnections": [
                ["user": "gCWpsbrZLrQjBa4E0vzw258TdUK2"]],
            "sentRelations": []
        ])
        Firestore.firestore().collection("users").document("km5NceyWM5YNDQSJNYGp6hvzRYD2").updateData([
            "connections": [
                ["user": "gCWpsbrZLrQjBa4E0vzw258TdUK2",
                "relationship": "Cousin"]],
            "pendingConnections": [],
            "pendingRelations": [],
            "sentConnections": [],
            "sentRelations": []
        ])
        Firestore.firestore().collection("users").document("UfnCWDLeKcd0dU7VygVbbfBB4su1").updateData([
            "connections": [],
            "pendingConnections": [],
            "pendingRelations": [],
            "sentConnections": [],
            "sentRelations": []
        ])
    }
    
    // code to dismiss keyboard when user clicks on background

    func textFieldShouldReturn(textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

