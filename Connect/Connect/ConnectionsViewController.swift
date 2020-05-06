//
//  ConnectionsViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/13/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseStorage

class ConnectionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profilePic: UIButton!
    @IBOutlet weak var noConnectionsMessage: UILabel!
    
    // Custom cell identifiers.
    let connectionCellIdentifier = "ConnectionCell"
    
    let locationManager = CLLocationManager()
    
    var connections: Array<Dictionary<String, Any>> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        profilePic.setImage(FirebaseManager.manager.getProfilePic(), for: .normal)
        let connections = FirebaseManager.manager.getDocument()["connections"] as! Array<Dictionary<String, Any>>
        if (connections.count > 0) {
            noConnectionsMessage.isHidden = true
            FirebaseManager.manager.loadBatchUsers(userConnections: connections) { results, errors in
                self.connections = connections
                for i in 0...(results.count - 1) {
                    if (errors[i] == nil) {
                        self.connections[i]["name"] = results[i]!["name"]
                        self.connections[i]["image"] = results[i]!["image"]
                    }
                }
                DispatchQueue.main.sync {
                    self.tableView.reloadData()
                }
            }
        } else {
            noConnectionsMessage.isHidden = false
            self.connections = []
            self.tableView.reloadData()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print(location.coordinate)
            FirebaseManager.manager.updateLocation(location: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
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
