//
//  ConnectionTableViewCell.swift
//  Connect
//
//  Created by Evan Weiss on 4/13/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class ConnectionTableViewCell: UITableViewCell {

    @IBOutlet weak var otherProfile: UIImageView!
    @IBOutlet weak var otherName: UILabel!
    @IBOutlet weak var relation: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        relation.layer.cornerRadius = 15
    }

}
