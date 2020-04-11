//
//  MutualConnectionTableViewCell.swift
//  Connect
//
//  Created by Evan Weiss on 4/10/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class MutualConnectionTableViewCell: UITableViewCell {

    @IBOutlet weak var mutualProfile: UIImageView!
    @IBOutlet weak var mutualName: UILabel!
    @IBOutlet weak var mutualRelation: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mutualRelation.layer.cornerRadius = 15
    }

}
