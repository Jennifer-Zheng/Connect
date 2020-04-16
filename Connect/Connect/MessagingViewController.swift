//
//  MessagingViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/13/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class MessagingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // Custom cell identifiers.
    let messagingCellIdentifier = "MessagingCell"
    
    // Dummy connections array. The structure is for testing purposes and does not represent data on Firebase.
    var connections = [
        ["user" : "TestUser 1",
         "lastSender" : "you",
         "lastMessage" : "Hello!"],
        ["user" : "First Last",
        "lastSender" : "other",
        "lastMessage" : "This is a really long message so there should be automatic dots"],
        ["user" : "John Doe",
        "lastSender" : "none",
        "lastMessage" : nil]
    ]
    
    var filteredConnections: [[String: String?]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        filteredConnections = connections
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    // Number of rows needed in the table.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredConnections.count
    }
    
    // Height for each cell.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: messagingCellIdentifier) as! MessagingTableViewCell
        let otherName = filteredConnections[indexPath.row]["user"]!!
        let otherFirstName = otherName.components(separatedBy: " ")[0]
        cell.otherName?.text = otherName
        //cell.otherProfile?.image
        
        // This is bad code for testing purposes.
        if (filteredConnections[indexPath.row]["lastSender"] == "none") {
            cell.previewMessage?.text = "You are now connected with " + otherFirstName
        } else if (filteredConnections[indexPath.row]["lastSender"] == "you") {
            cell.previewMessage?.text = "You said: " + connections[indexPath.row]["lastMessage"]!!
        } else {
            cell.previewMessage?.text = connections[indexPath.row]["lastMessage"]!!
        }
        return cell
    }

    @IBAction func onBackButtonPress(_ sender: Any) {
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

extension MessagingViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredConnections = searchText.isEmpty ? connections : connections.filter {
            return $0["user"]!!.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        }
        tableView.reloadData()
    }
}
