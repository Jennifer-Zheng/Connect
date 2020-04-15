//
//  NearbyViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/15/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class NearbyViewController: UIViewController {
    
    @IBOutlet weak var profilePic: UIButton!
    
    var uid = ""

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        uid = Auth.auth().currentUser!.uid
        loadUser()
    }
    
    // Load needed information from the user.
    func loadUser() {
        // Load user's profile picture
        let reference = Storage.storage().reference().child("profile_pics").child(uid + ".png")
        reference.getData(maxSize: 1024 * 1024 * 1024) { data, error in
          if let error = error {
            print(error.localizedDescription)
          } else {
            self.profilePic.setImage(UIImage(data: data!), for: .normal)
          }
        }
    }

}
