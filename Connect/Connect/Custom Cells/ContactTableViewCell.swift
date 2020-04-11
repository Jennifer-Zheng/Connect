//
//  ContactTableViewCell.swift
//  Connect
//
//  Created by Evan Weiss on 4/10/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class ContactTableViewCell: UITableViewCell {

    @IBOutlet weak var otherName: UILabel!
    @IBOutlet weak var otherProfile: UIImageView!
    @IBOutlet weak var otherNumberOfMutuals: UILabel!
    @IBOutlet weak var chevron: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addButton.layer.cornerRadius = 15
    }
}
