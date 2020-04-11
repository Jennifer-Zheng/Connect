//
//  ImportContactsViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/10/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class ImportContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let contactCellIdentifier = "ContactCell"
    let mutualConnectionCellIdentifier = "MutualConnectionCell"
    
    // Dummy contacts array.
    var contacts = [
        ["user" : "a"],
        ["user" : "b"],
        ["user" : "c"],
    ]
    
    // Dummy mutuals array.
    var users = [
        "a" : [
            "numMutuals" : 0
        ],
        "b" : [
            "numMutuals" : 1
        ],
        "c" : [
            "numMutuals" : 5
        ]
    ]
    
    // Dummy arrays for row expansion and dismissal.
    var expanded = [false, false, false, false, false]
    var pending = [false, false, false, false, false]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        let nib = UINib.init(nibName: "MutualConnectionTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: mutualConnectionCellIdentifier)
    }
    
    // Number of rows needed for each request.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If the section is not expanded, only 1 row is needed.
        if (expanded[section] == false) {
            return 1
        }
        // Show up to 5 mutuals if expanded.
        return min(5, users[contacts[section]["user"]!]!["numMutuals"]! + 1)
    }
    
    // Number of requests.
    func numberOfSections(in tableView: UITableView) -> Int {
        return contacts.count
    }
    
    // Height for each cell. Contacts are 150, mutual connections are 50.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == 0) {
            return 150
        }
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Request cells.
        if (indexPath.row == 0) {
            // Contact cell.
            let cell = tableView.dequeueReusableCell(withIdentifier: contactCellIdentifier) as! ContactTableViewCell
                
            // Add in user info.
            cell.otherName?.text = "First Last"
            //cell.otherProfile.image =
            let numMutuals = users[contacts[indexPath.section]["user"]!]!["numMutuals"]!
            cell.otherNumberOfMutuals?.text = "\(numMutuals) Mutual Connection"
            if (numMutuals != 1) {
                cell.otherNumberOfMutuals?.text! += "s"
            }
                
            // Add functions to buttons. They need to be in this file since they modify the table.
            cell.chevron?.tag = indexPath.section
            cell.chevron?.addTarget(self, action: #selector(onChevronPress(sender:)), for: .touchUpInside)
            cell.addButton?.tag = indexPath.section
            cell.addButton?.addTarget(self, action: #selector(onAddPress(sender:)), for: .touchUpInside)
            
            // Add button -> pending button.
            if (pending[indexPath.section]) {
                cell.addButton?.setTitle("Pending", for: .normal)
                cell.addButton?.backgroundColor = UIColor.systemGreen
            } else {
                cell.addButton?.setTitle("Add", for: .normal)
                cell.addButton?.backgroundColor = UIColor.systemBlue
            }
                
            // Chevron visibility.
            if (users[contacts[indexPath.section]["user"]!]!["numMutuals"]! == 0) {
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
    
    // Either send a new request or cancel an existing one. Also change the button accordingly.
    @objc func onAddPress(sender: UIButton) {
        // API Call goes here. Check where you need to make a new request or cancel an existing one.
        let sections = IndexSet(integer: sender.tag)
        pending[sender.tag] = !pending[sender.tag]
        tableView.reloadSections(sections, with: .automatic)
    }

    @IBAction func onBackButtonPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
