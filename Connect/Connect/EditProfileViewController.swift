//
//  EditProfileViewController.swift
//  Connect
//
//  Created by Jennifer on 4/9/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var bio: UITextField!
    @IBOutlet weak var numConnections: UITextField!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editButton.title = "Done"
        name.isEnabled = true
        bio.isEnabled = true
    
    }
    
    func showCurrentProfileInfo() {
        // TODO: once registration is finished, retrieve name, bio, numConnections, and profile pic from Firebase
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String,
                            sender: Any?) -> Bool {
        if identifier == "ConnectionsSegue" && editButton.title == "Edit" {
            return false
        }
        return true
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        if editButton.title == "Edit" {
            editButton.title = "Done"
            name.isEnabled = true
            bio.isEnabled = true
        } else {
            editButton.title = "Edit"
            name.isEnabled = false
            bio.isEnabled = false
        }
    }

}
