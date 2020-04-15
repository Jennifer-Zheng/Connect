//
//  RelationshipTableViewCell.swift
//  Connect
//
//  Created by Nikhil Pandeti on 4/14/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import Foundation
import Firebase

class RelationshipTableViewCell: UITableViewCell {
    @IBOutlet weak var relationship: UIButton!
    var viewController : RelationshipsViewController?
    
    @IBAction func buttonTap(_ sender: Any) {
        if(viewController != nil) {
            viewController?.dismiss(animated: true, completion: nil)
        }
    }
}
