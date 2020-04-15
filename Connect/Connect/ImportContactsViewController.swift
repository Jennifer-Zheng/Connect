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
    @IBOutlet weak var profilePic: UIButton!
    
    let contactCellIdentifier = "ContactCell"
    let mutualConnectionCellIdentifier = "MutualConnectionCell"
    
    let queue = DispatchQueue.global()
    let dispatchGroup = DispatchGroup()

    var phoneNumbersInContacts: Array<String> = []
    var contactsThatAreUsers: Dictionary<String, Dictionary<String, Any>> = [:]
    var mutualConnectionsPerContact: Array<Dictionary<String,Array<String>>> = []
    var contactProfilePics: Dictionary<String, UIImage> = [:]

    let testUser = "gCWpsbrZLrQjBa4E0vzw258TdUK2"
    
    // Dummy arrays for row expansion and dismissal.
    var expanded = [false, false, false, false, false]
    var pending = [false, false, false, false, false]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        let nib = UINib.init(nibName: "MutualConnectionTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: mutualConnectionCellIdentifier)
        
        // Authorize access to contacts if user hasn't already
        let store = CNContactStore()
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)

        if authorizationStatus == .notDetermined {
          store.requestAccess(for: .contacts) { [weak self] didAuthorize,
          error in
            if didAuthorize {
               self?.retrieveContacts(from: store)
            }
          }
        } else if authorizationStatus == .authorized {
            retrieveContacts(from: store)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        dispatchGroup.notify(queue: queue) {
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
        if (expanded[section] == false) {
            return 1
        }
        // Show up to 5 mutuals if expanded.
        //return min(5, users[contacts[section]["user"]!]!["numMutuals"]! + 1)
        return min(5, mutualConnectionsPerContact[section].values.count+1)
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
            if (pending[indexPath.section]) {
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
            if (expanded[indexPath.section]) {
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
        let relationship = connections[0]["relationship"]!
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
    
    // Query Firebase for phone numbers that exist in user contacts
    func getContactsThatAreRegisteredUsers() {
      let reference = Firestore.firestore().collection("users")
        // Firestore "in" operator only supports up to 10 comparison values
        if phoneNumbersInContacts.count < 10 {
          dispatchGroup.enter()
          reference.whereField("phoneNumber", in: phoneNumbersInContacts)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    self.dispatchGroup.leave()
                } else {
                    for document in querySnapshot!.documents {
                        // Map of uid to user info
                        if document.documentID != self.testUser {
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
                            if document.documentID != self.testUser {
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
          Firestore.firestore().collection("users").document("\(testUser)")
          .addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
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
                // Checks if contact is already a connection b/c then we don't need to import them
                if !userConnectionsList.contains(contactUid) {
                    let userInfo = self.contactsThatAreUsers[contactUid]!
                    let contactConnections = userInfo["connections"]! as! Array<Dictionary<String, String>>
                    let contactConnectionsList = contactConnections.map({ (person) -> String in
                        return person["user"]!
                    })
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
        for mutualConnection in self.mutualConnectionsPerContact {
            let contactUid = (mutualConnection.first?.key)!
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
                if (loadedImages == self.mutualConnectionsPerContact.count) {
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
