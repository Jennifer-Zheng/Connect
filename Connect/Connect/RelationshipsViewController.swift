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
    
    var user = ""
    var currentRelation = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        relationshipsTableView.dataSource = self
        searchBar.delegate = self
        relationships = Constants.allRelationships
        showCurrentProfileInfo()
    }
    
    func showCurrentProfileInfo() {
        // Profile picture
        let reference = Storage.storage().reference().child("profile_pics").child("\(user).png")
        // Download in memory with a maximum allowed size = 5 MB
        reference.getData(maxSize: 5 * 1024 * 1024) { data, error in
        if (error != nil) {
            let controller = UIAlertController(
                title: "Warning",
                message: "Image is too large",
                preferredStyle: .alert)
            controller.addAction(UIAlertAction(
                title: "OK",
                style: .default,
                handler: nil))
            self.present(controller, animated: true, completion: nil)
          } else {
            self.profilePic.image = UIImage(data: data!)
          }
        }
        
        // Name and bio
        let db = Firestore.firestore()
        // TODO: replace user id with id generated by Firebase Auth
        db.collection("users").document("\(user)")
            .getDocument(completion: { documentSnapshot, error in
          guard let document = documentSnapshot else {
            print("Error fetching document: \(error!)")
            return
          }
            self.nameTextField.text = document.get("name") as? String;
            
        })
    }
    
    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // code to dismiss keyboard when user clicks on background

    func textFieldShouldReturn(textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
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
        cell.relationship.tag = indexPath.row
        cell.relationship.removeTarget(nil, action: nil, for: .allEvents)
        cell.relationship.addTarget(self, action: #selector(onRelationshipPress(sender:)), for: .touchUpInside)
        return cell
    }
    
    @objc func onRelationshipPress(sender: UIButton) {
        let type = relationships[sender.tag].0
        
        FirebaseManager.manager.sendRelationRequest(otherUID: self.user, newRelationship: type)
        self.dismiss(animated: true, completion: nil)
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
