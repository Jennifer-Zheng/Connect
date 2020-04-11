//
//  PendingRelationshipTableViewCell.swift
//  Connect
//
//  Created by Evan Weiss on 4/10/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class PendingRelationshipTableViewCell: UITableViewCell {

    @IBOutlet weak var otherProfile: UIImageView!
    @IBOutlet weak var otherName: UILabel!
    @IBOutlet weak var otherRelation: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        confirmButton.layer.cornerRadius = 15
        declineButton.layer.cornerRadius = 15
        otherRelation.layer.cornerRadius = 15
    }
}
