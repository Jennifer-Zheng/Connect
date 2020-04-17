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
    private var userUid: String = ""
    private var userProfilePic: UIImage = UIImage()
    private var userDocument: Dictionary<String, Any> = [:]
    
    init() {
        Firestore.firestore().clearPersistence(completion: nil)
    }
    
    func getUid() -> String {
        return userUid
    }
    
    func getDocument() -> Dictionary<String, Any>{
        return userDocument
    }
    
    func getProfilePic() -> UIImage {
        return userProfilePic
    }
    
    // Load the user's profile.
    func loadSelf(completion: @escaping () -> Void) {
        userUid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(userUid)
            .addSnapshotListener() { document, error in
                if let error = error {
                    print("Error fetching document: \(error)")
                } else {
                    self.userDocument = document!.data()!
                }
                // We load the user's profile picture inside the snapshot listener so it auto-updates if changed.
                Storage.storage().reference().child("profile_pics").child(self.userUid + ".png")
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
    
    // Loads all of a user's connection's profiles. Also works for pendingRequests and pendingConnections.
    func loadBatchUsers(userConnections: Array<Dictionary<String, Any>>,
                        completion: @escaping (_ results: Array<Any?>, _ errors: Array<Error?>) -> Void) {
        var userIds = Array<String>()
        for user in userConnections {
            userIds.append(user["user"] as! String)
        }
        loadBatchUsers(userIds: userIds) { results, errors in
            completion(results, errors)
        }
    }
    
    // Loads users given an array of userIds.
    func loadBatchUsers(userIds: Array<String>, completion: @escaping (_ results: Array<Any?>, _ errors: Array<Error?>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var results: Array<Any?> = Array(repeating: nil, count: userIds.count)
        var errors: Array<Error?>  = Array(repeating: nil, count: userIds.count)
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
    
    func loadUsersWhere(where: String, in: Array<Any>) {
        
    }
    
    // Dictionaries should be the user's corresponding documents
    func loadMutualConnections(user: Dictionary<String, Any>, otherUser: Dictionary<String, Any>, limit: Int = Int.max,
                               completion: @escaping () -> Void) {
        
    }
}
