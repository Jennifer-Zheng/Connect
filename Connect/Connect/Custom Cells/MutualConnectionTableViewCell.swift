//
//  MutualConnectionTableViewCell.swift
//  Connect
//
//  Created by Evan Weiss on 4/10/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class MutualConnectionTableViewCell: UITableViewCell {

    @IBOutlet weak var mutualProfile: UIImageView!
    @IBOutlet weak var mutualName: UILabel!
    @IBOutlet weak var mutualRelation: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mutualRelation.layer.cornerRadius = 15
    }
    
    func populateWithUser(uid : String?) {
        if uid == nil {
            return
        }
        
        let reference = Storage.storage().reference().child("profile_pics").child("\(uid!).png")
        // Download in memory with a maximum allowed size = 5 MB
        reference.getData(maxSize: 5 * 1024 * 1024) { data, error in
        if (error != nil) {
            
          } else {
            self.mutualProfile.image = UIImage(data: data!)
          }
        }
        
        let db = Firestore.firestore()
        db.collection("users").document("\(uid!)")
        .addSnapshotListener { documentSnapshot, error in
          guard let document = documentSnapshot else {
            print("Error fetching document: \(error!)")
            return
          }
            self.mutualName.text = document.get("name") as? String
        }
    }

}
