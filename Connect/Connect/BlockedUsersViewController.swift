//
//  BlockedUsersViewController.swift
//  Connect
//
//  Created by Jennifer Zheng on 4/26/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit
import Firebase

class BlockedUsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    // Custom cell identifier
    let blockedUserCellIdentifier = "BlockedUserCell"
    
    var blockedUsersName: Array<String> = []
    var blockedUsersUid: Array<String> = []
    var blockedUsers: Array<Dictionary<String, Any>> = []
    
    override func viewDidLoad() {
       super.viewDidLoad()
       // Do any additional setup after loading the view.
       tableView.delegate = self
       tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        blockedUsersName = []
        blockedUsersUid = FirebaseManager.manager.getDocument()["blockedUsers"] as! Array<String>
        if (blockedUsersUid.count > 0) {
            FirebaseManager.manager.loadBatchUsers(userIds: blockedUsersUid) { results, errors in
                for i in 0...(results.count - 1) {
                    if (errors[i] == nil) {
                        self.blockedUsers.append(results[i]!)
                        self.blockedUsersName.append(results[i]!["name"] as! String)
                    }
                }
                DispatchQueue.main.sync {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return blockedUsersName.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: blockedUserCellIdentifier, for: indexPath as IndexPath) as! BlockedUsersTableViewCell
        let row = indexPath.row
        cell.blockedUserNameLabel?.text = blockedUsersName[row]
        return cell
    }

    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     if (segue.destination is ProfileViewController) {
         let indexPath = self.tableView.indexPathForSelectedRow!
         let profileVC = segue.destination as! ProfileViewController
         profileVC.user = blockedUsersUid[indexPath.section]
        }
    }
}
