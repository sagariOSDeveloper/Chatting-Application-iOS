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
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool)-> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else { return }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child(safeEmail)
        
        ref.observeSingleEvent(of: .value) { (snapshot) in
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
                "latestMessage": [
                    "date": dateString,
                    "message": message,
                    "isReade": false
                ]
            ]
            
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
                    self?.finishCreatingConversation(conversationID: conversationID, firstMessage: firstMessage, completion: completion)
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
                    self?.finishCreatingConversation(conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                    completion(true)
                }
            }
        }
        
    }
    
    private func finishCreatingConversation(conversationID: String, firstMessage: Message, completion: @escaping (Bool)-> Void){
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
            "isRead": false
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
    
    ///Gets all messages for a given conversation
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>)->Void) {
        
    }
    
    ///Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool)-> Void) {
        
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
