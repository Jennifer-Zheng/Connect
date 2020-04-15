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
    
    var relationships : [(String, UIColor)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        relationshipsTableView.dataSource = self
        searchBar.delegate = self
        relationships = Constants.allRelationships
        
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
        cell.relationship.setTitle(relationships[indexPath.row].0, for: .normal)
        cell.relationship.backgroundColor = relationships[indexPath.row].1
        let spacing: CGFloat = 8.0
        cell.relationship.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
        cell.viewController = self
        print("\(cell.relationship.frame.size)")
        return cell
    }
}

extension RelationshipsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        relationships = searchText.isEmpty ? Constants.allRelationships : Constants.allRelationships.filter { (item: (String, UIColor)) -> Bool in
            // If dataItem matches the searchText, return true to include it
            return item.0.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        }
        relationshipsTableView.reloadData()
        print(searchText)
    }
}
