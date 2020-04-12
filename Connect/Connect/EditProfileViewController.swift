//
//  EditProfileViewController.swift
//  Connect
//
//  Created by Jennifer Zheng on 4/9/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var bio: UITextView!
    @IBOutlet weak var numConnections: UITextField!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var avatar: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Remove padding from Bio text view
        self.bio.textContainer.lineFragmentPadding = 0
        setupAvatar()
    }
    
    // Register tap gesture on profile pic
    func setupAvatar() {
        avatar.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(recognizeTapGesture(recognizer:)))
        avatar.addGestureRecognizer(tapGesture)
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
            avatar.image = imageSelected.circleMask
        }
        if let imageOriginal = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            avatar.image = imageOriginal.circleMask
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func showCurrentProfileInfo() {
        // TODO: once registration is finished, retrieve name, bio, numConnections, and profile pic from Firebase
    }
    
    // Enable or disable editable fields depending on Edit button state
    @IBAction func editButtonPressed(_ sender: Any) {
        if editButton.currentTitle == "Edit" {
            editButton.setTitle("Save", for: .normal)
            avatar.isUserInteractionEnabled = true
            name.isEnabled = true
            name.backgroundColor = UIColor.quaternarySystemFill
            bio.isEditable = true
            bio.backgroundColor = UIColor.quaternarySystemFill
            
        } else {
            editButton.setTitle("Edit", for: .normal)
            avatar.isUserInteractionEnabled = false
            name.isEnabled = false
            name.backgroundColor = UIColor.white
            bio.isEditable = false
            bio.backgroundColor = UIColor.white
        }
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
