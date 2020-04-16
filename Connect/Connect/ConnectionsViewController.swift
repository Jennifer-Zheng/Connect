//
//  ConnectionsViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/13/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class ConnectionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profilePic: UIButton!
    
    // Custom cell identifiers.
    let connectionCellIdentifier = "ConnectionCell"
    
    var connections: Array<Dictionary<String, Any>> = []
    var uid = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Firestore.firestore().clearPersistence(completion: nil)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        uid = Auth.auth().currentUser!.uid
        loadProfilePic()
        loadConnections()
    }
    
    func loadProfilePic() {
        let reference = Storage.storage().reference().child("profile_pics").child(uid + ".png")
        reference.getData(maxSize: 1024 * 1024 * 1024) { data, error in
          if let error = error {
            print(error.localizedDescription)
          } else {
            self.profilePic.setImage(UIImage(data: data!), for: .normal)
          }
        }
    }
    
    // Load the profiles of the user's connections.
    func loadConnections() {
        Firestore.firestore().collection("users").document(uid)
            .getDocument { document, error in
                guard let document = document, document.exists else {
                    print("Error fetching document: \(error!)")
                    return
                }
                self.connections = (document.get("connections") as? Array<Dictionary<String, String>>)!
                var loadedImages = 0
                // Load each connection for their names and profile pictures.
                if (self.connections.count > 0) {
                    for i in 0...(self.connections.count - 1) {
                        let otherId = self.connections[i]["user"]!
                        Firestore.firestore().collection("users").document(otherId as! String)
                            .getDocument { document, error in
                                guard let document = document, document.exists else {
                                    print("Error fetching document: \(error!)")
                                    return
                                }
                                self.connections[i]["name"] = document.get("name") as? String
                                // Load in profile picture.
                                let reference = Storage.storage().reference().child("profile_pics").child(otherId as! String + ".png")
                                reference.getData(maxSize: 1024 * 1024 * 1024) { data, error in
                                  if let error = error {
                                      print(error.localizedDescription)
                                  } else {
                                      self.connections[i]["image"] = UIImage(data: data!)!
                                  }
                                  loadedImages += 1
                                  // Only reload the table once all images have loaded.
                                  if (loadedImages == self.connections.count){
                                    self.tableView.reloadData()
                                  }
                                }
                        }
                    }
                }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.destination is ProfileViewController) {
            let indexPath = self.tableView.indexPathForSelectedRow!
            let profileVC = segue.destination as! ProfileViewController
            profileVC.user = self.connections[indexPath.row]["user"] as! String
        }
    }
    
    // Number of rows needed in the table.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connections.count
    }
    
    // Height for each cell.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: connectionCellIdentifier) as! ConnectionTableViewCell
        cell.otherName?.text = (connections[indexPath.row]["name"] as! String)
        cell.otherProfile?.image = (connections[indexPath.row]["image"] as! UIImage)
        cell.relation?.setTitle((connections[indexPath.row]["relationship"] as! String), for: .normal)
        cell.relation.backgroundColor = Constants.getRelationColor(connections[indexPath.row]["relationship"] as! String)
        let spacing: CGFloat = 8.0
        cell.relation.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
        return cell
    }

}
