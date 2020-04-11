//
//  EditProfileViewController.swift
//  Connect
//
//  Created by Jennifer on 4/9/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var bio: UITextField!
    @IBOutlet weak var numConnections: UITextField!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var avatar: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editButton.title = "Done"
        name.isEnabled = true
        bio.isEnabled = true
        setupAvatar()
    }
    
    func setupAvatar() {
        avatar.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(recognizeTapGesture(recognizer:)))
        avatar.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func recognizeTapGesture(recognizer: UITapGestureRecognizer) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
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
    
    override func shouldPerformSegue(withIdentifier identifier: String,
                            sender: Any?) -> Bool {
        if identifier == "ConnectionsSegue" && editButton.title == "Edit" {
            return false
        }
        return true
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        if editButton.title == "Edit" {
            editButton.title = "Done"
            avatar.isUserInteractionEnabled = true
            name.isEnabled = true
            bio.isEnabled = true
        } else {
            editButton.title = "Edit"
            avatar.isUserInteractionEnabled = false
            name.isEnabled = false
            bio.isEnabled = false
        }
    }
}

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
