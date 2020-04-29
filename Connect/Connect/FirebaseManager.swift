//
//  FirebaseManager.swift
//  Connect
//
//  Created by Evan Weiss on 4/16/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase
import FirebaseStorage

class FirebaseManager {
    
    static var manager = FirebaseManager()
    
    private var isInitialLoad = true
    private var userUID: String = ""
    private var userProfilePic: UIImage = UIImage()
    private var userDocument: Dictionary<String, Any> = [:]
    var currentMessageListener: ListenerRegistration?
    var currentConversationListener: ListenerRegistration?
    
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
    
    // MARK: - Get Requests
    
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
    
    // Load all users where a field matches a value in a lit.
    func loadUsersWhereInList(field: String, list: Array<Any>, completion: @escaping (_ result: Array<Dictionary<String, Any>?>, _ error: Array<Error?>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var results: Array<Dictionary<String, Any>?> = []
        var errors: Array<Error?> = []
        var idx = 0
        // Firestore only allows up to 10 items to be searched through at a time so we need to loop with at most 10 items each time.
        while (idx < list.count) {
            let subArray = Array(list[idx...min(idx + 9, list.count - 1)]) as Array<Any>
            idx += subArray.count
            dispatchGroup.enter()
            // Load users matching values.
            Firestore.firestore().collection("users").whereField(field, in: subArray)
                .getDocuments() { documents, err in
                    if (err == nil) {
                        for document in documents!.documents {
                            if (document.documentID != self.userUID) {
                                var data = document.data()
                                data["id"] = document.documentID
                                dispatchGroup.enter()
                                // If user was found, load their image.
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
    
    // Loads nearby users.
    func loadNearbyUsers(completion: @escaping (_ result: Array<Dictionary<String,Any>?>, _ error: Array<Error?>) -> Void) {
        let userPoint = userDocument["location"] as? GeoPoint
        if (userPoint != nil) {
            let userKey = "\(Int((10*userPoint!.latitude).rounded())),\(Int((10*userPoint!.longitude).rounded()))"
            Firestore.firestore().collection("locations").document("location")
                .getDocument { document, error in
                    if let error = error {
                        completion([], [error])
                    } else {
                        let locations = (document!.data()!["dict"] as! Dictionary<String, Array<Dictionary<String, Any>>>)[userKey]!
                        var ids = Array<String>()
                        var distances = Array<String>()
                        for entry in locations {
                            let location = entry["location"] as! GeoPoint
                            let distance = self.haversineDistance(loc1: userPoint!, loc2: location)
                            if (distance < self.userDocument["maxRadius"] as! Double && (self.userUID != entry["user"] as! String)) {
                                ids.append(entry["user"] as! String)
                                distances.append(String(format: "%.1f", distance))
                            }
                        }
                        if (ids.count > 0) {
                            self.loadBatchUsers(userIds: ids) { results, errors in
                                var users = results
                                for i in 0...(users.count - 1) {
                                    users[i]!["distance"] = distances[i]
                                }
                                users = users.filter { !($0!["blockedUsers"] as! Array<String>).contains(self.userUID) }
                                users = users.filter { !(self.userDocument["blockedUsers"] as! Array<String>).contains($0!["id"] as! String) }
                                users = users.filter { $0!["hideProfile"] as! Bool == false }
                                users.sort { Double($0!["distance"] as! String)! < Double($1!["distance"] as! String)! }
                                completion(users, errors)
                            }
                        } else {
                            completion([], [error])
                        }
                    }
            }
        } else {
            completion([], [])
        }
    }

    
    // MARK: - Modify Requests
    
    // Upload the given profile picture to storage.
    func uploadImage(image: UIImage) {
        guard let imageData = image.pngData() else {
            print("Error converting image to type Data")
            return
        }
        let reference = Storage.storage().reference().child("profile_pics").child("\(userUID).png")
        reference.putData(imageData, metadata: nil, completion: { (metadata, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            reference.downloadURL(completion: { (url, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                Firestore.firestore().collection("users").document(self.userUID)
                    .updateData(["profilePic": url!.absoluteString])
            })
         })
    }
    
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

    func cancelExistingRelationRequest(otherUID: String, newRelationship: String) {
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
        Firestore.firestore().collection("users").document(otherUID)
            .updateData([
                "connections": FieldValue.arrayRemove([["user": userUID, "relationship": oldRelationship]])
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
        createConversationIfNonexistant(otherUID: otherUID, completion: {})
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
    
    func removeConnection(otherUID: String, relationship: String) {
        Firestore.firestore().collection("users").document(otherUID)
            .updateData([
                "connections": FieldValue.arrayRemove([["user": userUID, "relationship": relationship]])
            ])
        Firestore.firestore().collection("users").document(userUID)
            .updateData([
                "connections": FieldValue.arrayRemove([["user": otherUID, "relationship": relationship]])
            ])
    }
    
    func blockUser(otherUID: String, relationship: String) {
        Firestore.firestore().collection("users").document(userUID)
            .updateData([
                "blockedUsers": FieldValue.arrayUnion([otherUID])
            ])
        removeConnection(otherUID: otherUID, relationship: relationship)
        cancelConnectionRequest(otherUID: otherUID)
        removeConversation(otherUID: otherUID)
    }
    
    func unblockUser(otherUID: String, relationship: String) {
        Firestore.firestore().collection("users").document(userUID)
            .updateData([
                "blockedUsers": FieldValue.arrayRemove([otherUID])
            ])
        addConversation(otherUID: otherUID)
    }
    
    // Updates the user's most recent location.
    func updateLocation(location: CLLocation) {
        let newPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        // Remove old location from the dictionary.
        if (userDocument.keys.contains("location")) {
            let oldPoint = userDocument["location"] as! GeoPoint
            Firestore.firestore().collection("locations").document("location")
                .updateData(hashGeopoints(point: oldPoint, add: false))
        }
        // Store new location.
        Firestore.firestore().collection("users").document(userUID)
            .updateData(["location": newPoint])
        Firestore.firestore().collection("locations").document("location")
            .updateData(hashGeopoints(point: newPoint, add: true))
    }
    
    // MARK: - Messaging Methods
    
    // Create a conversation between users if one doesn't yet exist.
    func createConversationIfNonexistant(otherUID: String, completion: @escaping () -> Void) {
        let documentID = getConversationDocumentID(otherUID: otherUID)
        Firestore.firestore().collection("conversations").document(documentID)
            .getDocument { document, error in
                if let document = document, !document.exists {
                    Firestore.firestore().collection("conversations").document(documentID)
                        .setData([
                            "messages": [Any](),
                            "updatedAt": Timestamp()
                        ])
                    self.addConversation(otherUID: otherUID)
                }
                completion()
        }
    }
    
    // Show conversation. Used when a user is unblocked, or upon creation of a new conversation.
    private func addConversation(otherUID: String) {
        Firestore.firestore().collection("users").document(self.userUID)
        .updateData([
            "conversations": FieldValue.arrayUnion([otherUID]),
        ])
        Firestore.firestore().collection("users").document(otherUID)
        .updateData([
            "conversations": FieldValue.arrayUnion([self.userUID]),
        ])
    }
    
    // Hide conversations. Used when either user blocks each other.
    private func removeConversation(otherUID: String) {
        Firestore.firestore().collection("users").document(self.userUID)
        .updateData([
            "conversations": FieldValue.arrayRemove([otherUID]),
        ])
        Firestore.firestore().collection("users").document(otherUID)
        .updateData([
            "conversations": FieldValue.arrayRemove([self.userUID]),
        ])
    }
    
    private func loadConversation(otherUID: String, completion: @escaping (_ result: Dictionary<String, Any>) -> Void) {
        let dispatchGroup = DispatchGroup()
        let documentID = self.getConversationDocumentID(otherUID: otherUID)
        var conversation = Dictionary<String, Any>()
        
        dispatchGroup.enter()
        loadUser(uid: otherUID) { result, errors in
            for key in result!.keys {
                conversation[key] = result![key]
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        Firestore.firestore().collection("conversations").document(documentID)
            .getDocument { document, error in
                if let document = document, document.exists {
                    let data = document.data()!
                    let messages = data["messages"] as! Array<Dictionary<String, Any>>
                    conversation["documentID"] = documentID
                    conversation["updatedAt"] = data["updatedAt"] as! Timestamp
                    if (messages.count > 0) {
                        let lastMessage = messages.last!
                        conversation["lastSender"] = lastMessage["sender"]!
                        conversation["lastMessage"] = lastMessage["content"]!
                        conversation["read"] = data["read"] as! Bool
                    }
                }
                dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: DispatchQueue.global()) {
            completion(conversation)
        }
    }
    
    // TODO: Depending on how notifications are implemented, think about moving the listener to a separate function like the user document
    // listener. Then, get rid of the removeListener method and have this method reference variables instantaneously with an observer.
    //
    // Gets a list of conversations sorted by timestamp with the most recent message.
    func loadConversations(completion: @escaping (_ result: Array<Dictionary<String, Any>>) -> Void) {
        currentConversationListener = Firestore.firestore().collection("users").document(userUID)
            .addSnapshotListener() { document, error in
                if let document = document, document.exists {
                    let dispatchGroup = DispatchGroup()
                    var conversations = Array<Dictionary<String, Any>>()
                    let otherUIDs = document.data()!["conversations"] as! Array<String>
                    for otherUID in otherUIDs  {
                        dispatchGroup.enter()
                        self.loadConversation(otherUID: otherUID) { result in
                            conversations.append(result)
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.notify(queue: DispatchQueue.global()) {
                        conversations.sort { ($0["updatedAt"] as! Timestamp).seconds > ($1["updatedAt"] as! Timestamp).seconds }
                        completion(conversations)
                    }
                }
        }
    }
    
    // Returns all messages in a conversation.
    // TODO: Use documentChange .add. See photos on phone. Ray Wenderlich
    func getMessages(otherUID: String, completion: @escaping (_ result: Array<Dictionary<String, Any>>, _ error: Error?) -> Void) {
        let documentID = getConversationDocumentID(otherUID: otherUID)
        currentMessageListener = Firestore.firestore().collection("conversations").document(documentID)
            .addSnapshotListener() { document, error in
                if let error = error {
                    completion(Array<Dictionary<String, Any>>(), error)
                } else {
                    let messages = document!.data()!["messages"] as! Array<Dictionary<String, Any>>
                    // Mark as read.
                    if (messages.count > 0 && self.userUID != messages.last!["sender"] as! String) {
                        Firestore.firestore().collection("conversations").document(documentID)
                            .updateData([
                                "read": true
                            ])
                    }
                    completion(messages, nil)
                }
                
        }
    }
    
    func sendMessage(otherUID: String, content: String) {
        let newMessage = ["sender": userUID, "content": content, "timestamp": Timestamp()] as [String : Any]
        let documentID = getConversationDocumentID(otherUID: otherUID)
        Firestore.firestore().collection("conversations").document(documentID)
            .updateData([
                "messages": FieldValue.arrayUnion([newMessage]),
                "read": false,
                "updatedAt": Timestamp()
            ])
        Firestore.firestore().collection("conversations").document(otherUID)
            .updateData([
                "lastMessageReceivedAt": Timestamp()
            ])
        Firestore.firestore().collection("conversations").document(otherUID)
            .updateData([
                "lastMessageReceivedAt": Timestamp()
            ])
    }
    
    func deleteMessageListener() {
        currentMessageListener!.remove()
    }
    
    func deleteConversationListener() {
        currentConversationListener!.remove()
    }
    
    // MARK: - UTILITY METHODS
    
    // Use less precise coordinates for hashing then store data in neighbors for border cases.
    // Block sizes are roughly 20sq miles.
    // For example, coords 12.34567 and 32.10000 will be stored in (123, 321), (124, 321), (122, 321), (123, 322)... etc.
    func hashGeopoints(point: GeoPoint, add: Bool) -> Dictionary<String, Any> {
        var results = Dictionary<String, Any>()
        for i in -2...2 {
            for j in -2...2 {
                let lat = (10 * point.latitude) + Double(i)
                let long = (10 * point.longitude) + Double(j)
                let key = "\(Int(lat.rounded())),\(Int(long.rounded()))"
                if (add) {
                    results["dict.\(key)"] = FieldValue.arrayUnion([["user": userUID, "location": point]])
                } else {
                    results["dict.\(key)"] = FieldValue.arrayRemove([["user": userUID, "location": point]])
                }
            }
        }
        return results
    }
    
    // Equation to find the distance in miles between two coordinates.
    // Formula referenced from https://www.movable-type.co.uk/scripts/latlong.html.
    func haversineDistance(loc1: GeoPoint, loc2: GeoPoint) -> Double {
        // The radius of Earth in miles.
        let radius = 3958.8;
        let deltaLatitude = (loc2.latitude - loc1.latitude) * .pi / 180
        let deltaLongitude = (loc2.longitude - loc1.longitude) * .pi / 180
        let a = sin(deltaLatitude / 2) * sin(deltaLatitude / 2) +
            cos(loc1.latitude * .pi / 180) * cos(loc2.latitude * .pi / 180) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return radius * c
    }
    
    // Create a unique conversation document ID by combining both user's ID's in alphabetical order.
    func getConversationDocumentID(otherUID: String) -> String {
        return otherUID < userUID ? (otherUID + "|" + userUID) : (userUID + "|" + otherUID)
    }

}
