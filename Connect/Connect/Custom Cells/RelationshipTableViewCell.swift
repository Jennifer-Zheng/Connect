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
    
    
    func setText(text: String) {
        //print("\(text.size(withAttributes: [NSAttributedString.Key.font: self]).width)")
        relationship.titleLabel?.text = text
        relationship.frame.size = CGSize(width: (relationship.titleLabel?.frame.size.width ?? 200) + 40, height: relationship.frame.height)
    }
}
