//
//  ConversationViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/15/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class ConversationViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    
    var otherName = ""
    var otherUID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        nameLabel.text = otherName
    }

    @IBAction func onBackButtonPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
