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
    @IBOutlet weak var emptyMessageLabel: UILabel!
    
    // Custom cell identifiers.
    let pendingConnectionCellIdentifier = "PendingConnectionCell"
    let pendingRelationshipCellIdentifier = "PendingRelationshipCell"
    let mutualConnectionCellIdentifier = "MutualConnectionCell"
    
    let profileSegueIdentifier = "ProfileSegue"
    
    let maxMutualsToDisplay = 4
    
    // List of user's pending relationship requests represented as objects with the keys "user" and "relationship".
    var pendingRelations: Array<Dictionary<String, Any>?> = []
    // List of user's pending connection requests represented as objects with the key "user".
    var pendingConnections: Array<Dictionary<String, Any>?> = []
    var numDismissedCells = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        let nib = UINib.init(nibName: "MutualConnectionTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: mutualConnectionCellIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let dispatchGroup = DispatchGroup()
        emptyMessageLabel.isHidden = false
        numDismissedCells = 0
        // Load User.
        profilePic.setImage(FirebaseManager.manager.getProfilePic(), for: .normal)
        let document = FirebaseManager.manager.getDocument()
        var pendingRelations = document["pendingRelations"] as! Array<Dictionary<String, Any>>
        var pendingConnections = document["pendingConnections"] as! Array<Dictionary<String, Any>>
        
        // Load Pending Relations.
        if (pendingRelations.count > 0) {
            dispatchGroup.enter()
            FirebaseManager.manager.loadBatchUsers(userConnections: pendingRelations) { results, errors in
                for i in 0...(pendingRelations.count - 1) {
                    pendingRelations[i]["dismissed"] = false
                    pendingRelations[i]["image"] = results[i]!["image"]
                    pendingRelations[i]["name"] = results[i]!["name"]
                }
                self.pendingRelations = pendingRelations
                dispatchGroup.leave()
            }
        }
        
        // Load Pending Connections.
        if (pendingConnections.count > 0) {
            dispatchGroup.enter()
            FirebaseManager.manager.loadBatchUsers(userConnections: pendingConnections) { results, errors in
                FirebaseManager.manager.loadBatchRankedMutualConnections(user: document, otherUsers: results, limit: self.maxMutualsToDisplay) { resultsWithMutuals, errors in
                    if (pendingConnections.count > 0) {
                        for i in 0...(pendingConnections.count - 1) {
                            pendingConnections[i]["dismissed"] = false
                            pendingConnections[i]["expanded"] = false
                            pendingConnections[i]["image"] = resultsWithMutuals[i]!["image"]
                            pendingConnections[i]["name"] = resultsWithMutuals[i]!["name"]
                            pendingConnections[i]["mutuals"] = resultsWithMutuals[i]!["mutuals"]
                        }
                    }
                    self.pendingConnections = pendingConnections
                    dispatchGroup.leave()
                }
            }
        }
        
        if (pendingConnections.count == 0 && pendingConnections.count == 0) {
            self.pendingRelations = []
            self.pendingConnections = []
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.tableView.reloadData()
        }
    }
    
    // Segue to the profile screen when a request cell is clicked.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Don't segue for mutual cells.
        if (indexPath.row == 0) {
            performSegue(withIdentifier: profileSegueIdentifier, sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == profileSegueIdentifier) {
            let idx = self.tableView.indexPathForSelectedRow!.section
            let profileVC = segue.destination as! ProfileViewController
            if (idx < pendingRelations.count) {
                profileVC.user = pendingRelations[idx]!["user"] as! String
            } else {
                profileVC.user = pendingConnections[idx - pendingRelations.count]!["user"] as! String
            }
        }
    }
    
    // Number of rows needed for each request.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Pending Relationships
        if (section < pendingRelations.count) {
            if (pendingRelations[section]!["dismissed"] as! Bool) {
                return 0
            }
            return 1
        // Pending Connections
        } else {
            let idx = section - pendingRelations.count
            if (pendingConnections[idx]!["dismissed"] as! Bool) {
                return 0
            }
            if (pendingConnections[idx]!["expanded"] as! Bool) {
                return min(maxMutualsToDisplay, (pendingConnections[idx]!["mutuals"] as! Array<Any?>).count) + 1
            }
            return 1
        }
    }
    
    // Number of requests.
    func numberOfSections(in tableView: UITableView) -> Int {
        emptyMessageLabel.isHidden = !(numDismissedCells == pendingRelations.count + pendingConnections.count)
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
                cell.otherName?.text = (pendingRelations[indexPath.section]!["name"] as! String)
                cell.otherRelation?.setTitle((pendingRelations[indexPath.section]!["relationship"] as! String), for: .normal)
                cell.otherRelation.backgroundColor = Constants.getRelationColor(pendingRelations[indexPath.section]!["relationship"] as! String)
                let spacing: CGFloat = 8.0
                cell.otherRelation.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
                cell.otherProfile?.image = (pendingRelations[indexPath.section]!["image"] as! UIImage)
                
                // Add functions to buttons. They need to be in this file since they modify the table.
                cell.confirmButton?.tag = indexPath.section
                cell.declineButton?.tag = indexPath.section
                cell.confirmButton?.addTarget(self, action: #selector(onConfirmRelationship(sender:)), for: .touchUpInside)
                cell.declineButton?.addTarget(self, action: #selector(onDeclineRelationship(sender:)), for: .touchUpInside)
                
                return cell
            }
            // Connection Request
            let idx = indexPath.section - pendingRelations.count
            let cell = tableView.dequeueReusableCell(withIdentifier: pendingConnectionCellIdentifier) as! PendingConnectionTableViewCell
            
            cell.otherName?.text = (pendingConnections[idx]!["name"] as? String)!
            cell.otherProfile?.image = (pendingConnections[idx]!["image"] as! UIImage)
            let numMutuals = (pendingConnections[idx]!["mutuals"] as! Array<Any?>).count
            cell.otherNumberOfMutuals?.text = "\(numMutuals) Mutual Connection"
            if (numMutuals != 1) {
                cell.otherNumberOfMutuals?.text! += "s"
            }
                
            // Add functions to buttons. They need to be in this file since they modify the table.
            cell.chevron?.tag = indexPath.section
            cell.confirmButton?.tag = indexPath.section
            cell.declineButton?.tag = indexPath.section
            cell.chevron?.addTarget(self, action: #selector(onChevronPress(sender:)), for: .touchUpInside)
            cell.confirmButton?.addTarget(self, action: #selector(onConfirmConnection(sender:)), for: .touchUpInside)
            cell.declineButton?.addTarget(self, action: #selector(onDeclineConnection(sender:)), for: .touchUpInside)
                
            // Chevron visibility.
            if (numMutuals == 0) {
                cell.chevron?.isHidden = true
            } else {
                cell.chevron?.isHidden = false
            }
            if (pendingConnections[idx]!["expanded"] as! Bool) {
                cell.chevron?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            } else {
                cell.chevron?.transform = CGAffineTransform.identity
            }
                
            return cell
        }
        // Mutual connection cell.
        let cell = tableView.dequeueReusableCell(withIdentifier: mutualConnectionCellIdentifier) as! MutualConnectionTableViewCell
        let idx = indexPath.section - pendingRelations.count
        let mutuals = pendingConnections[idx]!["mutuals"] as! Array<Dictionary<String, Any>?>
        cell.mutualName?.text = (mutuals[indexPath.row - 1]!["name"] as? String)!
        cell.mutualRelation?.setTitle((mutuals[indexPath.row - 1]!["relationship"] as? String)!, for: .normal)
        cell.mutualRelation.backgroundColor = Constants.getRelationColor(mutuals[indexPath.row - 1]!["relationship"] as! String)
        let spacing: CGFloat = 8.0
        cell.mutualRelation.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
        cell.mutualProfile?.image = (mutuals[indexPath.row - 1]!["image"] as! UIImage)
        return cell
    }
    
    // Mark the section as expanded/collapsed and refresh it.
    @objc func onChevronPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        let idx = sender.tag - pendingRelations.count
        pendingConnections[idx]!["expanded"] = !(pendingConnections[idx]!["expanded"] as? Bool)!
        tableView.reloadSections(sections, with: .automatic)
    }
    
    // Update the database and hide the section.
    @objc func onConfirmRelationship(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        let otherUID = pendingRelations[sender.tag]!["user"] as! String
        let newRelationship = pendingRelations[sender.tag]!["relationship"] as! String
        FirebaseManager.manager.confirmPendingRelation(otherUID: otherUID, newRelationship: newRelationship)
        numDismissedCells += 1
        if (numDismissedCells == pendingRelations.count + pendingConnections.count) {
            emptyMessageLabel.isHidden = false
        }
        pendingRelations[sender.tag]!["dismissed"] = true
        tableView.reloadSections(sections, with: .automatic)
    }
    
    // Update the database and hide the section.
    @objc func onDeclineRelationship(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        let otherUID = pendingRelations[sender.tag]!["user"] as! String
        let newRelationship = pendingRelations[sender.tag]!["relationship"] as! String
        FirebaseManager.manager.declinePendingRelation(otherUID: otherUID, newRelationship: newRelationship)
        numDismissedCells += 1
        if (numDismissedCells == pendingRelations.count + pendingConnections.count) {
            emptyMessageLabel.isHidden = false
        }
        pendingRelations[sender.tag]!["dismissed"] = true
        tableView.reloadSections(sections, with: .automatic)
    }
    
    // Update the database and hide the section.
    @objc func onConfirmConnection(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        let idx = sender.tag - pendingRelations.count
        let otherUID = pendingConnections[idx]!["user"] as! String
        FirebaseManager.manager.confirmPendingConnection(otherUID: otherUID)
        numDismissedCells += 1
        if (numDismissedCells == pendingRelations.count + pendingConnections.count) {
            emptyMessageLabel.isHidden = false
        }
        pendingConnections[idx]!["dismissed"] = true
        tableView.reloadSections(sections, with: .automatic)
    }
    
    // Update the database and hide the section.
    @objc func onDeclineConnection(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        let idx = sender.tag - pendingRelations.count
        let otherUID = pendingConnections[idx]!["user"] as! String
        FirebaseManager.manager.declinePendingConnection(otherUID: otherUID)
        numDismissedCells += 1
        if (numDismissedCells == pendingRelations.count + pendingConnections.count) {
            emptyMessageLabel.isHidden = false
        }
        pendingConnections[idx]!["dismissed"] = true
        tableView.reloadSections(sections, with: .automatic)
    }
    
    @IBAction func onBackButtonPress(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
}
