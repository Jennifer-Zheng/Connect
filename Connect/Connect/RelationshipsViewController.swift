//
//  RelationshipsViewController.swift
//  Connect
//
//  Created by Nikhil Pandeti on 4/14/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

class RelationshipsViewController: UIViewController {
    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var relationshipsTableView: UITableView!
    
    var relationshipTableViewCell = "RelationshipTableViewCell"
    
    var relationships : [(String, UIColor)] = [("Friend",#colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1))]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        relationshipsTableView.dataSource = self
    }
    
    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension RelationshipsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return relationships.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = relationshipsTableView.dequeueReusableCell(withIdentifier: relationshipTableViewCell) as! RelationshipTableViewCell
        cell.setText(text: relationships[indexPath.row].0)
        cell.relationship.backgroundColor = relationships[indexPath.row].1
        return cell
    }
    
    
}
