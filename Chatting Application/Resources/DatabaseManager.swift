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
import MessageKit
import CoreLocation

///Manager Object to Read and Write Data to Firebase Database
final class DatabaseManager {
    ///Shared instances of class
    public static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    private init(){}
    
    static func safeEmail(emailAddress: String)->String{
        var safe = emailAddress.replacingOccurrences(of: ".", with: "-")
        safe = safe.replacingOccurrences(of: "@", with: "-")
        return safe
    }
}

//MARK: - Account Management
extension DatabaseManager {
    
    ///Checks if user exists with given email
    ///Parameters
    /// - `email`:      Target email to be checked
    /// - `completion`:      Async closure to return with result
    public func userExist(with email: String, completion: @escaping ((Bool)-> Void)){
        let safe = DatabaseManager.safeEmail(emailAddress: email)
        database.child(safe).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.value as? [String:Any] != nil else{
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
        ]) {[weak self] (error, _) in
            guard error == nil,
                  let strongSelf = self  else {
                print("Failed to save data to firebase")
                completion(false)
                return
            }
            
            strongSelf.database.child("users").observeSingleEvent(of: .value) { (snapshot) in
                if var usersCollection = snapshot.value as? [[String:String]]{
                    //Append to user dictionary
                    usersCollection.append([
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ])
                    
                    strongSelf.database.child("users").setValue(usersCollection) { (error, _) in
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
                    strongSelf.database.child("users").setValue(newCollection) { (error, _) in
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
    
    ///Get all users from database
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
        public var localizedDescription: String {
            switch self {
            case .failedToFetch:
                return "We are unable to fetch the data from database"
            }
        }
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
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String  else { return }
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
                "name": currentName,
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
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                    
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
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool)-> Void) {
        // add new message to Messages
        // update sender latest messate
        // update recipient latest messate
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self](snapshot) in
            guard let strongSelf = self else{return}
            guard var currentMessages = snapshot.value as? [[String:Any]] else {
                completion(false)
                return
            }
            let dateString = ChatViewController.dateFormatter.string(from: newMessage.sentDate)
            
            var message = ""
            switch newMessage.kind {
            
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetedURL = mediaItem.url?.absoluteString {
                    message = targetedURL
                }
                break
            case .video(let mediaItem):
                if let targetedURL = mediaItem.url?.absoluteString {
                    message = targetedURL
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
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
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return }
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            let newMessageEntry: [String:Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "senderEmail": currentUserEmail,
                "isRead": false,
                "name": name
            ]
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { (err, _) in
                guard err == nil else{
                    return completion(false)
                }
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                    
                    var databaseEntryConversations = [[String: Any]]()
                    
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "message": message,
                        "isRead": false
                    ]
                    if var currentUserConversations = snapshot.value as? [[String:Any]] {
                        
                        var targetConversation: [String:Any]?
                        var position = 0
                        
                        for conversationDictionary in currentUserConversations{
                            if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        
                        if var targetConversation = targetConversation {
                            targetConversation["latestMessage"] = updatedValue
                            currentUserConversations[position] = targetConversation
                            databaseEntryConversations = currentUserConversations
                        }else{
                            let newConversationData: [String:Any] = [
                                "id": conversation,
                                "otherUserEmail": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name": name,
                                "latestMessage": updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations
                        }
                    }else{
                        let newConversationData: [String:Any] = [
                            "id": conversation,
                            "otherUserEmail": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name": name,
                            "latestMessage": updatedValue
                        ]
                        databaseEntryConversations = [
                            newConversationData
                        ]
                    }
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                            
                        }
                        //Update latest message of Reciepent
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "message": message,
                                "isRead": false
                            ]
                            var databaseEntryConversations = [[String: Any]]()
                            guard let currentUserName = UserDefaults.standard.value(forKey: "name") as? String else {return}
                            
                            if var otherUserConversations = snapshot.value as? [[String:Any]] {
                                var targetConversation: [String:Any]?
                                var position = 0
                                
                                for conversationDictionary in otherUserConversations{
                                    if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                if var targetConversation = targetConversation {
                                    targetConversation["latestMessage"] = updatedValue
                                    otherUserConversations[position] = targetConversation
                                    databaseEntryConversations = otherUserConversations
                                }else{
                                    // Failed to find in current collection
                                    let newConversationData: [String:Any] = [
                                        "id": conversation,
                                        "otherUserEmail": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                        "name": currentUserName,
                                        "latestMessage": updatedValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversations = otherUserConversations
                                }
                            }else{
                                // current collection does not exist
                                let newConversationData: [String:Any] = [
                                    "id": conversation,
                                    "otherUserEmail": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                    "name": currentUserName,
                                    "latestMessage": updatedValue
                                ]
                                databaseEntryConversations = [
                                    newConversationData
                                ]
                            }
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations) { (error, _) in
                                guard error == nil else {
                                    completion(false)
                                    return
                                    
                                }
                                completion(true )
                            }
                        }
                    }
                }
            }
        }
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
                
                var kind: MessageKind?
                if type == "photo" {
                    
                    guard let imageURL = URL(string: content),
                          let placeHolderImage = UIImage(systemName: "plus")  else {
                        return nil
                    }
                    let media = Media(url: imageURL, image: nil, placeholderImage: placeHolderImage, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                    
                }else if type == "video" {
                    
                    guard let videoURL = URL(string: content),
                          let placeHolder = UIImage(named: "video")  else {
                        return nil
                    }
                    let media = Media(url: videoURL, image: nil, placeholderImage: placeHolder, size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                    
                } else if type == "location" {
                    let locationComponents = content.split(separator: ",")
                    guard let longitude = Double(locationComponents[0]), let latitude = Double(locationComponents[1]) else {
                        return nil
                    }
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude) , size: CGSize(width: 300, height: 300))
                    
                    kind = .location(location)
                }
                else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else{
                    return nil
                }
                
                //                if type == phot
                let sender = Sender(senderId: senderEmail, displayName: name, photoURL: "")
                return Message(sender: sender, messageId: messageID, sentDate: date, kind: finalKind)
            }
            completion(.success(messages))
        }
    }
    
    public func deleteConversation(converdsationId: String, completion: @escaping (Bool)->Void){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        print("Deleted Converssation with id: \(converdsationId)")
        // Get All Conversations For Current User
        // Delete Conversation in Collection with Target ID
        // Reset those conversations for the user in database
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) { (snapshot) in
            if var conversations = snapshot.value as? [[String:Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                       id == converdsationId {
                        print("Found Convo to Delete")
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations) { (error, _) in
                    guard error == nil else {
                        print("Error in deleting from database")
                        completion(false)
                        return
                    }
                    print("Deleted Converssation")
                    completion(true)
                }
            }
        }
    }
}
extension DatabaseManager {
    /// Returns a Dictionary Node at child path
    public func getDataFor(path: String, completion: @escaping (Result<Any,Error>)->Void){
        database.child(path).observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public func conversationExist(with targetRecipientEmail: String, completion: @escaping (Result<String,Error>)->Void){
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else { return }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
            guard let collection = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            // Iterate and find conversation with target sender
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["otherUserEmail"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }){
                // get ID
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failedToFetch))
            return
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
