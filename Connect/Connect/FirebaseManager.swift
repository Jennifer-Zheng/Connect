//
//  FirebaseManager.swift
//  Connect
//
//  Created by Evan Weiss on 4/16/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

class FirebaseManager {
    
    static var manager = FirebaseManager()
    
    private var isInitialLoad = true
    private var userUID: String = ""
    private var userProfilePic: UIImage = UIImage()
    private var userDocument: Dictionary<String, Any> = [:]
    
    init() {
        Firestore.firestore().clearPersistence(completion: nil)
    }
    
    func getUID() -> String {
        return userUID
    }
    
    func getDocument() -> Dictionary<String, Any> {
        return userDocument
    }
    
    func getProfilePic() -> UIImage {
        return userProfilePic
    }
    
    // Load the user's profile.
    func loadSelf(completion: @escaping () -> Void) {
        userUID = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(userUID)
            .addSnapshotListener() { document, error in
                if let error = error {
                    print("Error fetching document: \(error)")
                } else {
                    self.userDocument = document!.data()!
                }
                // We load the user's profile picture inside the snapshot listener so it auto-updates if changed.
                Storage.storage().reference().child("profile_pics").child(self.userUID + ".png")
                    .getData(maxSize: 1024 * 1024 * 1024) { data, error in
                        if let error = error {
                            print(error.localizedDescription)
                        } else {
                            self.userProfilePic = UIImage(data: data!)!
                        }
                        if (self.isInitialLoad) {
                            self.isInitialLoad = false
                            completion()
                        }
                }
        }
    }
    
    // GET REQUESTS
    
    // Loads all of a user's connection's profiles. Also works for pendingRequests and pendingConnections.
    func loadBatchUsers(userConnections: Array<Dictionary<String, Any>>,
                        completion: @escaping (_ results: Array<Dictionary<String, Any>?>, _ errors: Array<Error?>) -> Void) {
        var userIds = Array<String>()
        for user in userConnections {
            userIds.append(user["user"] as! String)
        }
        loadBatchUsers(userIds: userIds) { results, errors in
            completion(results, errors)
        }
    }
    
