//
//  RequestsViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/9/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class RequestsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    // Custom cell identifiers.
    let pendingConnectionCellIdentifier = "PendingConnectionCell"
    let pendingRelationshipCellIdentifier = "PendingRelationshipCell"
    let mutualConnectionCellIdentifier = "MutualConnectionCell"
    
    // Dummy requests array.
    var requests = [
        ["user" : "a",
         "kind" : "connection"],
        ["user" : "b",
         "kind" : "connection"],
        ["user" : "c",
        "kind" : "relationship",
        "relationship" : "Friend"],
        ["user" : "d",
         "kind" : "connection"],
        ["user" : "e",
         "kind" : "connection"]
    ]
    
    // Dummy users array.
    var users = [
        "a" : [
            "numMutuals" : 0
        ],
        "b" : [
            "numMutuals" : 1
        ],
        "c" : [
            "numMutuals" : 5
        ],
        "d" : [
            "numMutuals" : 3
        ],
        "e" : [
            "numMutuals" : 157
        ],
    ]
    
    // Dummy arrays for row expansion and dismissal.
    var expanded = [false, false, false, false, false]
    var dismissed = [false, false, false, false, false]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        let nib = UINib.init(nibName: "MutualConnectionTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: mutualConnectionCellIdentifier)
    }
    
    // Number of rows needed for each request.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If the user has confirmed or declined a request, don't display it.
        if (dismissed[section] == true) {
            return 0
        }
        // If the row is not expanded or it is a relationship request, only 1 row is needed.
        if (requests[section]["kind"] == "relationship" || expanded[section] == false) {
            return 1
        }
        // For an expanded connection request, show up to 4 mutuals.
        return min(5, users[requests[section]["user"]!]!["numMutuals"]! + 1)
    }
    
    // Number of requests.
    func numberOfSections(in tableView: UITableView) -> Int {
        return requests.count
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
            // Connection request.
            if (requests[indexPath.section]["kind"] == "connection") {
                let cell = tableView.dequeueReusableCell(withIdentifier: pendingConnectionCellIdentifier) as! PendingConnectionTableViewCell
                
                // Add in user info.
                cell.otherName?.text = "First Last"
                //cell.otherProfile.image =
                let numMutuals = users[requests[indexPath.section]["user"]!]!["numMutuals"]!
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
                if (users[requests[indexPath.section]["user"]!]!["numMutuals"]! == 0) {
                    cell.chevron?.isHidden = true
                } else {
                    cell.chevron?.isHidden = false
                }
                if (expanded[indexPath.section]) {
                    cell.chevron?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                } else {
                    cell.chevron?.transform = CGAffineTransform.identity
                }
                
                return cell
            }
            // Relationship request.
            let cell = tableView.dequeueReusableCell(withIdentifier: pendingRelationshipCellIdentifier) as! PendingRelationshipTableViewCell
            
            // Add in user info.
            cell.otherName?.text = "First Last"
            //cell.otherProfile.image =
            
            // Add functions to buttons. They need to be in this file since they modify the table.
            cell.confirmButton?.tag = indexPath.section
            cell.declineButton?.tag = indexPath.section
            cell.confirmButton?.addTarget(self, action: #selector(onConfirmRequestPress(sender:)), for: .touchUpInside)
            cell.declineButton?.addTarget(self, action: #selector(onDeclineRequestPress(sender:)), for: .touchUpInside)
            
            return cell
        }
        // Mutual connection cell.
        let cell = tableView.dequeueReusableCell(withIdentifier: mutualConnectionCellIdentifier) as! MutualConnectionTableViewCell
        return cell
    }
    
    // Mark the section as expanded/collapsed and refresh it.
    @objc func onChevronPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        expanded[sender.tag] = !expanded[sender.tag]
        tableView.reloadSections(sections, with: .automatic)
    }
    
    // Update the database and hide the section.
    @objc func onConfirmRequestPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        // api call here.
        dismissed[sender.tag] = true
        tableView.reloadSections(sections, with: .automatic)
    }
    
    // Hide the section.
    @objc func onDeclineRequestPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        dismissed[sender.tag] = true
        tableView.reloadSections(sections, with: .automatic)
    }
}
