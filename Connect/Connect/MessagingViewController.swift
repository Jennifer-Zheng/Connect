//
//  MessagingViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/13/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class MessagingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    // Custom cell identifiers.
    let messagingCellIdentifier = "MessagingCell"
    
    // Dummy connections array. The structure is bad for testing purposes
    var connections = [
        ["user" : "Jon Doe",
         "lastSender" : "you",
         "lastMessage" : "Hello!"],
        ["user" : "John Doe",
        "lastSender" : "other",
        "lastMessage" : "This is a really long message so there should be automatic dots"],
        ["user" : "Lauren Doe",
        "lastSender" : "none",
        "lastMessage" : nil]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
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
        let cell = tableView.dequeueReusableCell(withIdentifier: messagingCellIdentifier) as! MessagingTableViewCell
        let otherName = connections[indexPath.row]["user"]!!
        let otherFirstName = otherName.components(separatedBy: " ")[0]
        cell.otherName?.text = otherName
        //cell.otherProfile?.image
        
        // This is bad code for testing purposes.
        if (connections[indexPath.row]["lastSender"] == "none") {
            cell.previewMessage?.text = "You are now connected with " + otherFirstName
        } else if (connections[indexPath.row]["lastSender"] == "you") {
            cell.previewMessage?.text = "You said: " + connections[indexPath.row]["lastMessage"]!!
        } else {
            cell.previewMessage?.text = connections[indexPath.row]["lastMessage"]!!
        }
        return cell
    }

    @IBAction func onBackButtonPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
