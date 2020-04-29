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
    
    var userUID = ""
    var conversations: Array<Dictionary<String, Any>> = []
    var filteredConnections: Array<Dictionary<String, Any>> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        userUID = FirebaseManager.manager.getUID()
        FirebaseManager.manager.loadConversations() { results in
            self.conversations = results
            DispatchQueue.main.sync {
                self.filteredConnections = self.searchBar.text!.isEmpty ? self.conversations : self.conversations.filter {
                    return ($0["name"] as! String).range(of: self.searchBar.text!, options: .caseInsensitive, range: nil, locale: nil) != nil
                }
                self.tableView.reloadData()
            }
        }
    }
    
    // Stop listening for real time updates.
    override func viewWillDisappear(_ animated: Bool) {
        FirebaseManager.manager.deleteConversationListener()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.destination is ConversationViewController) {
            let indexPath = self.tableView.indexPathForSelectedRow!
            let conversationVC = segue.destination as! ConversationViewController
            var otherConnectionMessagesOnly = (self.filteredConnections[indexPath.row]["connectionMessagesOnly"] as! Bool)
            for connection in self.filteredConnections[indexPath.row]["connections"] as! Array<Dictionary<String, String>> {
                if (connection["user"] == userUID) {
                    otherConnectionMessagesOnly = false
                }
            }
            conversationVC.otherName = self.filteredConnections[indexPath.row]["name"] as! String
            conversationVC.otherUID = self.filteredConnections[indexPath.row]["id"] as! String
            conversationVC.otherProfile = (self.filteredConnections[indexPath.row]["image"] as! UIImage)
            conversationVC.otherConnectionMessagesOnly = otherConnectionMessagesOnly
        }
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
        cell.otherName?.text = (filteredConnections[indexPath.row]["name"] as! String)
        cell.otherProfile?.image = (filteredConnections[indexPath.row]["image"] as! UIImage)
        cell.previewMessage?.font = UIFont.systemFont(ofSize: 18.0)
        
        // Three cases for the preview text: No messages, user is the last sender, other person is the last sender (bold if unread).
        if (filteredConnections[indexPath.row]["lastSender"] == nil) {
            cell.previewMessage?.text = "No messages. Why not say hi?"
        } else if (filteredConnections[indexPath.row]["lastSender"] as! String == userUID) {
            cell.previewMessage?.text = "You said: " + (filteredConnections[indexPath.row]["lastMessage"] as! String)
        } else {
            cell.previewMessage?.text = (filteredConnections[indexPath.row]["lastMessage"] as! String)
            // Bold font if you have an unread message.
            if ((filteredConnections[indexPath.row]["read"] as! Bool) == false) {
                cell.previewMessage?.font = UIFont.boldSystemFont(ofSize: 18.0)
            }
        }
        return cell
    }

    @IBAction func onBackButtonPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Code to dismiss keyboard when user clicks on background.

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
        filteredConnections = searchText.isEmpty ? conversations : conversations.filter {
            return ($0["name"] as! String).range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        }
        tableView.reloadData()
    }
}
