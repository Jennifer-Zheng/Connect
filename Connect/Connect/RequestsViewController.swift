//
//  RequestsViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/9/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class RequestsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profilePic: UIButton!
    
    // Custom cell identifiers.
    let pendingConnectionCellIdentifier = "PendingConnectionCell"
    let pendingRelationshipCellIdentifier = "PendingRelationshipCell"
    let mutualConnectionCellIdentifier = "MutualConnectionCell"
    
    let queue = DispatchQueue.global()
    let dispatchGroup = DispatchGroup()
    
    let maxMutualsToDisplay = 4
    
    var pendingRelations: Array<Dictionary<String, Any>> = []
    var pendingConnections: Array<Dictionary<String, Any>> = []
    var connections: Array<Dictionary<String, Any>> = []
    var uid = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        let nib = UINib.init(nibName: "MutualConnectionTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: mutualConnectionCellIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        uid = Auth.auth().currentUser!.uid
        // First load the user.
        loadUser()
        dispatchGroup.notify(queue: queue) {
            // Then load the profiles of the senders of each request.
            self.loadPendingRelations()
            self.loadPendingConnections()
            self.dispatchGroup.notify(queue: self.queue) {
                // Then load the profiles of each mutual connection.
                self.loadMutuals()
                self.dispatchGroup.notify(queue: DispatchQueue.main) {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // Load needed information from the user.
    func loadUser() {
        dispatchGroup.enter()
        Firestore.firestore().collection("users").document(uid)
            .getDocument { document, error in
                guard let document = document, document.exists else {
                    print("Error fetching document: \(error!)")
                    self.dispatchGroup.leave()
                    return
                }
                self.connections = (document.get("connections") as? Array<Dictionary<String, String>>)!
                self.pendingRelations = (document.get("pendingRelations") as? Array<Dictionary<String, String>>)!
                self.pendingConnections = (document.get("pendingConnections") as? Array<Dictionary<String, String>>)!
                self.dispatchGroup.leave()
        }
        // Load user's profile picture
        let reference = Storage.storage().reference().child("profile_pics").child(self.uid + ".png")
        reference.getData(maxSize: 1024 * 1024 * 1024) { data, error in
          if let error = error {
            print(error.localizedDescription)
          } else {
            self.profilePic.setImage(UIImage(data: data!), for: .normal)
          }
        }
    }
    
    // Load the profiles of each relation request sender.
    func loadPendingRelations() {
        dispatchGroup.enter()
        if (self.pendingRelations.count > 0) {
            var loadedImages = 0
            for i in 0...(self.pendingRelations.count - 1) {
                let otherId = self.pendingRelations[i]["user"]!
                Firestore.firestore().collection("users").document(otherId as! String)
                    .getDocument { document, error in
                        guard let document = document, document.exists else {
                            print("Error fetching document: \(error!)")
                            return
                        }
                        self.pendingRelations[i]["name"] = document.get("name") as? String
                        self.pendingRelations[i]["dismissed"] = false
                }
                // Load in profile picture.
                let reference = Storage.storage().reference().child("profile_pics").child(otherId as! String + ".png")
                reference.getData(maxSize: 1024 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        self.pendingRelations[i]["image"] = UIImage(data: data!)!
                    }
                    loadedImages += 1
                    // Only mark done once all images have loaded.
                    if (loadedImages == self.pendingRelations.count){
                        self.dispatchGroup.leave()
                    }
                }
            }
        }
    }
    
    // Load the profiles of each connection request sender.
    func loadPendingConnections() {
        dispatchGroup.enter()
        if (self.pendingConnections.count > 0) {
            var loadedImages = 0
            for i in 0...(self.pendingConnections.count - 1) {
                let otherId = self.pendingConnections[i]["user"]!
                Firestore.firestore().collection("users").document(otherId as! String)
                    .getDocument { document, error in
                        guard let document = document, document.exists else {
                            print("Error fetching document: \(error!)")
                            return
                        }
                        self.pendingConnections[i]["name"] = document.get("name") as? String
                        self.pendingConnections[i]["connections"] = (document.get("connections") as? Array<Dictionary<String, String>>)!
                        self.pendingConnections[i]["dismissed"] = false
                        self.pendingConnections[i]["expanded"] = false
                        self.pendingConnections[i]["mutuals"] = []
                }
                // Load in profile picture.
                let reference = Storage.storage().reference().child("profile_pics").child(otherId as! String + ".png")
                reference.getData(maxSize: 1024 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        self.pendingConnections[i]["image"] = UIImage(data: data!)!
                    }
                    loadedImages += 1
                    // Only mark done once all images have loaded.
                    if (loadedImages == self.pendingConnections.count){
                        self.dispatchGroup.leave()
                    }
                }
            }
        }
    }
    
    // Load the profiles for each mutual connection.
    func loadMutuals() {
        var set = Set<String>()
        for connection in connections {
            set.insert(connection["user"] as! String)
        }
        if (pendingConnections.count > 0) {
            // Iterate through all of the sender's connections and see if there are matches with the users.
            for i in 0...(pendingConnections.count - 1) {
                var mutuals: Array<Dictionary<String, Any>> = []
                var mutualIds = Set<String>()
                for user in (pendingConnections[i]["connections"] as! Array<Dictionary<String, String>>) {
                    if (set.contains(user["user"]!)) {
                        mutuals.append([
                            "user": user["user"]!,
                            "relationship": user["relationship"]!
                        ])
                        mutualIds.insert(user["user"]!)
                    }
                }
                pendingConnections[i]["numMutuals"] = mutuals.count
                // If there are matches, load their profiles in to get their profiles.
                if (mutuals.count > 0) {
                    dispatchGroup.enter()
                    var loadedMutuals = 0
                    for i in 0...(mutuals.count - 1) {
                        Firestore.firestore().collection("users").document((mutuals[i]["user"] as? String)!)
                            .getDocument { document, error in
                                if let error = error {
                                    print("Error fetching document: \(error)")
                                } else {
                                    mutuals[i]["name"] = document!.get("name") as? String
                                    // Rank mutuals based on their # of mutuals to the sender of the connection request.
                                    var priority = 0
                                    let mutualConnections = document!.get("connections") as! Array<Dictionary<String, String>>
                                    for j in 0...(mutualConnections.count - 1) {
                                        if (mutualIds.contains(mutualConnections[j]["user"]!)) {
                                            priority += 1
                                        }
                                    }
                                    mutuals[i]["priority"] = priority
                                }
                                // Once all mutuals have loaded, we only need to load the profile pictures of those with the highest rank.
                                loadedMutuals += 1
                                if (loadedMutuals == mutuals.count) {
                                    mutuals.sort {
                                        (($0 as Dictionary<String, Any>)["priority"] as? Int)! < (($1 as Dictionary<String, Any>)["priority"] as? Int)!
                                    }
                                    mutuals = Array(mutuals.prefix(self.maxMutualsToDisplay))
                                    var loadedImages = 0
                                    for j in 0...(mutuals.count - 1) {
                                        // Load in profile picture.
                                        let reference = Storage.storage().reference().child("profile_pics").child(mutuals[j]["user"] as! String + ".png")
                                        reference.getData(maxSize: 1024 * 1024 * 1024) { data, error in
                                            if let error = error {
                                                print(error.localizedDescription)
                                            } else {
                                                mutuals[i]["image"] = UIImage(data: data!)!
                                            }
                                            loadedImages += 1
                                            // Only mark done once all images have loaded.
                                            if (loadedImages == mutuals.count) {
                                                self.pendingConnections[i]["mutuals"] = mutuals
                                                self.dispatchGroup.leave()
                                            }
                                        }
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
    
    // Number of rows needed for each request.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Pending Relationships
        if (section < pendingRelations.count) {
            if (pendingRelations[section]["dismissed"] as! Bool) {
                return 0
            }
            return 1
        // Pending Connections
        } else {
            let idx = section - pendingRelations.count
            if (pendingConnections[idx]["dismissed"] as! Bool) {
                return 0
            }
            if (pendingConnections[idx]["expanded"] as! Bool) {
                return min(maxMutualsToDisplay + 1, pendingConnections[idx]["numMutuals"] as! Int + 1)
            }
            return 1
        }
    }
    
    // Number of requests.
    func numberOfSections(in tableView: UITableView) -> Int {
        return pendingRelations.count + pendingConnections.count
    }
    
    // Height for each cell. Requests are 150, mutual connections are 50.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == 0) {
            return 150
        }
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Request cells.
        if (indexPath.row == 0) {
            // Relationship Request
            if (indexPath.section < pendingRelations.count) {
                // Relationship request.
                let cell = tableView.dequeueReusableCell(withIdentifier: pendingRelationshipCellIdentifier) as! PendingRelationshipTableViewCell
                
                // Add in user info.
                cell.otherName?.text = (pendingRelations[indexPath.row]["name"] as! String)
                cell.otherRelation?.setTitle((pendingRelations[indexPath.row]["relationship"] as! String), for: .normal)
                cell.otherRelation.backgroundColor = Constants.getRelationColor(pendingRelations[indexPath.row]["relationship"] as! String)
                let spacing: CGFloat = 8.0
                cell.otherRelation.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
                cell.otherProfile?.image = (pendingRelations[indexPath.row]["image"] as! UIImage)
                
                // Add functions to buttons. They need to be in this file since they modify the table.
                cell.confirmButton?.tag = indexPath.section
                cell.declineButton?.tag = indexPath.section
                cell.confirmButton?.addTarget(self, action: #selector(onConfirmRequestPress(sender:)), for: .touchUpInside)
                cell.declineButton?.addTarget(self, action: #selector(onDeclineRequestPress(sender:)), for: .touchUpInside)
                
                return cell
            }
            // Connection Request
            let idx = indexPath.section - pendingRelations.count
            let cell = tableView.dequeueReusableCell(withIdentifier: pendingConnectionCellIdentifier) as! PendingConnectionTableViewCell
            
            cell.otherName?.text = (pendingConnections[idx]["name"] as? String)!
            cell.otherProfile?.image = (pendingConnections[indexPath.row]["image"] as! UIImage)
            let numMutuals = pendingConnections[idx]["numMutuals"] as! Int
            cell.otherNumberOfMutuals?.text = "\(numMutuals) Mutual Connection"
            if (numMutuals != 1) {
                cell.otherNumberOfMutuals?.text! += "s"
            }
                
            // Add functions to buttons. They need to be in this file since they modify the table.
            cell.chevron?.tag = indexPath.section
            cell.confirmButton?.tag = indexPath.section
            cell.declineButton?.tag = indexPath.section
            cell.chevron?.addTarget(self, action: #selector(onChevronPress(sender:)), for: .touchUpInside)
            cell.confirmButton?.addTarget(self, action: #selector(onConfirmRequestPress(sender:)), for: .touchUpInside)
            cell.declineButton?.addTarget(self, action: #selector(onDeclineRequestPress(sender:)), for: .touchUpInside)
                
            // Chevron visibility.
            if (numMutuals == 0) {
                cell.chevron?.isHidden = true
            } else {
                cell.chevron?.isHidden = false
            }
            if (pendingConnections[idx]["expanded"] as! Bool) {
                cell.chevron?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            } else {
                cell.chevron?.transform = CGAffineTransform.identity
            }
                
            return cell
        }
        // Mutual connection cell.
        let cell = tableView.dequeueReusableCell(withIdentifier: mutualConnectionCellIdentifier) as! MutualConnectionTableViewCell
        let idx = indexPath.section - pendingRelations.count
        let entry = pendingConnections[idx]["mutuals"] as! Array<Dictionary<String, Any>>
        cell.mutualName?.text = (entry[indexPath.row - 1]["name"] as? String)!
        cell.mutualRelation?.setTitle((entry[indexPath.row - 1]["relationship"] as? String)!, for: .normal)
        cell.mutualRelation.backgroundColor = Constants.getRelationColor(entry[indexPath.row - 1]["relationship"] as! String)
        let spacing: CGFloat = 8.0
        cell.mutualRelation.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
        cell.mutualProfile?.image = (entry[indexPath.row - 1]["image"] as! UIImage)
        return cell
    }
    
    // Mark the section as expanded/collapsed and refresh it.
    @objc func onChevronPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        let idx = sender.tag - pendingRelations.count
        pendingConnections[idx]["expanded"] = !(pendingConnections[idx]["expanded"] as? Bool)!
        tableView.reloadSections(sections, with: .automatic)
    }
    
    // Update the database and hide the section.
    @objc func onConfirmRequestPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        // api call here.
        if (sender.tag < pendingRelations.count) {
            pendingRelations[sender.tag]["dismissed"] = true
        } else {
            pendingConnections[sender.tag - pendingRelations.count]["dismissed"] = true
        }
        tableView.reloadSections(sections, with: .automatic)
    }
    
    // Hide the section.
    @objc func onDeclineRequestPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        // api call here
        if (sender.tag < pendingRelations.count) {
            pendingRelations[sender.tag]["dismissed"] = true
        } else {
            pendingConnections[sender.tag - pendingRelations.count]["dismissed"] = true
        }
        tableView.reloadSections(sections, with: .automatic)
    }
    
    @IBAction func onBackButtonPress(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
}
