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
    @IBOutlet weak var emptyMessageLabel: UILabel!
    
    let contactCellIdentifier = "ContactCell"
    let mutualConnectionCellIdentifier = "MutualConnectionCell"
    
    let dispatchGroup = DispatchGroup()
    let permissionsMessage = "Please enable permissions for Connect to access your contacts in your device's settings."
    let emptyContactsMessage = "You have no contacts who can be connected to at this time."
    let maxMutualsToDisplay = 4

    var document: Dictionary<String, Any> = [:]
    var phoneNumbers: Array<String> = []
    var contactsWithMutuals: Array<Dictionary<String, Any>?> = []
    var numDismissedCells = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        let nib = UINib.init(nibName: "MutualConnectionTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: mutualConnectionCellIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let userUID = FirebaseManager.manager.getUID()
        document = FirebaseManager.manager.getDocument()
        numDismissedCells = 0
        emptyMessageLabel?.text = emptyContactsMessage
        // First ensure contact permissions are enabled then read in phone numbers.
        checkContactPermissions()
        dispatchGroup.notify(queue: DispatchQueue.global()) {
            if (self.phoneNumbers.count > 0) {
                // Next find users containing the found numbers.
                FirebaseManager.manager.loadUsersWhereInList(field: "phoneNumber", list: self.phoneNumbers) { results, errors in
                    // Filter out contacts that have blocked this user.
                    let filteredResults = results.filter { !($0!["blockedUsers"] as! Array<String>).contains(userUID) }
                    // Then look for mutual connections.
                    FirebaseManager.manager.loadBatchRankedMutualConnections(user: self.document, otherUsers: filteredResults, limit: self.maxMutualsToDisplay) { resultsWithMutuals, errors in
                        self.contactsWithMutuals = resultsWithMutuals
                        // If any contacts were found, setup booleans such as if a request was already sent.
                        if (self.contactsWithMutuals.count > 0) {
                            for i in 0...(self.contactsWithMutuals.count - 1) {
                                self.contactsWithMutuals[i]!["sentRequest"] = false
                                self.contactsWithMutuals[i]!["expanded"] = false
                                self.contactsWithMutuals[i]!["pending"] = false
                                self.contactsWithMutuals[i]!["dismissed"] = false
                                for connectionRequest in self.contactsWithMutuals[i]!["sentConnections"] as! Array<Dictionary<String, String>> {
                                    if (connectionRequest["user"] == userUID) {
                                        self.contactsWithMutuals[i]!["sentRequest"] = true
                                    }
                                }
                                for connectionRequest in self.contactsWithMutuals[i]!["pendingConnections"] as! Array<Dictionary<String, String>> {
                                    if (connectionRequest["user"] == userUID) {
                                        self.contactsWithMutuals[i]!["pending"] = true
                                    }
                                }
                                for connectionRequest in self.contactsWithMutuals[i]!["connections"] as! Array<Dictionary<String, String>> {
                                    if (connectionRequest["user"] == userUID) {
                                        self.numDismissedCells += 1
                                        self.contactsWithMutuals[i]!["dismissed"] = true
                                    }
                                }
                            }
                        }
                        DispatchQueue.main.sync {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination is ProfileViewController) {
            let indexPath = self.tableView.indexPathForSelectedRow!
            let profileVC = segue.destination as! ProfileViewController
            profileVC.user = contactsWithMutuals[indexPath.section]!["id"] as! String
           }
       }
    
    // Authorize access to contacts if user hasn't already
    func checkContactPermissions() {
        dispatchGroup.enter()
        let store = CNContactStore()
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if (authorizationStatus == .notDetermined) {
            store.requestAccess(for: .contacts) { [weak self] didAuthorize, error in
                if (didAuthorize) {
                    self?.retrieveContacts(from: store)
                } else {
                    self?.emptyMessageLabel.text = self?.permissionsMessage
                }
                self?.dispatchGroup.leave()
            }
        } else if (authorizationStatus == .authorized) {
            retrieveContacts(from: store)
            dispatchGroup.leave()
        } else {
            emptyMessageLabel.text = permissionsMessage
            dispatchGroup.leave()
        }
    }
    
    func retrieveContacts(from store: CNContactStore) {
        phoneNumbers = []
        let containerId = store.defaultContainerIdentifier()
        let predicate = CNContact.predicateForContactsInContainer(withIdentifier: containerId)
        let keysToFetch = [CNContactGivenNameKey as CNKeyDescriptor,
                           CNContactFamilyNameKey as CNKeyDescriptor,
                           CNContactImageDataAvailableKey as CNKeyDescriptor,
                           CNContactImageDataKey as CNKeyDescriptor]

        let contacts = try! store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        
        for contact in contacts {
            if (contact.isKeyAvailable(CNContactPhoneNumbersKey)) {
                let number = (contact.phoneNumbers.first?.value)?.stringValue
                phoneNumbers.append(number!.digits)
            } else {
                // Refetch the keys
                let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
                do {
                    let refetchedContact = try store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keysToFetch)
                    let number = (refetchedContact.phoneNumbers.first?.value)?.stringValue
                    phoneNumbers.append(number!.digits)
                } catch {
                    print("Failed to fetch contact, error: \(error)")
                }
            }
        }
    }
    
    // Number of rows needed for each request.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If the contact has been added or is already connected with the user, don't display them.
        if (contactsWithMutuals[section]!["dismissed"] as! Bool) {
            return 0
        // If the section is not expanded, only 1 row is needed.
        } else if (contactsWithMutuals[section]!["expanded"] as! Bool == false) {
            return 1
        }
        return min(maxMutualsToDisplay, (contactsWithMutuals[section]!["mutuals"] as! Array<Any?>).count) + 1
    }
    
    // Number of possible contacts to import.
    func numberOfSections(in tableView: UITableView) -> Int {
        emptyMessageLabel.isHidden = !(numDismissedCells == contactsWithMutuals.count)
        return contactsWithMutuals.count
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
            cell.otherName?.text = (contactsWithMutuals[indexPath.section]!["name"] as? String)!
            cell.otherProfile?.image = (contactsWithMutuals[indexPath.section]!["image"] as! UIImage)
            let numMutuals = (contactsWithMutuals[indexPath.section]!["mutuals"] as! Array<Any?>).count
            cell.otherNumberOfMutuals?.text = "\(numMutuals) Mutual Connection"
            if (numMutuals != 1) {
                cell.otherNumberOfMutuals?.text! += "s"
            }
                
            // Add functions to buttons. They need to be in this file since they modify the table.
            cell.chevron?.tag = indexPath.section
            cell.chevron?.addTarget(self, action: #selector(onChevronPress(sender:)), for: .touchUpInside)
            cell.addButton?.removeTarget(nil, action: nil, for: .allEvents)
            if (contactsWithMutuals[indexPath.section]!["sentRequest"] as! Bool) {
                cell.addButton?.setTitle("Accept", for: .normal)
                cell.addButton?.backgroundColor = UIColor.systemBlue
                cell.addButton?.tag = indexPath.section
                cell.addButton?.addTarget(self, action: #selector(onAcceptPress(sender:)), for: .touchUpInside)
            } else if (contactsWithMutuals[indexPath.section]!["pending"] as! Bool) {
                cell.addButton?.setTitle("Pending", for: .normal)
                cell.addButton?.backgroundColor = UIColor.systemGreen
                cell.addButton?.tag = indexPath.section
                cell.addButton?.addTarget(self, action: #selector(onPendingPress(sender:)), for: .touchUpInside)
            } else {
                cell.addButton?.setTitle("Add", for: .normal)
                cell.addButton?.backgroundColor = UIColor.systemBlue
                cell.addButton?.tag = indexPath.section
                cell.addButton?.addTarget(self, action: #selector(onAddPress(sender:)), for: .touchUpInside)
            }
                
            // Chevron visibility.
            if (numMutuals == 0) {
                cell.chevron?.isHidden = true
            } else {
                cell.chevron?.isHidden = false
            }
            if (contactsWithMutuals[indexPath.section]!["expanded"] as! Bool) {
                cell.chevron?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            } else {
                cell.chevron?.transform = CGAffineTransform.identity
            }
            return cell
        }
        
        // Mutual connection cell.
        let cell = tableView.dequeueReusableCell(withIdentifier: mutualConnectionCellIdentifier) as! MutualConnectionTableViewCell
        let mutuals = contactsWithMutuals[indexPath.section]!["mutuals"] as! Array<Dictionary<String, Any>?>
        cell.mutualName?.text = (mutuals[indexPath.row - 1]!["name"] as? String)!
        cell.mutualRelation?.setTitle((mutuals[indexPath.row - 1]!["relationship"] as? String)!, for: .normal)
        cell.mutualRelation.backgroundColor = Constants.getRelationColor(mutuals[indexPath.row - 1]!["relationship"] as! String)
        let spacing: CGFloat = 8.0
        cell.mutualRelation.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
        cell.mutualProfile?.image = (mutuals[indexPath.row - 1]!["image"] as! UIImage)
        return cell
    }
    
    // Mark the section as expanded/collapsed and refresh it.
    @objc func onChevronPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        contactsWithMutuals[sender.tag]!["expanded"] = !(contactsWithMutuals[sender.tag]!["expanded"] as? Bool)!
        tableView.reloadSections(sections, with: .automatic)
    }
    
    @objc func onAddPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        FirebaseManager.manager.sendConnectionRequest(otherUID: contactsWithMutuals[sender.tag]!["id"] as! String)
        contactsWithMutuals[sender.tag]!["pending"] = true
        tableView.reloadSections(sections, with: .automatic)
    }
    
    @objc func onPendingPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        FirebaseManager.manager.cancelConnectionRequest(otherUID: contactsWithMutuals[sender.tag]!["id"] as! String)
        contactsWithMutuals[sender.tag]!["pending"] = false
        tableView.reloadSections(sections, with: .automatic)
    }
    
    @objc func onAcceptPress(sender: UIButton) {
        let sections = IndexSet(integer: sender.tag)
        FirebaseManager.manager.confirmPendingConnection(otherUID: contactsWithMutuals[sender.tag]!["id"] as! String)
        numDismissedCells += 1
        if (numDismissedCells == contactsWithMutuals.count) {
            emptyMessageLabel.isHidden = false
        }
        contactsWithMutuals[sender.tag]!["dismissed"] = true
        tableView.reloadSections(sections, with: .automatic)
    }

    @IBAction func onBackButtonPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}

// Parses phone number so it only returns the digits (ex. (555) 564-8583 -> 5555648583)
extension String {
    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }
}
