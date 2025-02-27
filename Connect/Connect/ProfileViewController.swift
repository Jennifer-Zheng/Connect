//
//  ProfileViewController.swift
//  Connect
//
//  Created by Nikhil Pandeti on 4/13/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var Connection: UIButton!
    @IBOutlet weak var bioTextField: UITextView!
    @IBOutlet weak var mutualsTableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var blockButton: UIButton!
    @IBOutlet weak var relationshipButton: UIButton!
    @IBOutlet weak var conversationButton: UIButton!
    
    let mutualConnectionCellIdentifier = "MutualConnectionCell"
    let conversationSegueIdentifier = "ConversationSegue"
    
    var user = ""
    var uid = ""
    var connectionsArray : Array<Dictionary<String, String>> = Array<Dictionary<String, String>>()
    var mutualsArray : Array<Dictionary<String, String>> = Array<Dictionary<String, String>>()
    var mutualConnections : [String] = []
    var allConnections : [String] = []
    var userData : Dictionary<String, Any> = Dictionary<String, Any>()
    var status : String = ""
    var blockedStatus: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bioTextField.textContainer.lineFragmentPadding = 0
        self.uid = Auth.auth().currentUser!.uid
        mutualsTableView.dataSource = self
        mutualsTableView.delegate = self
        let nib = UINib.init(nibName: "MutualConnectionTableViewCell", bundle: nil)
        mutualsTableView.register(nib, forCellReuseIdentifier: mutualConnectionCellIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        conversationButton.isHidden = true
        showCurrentProfileInfo()
        self.mutualsTableView.reloadData()
    }
    
    func showCurrentProfileInfo() {
        // Profile picture
        let reference = Storage.storage().reference().child("profile_pics").child("\(user).png")
        // Download in memory with a maximum allowed size = 5 MB
        reference.getData(maxSize: 5 * 1024 * 1024) { data, error in
        if (error != nil) {
            let controller = UIAlertController(
                title: "Warning",
                message: "Image is too large",
                preferredStyle: .alert)
            controller.addAction(UIAlertAction(
                title: "OK",
                style: .default,
                handler: nil))
            self.present(controller, animated: true, completion: nil)
          } else {
            self.profilePic.image = UIImage(data: data!)
          }
        }
        
        // Name and bio
        let db = Firestore.firestore()
        db.collection("users").document("\(user)").getDocument(completion: { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            self.userData = document.data()!
            self.nameTextField.text = document.get("name") as? String
            self.bioTextField.text = document.get("bio") as? String
            self.connectionsArray = (document.get("connections") as? Array<Dictionary<String, String>>)!
            
            self.allConnections = self.connectionsArray.map({ (person) -> String in
                return person["user"]!
            })
            if self.allConnections.contains(self.uid) {
                self.status = "remove"
                // Message Condition 1/2 - Unhide conversation button if connected.
                self.conversationButton.isHidden = false
            }
            if (document.get("connectionMessagesOnly") as! Bool == false) {
                // Message Condition 2/2 - Unhide conversation button if settings allow non-connections to message them.
                self.conversationButton.isHidden = false
            }
            if let pendingConnections = document.get("sentConnections") as? Array<Dictionary<String, String>> {
                for p in pendingConnections {
                    if p["user"] == self.uid {
                        self.status = "accept"
                    }
                }
            }
            if let pendingConnections = document.get("pendingConnections") as? Array<Dictionary<String, String>> {
                for p in pendingConnections {
                    if p["user"] == self.uid {
                        self.status = "pending"
                    }
                }
            }
            if let blockedArray = FirebaseManager.manager.getDocument()["blockedUsers"] as? Array<String> {
                if(blockedArray.contains(self.user)) {
                    self.blockedStatus = "Unblock"
                }
            }
            self.updateButtons()
            self.mutualsTableView.reloadData()
            self.getMutualConnections()
        })
    }
    
    func getMutualConnections() {
        // TODO: replace user id with id generated by Firebase Auth
        Firestore.firestore().collection("users").document(uid).getDocument { document, error in
            guard let document = document, document.exists else {
                print("Error fetching document: \(error!)")
                return
            }
            // Get the user's list of connections
            let connections = (document.get("connections") as? Array<Dictionary<String, String>>)!
            

            // Return an array of strings containing the connections' names
            let userConnectionsList = connections.map({ (person) -> String in
                if person["user"]! == self.user {
                    let relationText = person["relationship"]!
                    self.Connection.setTitle(relationText, for: .normal)
                    self.Connection.backgroundColor = Constants.getRelationColor(relationText)
                }
                return person["user"]!
            })
            
            self.mutualConnections = self.allConnections.filter(userConnectionsList.contains)
            
            self.mutualsArray = self.connectionsArray.filter({ (person) -> Bool in
                return self.mutualConnections.contains(person["user"]!)
            })
            self.mutualsTableView.reloadData()
        }
    }
    
    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination is RelationshipsViewController){
            let relationshipVC = segue.destination as! RelationshipsViewController
            relationshipVC.user = self.user
            relationshipVC.currentRelation = self.Connection.titleLabel!.text!
        }
        if (segue.destination is ConversationViewController) {
            let conversationVC = segue.destination as! ConversationViewController
            conversationVC.otherName = nameTextField.text!
            conversationVC.otherUID = user
            conversationVC.otherProfile = profilePic.image!
        }
    }
    
    func updateButtons() {
        self.addButton.titleLabel!.adjustsFontSizeToFitWidth = true
        if(status == "") {
            self.addButton.setTitle("Add", for: .normal)
            self.addButton?.backgroundColor = #colorLiteral(red: 0.4453955889, green: 0.4632643461, blue: 0.9224863052, alpha: 1)
        } else if (status == "pending") {
            self.addButton.setTitle("Pending", for: .normal)
            self.addButton?.backgroundColor = UIColor.systemGreen
        } else if(status == "remove") {
            self.addButton.setTitle("Remove", for: .normal)
            self.addButton?.backgroundColor = UIColor.systemBlue
        }
        
        if(status == "remove") {
            self.relationshipButton.isEnabled = true
        } else {
            self.relationshipButton.isEnabled = false
        }
        
        if(blockedStatus == "") {
            self.addButton.isEnabled = true
            self.blockButton.setTitle("Block", for: .normal)
        } else if(blockedStatus == "Unblock"){
            self.addButton.isEnabled = false
            self.blockButton.setTitle("Unblock", for: .normal)
        }
    }
    
    @IBAction func add(_ sender: Any) {
        if(status == "") {
            FirebaseManager.manager.sendConnectionRequest(otherUID: user)
            status = "pending"
        } else if (status == "pending") {
            FirebaseManager.manager.cancelConnectionRequest(otherUID: user)
            status = ""
        } else if (status == "accept") {
            FirebaseManager.manager.confirmPendingConnection(otherUID: user)
            status = "remove"
        } else if(status == "remove") {
            FirebaseManager.manager.removeConnection(otherUID: user, relationship: self.Connection.titleLabel!.text!)
            status = ""
        }
        self.updateButtons()
    }
    @IBAction func block(_ sender: Any) {
        //waiting for settings
        if(blockedStatus == "") {
            self.blockButton.setTitle("Block", for: .normal)
            FirebaseManager.manager.blockUser(otherUID: self.user, relationship: self.Connection.titleLabel!.text!)
            self.blockedStatus = "Unblock"
            self.status = ""
        } else if(blockedStatus == "Unblock"){
            self.blockButton.setTitle("Block", for: .normal)
            FirebaseManager.manager.unblockUser(otherUID: self.user, relationship: self.Connection.titleLabel!.text!)
            self.blockedStatus = ""
        }
        self.updateButtons()
    }
}

extension ProfileViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mutualsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Mutual connection cell.
        let cell = tableView.dequeueReusableCell(withIdentifier: mutualConnectionCellIdentifier) as! MutualConnectionTableViewCell
        let relationText = self.mutualsArray[indexPath.row]["relationship"] ?? "Relation"
        cell.mutualRelation.setTitle(relationText, for: .normal)
        cell.mutualRelation.backgroundColor = Constants.getRelationColor(relationText)
        let spacing: CGFloat = 8.0
        cell.mutualRelation.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
        cell.populateWithUser(uid: self.mutualsArray[indexPath.row]["user"])
        return cell
    }
    
    
}

extension ProfileViewController : UITableViewDelegate {
    
}
