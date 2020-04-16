//
//  ImportContactsViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/10/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit
import Contacts
import Firebase
import FirebaseStorage

class ImportContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let contactCellIdentifier = "ContactCell"
    let mutualConnectionCellIdentifier = "MutualConnectionCell"
    
    let queue = DispatchQueue.global()
    let dispatchGroup = DispatchGroup()

    var phoneNumbersInContacts: Array<String> = []
    // A dictionary that maps userIDs to their profile's information.
    var contactsThatAreUsers: Dictionary<String, Dictionary<String, Any>> = [:]
    // A list of dictionaries for each contact that maps their phone numbers (there can be multiple) to a list of mutuals. This is needed
    // because a person may have multiple phone numbers linked to multiple accounts.
    var mutualConnectionsPerContact: Array<Dictionary<String,Array<String>>> = []
    var contactProfilePics: Dictionary<String, UIImage> = [:]

    var uid = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        uid = Auth.auth().currentUser!.uid
        tableView.dataSource = self
        tableView.delegate = self
        let nib = UINib.init(nibName: "MutualConnectionTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: mutualConnectionCellIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        phoneNumbersInContacts = []
        mutualConnectionsPerContact = []
        dispatchGroup.notify(queue: queue) {
            self.checkContactPermissions()
                self.dispatchGroup.notify(queue: self.queue) {
                    self.getContactsThatAreRegisteredUsers()
                    self.dispatchGroup.notify(queue: self.queue) {
                        self.getMutualConnections()
                        self.dispatchGroup.notify(queue: self.queue) {
                            self.getProfilePics()
                            self.dispatchGroup.notify(queue: DispatchQueue.main) {
                                self.tableView.reloadData()
                            }
                        }
                    }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if(segue.destination is ProfileViewController) {
               let indexPath = self.tableView.indexPathForSelectedRow!
               let profileVC = segue.destination as! ProfileViewController
               profileVC.user = mutualConnectionsPerContact[indexPath.row].first!.key
           }
       }
    
    // Authorize access to contacts if user hasn't already
    func checkContactPermissions() {
        dispatchGroup.enter()
        let store = CNContactStore()
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authorizationStatus == .notDetermined {
         store.requestAccess(for: .contacts) { [weak self] didAuthorize,
         error in
           if didAuthorize {
              self?.retrieveContacts(from: store)
            self?.dispatchGroup.leave()
           }
         }
        } else if authorizationStatus == .authorized {
           retrieveContacts(from: store)
           dispatchGroup.leave()
        }
    }
    
    func retrieveContacts(from store: CNContactStore) {
      let containerId = store.defaultContainerIdentifier()
      let predicate = CNContact.predicateForContactsInContainer(withIdentifier: containerId)
      let keysToFetch = [CNContactGivenNameKey as CNKeyDescriptor,
                         CNContactFamilyNameKey as CNKeyDescriptor,
                         CNContactImageDataAvailableKey as
                         CNKeyDescriptor,
                         CNContactImageDataKey as CNKeyDescriptor]

      let contacts = try! store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        
      for contact in contacts {
          if contact.isKeyAvailable(CNContactPhoneNumbersKey) {
            let number = (contact.phoneNumbers.first?.value)?.stringValue
            phoneNumbersInContacts.append(number!.digits)
          } else {
              //Refetch the keys
              let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]

              do {
                  let refetchedContact = try store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keysToFetch)
                  let number = (refetchedContact.phoneNumbers.first?.value)?.stringValue
                  phoneNumbersInContacts.append(number!.digits)
              } catch {
                  print("Failed to fetch contact, error: \(error)")
              }
            }
        }
    }
    
    // Number of rows needed for each request.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If the section is not expanded, only 1 row is needed.
        let contactUid = mutualConnectionsPerContact[section].first?.key
        if (self.contactsThatAreUsers[contactUid!]!["expanded"] as! Bool == false) {
            return 1
        }
        return min(5, mutualConnectionsPerContact[section].values.count + 1)
    }
    
    // Number of possible contacts to import.
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.mutualConnectionsPerContact.count
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
            let contactUid = mutualConnectionsPerContact[indexPath.section].first?.key
            cell.otherName?.text = contactsThatAreUsers[contactUid!]!["name"] as? String
            cell.otherProfile.image = contactProfilePics[contactUid!]
            let numMutuals = mutualConnectionsPerContact[indexPath.section][contactUid!]!.count
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
            if (contactsThatAreUsers[contactUid!]!["added"] as! Bool) {
                cell.addButton?.setTitle("Added", for: .normal)
                cell.addButton?.backgroundColor = UIColor.systemPurple
            } else if (contactsThatAreUsers[contactUid!]!["sentRequest"] as! Bool) {
                cell.addButton?.setTitle("Accept", for: .normal)
                cell.addButton?.backgroundColor = UIColor.systemBlue
            } else if (contactsThatAreUsers[contactUid!]!["pending"] as! Bool) {
                cell.addButton?.setTitle("Pending", for: .normal)
                cell.addButton?.backgroundColor = UIColor.systemGreen
            } else {
                cell.addButton?.setTitle("Add", for: .normal)
                cell.addButton?.backgroundColor = UIColor.systemBlue
            }
                
            // Chevron visibility.
            if (numMutuals == 0) {
                cell.chevron?.isHidden = true
            } else {
                cell.chevron?.isHidden = false
            }
            if (contactsThatAreUsers[contactUid!]!["expanded"] as! Bool) {
                cell.chevron?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            } else {
                cell.chevron?.transform = CGAffineTransform.identity
            }
            return cell
        }

        // Mutual connection cell.
        let cell = tableView.dequeueReusableCell(withIdentifier: mutualConnectionCellIdentifier) as! MutualConnectionTableViewCell
        let contactUid = mutualConnectionsPerContact[indexPath.section].first?.key
        // TODO: fix index 0
        let mutualUid = mutualConnectionsPerContact[indexPath.section][contactUid!]![0]
        cell.mutualName?.text = contactsThatAreUsers[mutualUid]!["name"] as? String
        let connections = contactsThatAreUsers[mutualUid]!["connections"] as! Array<Dictionary<String, String>>
        let relationship = connections[indexPath.row]["relationship"]!
        cell.mutualRelation?.setTitle(relationship, for: .normal)
        cell.mutualRelation.backgroundColor = Constants.getRelationColor(relationship)
        let spacing: CGFloat = 8.0
        cell.mutualRelation.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
        cell.mutualProfile?.image = contactProfilePics[mutualUid]
        return cell
    }
    
    // Mark the section as expanded/collapsed and refresh it.
    @objc func onChevronPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        let contactUid = mutualConnectionsPerContact[sender.tag].first?.key
        contactsThatAreUsers[contactUid!]!["expanded"] = !(contactsThatAreUsers[contactUid!]!["expanded"] as? Bool)!
        tableView.reloadSections(sections, with: .automatic)
    }
    
    // Either send a new request or cancel an existing one. Also change the button accordingly.
    @objc func onAddPress(sender: UIButton) {
        let contactUid = mutualConnectionsPerContact[sender.tag].first?.key
        let sections = IndexSet(integer: sender.tag)
        // Don't do anything if the recipient was added due to a pending request on their end.
        if (contactsThatAreUsers[contactUid!]!["added"] as! Bool) {
            tableView.reloadSections(sections, with: .automatic)
            return
        }
        if (contactsThatAreUsers[contactUid!]!["pending"] as! Bool) {
            Firestore.firestore().collection("users").document(uid)
                .updateData([
                    "sentConnections": FieldValue.arrayRemove([["user": contactUid!]])
                ])
            Firestore.firestore().collection("users").document(contactUid!)
                .updateData([
                    "pendingConnections": FieldValue.arrayRemove([["user": uid]])
                ])
            contactsThatAreUsers[contactUid!]!["pending"] = false
        } else if (contactsThatAreUsers[contactUid!]!["sentRequest"] as! Bool) {
            Firestore.firestore().collection("users").document(contactUid!)
                .updateData([
                    "sentConnections": FieldValue.arrayRemove([["user": uid]])
                ])
            Firestore.firestore().collection("users").document(uid)
                .updateData([
                    "pendingConnections": FieldValue.arrayRemove([["user": contactUid!]])
                ])
            Firestore.firestore().collection("users").document(contactUid!)
                .updateData([
                    "connections": FieldValue.arrayUnion([["user": uid, "relationship": "Acquaintance"]]),
                ])
            Firestore.firestore().collection("users").document(uid)
                .updateData([
                    "connections": FieldValue.arrayUnion([["user": contactUid!, "relationship": "Acquaintance"]]),
                ])
            contactsThatAreUsers[contactUid!]!["added"] = true
        } else {
            Firestore.firestore().collection("users").document(uid)
                .updateData([
                    "sentConnections": FieldValue.arrayUnion([["user": contactUid!]])
                ])
            Firestore.firestore().collection("users").document(contactUid!)
                .updateData([
                    "pendingConnections": FieldValue.arrayUnion([["user": uid]])
                ])
            contactsThatAreUsers[contactUid!]!["pending"] = true
        }
        tableView.reloadSections(sections, with: .automatic)
    }

    @IBAction func onBackButtonPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Query Firebase for phone numbers that exist in user contacts
    func getContactsThatAreRegisteredUsers() {
      let reference = Firestore.firestore().collection("users")
        // Firestore "in" operator only supports up to 10 comparison values
        if phoneNumbersInContacts.count < 10 && phoneNumbersInContacts.count > 0 {
          dispatchGroup.enter()
          reference.whereField("phoneNumber", in: phoneNumbersInContacts)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    self.dispatchGroup.leave()
                } else {
                    for document in querySnapshot!.documents {
                        // Map of uid to user info
                        if document.documentID != self.uid {
                            self.contactsThatAreUsers[document.documentID] = document.data()
                        }
                    }
                }
                self.dispatchGroup.leave()
            }
        } else {
            dispatchGroup.enter()
            for phoneNum in phoneNumbersInContacts {
                reference.whereField("phoneNumber", isEqualTo: phoneNum)
                .getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        self.dispatchGroup.leave()
                    } else {
                        for document in querySnapshot!.documents {
                            // Map of uid to user info
                            if document.documentID != self.uid {
                                self.contactsThatAreUsers[document.documentID] = document.data()
                            }
                        }
                    }
                }
            }
            self.dispatchGroup.leave()
        }
    }
      
      func getMutualConnections() {
         dispatchGroup.enter()
          // TODO: replace user id with id generated by Firebase Auth
          Firestore.firestore().collection("users").document(uid)
            .getDocument { document, error in
                guard let document = document, document.exists else {
              print("Error fetching document: \(error!)")
              self.dispatchGroup.leave()
              return
            }
            // Get the user's list of connections
            let userConnections = (document.get("connections") as? Array<Dictionary<String, String>>)!

            // Return an array of strings containing the connections' names
            let userConnectionsList = userConnections.map({ (person) -> String in
                return person["user"]!
            })
            for contactUid in self.contactsThatAreUsers.keys {
                // Checks if contact is already a connection b/c then we don't need to import them.
                // Also check if either the user or the contact has sent a connection request before.
                if !userConnectionsList.contains(contactUid) {
                    self.contactsThatAreUsers[contactUid]!["expanded"] = false
                    self.contactsThatAreUsers[contactUid]!["pending"] = false
                    self.contactsThatAreUsers[contactUid]!["added"] = false
                    self.contactsThatAreUsers[contactUid]!["sentRequest"] = false
                    let userInfo = self.contactsThatAreUsers[contactUid]!
                    let contactConnections = userInfo["connections"]! as! Array<Dictionary<String, String>>
                    let contactPendingConnections = userInfo["pendingConnections"]! as! Array<Dictionary<String, String>>
                    let contactSentConnections = userInfo["sentConnections"]! as! Array<Dictionary<String, String>>
                    let contactConnectionsList = contactConnections.map({ (person) -> String in
                        return person["user"]!
                    })
                    let contactRequestsList = contactPendingConnections.map({ (person) -> String in
                        return person["user"]!
                    })
                    let contactSentList = contactSentConnections.map({ (person) -> String in
                        return person["user"]!
                    })
                    if (contactSentList.contains(self.uid)) {
                        self.contactsThatAreUsers[contactUid]!["sentRequest"] = true
                    }
                    if (contactRequestsList.contains(self.uid)) {
                        self.contactsThatAreUsers[contactUid]!["pending"] = true
                    }
                    // Array of mutual connections shared by current user and their contact
                    let mutualConnectionIds = userConnectionsList.filter(contactConnectionsList.contains)
                    // Array of contacts paired with their mutual connections
                    self.mutualConnectionsPerContact.append([contactUid:mutualConnectionIds])
                }
              }
            self.dispatchGroup.leave()
          }
      }
    
    func getProfilePics() {
        dispatchGroup.enter()
        var loadedImages = 0
        for contactUid in self.contactsThatAreUsers.keys {
            let reference = Storage.storage().reference().child("profile_pics").child("\(contactUid).png")
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
                self.contactProfilePics[contactUid] = UIImage(data: data!)
              }
                loadedImages += 1
                // Only mark done once all images have loaded.
                if (loadedImages == self.contactsThatAreUsers.count) {
                    self.dispatchGroup.leave()
                }
            }
        }
    }
}

// Parses phone number so it only returns the digits (ex. (555) 564-8583 -> 5555648583)
extension String {
    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }
}
