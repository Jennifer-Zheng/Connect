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
    var otherUID = ""
    
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
        nameLabel.text = otherName
        self.messagesCollectionView.reloadData()
        self.messagesCollectionView.scrollToBottom(animated: true)
    }
    
    

    @objc func onBackButtonPress(sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - InputBarAccessoryViewDelegate
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // text = content.
        // TODO: Create message, Append to message array then call FirebaseManager.manager.sendMessage()
        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)
        messageInputBar.inputTextView.resignFirstResponder();
    }
    
    // MARK: - MessagesDataSource
    
    func currentSender() -> SenderType {
        return Message(id: "test", content: "test", timestamp: Timestamp(), senderUID: "test", senderName: "Evan Weiss") as SenderType
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterday2 = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        if (indexPath.section == 1) {
            return Message(id: "test", content: "Hello! My name is Evan Weiss.", timestamp: Timestamp(date: yesterday2), senderUID: "test", senderName: "Evan Weiss") as MessageType
        }
        else if (indexPath.section == 2) {
            return Message(id: "Hi, I am a Test Account. This is a really long message to test wrapping.", content: "test", timestamp: Timestamp(date: yesterday), senderUID: "test2", senderName: "Bill Bulko") as MessageType
        }
        return Message(id: "test", content: "Okay.", timestamp: Timestamp(), senderUID: "test", senderName: "Evan Weiss") as MessageType
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return 5
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
        
        // if message.sender.senderID == userUID. else...
        avatarView.image = FirebaseManager.manager.getProfilePic()
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

