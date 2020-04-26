//
//  NearbyViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/15/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseStorage

class NearbyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var profilePic: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noNearbyConnectionsLabel: UILabel!
    
    // Custom cell identifiers.
    let nearbyConnectionCellIdentifier = "NearbyCell"
    let mutualConnectionCellIdentifier = "MutualConnectionCell"
    
    let permissionsMessage = "Please enable Location permissions in your device's settings to connect with nearby users."
    let noNearbyMessage = "No nearby connections were found at this time."
    let maxMutualsToDisplay = 4
    
    var document: Dictionary<String, Any> = [:]
    var nearbyConnections: Array<Dictionary<String, Any>?> = []
    var numDismissedCells = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        let nib = UINib.init(nibName: "MutualConnectionTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: mutualConnectionCellIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        profilePic.setImage(FirebaseManager.manager.getProfilePic(), for: .normal)
        if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse) {
            let userUID = FirebaseManager.manager.getUID()
            document = FirebaseManager.manager.getDocument()
            numDismissedCells = 0
            noNearbyConnectionsLabel?.text = noNearbyMessage
            // First load nearby users.
            FirebaseManager.manager.loadNearbyUsers() { results, errors in
                // Then look for mutual connections.
                FirebaseManager.manager.loadBatchRankedMutualConnections(user: self.document, otherUsers: results, limit: self.maxMutualsToDisplay) { resultsWithMutuals, errors in
                    self.nearbyConnections = resultsWithMutuals
                    // If any contacts were found, setup booleans such as if a request was already sent.
                    if (self.nearbyConnections.count > 0) {
                        for i in 0...(self.nearbyConnections.count - 1) {
                            self.nearbyConnections[i]!["sentRequest"] = false
                            self.nearbyConnections[i]!["expanded"] = false
                            self.nearbyConnections[i]!["pending"] = false
                            self.nearbyConnections[i]!["dismissed"] = false
                            for connectionRequest in self.nearbyConnections[i]!["sentConnections"] as! Array<Dictionary<String, String>> {
                                if (connectionRequest["user"] == userUID) {
                                    self.nearbyConnections[i]!["sentRequest"] = true
                                }
                            }
                            for connectionRequest in self.nearbyConnections[i]!["pendingConnections"] as! Array<Dictionary<String, String>> {
                                if (connectionRequest["user"] == userUID) {
                                    self.nearbyConnections[i]!["pending"] = true
                                }
                            }
                            for connectionRequest in self.nearbyConnections[i]!["connections"] as! Array<Dictionary<String, String>> {
                                if (connectionRequest["user"] == userUID) {
                                    self.numDismissedCells += 1
                                    self.nearbyConnections[i]!["dismissed"] = true
                                }
                            }
                        }
                    }
                    DispatchQueue.main.sync {
                        self.tableView.reloadData()
                    }
                }
            }
        } else {
            noNearbyConnectionsLabel?.text = permissionsMessage
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination is ProfileViewController) {
            let indexPath = self.tableView.indexPathForSelectedRow!
            let profileVC = segue.destination as! ProfileViewController
            profileVC.user = nearbyConnections[indexPath.section]!["id"] as! String
        }
    }
    
    // Number of nearby connections.
    func numberOfSections(in tableView: UITableView) -> Int {
        noNearbyConnectionsLabel.isHidden = !(numDismissedCells == nearbyConnections.count)
        return nearbyConnections.count
    }
    
    // Height for each cell.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Height for nearby connections cell is 150.
        if (indexPath.row == 0) {
            return 150
        }
        // Height for mutual connections cell is 50.
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (nearbyConnections[section]!["dismissed"] as! Bool) {
            return 0
        // If the section is not expanded, only 1 row is needed.
        } else if (nearbyConnections[section]!["expanded"] as! Bool == false) {
            return 1
        }
        return min(maxMutualsToDisplay, (nearbyConnections[section]!["mutuals"] as! Array<Any?>).count) + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Request cells.
        if (indexPath.row == 0) {
            // Contact cell.
            let cell = tableView.dequeueReusableCell(withIdentifier: nearbyConnectionCellIdentifier) as! NearbyTableViewCell
            // Add in user info.
            cell.otherName?.text = (nearbyConnections[indexPath.section]!["name"] as! String)
            cell.otherProfile?.image = (nearbyConnections[indexPath.section]!["image"] as! UIImage)
            cell.otherDistance?.text = (nearbyConnections[indexPath.section]!["distance"] as! String) + " Miles Away"
            let numMutuals = (nearbyConnections[indexPath.section]!["mutuals"] as! Array<Any?>).count
            cell.otherNumberOfMutuals?.text = "\(numMutuals) Mutual Connection"
            if (numMutuals != 1) {
                cell.otherNumberOfMutuals?.text! += "s"
            }
                
            // Add functions to buttons. They need to be in this file since they modify the table.
            cell.chevron?.tag = indexPath.section
            cell.chevron?.addTarget(self, action: #selector(onChevronPress(sender:)), for: .touchUpInside)
            cell.addButton?.removeTarget(nil, action: nil, for: .allEvents)
            if (nearbyConnections[indexPath.section]!["sentRequest"] as! Bool) {
                cell.addButton?.setTitle("Accept", for: .normal)
                cell.addButton?.backgroundColor = UIColor.systemBlue
                cell.addButton?.tag = indexPath.section
                cell.addButton?.addTarget(self, action: #selector(onAcceptPress(sender:)), for: .touchUpInside)
            } else if (nearbyConnections[indexPath.section]!["pending"] as! Bool) {
                cell.addButton?.setTitle("Pending", for: .normal)
                cell.addButton?.backgroundColor = UIColor.systemGreen
                cell.addButton?.tag = indexPath.section
                cell.addButton?.addTarget(self, action: #selector(onPendingPress(sender:)), for: .touchUpInside)
            } else {
                cell.addButton?.setTitle("Add", for: .normal)
                cell.addButton?.backgroundColor = UIColor.systemBlue
                cell.addButton?.tag = indexPath.section
                cell.addButton?.addTarget(self, action: #selector(onAddPress(sender:)), for: .touchUpInside)
            }
                
            // Chevron visibility.
            if (numMutuals == 0) {
                cell.chevron?.isHidden = true
            } else {
                cell.chevron?.isHidden = false
            }
            if (nearbyConnections[indexPath.section]!["expanded"] as! Bool) {
                cell.chevron?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            } else {
                cell.chevron?.transform = CGAffineTransform.identity
            }
            return cell
        }
        
        // Mutual connection cell.
        let cell = tableView.dequeueReusableCell(withIdentifier: mutualConnectionCellIdentifier) as! MutualConnectionTableViewCell
        let mutuals = nearbyConnections[indexPath.section]!["mutuals"] as! Array<Dictionary<String, Any>?>
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
        nearbyConnections[sender.tag]!["expanded"] = !(nearbyConnections[sender.tag]!["expanded"] as? Bool)!
        tableView.reloadSections(sections, with: .automatic)
    }
    
    @objc func onAddPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        FirebaseManager.manager.sendConnectionRequest(otherUID: nearbyConnections[sender.tag]!["id"] as! String)
        nearbyConnections[sender.tag]!["pending"] = true
        tableView.reloadSections(sections, with: .automatic)
    }
    
    @objc func onPendingPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        FirebaseManager.manager.cancelConnectionRequest(otherUID: nearbyConnections[sender.tag]!["id"] as! String)
        nearbyConnections[sender.tag]!["pending"] = false
        tableView.reloadSections(sections, with: .automatic)
    }
    
    @objc func onAcceptPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        FirebaseManager.manager.confirmPendingConnection(otherUID: nearbyConnections[sender.tag]!["id"] as! String)
        numDismissedCells += 1
        if (numDismissedCells == nearbyConnections.count) {
            noNearbyConnectionsLabel.isHidden = false
        }
        nearbyConnections[sender.tag]!["dismissed"] = true
        tableView.reloadSections(sections, with: .automatic)
    }

}
