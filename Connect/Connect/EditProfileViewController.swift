//
//  EditProfileViewController.swift
//  Connect
//
//  Created by Jennifer Zheng on 4/9/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var bio: UITextView!
    @IBOutlet weak var numConnections: UITextField!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var goToConnectionsButton: UIButton!
    @IBOutlet weak var profilePic: UIImageView!
    
    var uid = ""
    var initialCreation = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Remove padding from Bio text view
        self.bio.textContainer.lineFragmentPadding = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
           uid = Auth.auth().currentUser!.uid
           showCurrentProfileInfo()
           setupProfilePic()
        if initialCreation {
            goToConnectionsButton.isHidden = false
        } else {
            goToConnectionsButton.isHidden = true
        }
    }
    
    @IBAction func onBackButtonPress(_ sender: Any) {
        if (initialCreation) {
            self.performSegue(withIdentifier: "tabBarSegue", sender: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func showCurrentProfileInfo() {
        // Profile picture
        let reference = Storage.storage().reference().child("profile_pics").child("\(uid).png")
        // Download in memory with a maximum allowed size = 5 MB
        reference.getData(maxSize: 5 * 1024 * 1024) { data, error in
        if (error != nil) {
            print(error.debugDescription)
          } else {
            self.profilePic.image = UIImage(data: data!)
          }
        }
        
        // Name and bio
        let db = Firestore.firestore()

        db.collection("users").document("\(uid)")
        .getDocument { document, error in
            guard let document = document, document.exists else {
            print("Error fetching document: \(error!)")
            return
          }
            self.name.text = document.get("name") as? String;
            self.bio.text = document.get("bio") as? String;
            
            let connectionsArray = (document.get("connections") as? Array<Dictionary<String, String>>)!
            if connectionsArray.count == 1 {
                self.numConnections.text = String(connectionsArray.count) + " Connection"
            } else {
                self.numConnections.text = String(connectionsArray.count) + " Connections"
            }
        }
    }
    
    
    // Register tap gesture on profile pic
    func setupProfilePic() {
        profilePic.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(recognizeTapGesture(recognizer:)))
        profilePic.addGestureRecognizer(tapGesture)
    }
    
    // Allow users to choose profile pic from their photo library
    @IBAction func recognizeTapGesture(recognizer: UITapGestureRecognizer) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    // Replace profile pic with selected image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imageSelected = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            // Resize image before upload
            let image = self.resizeImage(image: imageSelected, targetSize: CGSize(width: 500.0, height: 500.0))
            profilePic.image = image.circleMask
        }
        if let imageOriginal = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // Resize image before upload
            let image = self.resizeImage(image: imageOriginal, targetSize: CGSize(width: 500.0, height: 500.0))
            profilePic.image = image.circleMask
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // Enable or disable editable fields depending on Edit button state
    @IBAction func editButtonPressed(_ sender: Any) {
        if editButton.currentTitle == "Edit" {
            editButton.setTitle("Save", for: .normal)
            profilePic.isUserInteractionEnabled = true
            name.isEnabled = true
            name.backgroundColor = UIColor.quaternarySystemFill
            bio.isEditable = true
            bio.backgroundColor = UIColor.quaternarySystemFill
            
        } else {
            editButton.setTitle("Edit", for: .normal)
            profilePic.isUserInteractionEnabled = false
            name.isEnabled = false
            name.backgroundColor = UIColor.white
            bio.isEditable = false
            bio.backgroundColor = UIColor.white
            
            updateDatabaseWithUserNameAndBio()
            FirebaseManager.manager.uploadImage(image: profilePic.image!)
        }
    }
    
    // Update the name and bio of the user on "Save"
    func updateDatabaseWithUserNameAndBio() {
        let db = Firestore.firestore()
        
        let userRef = db.collection("users").document("\(self.uid)");

        // Update name and bio
        userRef.updateData([
            "name": name.text!,
            "bio": bio.text ?? "",
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    // Resize image to target size
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    // Code to dismiss keyboard
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

// Masks user selected profile pic so that it will be circular
extension UIImage {
    var circleMask: UIImage? {
        let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
        let imageView = UIImageView(frame: .init(origin: .init(x: 0, y: 0), size: square))
        imageView.contentMode = .scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
