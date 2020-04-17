//
//  ViewController.swift
//  Connect
//
//  Created by Nikhil Pandeti on 3/13/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            FirebaseManager.manager = FirebaseManager()
            FirebaseManager.manager.loadSelf() {
                DispatchQueue.global().async {
                    DispatchQueue.main.sync {
                        self.performSegue(withIdentifier: "tabsSegue", sender: self)
                    }
                }
            }
        } else {
            self.performSegue(withIdentifier: "loginSegue", sender: self)
        }
    }

}
