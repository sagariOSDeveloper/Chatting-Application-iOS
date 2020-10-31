//
//  DatabaseManager.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 16/09/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String)->String{
        var safe = emailAddress.replacingOccurrences(of: ".", with: "-")
        safe = safe.replacingOccurrences(of: "@", with: "-")
        return safe
    }
}

//MARK: - Account Management
extension DatabaseManager {
    
    public func userExist(with email: String, completion: @escaping ((Bool)-> Void)){
        var safe = email.replacingOccurrences(of: ".", with: "-")
        safe = safe.replacingOccurrences(of: "@", with: "-")
        database.child(safe).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.value as? String != nil else{
                //                If not found
                completion(false)
                return
            }
            //                If found.
            completion(true)
        }
    }
    
    
    // Inserts new user in Database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool)->Void){
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ]) { (error, _) in
            guard error == nil else {
                print("Failed to save data to firebase")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) { (snapshot) in
                if var usersCollection = snapshot.value as? [[String:String]]{
                    //Append to user dictionary
                    usersCollection.append([
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ])
                    
                    self.database.child("users").setValue(usersCollection) { (error, _) in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                }else{
                    //Create a user array
                    let newCollection: [[String:String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection) { (error, _) in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
                completion(true)
            }
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String:String]],Error>)->Void){
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}

//MARK: - Sending Messages/ Conversations
extension DatabaseManager {
    
    /*
     UniqueIdOfConversation: {
     "message": [
     {
     id: String,
     type: text, photo, video,
     content: String,
     date: Date(),
     senderEmail: String,
     isRead: true/false
     }
     ]
     
     }
     
     
     conversation => [
     [
     "conversationID": "UniqueIdOfConversation"
     "otherUserEmail":
     "latestMessage": => {
     "date": Date()
     "latestMsessage": "message"
     "isRead": true/false
     }
     ]
     ]
     
     */
    
    
    /// Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool)-> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else { return }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child(safeEmail)
        
        ref.observeSingleEvent(of: .value) {[weak self] (snapshot) in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false)
                print("User Not Found")
                return
            }
            let dateString = ChatViewController.dateFormatter.string(from: firstMessage.sentDate)
            
            var message = ""
            switch firstMessage.kind {
            
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
                
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String:Any] = [
                "id": conversationID,
                "otherUserEmail": otherUserEmail,
                "name": name,
                "latestMessage": [
                    "date": dateString,
                    "message": message,
                    "isRead": false
                ]
            ]
            
            let recipientNewConversationData: [String:Any] = [
                "id": conversationID,
                "otherUserEmail": safeEmail,
                "name": "Self",
                "latestMessage": [
                    "date": dateString,
                    "message": message,
                    "isRead": false
                ]
            ]
            // Update recipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //append
                    conversations.append(recipientNewConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversationID)
                    
                }else{
                    // Create one
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipientNewConversationData])
                }
            }
            
            // Update current user conversation entry
            if var converstaions = userNode["conversations"] as? [[String:Any]] {
                //Conversation array exists for current user
                //you should append
                converstaions.append(newConversationData)
                userNode["conversations"] = converstaions
                ref.setValue(userNode) {[weak self] (error, _) in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                    completion(true)
                }
            }else {
                //Conversation array does not exists
                //Create One
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode) {[weak self] (error, _) in
                    guard error == nil else{ 
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                    completion(true)
                }
            }
        }
        
    }
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool)-> Void){
        //        {
        //        id: String,
        //        type: text, photo, video,
        //        content: String,
        //        date: Date(),
        //        senderEmail: String,
        //        isRead: true/false
        //        }
        let dateString = ChatViewController.dateFormatter.string(from: firstMessage.sentDate)
        var message = ""
        switch firstMessage.kind {
        
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
            
        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else { return }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        let collectionMessage: [String:Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "senderEmail": currentUserEmail,
            "isRead": false,
            "name": name
        ]
        let value: [String:Any] = [
            "messages": [
                collectionMessage
                //                message:
            ]
        ]
        database.child(conversationID).setValue(value) { (error, _) in
            guard error == nil else{
                completion(false)
                return
            }
            completion(true)
        }
        
    }
    
    ///Gets all conversation for a given user
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>)->Void) {
        database.child("\(email)/conversations").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                print("Failed in Fetching")
                return
            }
            print("Fetched")
            let conversations: [Conversation] = value.compactMap { (dictionary) in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["otherUserEmail"] as? String,
                      let latestMessage = dictionary["latestMessage"] as? [String:Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["isRead"] as? Bool else {
                    print("HERE WE ARE")
                    return nil
                }
                let latestMessageObject = LatestMessage(date: date , text: message, isRead: isRead)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            }
            completion(.success(conversations))
        }
    }
    
    ///Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool)-> Void) {
        
    }
    
    ///Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>)->Void) {
        database.child("\(id)/messages").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                print("Failed in Fetching")
                return
            }
            print("Fetched")
            let messages: [Message] = value.compactMap { (dictionary) in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["isRead"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["senderEmail"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let type = dictionary["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                    return nil
                }
                let sender = Sender(senderId: senderEmail, displayName: name, photoURL: "")
                return Message(sender: sender, messageId: messageID, sentDate: date, kind: .text(content))
            }
            completion(.success(messages))
        }
    }
}

struct ChatAppUser {
    
    let emailAddress: String
    let firstName: String
    let lastName: String
    
    var safeEmail: String {
        var safe = emailAddress.replacingOccurrences(of: ".", with: "-")
        safe = safe.replacingOccurrences(of: "@", with: "-")
        return safe
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
    
}
