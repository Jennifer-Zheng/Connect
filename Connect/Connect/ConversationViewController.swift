//
//  ConversationViewController.swift
//  Connect
//
//  Created by Evan Weiss on 4/15/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit
import Firebase
import MessageKit
import InputBarAccessoryView

class ConversationViewController: MessagesViewController, InputBarAccessoryViewDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    var nameLabel = UILabel(frame: CGRect(x: 79, y: 57, width: 256, height: 35))
    var otherName = ""
    var otherProfile = UIImage(named: "Profile")
    var otherUID = ""
    var userUID = ""
    var userName = ""
    var messages = Array<Message>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Header.
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 414, height: 100))
        view.backgroundColor = UIColor(#colorLiteral(red: 1, green: 0.8384349346, blue: 0, alpha: 1))
        // Back Button.
        let button = UIButton(frame: CGRect(x: 18, y: 52, width: 50, height: 35))
        button.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        button.addTarget(self, action: #selector(onBackButtonPress), for: .touchUpInside)
        button.tintColor = UIColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        view.addSubview(button)
        // Label.
        nameLabel.font = UIFont(name: "Gill Sans", size: CGFloat(30))
        nameLabel.textAlignment = .center
        view.addSubview(nameLabel)
        self.view.addSubview(view)
        
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.contentInset = UIEdgeInsets(top: 75, left: 0, bottom: 0, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        userUID = FirebaseManager.manager.getUID()
        userName = FirebaseManager.manager.getDocument()["name"] as! String
        nameLabel.text = otherName
        FirebaseManager.manager.createConversationIfNonexistant(otherUID: otherUID) {
            FirebaseManager.manager.getMessages(otherUID: self.otherUID) { results, error in
                if (results.count > 0) {
                    var messages = Array<Message>()
                    for i in 0...(results.count - 1) {
                        let id = String(i)
                        let content = results[i]["content"] as! String
                        let timestamp = results[i]["timestamp"] as! Timestamp
                        let senderUID = results[i]["sender"] as! String
                        let senderName = (senderUID == self.userUID) ? self.userName : self.otherName
                        let message = Message(id: id, content: content, timestamp: timestamp, senderUID: senderUID, senderName: senderName)
                        messages.append(message)
                    }
                    self.messages = messages
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToBottom(animated: true)
                }
            }
        }
    }
    
    

    @objc func onBackButtonPress(sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - InputBarAccessoryViewDelegate
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        FirebaseManager.manager.sendMessage(otherUID: otherUID, content: text)
        let message = Message(id: String(messages.count + 1), content: text, timestamp: Timestamp(), senderUID: userUID, senderName: userName)
        messages.append(message)
        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    // MARK: - MessagesDataSource
    
    func currentSender() -> SenderType {
        return Message(id: "senderType", content: "", timestamp: Timestamp(), senderUID: userUID, senderName: userName) as SenderType
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return CGFloat(25)
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return CGFloat(15)
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }

    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    // MARK: - MessagesLayoutDelegate
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return .zero
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if isFromCurrentSender(message: message) {
            avatarView.image = FirebaseManager.manager.getProfilePic()
        } else {
            avatarView.image = otherProfile
        }
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        return .bubbleTail(corner, .curved)

    }
    
    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 0, height: 25)
    }

}

struct Message {
    var id: String
    var content: String
    var timestamp: Timestamp
    var senderUID: String
    var senderName: String
    
    init(id: String, content: String, timestamp: Timestamp, senderUID: String, senderName: String) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.senderUID = senderUID
        self.senderName = senderName
    }
}

extension Message: SenderType {
    var senderId: String {
        return senderUID
    }
    
    var displayName: String {
        return senderName
    }
}

extension Message: MessageType {
    var sender: SenderType {
        return self as SenderType
    }
    
    var messageId: String {
        return id
    }
    
    var sentDate: Date {
        return timestamp.dateValue()
    }
    
    var kind: MessageKind {
        return .text(content)
    }
}

