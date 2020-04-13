//
//  ConnectionsViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/13/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class ConnectionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    // Custom cell identifiers.
    let connectionCellIdentifier = "ConnectionCell"
    
    // Dummy connections array.
    var connections = [
        ["user" : "Jon Doe"],
        ["user" : "John Doe"],
        ["user" : "Lauren Doe"],
        ["user" : "Sarah Doe"]
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
        let cell = tableView.dequeueReusableCell(withIdentifier: connectionCellIdentifier) as! ConnectionTableViewCell
        cell.otherName?.text = connections[indexPath.row]["user"]
        //cell.otherProfile?.image
        return cell
    }

}
