//
//  NearbyTableViewCell.swift
//  Connect
//
//  Created by Evan Weiss on 4/25/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class NearbyTableViewCell: UITableViewCell {

    @IBOutlet weak var otherName: UILabel!
    @IBOutlet weak var otherProfile: UIImageView!
    @IBOutlet weak var otherNumberOfMutuals: UILabel!
    @IBOutlet weak var otherDistance: UILabel!
    @IBOutlet weak var chevron: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addButton.layer.cornerRadius = 15
    }

}