    // Loads users given an array of userIds.
    func loadBatchUsers(userIds: Array<String>, completion: @escaping (_ results: Array<Dictionary<String, Any>?>, _ errors: Array<Error?>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var results: Array<Dictionary<String, Any>?> = Array(repeating: nil, count: userIds.count)
        var errors: Array<Error?> = Array(repeating: nil, count: userIds.count)
        for i in 0...(userIds.count - 1) {
            dispatchGroup.enter()
            loadUser(uid: userIds[i]) { result, error in
                results[i] = result
                errors[i] = error
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: DispatchQueue.global()) {
            completion(results, errors)
        }
    }

    // Loads a user's profile given their uid.
    func loadUser(uid: String, completion: @escaping (_ result: Dictionary<String, Any>?, _ error: Error?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var doc: Dictionary<String, Any>?
        var img: UIImage?
        var err: Error?
        dispatchGroup.enter()
        Firestore.firestore().collection("users").document(uid)
            .getDocument { document, error in
                if let error = error {
                    err = error
                } else {
                    doc = document!.data()
                    doc!["id"] = uid
                }
                dispatchGroup.leave()
        }
        dispatchGroup.enter()
        Storage.storage().reference().child("profile_pics").child(uid + ".png")
            .getData(maxSize: 1024 * 1024 * 1024) { data, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    img = UIImage(data: data!)
                }
                dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: DispatchQueue.global()) {
            if (doc != nil) {
                doc!["image"] = img
            }
            completion(doc, err)
        }
    }
    
    // NOT TESTED
    func loadUsersWhereInList(field: String, list: Array<Any>, completion: @escaping (_ result: Array<Dictionary<String, Any>?>, _ error: Array<Error?>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var results: Array<Dictionary<String, Any>?> = []
        var errors: Array<Error?> = []
        var idx = 0
        while (idx < list.count) {
            let subArray = Array(list[idx...min(idx + 9, list.count - 1)]) as Array<Any>
            idx += subArray.count
            dispatchGroup.enter()
            Firestore.firestore().collection("users").whereField(field, in: subArray)
                .getDocuments() { documents, err in
                    if (err == nil) {
                        for document in documents!.documents {
                            if (document.documentID != self.userUID) {
                                var data = document.data()
                                data["id"] = document.documentID
                                dispatchGroup.enter()
                                Storage.storage().reference().child("profile_pics").child(document.documentID + ".png")
                                    .getData(maxSize: 1024 * 1024 * 1024) { imageData, error in
                                        if let error = error {
                                            print(error.localizedDescription)
                                        } else {
                                            data["image"] = UIImage(data: imageData!)
                                            results.append(data)
                                        }
                                        dispatchGroup.leave()
                                }
                            }
                        }
                    }
                    errors.append(err)
                    dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: DispatchQueue.global()) {
            completion(results, errors)
        }
    }
    
    // Parameters should be the user's corresponding documents.
    // Returns a list of documents for each mutual connection.
    // "Relationship" is added to the mutual's doc which represents their relationship to "otherUser"
    func loadMutualConnections(user: Dictionary<String, Any>, otherUser: Dictionary<String, Any>,
                               completion: @escaping (_ result: Array<Dictionary<String, Any>?>, _ error: Array<Error?>) -> Void) {
        var mutualIds = Array<String>()
        var mutualRelations = Array<String>()
        var set = Set<String>()
        let usersConnections = user["connections"] as! Array<Dictionary<String, String>>
        let othersConnections = otherUser["connections"] as! Array<Dictionary<String, String>>
        if (usersConnections.count > 0 && othersConnections.count > 0) {
            for connection in usersConnections {
                set.insert(connection["user"]!)
            }
            for connection in othersConnections {
                if (set.contains(connection["user"]!)) {
                    mutualIds.append(connection["user"]!)
                    mutualRelations.append(connection["relationship"]!)
                }
            }
            if (mutualIds.count == 0) {
                completion(Array<Dictionary<String, Any>?>(), Array<Error?>())
            } else {
                loadBatchUsers(userIds: mutualIds) { results, err in
                    var mutuals = results
                    if (mutuals.count > 0) {
                        for i in 0...(mutuals.count - 1) {
                            mutuals[i]!["relationship"] = mutualRelations[i]
                        }
                    }
                    completion(mutuals, err)
                }
            }
        } else {
            completion(Array<Dictionary<String, Any>?>(), Array<Error?>())
        }
    }
    
    // Parameters should be the user's corresponding documents.
    // Returns a list of documents for each mutual connection.
    // Ranks mutuals based on their number of mutuals to otherUser.
    func loadRankedMutualConnections(user: Dictionary<String, Any>, otherUser: Dictionary<String, Any>, limit: Int = Int.max,
                                     completion: @escaping (_ result: Array<Dictionary<String, Any>?>, _ error: Array<Error?>) -> Void) {
        loadMutualConnections(user: user, otherUser: otherUser) { results, err in
            var mutuals = results
            let othersConnections = otherUser["connections"] as! Array<Dictionary<String, String>>
            var set = Set<String>()
            for connection in othersConnections {
                set.insert(connection["user"]!)
            }
            if (results.count > 0) {
                for i in (0...results.count - 1) {
                    let mutualsConnections = mutuals[i]!["connections"] as! Array<Dictionary<String, String>>
                    var priority = 0
                    for j in 0...(mutualsConnections.count - 1) {
                        if (set.contains(mutualsConnections[j]["user"]!)) {
                            priority += 1
                        }
                    }
                    mutuals[i]!["priority"] = priority
                }
                mutuals.sort { ($0!["priority"] as? Int)! > ($1!["priority"] as? Int)! }
                completion(Array(mutuals.prefix(limit)), Array<Error?>())
            } else {
                completion(results, err)
            }
            
        }
    }
    
    // Parameters should be the user's corresponding document and a list of other documents.
    // Returns the list of other documents with the added "mutuals" key which will be a list of ranked documents.
    func loadBatchRankedMutualConnections(user: Dictionary<String, Any>, otherUsers: Array<Dictionary<String, Any>?>, limit: Int = Int.max,
                                          completion: @escaping (_ result: Array<Dictionary<String, Any>?>, _ error: Array<Array<Error?>>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var others = otherUsers
        var errors: Array<Array<Error?>> = Array(repeating: Array<Error?>(), count: others.count)
        if (others.count > 0) {
            for i in 0...(others.count - 1) {
                dispatchGroup.enter()
                loadRankedMutualConnections(user: user, otherUser: others[i]!, limit: limit) { results, err in
                    others[i]!["mutuals"] = results
                    errors[i] = err
                    dispatchGroup.leave()
                }
            }
        }
        dispatchGroup.notify(queue: DispatchQueue.global()) {
            completion(others, errors)
        }
    }
    
    // MODIFY REQUESTS
    
    func sendRelationRequest(otherUID: String, newRelationship: String) {
        Firestore.firestore().collection("users").document(userUID)
            .updateData([
                "sentRelations": FieldValue.arrayUnion([["user": otherUID, "relationship": newRelationship]])
            ])
        Firestore.firestore().collection("users").document(otherUID)
            .updateData([
                "pendingRelations": FieldValue.arrayUnion([["user": userUID, "relationship": newRelationship]])
            ])
    }
    
    func sendConnectionRequest(otherUID: String) {
        Firestore.firestore().collection("users").document(userUID)
            .updateData([
                "sentConnections": FieldValue.arrayUnion([["user": otherUID]])
            ])
        Firestore.firestore().collection("users").document(otherUID)
            .updateData([
                "pendingConnections": FieldValue.arrayUnion([["user": userUID]])
            ])
    }
    
    func cancelRelationRequest(otherUID: String, newRelationship: String) {
        Firestore.firestore().collection("users").document(userUID)
            .updateData([
                "sentRelations": FieldValue.arrayRemove([["user": otherUID, "relationship": newRelationship]])
            ])
        Firestore.firestore().collection("users").document(otherUID)
            .updateData([
                "pendingRelations": FieldValue.arrayRemove([["user": userUID, "relationship": newRelationship]])
            ])
    }
    
    func cancelConnectionRequest(otherUID: String) {
        Firestore.firestore().collection("users").document(userUID)
            .updateData([
                "sentConnections": FieldValue.arrayRemove([["user": otherUID]])
            ])
        Firestore.firestore().collection("users").document(otherUID)
            .updateData([
                "pendingConnections": FieldValue.arrayRemove([["user": userUID]])
            ])
    }
    
    func confirmPendingRelation(otherUID: String, newRelationship: String) {
        var oldRelationship = ""
        for connection in (userDocument["connections"] as! Array<Dictionary<String, String>>) {
            if (connection["user"] == otherUID) {
                oldRelationship = connection["relationship"]!
            }
        }
        Firestore.firestore().collection("users").document(otherUID)
            .updateData([
                "connections": FieldValue.arrayUnion([["user": userUID, "relationship": newRelationship]]),
                "sentRelations": FieldValue.arrayRemove([["user": userUID, "relationship": newRelationship]])
            ])
        Firestore.firestore().collection("users").document(userUID)
            .updateData([
                "connections": FieldValue.arrayRemove([["user": otherUID, "relationship": oldRelationship]]),
                "pendingRelations": FieldValue.arrayRemove([["user": otherUID, "relationship": newRelationship]])
            ])
        Firestore.firestore().collection("users").document(userUID)
            .updateData([
                "connections": FieldValue.arrayUnion([["user": otherUID, "relationship": newRelationship]])
            ])
    }
    
    func declinePendingRelation(otherUID: String, newRelationship: String) {
        Firestore.firestore().collection("users").document(otherUID)
            .updateData([
                "sentRelations": FieldValue.arrayRemove([["user": userUID, "relationship": newRelationship]])
            ])
        Firestore.firestore().collection("users").document(userUID)
            .updateData([
                "pendingRelations": FieldValue.arrayRemove([["user": otherUID, "relationship": newRelationship]])
            ])
    }
    
    func confirmPendingConnection(otherUID: String) {
        Firestore.firestore().collection("users").document(otherUID)
            .updateData([
                "connections": FieldValue.arrayUnion([["user": userUID, "relationship": "Acquaintance"]]),
                "sentConnections": FieldValue.arrayRemove([["user": userUID]])
            ])
        Firestore.firestore().collection("users").document(userUID)
            .updateData([
                "connections": FieldValue.arrayUnion([["user": otherUID, "relationship": "Acquaintance"]]),
                "pendingConnections": FieldValue.arrayRemove([["user": otherUID]])
            ])
    }
    
    func declinePendingConnection(otherUID: String) {
        Firestore.firestore().collection("users").document(otherUID)
            .updateData([
                "sentConnections": FieldValue.arrayRemove([["user": userUID]])
            ])
        Firestore.firestore().collection("users").document(userUID)
            .updateData([
                "pendingConnections": FieldValue.arrayRemove([["user": otherUID]])
            ])
    }

}
